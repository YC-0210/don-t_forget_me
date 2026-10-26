import Foundation

/// Explicit localization also covers runtime strings, accessibility, and notifications.
enum L10n {
    static func text(_ key: String, bundle: Bundle = .main) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: Locale.current, arguments: arguments)
    }
    static func iconName(_ symbol: String) -> String {
        let keys = ["bag.fill": "icon.bag", "person.text.rectangle.fill": "icon.id",
                    "waterbottle.fill": "icon.bottle", "key.fill": "icon.keys",
                    "wallet.bifold.fill": "icon.wallet", "headphones": "icon.headphones",
                    "umbrella.fill": "icon.umbrella", "eyeglasses": "icon.glasses"]
        return text(keys[symbol] ?? "icon.bag")
    }
}
