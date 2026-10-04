import SwiftUI
import Foundation

struct ComicFact: Identifiable, Hashable {
    let id: String
    let category: String
    let text: String
}

enum ComicFactCatalog {
    static let all: [ComicFact] = [
        ComicFact(id: "fact-001", category: "DC", text: "Superman ilk kez 1938'de Action Comics #1'de göründü."),
        ComicFact(id: "fact-002", category: "DC", text: "Superman'i Jerry Siegel ve Joe Shuster yarattı."),
        ComicFact(id: "fact-003", category: "DC", text: "Superman'in gazeteci kimliği Clark Kent'tir."),
        ComicFact(id: "fact-004", category: "DC", text: "Action Comics #1, süper kahraman çizgi roman çağının en önemli başlangıç noktalarından biri kabul edilir."),
        ComicFact(id: "fact-005", category: "DC", text: "Batman ilk kez 1939'da Detective Comics #27'de göründü."),
        ComicFact(id: "fact-006", category: "DC", text: "Batman'in ilk yayımlanan hikâyesi yalnızca altı sayfaydı."),
        ComicFact(id: "fact-007", category: "DC", text: "Bruce Wayne'in anne ve babasının öldürülmesiyle ilgili köken hikâyesi Batman'in çıkışından aylar sonra anlatıldı."),
        ComicFact(id: "fact-008", category: "DC", text: "Joker ve Catwoman, Batman #1'de Batman'in erken dönem düşmanları olarak yer aldı."),
        ComicFact(id: "fact-009", category: "DC", text: "Wonder Woman ilk kez 1941'de All Star Comics #8'de göründü."),
        ComicFact(id: "fact-010", category: "DC", text: "Wonder Woman'ın yaratıcıları arasında William Moulton Marston ve sanatçı H. G. Peter bulunur."),
        ComicFact(id: "fact-011", category: "DC", text: "Wonder Woman'ın kendi solo serisi 1942'de başladı."),
        ComicFact(id: "fact-012", category: "DC", text: "Wonder Woman Day, karakterin ilk görünümünün yıldönümü olan 21 Ekim'de kutlanır."),
        ComicFact(id: "fact-013", category: "DC", text: "Robin'in Dick Grayson versiyonu 1940'ta Detective Comics #38'de tanıtıldı."),
        ComicFact(id: "fact-014", category: "DC", text: "Robin, süper kahraman çizgi romanlarında genç yardımcı karakter modelini popülerleştiren isimlerden biridir."),
        ComicFact(id: "fact-015", category: "DC", text: "Dick Grayson, Batman'in ilk uzun soluklu Robin'idir."),
        ComicFact(id: "fact-016", category: "DC", text: "Robin adı yıllar içinde Jason Todd, Tim Drake ve Damian Wayne gibi farklı karakterler tarafından da kullanıldı."),
        ComicFact(id: "fact-017", category: "DC", text: "Dick Grayson, Nightwing kimliğini 1984'te Tales of the Teen Titans #44'te benimsedi."),
        ComicFact(id: "fact-018", category: "DC", text: "Nightwing adı Dick Grayson'ın Batman'in gölgesinden çıkışının sembollerinden biri haline geldi."),
        ComicFact(id: "fact-019", category: "DC", text: "Blüdhaven, Nightwing solo hikâyeleriyle güçlü biçimde özdeşleşen şehirdir."),
        ComicFact(id: "fact-020", category: "DC", text: "Nightwing'in akrobatik geçmişi, karakterin dövüş ve hareket tarzının temel parçalarından biridir."),
        ComicFact(id: "fact-021", category: "DC", text: "Barry Allen'ın Flash versiyonu 1956'da Showcase #4'te tanıtıldı."),
        ComicFact(id: "fact-022", category: "DC", text: "Showcase #4 sık sık DC'nin Silver Age döneminin başlangıç işaretlerinden biri olarak gösterilir."),
        ComicFact(id: "fact-023", category: "DC", text: "Jay Garrick, Barry Allen'dan önceki Golden Age Flash'idir."),
        ComicFact(id: "fact-024", category: "DC", text: "Speed Force kavramı Flash mitolojisinin modern dönemindeki temel fikirlerden biridir."),
        ComicFact(id: "fact-025", category: "DC", text: "Hal Jordan ilk kez 1959'da Showcase #22'de Green Lantern olarak göründü."),
        ComicFact(id: "fact-026", category: "DC", text: "Green Lantern yüzükleri irade gücü fikriyle özdeşleşmiştir."),
        ComicFact(id: "fact-027", category: "DC", text: "Green Lantern Corps, tek bir kahramandan çok evrensel ölçekte çalışan bir teşkilattır."),
        ComicFact(id: "fact-028", category: "DC", text: "Alan Scott, Hal Jordan'dan yıllar önce 1940'ta Green Lantern adını kullanan kahramandı."),
        ComicFact(id: "fact-029", category: "DC", text: "Aquaman ilk kez 1941'de More Fun Comics #73'te göründü."),
        ComicFact(id: "fact-030", category: "DC", text: "Aquaman uzun yıllar Atlantis'in kralı ve yüzey dünyasıyla denizler arasında bir köprü olarak işlendi."),
        ComicFact(id: "fact-031", category: "DC", text: "Arthur Curry, Aquaman'in en bilinen sivil adıdır."),
        ComicFact(id: "fact-032", category: "DC", text: "More Fun Comics #73 aynı zamanda Green Arrow'un da ilk görünümünü içerir."),
        ComicFact(id: "fact-033", category: "DC", text: "Green Arrow ilk kez 1941'de More Fun Comics #73'te göründü."),
        ComicFact(id: "fact-034", category: "DC", text: "Oliver Queen, Green Arrow'un en bilinen kimliğidir."),
        ComicFact(id: "fact-035", category: "DC", text: "Green Arrow hikâyeleri zaman zaman sosyal ve politik meseleleri diğer süper kahraman serilerinden daha doğrudan ele aldı."),
        ComicFact(id: "fact-036", category: "DC", text: "Denny O'Neil ve Neal Adams'ın Green Lantern/Green Arrow dönemi bu sosyal yaklaşımın ünlü örneklerindendir."),
        ComicFact(id: "fact-037", category: "DC", text: "Justice Society of America, 1940'taki All Star Comics #3 ile çizgi roman tarihinin en erken süper kahraman takımlarından biri oldu."),
        ComicFact(id: "fact-038", category: "DC", text: "Justice Society, Golden Age DC kahramanlarını tek çatı altında buluşturdu."),
        ComicFact(id: "fact-039", category: "DC", text: "JSA kavramı daha sonra DC'nin kuşaklar arası kahraman mirasının temel parçalarından biri oldu."),
        ComicFact(id: "fact-040", category: "DC", text: "Earth-Two fikri, Golden Age kahramanlarının modern DC evreninde yaşamaya devam etmesine yardımcı oldu."),
        ComicFact(id: "fact-041", category: "DC", text: "Justice League ilk kez 1960'ta The Brave and the Bold #28'de bir araya geldi."),
        ComicFact(id: "fact-042", category: "DC", text: "Justice League'in erken kadrosunda Superman, Batman, Wonder Woman, Flash, Green Lantern, Aquaman ve Martian Manhunter bulunuyordu."),
        ComicFact(id: "fact-043", category: "DC", text: "Justice League of America kendi serisine 1960'ta kavuştu."),
        ComicFact(id: "fact-044", category: "DC", text: "Justice League hikâyeleri DC'nin farklı solo serilerini ortak olaylarda birleştiren başlıca merkezlerden biridir."),
        ComicFact(id: "fact-045", category: "DC", text: "Teen Titans'ın kökleri Robin, Kid Flash ve Aqualad'ın ortak maceralarına uzanır."),
        ComicFact(id: "fact-046", category: "DC", text: "Teen Titans adı 1960'ların ortasında takımın kalıcı kimliği haline geldi."),
        ComicFact(id: "fact-047", category: "DC", text: "Marv Wolfman ve George Pérez'in The New Teen Titans serisi 1980'lerde takımın popülerliğini büyük ölçüde artırdı."),
        ComicFact(id: "fact-048", category: "DC", text: "Raven, Starfire ve Cyborg gibi karakterler New Teen Titans döneminin simge isimleri oldu."),
        ComicFact(id: "fact-049", category: "DC", text: "Swamp Thing'in ilk versiyonu 1971'de House of Secrets #92'de ortaya çıktı."),
        ComicFact(id: "fact-050", category: "DC", text: "Len Wein ve Bernie Wrightson, Swamp Thing'in yaratıcıları arasındadır."),
        ComicFact(id: "fact-051", category: "DC", text: "Alan Moore'un 1980'lerdeki Swamp Thing dönemi karakterin korku ve felsefe yönünü önemli ölçüde genişletti."),
        ComicFact(id: "fact-052", category: "DC", text: "Swamp Thing hikâyeleri DC'nin doğaüstü tarafının gelişmesinde etkili oldu."),
        ComicFact(id: "fact-053", category: "DC", text: "Harley Quinn ilk olarak 1992'de Batman: The Animated Series için yaratıldı."),
        ComicFact(id: "fact-054", category: "DC", text: "Harley Quinn'in yaratıcıları Paul Dini ve Bruce Timm'dir."),
        ComicFact(id: "fact-055", category: "DC", text: "Harley'nin DC çizgi roman evrenindeki erken önemli görünümü The Batman Adventures #12'dir."),
        ComicFact(id: "fact-056", category: "DC", text: "Harley Quinn, çizgi roman dışındaki bir medyada doğup daha sonra ana çizgi roman evrenine geçen en başarılı DC karakterlerinden biridir."),
        ComicFact(id: "fact-057", category: "DC", text: "John Constantine ilk kez 1985'te Swamp Thing #37'de tam olarak tanıtıldı."),
        ComicFact(id: "fact-058", category: "DC", text: "Constantine, büyüyü süper kahraman gücünden çok tehlikeli bir araç gibi kullanan karakterlerden biridir."),
        ComicFact(id: "fact-059", category: "DC", text: "Hellblazer, Constantine ile özdeşleşen en uzun soluklu serilerden biridir."),
        ComicFact(id: "fact-060", category: "DC", text: "Constantine'in görünümünün Sting'den esinlendiği yaratıcı ekip tarafından yıllarca anlatılmıştır."),
        ComicFact(id: "fact-061", category: "DC", text: "Neil Gaiman'ın The Sandman serisi 1989'da başladı."),
        ComicFact(id: "fact-062", category: "DC", text: "The Sandman'in merkezindeki Dream, Endless adlı kozmik kardeşler grubunun bir üyesidir."),
        ComicFact(id: "fact-063", category: "DC", text: "The Sandman süper kahraman çizgi romanı, mitoloji, korku ve edebiyatı aynı yapıda harmanlamasıyla tanınır."),
        ComicFact(id: "fact-064", category: "DC", text: "The Sandman, Vertigo döneminin en etkili uzun soluklu serilerinden biri haline geldi."),
        ComicFact(id: "fact-065", category: "DC", text: "Watchmen 1986-1987 arasında 12 sayı olarak yayımlandı."),
        ComicFact(id: "fact-066", category: "DC", text: "Watchmen'i Alan Moore yazdı ve Dave Gibbons çizdi."),
        ComicFact(id: "fact-067", category: "DC", text: "Watchmen'in renkleri John Higgins tarafından hazırlandı."),
        ComicFact(id: "fact-068", category: "DC", text: "Watchmen dokuz panelli sayfa düzenini tekrar eden görsel ritimler için sık sık kullanmasıyla ünlüdür."),
        ComicFact(id: "fact-069", category: "DC", text: "The Dark Knight Returns 1986'da dört bölümlük bir seri olarak yayımlandı."),
        ComicFact(id: "fact-070", category: "DC", text: "Frank Miller, The Dark Knight Returns'ün yazarı ve başlıca çizeridir."),
        ComicFact(id: "fact-071", category: "DC", text: "Klaus Janson'ın mürekkepleri ve Lynn Varley'nin renkleri eserin görsel kimliğinin önemli parçalarıdır."),
        ComicFact(id: "fact-072", category: "DC", text: "The Dark Knight Returns yaşlanmış bir Bruce Wayne üzerinden Batman mitini yeniden yorumladı."),
        ComicFact(id: "fact-073", category: "DC", text: "Batman: Year One, Batman #404-407 arasında 1987'de yayımlandı."),
        ComicFact(id: "fact-074", category: "DC", text: "Batman: Year One'ı Frank Miller yazdı ve David Mazzucchelli çizdi."),
        ComicFact(id: "fact-075", category: "DC", text: "Year One, Bruce Wayne kadar Jim Gordon'ın Gotham'a gelişine de odaklanır."),
        ComicFact(id: "fact-076", category: "DC", text: "Batman: Year One modern Batman köken anlatılarının en etkili örneklerinden biri kabul edilir."),
        ComicFact(id: "fact-077", category: "DC", text: "Kingdom Come 1996'da dört sayılık bir mini seri olarak yayımlandı."),
        ComicFact(id: "fact-078", category: "DC", text: "Kingdom Come'u Mark Waid yazdı ve Alex Ross resimledi."),
        ComicFact(id: "fact-079", category: "DC", text: "Kingdom Come, klasik kahramanlarla yeni ve daha sert kuşak arasındaki çatışmayı işler."),
        ComicFact(id: "fact-080", category: "DC", text: "Alex Ross'un boyalı sayfaları Kingdom Come'un ayırt edici görsel özelliklerinden biridir."),
        ComicFact(id: "fact-081", category: "DC", text: "Crisis on Infinite Earths 1985-1986 arasında 12 sayı yayımlandı."),
        ComicFact(id: "fact-082", category: "DC", text: "Crisis on Infinite Earths'ü Marv Wolfman yazdı ve George Pérez çizdi."),
        ComicFact(id: "fact-083", category: "DC", text: "Seri, DC'nin çoklu evren sürekliliğini büyük ölçekte yeniden düzenlemek amacıyla tasarlandı."),
        ComicFact(id: "fact-084", category: "DC", text: "Crisis on Infinite Earths, şirket çapında crossover event modelinin en etkili örneklerinden biridir."),
        ComicFact(id: "fact-085", category: "DC", text: "Flashpoint 2011'de beş sayılık ana seri olarak yayımlandı."),
        ComicFact(id: "fact-086", category: "DC", text: "Flashpoint'in yazarı Geoff Johns, ana seri çizeri Andy Kubert'tir."),
        ComicFact(id: "fact-087", category: "DC", text: "Flashpoint, Barry Allen'ın değişmiş bir zaman çizgisinde uyandığı bir hikâyedir."),
        ComicFact(id: "fact-088", category: "DC", text: "Flashpoint sonrasında DC'nin New 52 yayın dönemi başladı."),
        ComicFact(id: "fact-089", category: "DC", text: "DC'nin New 52 hamlesi 2011'de çok sayıda seriyi yeni #1 sayılarıyla yeniden başlattı."),
        ComicFact(id: "fact-090", category: "DC", text: "New 52 döneminde DC'nin ana süper kahraman çizgisi 52 başlık fikriyle tanıtıldı."),
        ComicFact(id: "fact-091", category: "DC", text: "New 52 bazı karakterlerin geçmişini sadeleştirirken bazılarını büyük ölçüde yeniden tasarladı."),
        ComicFact(id: "fact-092", category: "DC", text: "New 52 dönemi 2016'daki Rebirth hamlesine kadar DC yayın kimliğinin merkezinde kaldı."),
        ComicFact(id: "fact-093", category: "DC", text: "DC Rebirth 2016'da DC Universe: Rebirth #1 ile başladı."),
        ComicFact(id: "fact-094", category: "DC", text: "Rebirth hamlesi yeni süreklilik fikirlerini klasik DC mirasıyla yeniden birleştirmeyi amaçladı."),
        ComicFact(id: "fact-095", category: "DC", text: "DC Universe: Rebirth #1'in yazarı Geoff Johns'tur."),
        ComicFact(id: "fact-096", category: "DC", text: "Rebirth sonrasında Batman, Superman, Wonder Woman, Flash ve Nightwing gibi birçok seri yeni yaratıcı dönemlere girdi."),
        ComicFact(id: "fact-097", category: "DC", text: "Vertigo etiketi DC tarafından 1993'te yetişkin okurlara yönelik içerikler için başlatıldı."),
        ComicFact(id: "fact-098", category: "DC", text: "Karen Berger, Vertigo'nun oluşumunda en önemli editoryal isimlerden biridir."),
        ComicFact(id: "fact-099", category: "DC", text: "The Sandman, Hellblazer ve Swamp Thing gibi eserler Vertigo kimliğiyle güçlü biçimde ilişkilidir."),
        ComicFact(id: "fact-100", category: "DC", text: "Vertigo, yaratıcı odaklı ve tür çeşitliliği yüksek Amerikan çizgi romanlarının yaygınlaşmasında önemli rol oynadı."),
        ComicFact(id: "fact-101", category: "Marvel", text: "Marvel'ın kökleri 1939'da yayımlanan Marvel Comics #1 ve Timely Comics dönemine uzanır."),
        ComicFact(id: "fact-102", category: "Marvel", text: "Marvel Comics #1, Human Torch ve Namor gibi erken dönem karakterleri içeriyordu."),
        ComicFact(id: "fact-103", category: "Marvel", text: "Timely Comics adı 1940'larda Marvel'ın öncül şirket kimliklerinden biriydi."),
        ComicFact(id: "fact-104", category: "Marvel", text: "Marvel adı 1960'larda şirketin süper kahraman yayın kimliğiyle kalıcı biçimde özdeşleşti."),
        ComicFact(id: "fact-105", category: "Marvel", text: "Captain America ilk kez 1941 tarihli Captain America Comics #1'de göründü."),
        ComicFact(id: "fact-106", category: "Marvel", text: "Captain America'yı Joe Simon ve Jack Kirby yarattı."),
        ComicFact(id: "fact-107", category: "Marvel", text: "Captain America Comics #1'in kapağında kahraman Adolf Hitler'e yumruk atarken resmedildi."),
        ComicFact(id: "fact-108", category: "Marvel", text: "Steve Rogers, Captain America'nın en bilinen sivil kimliğidir."),
        ComicFact(id: "fact-109", category: "Marvel", text: "Fantastic Four #1 1961'de yayımlandı ve Marvel'ın Silver Age süper kahraman döneminin temel taşlarından biri oldu."),
        ComicFact(id: "fact-110", category: "Marvel", text: "Fantastic Four'u Stan Lee ve Jack Kirby yarattı."),
        ComicFact(id: "fact-111", category: "Marvel", text: "Fantastic Four üyeleri güç kazansalar da aile içi tartışmalarını ve kişisel sorunlarını kaybetmeyen kahramanlar olarak tasarlandı."),
        ComicFact(id: "fact-112", category: "Marvel", text: "Baxter Building uzun yıllar Fantastic Four ile özdeşleşen merkezlerden biri oldu."),
        ComicFact(id: "fact-113", category: "Marvel", text: "Spider-Man ilk kez 1962'de Amazing Fantasy #15'te göründü."),
        ComicFact(id: "fact-114", category: "Marvel", text: "Spider-Man'in yaratıcıları Stan Lee ve Steve Ditko'dur."),
        ComicFact(id: "fact-115", category: "Marvel", text: "Peter Parker'ın genç yaşta para, okul, iş ve aile sorunları yaşaması karakterin erken dönem ayırt edici özelliklerinden biri oldu."),
        ComicFact(id: "fact-116", category: "Marvel", text: "Amazing Spider-Man solo serisi 1963'te başladı."),
        ComicFact(id: "fact-117", category: "Marvel", text: "Hulk ilk kez 1962'de The Incredible Hulk #1'de göründü."),
        ComicFact(id: "fact-118", category: "Marvel", text: "Bruce Banner'ın Hulk'a dönüşümü Marvel'ın bilimkurgu ve canavar çizgi romanı mirasını süper kahraman türüyle birleştirdi."),
        ComicFact(id: "fact-119", category: "Marvel", text: "Hulk'un rengi ilk sayıda gridir; kısa süre sonra baskı nedenleriyle yeşil renk kalıcı hale geldi."),
        ComicFact(id: "fact-120", category: "Marvel", text: "Hulk yıllar içinde hem Avengers hem Defenders gibi farklı takımlarla bağlantı kurdu."),
        ComicFact(id: "fact-121", category: "Marvel", text: "Thor'un Marvel versiyonu 1962'de Journey into Mystery #83'te tanıtıldı."),
        ComicFact(id: "fact-122", category: "Marvel", text: "Thor'un erken Marvel maceralarında Stan Lee, Larry Lieber ve Jack Kirby önemli yaratıcı rollere sahipti."),
        ComicFact(id: "fact-123", category: "Marvel", text: "Mjolnir, Thor çizgi romanlarının en tanınan sembollerinden biridir."),
        ComicFact(id: "fact-124", category: "Marvel", text: "Walt Simonson'ın 1980'lerdeki Thor dönemi Beta Ray Bill gibi kalıcı karakterler ekledi."),
        ComicFact(id: "fact-125", category: "Marvel", text: "Iron Man ilk kez 1963'te Tales of Suspense #39'da göründü."),
        ComicFact(id: "fact-126", category: "Marvel", text: "Tony Stark'ın ilk zırhı hantal ve gri bir tasarıma sahipti."),
        ComicFact(id: "fact-127", category: "Marvel", text: "Iron Man'in zırhları teknoloji ilerledikçe çizgi romanlarda sürekli değişen görsel bir tasarım alanı oluşturdu."),
        ComicFact(id: "fact-128", category: "Marvel", text: "Iron Man Avengers'ın kurucu kadrosunun önemli üyelerinden biridir."),
        ComicFact(id: "fact-129", category: "Marvel", text: "X-Men #1 1963'te yayımlandı."),
        ComicFact(id: "fact-130", category: "Marvel", text: "X-Men'i Stan Lee ve Jack Kirby yarattı."),
        ComicFact(id: "fact-131", category: "Marvel", text: "Mutant kavramı Marvel'a aynı evrende çok sayıda farklı güçte karakter yaratmak için esnek bir yapı sağladı."),
        ComicFact(id: "fact-132", category: "Marvel", text: "1975'te Giant-Size X-Men #1 takıma Wolverine, Storm, Nightcrawler ve Colossus gibi önemli isimleri taşıdı."),
        ComicFact(id: "fact-133", category: "Marvel", text: "Avengers #1 1963'te yayımlandı."),
        ComicFact(id: "fact-134", category: "Marvel", text: "Avengers'ın ilk kadrosunda Iron Man, Thor, Hulk, Ant-Man ve Wasp bulunuyordu."),
        ComicFact(id: "fact-135", category: "Marvel", text: "Captain America Avengers #4'te modern Marvel evrenine geri döndü."),
        ComicFact(id: "fact-136", category: "Marvel", text: "'Avengers Assemble!' takımın en tanınan sloganlarından biri haline geldi."),
        ComicFact(id: "fact-137", category: "Marvel", text: "Daredevil #1 1964'te yayımlandı."),
        ComicFact(id: "fact-138", category: "Marvel", text: "Matt Murdock görme duyusunu kaybettikten sonra diğer duyuları olağanüstü derecede keskinleşen bir kahramandır."),
        ComicFact(id: "fact-139", category: "Marvel", text: "Daredevil hem avukat hem gece kahramanı kimliği üzerinden suç ve adalet temalarını işler."),
        ComicFact(id: "fact-140", category: "Marvel", text: "Frank Miller'ın Daredevil dönemi Elektra ve The Hand gibi unsurları serinin merkezine taşıdı."),
        ComicFact(id: "fact-141", category: "Marvel", text: "Black Panther ilk kez 1966'da Fantastic Four #52'de göründü."),
        ComicFact(id: "fact-142", category: "Marvel", text: "T'Challa, kurgusal Afrika ülkesi Wakanda'nın kralı ve koruyucusudur."),
        ComicFact(id: "fact-143", category: "Marvel", text: "Black Panther, ana akım Amerikan süper kahraman çizgi romanlarındaki en önemli siyah kahramanlardan biri oldu."),
        ComicFact(id: "fact-144", category: "Marvel", text: "Vibranium, Wakanda mitolojisinin temel kurgusal kaynaklarından biridir."),
        ComicFact(id: "fact-145", category: "Marvel", text: "Silver Surfer ilk kez 1966'da Fantastic Four #48'de göründü."),
        ComicFact(id: "fact-146", category: "Marvel", text: "Silver Surfer'ı Jack Kirby tasarladı."),
        ComicFact(id: "fact-147", category: "Marvel", text: "Silver Surfer Galactus'un habercisi olarak tanıtıldı."),
        ComicFact(id: "fact-148", category: "Marvel", text: "Norrin Radd, Silver Surfer'ın en bilinen gerçek adıdır."),
        ComicFact(id: "fact-149", category: "Marvel", text: "Wolverine'in kısa tanıtımı The Incredible Hulk #180'de, büyük ilk görünümü ise #181'de gerçekleşti."),
        ComicFact(id: "fact-150", category: "Marvel", text: "Wolverine 1975'te Giant-Size X-Men #1 ile X-Men'in yeni kadrosuna katıldı."),
        ComicFact(id: "fact-151", category: "Marvel", text: "Logan adı Wolverine ile en çok özdeşleşen adlardan biridir."),
        ComicFact(id: "fact-152", category: "Marvel", text: "Adamantium kaplı iskelet ve iyileşme faktörü Wolverine'in en bilinen özellikleridir."),
        ComicFact(id: "fact-153", category: "Marvel", text: "Punisher ilk kez 1974'te The Amazing Spider-Man #129'da göründü."),
        ComicFact(id: "fact-154", category: "Marvel", text: "Punisher başlangıçta Spider-Man'e karşı kullanılan bir anti-kahraman figürüydü."),
        ComicFact(id: "fact-155", category: "Marvel", text: "Frank Castle, Punisher'ın sivil kimliğidir."),
        ComicFact(id: "fact-156", category: "Marvel", text: "Punisher'ın göğsündeki kafatası logosu çizgi roman dünyasının en kolay tanınan sembollerinden biri oldu."),
        ComicFact(id: "fact-157", category: "Marvel", text: "Moon Knight ilk kez 1975'te Werewolf by Night #32'de göründü."),
        ComicFact(id: "fact-158", category: "Marvel", text: "Moon Knight başlangıçta Werewolf by Night'ın karşısına çıkan bir paralı asker olarak tasarlandı."),
        ComicFact(id: "fact-159", category: "Marvel", text: "Marc Spector, Moon Knight ile ilişkilendirilen temel kimliklerden biridir."),
        ComicFact(id: "fact-160", category: "Marvel", text: "Moon Knight serileri suç, mistisizm ve psikolojik anlatıyı farklı oranlarda birleştirir."),
        ComicFact(id: "fact-161", category: "Marvel", text: "Deadpool ilk kez 1991'de The New Mutants #98'de göründü."),
        ComicFact(id: "fact-162", category: "Marvel", text: "Deadpool'u Rob Liefeld ve Fabian Nicieza yarattı."),
        ComicFact(id: "fact-163", category: "Marvel", text: "Wade Wilson, Deadpool'un en bilinen gerçek adıdır."),
        ComicFact(id: "fact-164", category: "Marvel", text: "Deadpool'un dördüncü duvarı kıran mizahı karakterin ilerleyen yıllardaki temel özelliklerinden biri oldu."),
        ComicFact(id: "fact-165", category: "Marvel", text: "Venom'un Eddie Brock versiyonu tam olarak 1988'de The Amazing Spider-Man #300'de ortaya çıktı."),
        ComicFact(id: "fact-166", category: "Marvel", text: "Uzaylı symbiote, Eddie Brock'tan önce Spider-Man'in siyah kostümüyle bağlantılıydı."),
        ComicFact(id: "fact-167", category: "Marvel", text: "Venom yıllar içinde Spider-Man düşmanlığından anti-kahramanlığa doğru değişen roller üstlendi."),
        ComicFact(id: "fact-168", category: "Marvel", text: "Symbiote mitolojisi daha sonra Carnage ve Knull gibi karakterlerle büyük ölçüde genişledi."),
        ComicFact(id: "fact-169", category: "Marvel", text: "Miles Morales ilk kez 2011'de Ultimate Fallout #4'te göründü."),
        ComicFact(id: "fact-170", category: "Marvel", text: "Miles Morales'i Brian Michael Bendis ve Sara Pichelli yarattı."),
        ComicFact(id: "fact-171", category: "Marvel", text: "Miles ilk olarak Ultimate Universe içinde Spider-Man kimliğini devraldı."),
        ComicFact(id: "fact-172", category: "Marvel", text: "Miles daha sonra ana Marvel sürekliliğine taşınarak Peter Parker ile aynı evrende Spider-Man olarak yaşamaya başladı."),
        ComicFact(id: "fact-173", category: "Marvel", text: "Kamala Khan'ın Ms. Marvel serisi 2014'te başladı."),
        ComicFact(id: "fact-174", category: "Marvel", text: "Kamala Khan, Jersey City'de yaşayan genç bir Pakistan kökenli Amerikalı kahramandır."),
        ComicFact(id: "fact-175", category: "Marvel", text: "Kamala'nın kahraman adı, Carol Danvers'ın daha önce kullandığı Ms. Marvel kimliğinden miras gelir."),
        ComicFact(id: "fact-176", category: "Marvel", text: "Kamala Khan kısa sürede genç kuşak Marvel kahramanlarının en önemli isimlerinden biri oldu."),
        ComicFact(id: "fact-177", category: "Marvel", text: "Marvel Super Heroes Secret Wars 1984'te 12 sayılık bir event olarak yayımlandı."),
        ComicFact(id: "fact-178", category: "Marvel", text: "Secret Wars'ün yazarı Jim Shooter'dır."),
        ComicFact(id: "fact-179", category: "Marvel", text: "Secret Wars, Marvel'ın çok sayıda kahraman ve kötü karakterini Battleworld adlı yapay dünyada bir araya getirdi."),
        ComicFact(id: "fact-180", category: "Marvel", text: "Spider-Man'in siyah kostümünün çizgi romanlardaki en önemli erken kullanımlarından biri Secret Wars dönemidir."),
        ComicFact(id: "fact-181", category: "Marvel", text: "The Infinity Gauntlet 1991'de altı sayılık bir mini seri olarak yayımlandı."),
        ComicFact(id: "fact-182", category: "Marvel", text: "Infinity Gauntlet'in yazarı Jim Starlin'dir."),
        ComicFact(id: "fact-183", category: "Marvel", text: "George Pérez serinin erken sayılarında, Ron Lim ise devamında ana sanatçılar arasındadır."),
        ComicFact(id: "fact-184", category: "Marvel", text: "Infinity Gems'in tek eldivende birleşmesi Thanos'u Marvel evreninin merkezî tehditlerinden biri yaptı."),
        ComicFact(id: "fact-185", category: "Marvel", text: "Civil War 2006-2007 arasında yedi sayılık ana seri olarak yayımlandı."),
        ComicFact(id: "fact-186", category: "Marvel", text: "Civil War'u Mark Millar yazdı ve Steve McNiven çizdi."),
        ComicFact(id: "fact-187", category: "Marvel", text: "Civil War'ın merkezinde süper kahramanların devlet kaydına alınması tartışması vardır."),
        ComicFact(id: "fact-188", category: "Marvel", text: "Captain America ve Iron Man, Civil War'ın karşıt taraflarının en görünür liderleri oldu."),
        ComicFact(id: "fact-189", category: "Marvel", text: "House of M 2005'te sekiz sayılık bir event olarak yayımlandı."),
        ComicFact(id: "fact-190", category: "Marvel", text: "House of M'i Brian Michael Bendis yazdı ve Olivier Coipel çizdi."),
        ComicFact(id: "fact-191", category: "Marvel", text: "House of M, Scarlet Witch'in değiştirdiği alternatif bir gerçeklik üzerine kuruludur."),
        ComicFact(id: "fact-192", category: "Marvel", text: "House of M sonrası mutant nüfusundaki büyük değişim X-Men çizgisini yıllarca etkiledi."),
        ComicFact(id: "fact-193", category: "Marvel", text: "Kraven's Last Hunt 1987'de altı bölümlük bir Spider-Man hikâyesi olarak yayımlandı."),
        ComicFact(id: "fact-194", category: "Marvel", text: "Kraven's Last Hunt'ı J. M. DeMatteis yazdı ve Mike Zeck çizdi."),
        ComicFact(id: "fact-195", category: "Marvel", text: "Hikâye üç farklı Spider-Man başlığında sırayla yayımlandı."),
        ComicFact(id: "fact-196", category: "Marvel", text: "Kraven's Last Hunt, süper kahraman hikâyesi ile psikolojik korku tonunu birleştiren ünlü Spider-Man anlatılarındandır."),
        ComicFact(id: "fact-197", category: "Marvel", text: "Ultimate Marvel çizgisi 2000'de modernize edilmiş alternatif bir Marvel evreni olarak başladı."),
        ComicFact(id: "fact-198", category: "Marvel", text: "Ultimate Spider-Man, Ultimate çizgisinin en uzun soluklu ve etkili başlıklarından biri oldu."),
        ComicFact(id: "fact-199", category: "Marvel", text: "Ultimate evreni klasik karakterlerin kökenlerini yeni kuşak okurlar için yeniden yorumladı."),
        ComicFact(id: "fact-200", category: "Marvel", text: "Miles Morales ilk olarak Ultimate evreninde doğan ve daha sonra ana Marvel evrenine geçen en önemli karakterlerden biri oldu."),
        ComicFact(id: "fact-201", category: "Tarih & Yaratıcılar", text: "Will Eisner'ın The Spirit'i 1940'ta gazete eklerinde yayımlanmaya başladı."),
        ComicFact(id: "fact-202", category: "Tarih & Yaratıcılar", text: "Will Eisner'ın 1978 tarihli A Contract with God eseri 'graphic novel' teriminin yaygınlaşmasında etkili oldu."),
        ComicFact(id: "fact-203", category: "Tarih & Yaratıcılar", text: "Eisner Awards adını Will Eisner'dan alır."),
        ComicFact(id: "fact-204", category: "Tarih & Yaratıcılar", text: "Will Eisner, çizgi roman anlatımını açıklarken 'sequential art' ifadesini yaygınlaştıran isimlerden biridir."),
        ComicFact(id: "fact-205", category: "Tarih & Yaratıcılar", text: "Jack Kirby, Joe Simon ile birlikte Captain America'nın yaratıcılarından biridir."),
        ComicFact(id: "fact-206", category: "Tarih & Yaratıcılar", text: "Jack Kirby, Fantastic Four, X-Men ve New Gods gibi çok farklı evrenlerin oluşumunda büyük rol oynadı."),
        ComicFact(id: "fact-207", category: "Tarih & Yaratıcılar", text: "Kirby'nin enerjik kozmik çizimlerinde görülen siyah noktalı enerji dokusu hayranlar arasında 'Kirby Krackle' diye anılır."),
        ComicFact(id: "fact-208", category: "Tarih & Yaratıcılar", text: "Jack Kirby 1970'lerde DC için Fourth World adını alan bağlantılı seriler grubunu geliştirdi."),
        ComicFact(id: "fact-209", category: "Tarih & Yaratıcılar", text: "Stan Lee uzun yıllar Marvel'da yazar, editör ve yayın yöneticisi olarak çalıştı."),
        ComicFact(id: "fact-210", category: "Tarih & Yaratıcılar", text: "Stan Lee'nin okuyucuya doğrudan seslenen editoryal üslubu Marvel'ın marka kişiliğinin önemli parçası oldu."),
        ComicFact(id: "fact-211", category: "Tarih & Yaratıcılar", text: "Stan Lee pek çok Marvel karakterini sanatçı ortaklarıyla birlikte geliştirdi."),
        ComicFact(id: "fact-212", category: "Tarih & Yaratıcılar", text: "'Stan's Soapbox' başlıklı köşeler Lee'nin okuyucularla doğrudan iletişim kurduğu ünlü yayın öğelerindendi."),
        ComicFact(id: "fact-213", category: "Tarih & Yaratıcılar", text: "Steve Ditko, Spider-Man'in ortak yaratıcılarından biridir."),
        ComicFact(id: "fact-214", category: "Tarih & Yaratıcılar", text: "Steve Ditko, Doctor Strange'in de ortak yaratıcılarındandır."),
        ComicFact(id: "fact-215", category: "Tarih & Yaratıcılar", text: "Ditko'nun Spider-Man kostümündeki ağ deseni karakterin en kalıcı görsel özelliklerinden biri oldu."),
        ComicFact(id: "fact-216", category: "Tarih & Yaratıcılar", text: "Steve Ditko daha sonra The Question ve Mr. A gibi farklı yayıncılarda etkili karakterler yarattı."),
        ComicFact(id: "fact-217", category: "Tarih & Yaratıcılar", text: "Joe Simon, Jack Kirby ile birlikte Captain America'yı yarattı."),
        ComicFact(id: "fact-218", category: "Tarih & Yaratıcılar", text: "Simon ve Kirby ikilisi 1940'larda çok sayıda macera, suç ve süper kahraman çizgi romanında birlikte çalıştı."),
        ComicFact(id: "fact-219", category: "Tarih & Yaratıcılar", text: "Young Romance, Simon ve Kirby'nin romantik çizgi roman türünü popülerleştiren önemli çalışmalarındandır."),
        ComicFact(id: "fact-220", category: "Tarih & Yaratıcılar", text: "Joe Simon aynı zamanda editörlük ve yayıncılık tarafında da uzun süre çalıştı."),
        ComicFact(id: "fact-221", category: "Tarih & Yaratıcılar", text: "Jerry Siegel ve Joe Shuster, Superman'in yaratıcılarıdır."),
        ComicFact(id: "fact-222", category: "Tarih & Yaratıcılar", text: "Siegel ve Shuster Superman fikrini Action Comics #1'den yıllar önce geliştirmeye başlamıştı."),
        ComicFact(id: "fact-223", category: "Tarih & Yaratıcılar", text: "Superman'in başarısı Amerikan çizgi roman endüstrisinde süper kahraman patlamasını hızlandırdı."),
        ComicFact(id: "fact-224", category: "Tarih & Yaratıcılar", text: "Siegel ve Shuster'ın Superman üzerindeki hakları, yaratıcı hakları tartışmalarının tarihindeki en bilinen örneklerden biridir."),
        ComicFact(id: "fact-225", category: "Tarih & Yaratıcılar", text: "Bill Finger, Batman'in temel yaratıcı ortaklarından biridir."),
        ComicFact(id: "fact-226", category: "Tarih & Yaratıcılar", text: "Bill Finger ilk Batman hikâyesinin senaryosunu yazdı."),
        ComicFact(id: "fact-227", category: "Tarih & Yaratıcılar", text: "Bruce Wayne adı ve Batman'in erken dönem mitolojisinin pek çok öğesi Bill Finger'ın katkılarıyla şekillendi."),
        ComicFact(id: "fact-228", category: "Tarih & Yaratıcılar", text: "DC, 2015'ten itibaren Batman yapımlarında Bill Finger'ı resmî yaratıcı kredilerinde daha görünür biçimde anmaya başladı."),
        ComicFact(id: "fact-229", category: "Tarih & Yaratıcılar", text: "George Pérez, Crisis on Infinite Earths'ün ana çizeridir."),
        ComicFact(id: "fact-230", category: "Tarih & Yaratıcılar", text: "George Pérez, Marv Wolfman ile The New Teen Titans'ın yeniden doğuşunda merkezi rol oynadı."),
        ComicFact(id: "fact-231", category: "Tarih & Yaratıcılar", text: "Pérez, 1980'lerde Wonder Woman'ın yazar ve çizeri olarak karakterin mitolojisini yeniden kurdu."),
        ComicFact(id: "fact-232", category: "Tarih & Yaratıcılar", text: "George Pérez kalabalık karakter kadrolarını aynı sayfada ayrıntılı çizmesiyle ünlüydü."),
        ComicFact(id: "fact-233", category: "Tarih & Yaratıcılar", text: "Neal Adams'ın gerçekçi anatomisi 1960'lar ve 1970'lerde süper kahraman çizim estetiğini etkiledi."),
        ComicFact(id: "fact-234", category: "Tarih & Yaratıcılar", text: "Neal Adams, Denny O'Neil ile Batman'in karanlık dedektif köklerine dönüşünde önemli rol oynadı."),
        ComicFact(id: "fact-235", category: "Tarih & Yaratıcılar", text: "Green Lantern/Green Arrow dönemi Neal Adams'ın en ünlü sosyal içerikli çalışmalarındandır."),
        ComicFact(id: "fact-236", category: "Tarih & Yaratıcılar", text: "Neal Adams, Jerry Siegel ve Joe Shuster'ın Superman hakları ve kredileri konusunda destek veren sektör figürlerinden biriydi."),
        ComicFact(id: "fact-237", category: "Tarih & Yaratıcılar", text: "Denny O'Neil uzun süre Batman, Green Lantern ve Green Arrow hikâyeleri yazdı."),
        ComicFact(id: "fact-238", category: "Tarih & Yaratıcılar", text: "O'Neil ve Neal Adams ikilisi Ra's al Ghul döneminin oluşmasında temel yaratıcı ekiplerdendir."),
        ComicFact(id: "fact-239", category: "Tarih & Yaratıcılar", text: "Denny O'Neil daha sonra Batman çizgisinde editör olarak da önemli rol oynadı."),
        ComicFact(id: "fact-240", category: "Tarih & Yaratıcılar", text: "O'Neil'in çalışmaları Batman'i 1960'ların kamp tonundan daha ciddi dedektif anlatısına taşıyan süreçte etkili oldu."),
        ComicFact(id: "fact-241", category: "Tarih & Yaratıcılar", text: "Alan Moore, Watchmen'in yazarıdır."),
        ComicFact(id: "fact-242", category: "Tarih & Yaratıcılar", text: "Alan Moore'un Swamp Thing dönemi karakteri geleneksel canavar kökeninden daha metafizik bir yapıya taşıdı."),
        ComicFact(id: "fact-243", category: "Tarih & Yaratıcılar", text: "V for Vendetta ve From Hell, Moore'un süper kahraman dışındaki en bilinen çalışmalarındandır."),
        ComicFact(id: "fact-244", category: "Tarih & Yaratıcılar", text: "Alan Moore'un eserleri çizgi roman biçiminde simetri, paralel kurgu ve tekrarlanan görsel motiflerin kullanımına örnek gösterilir."),
        ComicFact(id: "fact-245", category: "Tarih & Yaratıcılar", text: "Frank Miller'ın Daredevil dönemi karakterin suç-noir yönünü belirgin biçimde güçlendirdi."),
        ComicFact(id: "fact-246", category: "Tarih & Yaratıcılar", text: "Frank Miller The Dark Knight Returns'ü yazıp çizdi."),
        ComicFact(id: "fact-247", category: "Tarih & Yaratıcılar", text: "Batman: Year One'ın yazarı Frank Miller'dır."),
        ComicFact(id: "fact-248", category: "Tarih & Yaratıcılar", text: "Frank Miller daha sonra Sin City gibi yaratıcı sahipli projelerle de büyük başarı kazandı."),
        ComicFact(id: "fact-249", category: "Tarih & Yaratıcılar", text: "Neil Gaiman The Sandman'in yazarıdır."),
        ComicFact(id: "fact-250", category: "Tarih & Yaratıcılar", text: "Neil Gaiman'ın Marvel 1602 serisi Marvel kahramanlarını Elizabeth dönemi benzeri bir dünyada yeniden yorumladı."),
        ComicFact(id: "fact-251", category: "Tarih & Yaratıcılar", text: "The Sandman, Gaiman'ın mitoloji, tarih ve edebiyat referanslarını tek uzun anlatıda birleştirdiği seridir."),
        ComicFact(id: "fact-252", category: "Tarih & Yaratıcılar", text: "Neil Gaiman çizgi romanın yanı sıra roman, öykü, senaryo ve çocuk edebiyatı alanlarında da çalıştı."),
        ComicFact(id: "fact-253", category: "Tarih & Yaratıcılar", text: "Chris Claremont 1975'ten 1991'e kadar X-Men çizgisinin en belirleyici yazarlarından biri oldu."),
        ComicFact(id: "fact-254", category: "Tarih & Yaratıcılar", text: "Dark Phoenix Saga, Claremont döneminin en ünlü X-Men hikâyelerindendir."),
        ComicFact(id: "fact-255", category: "Tarih & Yaratıcılar", text: "Days of Future Past, Chris Claremont ve John Byrne döneminin klasik X-Men anlatılarındandır."),
        ComicFact(id: "fact-256", category: "Tarih & Yaratıcılar", text: "Claremont'un uzun soluklu alt hikâyeleri ve karakter ilişkileri X-Men'in seri anlatım modelini güçlü biçimde etkiledi."),
        ComicFact(id: "fact-257", category: "Tarih & Yaratıcılar", text: "John Byrne, Uncanny X-Men döneminde çizer ve ortak hikâye geliştiricisi olarak önemli rol oynadı."),
        ComicFact(id: "fact-258", category: "Tarih & Yaratıcılar", text: "John Byrne 1980'lerde Fantastic Four'u hem yazdı hem çizdi."),
        ComicFact(id: "fact-259", category: "Tarih & Yaratıcılar", text: "1986'daki The Man of Steel mini serisiyle Byrne Superman'in modern sonrası kökenini yeniden kurdu."),
        ComicFact(id: "fact-260", category: "Tarih & Yaratıcılar", text: "Alpha Flight, John Byrne ile güçlü biçimde özdeşleşen Marvel takımlarındandır."),
        ComicFact(id: "fact-261", category: "Tarih & Yaratıcılar", text: "Walt Simonson'ın Thor dönemi 1980'lerin en sevilen Marvel yaratıcı dönemlerinden biridir."),
        ComicFact(id: "fact-262", category: "Tarih & Yaratıcılar", text: "Beta Ray Bill ilk kez Walt Simonson'ın Thor #337 sayısında tanıtıldı."),
        ComicFact(id: "fact-263", category: "Tarih & Yaratıcılar", text: "Simonson'ın Thor hikâyelerinde yazı ve görsel efektler sayfa tasarımının aktif parçası olarak kullanıldı."),
        ComicFact(id: "fact-264", category: "Tarih & Yaratıcılar", text: "Walt Simonson daha sonra Orion gibi DC projelerinde de yazar ve çizer olarak çalıştı."),
        ComicFact(id: "fact-265", category: "Tarih & Yaratıcılar", text: "Jim Lee 1990'ların başında X-Men çizgisinin en tanınan sanatçılarından biri oldu."),
        ComicFact(id: "fact-266", category: "Tarih & Yaratıcılar", text: "1991 tarihli X-Men #1'in farklı kapakları koleksiyon pazarının en ünlü örneklerinden biridir."),
        ComicFact(id: "fact-267", category: "Tarih & Yaratıcılar", text: "Jim Lee daha sonra WildStorm'un oluşumunda rol aldı."),
        ComicFact(id: "fact-268", category: "Tarih & Yaratıcılar", text: "Jim Lee Batman: Hush'ta Jeph Loeb ile birlikte çalıştı."),
        ComicFact(id: "fact-269", category: "Tarih & Yaratıcılar", text: "Todd McFarlane 1980'lerin sonlarında Amazing Spider-Man çizimleriyle büyük popülerlik kazandı."),
        ComicFact(id: "fact-270", category: "Tarih & Yaratıcılar", text: "Todd McFarlane, David Michelinie ile birlikte Venom'un görsel kimliğinin oluşumunda önemli rol oynadı."),
        ComicFact(id: "fact-271", category: "Tarih & Yaratıcılar", text: "McFarlane 1990'da Spider-Man adlı solo serinin ilk sayısını yazıp çizdi."),
        ComicFact(id: "fact-272", category: "Tarih & Yaratıcılar", text: "Spawn, Todd McFarlane'in 1992'de Image Comics altında başlattığı yaratıcı sahipli seridir."),
        ComicFact(id: "fact-273", category: "Tarih & Yaratıcılar", text: "Image Comics 1992'de büyük yayıncılardan ayrılan yüksek profilli çizerler tarafından kuruldu."),
        ComicFact(id: "fact-274", category: "Tarih & Yaratıcılar", text: "Image'in kuruluş ilkelerinden biri yaratıcıların karakter haklarını korumasına imkân vermekti."),
        ComicFact(id: "fact-275", category: "Tarih & Yaratıcılar", text: "Spawn, Savage Dragon ve WildC.A.T.s Image'in erken dönem simge serilerindendir."),
        ComicFact(id: "fact-276", category: "Tarih & Yaratıcılar", text: "Image zamanla süper kahraman dışındaki türlerde de çok sayıda yaratıcı sahipli hit serinin yayıncısı oldu."),
        ComicFact(id: "fact-277", category: "Tarih & Yaratıcılar", text: "Dark Horse Comics 1986'da Mike Richardson tarafından kuruldu."),
        ComicFact(id: "fact-278", category: "Tarih & Yaratıcılar", text: "Dark Horse Presents antoloji serisi şirketin erken döneminde önemli bir vitrin oldu."),
        ComicFact(id: "fact-279", category: "Tarih & Yaratıcılar", text: "Hellboy, Sin City ve The Mask gibi eserler Dark Horse tarihiyle güçlü biçimde ilişkilidir."),
        ComicFact(id: "fact-280", category: "Tarih & Yaratıcılar", text: "Dark Horse uzun yıllar Star Wars ve Alien gibi lisanslı evrenlerde de çizgi roman yayımladı."),
        ComicFact(id: "fact-281", category: "Tarih & Yaratıcılar", text: "Comics Code Authority 1954'te Amerikan çizgi roman endüstrisinin özdenetim sistemi olarak kuruldu."),
        ComicFact(id: "fact-282", category: "Tarih & Yaratıcılar", text: "Comics Code mührü uzun yıllar ana akım Amerikan çizgi roman kapaklarında görüldü."),
        ComicFact(id: "fact-283", category: "Tarih & Yaratıcılar", text: "Code kuralları korku, suç ve şiddet anlatılarının sunumunu ciddi biçimde sınırladı."),
        ComicFact(id: "fact-284", category: "Tarih & Yaratıcılar", text: "Büyük Amerikan yayıncıları 2000'lerin sonunda ve 2010'ların başında Comics Code'u büyük ölçüde terk etti."),
        ComicFact(id: "fact-285", category: "Tarih & Yaratıcılar", text: "Direct Market modeli çizgi romanların özel mağazalara iade edilemez biçimde dağıtılmasına dayanır."),
        ComicFact(id: "fact-286", category: "Tarih & Yaratıcılar", text: "Direct Market 1970'lerden itibaren çizgi roman mağazalarının büyümesini hızlandırdı."),
        ComicFact(id: "fact-287", category: "Tarih & Yaratıcılar", text: "Direct Market, daha küçük okur kitlelerine hitap eden başlıkların yaşamasına olanak sağlayan bir pazar yarattı."),
        ComicFact(id: "fact-288", category: "Tarih & Yaratıcılar", text: "Uzman çizgi roman dükkânları koleksiyon, back issue ve bağımsız yayın kültürünün merkezlerinden biri oldu."),
        ComicFact(id: "fact-289", category: "Tarih & Yaratıcılar", text: "Free Comic Book Day ilk kez 2002'de düzenlendi."),
        ComicFact(id: "fact-290", category: "Tarih & Yaratıcılar", text: "Free Comic Book Day geleneksel olarak Mayıs ayının ilk cumartesi günü yapılır."),
        ComicFact(id: "fact-291", category: "Tarih & Yaratıcılar", text: "Etkinlikte katılımcı çizgi roman dükkânları özel seçilmiş çizgi romanları okurlara ücretsiz verir."),
        ComicFact(id: "fact-292", category: "Tarih & Yaratıcılar", text: "Free Comic Book Day'in amaçlarından biri yeni okurları yerel çizgi roman dükkânlarıyla tanıştırmaktır."),
        ComicFact(id: "fact-293", category: "Tarih & Yaratıcılar", text: "Eisner Awards çizgi roman endüstrisinin en bilinen ödül programlarından biridir."),
        ComicFact(id: "fact-294", category: "Tarih & Yaratıcılar", text: "Ödüller adını The Spirit'in yaratıcısı Will Eisner'dan alır."),
        ComicFact(id: "fact-295", category: "Tarih & Yaratıcılar", text: "Eisner Awards sonuçları geleneksel olarak San Diego Comic-Con dönemiyle ilişkilidir."),
        ComicFact(id: "fact-296", category: "Tarih & Yaratıcılar", text: "Eisner kategorileri yazar, çizer, seri, yeni seri, dijital yayın ve arşiv projeleri gibi çok farklı alanları kapsar."),
        ComicFact(id: "fact-297", category: "Tarih & Yaratıcılar", text: "San Diego Comic-Con'un kökleri 1970'te düzenlenen çizgi roman odaklı toplantılara uzanır."),
        ComicFact(id: "fact-298", category: "Tarih & Yaratıcılar", text: "San Diego Comic-Con yıllar içinde çizgi roman merkezli bir etkinlikten geniş popüler kültür buluşmasına dönüştü."),
        ComicFact(id: "fact-299", category: "Tarih & Yaratıcılar", text: "Comic-Con panelleri yeni çizgi roman projeleri ve yaratıcı ekip duyuruları için önemli platformlardan biridir."),
        ComicFact(id: "fact-300", category: "Tarih & Yaratıcılar", text: "San Diego Comic-Con aynı zamanda Eisner Awards gibi çizgi roman sektörü etkinliklerine ev sahipliği yapar."),
        ComicFact(id: "fact-301", category: "Çizgi Roman Dili", text: "Golden Age terimi genellikle 1930'ların sonundan 1950'lerin başına uzanan Amerikan süper kahraman dönemini anlatır."),
        ComicFact(id: "fact-302", category: "Çizgi Roman Dili", text: "Superman, Batman, Wonder Woman ve Captain America Golden Age'in en kalıcı kahramanları arasındadır."),
        ComicFact(id: "fact-303", category: "Çizgi Roman Dili", text: "Golden Age sırasında çizgi romanlar savaş, suç, mizah ve korku gibi çok farklı türlerde büyük satışlara ulaştı."),
        ComicFact(id: "fact-304", category: "Çizgi Roman Dili", text: "Golden Age karakterlerinin bir kısmı daha sonra paralel evren ve miras kahramanı fikirleriyle modern çizgi romanlara geri döndü."),
        ComicFact(id: "fact-305", category: "Çizgi Roman Dili", text: "Silver Age terimi genellikle 1950'lerin ortasından 1970 civarına uzanan Amerikan süper kahraman canlanmasını anlatır."),
        ComicFact(id: "fact-306", category: "Çizgi Roman Dili", text: "Barry Allen'ın Showcase #4'teki çıkışı Silver Age için sık kullanılan başlangıç işaretlerinden biridir."),
        ComicFact(id: "fact-307", category: "Çizgi Roman Dili", text: "Silver Age döneminde bilimkurgu kavramları süper kahraman çizgi romanlarında çok yaygınlaştı."),
        ComicFact(id: "fact-308", category: "Çizgi Roman Dili", text: "Marvel'ın Fantastic Four ve Spider-Man gibi karakterleri Silver Age'in karakter odaklı süper kahraman anlatısını şekillendirdi."),
        ComicFact(id: "fact-309", category: "Çizgi Roman Dili", text: "Bronze Age terimi çoğunlukla 1970'ler ve 1980'lerin ilk yarısındaki Amerikan çizgi roman dönemini anlatır."),
        ComicFact(id: "fact-310", category: "Çizgi Roman Dili", text: "Bronze Age'de sosyal sorunlar, uyuşturucu, çevre ve şehir suçları gibi temalar daha görünür hale geldi."),
        ComicFact(id: "fact-311", category: "Çizgi Roman Dili", text: "Green Lantern/Green Arrow hikâyeleri Bronze Age'in sosyal içerikli anlatımına sık verilen örneklerdendir."),
        ComicFact(id: "fact-312", category: "Çizgi Roman Dili", text: "Bronze Age, çizgi roman sanatında daha gerçekçi anatomi ve daha karmaşık sayfa tasarımının yaygınlaştığı bir dönemdi."),
        ComicFact(id: "fact-313", category: "Çizgi Roman Dili", text: "Modern Age ifadesi çoğu zaman 1980'lerin ortasından günümüze uzanan geniş Amerikan çizgi roman dönemini anlatmak için kullanılır."),
        ComicFact(id: "fact-314", category: "Çizgi Roman Dili", text: "Watchmen ve The Dark Knight Returns, Modern Age'in başlangıcı tartışmalarında sık anılan eserlerdendir."),
        ComicFact(id: "fact-315", category: "Çizgi Roman Dili", text: "Modern Age boyunca creator-owned yayıncılık, graphic novel pazarı ve dijital çizgi romanlar büyük ölçüde büyüdü."),
        ComicFact(id: "fact-316", category: "Çizgi Roman Dili", text: "Modern çizgi romanlarda tek bir karakter aynı anda ana süreklilik, alternatif evren ve bağımsız mini serilerde yer alabilir."),
        ComicFact(id: "fact-317", category: "Çizgi Roman Dili", text: "Panel, çizgi roman sayfasında tek bir zaman veya eylem dilimini gösteren çerçevelenmiş alandır."),
        ComicFact(id: "fact-318", category: "Çizgi Roman Dili", text: "Panel boyutu okuma hızını ve sahnenin önem hissini değiştirebilir."),
        ComicFact(id: "fact-319", category: "Çizgi Roman Dili", text: "Çerçevesiz panel kullanımı görüntünün sayfanın sınırlarına taşması hissini güçlendirebilir."),
        ComicFact(id: "fact-320", category: "Çizgi Roman Dili", text: "Bir sayfadaki panel sayısı arttıkça anlatının ritmi genellikle daha parçalı ve hızlı hissedilir."),
        ComicFact(id: "fact-321", category: "Çizgi Roman Dili", text: "Gutter, iki panel arasındaki boşluğa verilen yaygın İngilizce terimdir."),
        ComicFact(id: "fact-322", category: "Çizgi Roman Dili", text: "Okur, gutter'da gösterilmeyen hareketi zihninde tamamlayarak iki paneli birbirine bağlar."),
        ComicFact(id: "fact-323", category: "Çizgi Roman Dili", text: "Gutter'ın genişliği zaman atlaması veya sahne ayrımı hissini etkileyebilir."),
        ComicFact(id: "fact-324", category: "Çizgi Roman Dili", text: "Bazı deneysel çizgi romanlar panel sınırlarını tamamen kaldırarak gutter kavramıyla oynar."),
        ComicFact(id: "fact-325", category: "Çizgi Roman Dili", text: "Splash page, tek bir büyük görselin sayfanın tamamını ya da büyük bölümünü kapladığı sayfadır."),
        ComicFact(id: "fact-326", category: "Çizgi Roman Dili", text: "Splash page genellikle önemli giriş, büyük aksiyon veya dramatik mekân tanıtımı için kullanılır."),
        ComicFact(id: "fact-327", category: "Çizgi Roman Dili", text: "İlk sayfadaki splash page aynı zamanda başlık ve yaratıcı kredilerini taşıyabilir."),
        ComicFact(id: "fact-328", category: "Çizgi Roman Dili", text: "Bazı çizgi romanlar finalde büyük bir görsel etki yaratmak için splash page kullanır."),
        ComicFact(id: "fact-329", category: "Çizgi Roman Dili", text: "Double-page spread, tek kompozisyonun karşılıklı iki sayfaya yayıldığı düzen türüdür."),
        ComicFact(id: "fact-330", category: "Çizgi Roman Dili", text: "İki sayfalık spread özellikle savaş, şehir manzarası ve kalabalık sahnelerde ölçek hissini büyütür."),
        ComicFact(id: "fact-331", category: "Çizgi Roman Dili", text: "Dijital okuyucularda çift sayfa spread'lerin yanlış ayrılması kompozisyonu bozabilir."),
        ComicFact(id: "fact-332", category: "Çizgi Roman Dili", text: "Landscape çift sayfa modu, fiziksel çizgi roman okuma hissini dijital ekranda taklit etmenin yollarından biridir."),
        ComicFact(id: "fact-333", category: "Çizgi Roman Dili", text: "Speech balloon karakterlerin konuşmasını çizgi roman sayfasında görselleştiren temel araçtır."),
        ComicFact(id: "fact-334", category: "Çizgi Roman Dili", text: "Balon kuyruğu genellikle konuşmanın hangi karakterden geldiğini gösterir."),
        ComicFact(id: "fact-335", category: "Çizgi Roman Dili", text: "Farklı balon biçimleri fısıltı, bağırma, robotik ses veya telepati gibi farklı sesleri gösterebilir."),
        ComicFact(id: "fact-336", category: "Çizgi Roman Dili", text: "Lettering, konuşma balonlarının okunabilirliği ve sayfadaki görsel ritim için kritik öneme sahiptir."),
        ComicFact(id: "fact-337", category: "Çizgi Roman Dili", text: "Caption kutuları anlatıcı sesi, yer bilgisi, zaman geçişi veya iç monolog için kullanılabilir."),
        ComicFact(id: "fact-338", category: "Çizgi Roman Dili", text: "Caption ile speech balloon aynı metni taşısa bile okurda farklı anlatıcı hissi yaratır."),
        ComicFact(id: "fact-339", category: "Çizgi Roman Dili", text: "Modern çizgi romanlarda karakter iç sesi sık sık renkli veya özel tasarımlı caption kutularıyla ayrılır."),
        ComicFact(id: "fact-340", category: "Çizgi Roman Dili", text: "Caption kutularının yerleşimi gözün sayfada izleyeceği rotayı yönlendirebilir."),
        ComicFact(id: "fact-341", category: "Çizgi Roman Dili", text: "Thought balloon klasik süper kahraman çizgi romanlarında iç düşünceyi göstermek için çok yaygındı."),
        ComicFact(id: "fact-342", category: "Çizgi Roman Dili", text: "Thought balloon genellikle bulut biçimli kenarlar ve küçük baloncuklardan oluşan kuyrukla çizilir."),
        ComicFact(id: "fact-343", category: "Çizgi Roman Dili", text: "1980'lerden sonra Amerikan ana akım çizgi romanlarında iç düşünce için caption kullanımı thought balloon'un yerini kısmen aldı."),
        ComicFact(id: "fact-344", category: "Çizgi Roman Dili", text: "Thought balloon bugün retro veya bilinçli biçimde klasik anlatım hissi yaratmak için kullanılabilir."),
        ComicFact(id: "fact-345", category: "Çizgi Roman Dili", text: "Çizgi romanlardaki ses efektleri yazı ile görsel arasında doğrudan bir bağ kurar."),
        ComicFact(id: "fact-346", category: "Çizgi Roman Dili", text: "'BAM', 'THOOM' veya 'SNIKT' gibi efektler sesin yanında hareket ve kuvvet hissini de taşır."),
        ComicFact(id: "fact-347", category: "Çizgi Roman Dili", text: "Ses efektinin harf biçimi sahnenin sertliğini, teknolojik yapısını veya duygusunu değiştirebilir."),
        ComicFact(id: "fact-348", category: "Çizgi Roman Dili", text: "Bazı sanatçılar ses efektlerini panel kompozisyonunun fiziksel bir parçası gibi kullanır."),
        ComicFact(id: "fact-349", category: "Çizgi Roman Dili", text: "One-shot, tek sayıda tamamlanan bağımsız çizgi roman yayınıdır."),
        ComicFact(id: "fact-350", category: "Çizgi Roman Dili", text: "One-shot'lar devam eden bir serinin yan hikâyesini anlatabileceği gibi tamamen bağımsız olabilir."),
        ComicFact(id: "fact-351", category: "Çizgi Roman Dili", text: "Özel gün, crossover veya karakter yıldönümü yayınları sık sık one-shot formatında çıkar."),
        ComicFact(id: "fact-352", category: "Çizgi Roman Dili", text: "One-shot formatı yeni okurların uzun süreklilik okumadan bir karakteri denemesini kolaylaştırabilir."),
        ComicFact(id: "fact-353", category: "Çizgi Roman Dili", text: "Annual, genellikle devam eden bir serinin normal sayılarına ek olarak yılda bir yayımlanan özel sayıdır."),
        ComicFact(id: "fact-354", category: "Çizgi Roman Dili", text: "Annual sayıları normal sayıdan daha uzun olabilir."),
        ComicFact(id: "fact-355", category: "Çizgi Roman Dili", text: "Annual'lar bazen ana serinin önemli hikâyesini sürdürür, bazen bağımsız macera anlatır."),
        ComicFact(id: "fact-356", category: "Çizgi Roman Dili", text: "Bazı crossover okuma sıralarında annual sayıları ana hikâyenin zorunlu bölümü olabilir."),
        ComicFact(id: "fact-357", category: "Çizgi Roman Dili", text: "Limited series başlangıçtan itibaren belirli sayıda bölümle planlanan seridir."),
        ComicFact(id: "fact-358", category: "Çizgi Roman Dili", text: "Dört, altı ve on iki sayı Amerikan çizgi romanlarında çok yaygın limited series uzunluklarıdır."),
        ComicFact(id: "fact-359", category: "Çizgi Roman Dili", text: "Limited series formatı yaratıcı ekibin önceden tanımlı bir final etrafında hikâye kurmasını kolaylaştırır."),
        ComicFact(id: "fact-360", category: "Çizgi Roman Dili", text: "Watchmen 12 sayılık, Kingdom Come ise dört sayılık ünlü limited series örnekleridir."),
        ComicFact(id: "fact-361", category: "Çizgi Roman Dili", text: "Ongoing series belirlenmiş bir final sayısı olmadan düzenli olarak devam eden çizgi roman serisidir."),
        ComicFact(id: "fact-362", category: "Çizgi Roman Dili", text: "Ongoing seriler yaratıcı ekip değiştirse bile aynı numaralandırmayla yıllarca sürebilir."),
        ComicFact(id: "fact-363", category: "Çizgi Roman Dili", text: "Büyük yayıncılar bazen ongoing serileri yeni #1 sayısıyla yeniden başlatır."),
        ComicFact(id: "fact-364", category: "Çizgi Roman Dili", text: "Legacy numbering, farklı ciltlerdeki sayıların toplamını göstererek serinin tarihsel numarasına geri dönme yöntemidir."),
        ComicFact(id: "fact-365", category: "Çizgi Roman Dili", text: "Trade paperback genellikle daha önce tek tek yayımlanmış birkaç sayıyı tek yumuşak kapaklı kitapta toplar."),
        ComicFact(id: "fact-366", category: "Çizgi Roman Dili", text: "TPB kısaltması trade paperback için yaygın olarak kullanılır."),
        ComicFact(id: "fact-367", category: "Çizgi Roman Dili", text: "Bir trade genellikle tek bir story arc'ı ya da birkaç bağlantılı sayıyı bir araya getirir."),
        ComicFact(id: "fact-368", category: "Çizgi Roman Dili", text: "Trade koleksiyonları çizgi roman dükkânı dışında genel kitapçılarda da serilerin yayılmasını kolaylaştırdı."),
        ComicFact(id: "fact-369", category: "Çizgi Roman Dili", text: "Hardcover koleksiyonlar trade paperback'e göre daha sert kapak ve çoğu zaman daha büyük üretim kalitesi sunar."),
        ComicFact(id: "fact-370", category: "Çizgi Roman Dili", text: "Deluxe hardcover baskılar bazen standart çizgi roman sayfasından daha büyük ölçüde basılır."),
        ComicFact(id: "fact-371", category: "Çizgi Roman Dili", text: "Hardcover koleksiyonlar ek eskiz, kapak galerisi ve yaratıcı notları içerebilir."),
        ComicFact(id: "fact-372", category: "Çizgi Roman Dili", text: "Aynı hikâye yıllar içinde paperback, hardcover, deluxe ve omnibus gibi birçok farklı formatta yeniden basılabilir."),
        ComicFact(id: "fact-373", category: "Çizgi Roman Dili", text: "Omnibus çok sayıda çizgi roman sayısını tek büyük ciltte toplayan kapsamlı koleksiyon formatıdır."),
        ComicFact(id: "fact-374", category: "Çizgi Roman Dili", text: "Omnibus ciltleri yüzlerce, hatta binden fazla sayfa içerebilir."),
        ComicFact(id: "fact-375", category: "Çizgi Roman Dili", text: "Omnibus baskılar uzun bir yaratıcı dönemi veya büyük event'i tek ciltte okumayı kolaylaştırır."),
        ComicFact(id: "fact-376", category: "Çizgi Roman Dili", text: "Omnibusların ağırlığı ve cilt yapısı dijital okuyucuların büyük koleksiyonlarda pratik avantaj sağlamasının nedenlerinden biridir."),
        ComicFact(id: "fact-377", category: "Çizgi Roman Dili", text: "Absolute ve benzeri premium baskılar genellikle büyük sayfa boyutu ve yüksek üretim kalitesiyle hazırlanır."),
        ComicFact(id: "fact-378", category: "Çizgi Roman Dili", text: "DC'nin Absolute formatı sanat eserini standart comic boyutundan daha büyük göstermek için tasarlanmıştır."),
        ComicFact(id: "fact-379", category: "Çizgi Roman Dili", text: "Deluxe ve premium baskılar sık sık ek kapaklar, taslaklar veya yaratıcı materyaller içerir."),
        ComicFact(id: "fact-380", category: "Çizgi Roman Dili", text: "Premium baskı adları yayıncıdan yayıncıya farklı anlamlar taşıyabilir."),
        ComicFact(id: "fact-381", category: "Çizgi Roman Dili", text: "Facsimile edition eski bir çizgi roman sayısını orijinal baskıya mümkün olduğunca benzer biçimde yeniden üretmeyi amaçlar."),
        ComicFact(id: "fact-382", category: "Çizgi Roman Dili", text: "Facsimile baskılar bazen orijinal reklamları ve editoryal sayfaları da korur."),
        ComicFact(id: "fact-383", category: "Çizgi Roman Dili", text: "Facsimile baskılar pahalı koleksiyonluk eski sayıları modern okurun fiziksel olarak deneyimlemesini kolaylaştırır."),
        ComicFact(id: "fact-384", category: "Çizgi Roman Dili", text: "Bir facsimile edition yeni bir reprint'tir; orijinal ilk baskıyla aynı koleksiyon değeri taşımaz."),
        ComicFact(id: "fact-385", category: "Çizgi Roman Dili", text: "Variant cover aynı çizgi romanın içeriği değişmeden farklı kapaklarla satılan baskısıdır."),
        ComicFact(id: "fact-386", category: "Çizgi Roman Dili", text: "Variant kapaklar sanatçı odaklı koleksiyonculuğun önemli parçalarından biridir."),
        ComicFact(id: "fact-387", category: "Çizgi Roman Dili", text: "Bazı variant kapaklar belirli sipariş oranlarına bağlı 'ratio variant' olarak dağıtılır."),
        ComicFact(id: "fact-388", category: "Çizgi Roman Dili", text: "Tek bir popüler #1 sayısı onlarca farklı variant kapakla yayımlanabilir."),
        ComicFact(id: "fact-389", category: "Çizgi Roman Dili", text: "Crossover iki veya daha fazla seri ya da karakterin aynı hikâyede kesişmesidir."),
        ComicFact(id: "fact-390", category: "Çizgi Roman Dili", text: "Küçük crossover yalnızca iki seri arasında olabilir; büyük event onlarca başlığa yayılabilir."),
        ComicFact(id: "fact-391", category: "Çizgi Roman Dili", text: "Crossover okuma sıraları ana seri ile tie-in sayılarının hangi sırayla okunacağını gösterir."),
        ComicFact(id: "fact-392", category: "Çizgi Roman Dili", text: "Secret Wars, Crisis on Infinite Earths ve Civil War büyük çaplı crossover event örnekleridir."),
        ComicFact(id: "fact-393", category: "Çizgi Roman Dili", text: "Retcon, daha önce anlatılmış süreklilik bilgisinin yeni hikâyeyle yeniden yorumlanmasına verilen yaygın terimdir."),
        ComicFact(id: "fact-394", category: "Çizgi Roman Dili", text: "Retcon her zaman eski hikâyeyi tamamen silmez; bazen yalnızca yeni bağlam ekler."),
        ComicFact(id: "fact-395", category: "Çizgi Roman Dili", text: "Gizli akrabalık, unutulmuş olay veya değişen köken hikâyeleri retcon için sık kullanılan yöntemlerdir."),
        ComicFact(id: "fact-396", category: "Çizgi Roman Dili", text: "Uzun soluklu süper kahraman evrenleri onlarca yıllık sürekliliği yönetmek için sık sık retcon kullanır."),
        ComicFact(id: "fact-397", category: "Çizgi Roman Dili", text: "Cliffhanger bölümün kritik bir anda bitirilerek okurun sonraki sayıyı merak etmesini sağlayan anlatım tekniğidir."),
        ComicFact(id: "fact-398", category: "Çizgi Roman Dili", text: "Aylık yayımlanan çizgi romanlarda cliffhanger, sayılar arasındaki bekleyişi dramatik araca dönüştürür."),
        ComicFact(id: "fact-399", category: "Çizgi Roman Dili", text: "Sayfanın sağ alt köşesinde kurulan sürpriz, fiziksel sayfa çevirmenin etkisini kullanan klasik cliffhanger yöntemlerindendir."),
        ComicFact(id: "fact-400", category: "Çizgi Roman Dili", text: "Dijital çizgi roman okuyucuları da sayfa sonu ve bölüm sonu tasarımlarıyla cliffhanger ritmini koruyabilir."),
    ]

