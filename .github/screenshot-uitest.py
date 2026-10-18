import json, pathlib, subprocess, shutil

def run(*args):
    return subprocess.check_output(args, text=True).strip()

devices = json.loads(run('xcrun','simctl','list','devices','available','--json'))['devices']
all_devices = [d for group in devices.values() for d in group if 'iPad' in d['name']]
device = next((d for d in all_devices if '11-inch' in d['name']), all_devices[0])
udid = device['udid']
run('xcrun','simctl','boot',udid)
run('xcrun','simctl','bootstatus',udid,'-b')
run('xcrun','simctl','status_bar',udid,'override','--time','9:41','--batteryLevel','100','--batteryState','charged')
app = next(pathlib.Path('build/Build/Products/Debug-iphonesimulator').glob('*.app'))
run('xcrun','simctl','install',udid,str(app))
container = pathlib.Path(run('xcrun','simctl','get_app_container',udid,'com.yeetozer.comicport','data'))
samples = container / 'Documents/ScreenshotSamples'; samples.mkdir(parents=True,exist_ok=True)
for src in pathlib.Path('samples').iterdir(): shutil.copy(src,samples / src.name)
result = subprocess.run(['xcodebuild','-project','PanelReader.xcodeproj','-scheme','Screenshots','-configuration','Debug','-destination',f'platform=iOS Simulator,id={udid}','-derivedDataPath','build','-resultBundlePath','screenshots.xcresult','CODE_SIGNING_ALLOWED=NO','CODE_SIGNING_REQUIRED=NO','SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG','test'],stdout=pathlib.Path('uitest.log').open('w'),stderr=subprocess.STDOUT)
output=pathlib.Path('screenshots'); output.mkdir(exist_ok=True)
run('xcrun','xcresulttool','export','attachments','--path','screenshots.xcresult','--output-path',str(output))
(output/'device.json').write_text(json.dumps(device,indent=2))
marker=container/'Documents/screenshot-ready.txt'
if marker.exists(): (output/'import-status.txt').write_text(marker.read_text())
subprocess.run(['xcrun','simctl','spawn',udid,'log','show','--last','40m','--style','compact','--predicate','process == "PanelReader"'],stdout=(output/'runtime.log').open('w'),stderr=subprocess.DEVNULL,timeout=120)
if result.returncode: raise SystemExit(result.returncode)
