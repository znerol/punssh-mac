import Foundation
import Logging

public struct Tunnel: CustomStringConvertible {
    private let logger = Logger(label: "ch.znerol.punssh.Tunnel")

    private let name: String
    private let destination: String
    private let user: String
    private let group: String
    private let identity: SshIdentity
    private let job: LaunchdJob
    private let def: LaunchdJob.Definition
    private let idfile: URL

    public var description: String {
        "Tunnel(\(destination):\(name))"
    }

    public init(
        label: String,
        name: String,
        destination: String,
        user: String,
        group: String
    ) {
        self.name = name
        self.destination = destination
        self.user = user
        self.group = group

        let libdirs = FileManager.default.urls(for: .libraryDirectory, in: .localDomainMask)
        if libdirs.isEmpty {
            fatalError("Failed to find local library directory")
        }
        idfile = URL(fileURLWithPath: "PunSSH/Tunnels/\(destination).\(name)/id", relativeTo: libdirs[0])
        identity = SshIdentity(url: idfile, name: name)

        job = LaunchdJob(label: label)
        def = LaunchdJob.Definition(
            label: label,
            userName: user,
            groupName: group,
            programArguments: [
                "/Library/PunSSH/Bin/punssh-connect",
                "\(destination):\(name)",
                "-i",
                idfile.path,
            ],
            runAtLoad: true,
            keepAlive: [
                "SuccessfulExit": false,
            ]
        )
    }

    public func status() -> Result<Status, TunnelError> {
        let pubkey = identity.pubkey()

        if pubkey.isEmpty {
            return .success(.Absent)
        }

        return job.status().map {
            switch $0 {
            case .Up:
                return .Up(pubkey: pubkey)
            case let .Down(status):
                if status == 0 {
                    return .Ready(pubkey: pubkey)
                } else {
                    return .Error(pubkey: pubkey, code: status)
                }
            case .Ready:
                return .Ready(pubkey: pubkey)
            case .Absent:
                return .Absent
            }
        }.mapError {
            .LanuchdJobError(error: $0)
        }
    }

    public func start() -> Result<Status, TunnelError> {
        do {
            if case .Up = try job.status().get() {
                _ = job.stop()
            }

            if identity.pubkey() == "" {
                try FileManager.default.createDirectory(at: idfile.deletingLastPathComponent(),
                                                        withIntermediateDirectories: true)
                _ = identity.generate()
                let attributes: [FileAttributeKey: Any] = [
                    .posixPermissions: 0o600,
                    .ownerAccountName: user,
                    .groupOwnerAccountName: group,
                ]
                try FileManager.default.setAttributes(attributes, ofItemAtPath: idfile.path)
            }

            if try job.write(definition: def).get() {
                _ = job.unload()
                _ = job.load()
                _ = job.start()
            }
        } catch {
            logger.error("Failed to start tunnel: \(error)")
        }

        return status()
    }

    public enum Status {
        case Absent
        case Ready(pubkey: String)
        case Error(pubkey: String, code: Int32)
        case Up(pubkey: String)
    }

    public enum TunnelError: Error {
        case LanuchdJobError(error: Error)
    }
}

extension Tunnel.Status: Encodable {
    private enum CodingKeys: String, CodingKey {
        case Status = "status"
        case PubKey = "pubkey"
        case Code = "code"
    }

    private enum CodingValues: String, Encodable {
        case Absent = "absent"
        case Ready = "ready"
        case Error = "error"
        case Up = "up"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .Absent:
            try container.encode(CodingValues.Absent, forKey: .Status)
        case let .Ready(pubkey):
            try container.encode(CodingValues.Ready, forKey: .Status)
            try container.encode(pubkey, forKey: .PubKey)
        case let .Error(pubkey, code):
            try container.encode(CodingValues.Error, forKey: .Status)
            try container.encode(pubkey, forKey: .PubKey)
            try container.encode(code, forKey: .Code)
        case let .Up(pubkey):
            try container.encode(CodingValues.Up, forKey: .Status)
            try container.encode(pubkey, forKey: .PubKey)
        }
    }
}
