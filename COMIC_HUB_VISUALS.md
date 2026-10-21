# Comic Hub visual refresh — 2026-10-21

Comics now has its own home page, distinct from the warm Book Hub and the existing Manga/Mix dashboards. The palette uses midnight navy, crimson actions, electric blue navigation accents and cream display type. The original generated ComicHubCity asset provides an inked, halftone cityscape without characters, publisher logos or embedded text. Runtime type remains selectable/accessibly announced; decorative art and dots are hidden from accessibility.

Home sections:
- City header with real collection and series counts, a reader action for the most recently read comic (or newest comic when none is in progress), and library navigation.
- Four status panels with live counts and up to three actual cover thumbnails: reading, to-read, completed and favorites.
- Continue-reading and recently-added rows, with cached covers, current progress and existing reader/context-menu behavior. Rows are bounded to eight/ten items and lazy.
- Series and character shortcuts with counts from the existing production services, computed off the main actor. No example books or invented characters are inserted.
- Existing reading goals and calendar cards remain available in a responsive layout.
- The existing “Biliyor muydun?” information box and personalized reading recommendation are restored directly below the city header. Their shuffle actions and recommendation service are preserved; the cards inherit Comic Hub's crimson accent and navy background.

The sidebar brand reads COMIC HUB in Comics; the profile-cycle icon is preserved. Books retains the amber palette. Comics also applies navy secondary surfaces to achievements, notes, smart search, Wrapped, comic details, series and characters. Series and character views use the selected profile's library, keeping novels out of comic collections and matching home counts. The manga and mix home layouts remain available.

Artwork: Assets.xcassets/ComicHubCity.imageset/city.png is an original generated decorative background, bundled for offline use. Existing user covers and reading data are displayed without modification.

Validation: Mac Catalyst Debug build succeeds. Native visual checks cover the header, four status panels, cover rows, discovery shortcuts and goal/calendar area. Series opens exactly two comic series; Characters shows Batman from the existing title detector. The completed panel opens the single completed comic. Comic achievements use navy cards and crimson progress. Switching through Manga/Books/Mix/Comics preserves the separate amber Book Hub and returns to the new Comics home. No user files, covers or progress were changed during these checks. iPad layout uses adaptive grids/ViewThatFits but has not been visually tested in this checkpoint.

## Comic Port collection browser and issue boxes

Replaced the Comics branch of the shared collection view with a dedicated collection browser. Cover display uses a uniform 2:3 viewport, an issue-number badge parsed by the existing SeriesService, two-line titles, a status indicator and a slim progress strip. Completed status is displayed as 100% without changing saved page position. Detail navigation, quick preview, favorite/status actions and content-kind actions are retained.

Users can switch between Cover Showcase and Series Boxes; layout, sort and thumbnail size have separate Comic Hub preferences. Filters operate on the current collection; sorting supports date added, title and production series/issue order. Series boxes group actual issues in responsive panels with horizontal lazy cover rows. No example issues are added. The home status shortcuts are now illustrated long-box panels with cover previews, a front label and handle; their destinations open the matching real collection.

The missing gray collection background came from its inner NavigationStack. Comic theme is now inherited through a scoped environment value and applied to inner navigation/scroll/presentation layers throughout dashboard menus, including settings, reading orders, smart collections, tools, journal, panels, backup and storage screens. Native section rows opt into the navy surface while Book Hub, Manga and Mix retain their own appearances. Reading-page colors are not altered.

Validation so far: Mac Catalyst build succeeds; native checks verify both layouts, counts (two issues/two series), completed-only filtering (one issue/one series), empty to-read filtering and restoring all issues. The visible completed issue now shows 100%, while the ongoing issue retains 27% and original page state. Covers and user records are unchanged.

Final checks include the two-column series-box layout, persistent view switching, series/issue sorting, issue-card detail navigation, empty filters and theme consistency in Reading Order, Reading Orders and Settings. System material backgrounds on Comic Hub cards now resolve to the navy surface instead of system gray; the original materials are retained outside Comic Hub. Smart Reading Order 2.0 and its related-series suggestions now use the active profile's library, matching the filtered series browser rather than including the bundled novels. No reading pages, favorites or content-kind values were changed during verification.

## Gece Mağarası — optional Comic Hub scene

Settings now offers two complete Comic Hub themes: the existing Kızıl Şehir and the new Gece Mağarası. The choice is stored under `ComicPort.ComicHub.sceneTheme`; the shell refreshes its themed view subtree on changes, retaining the selected dashboard section and library records. The palette covers navigation, library cards, settings, achievements and inherited surfaces. Books/Manga/Mix retain their profile appearances. The cyan theme uses dark foregrounds on filled accent buttons for readability.

