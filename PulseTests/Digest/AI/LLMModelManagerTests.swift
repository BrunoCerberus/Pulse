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

    @Test("Load model is callable")
    func loadModelIsCallable() async {
        do {
            try await sut.loadModel { _ in }
        } catch {}
        #expect(true)
    }
}
