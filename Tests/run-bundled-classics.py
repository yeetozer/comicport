from pathlib import Path
import subprocess,tempfile,zipfile,xml.etree.ElementTree as E,json,hashlib
root=Path(__file__).resolve().parent.parent
assets=root/'PanelReader/BundledClassics'
with tempfile.TemporaryDirectory(prefix='classic-check-') as folder:
 temp=Path(folder)
 for entry in json.loads((assets/'catalog.json').read_text()):
  file=assets/entry['fileName']
  assert hashlib.sha256(file.read_bytes()).hexdigest()==entry['sha256']
  with zipfile.ZipFile(file) as z:
   assert z.read('mimetype')==b'application/epub+zip'
   for n in z.namelist():
    assert '..' not in Path(n).parts and not n.startswith('/')
    if n.endswith(('.xhtml','.xml','.opf')):E.fromstring(z.read(n))
   z.extractall(temp/file.name)
 binary=temp/'classic-checks'
 subprocess.run(['xcrun','swiftc','-module-cache-path',str(temp/'modules'),str(root/'PanelReader/Models.swift'),str(root/'PanelReader/EPUBPackage.swift'),str(root/'PanelReader/BundledClassics.swift'),str(root/'Tests/BundledClassicsChecks.swift'),'-o',str(binary)],check=True)
 subprocess.run([str(binary),str(assets),str(temp)],check=True)