The user-approved cavern is original generated comic-style artwork: layered rock, a multi-monitor workstation, suspended walkways, an underground lake/waterfall, a giant copper coin with generic classical relief, a geometric J playing card and a T-Rex museum sculpture. Research consulted DC’s trophy overview (https://www.dc.com/blog/2019/03/25/the-secret-origins-of-the-batcaves-best-trophies); reference images are not bundled. No character portraits, franchise logos or copied panel/set layouts are included. The user-facing name is Gece Mağarası. This provenance describes the implementation, not legal clearance or a guarantee against all IP claims. Existing library covers and the independent recommendation/fact content are not theme assets.

The scene is static, bundled for offline use and hidden from accessibility; all reading/navigation controls retain their labels. No animation, image download or new package is needed. Native Mac Catalyst validation covers theme selection in Settings, switching both ways and the cave home with its existing fact/recommendation bars.

Final validation: Mac Catalyst build succeeds. Relaunch retains Gece Mağarası as selected. Native library shows the charcoal surfaces and cyan controls with the same two issues/two series and unchanged reading progress. Dark text is verified on the sidebar selection and import button. iPad has not been visually verified in this pass.

## Kıyı Atölyesi — illustrated crimson/gold workshop

The workshop returns to the shared compact hero layout: title, live counts and reader/library actions overlay the left side of the scenic banner, with a dark leading gradient for readability. Its scene is stylized comic illustration rather than a realistic rendering. Deep burgundy surfaces, crimson primary controls, gold secondary details and warm pale text replace the copper/turquoise interface. Filled crimson controls use white text.

The user's `iron man.jpg` is a reference for workshop atmosphere only. The new generated scene is instructed to use original angular architecture and a cel-shaded graphic style, with empty exhibition niches, ocean windows, small generic cars, tool cabinets, carts and abstract technical displays. No armor, people, mannequins, franchise logos, branding, reference-image footer or circular suit assembly prop is intended. Reference bytes remain outside the app/repository. This describes provenance and design constraints, not a legal clearance guarantee.

Asset: `Assets.xcassets/ComicHubWorkshop.imageset/workshop.png`. The prior realistic coastal artwork is superseded. Theme identity/preferences, reading actions, information/recommendation cards and user data remain intact.

## Kayıp Orman — emerald rainforest

The fourth selectable Comic Hub theme uses deep forest-green canvas/surfaces, fresh moss-green primary accents, jade secondary accents and pale botanical text. The approved original illustrated background depicts dense rainforest, mist, ferns, a small distant unbranded abandoned aircraft, a foreground campfire and a winding river. The scene uses comic-style outlines and cel shading. It is decorative artwork, with no character, airline logo or film/game reference requested. The image is bundled for offline use; all user books/covers remain unchanged. Theme naming, headline and subtitle use the same persisted scene system as the other three themes.

Asset: `Assets.xcassets/ComicHubForest.imageset/forest.png`, original generated landscape. The hero uses a centered crop to retain both the distant aircraft and foreground campfire in the wide banner; the existing leading gradient protects text contrast. No downloaded reference photos or brand markings are incorporated.

Validation: Swift parse and Mac Catalyst build pass. Native Settings shows all four themes; selecting Kayıp Orman updates the home, sidebar, import button, info/recommendation bars and shelf fronts to green. Screenshot reviewed: cockpit and overgrown fuselage remain visible at the right, with legible hero text at the left. No reader data is changed. iPad visual verification is not included in this pass.

Stylized revision validation: Swift parsing and Mac Catalyst build pass. Native screenshot reviewed for the compact overlay hero, empty display bays, illustrative linework, crimson sidebar/buttons, gold links/borders and retained info/recommendation bars. White text on the primary crimson fill has a calculated 5.06:1 contrast ratio. Workshop remains selected. iPad visual verification is not included in this pass.

Approved forest revision: the user reviewed the illustrated scene before integration. The forest hero now has a 340-point minimum height and a centered crop so the small distant aircraft, foreground campfire and river remain visible together. Mac Catalyst build and Swift parsing pass; the final native screenshot confirms the scene, legible overlay text, green menus and unchanged info/recommendation cards. Kayıp Orman is selected. iPad visual verification is not included in this pass.

Approved cavern asset: `Assets.xcassets/ComicHubCavern.imageset/cavern.png`. The hero uses a 380-point minimum height and centered crop to retain the three trophies. The former Canvas scenery is removed; charcoal/cyan palette and existing theme selection are retained.

Approved cavern validation: Swift parsing and Mac Catalyst build pass. Native screenshot confirms the coin, J card and T-Rex are visible together with the workstation, walkways and underground lake. Title contrast, cyan menu accents and existing info/recommendation cards are retained. Gece Mağarası is selected in the running app. No library records were changed. iPad visual verification is not included in this pass.

## Altın Salon — gold-lit manor

The fifth selectable Comic Hub theme uses the user-approved original illustrated manor scene: a quiet drawing room, anonymous suited seated silhouette, burning fireplace, panoramic night-city windows and a golden sky searchlight bearing COMIC HUB instead of an emblem. No identifiable actor/character likeness, bat logo or copied film set is used. Asset: `Assets.xcassets/ComicHubManor.imageset/manor.png`, bundled for offline use.

Menus and inherited surfaces use warm dark ochre, yellow-gold primary fills, gold secondary accents and pale cream text. Filled yellow buttons retain dark ink. Theme title, detail, symbol, copy and persistent selection use the existing scene system. Per-scene hero height now lives in the scene enum; Manor uses 500 points to preserve the seated figure and sky lettering in the desktop banner. Other scenes retain their existing heights. Library records, reader settings and book covers are unchanged.

Altın Salon validation: Swift parsing and Mac Catalyst build pass. Native Settings lists all five themes and selects Altın Salon successfully. Screenshot reviewed for the complete COMIC HUB sky lettering, city windows, fireplace/seated silhouette, readable hero copy, yellow menu/button fills and retained information/recommendation cards. No user records were changed. iPad visual verification is not included in this pass.
