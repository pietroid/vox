// Phase 0 of the voice call: measure Deepgram against the key before
// trusting it. Flux TTS's time to first audio in Portuguese, and where Flux
// STT ends the turns of a long Portuguese talk.
//
//   node --env-file=.env.local scripts/deepgram-probe.mjs tts [voice…]
//   node --env-file=.env.local scripts/deepgram-probe.mjs stt take.wav [--long] [--out words.json]
//
// `tts` speaks two sentences per voice and prints ms to the first audio
// byte; the audio goes to /tmp/vox-probe-<voice>.wav to be listened to.
// `stt` streams a 16 kHz mono WAV in real time, 80 ms a chunk, and prints
// each turn event; `--long` sends the long-turn Configure (0.9, 3 s) after
// 20 s of speech, as the gateway does. `--out` keeps every EndOfTurn.
import { writeFileSync, readFileSync } from 'node:fs';
import WebSocket from 'ws';

const key = process.env.DEEPGRAM_API_KEY;
if (!key) throw new Error('DEEPGRAM_API_KEY is not set');
const headers = { Authorization: `Token ${key}` };
const [mode, ...args] = process.argv.slice(2);

if (mode === 'tts') await tts(args.length ? args : ['flux-bianca-pt']);
else if (mode === 'stt')
  await stt(args[0], args.includes('--long'), after(args, '--out'), after(args, '--eot'), after(args, '--timeout'));
else throw new Error('usage: deepgram-probe.mjs tts [voice…] | stt take.wav');

function after(list, flag) {
  const i = list.indexOf(flag);
  return i < 0 ? undefined : list[i + 1];
}

async function tts(voices) {
  const sentences = [
    'Boa! Você falou em um ritmo de cento e dezoito palavras por minuto.',
    'Agora tente de novo, fazendo uma pausa depois de cada ideia.',
  ];
  for (const voice of voices) {
    const url = `wss://api.deepgram.com/v2/speak?model=${voice}&encoding=linear16&sample_rate=24000`;
    const t0 = performance.now();
    const ws = new WebSocket(url, { headers });
    const chunks = [];
    let opened, first, meta;
    await new Promise((resolve, reject) => {
      ws.on('open', () => {
        opened = performance.now();
        for (const text of sentences) ws.send(JSON.stringify({ type: 'Speak', text }));
        ws.send(JSON.stringify({ type: 'Flush' }));
      });
      ws.on('message', (data, binary) => {
        if (binary) {
          first ??= performance.now();
          chunks.push(data);
          return;
        }
        const message = JSON.parse(data.toString());
        if (message.type === 'SpeechMetadata') {
          meta = message;
          ws.send(JSON.stringify({ type: 'Close' }));
        }
        if (message.type === 'Error') reject(new Error(JSON.stringify(message)));
      });
      ws.on('close', resolve);
      ws.on('error', reject);
    });
    const pcm = Buffer.concat(chunks);
    writeFileSync(`/tmp/vox-probe-${voice}.wav`, wav(pcm, 24000));
    console.log(
      JSON.stringify({
        voice,
        connect_ms: Math.round(opened - t0),
        first_audio_ms_after_speak: Math.round(first - opened),
        audio_s: +(pcm.length / 48000).toFixed(2),
        chars: meta?.billable_character_count,
      }),
    );
  }
}

async function stt(path, long, out, eot, timeout) {
  const file = readFileSync(path);
  const pcm = file.subarray(file.indexOf('data') + 8);
  const url =
    'wss://api.deepgram.com/v2/listen?model=flux-general-multi&language_hint=pt' +
    '&encoding=linear16&sample_rate=16000' +
    (eot ? `&eot_threshold=${eot}` : '') +
    (timeout ? `&eot_timeout_ms=${timeout}` : '');
  const ws = new WebSocket(url, { headers });
  const turns = [];
  let started = 0;
  let configured = false;
  await new Promise((resolve, reject) => {
    ws.on('open', async () => {
      started = performance.now();
      const chunk = 2560; // 80 ms
      for (let at = 0; at < pcm.length; at += chunk) {
        ws.send(pcm.subarray(at, at + chunk));
        await new Promise((r) => setTimeout(r, 80));
      }
      // 4 s of silence, so the last turn can end on the timeout.
      for (let i = 0; i < 50; i++) {
        ws.send(Buffer.alloc(chunk));
        await new Promise((r) => setTimeout(r, 80));
      }
      ws.send(JSON.stringify({ type: 'CloseStream' }));
    });
    ws.on('message', (data) => {
      const m = JSON.parse(data.toString());
      const at = ((performance.now() - started) / 1000).toFixed(2);
      if (m.type !== 'TurnInfo') {
        console.log(at, m.type, m.code ?? '', m.description ?? '');
        return;
      }
      if (long && !configured && m.audio_window_end - m.audio_window_start > 20) {
        configured = true;
        ws.send(
          JSON.stringify({
            type: 'Configure',
            thresholds: { eot_threshold: 0.9, eot_timeout_ms: 3000 },
          }),
        );
        console.log(at, 'sent Configure 0.9 / 3000');
      }
      if (m.event === 'Update') return;
      console.log(
        at,
        m.event,
        `turn ${m.turn_index}`,
        `window ${m.audio_window_start}–${m.audio_window_end}`,
        m.trigger ?? '',
        `eot ${m.end_of_turn_confidence?.toFixed(2)}`,
        `${m.words.length} words`,
        m.event === 'EndOfTurn' ? `"${m.transcript.slice(0, 80)}…"` : '',
      );
      if (m.event === 'EndOfTurn') turns.push(m);
    });
    ws.on('close', resolve);
    ws.on('error', reject);
  });
  if (out) writeFileSync(out, JSON.stringify(turns, null, 1));
}

function wav(pcm, rate) {
  const h = Buffer.alloc(44);
  h.write('RIFF', 0);
  h.writeUInt32LE(36 + pcm.length, 4);
  h.write('WAVEfmt ', 8);
  h.writeUInt32LE(16, 16);
  h.writeUInt16LE(1, 20);
  h.writeUInt16LE(1, 22);
  h.writeUInt32LE(rate, 24);
  h.writeUInt32LE(rate * 2, 28);
  h.writeUInt16LE(2, 32);
  h.writeUInt16LE(16, 34);
  h.write('data', 36);
  h.writeUInt32LE(pcm.length, 40);
  return Buffer.concat([h, pcm]);
}
