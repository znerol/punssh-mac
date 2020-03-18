import Foundation
import punssh

private let bundleId = "ch.znerol.punssh"

func main() -> Int32 {
    UserDefaultsTunnels(bundleId: bundleId).tunnels().forEach {
        $0.start()
    }

    return 0
}

exit(main())
