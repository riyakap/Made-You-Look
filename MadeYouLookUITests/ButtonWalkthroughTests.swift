import XCTest

/// Taps through every main flow and records any control that doesn't do what it should.
final class ButtonWalkthroughTests: XCTestCase {
    private var app: XCUIApplication!
    private var problems: [String] = []

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-resetState"]
        app.launch()
    }

    override func tearDown() {
        if !problems.isEmpty {
            print("BUTTON PROBLEMS:\n- " + problems.joined(separator: "\n- "))
        }
        XCTAssertTrue(problems.isEmpty, problems.joined(separator: "; "))
    }

    // MARK: helpers

    private func check(_ ok: Bool, _ message: String) {
        if !ok { problems.append(message) }
    }

    private func exists(_ element: XCUIElement, _ timeout: TimeInterval = 3) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    private func text(_ label: String) -> XCUIElement {
        app.staticTexts[label].firstMatch
    }

    private func tap(_ element: XCUIElement, _ name: String) -> Bool {
        guard exists(element) else { problems.append("\(name): not found"); return false }
        if !element.isHittable { app.swipeUp(velocity: .slow) }
        guard element.isHittable else { problems.append("\(name): not tappable"); return false }
        element.tap()
        return true
    }

    /// First on-screen button with this exact label.
    private func button(_ label: String) -> XCUIElement {
        let matches = app.buttons.matching(NSPredicate(format: "label == %@", label))
        _ = matches.firstMatch.waitForExistence(timeout: 3)
        return matches.allElementsBoundByIndex.first(where: { $0.isHittable }) ?? matches.firstMatch
    }

    private func goBack() {
        let back = app.buttons["Back"].firstMatch
        if back.exists && back.isHittable { back.tap() }
        else if app.navigationBars.buttons.firstMatch.exists { app.navigationBars.buttons.firstMatch.tap() }
    }

    private func tab(_ name: String) {
        _ = tap(app.tabBars.buttons[name].firstMatch, "Tab \(name)")
    }

    // MARK: test

    func testEveryScreenResponds() {
        // Welcome
        check(exists(text("Beauty, Made Personal"), 5), "Welcome screen not shown on launch")
        _ = tap(app.buttons["Get Started"], "Get Started")

        // Quiz
        check(exists(text("What are you\nlooking for?")) || exists(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'looking for'")).firstMatch), "Quiz step 1 not shown")
        _ = tap(app.buttons.containing(NSPredicate(format: "label CONTAINS 'Find makeup'")).firstMatch, "Goal option")
        _ = tap(app.buttons["Next"], "Next (step 1)")
        _ = tap(app.buttons.containing(NSPredicate(format: "label CONTAINS 'Tan'")).firstMatch, "Skin tone Tan")
        _ = tap(app.buttons["Next"], "Next (step 2)")
        _ = tap(app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Oily'")).firstMatch, "Skin type Oily")
        _ = tap(app.buttons["Next"], "Next (skin type)")
        _ = tap(app.buttons.containing(NSPredicate(format: "label CONTAINS 'Soft Glam'")).firstMatch, "Look Soft Glam")
        _ = tap(app.buttons["Next"], "Next (step 3)")
        _ = tap(app.buttons.containing(NSPredicate(format: "label CONTAINS 'Dark Circles'")).firstMatch, "Concern Dark Circles")
        _ = tap(app.buttons["Next"], "Next (step 4)")
        _ = tap(app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Drugstore'")).firstMatch, "Budget Drugstore")
        _ = tap(app.buttons["Next"], "Next (budget)")
        _ = tap(app.buttons.containing(NSPredicate(format: "label CONTAINS 'NARS'")).firstMatch, "Owned product NARS")
        _ = tap(app.buttons["Finish"], "Finish")

        // Sign up
        check(exists(text("You're all set!")), "All set screen not shown")
        _ = tap(app.buttons["Continue with Google"], "Continue with Google")

        // Home
        check(exists(text("made you look"), 5), "Home not shown after sign up")
        _ = tap(button("Notifications"), "Bell")
        check(exists(app.navigationBars["Notifications"]), "Notifications sheet didn't open")
        app.swipeDown(velocity: .fast)

        let seeAll = app.buttons.matching(NSPredicate(format: "label == 'See all'"))
        if tap(seeAll.firstMatch, "For You See all") {
            check(exists(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Personalized'")).firstMatch), "For You See all didn't open Recommendations")
            check(exists(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'oily skin' OR label CONTAINS[c] 'drugstore budget'")).firstMatch),
                  "No personalized reason shown for oily skin / drugstore budget")
            _ = tap(button("Cheeks"), "Recs chip Cheeks")
            _ = tap(button("Add to bag"), "Recs Add to bag")
            check(exists(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Added'")).firstMatch), "Add to bag showed no confirmation")
            goBack()
        }

        // Product tile → detail
        let productTile = app.scrollViews.otherElements.buttons.containing(NSPredicate(format: "label CONTAINS '$'")).firstMatch
        if tap(productTile, "For You product tile") {
            check(exists(app.buttons["Add to Bag"]), "Product detail didn't open")
            _ = tap(app.buttons["Add to Bag"], "Detail Add to Bag")
            _ = tap(button("Save"), "Detail heart")
            check(exists(app.buttons["Remove from saved"].firstMatch), "Heart didn't toggle on product detail")
            _ = tap(app.buttons.containing(NSPredicate(format: "label CONTAINS 'Product Details'")).firstMatch, "Product Details disclosure")
            goBack()
        }

        // Looks You'll Love See all → Explore
        app.swipeUp()
        // After scrolling, the last visible "See all" belongs to Looks You'll Love.
        if let looksSeeAll = seeAll.allElementsBoundByIndex.last(where: { $0.isHittable }) {
            looksSeeAll.tap()
            check(exists(text("Makeup Looks")), "Looks You'll Love See all didn't open Explore")
        } else {
            problems.append("Looks You'll Love See all: not found")
            tab("Explore")
        }

        // Explore
        sleep(1)
        _ = tap(button("Bronzy"), "Explore chip Bronzy")
        let lookCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'min'")).firstMatch
        if tap(lookCard, "Look card") {
            check(exists(app.staticTexts["Products in this look"]), "Look detail didn't open")
            _ = tap(app.buttons.containing(NSPredicate(format: "label CONTAINS 'tutorial'")).firstMatch, "Save tutorial")
            _ = tap(button("Save"), "Look heart")
            goBack()
        }

        // Saved
        tab("Saved")
        check(exists(text("Saved")), "Saved tab didn't open")
        _ = tap(button("Products"), "Saved chip Products")
        _ = tap(button("All"), "Saved chip All")
        if seeAll.firstMatch.waitForExistence(timeout: 2) {
            seeAll.firstMatch.tap()
            check(exists(app.navigationBars.firstMatch), "Saved See all didn't open")
            goBack()
        } else {
            problems.append("Saved See all: not found (nothing saved?)")
        }

        // Profile
        tab("Profile")
        _ = tap(app.buttons.containing(NSPredicate(format: "label CONTAINS 'In my bag'")).firstMatch, "Stat In my bag")
        check(exists(app.navigationBars["My Bag"]), "Bag didn't open")
        goBack()
        _ = tap(app.buttons.containing(NSPredicate(format: "label CONTAINS 'My products'")).firstMatch, "Stat My products")
        check(exists(app.navigationBars["My Products"]), "My Products didn't open")
        goBack()
        _ = tap(app.buttons.containing(NSPredicate(format: "label CONTAINS 'Recent'")).firstMatch, "Stat Recent")
        check(exists(app.navigationBars["Recently Viewed"]), "Recent didn't open")
        goBack()
        _ = tap(app.buttons.containing(NSPredicate(format: "label CONTAINS 'Skin Type'")).firstMatch, "Beauty profile Skin Type")
        _ = tap(app.buttons.containing(NSPredicate(format: "label CONTAINS 'Oily'")).firstMatch, "Skin type Oily")
        _ = tap(button("Done"), "Trait editor Done")
        check(exists(app.staticTexts["Oily"]), "Skin type edit didn't update profile")
        _ = tap(app.buttons["Edit Profile"], "Edit Profile")
        _ = tap(button("Cancel"), "Edit Profile Cancel")
        _ = tap(button("Settings"), "Settings gear")
        check(exists(app.staticTexts["Basic Information"]), "Settings didn't open")
        let soundToggle = app.switches["Sound Effects"].firstMatch
        if exists(soundToggle) {
            let before = soundToggle.value as? String
            soundToggle.switches.firstMatch.exists ? soundToggle.switches.firstMatch.tap() : soundToggle.tap()
            check((soundToggle.value as? String) != before, "Sound Effects toggle didn't change")
            soundToggle.switches.firstMatch.exists ? soundToggle.switches.firstMatch.tap() : soundToggle.tap()
        } else {
            problems.append("Sound Effects toggle: not found")
        }
        _ = tap(app.buttons.containing(NSPredicate(format: "label CONTAINS 'Notification Preferences'")).firstMatch, "Notification Preferences")
        check(exists(app.switches.firstMatch), "Notification toggles missing")
        goBack()
        _ = tap(app.buttons.containing(NSPredicate(format: "label CONTAINS 'How Recommendations Work'")).firstMatch, "How Recommendations Work")
        check(exists(app.staticTexts["Applied to your profile"]) || exists(app.staticTexts["APPLIED TO YOUR PROFILE"]), "Research page didn't open")
        goBack()
        _ = tap(button("Logout"), "Logout")
        _ = tap(button("Logout"), "Logout confirm")
        check(exists(text("Beauty, Made Personal"), 4), "Logout didn't return to welcome")
    }
}
