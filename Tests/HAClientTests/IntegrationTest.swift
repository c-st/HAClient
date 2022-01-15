import Nimble
import XCTest

@testable import HAClient

final class IntegrationTest: XCTestCase {
    let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiI4YzI5ZGJmODdjZjE0NTUyYTJlMWVjMjFjOWU4NGM1MyIsImlhdCI6MTY0MTc0NDU3MSwiZXhwIjoxOTU3MTA0NTcxfQ.lhrtV093l7yL88l0jjfMPwSAZc1eAQpxejFzLIWry8s"

    func test_authentication() async throws {
        let client = HAClient(messageExchange: WebSocketStream("ws://homeassistant.raspberrypi.localdomain/api/websocket"))

        try await client.authenticate(token: token)
    }

    func test_authenticationFail() async throws {
        let client = HAClient(messageExchange: WebSocketStream("ws://homeassistant.raspberrypi.localdomain/api/websocket"))

        do {
            try await client.authenticate(token: "invalid-token")
            fail("Method did not throw")
        } catch {}
    }
}
