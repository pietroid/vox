// A whole call against the real Deepgram and OpenRouter, with no phone:
// a WAV streamed in real time as the mic, the agent's voice written to a
// WAV, every message the phone would get printed with its time.
//
//   npm run build
//   node --env-file=.env.local scripts/voice-e2e.mjs take.wav [more.wav…]
//
// Takes play one after another, with 6 s of silence between them so the
// agent can answer (a long silence after a long talk ends the turn).
import { readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { VoiceSession } = require('../dist/assistant/voice/voice-session.js');
const { Deepgram } = require('../dist/assistant/voice/deepgram.js');
const { OpenRouterClient } = require('../dist/assistant/openrouter.client.js');

const takes = process.argv.slice(2);
const t0 = performance.now();
const at = () => ((performance.now() - t0) / 1000).toFixed(2).padStart(6);
const voice = [];
let audioAt;

const phone = {
  sendJson: (m) => {
    if (m.type === 'caption') console.log(at(), 'caption', JSON.stringify(m.text));
    else console.log(at(), m.type, m.state ?? '');
  },
  sendAudio: (pcm) => {
    if (audioAt === undefined) {
      audioAt = at();
      console.log(audioAt, '(first audio bytes)');
    }
    voice.push(pcm);
  },
  close: (code, reason) => console.log(at(), 'closed', code, reason),
};
const model = new OpenRouterClient({ get: (key) => process.env[key] });
const session = new VoiceSession(
  { id: 'e2e', email: 'e2e@vox', name: 'Ana Souza' },
  phone,
  new Deepgram(process.env.DEEPGRAM_API_KEY ?? ''),
  model,
  (line) => console.log(at(), '[log]', line),
);

const chunk = 2560; // 80 ms
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function stream(pcm) {
  for (let i = 0; i < pcm.length; i += chunk) {
    session.hear(pcm.subarray(i, i + chunk));
    await sleep(80);
  }
}

await stream(Buffer.alloc(chunk * 50)); // the greeting plays meanwhile
for (const take of takes) {
  const file = readFileSync(take);
  console.log(at(), `--- streaming ${take}`);
  await stream(file.subarray(file.indexOf('data') + 8));
  console.log(at(), '--- take ended, silence');
  await stream(Buffer.alloc(chunk * Math.round(25_000 / 80)));
}
session.hangUp();
const pcm = Buffer.concat(voice);
const header = Buffer.alloc(44);
header.write('RIFF', 0);
header.writeUInt32LE(36 + pcm.length, 4);
header.write('WAVEfmt ', 8);
header.writeUInt32LE(16, 16);
header.writeUInt16LE(1, 20);
header.writeUInt16LE(1, 22);
header.writeUInt32LE(24000, 24);
header.writeUInt32LE(48000, 28);
header.writeUInt16LE(2, 32);
header.writeUInt16LE(16, 34);
header.write('data', 36);
header.writeUInt32LE(pcm.length, 40);
writeFileSync('/tmp/vox-e2e-agent.wav', Buffer.concat([header, pcm]));
console.log(at(), `agent's voice: /tmp/vox-e2e-agent.wav, ${(pcm.length / 48000).toFixed(1)} s`);
setTimeout(() => process.exit(0), 2500);
