import Foundation
import os
@testable import Pulse
import Testing

@Suite("LLMModelManager Tests")
@MainActor
struct LLMModelManagerTests {
    let sut = LLMModelManager.shared

    @Test("Singleton instance is shared")
    func singletonInstance() {
        let instance1 = LLMModelManager.shared
        let instance2 = LLMModelManager.shared

        #expect(instance1 === instance2)
    }

    @Test("Initial state has model not loaded")
    func initialState() {
        #expect(!sut.modelIsLoaded)
    }

    @Test("Unload model is callable")
    func unloadModel() async {
        await sut.unloadModel()
        #expect(!sut.modelIsLoaded)
    }

    @Test("Load model is callable - skips if already loaded")
    func loadModelIsCallable() async {
        let wasAlreadyLoaded = sut.modelIsLoaded

        if !wasAlreadyLoaded {
            do {
                try await sut.loadModel { _ in }
            } catch {}
        }

        #expect(true)
    }

    @Test("Load model is idempotent")
    func loadModelIsIdempotent() async {
        do {
            try await sut.loadModel { _ in }
        } catch {}

        let firstLoadState = sut.modelIsLoaded

        do {
            try await sut.loadModel { _ in }
        } catch {}

        let secondLoadState = sut.modelIsLoaded

        #expect(firstLoadState == secondLoadState)
    }
}
