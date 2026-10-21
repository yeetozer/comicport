"""Build text-only EPUBs from ten locally saved, unmodified source HTML pages.
Usage: python3 Scripts/build_classics.py /path/to/source-pages
No network access; source HTML is retained separately for audit, not shipped.
"""
from pathlib import Path
from html.parser import HTMLParser
from html import escape
import re, json, hashlib, uuid, zipfile, sys

BOOKS = [
 (1342,'pride-and-prejudice','Pride and Prejudice','Jane Austen',1813,1817,'Romance','İlk izlenimler, toplumsal beklentiler ve Elizabeth Bennet ile Bay Darcy’nin hikâyesi.'),
 (84,'frankenstein','Frankenstein','Mary Shelley',1818,1851,'Gothic fiction','Yaratıcısı tarafından terk edilen bir varlığın aidiyet ve adalet arayışı.'),
 (345,'dracula','Dracula','Bram Stoker',1897,1912,'Gothic fiction','Günlükler ve mektuplarla anlatılan Kont Dracula’ya karşı mücadele.'),
 (1661,'sherlock-holmes','The Adventures of Sherlock Holmes','Arthur Conan Doyle',1892,1930,'Detective fiction','Sherlock Holmes ve Dr. Watson’dan on iki dedektiflik öyküsü.'),
 (11,'alice-in-wonderland',"Alice’s Adventures in Wonderland",'Lewis Carroll',1865,1898,'Fantasy','Alice’in tavşan deliğinden başlayıp mantığın sınırlarını zorlayan yolculuğu.'),
 (174,'dorian-gray','The Picture of Dorian Gray','Oscar Wilde',1891,1900,'Gothic fiction','Gençliğini koruyan Dorian Gray ile onun yerine değişen portresinin hikâyesi.'),
 (43,'jekyll-and-hyde','Dr. Jekyll and Mr. Hyde','Robert Louis Stevenson',1886,1894,'Gothic fiction','Londra sokaklarında başlayan bir soruşturma ve insan doğasının iki yüzü.'),
 (46,'a-christmas-carol','A Christmas Carol','Charles Dickens',1843,1870,'Fantasy','Scrooge’un geçmiş, bugün ve gelecekle yüzleştiği unutulmaz Noel gecesi.'),
 (120,'treasure-island','Treasure Island','Robert Louis Stevenson',1883,1894,'Adventure','Jim Hawkins’in bir hazine haritasıyla başlayan korsanlık ve cesaret yolculuğu.'),
 (35,'the-time-machine','The Time Machine','H. G. Wells',1895,1946,'Science fiction','Uzak geleceğe yolculuk eden bir mucidin insanlığın kaderiyle karşılaşması.'),
]
class Node:
 def __init__(self, tag, attrs=()): self.tag=tag; self.attrs=dict(attrs); self.children=[]
 def walk(self):
  yield self
  for c in self.children:
   if isinstance(c,Node): yield from c.walk()
 def text(self): return ''.join(c.text() if isinstance(c,Node) else c for c in self.children)
class Parser(HTMLParser):
 def __init__(self): super().__init__(convert_charrefs=True); self.root=Node('root'); self.stack=[self.root]
 def handle_starttag(self,tag,attrs):
  n=Node(tag,attrs); self.stack[-1].children.append(n)
  if tag not in {'img','br','hr','meta','link','input','source','wbr','base','area','embed','param','col'}: self.stack.append(n)
 def handle_endtag(self,tag):
  for i in range(len(self.stack)-1,0,-1):
   if self.stack[i].tag==tag: self.stack=self.stack[:i]; break
 def handle_data(self,data):self.stack[-1].children.append(data)

def clean(n):
 if isinstance(n,str): return escape(n)
 cls=n.attrs.get('class','').split()
 if n.tag in {'script','style','iframe','object','nav'} or any(c in cls for c in ['boxxx','pagenum','figcenter','figleft','figright','caption','illustration','figcaption']): return ''
 if n.attrs.get('id','').startswith('pg-'):return ''
 if n.tag=='img':
  alt=n.attrs.get('alt','')
  # Old illustrated editions put a paragraph's initial letter in an image.
  return escape(alt) if re.fullmatch(r'[“\"\']?[A-Za-z]',alt) else ''
 if n.tag=='hr':return ''
 if n.tag=='br':return '<br/>'
 tag=n.tag if n.tag in {'p','div','section','span','em','i','b','strong','h1','h2','h3','h4','blockquote','pre','sup','sub','ul','ol','li'} else 'span'
 # Preserve in-book anchors, while removing external links and publisher branding.
 attrs=' id="'+escape(n.attrs['id'],quote=True)+'"' if 'id' in n.attrs else ''
 return '<'+tag+attrs+'>'+''.join(clean(c) for c in n.children)+'</'+tag+'>'

