import Foundation
import Logging

public struct UserDefaultsTunnels {
    private let bundleId: String
    private let logger = Logger(label: "ch.znerol.punssh.UserDefaultTunnels")

    public init(bundleId: String) {
        self.bundleId = bundleId
    }

    public func tunnels() -> [Tunnel] {
        guard let defaults = UserDefaults(suiteName: bundleId) else {
            logger.error("Failed to open preferences suite \(bundleId)")
            return []
        }

        guard let tunnels = defaults.array(forKey: "tunnels") else {
            logger.info("No tunnels defined in preferences suite \(bundleId)")
            return []
        }

        return tunnels.compactMap {
            guard let info = $0 as? [String: Any] else {
                logger.warning("Tunnel definition must be a dictionary")
                return nil
            }

            guard let rawname = info["name"] as? String, let destination = info["destination"] as? String, let hostkeys = info["hostkeys"] as? [String], hostkeys.count > 0 else {
                logger.warning("Tunnel name, destination and hostkeys are required and must be of type string")
                return nil
            }

            let name = substitutePlaceholders(name: rawname)

            let user = info["user"] as? String ?? "nobody"
            let group = info["group"] as? String ?? "nogroup"

            return Tunnel(
                label: "\(bundleId).tunnel.\(destination).\(name)",
                name: name,
                destination: destination,
                hostkeys: hostkeys,
                user: user,
                group: group
            )
        }
    }

    private func substitutePlaceholders(name: String) -> String {
        let hostname = Host.current().name ?? "localhost"
        let computername = hostname.split(separator: ".")[0]
        return name
            .replacingOccurrences(of: "%ComputerName%", with: computername)
    }
}