    static func random(excluding id: String? = nil) -> ComicFact {
        guard !all.isEmpty else { return ComicFact(id: "empty", category: "", text: "") }
        guard let id, all.count > 1 else { return all.randomElement() ?? all[0] }

        var candidate = all.randomElement() ?? all[0]
        if candidate.id == id {
            let currentIndex = all.firstIndex { $0.id == id } ?? 0
            candidate = all[(currentIndex + 1) % all.count]
        }
        return candidate
    }
}

enum ComicCalendarEventKind: String, CaseIterable, Sendable {
    case official = "Resmî"
    case publisher = "Yayıncı"
    case community = "Topluluk"
    case milestone = "Tarih"

    var color: Color {
        switch self {
        case .official: return .yellow
        case .publisher: return .red
        case .community: return .green
        case .milestone: return .cyan
        }
    }

    var icon: String {
        switch self {
        case .official: return "star.fill"
        case .publisher: return "building.2.fill"
        case .community: return "person.3.fill"
        case .milestone: return "clock.fill"
        }
    }
}

struct ComicCalendarEvent: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let detail: String
    let kind: ComicCalendarEventKind
    let month: Int?
    let day: Int?
    let rule: RecurringRule?

    enum RecurringRule: Hashable, Sendable {
        case firstSaturdayOfMay
        case thirdSaturdayOfSeptember
    }
}

