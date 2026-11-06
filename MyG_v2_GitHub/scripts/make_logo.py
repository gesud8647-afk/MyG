"""Native geometric My G mark: an open G ring plus a signal dot."""
from pathlib import Path
from PIL import Image, ImageDraw
import json
root = Path(__file__).resolve().parent.parent
svg = '''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
<rect width="1024" height="1024" fill="#09121c"/>
<circle cx="512" cy="512" r="388" fill="none" stroke="#14382f" stroke-width="4"/>
<circle cx="512" cy="512" r="310" fill="none" stroke="#14382f" stroke-width="4"/>
<path d="M798 512 A286 286 0 1 1 696 294 M798 512 H536" fill="none" stroke="#5fffc6" stroke-width="70" stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="775" cy="263" r="37" fill="#ffffff"/>
<circle cx="775" cy="263" r="60" fill="none" stroke="#5fffc6" stroke-width="6"/>
</svg>'''
(root/'Brand/MyG-logo.svg').write_text(svg)
# Raster companion uses the same geometry, supersampled for small icons.
scale=3
im=Image.new('RGB',(1024*scale,1024*scale),'#09121c'); d=ImageDraw.Draw(im)
def ellipse(box, **kw): d.ellipse(tuple(int(x*scale) for x in box), **{k:(v*scale if k=='width' else v) for k,v in kw.items()})
for r in [388,310]: ellipse((512-r,512-r,512+r,512+r),outline='#14382f',width=4)
# G: long arc and horizontal bar to the middle.
d.arc((226*scale,226*scale,798*scale,798*scale),start=0,end=310,fill='#5fffc6',width=70*scale)
d.line((798*scale,512*scale,536*scale,512*scale),fill='#5fffc6',width=70*scale)
ellipse((501,477,571,547),fill='#5fffc6')
import math
x,y=512+286*math.cos(math.radians(310)),512+286*math.sin(math.radians(310))
ellipse((x-35,y-35,x+35,y+35),fill='#5fffc6')
ellipse((715,203,835,323),outline='#5fffc6',width=6)
ellipse((738,226,812,300),fill='white')
im=im.resize((1024,1024),Image.Resampling.LANCZOS)
im.save(root/'Brand/MyG-logo.png')
assets=root/'MyG/Assets.xcassets'
assets.mkdir(parents=True,exist_ok=True)
(assets/'Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}}))
for folder in ['AppIcon.appiconset','MyGLogo.imageset']:
 p=assets/folder;p.mkdir(exist_ok=True)
 if folder.startswith('AppIcon'):
  im.save(p/'AppIcon.png')
  spec={'images':[{'filename':'AppIcon.png','idiom':'universal','platform':'ios','size':'1024x1024'}],'info':{'author':'xcode','version':1}}
 else:
  im.resize((256,256),Image.Resampling.LANCZOS).save(p/'MyGLogo.png')
  spec={'images':[{'filename':'MyGLogo.png','idiom':'universal'}],'info':{'author':'xcode','version':1}}
 (p/'Contents.json').write_text(json.dumps(spec,indent=2))
print('Logo vettoriale e icona opaca 1024px creati.')
