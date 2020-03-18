import Foundation
import Logging

struct SshIdentity {
    private let keygen = URL(fileURLWithPath: "/usr/bin/ssh-keygen")
    private let url: URL
    private let urlpub: URL
    private let name: String

    init(
        url: URL,
        name: String
    ) {
        assert(url.isFileURL)
        self.url = url
        urlpub = url.appendingPathExtension("pub")
        self.name = name
    }

    func pubkey() -> String {
        if let contents = FileManager.default.contents(atPath: urlpub.path) {
            if let text = String(data: contents, encoding: .utf8) {
                return text
            }
        }

        return ""
    }

    func generate() -> String {
        guard let tempDir = try? FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: url,
            create: true
        ) else {
            return ""
        }

        let tempFile = tempDir.appendingPathComponent(UUID().uuidString)

        switch Command(keygen, "-q", "-t", "ed25519", "-C", name, "-N", "", "-f", tempFile.path).run() {
        case .success:
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: urlpub)
            try? FileManager.default.moveItem(at: tempFile, to: url)
            try? FileManager.default.moveItem(at: tempFile.appendingPathExtension("pub"), to: urlpub)
            try? FileManager.default.removeItem(at: tempDir)
            return pubkey()
        case .failure:
            try? FileManager.default.removeItem(at: tempDir)
            return ""
        }
    }
}
