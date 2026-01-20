import Foundation
@testable import Pulse
import Testing

@Suite("PaywallDomainAction Product Loading Tests")
struct PaywallDomainActionProductLoadingTests {
    @Test("Can create loadProducts action")
    func loadProductsAction() {
        let action1 = PaywallDomainAction.loadProducts
        let action2 = PaywallDomainAction.loadProducts
        #expect(action1 == action2)
    }

    @Test("loadProducts is repeatable")
    func loadProductsRepeatable() {
        let actions = Array(repeating: PaywallDomainAction.loadProducts, count: 3)
        for action in actions {
            #expect(action == .loadProducts)
        }
    }
}

@Suite("PaywallDomainAction Product Selection Tests")
struct PaywallDomainActionProductSelectionTests {
    @Test("Can create selectProduct action")
    func selectProductAction() {
        let product = Product(id: "monthly", name: "Monthly Plan")
        let action = PaywallDomainAction.selectProduct(product)
        #expect(action == .selectProduct(product))
    }

    @Test("selectProduct preserves product ID")
    func selectProductPreservesID() {
        let product = Product(id: "annual", name: "Annual Plan")
        let action = PaywallDomainAction.selectProduct(product)

        if case let .selectProduct(selectedProduct) = action {
            #expect(selectedProduct.id == "annual")
        } else {
            #expect(Bool(false))
        }
    }

    @Test("Different products create different actions")
    func differentProductsDifferentActions() {
        let product1 = Product(id: "monthly", name: "Monthly")
        let product2 = Product(id: "annual", name: "Annual")
        let action1 = PaywallDomainAction.selectProduct(product1)
        let action2 = PaywallDomainAction.selectProduct(product2)
        #expect(action1 != action2)
    }

    @Test("Same product ID creates equal actions")
    func sameProductIDEqualActions() {
        let product1 = Product(id: "monthly", name: "Monthly Plan")
        let product2 = Product(id: "monthly", name: "Monthly Plan (Updated)")
        let action1 = PaywallDomainAction.selectProduct(product1)
        let action2 = PaywallDomainAction.selectProduct(product2)
        // Custom Equatable: compares by product ID only
        #expect(action1 == action2)
    }
}

@Suite("PaywallDomainAction Purchase Tests")
struct PaywallDomainActionPurchaseTests {
    @Test("Can create purchase action")
    func testPurchaseAction() {
        let product = Product(id: "premium", name: "Premium Plan")
        let action = PaywallDomainAction.purchase(product)
        #expect(action == .purchase(product))
    }

    @Test("purchase preserves product")
    func purchasePreservesProduct() {
        let product = Product(id: "pro", name: "Pro Plan")
        let action = PaywallDomainAction.purchase(product)

        if case let .purchase(purchaseProduct) = action {
            #expect(purchaseProduct.id == "pro")
        } else {
            #expect(Bool(false))
        }
    }

    @Test("Different products in purchase create different actions")
    func differentProductsInPurchase() {
        let product1 = Product(id: "monthly", name: "Monthly")
        let product2 = Product(id: "annual", name: "Annual")
        let action1 = PaywallDomainAction.purchase(product1)
        let action2 = PaywallDomainAction.purchase(product2)
        #expect(action1 != action2)
    }

    @Test("Same product ID in purchase creates equal actions")
    func sameProductIDInPurchaseEqual() {
        let product1 = Product(id: "premium", name: "Premium")
        let product2 = Product(id: "premium", name: "Premium (Updated)")
        let action1 = PaywallDomainAction.purchase(product1)
        let action2 = PaywallDomainAction.purchase(product2)
        // Custom Equatable: compares by product ID only
        #expect(action1 == action2)
    }
}

@Suite("PaywallDomainAction Subscription Management Tests")
struct PaywallDomainActionSubscriptionManagementTests {
    @Test("Can create restorePurchases action")
    func restorePurchasesAction() {
        let action1 = PaywallDomainAction.restorePurchases
        let action2 = PaywallDomainAction.restorePurchases
        #expect(action1 == action2)
    }

