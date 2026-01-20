import Foundation
@testable import Pulse
import Testing

@Suite("PaywallDomainState Initialization Tests")
struct PaywallDomainStateInitializationTests {
    @Test("Initial products are empty")
    func initialProductsEmpty() {
        let state = PaywallDomainState()
        #expect(state.products.isEmpty)
    }

    @Test("Initial selectedProduct is nil")
    func initialSelectedProductNil() {
        let state = PaywallDomainState()
        #expect(state.selectedProduct == nil)
    }

    @Test("Initial isPremium is false")
    func initialIsPremiumFalse() {
        let state = PaywallDomainState()
        #expect(!state.isPremium)
    }

    @Test("Initial isLoadingProducts is false")
    func initialIsLoadingProductsFalse() {
        let state = PaywallDomainState()
        #expect(!state.isLoadingProducts)
    }

    @Test("Initial isPurchasing is false")
    func initialIsPurchasingFalse() {
        let state = PaywallDomainState()
        #expect(!state.isPurchasing)
    }

    @Test("Initial isRestoring is false")
    func initialIsRestoringFalse() {
        let state = PaywallDomainState()
        #expect(!state.isRestoring)
    }

    @Test("Initial error is nil")
    func initialErrorNil() {
        let state = PaywallDomainState()
        #expect(state.error == nil)
    }

    @Test("Initial purchaseSuccessful is false")
    func initialPurchaseSuccessfulFalse() {
        let state = PaywallDomainState()
        #expect(!state.purchaseSuccessful)
    }

    @Test("Initial restoreSuccessful is false")
    func initialRestoreSuccessfulFalse() {
        let state = PaywallDomainState()
        #expect(!state.restoreSuccessful)
    }

    @Test("Initial shouldDismiss is false")
    func initialShouldDismissFalse() {
        let state = PaywallDomainState()
        #expect(!state.shouldDismiss)
    }
}

@Suite("PaywallDomainState Products Tests")
struct PaywallDomainStateProductsTests {
    @Test("Can set products array")
    func setProducts() {
        var state = PaywallDomainState()
        let products = [
            Product(id: "1", name: "Plan 1"),
            Product(id: "2", name: "Plan 2"),
        ]
        state.products = products
        #expect(state.products.count == 2)
    }

    @Test("Can append product")
    func appendProduct() {
        var state = PaywallDomainState()
        state.products.append(Product(id: "1", name: "Plan 1"))
        #expect(state.products.count == 1)
    }

    @Test("Can clear products")
    func clearProducts() {
        var state = PaywallDomainState()
        state.products = [
            Product(id: "1", name: "Plan 1"),
            Product(id: "2", name: "Plan 2"),
        ]
        state.products = []
        #expect(state.products.isEmpty)
    }

    @Test("Multiple products can be stored")
    func multipleProducts() {
        var state = PaywallDomainState()
        let products = (1 ... 5).map { Product(id: "\($0)", name: "Plan \($0)") }
        state.products = products
        #expect(state.products.count == 5)
    }
}

@Suite("PaywallDomainState Selected Product Tests")
struct PaywallDomainStateSelectedProductTests {
    @Test("Can select product")
    func selectProduct() {
        var state = PaywallDomainState()
        let product = Product(id: "1", name: "Plan 1")
        state.selectedProduct = product
        #expect(state.selectedProduct == product)
    }

    @Test("Can change selected product")
    func changeSelectedProduct() {
        var state = PaywallDomainState()
        let product1 = Product(id: "1", name: "Plan 1")
        let product2 = Product(id: "2", name: "Plan 2")
        state.selectedProduct = product1
        state.selectedProduct = product2
        #expect(state.selectedProduct == product2)
    }

    @Test("Can deselect product")
    func deselectProduct() {
        var state = PaywallDomainState()
        state.selectedProduct = Product(id: "1", name: "Plan 1")
        state.selectedProduct = nil
        #expect(state.selectedProduct == nil)
    }

    @Test("Selected product independent from products array")
    func selectedProductIndependent() {
        var state = PaywallDomainState()
        let products = [
            Product(id: "1", name: "Plan 1"),
            Product(id: "2", name: "Plan 2"),
        ]
        state.products = products
        state.selectedProduct = Product(id: "3", name: "Plan 3")
        #expect(state.products.count == 2)
        #expect(state.selectedProduct?.id == "3")
    }
}

@Suite("PaywallDomainState Premium Status Tests")
struct PaywallDomainStatePremiumStatusTests {
    @Test("Can set isPremium flag")
    func setIsPremium() {
        var state = PaywallDomainState()
        state.isPremium = true
        #expect(state.isPremium)
    }

    @Test("Can toggle isPremium flag")
    func toggleIsPremium() {
        var state = PaywallDomainState()
        state.isPremium = true
        #expect(state.isPremium)
        state.isPremium = false
        #expect(!state.isPremium)
    }

