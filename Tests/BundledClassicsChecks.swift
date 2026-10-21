import Foundation
import CryptoKit
@main struct BundledClassicsChecks {
 static func main() throws {
  let resources = URL(fileURLWithPath: CommandLine.arguments[1])
  let extracted = URL(fileURLWithPath: CommandLine.arguments[2])
  let fm=FileManager.default
  let temp=fm.temporaryDirectory.appendingPathComponent("classic-installer-"+UUID().uuidString)
  try fm.createDirectory(at:temp,withIntermediateDirectories:true)
  defer {try? fm.removeItem(at:temp)}
  let catalog=try BundledClassics.readCatalog(at:resources)
  precondition(catalog.count==10)
  let previousResources=temp.appendingPathComponent("previous-six")
  try fm.copyItem(at:resources,to:previousResources)
  let previousCatalog=try JSONSerialization.jsonObject(with:Data(contentsOf:resources.appendingPathComponent("catalog.json"))) as! [[String:Any]]
  try JSONSerialization.data(withJSONObject:Array(previousCatalog.prefix(6))).write(to:previousResources.appendingPathComponent("catalog.json"))
  let upgradeRoot=temp.appendingPathComponent("upgrade")
  var oldSix=try BundledClassics.install(in:upgradeRoot,existing:[],resources:previousResources)
  oldSix[0].currentPage=8; oldSix[0].readingStatus = .reading
  let upgraded=try BundledClassics.install(in:upgradeRoot,existing:oldSix,resources:resources)
  precondition(upgraded.count==10 && Array(upgraded.prefix(6))==oldSix)
  var personal=ComicBook(title:"Personal book",storedFileName:"personal.epub",type:.epub,pageCount:10,currentPage:4,contentKind:.book)
  personal.favorite=true
  let installed=try BundledClassics.install(in:temp,existing:[personal],resources:resources)
  precondition(installed.count==11 && installed[0]==personal)
  for entry in catalog {
   let book=installed.first{$0.id==entry.id}!
   precondition(book.bookMetadata?.authors==[entry.author] && book.bookMetadata?.language=="en")
   precondition(book.currentPage==0 && book.readingStatus == .toRead && !book.favorite)
   precondition(fm.fileExists(atPath:temp.appendingPathComponent("Books/"+book.storedFileName).path))
   let publication=try EPUBPackage.load(root:extracted.appendingPathComponent(entry.fileName))
   precondition(publication.chapters.count==entry.chapterCount && publication.metadata.title==entry.title)
   precondition(publication.coverURL != nil)
   var count=0
   for chapter in publication.chapters {
    let content=try EPUBPackage.content(at:chapter.fileURL,root:publication.root)
    precondition(!content.text.lowercased().contains("project gutenberg"))
    count += content.text.utf8.count
   }
   precondition(count>100_000)
  }
  var changed=installed
  changed[1].currentPage=3; changed[1].isArchived=true
  let repeatInstall=try BundledClassics.install(in:temp,existing:changed,resources:resources)
  precondition(repeatInstall==changed)
  let deleted=Array(changed.dropLast())
  let afterDelete = try BundledClassics.install(in:temp,existing:deleted,resources:resources)
  precondition(afterDelete==deleted)
  let duplicateRoot=temp.appendingPathComponent("duplicates")
  var imported=installed[1]; imported = ComicBook(title:imported.title,storedFileName:"existing.epub",type:.epub,pageCount:imported.pageCount,currentPage:2,contentKind:.book,bookMetadata:imported.bookMetadata)
  let deduplicated=try BundledClassics.install(in:duplicateRoot,existing:[imported],resources:resources)
  precondition(deduplicated.count==10 && deduplicated[0]==imported)
  let revisedResources=temp.appendingPathComponent("revision-resources")
  try fm.copyItem(at:resources,to:revisedResources)
  var entries=try JSONSerialization.jsonObject(with:Data(contentsOf:revisedResources.appendingPathComponent("catalog.json"))) as! [[String:Any]]
  var revision=try Data(contentsOf:resources.appendingPathComponent(catalog[0].fileName))
  revision.append(contentsOf:[0x0a])
  try revision.write(to:revisedResources.appendingPathComponent(catalog[0].fileName))
  entries[0]["replacesSHA256"]=[catalog[0].sha256]
  entries[0]["sha256"]=SHA256.hash(data:revision).map{String(format:"%02x",$0)}.joined()
  try JSONSerialization.data(withJSONObject:entries).write(to:revisedResources.appendingPathComponent("catalog.json"))
  let revisedBooks=try BundledClassics.install(in:temp,existing:installed,resources:revisedResources)
  precondition(revisedBooks==installed)
  let destination=temp.appendingPathComponent("Books/"+installed[1].storedFileName)
  let revisedData=try Data(contentsOf:destination)
  precondition(revisedData==revision)
  try Data("user changed this file".utf8).write(to:destination)
  _ = try BundledClassics.install(in:temp,existing:installed,resources:revisedResources)
  let userData=try Data(contentsOf:destination)
  precondition(userData==Data("user changed this file".utf8))
  let corruptRoot=temp.appendingPathComponent("corrupt-source")
  try fm.copyItem(at:resources,to:corruptRoot)
  try Data("not an EPUB".utf8).write(to:corruptRoot.appendingPathComponent(catalog[0].fileName))
  do { _ = try BundledClassics.install(in:temp.appendingPathComponent("corrupt-destination"),existing:[],resources:corruptRoot); preconditionFailure("Corrupt source accepted") }
  catch { }
  print("PASS: ten real EPUBs/chapter counts, full chapter parsing, embedded covers, checksums, first-run installation, no restart duplicates, personal-progress preservation, archive/delete receipts, restored/manual-import deduplication and corrupt-resource rejection")
 }
}
