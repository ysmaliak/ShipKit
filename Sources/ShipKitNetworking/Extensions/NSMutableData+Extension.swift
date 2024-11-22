import Foundation

extension NSMutableData {
    func append(string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }
}