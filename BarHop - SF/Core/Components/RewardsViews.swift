import SwiftUI

struct RewardsView: View {
    let bars: [Bar]
    @Environment(RewardsStore.self) private var rewards
    @State private var selectedPrize: RewardPrize?
    @State private var message = ""
    @State private var showingMessage = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("BAR HOP REWARDS", systemImage: "gift").font(.caption.bold()).tracking(2)
                    Text("\(rewards.points) points").font(.largeTitle.bold())
                    Text("Capture the night. Unlock your next one.").foregroundStyle(BH.muted)
                    Text("Demo points · rewards have no cash value").font(.caption).foregroundStyle(BH.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(24).barHopCard()

                Text("Earn points").font(BH.TypeStyle.section)
                RewardOffer(title: "If the bar is lit, take a picture!", detail: "Post a photo to a bar gallery. Once per bar per day.", points: 50, symbol: "camera")
                RewardOffer(title: "Make your night count", detail: "Spend $25 or more and photograph your receipt. Once per bar per day. Receipts stay out of the gallery.", points: 100, symbol: "receipt")
                NavigationLink {
                    RewardVenuePicker(bars: bars)
                } label: {
                    Label("Choose a bar to earn points", systemImage: "mappin.and.ellipse")
                        .frame(maxWidth: .infinity).padding(12)
                }
                .buttonStyle(.borderedProminent).tint(BH.accent)

                Text("Redeem your points").font(BH.TypeStyle.section)
                ForEach(RewardPrize.all) { prize in
                    VStack(alignment: .leading, spacing: 12) {
                        Label(prize.title, systemImage: prize.symbol).font(.headline)
                        Text("\(prize.cost) points").foregroundStyle(BH.orange)
                        Button(rewards.points >= prize.cost ? "Redeem" : "\(prize.cost - rewards.points) more points needed") {
                            selectedPrize = prize
                        }
                        .buttonStyle(.bordered)
                        .disabled(rewards.points < prize.cost)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(20).barHopCard()
                }
                Text("Demo offers only. Photo and receipt submissions award demo points immediately; purchases and receipts are not verified. Real rewards will require participating venues.")
                    .font(.footnote).foregroundStyle(BH.muted)
            }
            .padding(24)
        }
        .background(BH.background)
        .navigationTitle("Rewards")
        .confirmationDialog("Redeem this reward?", isPresented: Binding(
            get: { selectedPrize != nil },
            set: { if !$0 { selectedPrize = nil } }
        ), titleVisibility: .visible) {
            if let prize = selectedPrize {
                Button("Use \(prize.cost) points") {
                    do {
                        try rewards.redeem(prize)
                        message = "Your demo reward is in Passes."
                    } catch { message = error.localizedDescription }
                    showingMessage = true
                    selectedPrize = nil
                }
            }
        }
        .alert("Rewards", isPresented: $showingMessage) { Button("OK", role: .cancel) {} } message: { Text(message) }
    }
}

private struct RewardOffer: View {
    let title: String
    let detail: String
    let points: Int
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("+\(points) points", systemImage: symbol).font(.headline).foregroundStyle(BH.orange)
            Text(title).font(.headline)
            Text(detail).font(.subheadline).foregroundStyle(BH.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(20).barHopCard()
    }
}

private struct RewardVenuePicker: View {
    let bars: [Bar]
    var body: some View {
        List(bars) { bar in
            NavigationLink(bar.name) { PhotoSubmissionView(bar: bar) }
        }
        .navigationTitle("Choose a bar")
        .overlay {
            if bars.isEmpty { ContentUnavailableView("No bars yet", systemImage: "mappin", description: Text("Explore bars to load available venues.")) }
        }
    }
}

struct RewardPassesView: View {
    @Environment(RewardsStore.self) private var rewards
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if rewards.passes.isEmpty {
                    ContentUnavailableView("Your next night awaits", systemImage: "ticket", description: Text("Buy a demo line skip from a bar or redeem points in Rewards."))
                }
                ForEach(rewards.passes) { pass in
                    VStack(alignment: .leading, spacing: 10) {
                        Label(pass.title, systemImage: "ticket").font(.title3.bold())
                        Text(pass.venue)
                        Text("DEMO · Not valid for entry or merchandise").font(.caption).foregroundStyle(BH.orange)
                        Text(pass.date, style: .date).font(.caption).foregroundStyle(BH.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(24).barHopCard()
                }
            }
            .padding(24)
        }
        .background(BH.background)
        .navigationTitle("Passes")
    }
}

struct BarGalleryView: View {
    let bar: Bar
    @Environment(RewardsStore.self) private var rewards
    private var posts: [GalleryPost] { rewards.posts.filter { $0.barID == bar.id } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gallery").font(BH.TypeStyle.section)
            Text("If the bar is lit, take a picture! Get 50 points.")
                .foregroundStyle(BH.orange)
            Text("Your photos are stored on this device. Community sharing is coming soon.")
                .font(.caption).foregroundStyle(BH.muted)
            if posts.isEmpty {
                ContentUnavailableView("Be the first to capture the night", systemImage: "photo.on.rectangle", description: Text("Tap Take Picture to add your first gallery photo."))
            }
            ForEach(posts) { post in
                if let image = UIImage(data: post.photo) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(uiImage: image).resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .accessibilityLabel(post.caption.isEmpty ? "Your bar photo" : post.caption)
                        Text("You · \(post.date.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(BH.muted)
                        if !post.caption.isEmpty { Text(post.caption) }
                    }
                }
            }
        }
    }
}
