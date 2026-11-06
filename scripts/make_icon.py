from pathlib import Path
from PIL import Image, ImageDraw
import json
r=Path(__file__).resolve().parent.parent
(r/'Brand').mkdir(exist_ok=True)
svg='''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><rect width="1024" height="1024" fill="#0b111c"/><circle cx="512" cy="512" r="382" fill="none" stroke="#254439" stroke-width="4"/><path d="M512 288 C330 286 260 478 294 650 C324 796 700 796 730 650 C764 478 694 286 512 288Z" fill="#8cf0bf"/><path d="M510 308 Q478 146 658 158 Q674 290 510 308Z" fill="#b9f7d3"/><ellipse cx="432" cy="528" rx="18" ry="28" fill="#102634"/><ellipse cx="592" cy="528" rx="18" ry="28" fill="#102634"/><path d="M482 604 Q512 634 542 604" fill="none" stroke="#102634" stroke-width="10" stroke-linecap="round"/><circle cx="780" cy="246" r="14" fill="#ffd28f"/></svg>'''
(r/'Brand/ECO-logo.svg').write_text(svg)
s=3
im=Image.new('RGB',(1024*s,1024*s),'#0b111c');d=ImageDraw.Draw(im)
def box(b): return tuple(round(v*s) for v in b)
d.ellipse(box((130,130,894,894)),outline='#254439',width=4*s)
# Lume silhouette: a soft seed with a leaf and a quiet smile.
d.ellipse(box((286,286,738,778)),fill='#8cf0bf')
d.ellipse(box((488,150,660,328)),fill='#b9f7d3')
for x in [432,592]: d.ellipse(box((x-18,500,x+18,556)),fill='#102634')
d.arc(box((482,580,542,626)),start=0,end=180,fill='#102634',width=9*s)
d.ellipse(box((766,232,794,260)),fill='#ffd28f')
im=im.resize((1024,1024),Image.Resampling.LANCZOS)
im.save(r/'Brand/ECO-icon.png')
a=r/'ECO/Assets.xcassets';a.mkdir(parents=True,exist_ok=True)
(a/'Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}}))
p=a/'AppIcon.appiconset';p.mkdir(exist_ok=True);im.save(p/'AppIcon.png')
(p/'Contents.json').write_text(json.dumps({'images':[{'filename':'AppIcon.png','idiom':'universal','platform':'ios','size':'1024x1024'}],'info':{'author':'xcode','version':1}},indent=2))
print('ECO: icona originale opaca 1024px e sorgente vettoriale creati.')