    @Test("Can create checkSubscriptionStatus action")
    func checkSubscriptionStatusAction() {
        let action1 = PaywallDomainAction.checkSubscriptionStatus
        let action2 = PaywallDomainAction.checkSubscriptionStatus
        #expect(action1 == action2)
    }

    @Test("restorePurchases and checkSubscriptionStatus are different")
    func restoreAndCheckDifferent() {
        let restoreAction = PaywallDomainAction.restorePurchases
        let checkAction = PaywallDomainAction.checkSubscriptionStatus
        #expect(restoreAction != checkAction)
    }

    @Test("restorePurchases is repeatable")
    func restorePurchasesRepeatable() {
        let actions = Array(repeating: PaywallDomainAction.restorePurchases, count: 3)
        for action in actions {
            #expect(action == .restorePurchases)
        }
    }
}

@Suite("PaywallDomainAction Dismissal Tests")
struct PaywallDomainActionDismissalTests {
    @Test("Can create dismiss action")
    func dismissAction() {
        let action1 = PaywallDomainAction.dismiss
        let action2 = PaywallDomainAction.dismiss
        #expect(action1 == action2)
    }

    @Test("dismiss is repeatable")
    func dismissRepeatable() {
        let actions = Array(repeating: PaywallDomainAction.dismiss, count: 3)
        for action in actions {
            #expect(action == .dismiss)
        }
    }
}

@Suite("PaywallDomainAction Custom Equatable Tests")
struct PaywallDomainActionCustomEquatableTests {
    @Test("loadProducts actions are equal")
    func loadProductsEqual() {
        let action1 = PaywallDomainAction.loadProducts
        let action2 = PaywallDomainAction.loadProducts
        #expect(action1 == action2)
    }

    @Test("restorePurchases actions are equal")
    func restorePurchasesEqual() {
        let action1 = PaywallDomainAction.restorePurchases
        let action2 = PaywallDomainAction.restorePurchases
        #expect(action1 == action2)
    }

    @Test("dismiss actions are equal")
    func dismissEqual() {
        let action1 = PaywallDomainAction.dismiss
        let action2 = PaywallDomainAction.dismiss
        #expect(action1 == action2)
    }

    @Test("checkSubscriptionStatus actions are equal")
    func checkSubscriptionStatusEqual() {
        let action1 = PaywallDomainAction.checkSubscriptionStatus
        let action2 = PaywallDomainAction.checkSubscriptionStatus
        #expect(action1 == action2)
    }

    @Test("Products compared by ID in selectProduct")
    func selectProductComparedByID() {
        let product1 = Product(id: "same-id", name: "Original Name")
        let product2 = Product(id: "same-id", name: "Different Name")
        let action1 = PaywallDomainAction.selectProduct(product1)
        let action2 = PaywallDomainAction.selectProduct(product2)
        #expect(action1 == action2)
    }

    @Test("Products compared by ID in purchase")
    func purchaseComparedByID() {
        let product1 = Product(id: "premium", name: "Premium Plan")
        let product2 = Product(id: "premium", name: "Premium Plan Updated")
        let action1 = PaywallDomainAction.purchase(product1)
        let action2 = PaywallDomainAction.purchase(product2)
        #expect(action1 == action2)
    }

    @Test("Different product IDs make actions not equal")
    func differentProductIDsNotEqual() {
        let product1 = Product(id: "id-1", name: "Same Name")
        let product2 = Product(id: "id-2", name: "Same Name")
        let action1 = PaywallDomainAction.selectProduct(product1)
        let action2 = PaywallDomainAction.selectProduct(product2)
        #expect(action1 != action2)
    }

    @Test("selectProduct and purchase with same ID are different")
    func selectAndPurchaseDifferent() {
        let product = Product(id: "premium", name: "Premium")
        let selectAction = PaywallDomainAction.selectProduct(product)
        let purchaseAction = PaywallDomainAction.purchase(product)
        #expect(selectAction != purchaseAction)
    }
}

