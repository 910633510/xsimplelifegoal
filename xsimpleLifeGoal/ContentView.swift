import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            Text(AppMetadata.displayName)
                .font(.title.weight(.semibold))
                .padding()
                .navigationTitle("Goals")
        }
    }
}

#Preview {
    ContentView()
}
