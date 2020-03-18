import Foundation
import Logging

struct Command {
    private let logger = Logger(label: "ch.znerol.punssh.Command")
    private let executable: URL
    private let args: [String]

    init(_ executable: URL, _ args: String...) {
        self.executable = executable
        self.args = args
    }

    func run() -> Result<String, CommandError> {
        let task = Process()
        let out = Pipe()
        task.executableURL = executable
        task.arguments = args
        task.standardOutput = out

        do {
            logger.debug("Attempting to run process \(executable) \(args)")
            try task.run()
            task.waitUntilExit()
            logger.debug("Process terminated \(executable)")
        } catch {
            logger.error("Failed to run process \(executable): \(error)")
            return .failure(CommandError.UndefinedError(error: error))
        }

        let data = out.fileHandleForReading.readDataToEndOfFile()

        if task.terminationStatus == 0 {
            return .success(String(decoding: data, as: UTF8.self))
        } else {
            return .failure(CommandError.NonZeroStatus(status: task.terminationStatus))
        }
    }

    enum CommandError: Error {
        case NonZeroStatus(status: Int32)
        case UndefinedError(error: Error)
    }
}