    @Test("isPremium independent from other flags")
    func isPremiumIndependent() {
        var state = PaywallDomainState()
        state.isPremium = true
        state.isPurchasing = true
        state.purchaseSuccessful = true
        #expect(state.isPremium)
        #expect(state.isPurchasing)
        #expect(state.purchaseSuccessful)
    }
}

@Suite("PaywallDomainState Loading States Tests")
struct PaywallDomainStateLoadingStatesTests {
    @Test("Can set isLoadingProducts flag")
    func setIsLoadingProducts() {
        var state = PaywallDomainState()
        state.isLoadingProducts = true
        #expect(state.isLoadingProducts)
    }

    @Test("Can set isPurchasing flag")
    func setIsPurchasing() {
        var state = PaywallDomainState()
        state.isPurchasing = true
        #expect(state.isPurchasing)
    }

    @Test("Can set isRestoring flag")
    func setIsRestoring() {
        var state = PaywallDomainState()
        state.isRestoring = true
        #expect(state.isRestoring)
    }

    @Test("Loading flags are independent")
    func loadingFlagsIndependent() {
        var state = PaywallDomainState()
        state.isLoadingProducts = true
        state.isPurchasing = true
        state.isRestoring = true
        #expect(state.isLoadingProducts)
        #expect(state.isPurchasing)
        #expect(state.isRestoring)

        state.isLoadingProducts = false
        #expect(!state.isLoadingProducts)
        #expect(state.isPurchasing)
        #expect(state.isRestoring)
    }
}

@Suite("PaywallDomainState Error Tests")
struct PaywallDomainStateErrorTests {
    @Test("Can set error message")
    func setErrorMessage() {
        var state = PaywallDomainState()
        state.error = "Purchase failed"
        #expect(state.error == "Purchase failed")
    }

    @Test("Can clear error")
    func clearError() {
        var state = PaywallDomainState()
        state.error = "Error"
        state.error = nil
        #expect(state.error == nil)
    }

    @Test("Can change error message")
    func changeErrorMessage() {
        var state = PaywallDomainState()
        state.error = "Error 1"
        state.error = "Error 2"
        #expect(state.error == "Error 2")
    }
}

@Suite("PaywallDomainState Success Flags Tests")
struct PaywallDomainStateSuccessFlagsTests {
    @Test("Can set purchaseSuccessful flag")
    func setPurchaseSuccessful() {
        var state = PaywallDomainState()
        state.purchaseSuccessful = true
        #expect(state.purchaseSuccessful)
    }

    @Test("Can set restoreSuccessful flag")
    func setRestoreSuccessful() {
        var state = PaywallDomainState()
        state.restoreSuccessful = true
        #expect(state.restoreSuccessful)
    }

    @Test("Can set shouldDismiss flag")
    func setShouldDismiss() {
        var state = PaywallDomainState()
        state.shouldDismiss = true
        #expect(state.shouldDismiss)
    }

    @Test("Success flags are independent")
    func successFlagsIndependent() {
        var state = PaywallDomainState()
        state.purchaseSuccessful = true
        state.restoreSuccessful = true
        state.shouldDismiss = true
        #expect(state.purchaseSuccessful)
        #expect(state.restoreSuccessful)
        #expect(state.shouldDismiss)
    }
}

@Suite("PaywallDomainState Custom Equatable Tests")
struct PaywallDomainStateCustomEquatableTests {
    @Test("Two initial states are equal")
    func twoInitialStatesEqual() {
        let state1 = PaywallDomainState()
        let state2 = PaywallDomainState()
        #expect(state1 == state2)
    }

    @Test("Products compared by ID only")
    func productsComparedByIDOnly() {
        var state1 = PaywallDomainState()
        var state2 = PaywallDomainState()

        state1.products = [Product(id: "1", name: "Plan A")]
        state2.products = [Product(id: "1", name: "Plan B")]

        // Both have same product ID, so they should be equal
        #expect(state1 == state2)
    }

    @Test("Different product IDs make states not equal")
    func differentProductIDsNotEqual() {
        var state1 = PaywallDomainState()
        var state2 = PaywallDomainState()

        state1.products = [Product(id: "1", name: "Plan")]
        state2.products = [Product(id: "2", name: "Plan")]

        #expect(state1 != state2)
    }

    @Test("States with different isPremium are not equal")
    func differentIsPremiumNotEqual() {
        var state1 = PaywallDomainState()
        var state2 = PaywallDomainState()
        state1.isPremium = true
        #expect(state1 != state2)
    }

    @Test("States with different loading flags are not equal")
    func differentLoadingFlagsNotEqual() {
        var state1 = PaywallDomainState()
        var state2 = PaywallDomainState()
        state1.isLoadingProducts = true
        #expect(state1 != state2)
    }

    @Test("States become equal after same mutations")
    func statesEqualAfterSameMutations() {
        var state1 = PaywallDomainState()
        var state2 = PaywallDomainState()

        state1.isPremium = true
        state2.isPremium = true
        state1.purchaseSuccessful = true
        state2.purchaseSuccessful = true

        #expect(state1 == state2)
    }
}

