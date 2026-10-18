import SwiftUI
import Foundation

struct ComicFact: Identifiable, Hashable {
    let id: String
    let category: String
    let text: String
}

enum ComicFactCatalog {
    static let all: [ComicFact] = [
        ComicFact(id: "fact-001", category: "DC", text: String(localized: "Superman first appeared in Action Comics #1 in 1938.")),
        ComicFact(id: "fact-002", category: "DC", text: String(localized: "Superman was created by Jerry Siegel and Joe Shuster.")),
        ComicFact(id: "fact-003", category: "DC", text: String(localized: "Superman's journalist identity is Clark Kent.")),
        ComicFact(id: "fact-004", category: "DC", text: String(localized: "Action Comics #1 is considered one of the most important starting points of the superhero comics era.")),
        ComicFact(id: "fact-005", category: "DC", text: String(localized: "Batman first appeared in Detective Comics #27 in 1939.")),
        ComicFact(id: "fact-006", category: "DC", text: String(localized: "Batman's first published story was only six pages long.")),
        ComicFact(id: "fact-007", category: "DC", text: String(localized: "Bruce Wayne's origin story about the murder of his parents was told months after the release of Batman.")),
        ComicFact(id: "fact-008", category: "DC", text: String(localized: "Joker and Catwoman appeared in Batman #1 as Batman's early foes.")),
        ComicFact(id: "fact-009", category: "DC", text: String(localized: "Wonder Woman first appeared in All Star Comics #8 in 1941.")),
        ComicFact(id: "fact-010", category: "DC", text: String(localized: "Wonder Woman's creators include William Moulton Marston and artist H. G. Peter.")),
        ComicFact(id: "fact-011", category: "DC", text: String(localized: "Wonder Woman's own solo series began in 1942.")),
        ComicFact(id: "fact-012", category: "DC", text: String(localized: "Wonder Woman Day is celebrated on October 21, the anniversary of the character's first appearance.")),
        ComicFact(id: "fact-013", category: "DC", text: String(localized: "The Dick Grayson version of Robin was introduced in Detective Comics #38 in 1940.")),
        ComicFact(id: "fact-014", category: "DC", text: String(localized: "Robin is one of the names that popularized the young supporting character model in superhero comics.")),
        ComicFact(id: "fact-015", category: "DC", text: String(localized: "Dick Grayson, Batman'in ilk uzun soluklu Robin'idir.")),
        ComicFact(id: "fact-016", category: "DC", text: String(localized: "The name Robin has been used by different characters over the years, including Jason Todd, Tim Drake, and Damian Wayne.")),
        ComicFact(id: "fact-017", category: "DC", text: String(localized: "Dick Grayson adopted the Nightwing identity in 1984's Tales of the Teen Titans #44.")),
        ComicFact(id: "fact-018", category: "DC", text: String(localized: "The name Nightwing has become one of the symbols of Dick Grayson's emergence from Batman's shadow.")),
        ComicFact(id: "fact-019", category: "DC", text: String(localized: "Blüdhaven is the city strongly identified with the Nightwing solo stories.")),
        ComicFact(id: "fact-020", category: "DC", text: String(localized: "Nightwing's acrobatic background is a core part of the character's fighting and movement style.")),
        ComicFact(id: "fact-021", category: "DC", text: String(localized: "Barry Allen's version of the Flash was introduced in 1956's Showcase #4.")),
        ComicFact(id: "fact-022", category: "DC", text: String(localized: "Showcase #4 is often cited as one of the beginnings of DC's Silver Age era.")),
        ComicFact(id: "fact-023", category: "DC", text: String(localized: "Jay Garrick is the Golden Age Flash before Barry Allen.")),
        ComicFact(id: "fact-024", category: "DC", text: String(localized: "The concept of the Speed ​​Force is one of the fundamental ideas in the modern era of the Flash mythology.")),
        ComicFact(id: "fact-025", category: "DC", text: String(localized: "Hal Jordan first appeared as Green Lantern in 1959's Showcase #22.")),
        ComicFact(id: "fact-026", category: "DC", text: String(localized: "Green Lantern rings are associated with the idea of ​​willpower.")),
        ComicFact(id: "fact-027", category: "DC", text: String(localized: "The Green Lantern Corps is an organization that operates on a global scale rather than a single hero.")),
        ComicFact(id: "fact-028", category: "DC", text: String(localized: "Alan Scott was the hero who used the name Green Lantern in 1940, years before Hal Jordan.")),
        ComicFact(id: "fact-029", category: "DC", text: String(localized: "Aquaman first appeared in More Fun Comics #73 in 1941.")),
        ComicFact(id: "fact-030", category: "DC", text: String(localized: "For many years, Aquaman was portrayed as the king of Atlantis and the bridge between the surface world and the seas.")),
        ComicFact(id: "fact-031", category: "DC", text: String(localized: "Arthur Curry is Aquaman's best-known civilian name.")),
        ComicFact(id: "fact-032", category: "DC", text: String(localized: "More Fun Comics #73 also includes the first appearance of Green Arrow.")),
        ComicFact(id: "fact-033", category: "DC", text: String(localized: "Green Arrow first appeared in More Fun Comics #73 in 1941.")),
        ComicFact(id: "fact-034", category: "DC", text: String(localized: "Oliver Queen is Green Arrow's most well-known identity.")),
        ComicFact(id: "fact-035", category: "DC", text: String(localized: "Green Arrow stories have at times addressed social and political issues more directly than other superhero series.")),
        ComicFact(id: "fact-036", category: "DC", text: String(localized: "Denny O'Neil and Neal Adams' Green Lantern/Green Arrow era are famous examples of this social approach.")),
        ComicFact(id: "fact-037", category: "DC", text: String(localized: "The Justice Society of America became one of the earliest superhero teams in comic book history with 1940's All Star Comics #3.")),
        ComicFact(id: "fact-038", category: "DC", text: String(localized: "Justice Society brought Golden Age DC heroes together under one roof.")),
        ComicFact(id: "fact-039", category: "DC", text: String(localized: "The JSA concept later became a core part of DC's cross-generational hero legacy.")),
        ComicFact(id: "fact-040", category: "DC", text: String(localized: "The idea of ​​Earth-Two helped Golden Age heroes continue to live on in the modern DC universe.")),
        ComicFact(id: "fact-041", category: "DC", text: String(localized: "Justice League ilk kez 1960'ta The Brave and the Bold #28'de bir araya geldi.")),
        ComicFact(id: "fact-042", category: "DC", text: String(localized: "Justice League'in erken kadrosunda Superman, Batman, Wonder Woman, Flash, Green Lantern, Aquaman ve Martian Manhunter bulunuyordu.")),
        ComicFact(id: "fact-043", category: "DC", text: String(localized: "Justice League of America got its own series in 1960.")),
        ComicFact(id: "fact-044", category: "DC", text: String(localized: "Justice League storylines are one of the major centers that unite DC's different solo series into joint events.")),
        ComicFact(id: "fact-045", category: "DC", text: String(localized: "Teen Titans has its roots in the shared adventures of Robin, Kid Flash and Aqualad.")),
        ComicFact(id: "fact-046", category: "DC", text: String(localized: "The name Teen Titans became the team's permanent identity in the mid-1960s.")),
        ComicFact(id: "fact-047", category: "DC", text: String(localized: "Marv Wolfman and George Pérez's The New Teen Titans series greatly increased the team's popularity in the 1980s.")),
        ComicFact(id: "fact-048", category: "DC", text: String(localized: "Characters such as Raven, Starfire and Cyborg became iconic names of the New Teen Titans era.")),
        ComicFact(id: "fact-049", category: "DC", text: String(localized: "The first version of Swamp Thing appeared in 1971's House of Secrets #92.")),
        ComicFact(id: "fact-050", category: "DC", text: String(localized: "Len Wein and Bernie Wrightson are among the creators of Swamp Thing.")),
        ComicFact(id: "fact-051", category: "DC", text: String(localized: "Alan Moore's Swamp Thing era in the 1980s significantly expanded the horror and philosophy aspect of the character.")),
        ComicFact(id: "fact-052", category: "DC", text: String(localized: "Swamp Thing stories were instrumental in the development of DC's supernatural side.")),
        ComicFact(id: "fact-053", category: "DC", text: String(localized: "Harley Quinn was first created for Batman: The Animated Series in 1992.")),
        ComicFact(id: "fact-054", category: "DC", text: String(localized: "Harley Quinn is created by Paul Dini and Bruce Timm.")),
        ComicFact(id: "fact-055", category: "DC", text: String(localized: "Harley's early significant appearance in the DC comics universe is The Batman Adventures #12.")),
        ComicFact(id: "fact-056", category: "DC", text: String(localized: "Harley Quinn is one of the most successful DC characters who was born in a medium outside of comics and then transitioned to the main comic book universe.")),
        ComicFact(id: "fact-057", category: "DC", text: String(localized: "John Constantine was first fully introduced in 1985 in Swamp Thing #37.")),
        ComicFact(id: "fact-058", category: "DC", text: String(localized: "Constantine is one of the characters who uses magic as a dangerous tool rather than a superhero power.")),
        ComicFact(id: "fact-059", category: "DC", text: String(localized: "Hellblazer is one of the longest-running series identified with Constantine.")),
        ComicFact(id: "fact-060", category: "DC", text: String(localized: "It has been stated for years by the creative team that Constantine's appearance was inspired by Sting.")),
        ComicFact(id: "fact-061", category: "DC", text: String(localized: "Neil Gaiman's The Sandman series began in 1989.")),
        ComicFact(id: "fact-062", category: "DC", text: String(localized: "Dream, at the center of The Sandman, is a member of a cosmic band of brothers called the Endless.")),
        ComicFact(id: "fact-063", category: "DC", text: String(localized: "The Sandman superhero comic is known for blending mythology, horror and literature in the same structure.")),
        ComicFact(id: "fact-064", category: "DC", text: String(localized: "The Sandman became one of the most influential long-running series of the Vertigo era.")),
        ComicFact(id: "fact-065", category: "DC", text: String(localized: "Watchmen was published in 12 issues between 1986-1987.")),
        ComicFact(id: "fact-066", category: "DC", text: String(localized: "Watchmen was written by Alan Moore and drawn by Dave Gibbons.")),
        ComicFact(id: "fact-067", category: "DC", text: String(localized: "Watchmen's colors were created by John Higgins.")),
        ComicFact(id: "fact-068", category: "DC", text: String(localized: "Watchmen is famous for its frequent use of the nine-panel layout for repetitive visual rhythms.")),
        ComicFact(id: "fact-069", category: "DC", text: String(localized: "The Dark Knight Returns was released as a four-part series in 1986.")),
        ComicFact(id: "fact-070", category: "DC", text: String(localized: "Frank Miller is the writer and primary artist of The Dark Knight Returns.")),
        ComicFact(id: "fact-071", category: "DC", text: String(localized: "Klaus Janson's inks and Lynn Varley's colors are important parts of the visual identity of the work.")),
        ComicFact(id: "fact-072", category: "DC", text: String(localized: "The Dark Knight Returns reinterpreted the Batman myth through an aging Bruce Wayne.")),
        ComicFact(id: "fact-073", category: "DC", text: String(localized: "Batman: Year One was published in Batman #404-407 in 1987.")),
        ComicFact(id: "fact-074", category: "DC", text: String(localized: "Batman: Year One was written by Frank Miller and drawn by David Mazzucchelli.")),
        ComicFact(id: "fact-075", category: "DC", text: String(localized: "Year One focuses as much on Jim Gordon's arrival in Gotham as it does on Bruce Wayne.")),
        ComicFact(id: "fact-076", category: "DC", text: String(localized: "Batman: Year One is considered one of the most influential examples of modern Batman origin narratives.")),
        ComicFact(id: "fact-077", category: "DC", text: String(localized: "Kingdom Come was published as a four-issue mini-series in 1996.")),
        ComicFact(id: "fact-078", category: "DC", text: String(localized: "Kingdom Come was written by Mark Waid and illustrated by Alex Ross.")),
        ComicFact(id: "fact-079", category: "DC", text: String(localized: "Kingdom Come deals with the conflict between classic heroes and a new, tougher generation.")),
        ComicFact(id: "fact-080", category: "DC", text: String(localized: "Alex Ross's painted pages are one of Kingdom Come's distinctive visual features.")),
        ComicFact(id: "fact-081", category: "DC", text: String(localized: "Crisis on Infinite Earths was published in 12 issues between 1985-1986.")),
        ComicFact(id: "fact-082", category: "DC", text: String(localized: "Crisis on Infinite Earths was written by Marv Wolfman and drawn by George Pérez.")),
        ComicFact(id: "fact-083", category: "DC", text: String(localized: "Series 1 was designed with the aim of retooling DC's multiverse continuity on a massive scale.")),
        ComicFact(id: "fact-084", category: "DC", text: String(localized: "Crisis on Infinite Earths is one of the most effective examples of the company-wide crossover event model.")),
        ComicFact(id: "fact-085", category: "DC", text: String(localized: "Flashpoint was published as a five-issue main series in 2011.")),
        ComicFact(id: "fact-086", category: "DC", text: String(localized: "Flashpoint is written by Geoff Johns and main series artist is Andy Kubert.")),
        ComicFact(id: "fact-087", category: "DC", text: String(localized: "Flashpoint is a story in which Barry Allen wakes up in an altered timeline.")),
        ComicFact(id: "fact-088", category: "DC", text: String(localized: "After Flashpoint, DC's New 52 publishing era began.")),
        ComicFact(id: "fact-089", category: "DC", text: String(localized: "DC's New 52 push rebooted numerous series with new #1 issues in 2011.")),
        ComicFact(id: "fact-090", category: "DC", text: String(localized: "During the New 52 era, DC's main superhero line was introduced with the idea of ​​52 titles.")),
        ComicFact(id: "fact-091", category: "DC", text: String(localized: "The New 52 simplified the backstories of some characters and drastically redesigned others.")),
        ComicFact(id: "fact-092", category: "DC", text: String(localized: "The New 52 era remained central to DC's publishing identity until the Rebirth push in 2016.")),
        ComicFact(id: "fact-093", category: "DC", text: String(localized: "DC Rebirth began in 2016 with DC Universe: Rebirth #1.")),
        ComicFact(id: "fact-094", category: "DC", text: String(localized: "The Rebirth push aimed to reintegrate new continuity ideas with the classic DC legacy.")),
        ComicFact(id: "fact-095", category: "DC", text: String(localized: "DC Universe: Rebirth #1 is written by Geoff Johns.")),
        ComicFact(id: "fact-096", category: "DC", text: String(localized: "After Rebirth, many series such as Batman, Superman, Wonder Woman, Flash and Nightwing entered new creative eras.")),
        ComicFact(id: "fact-097", category: "DC", text: String(localized: "The Vertigo label was started by DC in 1993 for content aimed at adult readers.")),
        ComicFact(id: "fact-098", category: "DC", text: String(localized: "Karen Berger is one of the most important editorial figures in the creation of Vertigo.")),
        ComicFact(id: "fact-099", category: "DC", text: String(localized: "Works such as The Sandman, Hellblazer, and Swamp Thing are strongly associated with the Vertigo identity.")),
        ComicFact(id: "fact-100", category: "DC", text: String(localized: "Vertigo played an important role in the popularization of creatively focused and genre-diverse American comics.")),
        ComicFact(id: "fact-101", category: "Marvel", text: String(localized: "Marvel's roots date back to Marvel Comics #1, published in 1939, and the Timely Comics era.")),
        ComicFact(id: "fact-102", category: "Marvel", text: String(localized: "Marvel Comics #1 featured early characters like the Human Torch and Namor.")),
        ComicFact(id: "fact-103", category: "Marvel", text: String(localized: "The name Timely Comics was one of Marvel's early corporate identities in the 1940s.")),
        ComicFact(id: "fact-104", category: "Marvel", text: String(localized: "The Marvel name became permanently identified with the company's superhero publishing identity in the 1960s.")),
        ComicFact(id: "fact-105", category: "Marvel", text: String(localized: "Captain America first appeared in 1941's Captain America Comics #1.")),
        ComicFact(id: "fact-106", category: "Marvel", text: String(localized: "Captain America was created by Joe Simon and Jack Kirby.")),
        ComicFact(id: "fact-107", category: "Marvel", text: String(localized: "On the cover of Captain America Comics #1, the hero is depicted punching Adolf Hitler.")),
        ComicFact(id: "fact-108", category: "Marvel", text: String(localized: "Steve Rogers is Captain America's best-known civilian identity.")),
        ComicFact(id: "fact-109", category: "Marvel", text: String(localized: "Fantastic Four #1 was published in 1961 and became a cornerstone of Marvel's Silver Age superhero era.")),
        ComicFact(id: "fact-110", category: "Marvel", text: String(localized: "Stan Lee and Jack Kirby created the Fantastic Four.")),
        ComicFact(id: "fact-111", category: "Marvel", text: String(localized: "Fantastic Four members were designed as heroes who did not lose their family arguments and personal problems even as they gained power.")),
        ComicFact(id: "fact-112", category: "Marvel", text: String(localized: "Baxter Building has been one of the centers identified with the Fantastic Four for many years.")),
        ComicFact(id: "fact-113", category: "Marvel", text: String(localized: "Spider-Man first appeared in 1962 in Amazing Fantasy #15.")),
        ComicFact(id: "fact-114", category: "Marvel", text: String(localized: "Spider-Man is created by Stan Lee and Steve Ditko.")),
        ComicFact(id: "fact-115", category: "Marvel", text: String(localized: "Peter Parker's struggle with money, school, work and family at a young age became one of the character's early distinguishing features.")),
        ComicFact(id: "fact-116", category: "Marvel", text: String(localized: "The Amazing Spider-Man solo series began in 1963.")),
        ComicFact(id: "fact-117", category: "Marvel", text: String(localized: "The Hulk first appeared in 1962's The Incredible Hulk #1.")),
        ComicFact(id: "fact-118", category: "Marvel", text: String(localized: "Bruce Banner's transformation into the Hulk combined Marvel's sci-fi and monster comic heritage with the superhero genre.")),
        ComicFact(id: "fact-119", category: "Marvel", text: String(localized: "Hulk's color is gray in the first issue; soon the green color became permanent for printing reasons.")),
        ComicFact(id: "fact-120", category: "Marvel", text: String(localized: "Hulk has been affiliated with different teams over the years, including both the Avengers and the Defenders.")),
        ComicFact(id: "fact-121", category: "Marvel", text: String(localized: "The Marvel version of Thor was introduced in 1962's Journey into Mystery #83.")),
        ComicFact(id: "fact-122", category: "Marvel", text: String(localized: "Stan Lee, Larry Lieber, and Jack Kirby had major creative roles in Thor's early Marvel adventures.")),
        ComicFact(id: "fact-123", category: "Marvel", text: String(localized: "Mjolnir is one of the most recognizable symbols of the Thor comics.")),
        ComicFact(id: "fact-124", category: "Marvel", text: String(localized: "Walt Simonson's 1980s Thor era added enduring characters like Beta Ray Bill.")),
        ComicFact(id: "fact-125", category: "Marvel", text: String(localized: "Iron Man first appeared in Tales of Suspense #39 in 1963.")),
        ComicFact(id: "fact-126", category: "Marvel", text: String(localized: "Tony Stark's first armor had a bulky, gray design.")),
        ComicFact(id: "fact-127", category: "Marvel", text: String(localized: "Iron Man's armor created an ever-changing field of visual design in comics as technology advanced.")),
        ComicFact(id: "fact-128", category: "Marvel", text: String(localized: "Iron Man is one of the key members of the Avengers' founding cast.")),
        ComicFact(id: "fact-129", category: "Marvel", text: String(localized: "X-Men #1 was published in 1963.")),
        ComicFact(id: "fact-130", category: "Marvel", text: String(localized: "Stan Lee and Jack Kirby created the X-Men.")),
        ComicFact(id: "fact-131", category: "Marvel", text: String(localized: "The mutant concept gave Marvel a flexible structure to create characters with many different powers in the same universe.")),
        ComicFact(id: "fact-132", category: "Marvel", text: String(localized: "In 1975, Giant-Size X-Men #1 brought important names to the team such as Wolverine, Storm, Nightcrawler and Colossus.")),
        ComicFact(id: "fact-133", category: "Marvel", text: String(localized: "Avengers #1 was published in 1963.")),
        ComicFact(id: "fact-134", category: "Marvel", text: String(localized: "The original cast of Avengers included Iron Man, Thor, Hulk, Ant-Man and the Wasp.")),
        ComicFact(id: "fact-135", category: "Marvel", text: String(localized: "Captain America returns to the modern Marvel universe in Avengers #4.")),
        ComicFact(id: "fact-136", category: "Marvel", text: String(localized: "'Avengers Assemble!' has become one of the team's most recognizable slogans.")),
        ComicFact(id: "fact-137", category: "Marvel", text: String(localized: "Daredevil #1 was published in 1964.")),
        ComicFact(id: "fact-138", category: "Marvel", text: String(localized: "Matt Murdock is a hero whose other senses became extraordinarily sharp after he lost his sight.")),
        ComicFact(id: "fact-139", category: "Marvel", text: String(localized: "Daredevil deals with the themes of crime and justice through his identity as both a lawyer and a night hero.")),
        ComicFact(id: "fact-140", category: "Marvel", text: String(localized: "Frank Miller's Daredevil era brought elements like Elektra and The Hand to the center of the series.")),
        ComicFact(id: "fact-141", category: "Marvel", text: String(localized: "Black Panther first appeared in 1966's Fantastic Four #52.")),
        ComicFact(id: "fact-142", category: "Marvel", text: String(localized: "T'Challa is the king and protector of the fictional African country of Wakanda.")),
        ComicFact(id: "fact-143", category: "Marvel", text: String(localized: "Black Panther became one of the most important black heroes in mainstream American superhero comics.")),
        ComicFact(id: "fact-144", category: "Marvel", text: String(localized: "Vibranium is one of the primary fictional sources of Wakandan mythology.")),
        ComicFact(id: "fact-145", category: "Marvel", text: String(localized: "The Silver Surfer first appeared in 1966's Fantastic Four #48.")),
        ComicFact(id: "fact-146", category: "Marvel", text: String(localized: "Jack Kirby designed the Silver Surfer.")),
        ComicFact(id: "fact-147", category: "Marvel", text: String(localized: "Silver Surfer was introduced as the forerunner of Galactus.")),
        ComicFact(id: "fact-148", category: "Marvel", text: String(localized: "Norrin Radd is the Silver Surfer's best known real name.")),
        ComicFact(id: "fact-149", category: "Marvel", text: String(localized: "Wolverine's brief introduction was in The Incredible Hulk #180, with his first major appearance in #181.")),
        ComicFact(id: "fact-150", category: "Marvel", text: String(localized: "Wolverine joined the new roster of X-Men in 1975 with Giant-Size X-Men #1.")),
        ComicFact(id: "fact-151", category: "Marvel", text: String(localized: "The name Logan is one of the names most identified with Wolverine.")),
        ComicFact(id: "fact-152", category: "Marvel", text: String(localized: "Adamantium-coated skeleton and healing factor are Wolverine's most well-known features.")),
        ComicFact(id: "fact-153", category: "Marvel", text: String(localized: "The Punisher first appeared in 1974's The Amazing Spider-Man #129.")),
        ComicFact(id: "fact-154", category: "Marvel", text: String(localized: "The Punisher was initially an anti-hero figure used against Spider-Man.")),
        ComicFact(id: "fact-155", category: "Marvel", text: String(localized: "Frank Castle is the civilian identity of the Punisher.")),
        ComicFact(id: "fact-156", category: "Marvel", text: String(localized: "The skull logo on the Punisher's chest has become one of the most easily recognized symbols in the comic book world.")),
        ComicFact(id: "fact-157", category: "Marvel", text: String(localized: "Moon Knight first appeared in Werewolf by Night #32 in 1975.")),
        ComicFact(id: "fact-158", category: "Marvel", text: String(localized: "Moon Knight was originally conceived as a mercenary opposing the Werewolf by Night.")),
        ComicFact(id: "fact-159", category: "Marvel", text: String(localized: "Marc Spector is one of the key identities associated with Moon Knight.")),
        ComicFact(id: "fact-160", category: "Marvel", text: String(localized: "The Moon Knight series combines crime, mysticism and psychological narrative in different proportions.")),
        ComicFact(id: "fact-161", category: "Marvel", text: String(localized: "Deadpool first appeared in 1991's The New Mutants #98.")),
        ComicFact(id: "fact-162", category: "Marvel", text: String(localized: "Deadpool was created by Rob Liefeld and Fabian Nicieza.")),
        ComicFact(id: "fact-163", category: "Marvel", text: String(localized: "Wade Wilson is Deadpool's best-known real name.")),
        ComicFact(id: "fact-164", category: "Marvel", text: String(localized: "Deadpool's fourth-wall-breaking humor became one of the character's main characteristics in the following years.")),
        ComicFact(id: "fact-165", category: "Marvel", text: String(localized: "The Eddie Brock version of Venom made his full appearance in 1988's The Amazing Spider-Man #300.")),
        ComicFact(id: "fact-166", category: "Marvel", text: String(localized: "The alien symbiote was linked to Spider-Man's black suit before Eddie Brock.")),
        ComicFact(id: "fact-167", category: "Marvel", text: String(localized: "Over the years, Venom has taken on roles ranging from Spider-Man antagonist to anti-hero.")),
        ComicFact(id: "fact-168", category: "Marvel", text: String(localized: "The Symbiote mythology later expanded greatly with characters such as Carnage and Knull.")),
        ComicFact(id: "fact-169", category: "Marvel", text: String(localized: "Miles Morales first appeared in Ultimate Fallout #4 in 2011.")),
        ComicFact(id: "fact-170", category: "Marvel", text: String(localized: "Miles Morales was created by Brian Michael Bendis and Sara Pichelli.")),
        ComicFact(id: "fact-171", category: "Marvel", text: String(localized: "Miles first took up the mantle of Spider-Man within the Ultimate Universe.")),
        ComicFact(id: "fact-172", category: "Marvel", text: String(localized: "Miles later moved into the main Marvel continuity and began living as Spider-Man in the same universe as Peter Parker.")),
        ComicFact(id: "fact-173", category: "Marvel", text: String(localized: "Kamala Khan's Ms. The Marvel series started in 2014.")),
        ComicFact(id: "fact-174", category: "Marvel", text: String(localized: "Kamala Khan is a young Pakistani-American heroine living in Jersey City.")),
        ComicFact(id: "fact-175", category: "Marvel", text: String(localized: "Kamala's hero name is Ms., which Carol Danvers previously used. It inherits from the Marvel identity.")),
        ComicFact(id: "fact-176", category: "Marvel", text: String(localized: "Kamala Khan quickly became one of the most important names of the young generation Marvel heroes.")),
        ComicFact(id: "fact-177", category: "Marvel", text: String(localized: "Marvel Super Heroes Secret Wars was published as a 12-issue event in 1984.")),
        ComicFact(id: "fact-178", category: "Marvel", text: String(localized: "Secret Wars is written by Jim Shooter.")),
        ComicFact(id: "fact-179", category: "Marvel", text: String(localized: "Secret Wars brought together many of Marvel's heroes and villains in the artificial world called Battleworld.")),
        ComicFact(id: "fact-180", category: "Marvel", text: String(localized: "One of the most notable early uses of Spider-Man's black suit in comics is during the Secret Wars era.")),
        ComicFact(id: "fact-181", category: "Marvel", text: String(localized: "The Infinity Gauntlet was published as a six-issue miniseries in 1991.")),
        ComicFact(id: "fact-182", category: "Marvel", text: String(localized: "Infinity Gauntlet is written by Jim Starlin.")),
        ComicFact(id: "fact-183", category: "Marvel", text: String(localized: "George Pérez is among the main artists in the early issues of the series, and Ron Lim is among the main artists in the sequels.")),
        ComicFact(id: "fact-184", category: "Marvel", text: String(localized: "The combination of the Infinity Gems into one glove made Thanos one of the central threats of the Marvel universe.")),
        ComicFact(id: "fact-185", category: "Marvel", text: String(localized: "Civil War 1 was published as a seven-issue main series between 2006 and 2007.")),
        ComicFact(id: "fact-186", category: "Marvel", text: String(localized: "Civil War was written by Mark Millar and drawn by Steve McNiven.")),
        ComicFact(id: "fact-187", category: "Marvel", text: String(localized: "At the heart of Civil War is the debate over state registration of superheroes.")),
        ComicFact(id: "fact-188", category: "Marvel", text: String(localized: "Captain America and Iron Man became the most visible leaders of opposing sides of the Civil War.")),
        ComicFact(id: "fact-189", category: "Marvel", text: String(localized: "House of M was published as an eight-issue event in 2005.")),
        ComicFact(id: "fact-190", category: "Marvel", text: String(localized: "House of M was written by Brian Michael Bendis and drawn by Olivier Coipel.")),
        ComicFact(id: "fact-191", category: "Marvel", text: String(localized: "House of M is based on an alternate reality altered by Scarlet Witch.")),
        ComicFact(id: "fact-192", category: "Marvel", text: String(localized: "The massive shift in the mutant population post-House of M affected the X-Men line for years.")),
        ComicFact(id: "fact-193", category: "Marvel", text: String(localized: "Kraven's Last Hunt was published as a six-part Spider-Man story in 1987.")),
        ComicFact(id: "fact-194", category: "Marvel", text: String(localized: "Kraven's Last Hunt was written by J. M. DeMatteis and drawn by Mike Zeck.")),
        ComicFact(id: "fact-195", category: "Marvel", text: String(localized: "The story was published sequentially in three different Spider-Man titles.")),
        ComicFact(id: "fact-196", category: "Marvel", text: String(localized: "Kraven's Last Hunt is one of the famous Spider-Man narratives that combines the superhero story with the psychological horror tone.")),
        ComicFact(id: "fact-197", category: "Marvel", text: String(localized: "The Ultimate Marvel line began in 2000 as a modernized alternate Marvel universe.")),
        ComicFact(id: "fact-198", category: "Marvel", text: String(localized: "Ultimate Spider-Man has been one of the longest-running and influential titles in the Ultimate line.")),
        ComicFact(id: "fact-199", category: "Marvel", text: String(localized: "The Ultimate universe reinterpreted the origins of classic characters for a new generation of readers.")),
        ComicFact(id: "fact-200", category: "Marvel", text: String(localized: "Miles Morales became one of the most important characters who was first born in the Ultimate universe and later transferred to the main Marvel universe.")),
        ComicFact(id: "fact-201", category: "History & Creators", text: String(localized: "Will Eisner's The Spirit began appearing in newspaper supplements in 1940.")),
        ComicFact(id: "fact-202", category: "History & Creators", text: String(localized: "Will Eisner's 1978 novel A Contract with God was influential in popularizing the term 'graphic novel'.")),
        ComicFact(id: "fact-203", category: "History & Creators", text: String(localized: "The Eisner Awards are named after Will Eisner.")),
        ComicFact(id: "fact-204", category: "History & Creators", text: String(localized: "Will Eisner is one of the names who popularized the expression 'sequential art' when describing comic book narration.")),
        ComicFact(id: "fact-205", category: "History & Creators", text: String(localized: "Jack Kirby is one of the creators of Captain America, along with Joe Simon.")),
        ComicFact(id: "fact-206", category: "History & Creators", text: String(localized: "Jack Kirby played a major role in the creation of very different universes such as Fantastic Four, X-Men and New Gods.")),
        ComicFact(id: "fact-207", category: "History & Creators", text: String(localized: "The black dotted energy texture seen in Kirby's energetic cosmic drawings is nicknamed 'Kirby Krackle' by fans.")),
        ComicFact(id: "fact-208", category: "History & Creators", text: String(localized: "Jack Kirby developed a series of tie-in series for DC in the 1970s called Fourth World.")),
        ComicFact(id: "fact-209", category: "History & Creators", text: String(localized: "Stan Lee worked as a writer, editor and publishing executive at Marvel for many years.")),
        ComicFact(id: "fact-210", category: "History & Creators", text: String(localized: "Stan Lee's editorial style that speaks directly to the reader has become an important part of Marvel's brand personality.")),
        ComicFact(id: "fact-211", category: "History & Creators", text: String(localized: "Stan Lee developed many Marvel characters with his artistic partners.")),
        ComicFact(id: "fact-212", category: "History & Creators", text: String(localized: "Columns titled 'Stan's Soapbox' were among Lee's famous publications through which he communicated directly with readers.")),
        ComicFact(id: "fact-213", category: "History & Creators", text: String(localized: "Steve Ditko is one of the co-creators of Spider-Man.")),
        ComicFact(id: "fact-214", category: "History & Creators", text: String(localized: "Steve Ditko is also the co-creator of Doctor Strange.")),
        ComicFact(id: "fact-215", category: "History & Creators", text: String(localized: "The web pattern on Ditko's Spider-Man costume became one of the character's most enduring visual features.")),
        ComicFact(id: "fact-216", category: "History & Creators", text: String(localized: "Steve Ditko later starred in The Question and Mr. He has created influential characters in different publishers such as A.")),
        ComicFact(id: "fact-217", category: "History & Creators", text: String(localized: "Joe Simon created Captain America with Jack Kirby.")),
        ComicFact(id: "fact-218", category: "History & Creators", text: String(localized: "The duo of Simon and Kirby worked together on numerous adventure, crime and superhero comics in the 1940s.")),
        ComicFact(id: "fact-219", category: "History & Creators", text: String(localized: "Young Romance is one of Simon and Kirby's important works that popularized the romantic comic book genre.")),
        ComicFact(id: "fact-220", category: "History & Creators", text: String(localized: "Joe Simon also worked for a long time on the editorial and publishing side.")),
        ComicFact(id: "fact-221", category: "History & Creators", text: String(localized: "Jerry Siegel and Joe Shuster are the creators of Superman.")),
        ComicFact(id: "fact-222", category: "History & Creators", text: String(localized: "Siegel and Shuster began developing the idea for Superman years before Action Comics #1.")),
        ComicFact(id: "fact-223", category: "History & Creators", text: String(localized: "The success of Superman fueled the superhero boom in the American comic book industry.")),
        ComicFact(id: "fact-224", category: "History & Creators", text: String(localized: "Siegel and Shuster's rights to Superman are one of the best-known examples in the history of creator rights disputes.")),
        ComicFact(id: "fact-225", category: "History & Creators", text: String(localized: "Bill Finger is one of Batman's primary creative partners.")),
        ComicFact(id: "fact-226", category: "History & Creators", text: String(localized: "Bill Finger wrote the screenplay for the first Batman story.")),
        ComicFact(id: "fact-227", category: "History & Creators", text: String(localized: "The Bruce Wayne name and many elements of Batman's early mythology were shaped by Bill Finger's contributions.")),
        ComicFact(id: "fact-228", category: "History & Creators", text: String(localized: "Starting in 2015, DC began to mention Bill Finger more visibly in its official creative credits for Batman productions.")),
        ComicFact(id: "fact-229", category: "History & Creators", text: String(localized: "George Pérez is the main artist of Crisis on Infinite Earths.")),
        ComicFact(id: "fact-230", category: "History & Creators", text: String(localized: "George Pérez played a central role in the rebirth of The New Teen Titans with Marv Wolfman.")),
        ComicFact(id: "fact-231", category: "History & Creators", text: String(localized: "Pérez re-established the character's mythology as the writer and artist of Wonder Woman in the 1980s.")),
        ComicFact(id: "fact-232", category: "History & Creators", text: String(localized: "George Pérez was famous for drawing large casts of characters in detail on the same page.")),
        ComicFact(id: "fact-233", category: "History & Creators", text: String(localized: "Neal Adams' realistic anatomy influenced the aesthetics of superhero drawing in the 1960s and 1970s.")),
        ComicFact(id: "fact-234", category: "History & Creators", text: String(localized: "Neal Adams played an important role in Batman's return to his dark detective roots with Denny O'Neil.")),
        ComicFact(id: "fact-235", category: "History & Creators", text: String(localized: "The Green Lantern/Green Arrow era is one of Neal Adams' most famous works with social content.")),
        ComicFact(id: "fact-236", category: "History & Creators", text: String(localized: "Neal Adams was one of the industry figures who backed Jerry Siegel and Joe Shuster's Superman rights and credits.")),
        ComicFact(id: "fact-237", category: "History & Creators", text: String(localized: "Denny O'Neil wrote Batman, Green Lantern and Green Arrow stories for a long time.")),
        ComicFact(id: "fact-238", category: "History & Creators", text: String(localized: "O'Neil and Neal Adams are one of the main creative teams in the creation of the Ra's al Ghul era.")),
        ComicFact(id: "fact-239", category: "History & Creators", text: String(localized: "Denny O'Neil later played an important role as an editor in the Batman series.")),
        ComicFact(id: "fact-240", category: "History & Creators", text: String(localized: "O'Neil's work was instrumental in moving Batman from its 1960s camp tone to a more serious detective narrative.")),
        ComicFact(id: "fact-241", category: "History & Creators", text: String(localized: "Alan Moore is the author of Watchmen.")),
        ComicFact(id: "fact-242", category: "History & Creators", text: String(localized: "Alan Moore's Swamp Thing era took the character from his traditional monster origin to a more metaphysical structure.")),
        ComicFact(id: "fact-243", category: "History & Creators", text: String(localized: "V for Vendetta and From Hell are Moore's best-known non-superhero works.")),
        ComicFact(id: "fact-244", category: "History & Creators", text: String(localized: "Alan Moore's works exemplify the use of symmetry, parallel editing, and repeated visual motifs in comic book form.")),
        ComicFact(id: "fact-245", category: "History & Creators", text: String(localized: "Frank Miller's Daredevil run significantly strengthened the crime-noir aspect of the character.")),
        ComicFact(id: "fact-246", category: "History & Creators", text: String(localized: "Frank Miller wrote and drew The Dark Knight Returns.")),
        ComicFact(id: "fact-247", category: "History & Creators", text: String(localized: "Batman: Year One is written by Frank Miller.")),
        ComicFact(id: "fact-248", category: "History & Creators", text: String(localized: "Frank Miller later found great success with creatively owned projects such as Sin City.")),
        ComicFact(id: "fact-249", category: "History & Creators", text: String(localized: "Neil Gaiman is the author of The Sandman.")),
        ComicFact(id: "fact-250", category: "History & Creators", text: String(localized: "Neil Gaiman's Marvel 1602 series reinterpreted Marvel heroes in an Elizabethan-like world.")),
        ComicFact(id: "fact-251", category: "History & Creators", text: String(localized: "The Sandman is a series in which Gaiman combines mythology, history and literary references into a single long narrative.")),
        ComicFact(id: "fact-252", category: "History & Creators", text: String(localized: "In addition to comics, Neil Gaiman also worked in the fields of novels, short stories, screenplays and children's literature.")),
        ComicFact(id: "fact-253", category: "History & Creators", text: String(localized: "Chris Claremont was one of the most defining writers of the X-Men franchise from 1975 to 1991.")),
        ComicFact(id: "fact-254", category: "History & Creators", text: String(localized: "Dark Phoenix Saga is one of the most famous X-Men stories of the Claremont era.")),
        ComicFact(id: "fact-255", category: "History & Creators", text: String(localized: "Days of Future Past is one of the classic X-Men narratives of the Chris Claremont and John Byrne era.")),
        ComicFact(id: "fact-256", category: "History & Creators", text: String(localized: "Claremont's long-running substories and character relationships strongly influenced the X-Men's serial narrative model.")),
        ComicFact(id: "fact-257", category: "History & Creators", text: String(localized: "John Byrne played a key role as an artist and co-story developer during the Uncanny X-Men era.")),
        ComicFact(id: "fact-258", category: "History & Creators", text: String(localized: "John Byrne both wrote and drew Fantastic Four in the 1980s.")),
        ComicFact(id: "fact-259", category: "History & Creators", text: String(localized: "With 1986's The Man of Steel miniseries, Byrne reestablished Superman's post-modern origin.")),
        ComicFact(id: "fact-260", category: "History & Creators", text: String(localized: "Alpha Flight is one of the Marvel teams that is strongly identified with John Byrne.")),
        ComicFact(id: "fact-261", category: "History & Creators", text: String(localized: "Walt Simonson's Thor era is one of the most beloved Marvel creative eras of the 1980s.")),
        ComicFact(id: "fact-262", category: "History & Creators", text: String(localized: "Beta Ray Bill was first introduced in Walt Simonson's Thor #337.")),
        ComicFact(id: "fact-263", category: "History & Creators", text: String(localized: "In Simonson's Thor stories, text and visual effects were used as active parts of the page design.")),
        ComicFact(id: "fact-264", category: "History & Creators", text: String(localized: "Walt Simonson later worked as a writer and artist on DC projects such as Orion.")),
        ComicFact(id: "fact-265", category: "History & Creators", text: String(localized: "Jim Lee became one of the most recognized artists of the X-Men line in the early 1990s.")),
        ComicFact(id: "fact-266", category: "History & Creators", text: String(localized: "The variant covers of 1991's X-Men #1 are one of the most famous examples of the collectible market.")),
        ComicFact(id: "fact-267", category: "History & Creators", text: String(localized: "Jim Lee later took part in the creation of WildStorm.")),
        ComicFact(id: "fact-268", category: "History & Creators", text: String(localized: "Jim Lee worked with Jeph Loeb on Batman: Hush.")),
        ComicFact(id: "fact-269", category: "History & Creators", text: String(localized: "Todd McFarlane gained immense popularity in the late 1980s with his Amazing Spider-Man drawings.")),
        ComicFact(id: "fact-270", category: "History & Creators", text: String(localized: "Todd McFarlane, along with David Michelinie, played an important role in the creation of Venom's visual identity.")),
        ComicFact(id: "fact-271", category: "History & Creators", text: String(localized: "McFarlane wrote and drew the first issue of the solo series Spider-Man in 1990.")),
        ComicFact(id: "fact-272", category: "History & Creators", text: String(localized: "Spawn is the creatively owned series started by Todd McFarlane under Image Comics in 1992.")),
        ComicFact(id: "fact-273", category: "History & Creators", text: String(localized: "Image Comics was founded in 1992 by high-profile artists who left major publishers.")),
        ComicFact(id: "fact-274", category: "History & Creators", text: String(localized: "One of Image's founding principles was to allow creators to retain rights to characters.")),
        ComicFact(id: "fact-275", category: "History & Creators", text: String(localized: "Spawn, Savage Dragon, and WildC.A.T.s are Image's early icon series.")),
        ComicFact(id: "fact-276", category: "History & Creators", text: String(localized: "Over time, Image has become the publisher of a number of creatively-owned hit series in genres other than superheroes.")),
        ComicFact(id: "fact-277", category: "History & Creators", text: String(localized: "Dark Horse Comics was founded in 1986 by Mike Richardson.")),
        ComicFact(id: "fact-278", category: "History & Creators", text: String(localized: "The Dark Horse Presents anthology series was a major showcase in the company's early life.")),
        ComicFact(id: "fact-279", category: "History & Creators", text: String(localized: "Works like Hellboy, Sin City, and The Mask are strongly associated with Dark Horse history.")),
        ComicFact(id: "fact-280", category: "History & Creators", text: String(localized: "Dark Horse has also published comics in licensed universes such as Star Wars and Alien for many years.")),
        ComicFact(id: "fact-281", category: "History & Creators", text: String(localized: "Comics Code Authority was established in 1954 as the self-regulatory system of the American comic book industry.")),
        ComicFact(id: "fact-282", category: "History & Creators", text: String(localized: "The Comics Code seal appeared on mainstream American comic book covers for many years.")),
        ComicFact(id: "fact-283", category: "History & Creators", text: String(localized: "Code rules severely limited the presentation of narratives of fear, crime and violence.")),
        ComicFact(id: "fact-284", category: "History & Creators", text: String(localized: "Major American publishers largely abandoned the Comics Code in the late 2000s and early 2010s.")),
        ComicFact(id: "fact-285", category: "History & Creators", text: String(localized: "The Direct Market model is based on the non-refundable distribution of comic books to specialty stores.")),
        ComicFact(id: "fact-286", category: "History & Creators", text: String(localized: "Direct Market fueled the growth of comic book stores starting in the 1970s.")),
        ComicFact(id: "fact-287", category: "History & Creators", text: String(localized: "Direct Market has created a marketplace that allows titles that appeal to smaller readerships to survive.")),
        ComicFact(id: "fact-288", category: "History & Creators", text: String(localized: "Specialist comic shops have become centers of collectibles, back issues and independent publishing culture.")),
        ComicFact(id: "fact-289", category: "History & Creators", text: String(localized: "Free Comic Book Day was first held in 2002.")),
        ComicFact(id: "fact-290", category: "History & Creators", text: String(localized: "Free Comic Book Day is traditionally held on the first Saturday of May.")),
        ComicFact(id: "fact-291", category: "History & Creators", text: String(localized: "Participating comic book shops at the event give specially selected comic books to readers free of charge.")),
        ComicFact(id: "fact-292", category: "History & Creators", text: String(localized: "One of the goals of Free Comic Book Day is to introduce new readers to local comic shops.")),
        ComicFact(id: "fact-293", category: "History & Creators", text: String(localized: "The Eisner Awards is one of the comic book industry's most well-known awards programs.")),
        ComicFact(id: "fact-294", category: "History & Creators", text: String(localized: "The awards are named after Will Eisner, creator of The Spirit.")),
        ComicFact(id: "fact-295", category: "History & Creators", text: String(localized: "Eisner Awards results are traditionally associated with the San Diego Comic-Con period.")),
        ComicFact(id: "fact-296", category: "History & Creators", text: String(localized: "Eisner categories cover many different areas such as author, illustrator, series, new series, digital publication and archive projects.")),
        ComicFact(id: "fact-297", category: "History & Creators", text: String(localized: "San Diego Comic-Con traces its roots back to comic book-focused conventions held in 1970.")),
        ComicFact(id: "fact-298", category: "History & Creators", text: String(localized: "Over the years, San Diego Comic-Con has evolved from a comic book-centric event to a broad pop culture gathering.")),
        ComicFact(id: "fact-299", category: "History & Creators", text: String(localized: "Comic-Con panels are one of the important platforms for new comic book projects and creative team announcements.")),
        ComicFact(id: "fact-300", category: "History & Creators", text: String(localized: "San Diego Comic-Con also hosts comic book industry events such as the Eisner Awards.")),
        ComicFact(id: "fact-301", category: "Comic Book Language", text: String(localized: "The term Golden Age generally refers to the American superhero era that spanned from the late 1930s to the early 1950s.")),
        ComicFact(id: "fact-302", category: "Comic Book Language", text: String(localized: "Superman, Batman, Wonder Woman and Captain America are among the most enduring heroes of the Golden Age.")),
        ComicFact(id: "fact-303", category: "Comic Book Language", text: String(localized: "During the Golden Age, comic books achieved huge sales in genres as diverse as war, crime, humor, and horror.")),
        ComicFact(id: "fact-304", category: "Comic Book Language", text: String(localized: "Some of the Golden Age characters later returned to modern comics with parallel universe and legacy hero ideas.")),
        ComicFact(id: "fact-305", category: "Comic Book Language", text: String(localized: "The term Silver Age generally describes the American superhero revival that spanned from the mid-1950s to around 1970.")),
        ComicFact(id: "fact-306", category: "Comic Book Language", text: String(localized: "Barry Allen's debut in Showcase #4 is a common cue for the Silver Age.")),
        ComicFact(id: "fact-307", category: "Comic Book Language", text: String(localized: "During the Silver Age, science fiction concepts became very common in superhero comics.")),
        ComicFact(id: "fact-308", category: "Comic Book Language", text: String(localized: "Marvel's characters like the Fantastic Four and Spider-Man shaped the character-driven superhero narrative of the Silver Age.")),
        ComicFact(id: "fact-309", category: "Comic Book Language", text: String(localized: "The term Bronze Age mostly refers to the American comic book era of the 1970s and first half of the 1980s.")),
        ComicFact(id: "fact-310", category: "Comic Book Language", text: String(localized: "In the Bronze Age, themes such as social problems, drugs, the environment and urban crime became more visible.")),
        ComicFact(id: "fact-311", category: "Comic Book Language", text: String(localized: "Green Lantern/Green Arrow stories are frequently cited examples of the social narrative of the Bronze Age.")),
        ComicFact(id: "fact-312", category: "Comic Book Language", text: String(localized: "The Bronze Age was a period in comic book art when more realistic anatomy and more complex page design became common.")),
        ComicFact(id: "fact-313", category: "Comic Book Language", text: String(localized: "The phrase Modern Age is often used to describe the broad period of American comics spanning from the mid-1980s to the present.")),
        ComicFact(id: "fact-314", category: "Comic Book Language", text: String(localized: "Watchmen and The Dark Knight Returns are frequently mentioned works in discussions of the beginning of the Modern Age.")),
        ComicFact(id: "fact-315", category: "Comic Book Language", text: String(localized: "Throughout the Modern Age, creator-owned publishing, the graphic novel market, and digital comics have grown greatly.")),
        ComicFact(id: "fact-316", category: "Comic Book Language", text: String(localized: "In modern comics, a single character can appear in the main continuity, alternate universe, and standalone mini-series simultaneously.")),
        ComicFact(id: "fact-317", category: "Comic Book Language", text: String(localized: "A panel is a framed area on a comic book page that shows a single period of time or action.")),
        ComicFact(id: "fact-318", category: "Comic Book Language", text: String(localized: "Panel size can change reading speed and the sense of importance of the scene.")),
        ComicFact(id: "fact-319", category: "Comic Book Language", text: String(localized: "The use of frameless panels can increase the feeling of the image extending beyond the borders of the page.")),
        ComicFact(id: "fact-320", category: "Comic Book Language", text: String(localized: "As the number of panels on a page increases, the rhythm of the narrative generally feels more fragmented and faster.")),
        ComicFact(id: "fact-321", category: "Comic Book Language", text: String(localized: "Gutter is the common English term for the space between two panels.")),
        ComicFact(id: "fact-322", category: "Comic Book Language", text: String(localized: "The reader connects the two panels by mentally completing the movement not shown in the gutter.")),
        ComicFact(id: "fact-323", category: "Comic Book Language", text: String(localized: "The width of the gutter can affect the sense of time lapse or scene separation.")),
        ComicFact(id: "fact-324", category: "Comic Book Language", text: String(localized: "Some experimental comics play with the concept of gutter by removing panel boundaries altogether.")),
        ComicFact(id: "fact-325", category: "Comic Book Language", text: String(localized: "A splash page is a page where a single large image covers the entire or most of the page.")),
        ComicFact(id: "fact-326", category: "Comic Book Language", text: String(localized: "Splash page is usually used for important introduction, big action or dramatic location introduction.")),
        ComicFact(id: "fact-327", category: "Comic Book Language", text: String(localized: "The splash page on the first page can also carry the title and creator credits.")),
        ComicFact(id: "fact-328", category: "Comic Book Language", text: String(localized: "Some comics use a splash page in the finale to create a big visual impact.")),
        ComicFact(id: "fact-329", category: "Comic Book Language", text: String(localized: "Double-page spread is a type of layout in which a single composition is spread across two facing pages.")),
        ComicFact(id: "fact-330", category: "Comic Book Language", text: String(localized: "A two-page spread magnifies the sense of scale, especially in battle, cityscape and crowd scenes.")),
        ComicFact(id: "fact-331", category: "Comic Book Language", text: String(localized: "Incorrect separation of double page spreads on digital readers can ruin the composition.")),
        ComicFact(id: "fact-332", category: "Comic Book Language", text: String(localized: "Landscape double page mode is one of the ways to mimic the feeling of reading physical comics on a digital screen.")),
        ComicFact(id: "fact-333", category: "Comic Book Language", text: String(localized: "Speech balloon is the basic tool that visualizes characters' speech on the comic page.")),
        ComicFact(id: "fact-334", category: "Comic Book Language", text: String(localized: "The balloon tail usually indicates which character the speech is coming from.")),
        ComicFact(id: "fact-335", category: "Comic Book Language", text: String(localized: "Different balloon shapes can represent different sounds such as whispering, shouting, robotic voice or telepathy.")),
        ComicFact(id: "fact-336", category: "Comic Book Language", text: String(localized: "Lettering is critical to the readability of speech bubbles and the visual rhythm on the page.")),
        ComicFact(id: "fact-337", category: "Comic Book Language", text: String(localized: "Caption boxes can be used for narrator voice, location information, time passage or interior monologue.")),
        ComicFact(id: "fact-338", category: "Comic Book Language", text: String(localized: "Even though the caption and speech balloon carry the same text, they create the feeling of a different narrator in the reader.")),
        ComicFact(id: "fact-339", category: "Comic Book Language", text: String(localized: "In modern comics, character voiceovers are often separated by colored or specially designed caption boxes.")),
        ComicFact(id: "fact-340", category: "Comic Book Language", text: String(localized: "The placement of caption boxes can direct the route the eye follows on the page.")),
        ComicFact(id: "fact-341", category: "Comic Book Language", text: String(localized: "Thought balloon was very common in classic superhero comics to show inner thought.")),
        ComicFact(id: "fact-342", category: "Comic Book Language", text: String(localized: "Thought balloon is usually drawn with cloud-shaped edges and a tail made of small bubbles.")),
        ComicFact(id: "fact-343", category: "Comic Book Language", text: String(localized: "After the 1980s, the use of captions for internal thought in mainstream American comics partially replaced the thought balloon.")),
        ComicFact(id: "fact-344", category: "Comic Book Language", text: String(localized: "Thought balloon can be used today to create a retro or consciously classical narrative feel.")),
        ComicFact(id: "fact-345", category: "Comic Book Language", text: String(localized: "Sound effects in comics establish a direct link between text and visuals.")),
        ComicFact(id: "fact-346", category: "Comic Book Language", text: String(localized: "Effects such as 'BAM', 'THOOM' or 'SNIKT' convey the feeling of movement and force as well as sound.")),
        ComicFact(id: "fact-347", category: "Comic Book Language", text: String(localized: "The letterform of the sound effect can change the harshness, technological structure or emotion of the scene.")),
        ComicFact(id: "fact-348", category: "Comic Book Language", text: String(localized: "Some artists use sound effects as a physical part of the panel composition.")),
        ComicFact(id: "fact-349", category: "Comic Book Language", text: String(localized: "A one-shot is an independent comic book publication completed in a single issue.")),
        ComicFact(id: "fact-350", category: "Comic Book Language", text: String(localized: "One-shots can tell a side story of an ongoing series or be completely independent.")),
        ComicFact(id: "fact-351", category: "Comic Book Language", text: String(localized: "Special occasion, crossover, or character anniversary releases often appear in a one-shot format.")),
        ComicFact(id: "fact-352", category: "Comic Book Language", text: String(localized: "The one-shot format can make it easier for new readers to try out a character without reading long continuity.")),
        ComicFact(id: "fact-353", category: "Comic Book Language", text: String(localized: "Annual is a special issue published annually, usually in addition to the regular issues of an ongoing series.")),
        ComicFact(id: "fact-354", category: "Comic Book Language", text: String(localized: "Annual issues may be longer than the regular issue.")),
        ComicFact(id: "fact-355", category: "Comic Book Language", text: String(localized: "Annuals sometimes continue the important story of the main series, sometimes tell independent adventures.")),
        ComicFact(id: "fact-356", category: "Comic Book Language", text: String(localized: "In some crossover reading orders, annual issues may be an obligatory part of the main story.")),
        ComicFact(id: "fact-357", category: "Comic Book Language", text: String(localized: "Limited series is a series that is planned from the beginning with a certain number of episodes.")),
        ComicFact(id: "fact-358", category: "Comic Book Language", text: String(localized: "Four, six, and twelve issues are very common limited series lengths in American comics.")),
        ComicFact(id: "fact-359", category: "Comic Book Language", text: String(localized: "The limited series format makes it easier for the creative team to build a story around a predefined ending.")),
        ComicFact(id: "fact-360", category: "Comic Book Language", text: String(localized: "Watchmen is a 12-issue limited series and Kingdom Come is a four-issue famous limited series.")),
        ComicFact(id: "fact-361", category: "Comic Book Language", text: String(localized: "Ongoing series is a regularly continuing comic book series without a set final issue.")),
        ComicFact(id: "fact-362", category: "Comic Book Language", text: String(localized: "Ongoing series can last for years with the same numbering even if the creative team changes.")),
        ComicFact(id: "fact-363", category: "Comic Book Language", text: String(localized: "Major publishers sometimes reboot ongoing series with new #1 issues.")),
        ComicFact(id: "fact-364", category: "Comic Book Language", text: String(localized: "Legacy numbering is a method of returning to the historical number of the series by displaying the total of the numbers in different volumes.")),
        ComicFact(id: "fact-365", category: "Comic Book Language", text: String(localized: "Trade paperback usually collects several previously published issues into one softcover book.")),
        ComicFact(id: "fact-366", category: "Comic Book Language", text: String(localized: "The abbreviation TPB is commonly used for trade paperback.")),
        ComicFact(id: "fact-367", category: "Comic Book Language", text: String(localized: "A trade usually combines a single story arc or several related issues.")),
        ComicFact(id: "fact-368", category: "Comic Book Language", text: String(localized: "Trade collections facilitated the dissemination of series in general bookstores other than comic book stores.")),
        ComicFact(id: "fact-369", category: "Comic Book Language", text: String(localized: "Hardcover collections offer a harder cover and often greater production quality than trade paperback.")),
        ComicFact(id: "fact-370", category: "Comic Book Language", text: String(localized: "Deluxe hardcover editions are sometimes printed at a larger size than the standard comic book page.")),
        ComicFact(id: "fact-371", category: "Comic Book Language", text: String(localized: "Hardcover collections may include additional sketches, cover gallery and creative notes.")),
        ComicFact(id: "fact-372", category: "Comic Book Language", text: String(localized: "The same story can be reprinted over the years in many different formats such as paperback, hardcover, deluxe and omnibus.")),
        ComicFact(id: "fact-373", category: "Comic Book Language", text: String(localized: "Omnibus is a comprehensive collection format that collects multiple comic book issues into one large volume.")),
        ComicFact(id: "fact-374", category: "Comic Book Language", text: String(localized: "Omnibus volumes can contain hundreds or even more than a thousand pages.")),
        ComicFact(id: "fact-375", category: "Comic Book Language", text: String(localized: "Omnibus editions make it easy to read a long creative period or major event in one volume.")),
        ComicFact(id: "fact-376", category: "Comic Book Language", text: String(localized: "The weight and binding structure of omnibuses are one of the reasons why digital readers provide a practical advantage in large collections.")),
        ComicFact(id: "fact-377", category: "Comic Book Language", text: String(localized: "Absolute and similar premium prints are usually produced with large page size and high production quality.")),
        ComicFact(id: "fact-378", category: "Comic Book Language", text: String(localized: "DC's Absolute format is designed to make artwork appear larger than standard comic size.")),
        ComicFact(id: "fact-379", category: "Comic Book Language", text: String(localized: "Deluxe and premium editions frequently include additional covers, manuscripts, or creative materials.")),
        ComicFact(id: "fact-380", category: "Comic Book Language", text: String(localized: "Premium edition names may have different meanings from publisher to publisher.")),
        ComicFact(id: "fact-381", category: "Comic Book Language", text: String(localized: "Facsimile edition aims to reproduce an old comic book issue as closely as possible to the original edition.")),
        ComicFact(id: "fact-382", category: "Comic Book Language", text: String(localized: "Facsimile editions sometimes preserve the original advertisements and editorial pages.")),
        ComicFact(id: "fact-383", category: "Comic Book Language", text: String(localized: "Facsimile editions make it easier for the modern reader to physically experience expensive collectible back issues.")),
        ComicFact(id: "fact-384", category: "Comic Book Language", text: String(localized: "A facsimile edition is a new reprint; does not have the same collectible value as the original first printing.")),
        ComicFact(id: "fact-385", category: "Comic Book Language", text: String(localized: "Variant cover is an edition of the same comic book sold with different covers, without changing its content.")),
        ComicFact(id: "fact-386", category: "Comic Book Language", text: String(localized: "Variant covers are one of the important parts of artist-oriented collecting.")),
        ComicFact(id: "fact-387", category: "Comic Book Language", text: String(localized: "Some variant covers are distributed as 'ratio variant' depending on certain order rates.")),
        ComicFact(id: "fact-388", category: "Comic Book Language", text: String(localized: "A single popular #1 issue can be published with dozens of different variant covers.")),
        ComicFact(id: "fact-389", category: "Comic Book Language", text: String(localized: "Crossover is the intersection of two or more series or characters in the same story.")),
        ComicFact(id: "fact-390", category: "Comic Book Language", text: String(localized: "Small crossover can only be between two series; A big event can span dozens of topics.")),
        ComicFact(id: "fact-391", category: "Comic Book Language", text: String(localized: "Crossover reading orders indicate the order in which the main series and tie-in numbers will be read.")),
        ComicFact(id: "fact-392", category: "Comic Book Language", text: String(localized: "Secret Wars, Crisis on Infinite Earths and Civil War are examples of large-scale crossover events.")),
        ComicFact(id: "fact-393", category: "Comic Book Language", text: String(localized: "Retcon is the common term given to the reinterpretation of previously told continuity information with a new story.")),
        ComicFact(id: "fact-394", category: "Comic Book Language", text: String(localized: "Retcon does not always completely erase the old story; sometimes it just adds new context.")),
        ComicFact(id: "fact-395", category: "Comic Book Language", text: String(localized: "Hidden kinship, forgotten events, or changed origin stories are common methods for retcon.")),
        ComicFact(id: "fact-396", category: "Comic Book Language", text: String(localized: "Long-running superhero universes frequently use retcons to manage decades of continuity.")),
        ComicFact(id: "fact-397", category: "Comic Book Language", text: String(localized: "Cliffhanger is a narrative technique that ends the chapter at a critical moment, making the reader curious about the next issue.")),
        ComicFact(id: "fact-398", category: "Comic Book Language", text: String(localized: "In monthly comics, the cliffhanger turns the wait between issues into a dramatic device.")),
        ComicFact(id: "fact-399", category: "Comic Book Language", text: String(localized: "The surprise set in the bottom right corner of the page is one of the classic cliffhanger methods that uses the effect of physical page turning.")),
        ComicFact(id: "fact-400", category: "Comic Book Language", text: String(localized: "Digital comic book readers can also keep the cliffhanger rhythm with page break and chapter break designs.")),
    ]

