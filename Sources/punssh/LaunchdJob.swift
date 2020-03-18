import Foundation

struct LaunchdJob {
    private let label: String
    private let launchctl = URL(fileURLWithPath: "/bin/launchctl")

    private var plistURL: URL {
        let libdirs = FileManager.default.urls(for: .libraryDirectory, in: .localDomainMask)
        if libdirs.isEmpty {
            fatalError("Failed to find local library directory")
        }
        return URL(fileURLWithPath: "LaunchDaemons/\(label).plist", relativeTo: libdirs[0])
    }

    init(label: String) {
        self.label = label
    }

    func status() -> Result<Status, LaunchdJobError> {
        switch Command(launchctl, "print", "system/\(label)").run() {
        case let .success(output):
            let pairs = output
                .components(separatedBy: .newlines)
                .map { line in
                    line.split(separator: "=", maxSplits: 1).map {
                        $0.trimmingCharacters(in: .whitespaces)
                    }
                }
                .filter { $0.count == 2 }

            for pair in pairs {
                if pair[0] == "pid", let pid = Int32(pair[1]) {
                    return .success(.Up(pid: pid))
                } else if pair[0] == "last exit code", let code = Int32(pair[1].components(separatedBy: ":")[0]) {
                    return .success(.Down(status: code))
                }
            }

            return .success(.Ready)

        case let .failure(error):
            return .success(.Absent)
        }
    }

    func write(definition: Definition) -> Result<Bool, LaunchdJobError> {
        let needsWrite = (try? read().map { $0 != definition }.get()) ?? true

        if needsWrite {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            do {
                let data = try encoder.encode(definition)
                try data.write(to: plistURL)
            } catch {
                return .failure(.EncodingError(error: error))
            }
        }

        return .success(needsWrite)
    }

    func read() -> Result<Definition, LaunchdJobError> {
        if let contents = FileManager.default.contents(atPath: plistURL.path) {
            do {
                let definition = try PropertyListDecoder().decode(Definition.self, from: contents)
                return .success(definition)
            } catch {
                return .failure(.DecodingError(error: error))
            }
        } else {
            return .failure(.FileNotFoundError(url: plistURL))
        }
    }

    func start() -> Result<Status, LaunchdJobError> {
        _ = Command(launchctl, "start", label).run()
        return status()
    }

    func stop() -> Result<Status, LaunchdJobError> {
        _ = Command(launchctl, "stop", label).run()
        return status()
    }

    func load() -> Result<Status, LaunchdJobError> {
        _ = Command(launchctl, "load", plistURL.path).run()
        return status()
    }

    func unload() -> Result<Status, LaunchdJobError> {
        _ = Command(launchctl, "unload", plistURL.path).run()
        return status()
    }

    enum Status {
        case Ready
        case Up(pid: Int32)
        case Down(status: Int32)
        case Absent
    }

    enum LaunchdJobError: Error {
        case EncodingError(error: Error)
        case DecodingError(error: Error)
        case FileNotFoundError(url: URL)
        case LaunchctlError(error: Error)
    }

    struct Definition: Codable, Equatable {
        let label: String
        let userName: String
        let groupName: String
        let programArguments: [String]
        let runAtLoad: Bool
        let keepAlive: [String: Bool] // FIXME: [String: Bool] ist the wrong type, use an enum.

        enum CodingKeys: String, CodingKey {
            case label = "Label"
            case userName = "UserName"
            case groupName = "GroupName"
            case programArguments = "ProgramArguments"
            case runAtLoad = "RunAtLoad"
            case keepAlive = "KeepAlive"
        }
    }
}
