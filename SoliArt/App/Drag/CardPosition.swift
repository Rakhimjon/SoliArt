import SwiftUI

extension DragState {
    func pileCardsAndOffsets(pileID: Pile.ID) -> [(card: Card, yOffset: Double)] {
        guard let cards = piles[id: pileID]?.cards else { return [] }
        let spacing = cardWidth * 2/5 + 4
        return cards.reduce([]) { result, card in
            guard let previous = result.last else { return [(card, 0)] }
            let spacing: Double = previous.card.isFacedUp ? spacing : spacing/5
            return result + [(card, previous.yOffset + spacing)]
        }
    }

    var deckUpwardsCardsAndOffsets: [(card: Card, xOffset: Double, isDraggable: Bool)] {
        let spacing = cardWidth * 1/20
        let cards = deckUpwards.suffix(3)
        return cards.enumerated().map { offset, card in
            (card, Double(offset) * spacing, isDraggable: cards.last == card)
        }
    }

    func cardPosition(_ card: Card) -> CGPoint {
        switch DraggingSource.card(card, in: self) {
        case let .pile(id):
            guard let rect = frames
                .first(where: { if case .pile(id, _) = $0 { return true } else { return false } })?.rect,
                  let yOffset = pileCardsAndOffsets(pileID: id).first(where: { $0.card == card })?.yOffset
            else { return .zero }

            return CGPoint(x: rect.midX, y: rect.minY + cardWidth/2 * 7/5 + yOffset)
        case .deck:
            guard
                let rect = frames.first(where: { if case .deck = $0 { return true } else { return false } })?.rect,
                let xOffset = deckUpwardsCardsAndOffsets.first(where: { $0.card == card })?.xOffset
            else { return .zero }

            return CGPoint(x: rect.midX + xOffset, y: rect.midY)
        case .foundation, .removed: return .zero
        }
    }

    func destinationPosition(_ destination: Hint.Destination) -> CGPoint {
        switch destination {
        case let .foundation(id):
            guard let rect = frames
                .first(where: { if case .foundation(id, _) = $0 { return true } else { return false } })?.rect
            else { return .zero }

            return CGPoint(x: rect.midX, y: rect.midY)
        case .pile: return .zero
        }
    }
}

enum Frame: Equatable, Hashable, Identifiable {
    case pile(Pile.ID, CGRect)
    case foundation(Foundation.ID, CGRect)
    case deck(CGRect)

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .pile(pileID, _):
            hasher.combine("Pile")
            hasher.combine(pileID)
        case let .foundation(foundationID, _):
            hasher.combine("Foundation")
            hasher.combine(foundationID)
        case .deck:
            hasher.combine("Deck")
        }
    }

    var id: Int { hashValue }

    var rect: CGRect {
        switch self {
        case let .pile(_, rect), let .foundation(_, rect), let .deck(rect): return rect
        }
    }
}