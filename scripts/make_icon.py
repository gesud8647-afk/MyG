from pathlib import Path
from PIL import Image, ImageDraw
import json
r=Path(__file__).resolve().parent.parent
s=3
im=Image.new('RGB',(1024*s,1024*s),'#09101d');d=ImageDraw.Draw(im)
def box(b):return tuple(int(v*s) for v in b)
d.rounded_rectangle(box((205,205,819,819)),radius=90*s,outline='#68ffcc',width=26*s)
for v in [340,455,570,685]:
 for a,b in [((v,135),(v,205)),((v,819),(v,889)),((135,v),(205,v)),((819,v),(889,v))]:
  d.line(box((*a,*b)),fill='#68ffcc',width=20*s)
d.line(box((335,402,442,509,335,616)),fill='white',width=35*s)
d.line(box((515,620,685,620)),fill='#68ffcc',width=35*s)
im=im.resize((1024,1024),Image.Resampling.LANCZOS)
a=r/'PocketAI/Assets.xcassets';a.mkdir(parents=True,exist_ok=True)
(a/'Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}}))
p=a/'AppIcon.appiconset';p.mkdir(exist_ok=True);im.save(p/'AppIcon.png')
(p/'Contents.json').write_text(json.dumps({'images':[{'filename':'AppIcon.png','idiom':'universal','platform':'ios','size':'1024x1024'}],'info':{'author':'xcode','version':1}},indent=2))
