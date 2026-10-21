"""Compile the production Foundation model and metadata scheduler without UIKit.
The queue probe replaces OCR only; scheduling code comes directly from production.
"""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix='comicport-bookhub-') as temp:
    temp = Path(temp)
    model_binary = temp / 'model-checks'
    subprocess.run(['xcrun', 'swiftc', '-module-cache-path', str(temp/'modules'), str(root/'PanelReader/Models.swift'), str(root/'PanelReader/AchievementSystem.swift'), str(root/'PanelReader/BookLookupService.swift'), str(root/'Tests/BookHubModelChecks.swift'), '-o', str(model_binary)], check=True)
    subprocess.run([str(model_binary)], check=True)
    epub_binary = temp / 'epub-checks'
    subprocess.run(['xcrun', 'swiftc', '-module-cache-path', str(temp/'modules'), str(root/'PanelReader/Models.swift'), str(root/'PanelReader/EPUBPackage.swift'), str(root/'Tests/EPUBPackageChecks.swift'), '-o', str(epub_binary)], check=True)
    subprocess.run([str(epub_binary)], check=True)
    workspace_binary = temp / 'workspace-checks'
    subprocess.run(['xcrun', 'swiftc', '-module-cache-path', str(temp/'modules'), str(root/'PanelReader/Models.swift'), str(root/'Tests/BookHubWorkspaceChecks.swift'), '-o', str(workspace_binary)], check=True)
    subprocess.run([str(workspace_binary)], check=True)
    source = (root/'PanelReader/BookInfoService.swift').read_text()
    actor_file = temp/'QueueActor.swift'
    actor_file.write_text('import Foundation\n'+source[source.index('actor BookMetadataIntelligence {'):])
    queue_binary = temp/'queue-checks'
    subprocess.run(['xcrun', 'swiftc', '-module-cache-path', str(temp/'modules'), str(root/'PanelReader/Models.swift'), str(actor_file), str(root/'Tests/BookHubQueueChecks.swift'), '-o', str(queue_binary)], check=True)
    subprocess.run([str(queue_binary), str(temp/'fixture.pdf')], check=True)
    source = (root/'PanelReader/CoverImageCache.swift').read_text()
    actor_file = temp/'CoverActor.swift'
    actor_file.write_text('import Foundation\n'+source[source.index('actor PanelCoverLoader {'):])
    cover_binary = temp/'cover-checks'
    subprocess.run(['xcrun', 'swiftc', '-module-cache-path', str(temp/'modules'), str(actor_file), str(root/'Tests/BookHubCoverQueueChecks.swift'), '-o', str(cover_binary)], check=True)
    subprocess.run([str(cover_binary)], check=True)
