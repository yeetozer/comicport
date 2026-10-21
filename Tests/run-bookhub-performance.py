"""Measure production Book Hub model operations using synthetic records.
Optionally create library.json in a new fixture directory for DEBUG Mac UI tests.
"""
from pathlib import Path
import argparse
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--fixture-directory', type=Path)
args = parser.parse_args()
if args.fixture_directory and (args.fixture_directory / 'library.json').exists():
    parser.error('The fixture directory already contains library.json; choose a new directory.')

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='comicport-performance-') as temp:
    temp = Path(temp)
    binary = temp / 'performance-checks'
    subprocess.run([
        'xcrun', 'swiftc', '-O', '-module-cache-path', str(temp / 'ModuleCache'),
        str(root / 'PanelReader/Models.swift'),
        str(root / 'Tests/BookHubPerformanceChecks.swift'), '-o', str(binary)
    ], check=True)
    command = [str(binary)]
    if args.fixture_directory:
        command.append(str(args.fixture_directory.resolve()))
    subprocess.run(command, check=True)
