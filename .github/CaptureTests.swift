import XCTest

final class CaptureTests: XCTestCase {
    func testScreenshots() throws {
        continueAfterFailure = false
        let routes = ["empty", "home", "library", "detail", "preview", "cbz", "cbz-hidden", "pdf", "guided", "settings", "reader-settings", "statistics", "journal", "series", "achievements", "import", "characters", "lists", "notes", "myPanels", "smartSearch", "readingOrder2", "libraryHealth", "libraryTools", "smartCollections", "sourcesSync", "wrapped", "history", "saved"]
        let app = XCUIApplication(bundleIdentifier: "com.yeetozer.comicport")
        for (index, route) in routes.enumerated() {
            for landscape in [false, true] {
                if route == "pdf" && !landscape { continue }
                app.terminate()
                XCUIDevice.shared.orientation = landscape ? .landscapeLeft : .portrait
                app.launchEnvironment = ["SCREENSHOT_ROUTE": route, "SCREENSHOT_ORIENTATION": landscape ? "landscape" : "portrait"]
                app.launch()
                sleep(route == "home" ? 18 : 10)
                XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
                let screenshot = XCUIScreen.main.screenshot()
                let attachment = XCTAttachment(screenshot: screenshot)
                attachment.name = String(format: "%02d_%@_%@", index + 1, route, landscape ? "landscape" : "portrait")
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }
}