    static func random(excluding id: String? = nil) -> ComicFact {
        guard !all.isEmpty else { return ComicFact(id: "empty", category: "", text: String(localized: "")) }
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
    case official = "Official"
    case publisher = "Publisher"
    case community = "Community"
    case milestone = "Milestone"

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
        .init(id: "superman-day", title: "Superman Day", detail: String(localized: "DC's celebration of Superman; Tied with the April 18, 1938 release of Action Comics #1."), kind: .official, month: 4, day: 18, rule: nil),
        .init(id: "free-comic-book-day", title: "Free Comic Book Day", detail: String(localized: "Industry-wide celebration held by comic book stores on the first Saturday of May each year."), kind: .official, month: nil, day: nil, rule: .firstSaturdayOfMay),
        .init(id: "x-men-day", title: "X-Men Day", detail: String(localized: "May 13 is a publisher/promotional day used to celebrate the X-Men legacy."), kind: .publisher, month: 5, day: 13, rule: nil),
        .init(id: "spider-man-day", title: "Spider-Man Day", detail: String(localized: "The day Marvel celebrates with Spider-Man content on August 1."), kind: .publisher, month: 8, day: 1, rule: nil),
        .init(id: "read-comics-public", title: "Read Comics in Public Day", detail: String(localized: "Community day to promote public reading of comics on August 28; The date coincides with Jack Kirby's birthday."), kind: .community, month: 8, day: 28, rule: nil),
        .init(id: "batman-day", title: "Batman Day", detail: String(localized: "DC's annual global Batman celebration in September; The practice marks the third Saturday."), kind: .official, month: nil, day: nil, rule: .thirdSaturdayOfSeptember),
        .init(id: "comic-book-day", title: "National Comic Book Day", detail: String(localized: "Community day celebrating comic book art, creators and readers on September 25th."), kind: .community, month: 9, day: 25, rule: nil),
        .init(id: "wonder-woman-day", title: "Wonder Woman Day", detail: String(localized: "21 October; It's the anniversary of Wonder Woman's first appearance in All Star Comics #8."), kind: .official, month: 10, day: 21, rule: nil),
        .init(id: "batman-debut", title: "1st Batman Comics Anniversary", detail: String(localized: "Detective Comics #27 hit newsstands on March 30, 1939."), kind: .milestone, month: 3, day: 30, rule: nil),
        .init(id: "jack-kirby-birthday", title: "Jack Kirby's Birthday", detail: String(localized: "28 August 1917; It's the birthday of Jack Kirby, one of the most influential creators in comic book history."), kind: .milestone, month: 8, day: 28, rule: nil),
        .init(id: "stan-lee-birthday", title: "Stan Lee's Birthday", detail: String(localized: "December 28, 1922; Birthday of Stan Lee, one of the most well-known editors and writers in Marvel history."), kind: .milestone, month: 12, day: 28, rule: nil)
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