enum ComicCalendarService {
    static let events: [ComicCalendarEvent] = [
        .init(id: "superman-day", title: "Superman Day", detail: "DC'nin Superman kutlaması; Action Comics #1'in 18 Nisan 1938'deki çıkışıyla bağlantılı.", kind: .official, month: 4, day: 18, rule: nil),
        .init(id: "free-comic-book-day", title: "Free Comic Book Day", detail: "Çizgi roman dükkânlarının her yıl Mayıs'ın ilk cumartesi günü düzenlediği sektör çapında kutlama.", kind: .official, month: nil, day: nil, rule: .firstSaturdayOfMay),
        .init(id: "x-men-day", title: "X-Men Day", detail: "13 Mayıs'ta X-Men mirasını kutlamak için kullanılan yayıncı/promosyon günü.", kind: .publisher, month: 5, day: 13, rule: nil),
        .init(id: "spider-man-day", title: "Spider-Man Day", detail: "Marvel'ın 1 Ağustos'ta Spider-Man içerikleriyle kutladığı gün.", kind: .publisher, month: 8, day: 1, rule: nil),
        .init(id: "read-comics-public", title: "Read Comics in Public Day", detail: "28 Ağustos'ta çizgi romanları kamusal alanda okumayı teşvik eden topluluk günü; tarih Jack Kirby'nin doğum gününe denk gelir.", kind: .community, month: 8, day: 28, rule: nil),
        .init(id: "batman-day", title: "Batman Day", detail: "DC'nin her yıl Eylül ayında düzenlediği küresel Batman kutlaması; uygulama üçüncü cumartesiyi işaretler.", kind: .official, month: nil, day: nil, rule: .thirdSaturdayOfSeptember),
        .init(id: "comic-book-day", title: "National Comic Book Day", detail: "25 Eylül'de çizgi roman sanatını, yaratıcıları ve okurları kutlayan topluluk günü.", kind: .community, month: 9, day: 25, rule: nil),
        .init(id: "wonder-woman-day", title: "Wonder Woman Day", detail: "21 Ekim; Wonder Woman'ın All Star Comics #8'deki ilk görünümünün yıldönümü.", kind: .official, month: 10, day: 21, rule: nil),
        .init(id: "batman-debut", title: "Batman Çizgi Roman Yıldönümü", detail: "Detective Comics #27, 30 Mart 1939'da gazete bayilerine ulaştı.", kind: .milestone, month: 3, day: 30, rule: nil),
        .init(id: "jack-kirby-birthday", title: "Jack Kirby'nin Doğum Günü", detail: "28 Ağustos 1917; çizgi roman tarihinin en etkili yaratıcılarından Jack Kirby'nin doğum günü.", kind: .milestone, month: 8, day: 28, rule: nil),
        .init(id: "stan-lee-birthday", title: "Stan Lee'nin Doğum Günü", detail: "28 Aralık 1922; Marvel tarihinin en tanınan editör ve yazarlarından Stan Lee'nin doğum günü.", kind: .milestone, month: 12, day: 28, rule: nil)
    ]