@Suite("PaywallDomainAction Complex Paywall Workflow Tests")
struct PaywallDomainActionComplexPaywallWorkflowTests {
    @Test("Simulate initial product loading")
    func initialProductLoading() {
        let actions: [PaywallDomainAction] = [
            .loadProducts,
            .checkSubscriptionStatus,
        ]

        #expect(actions.count == 2)
        #expect(actions[0] == .loadProducts)
    }

    @Test("Simulate product selection and purchase")
    func productSelectionAndPurchase() {
        let product = Product(id: "monthly", name: "Monthly Plan")
        let actions: [PaywallDomainAction] = [
            .loadProducts,
            .selectProduct(product),
            .purchase(product),
        ]

        #expect(actions.count == 3)
        #expect(actions[1] == .selectProduct(product))
    }

    @Test("Simulate restore purchases workflow")
    func restorePurchasesWorkflow() {
        let actions: [PaywallDomainAction] = [
            .loadProducts,
            .restorePurchases,
            .checkSubscriptionStatus,
        ]

        #expect(actions.count == 3)
        #expect(actions[1] == .restorePurchases)
    }

    @Test("Simulate complete purchase flow")
    func completePurchaseFlow() {
        let product1 = Product(id: "monthly", name: "Monthly Plan")
        let product2 = Product(id: "annual", name: "Annual Plan")

        let actions: [PaywallDomainAction] = [
            .loadProducts,
            .selectProduct(product1),
            .selectProduct(product2),
            .purchase(product2),
            .checkSubscriptionStatus,
            .dismiss,
        ]

        #expect(actions.count == 6)
        #expect(actions.first == .loadProducts)
        #expect(actions.last == .dismiss)
    }

    @Test("Simulate product switching before purchase")
    func productSwitchingBeforePurchase() {
        let products = [
            Product(id: "monthly", name: "Monthly"),
            Product(id: "annual", name: "Annual"),
            Product(id: "lifetime", name: "Lifetime"),
        ]

        var actions: [PaywallDomainAction] = [.loadProducts]

        for product in products {
            actions.append(.selectProduct(product))
        }

        actions.append(.purchase(products[2]))

        #expect(actions.count == 5)
    }

    @Test("Simulate multiple purchase attempts")
    func multiplePurchaseAttempts() {
        let product = Product(id: "premium", name: "Premium")
        var actions: [PaywallDomainAction] = [
            .loadProducts,
            .selectProduct(product),
        ]

        // Multiple purchase attempts
        for _ in 1 ... 3 {
            actions.append(.purchase(product))
        }

        #expect(actions.count == 5)
    }

    @Test("Simulate complete paywall lifecycle")
    func completePaywallLifecycle() {
        let product1 = Product(id: "monthly", name: "Monthly")
        let product2 = Product(id: "annual", name: "Annual")

        let actions: [PaywallDomainAction] = [
            .loadProducts,
            .checkSubscriptionStatus,
            .selectProduct(product1),
            .selectProduct(product2),
            .purchase(product2),
            .restorePurchases,
            .dismiss,
        ]

        #expect(actions.count == 7)
        #expect(actions[0] == .loadProducts)
        #expect(actions[4] == .purchase(product2))
        #expect(actions.last == .dismiss)
    }

    @Test("Simulate product ID-based equality in workflow")
    func productIDEqualityInWorkflow() {
        let product1 = Product(id: "premium", name: "Premium Plan")
        let product2 = Product(id: "premium", name: "Premium Plan (Updated)")

        let action1 = PaywallDomainAction.selectProduct(product1)
        let action2 = PaywallDomainAction.selectProduct(product2)

        #expect(action1 == action2)

        let purchaseAction1 = PaywallDomainAction.purchase(product1)
        let purchaseAction2 = PaywallDomainAction.purchase(product2)

        #expect(purchaseAction1 == purchaseAction2)
    }
}
