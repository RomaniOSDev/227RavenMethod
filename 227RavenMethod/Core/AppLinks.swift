import Foundation

enum AppLinks {
    case privacyPolicy
    case termsOfService

    var urlString: String {
        switch self {
        case .privacyPolicy:
            return "https://ravenmethod227.site/privacy/274"
        case .termsOfService:
            return "https://ravenmethod227.site/terms/274"
        }
    }

    var url: URL? {
        URL(string: urlString)
    }
}
