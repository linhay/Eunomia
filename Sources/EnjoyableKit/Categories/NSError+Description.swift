import Foundation

extension NSError {
    @objc(errorWithDomain:code:description:)
    class func error(withDomain domain: String, code: Int, description: String) -> NSError {
        NSError(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey: description])
    }
}
