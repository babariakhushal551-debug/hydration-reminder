import Foundation
import HealthKit

/// Metadata key used to tag each HealthKit sample with our entry UUID
/// so deletes can find the matching object.
enum HydroFlowMetadata {
    static let entryUUID = "hydroflow.entryUUID"
}

/// Syncs water intake to Apple Health (HKQuantityTypeIdentifier.dietaryWater).
///
/// Sync happens on a background queue per the plan's performance requirement;
/// every write is tagged with the entry UUID for de-duplication.
final class HealthKitManager: ObservableObject {

    static let shared = HealthKitManager()

    @Published private(set) var isAuthorized = false
    @Published private(set) var lastSyncError: String?

    private let healthStore = HKHealthStore()
    private let queue = DispatchQueue(label: "com.hydroflow.healthkit", qos: .utility)

    /// The single quantity type we read/write.
    private var waterType: HKQuantityType? {
        HKObjectType.quantityType(forIdentifier: .dietaryWater)
    }

    /// Whether this device supports HealthKit (iPhone only, always true in practice).
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Authorization

    /// Requests write access for dietary water.
    func requestAuthorization() async -> Bool {
        guard isAvailable, let waterType else {
            await MainActor.run { isAuthorized = false }
            return false
        }
        do {
            try await healthStore.requestAuthorization(toShare: [waterType], read: [])
            await MainActor.run { isAuthorized = true }
            return true
        } catch {
            await MainActor.run {
                isAuthorized = false
                lastSyncError = error.localizedDescription
            }
            return false
        }
    }

    // MARK: - Syncing

    /// Writes one water sample for a logged entry. Fire-and-forget; failures are logged.
    func syncEntry(_ entry: WaterEntry) {
        guard isAvailable, isAuthorized, let waterType else { return }

        queue.async { [weak self] in
            guard let self else { return }
            let quantity = HKQuantity(
                unit: .liter(),
                doubleValue: entry.volumeML / 1000
            )
            let sample = HKQuantitySample(
                type: waterType,
                quantity: quantity,
                start: entry.date,
                end: entry.date,
                metadata: [HydroFlowMetadata.entryUUID: entry.id.uuidString]
            )

            self.healthStore.save(sample) { success, error in
                if let error, !success {
                    DispatchQueue.main.async {
                        self.lastSyncError = error.localizedDescription
                    }
                }
            }
        }
    }

    /// Deletes the matching HealthKit sample when an entry is removed in-app.
    func deleteEntry(_ entry: WaterEntry) {
        guard isAvailable, isAuthorized, let waterType else { return }

        queue.async { [weak self] in
            let predicate = HKQuery.predicateForObjects(withMetadataKey: HydroFlowMetadata.entryUUID,
                                                        allowedValues: [entry.id.uuidString])
            self?.healthStore.deleteObjects(of: waterType, predicate: predicate) { _, _, error in
                if let error {
                    DispatchQueue.main.async {
                        self?.lastSyncError = error.localizedDescription
                    }
                }
            }
        }
    }
}
