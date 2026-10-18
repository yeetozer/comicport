import json, os, pathlib, subprocess, time

def run(*args, **kw):
    return subprocess.check_output(args, text=True, **kw).strip()

devices = json.loads(run('xcrun', 'simctl', 'list', 'devices', 'available', '--json'))['devices']
all_devices = [d for group in devices.values() for d in group if 'iPad' in d['name']]
small = next((d for d in all_devices if '11-inch' in d['name']), all_devices[0])
large = next((d for d in all_devices if '13-inch' in d['name'] and 'Pro' in d['name']), None)
output = pathlib.Path('screenshots'); output.mkdir(exist_ok=True)
manifest = []
for device in [small] + ([large] if large else []):
    udid = device['udid']
    run('xcrun','simctl','boot',udid)
    run('xcrun','simctl','bootstatus',udid,'-b')
    run('xcrun','simctl','status_bar',udid,'override','--time','9:41','--batteryLevel','100','--batteryState','charged','--wifiMode','active','--wifiBars','3')
    apps = list(pathlib.Path('build/Build/Products/Debug-iphonesimulator').glob('*.app'))
    if len(apps) != 1: raise RuntimeError(f'Expected one app product, got {apps}')
    run('xcrun','simctl','install',udid,str(apps[0]))
    container = pathlib.Path(run('xcrun','simctl','get_app_container',udid,'com.yeetozer.comicport','data'))
    docs = container / 'Documents'; docs.mkdir(exist_ok=True)
    samples = docs / 'ScreenshotSamples'; samples.mkdir(exist_ok=True)
    import shutil
    for src in pathlib.Path('samples').iterdir(): shutil.copy(src, samples / src.name)
    folder = output / device['name'].replace(' ','_').replace('/','-'); folder.mkdir(exist_ok=True)
    routes = ['empty','home','library','detail','preview','cbz','cbz-hidden','pdf','guided','settings','reader-settings','statistics','journal','series','achievements','import','characters','lists','notes','myPanels','smartSearch','readingOrder2','libraryHealth','libraryTools','smartCollections','sourcesSync','wrapped','history','saved','browse']
    for index, route in enumerate(routes,1):
        orientations = ['portrait']
        for orientation in orientations:
            if route == 'empty' and orientation == 'landscape': pass
            subprocess.run(['xcrun','simctl','terminate',udid,'com.yeetozer.comicport'],capture_output=True)
            marker = docs / 'screenshot-ready.txt'
            marker.unlink(missing_ok=True)
            env = os.environ.copy(); env.update(SIMCTL_CHILD_SCREENSHOT_ROUTE=route, SIMCTL_CHILD_SCREENSHOT_ORIENTATION=orientation)
            run('xcrun','simctl','launch',udid,'com.yeetozer.comicport',env=env)
            deadline = time.time()+180
            while not marker.exists() and time.time()<deadline: time.sleep(1)
            if not marker.exists():
                run('xcrun','simctl','io',udid,'screenshot',str(folder / 'failure.png'))
                subprocess.run(['xcrun','simctl','spawn',udid,'log','show','--last','5m','--style','compact','--predicate','process == "PanelReader"'],stdout=(folder/'failure.log').open('w'),stderr=subprocess.DEVNULL)
                raise RuntimeError(f'No ready marker: {route} {device["name"]}')
            status = marker.read_text()
            if route != 'empty' and 'books=2' not in status: raise RuntimeError(status)
            time.sleep(3)
            path = folder / f'{index:02}_{route}_{orientation}.png'
            run('xcrun','simctl','io',udid,'screenshot',str(path))
            manifest.append(dict(path=str(path),screen=f'{route} {orientation}',simulator=device['name'],status=status))
            (output/'manifest.json').write_text(json.dumps(manifest,indent=2))
    subprocess.run(['xcrun','simctl','spawn',udid,'log','show','--last','30m','--style','compact','--predicate','process == "ComicPort"'],stdout=(folder/'runtime.log').open('w'),stderr=subprocess.DEVNULL)
    run('xcrun','simctl','shutdown',udid)
