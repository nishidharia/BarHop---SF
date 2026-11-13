import Foundation
import Testing
@testable import BarHop___SF

@MainActor
struct RewardsTests {
    @Test func submissionsPersistAndReceiptsStayPrivate() throws {
        let url = URL.temporaryDirectory.appending(path: UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = RewardsStore(fileURL: url)
        try store.submit(photo: Data([1]), barID: "balboa", caption: "Great night",
                         receipt: false, amount: 0)
        try store.submit(photo: Data([2]), barID: "balboa", caption: "",
                         receipt: true, amount: 25)
        let restored = RewardsStore(fileURL: url)
        #expect(restored.points == 150)
        #expect(restored.posts.count == 1)
        #expect(restored.posts.first?.caption == "Great night")
    }

    @Test func rejectsDuplicatesDailyRepeatsAndLowSpend() throws {
        let url = URL.temporaryDirectory.appending(path: UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = RewardsStore(fileURL: url)
        try store.submit(photo: Data([1]), barID: "balboa", caption: "", receipt: false, amount: 0)
        #expect(throws: RewardsError.self) {
            try store.submit(photo: Data([1]), barID: "vesuvio", caption: "", receipt: false, amount: 0)
        }
        #expect(throws: RewardsError.self) {
            try store.submit(photo: Data([2]), barID: "balboa", caption: "", receipt: false, amount: 0)
        }
        #expect(throws: RewardsError.self) {
            try store.submit(photo: Data([3]), barID: "balboa", caption: "", receipt: true, amount: 24)
        }
        #expect(store.points == 50)
        #expect(store.posts.count == 1)
    }

    @Test func redemptionDeductsPointsAndPersistsPass() throws {
        let url = URL.temporaryDirectory.appending(path: UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = RewardsStore(fileURL: url)
        let prize = RewardPrize.all[0]
        #expect(throws: RewardsError.self) { try store.redeem(prize) }
        try store.submit(photo: Data([1]), barID: "balboa", caption: "", receipt: true, amount: 25)
        try store.redeem(prize)
        let restored = RewardsStore(fileURL: url)
        #expect(restored.points == 0)
        #expect(restored.passes.count == 1)
        #expect(restored.passes.first?.title == prize.title)
        #expect(throws: RewardsError.self) { try restored.redeem(prize) }
    }
}
