import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 48))
            Text("Enjoyable")
                .font(.title2)
            Text("SwiftUI Shell")
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 480, minHeight: 320)
        .padding()
    }
}

#Preview {
    ContentView()
}
