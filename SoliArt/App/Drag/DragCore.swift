import ComposableArchitecture
import SwiftUI

struct DragState: Equatable {
    var frames: IdentifiedArrayOf<Frame> = []
    var draggingState: DraggingState?
    var zIndexPriority: DraggingSource = .pile(id: 1)
    var namespace: Namespace.ID?
    var piles: IdentifiedArrayOf<Pile> = []
    var foundations: IdentifiedArrayOf<Foundation> = []
    var deckUpwards: IdentifiedArrayOf<Card> = []
}

enum DragAction: Equatable {
    case updateFrame(Frame)
    case dragCard(Card, position: CGPoint)
    case dropCards
    case doubleTapCard(Card)
    case setNamespace(Namespace.ID)
    case resetZIndexPriority
    case score(ScoreAction)
}

struct DragEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
}

let dragReducer = Reducer<DragState, DragAction, DragEnvironment> { state, action, environment in
    switch action {
    case let .updateFrame(frame):
        state.frames.updateOrAppend(frame)
        return .none
    case let .dragCard(card, position):
        guard card.isFacedUp else { return .none }
        state.draggingState = DraggingState(card: card, position: position)
        state.zIndexPriority = DraggingSource.card(card, in: state)
        return .none
    case .dropCards:
        return state.dropCards(mainQueue: environment.mainQueue)
    case .resetZIndexPriority:
        state.zIndexPriority = .pile(id: 1)
        return .none
    case let .doubleTapCard(card):
        guard
            card.isFacedUp,
            let foundation = state.foundations.first(where: { $0.suit == card.suit })
        else { return .none }

        return state.move(card: card, foundation: foundation)
    case let .setNamespace(namespace):
        state.namespace = namespace
        return .none
    case .score:
        return .none
    }
}

extension DragState {
    var cardWidth: CGFloat {
        frames.first(where: { if case .pile = $0 { return true } else { return false } })?.rect.width ?? 0
    }
}

extension AppState {
    var drag: DragState {
        get {
            DragState(
                frames: _drag.frames,
                draggingState: _drag.draggingState,
                zIndexPriority: _drag.zIndexPriority,
                namespace: _drag.namespace,
                piles: game.piles,
                foundations: game.foundations,
                deckUpwards: game.deck.upwards
            )
        }
        set {
            (
                _drag.frames,
                _drag.draggingState,
                _drag.zIndexPriority,
                _drag.namespace,

                game.piles,
                game.foundations,
                game.deck.upwards
            ) = (
                newValue.frames,
                newValue.draggingState,
                newValue.zIndexPriority,
                newValue.namespace,

                newValue.piles,
                newValue.foundations,
                newValue.deckUpwards
            )
        }
    }
}