#if canImport(SwiftUI)
import SwiftUI

@main
struct StarSystemProceduralUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
#else
@main
struct StarSystemProceduralUIUnsupportedApp {
    static func main() {
        fatalError("SwiftUI is not available on this platform.")
    }
}
#endif