    static func date(for event: ComicCalendarEvent, year: Int, calendar: Calendar = .current) -> Date? {
        if let month = event.month, let day = event.day {
            return calendar.date(from: DateComponents(year: year, month: month, day: day))
        }
        switch event.rule {
        case .firstSaturdayOfMay:
            return nthWeekday(7, ordinal: 1, month: 5, year: year, calendar: calendar)
        case .thirdSaturdayOfSeptember:
            return nthWeekday(7, ordinal: 3, month: 9, year: year, calendar: calendar)
        case .none:
            return nil
        }
    }

    static func events(on date: Date, calendar: Calendar = .current) -> [ComicCalendarEvent] {
        let year = calendar.component(.year, from: date)
        return events.filter { event in
            guard let eventDate = self.date(for: event, year: year, calendar: calendar) else { return false }
            return calendar.isDate(eventDate, inSameDayAs: date)
        }
    }

    static func events(inMonthContaining date: Date, calendar: Calendar = .current) -> [(Date, ComicCalendarEvent)] {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        return events.compactMap { event in
            guard let eventDate = self.date(for: event, year: year, calendar: calendar),
                  calendar.component(.month, from: eventDate) == month else { return nil }
            return (eventDate, event)
        }.sorted { $0.0 < $1.0 }
    }


