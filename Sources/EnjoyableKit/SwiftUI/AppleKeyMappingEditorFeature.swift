import ComposableArchitecture
import SwiftUI

@Reducer
struct AppleKeyMappingEditorFeature {
    @ObservableState
    struct State: Equatable {
        var initialState: KeyMappingEditorState
        var draft: KeyMappingEditorState
        var showsDiscardConfirmation = false
        var selectedStepIndex: Int?

        init(initialState: KeyMappingEditorState) {
            self.initialState = initialState
            self.draft = initialState
            self.selectedStepIndex = Self.normalizedSelectedStepIndex(
                nil,
                stepCount: initialState.keySequenceSteps.count
            )
        }

        static func normalizedSelectedStepIndex(_ selectedIndex: Int?, stepCount: Int) -> Int? {
            guard stepCount > 0 else { return nil }
            guard let selectedIndex else { return 0 }
            return min(max(0, selectedIndex), stepCount - 1)
        }
    }

    enum Action: Equatable {
        case setShowsDiscardConfirmation(Bool)
        case setSelectedStepIndex(Int?)
        case setEnabled(Bool)
        case setActivationThreshold(Double)
        case setKeySequenceKeys(index: Int, keys: [UInt16])
        case setKeySequenceDelay(index: Int, value: Int)
        case moveStep(from: IndexSet, to: Int)
        case appendStep
        case removeStep
        case cancelTapped
        case discardConfirmed
        case saveTapped
        case delegate(Delegate)
    }

    enum Delegate: Equatable {
        case cancel
        case save(KeyMappingEditorState)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .setShowsDiscardConfirmation(isPresented):
                state.showsDiscardConfirmation = isPresented
                return .none

            case let .setSelectedStepIndex(index):
                state.selectedStepIndex = State.normalizedSelectedStepIndex(
                    index,
                    stepCount: state.draft.keySequenceSteps.count
                )
                return .none

            case let .setEnabled(isEnabled):
                state.draft.enabled = isEnabled
                return .none

            case let .setActivationThreshold(value):
                state.draft.activationThreshold = Float(value)
                return .none

            case let .setKeySequenceKeys(index, keys):
                guard state.draft.keySequenceSteps.indices.contains(index) else { return .none }

                var normalizedKeys: [UInt16] = []
                for key in keys where key != NJKeyInputFieldEmpty {
                    if !normalizedKeys.contains(key) {
                        normalizedKeys.append(key)
                    }
                }

                let delay = state.draft.keySequenceSteps[index].delayMilliseconds
                state.draft.keySequenceSteps[index] = NJKeySequenceStep(
                    keys: normalizedKeys,
                    delayMilliseconds: delay
                )
                syncPrimaryKeyFromSequence(state: &state)
                return .none

            case let .setKeySequenceDelay(index, value):
                guard state.draft.keySequenceSteps.indices.contains(index) else { return .none }
                let keys = state.draft.keySequenceSteps[index].keys
                state.draft.keySequenceSteps[index] = NJKeySequenceStep(
                    keys: keys,
                    delayMilliseconds: max(0, value)
                )
                return .none

            case let .moveStep(from, to):
                state.draft.keySequenceSteps.move(fromOffsets: from, toOffset: to)
                state.selectedStepIndex = State.normalizedSelectedStepIndex(
                    state.selectedStepIndex,
                    stepCount: state.draft.keySequenceSteps.count
                )
                syncPrimaryKeyFromSequence(state: &state)
                return .none

            case .appendStep:
                let fallbackCode = state.draft.resolvedPrimaryKeyCode
                let nextCode = fallbackCode == NJKeyInputFieldEmpty ? NJKeyInputFieldEmpty : fallbackCode
                state.draft.keySequenceSteps.append(
                    .init(
                        keys: nextCode == NJKeyInputFieldEmpty ? [] : [nextCode],
                        delayMilliseconds: 80
                    )
                )
                state.selectedStepIndex = state.draft.keySequenceSteps.count - 1
                return .none

            case .removeStep:
                guard state.draft.keySequenceSteps.count > 1 else { return .none }
                state.draft.keySequenceSteps.removeLast()
                state.selectedStepIndex = State.normalizedSelectedStepIndex(
                    state.selectedStepIndex,
                    stepCount: state.draft.keySequenceSteps.count
                )
                syncPrimaryKeyFromSequence(state: &state)
                return .none

            case .cancelTapped:
                if state.hasUnsavedChanges {
                    state.showsDiscardConfirmation = true
                    return .none
                }
                return .send(.delegate(.cancel))

            case .discardConfirmed:
                state.showsDiscardConfirmation = false
                return .send(.delegate(.cancel))

            case .saveTapped:
                guard state.draft.canSaveChanges else { return .none }
                return .send(.delegate(.save(state.stateForSaving)))

            case .delegate:
                return .none
            }
        }
    }

    private func syncPrimaryKeyFromSequence(state: inout State) {
        if let first = state.draft.keySequenceSteps
            .compactMap({ $0.keys.first(where: { $0 != NJKeyInputFieldEmpty }) })
            .first {
            state.draft.keyCode = first
            return
        }
        state.draft.keyCode = NJKeyInputFieldEmpty
    }
}

private extension AppleKeyMappingEditorFeature.State {
    var hasUnsavedChanges: Bool {
        !draft.hasSameEditingPayload(as: initialState)
    }

    var stateForSaving: KeyMappingEditorState {
        var next = draft
        next.keyCode = next.resolvedPrimaryKeyCode
        return next
    }
}
