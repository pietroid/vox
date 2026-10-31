"""Cut 'The call' section out of the design-system artifact and render it at phone width.
Usage: python3 code/shot_call.py  (from the topic folder; needs Google Chrome)"""
import re, subprocess, tempfile, os
src = open('data/vox-design-system.html').read()
head = src[:src.find('<div class="wrap">')] if '<div class="wrap">' in src else src[:src.find('<section>')]
i = src.find('<h2>The call</h2>'); start = src.rfind('<section', 0, i); end = src.find('</section>', i) + 10
fit = ('<style>.sub,.notes,.states p,section>h2{display:none!important}html,body{width:390px!important;overflow:hidden}.wrap{max-width:390px!important;margin:0!important;padding:16px!important}'
       '.states{display:grid!important;grid-template-columns:repeat(3,1fr)!important;gap:6px!important}'
       '.states>div{min-width:0!important;padding:8px 0!important}.states .pres{transform:scale(.7)}'
       '.call-wrap{display:block!important}.phone-col{width:100%}.phone{max-width:100%}</style>')
page = head + fit + '<div class="wrap" style="padding-block:24px">' + src[start:end] + '</div></body></html>'
with tempfile.NamedTemporaryFile('w', suffix='.html', delete=False) as f: f.write(page)
chrome = os.environ.get('CHROME', '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')
subprocess.run([chrome, '--headless=new', '--hide-scrollbars', '--force-device-scale-factor=2',
  '--virtual-time-budget=4000', '--window-size=390,950', '--screenshot=img/call-design.png',
  'file://' + f.name], check=True, capture_output=True)
print('img/call-design.png')
