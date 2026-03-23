import ComposableArchitecture

@Reducer
public struct KeyMappingEditorTCAFeature {
    @ObservableState
    public struct State: Equatable {
        public var isEnabled: Bool
        public var threshold: Double

        public init(
            isEnabled: Bool = true,
            threshold: Double = 0.5
        ) {
            self.isEnabled = isEnabled
            self.threshold = min(max(threshold, 0), 1)
        }
    }

    public enum Action: Equatable {
        case setEnabled(Bool)
        case setThreshold(Double)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .setEnabled(isEnabled):
                state.isEnabled = isEnabled
                return .none
            case let .setThreshold(threshold):
                state.threshold = min(max(threshold, 0), 1)
                return .none
            }
        }
    }
}
