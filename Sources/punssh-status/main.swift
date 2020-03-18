import Foundation
import Logging
import punssh

private let bundleId = "ch.znerol.punssh"
private let logger = Logger(label: "ch.znerol.punssh-status.main")

private struct ServiceStatus: Encodable {
    let service: String
    let status: Tunnel.Status
}

func main() -> Int32 {
    do {
        let status = try UserDefaultsTunnels(bundleId: bundleId).tunnels().map {
            ServiceStatus(
                service: String(describing: $0),
                status: try $0.status().get()
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(status)
        print(String(data: data, encoding: .utf8)!)
        return 0
    } catch {
        logger.error("Failed to gather status \(error)")
        return 1
    }
}

exit(main())
