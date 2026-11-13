import SwiftUI

struct VenueStats: View {
    let bar: Bar

    // Editorial placeholders until a venue data provider is connected.
    private var level: Int { bar.priceCents <= 1500 ? 1 : bar.priceCents <= 2500 ? 2 : 3 }
    private var rating: Double { 4.5 + Double(bar.artworkVariant) / 10 }

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 2) {
                ForEach(1...3, id: \.self) { index in
                    Text("$").foregroundStyle(index <= level ? BH.text : BH.muted.opacity(0.35))
                }
            }
            .accessibilityLabel("Sample price level \(level) of 3")
            Text("·").foregroundStyle(BH.muted)
            Label(rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                .foregroundStyle(BH.orange)
            Text("Sample").font(.caption2).foregroundStyle(BH.muted)
        }
        .font(.subheadline.weight(.semibold))
    }
}

struct GlowAction: View {
    let title: String
    let subtitle: String
    let symbol: String
    var prominent = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: symbol).font(.title2)
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.13), in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).opacity(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .foregroundStyle(prominent ? Color.black : BH.text)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: prominent ? [Color(red: 1, green: 0.75, blue: 0.40), BH.orange] : [BH.espresso, BH.card],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.12)))
    }
}

struct ShimmerTicket: View {
    let title: String
    let venue: String
    var preview = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("BAR HOP").font(.caption.bold()).tracking(4)
                Spacer()
                Image(systemName: "sparkles").font(.title2)
            }
            Image(systemName: "ticket.fill").font(.system(size: 50))
                .rotationEffect(.degrees(-15)).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.largeTitle.bold())
                Text(venue).font(.headline)
            }
            Rectangle().fill(.black.opacity(0.15)).frame(height: 1)
            HStack {
                Text(preview ? "MAKE IT A NIGHT" : "DEMO PASS · NOT VALID FOR ENTRY")
                    .font(.caption2.bold()).tracking(1)
                Spacer()
                Image(systemName: "star.circle.fill").font(.title)
            }
        }
        .padding(28)
        .foregroundStyle(Color(red: 0.19, green: 0.09, blue: 0.05))
        .background {
            RoundedRectangle(cornerRadius: 30)
                .fill(LinearGradient(stops: [
                    .init(color: Color(red: 1, green: 0.61, blue: 0.32), location: 0),
                    .init(color: Color(red: 1, green: 0.89, blue: 0.65), location: 0.37),
                    .init(color: Color(red: 0.94, green: 0.65, blue: 0.40), location: 0.55),
                    .init(color: Color(red: 1, green: 0.83, blue: 0.66), location: 0.8),
                    .init(color: Color(red: 0.79, green: 0.44, blue: 0.30), location: 1)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.5)))
        .shadow(color: BH.orange.opacity(0.15), radius: 24, y: 12)
    }
}
