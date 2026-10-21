"""Verify Book Hub planning and the production backup payload with local fixtures."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='comicport-workspace-') as folder:
    temp = Path(folder)
    cache = temp / 'module-cache'
    def run(files, name):
        binary = temp / name
        subprocess.run(['xcrun', 'swiftc', '-module-cache-path', str(cache), *map(str, files), '-o', str(binary)], check=True)
        subprocess.run([str(binary)], check=True)
    run([root/'PanelReader/Models.swift', root/'Tests/BookHubWorkspaceChecks.swift'], 'workspace')
    artifacts = (root/'PanelReader/ReaderArtifacts.swift').read_text()
    series = (root/'PanelReader/SeriesSystem.swift').read_text()
    store = (root/'PanelReader/LibraryStore.swift').read_text()
    payload = (root/'PanelReader/PanelBackup.swift').read_text()
    source = 'import Foundation\n'
    source += artifacts[artifacts.index('struct PageTextNote'):artifacts.index('private final class PageSnapshotDataBox')]
    source += series[series.index('struct StoryArc:'):series.index('struct SeriesMissingIssue:')]
    source += store[store.index('enum ComicPortSmartFormat:'):store.index('enum ComicPortBuiltInCollection:')]
    source += payload[payload.index('struct BackupPencilDrawing:'):payload.index('struct PanelBackupRestoreResult')]
    extracted = temp/'BackupTypes.swift'
    extracted.write_text(source)
    run([root/'PanelReader/Models.swift', root/'PanelReader/AchievementSystem.swift', root/'PanelReader/ReaderSettings.swift', root/'PanelReader/ReadingJournal.swift', extracted, root/'Tests/BookHubBackupChecks.swift'], 'backup')