def chapters(parser, pgid):
 nodes=list(parser.root.walk())
 if pgid==46:
  body=next(n for n in nodes if n.tag=='body')
  result=[]; current=[]; title=None
  children=[c for block in nodes if block.tag=='div' and block.attrs.get('class')=='book' for c in block.children]
  for n in children:
   if isinstance(n,Node) and n.tag=='h2' and n.text().strip().startswith('STAVE'):
    if title:result.append((title,''.join(clean(c) for c in current)))
    title=' '.join(n.text().split());current=[n];continue
   if isinstance(n,Node) and n.attrs.get('id','').startswith('pg-footer'):break
   if title:current.append(n)
  if title:result.append((title,''.join(clean(c) for c in current)))
  assert len(result)==5,len(result)
  return result
 if pgid==1342:
  body=next(n for n in nodes if n.tag=='body')
  result=[]; current=[]; title=None
  for n in body.children:
   if isinstance(n,Node) and n.tag=='h2':
    t=' '.join(n.text().split())
    match=re.search(r'CHAPTER\s*([IVXLCDM]+)',t,re.I)
    if match:
     if title:result.append((title,''.join(clean(c) for c in current)))
     title='Chapter '+match.group(1); current=[];continue
   if isinstance(n,Node) and n.attrs.get('id','').startswith('pg-footer'):break
   if title:current.append(n)
  if title:result.append((title,''.join(clean(c) for c in current)))
  assert len(result)==61, len(result)
  return result
 result=[]
 for n in nodes:
  if n.tag!='div' or 'chapter' not in n.attrs.get('class','').split():continue
  heading=next((c for c in n.walk() if c.tag=='h2'),None)
  if heading is None:continue
  title=' '.join(heading.text().split())
  if pgid==120 and not re.match(r'^[IVXLCDM]+\s',title):continue
  if title.lower() in {'contents','d r a c u l a','dracula'}:continue
  content=clean(n)
  if len(n.text().strip())<100:continue
  result.append((title,content))
 expected={84:28,345:28,1661:12,11:12,174:21,43:10,120:34,35:17}
 # Fail rather than silently ship incomplete/chapterless editions.
 assert len(result)==expected[pgid], (pgid,len(result),[t for t,_ in result])
 return result

def document(title,body):return '<?xml version="1.0" encoding="utf-8"?><html xmlns="http://www.w3.org/1999/xhtml" lang="en"><head><title>'+escape(title)+'</title></head><body>'+body+'</body></html>'

def build(source):
 out=Path(__file__).resolve().parents[1]/'PanelReader/BundledClassics';out.mkdir(parents=True,exist_ok=True)
 previous={b['id']:b for b in json.loads((out/'catalog.json').read_text())} if (out/'catalog.json').exists() else {}
 manifest=[]
 for pgid,slug,title,author,year,death,genre,summary in BOOKS:
  raw=(source/f'classic-{pgid}.html').read_bytes(); html=raw.decode('utf-8'); parser=Parser();parser.feed(html)
  assert 'Public domain' in html or 'United States' in html
  assert '*** START OF THE PROJECT GUTENBERG EBOOK' in parser.root.text()
  parts=chapters(parser,pgid)
  for _,body in parts: assert 'gutenberg' not in body.lower(), (pgid,'source wrapper remains')
  bookid=str(uuid.uuid5(uuid.NAMESPACE_URL,'https://comicport.local/classics/'+slug)).upper()
  names=[f'chapter-{i+1}.xhtml' for i in range(len(parts))]
  metadata=f'<meta property="dcterms:modified">2026-10-20T00:00:00Z</meta><dc:publisher>Book Hub Classics</dc:publisher><dc:identifier id="uid">urn:uuid:{bookid}</dc:identifier><dc:title>{escape(title)}</dc:title><dc:creator>{escape(author)}</dc:creator><dc:language>en</dc:language><dc:date>{year}</dc:date><dc:description>{escape(summary)}</dc:description>'
  items=''.join(f'<item id="c{i}" href="{name}" media-type="application/xhtml+xml"/>' for i,name in enumerate(names))
  spine=''.join(f'<itemref idref="c{i}"/>' for i in range(len(parts)))
  path=out/(slug+'.epub')
  with zipfile.ZipFile(path,'w',compression=zipfile.ZIP_DEFLATED) as z:
   z.writestr('mimetype','application/epub+zip',compress_type=zipfile.ZIP_STORED)
   z.writestr('META-INF/container.xml','<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="OPS/package.opf" media-type="application/oebps-package+xml"/></rootfiles></container>')
   z.writestr('OPS/package.opf','<package xmlns="http://www.idpf.org/2007/opf" xmlns:dc="http://purl.org/dc/elements/1.1/" version="3.0" unique-identifier="uid"><metadata>'+metadata+'</metadata><manifest>'+items+'<item id="cover" href="cover.png" media-type="image/png" properties="cover-image"/><item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/></manifest><spine>'+spine+'</spine></package>')
   z.writestr('OPS/cover.png',(out/(slug+'.png')).read_bytes())
   for name,(chapter,body) in zip(names,parts):z.writestr('OPS/'+name,document(chapter, ('<h2>'+escape(chapter)+'</h2>' if pgid==1342 else '')+body))
   nav='<nav xmlns:epub="http://www.idpf.org/2007/ops" epub:type="toc"><h1>Contents</h1><ol>'+''.join(f'<li><a href="{name}">{escape(t)}</a></li>' for name,(t,_) in zip(names,parts))+'</ol></nav>'
   z.writestr('OPS/nav.xhtml',document('Contents',nav))
  manifest.append(dict(id=bookid,title=title,author=author,year=str(year),authorDeathYear=death,genre=genre,summary=summary,fileName=path.name,coverFileName=slug+'.png',chapterCount=len(parts),sourceURL=f'https://www.gutenberg.org/ebooks/{pgid}',sourceHTMLSHA256=hashlib.sha256(raw).hexdigest(),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),rights='Original English text; public domain in the United States and Türkiye. Other release territories require review. New typographic covers; no source illustrations, publisher covers or modern translations included.'))
  old=previous.get(bookid,{})
  accepted=set(old.get('replacesSHA256',[]))
  if old.get('sha256') and old['sha256']!=manifest[-1]['sha256']:accepted.add(old['sha256'])
  manifest[-1]['replacesSHA256']=sorted(accepted)
  print(title,len(parts),path.stat().st_size)
 (out/'catalog.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
if __name__=='__main__':build(Path(sys.argv[1]))
