import Combine

protocol VoltageSentry {
    func sentryCheck() async throws -> Bool
}

protocol AttributionRetriever {
    func retrieve(deviceID: String) async throws -> [String: Any]
}

protocol LedgerLocator {
    func locate(seed: [String: Any]) async throws -> String
}

protocol ConsentSummoner {
    func summon() -> AsyncStream<Bool>
    func ringPushBell()
}


final class SupabaseVoltageSentry: VoltageSentry {
    
    func sentryCheck() async throws -> Bool {
        return true
    }
}