@Suite("PaywallDomainState Copy Method Tests")
struct PaywallDomainStateCopyMethodTests {
    @Test("Copy creates new instance with same values")
    func copyCreatesNewInstance() {
        var state = PaywallDomainState()
        state.isPremium = true
        state.purchaseSuccessful = true

        let copy = state.copy()
        #expect(copy.isPremium == state.isPremium)
        #expect(copy.purchaseSuccessful == state.purchaseSuccessful)
    }

    @Test("Copy can override isPremium")
    func copyOverridePremium() {
        var state = PaywallDomainState()
        state.isPremium = false

        let copy = state.copy(isPremium: true)
        #expect(copy.isPremium == true)
        #expect(state.isPremium == false)
    }

    @Test("Copy can override products")
    func copyOverrideProducts() {
        var state = PaywallDomainState()
        state.products = [Product(id: "1", name: "Original")]

        let newProducts = [Product(id: "2", name: "New")]
        let copy = state.copy(products: newProducts)
        #expect(copy.products == newProducts)
        #expect(state.products != newProducts)
    }

    @Test("Copy can override multiple values")
    func copyOverrideMultiple() {
        var state = PaywallDomainState()
        state.isPremium = false
        state.error = "Old error"

        let copy = state.copy(isPremium: true, error: "New error")
        #expect(copy.isPremium == true)
        #expect(copy.error == "New error")
        #expect(state.isPremium == false)
        #expect(state.error == "Old error")
    }

    @Test("Copy preserves nil values when not overridden")
    func copyPreservesNilValues() {
        var state = PaywallDomainState()
        state.selectedProduct = nil
        state.error = nil

        let copy = state.copy()
        #expect(copy.selectedProduct == nil)
        #expect(copy.error == nil)
    }
}

@Suite("PaywallDomainState Complex Purchase Scenarios")
struct PaywallDomainStateComplexPurchaseScenarioTests {
    @Test("Simulate product loading")
    func productLoading() {
        var state = PaywallDomainState()
        state.isLoadingProducts = true
        state.products = [
            Product(id: "1", name: "Monthly"),
            Product(id: "2", name: "Yearly"),
        ]
        state.isLoadingProducts = false

        #expect(!state.isLoadingProducts)
        #expect(state.products.count == 2)
    }

    @Test("Simulate purchase flow")
    func purchaseFlow() {
        var state = PaywallDomainState()
        state.products = [Product(id: "1", name: "Premium")]
        state.selectedProduct = state.products[0]

        state.isPurchasing = true
        state.isPremium = true
        state.purchaseSuccessful = true
        state.isPurchasing = false

        #expect(state.isPremium)
        #expect(state.purchaseSuccessful)
        #expect(!state.isPurchasing)
    }

    @Test("Simulate purchase error")
    func purchaseError() {
        var state = PaywallDomainState()
        state.isPurchasing = true
        state.error = "Payment declined"
        state.isPurchasing = false

        #expect(!state.isPurchasing)
        #expect(state.error == "Payment declined")
        #expect(!state.purchaseSuccessful)
    }

    @Test("Simulate restore purchases")
    func restorePurchases() {
        var state = PaywallDomainState()
        state.isRestoring = true
        state.isPremium = true
        state.restoreSuccessful = true
        state.isRestoring = false

        #expect(!state.isRestoring)
        #expect(state.isPremium)
        #expect(state.restoreSuccessful)
    }

    @Test("Simulate dismissal after purchase")
    func dismissalAfterPurchase() {
        var state = PaywallDomainState()
        state.purchaseSuccessful = true
        state.shouldDismiss = true

        #expect(state.purchaseSuccessful)
        #expect(state.shouldDismiss)
    }

    @Test("Simulate complete paywall lifecycle")
    func completePaywallLifecycle() {
        var state = PaywallDomainState()

        // Load products
        state.isLoadingProducts = true
        state.products = [Product(id: "1", name: "Premium")]
        state.isLoadingProducts = false

        // Select product
        state.selectedProduct = state.products[0]

        // Purchase
        state.isPurchasing = true
        state.isPremium = true
        state.purchaseSuccessful = true
        state.isPurchasing = false

        // Dismiss
        state.shouldDismiss = true

        #expect(state.isPremium)
        #expect(state.purchaseSuccessful)
        #expect(state.shouldDismiss)
    }

    @Test("Simulate error recovery")
    func errorRecovery() {
        var state = PaywallDomainState()
        state.isPurchasing = true
        state.error = "Network error"
        state.isPurchasing = false

        // Clear error and retry
        state.error = nil
        state.isPurchasing = true
        state.isPremium = true
        state.purchaseSuccessful = true
        state.isPurchasing = false

        #expect(state.error == nil)
        #expect(state.purchaseSuccessful)
    }
}
