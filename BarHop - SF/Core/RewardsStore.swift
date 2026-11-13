import Foundation
import Observation
import CryptoKit

struct GalleryPost: Identifiable, Codable {
    var id = UUID()
    let barID: String
    let photo: Data
    let caption: String
    let date: Date
}

struct RewardPrize: Identifiable, Hashable {
    let id: String
    let title: String
    let cost: Int
    let symbol: String

    static let all = [
        RewardPrize(id: "skip", title: "Free line-skip pass", cost: 100, symbol: "ticket"),
        RewardPrize(id: "duo", title: "Line skip for two", cost: 200, symbol: "person.2"),
        RewardPrize(id: "event", title: "$10 event-entry credit", cost: 300, symbol: "music.note"),
        RewardPrize(id: "merch", title: "Bar Hop tote bag", cost: 500, symbol: "bag")
    ]
}

struct RewardPass: Identifiable, Codable {
    var id = UUID()
    let title: String
    let venue: String
    let date: Date
}

private struct RewardsSnapshot: Codable {
    var points = 0
    var posts: [GalleryPost] = []
    var passes: [RewardPass] = []
    var claims: Set<String> = []
    var photoHashes: Set<String> = []
}

@MainActor @Observable
final class RewardsStore {
    private var snapshot = RewardsSnapshot()
    private let fileURL: URL
    var points: Int { snapshot.points }
    var posts: [GalleryPost] { snapshot.posts }
    var passes: [RewardPass] { snapshot.passes }

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? URL.documentsDirectory.appending(path: "barhop-rewards.json")
        if let data = try? Data(contentsOf: self.fileURL),
           let saved = try? JSONDecoder().decode(RewardsSnapshot.self, from: data) {
            snapshot = saved
        }
    }

    // Persist before publishing changes so a failed write never awards or spends points.
    private func commit(_ updated: RewardsSnapshot) throws {
        let data = try JSONEncoder().encode(updated)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        snapshot = updated
    }

    func submit(photo: Data, barID: String, caption: String, receipt: Bool, amount: Decimal) throws {
        guard !photo.isEmpty else { throw RewardsError.invalidPhoto }
        if receipt && amount < 25 { throw RewardsError.minimumSpend }
        let hash = SHA256.hash(data: photo).map { String(format: "%02x", $0) }.joined()
        guard !snapshot.photoHashes.contains(hash) else { throw RewardsError.duplicate }
        let day = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        let claim = "\(barID)-\(receipt)-\(day)"
        guard !snapshot.claims.contains(claim) else { throw RewardsError.dailyLimit }
        var updated = snapshot
        updated.claims.insert(claim)
        updated.photoHashes.insert(hash)
        updated.points += receipt ? 100 : 50
        // Receipts remain private and are never included in the gallery.
        if !receipt {
            updated.posts.insert(GalleryPost(barID: barID, photo: photo, caption: caption, date: Date()), at: 0)
        }
        try commit(updated)
    }

    func redeem(_ prize: RewardPrize) throws {
        guard snapshot.points >= prize.cost else { throw RewardsError.insufficientPoints }
        var updated = snapshot
        updated.points -= prize.cost
        updated.passes.insert(RewardPass(title: prize.title, venue: "Demo reward", date: Date()), at: 0)
        try commit(updated)
    }

    func buyDemoPass(for bar: Bar) throws {
        var updated = snapshot
        updated.passes.insert(RewardPass(title: "Line-skip pass", venue: bar.name, date: Date()), at: 0)
        try commit(updated)
    }
}

enum RewardsError: LocalizedError {
    case invalidPhoto, minimumSpend, duplicate, dailyLimit, insufficientPoints
    var errorDescription: String? {
        switch self {
        case .invalidPhoto: "Choose a valid photo."
        case .minimumSpend: "This receipt offer requires a purchase of at least $25."
        case .duplicate: "This photo has already been submitted."
        case .dailyLimit: "You have already claimed this offer at this bar today."
        case .insufficientPoints: "Earn more points before redeeming this reward."
        }
    }
}
