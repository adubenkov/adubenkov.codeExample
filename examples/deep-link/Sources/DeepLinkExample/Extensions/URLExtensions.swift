import Foundation

extension URL {
    func queryValueOf(parameterName: String) -> String? {
        guard let url = URLComponents(string: absoluteString) else {
            return nil
        }
        return url.queryItems?.first(where: { $0.name == parameterName })?.value
    }
}
