import XCTest
@testable import HydroFlow

final class WidgetSnapshotTests: XCTestCase {

    func testProgressMath() {
        var s = WidgetSnapshot(currentML: 1330, goalML: 2660, unitSymbol: "oz", streak: 3, updated: Date())
        XCTAssertEqual(s.progress, 0.5, accuracy: 0.001)

        s.currentML = 5000
        XCTAssertEqual(s.progress, 1.0, accuracy: 0.001, "Progress clamps at 100%")

        s.goalML = 0
        XCTAssertEqual(s.progress, 0, "Zero goal yields zero progress")
    }

    func testDisplayTextUnitFormatting() {
        let ml = WidgetSnapshot(currentML: 1500, goalML: 2660, unitSymbol: "ml", streak: 0, updated: Date())
        XCTAssertEqual(ml.displayText(), "1500 ml")
        XCTAssertEqual(ml.goalText(), "2660 ml")

        let oz = WidgetSnapshot(currentML: 2366, goalML: 2660, unitSymbol: "oz", streak: 0, updated: Date())
        XCTAssertEqual(oz.displayText(), "80 oz", "2366 ml ≈ 80 fl oz")
        XCTAssertEqual(oz.goalText(), "90 oz")
    }

    func testSnapshotFileRoundTrip() {
        let snapshot = WidgetSnapshot(currentML: 1234.5, goalML: 2660, unitSymbol: "oz", streak: 6, updated: Date())
        WidgetPublisher.write(snapshot)
        let loaded = WidgetPublisher.read()
        XCTAssertEqual(loaded, snapshot, "Write→read through the shared container must round-trip")
    }

    func testReadMissingFileReturnsNil() {
        // Reading a nonexistent snapshot file must yield nil (fresh installs).
        let bogus = FileManager.default.temporaryDirectory
            .appendingPathComponent("missing-\(UUID().uuidString).json")
        let data = try? Data(contentsOf: bogus)
        XCTAssertNil(data)
        XCTAssertNil(try? JSONDecoder().decode(WidgetSnapshot.self, from: data ?? Data()))
    }

    func testStoreSaveUpdatesWidgetSnapshotFile() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("widget-store-\(UUID().uuidString).json")
        let store = HydrationStore(fileURL: url)
        store.logDrink(.water, volumeML: 500)
        store.flushSaves()

        let snapshot = WidgetPublisher.read()
        XCTAssertNotNil(snapshot, "Store save should refresh the widget snapshot")
        XCTAssertEqual(snapshot?.currentML ?? 0, 500, accuracy: 0.5)
        XCTAssertEqual(snapshot?.unitSymbol, "oz")
    }
}
