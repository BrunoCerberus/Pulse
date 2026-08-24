import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("SupabaseConfig Tests")
struct SupabaseConfigTests {
    @Test("url returns empty when not configured")
    func urlReturnsEmptyWhenNotConfigured() {
        let mockRemoteConfig = MockRemoteConfigService()
        mockRemoteConfig.supabaseURLValue = nil
        SupabaseConfig.configure(with: mockRemoteConfig)
        let url = SupabaseConfig.url
        #expect(url.isEmpty)
    }

    @Test("url returns Remote Config value when available")
    func urlReturnsRemoteConfigValue() {
        let mockRemoteConfig = MockRemoteConfigService()
        mockRemoteConfig.supabaseURLValue = "https://test.supabase.co"
        SupabaseConfig.configure(with: mockRemoteConfig)
        let url = SupabaseConfig.url
        #expect(url == "https://test.supabase.co")
    }

    @Test("url falls back to environment variable")
    func urlFallsBackToEnvironmentVariable() {
        let mockRemoteConfig = MockRemoteConfigService()
        mockRemoteConfig.supabaseURLValue = nil
        SupabaseConfig.configure(with: mockRemoteConfig)
        let testURL = "https://env.supabase.co"
        setenv("SUPABASE_URL", testURL, 1)
        defer { unsetenv("SUPABASE_URL") }
        let url = SupabaseConfig.url
        #expect(url == testURL)
    }

    @Test("isConfigured returns true when URL is set")
    func isConfiguredReturnsTrueWhenSet() {
        let mockRemoteConfig = MockRemoteConfigService()
        mockRemoteConfig.supabaseURLValue = "https://test.supabase.co"
        SupabaseConfig.configure(with: mockRemoteConfig)
        #expect(SupabaseConfig.isConfigured == true)
    }

    @Test("isConfigured returns false when URL is empty")
    func isConfiguredReturnsFalseWhenEmpty() {
        let mockRemoteConfig = MockRemoteConfigService()
        mockRemoteConfig.supabaseURLValue = ""
        SupabaseConfig.configure(with: mockRemoteConfig)
        #expect(SupabaseConfig.isConfigured == false)
    }

    @Test("url rejects a non-https Remote Config value")
    func urlRejectsNonHTTPSRemoteConfigValue() {
        let mockRemoteConfig = MockRemoteConfigService()
        mockRemoteConfig.supabaseURLValue = "http://insecure.supabase.co"
        SupabaseConfig.configure(with: mockRemoteConfig)
        #expect(SupabaseConfig.url.isEmpty)
        #expect(SupabaseConfig.isConfigured == false)
    }

    @Test("url rejects an unparseable Remote Config value")
    func urlRejectsUnparseableRemoteConfigValue() {
        let mockRemoteConfig = MockRemoteConfigService()
        mockRemoteConfig.supabaseURLValue = "not a url"
        SupabaseConfig.configure(with: mockRemoteConfig)
        #expect(SupabaseConfig.url.isEmpty)
        #expect(SupabaseConfig.isConfigured == false)
    }
}
