import Foundation

extension FileManager {
    func generateUniqueURL(withBase canonical: URL) -> URL {
        guard canonical.isFileURL else { return canonical }

        var trying = canonical.path
        let dirname = (trying as NSString).deletingLastPathComponent
        let basename = ((trying as NSString).lastPathComponent as NSString).deletingPathExtension
        let ext = (trying as NSString).pathExtension

        var index = 1
        while fileExists(atPath: trying) && index < 10_000 {
            var indexName = "\(basename) (\(index))"
            index += 1
            if !ext.isEmpty {
                indexName = (indexName as NSString).appendingPathExtension(ext) ?? indexName
            }
            trying = (dirname as NSString).appendingPathComponent(indexName)
        }

        return URL(fileURLWithPath: trying)
    }
}
