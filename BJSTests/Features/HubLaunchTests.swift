import Foundation
import Testing
import BJSCore
@testable import BJS

@MainActor
struct HubLaunchTests {

    @Test("Continue maps the last launch's training module to its hub module and keeps the setup")
    func continueMapping() {
        let data = Data("{}".utf8)
        let cases: [(TrainingModule, AppModule)] = [(.strategy, .strategy), (.countingRC, .counting),
                                                    (.countingTC, .counting), (.shoe, .shoe)]
        for (training, app) in cases {
            let launch = HubViewModel.continueLaunch(from: LastLaunch(module: training, mode: "test", setup: data))
            #expect(launch?.module == app)
            #expect(launch?.setup == data)
        }
        #expect(HubViewModel.continueLaunch(from: nil) == nil)
    }

    @Test("Each launch gets a fresh identity, so relaunching the same module re-presents")
    func freshIdentity() {
        #expect(ModuleLaunch(module: .strategy, setup: nil) != ModuleLaunch(module: .strategy, setup: nil))
    }

    @Test("AppRouter starts with no launch")
    func routerDefault() {
        #expect(AppRouter().launch == nil)
    }

    @Test("A corrupt lastLaunch is ignored at load")
    func corruptLastLaunch() {
        let d = makeTestDefaults()
        d.set(Data("nope".utf8), forKey: PreferencesStore.Key.lastLaunch)
        #expect(PreferencesStore(defaults: d).lastLaunch == nil)
    }
}