    static func eventMap(inMonthContaining date: Date, calendar: Calendar = .current) -> [String: [ComicCalendarEvent]] {
        var map: [String: [ComicCalendarEvent]] = [:]
        for (eventDate, event) in events(inMonthContaining: date, calendar: calendar) {
            map[PanelDayKey.string(eventDate, calendar: calendar), default: []].append(event)
        }
        return map
    }

    static func upcoming(from date: Date = .now, count: Int = 4, calendar: Calendar = .current) -> [(Date, ComicCalendarEvent)] {
        let startYear = calendar.component(.year, from: date)
        var candidates: [(Date, ComicCalendarEvent)] = []
        for year in startYear...(startYear + 1) {
            for event in events {
                if let eventDate = self.date(for: event, year: year, calendar: calendar),
                   eventDate >= calendar.startOfDay(for: date) {
                    candidates.append((eventDate, event))
                }
            }
        }
        return Array(candidates.sorted { $0.0 < $1.0 }.prefix(count))
    }

    private static func nthWeekday(_ weekday: Int, ordinal: Int, month: Int, year: Int, calendar: Calendar) -> Date? {
        guard let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { return nil }
        let firstWeekday = calendar.component(.weekday, from: first)
        let delta = (weekday - firstWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: delta + (ordinal - 1) * 7, to: first)
    }
}
