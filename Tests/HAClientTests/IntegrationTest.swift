import Nimble
import XCTest

@testable import HAClient

final class IntegrationTest: XCTestCase {
    let url = "ws://homeassistant.raspberrypi.localdomain/api/websocket"
    let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiI4YzI5ZGJmODdjZjE0NTUyYTJlMWVjMjFjOWU4NGM1MyIsImlhdCI6MTY0MTc0NDU3MSwiZXhwIjoxOTU3MTA0NTcxfQ.lhrtV093l7yL88l0jjfMPwSAZc1eAQpxejFzLIWry8s"

    func test_authentication() async throws {
        let client = HAClient(messageExchange: WebSocketStream(url))
        try await client.authenticate(token: token)
    }

    func test_authenticationFail() async throws {
        let client = HAClient(messageExchange: WebSocketStream(url))
        do {
            try await client.authenticate(token: "invalid-token")
            fail("Method did not throw")
        } catch {}
    }
    
    func test_retrieveRegistry() async throws {
        let client = HAClient(messageExchange: WebSocketStream(url))
        try await client.authenticate(token: token)
        
        let areas = try await client.listAreas()
        expect(areas).to(haveCount(4))
        
        let devices = try await client.listDevices()
        expect(devices).to(haveCount(38))
        
        let entities = try await client.listEntities()
        expect(entities).to(haveCount(293))
        
        let states = try await client.retrieveStates()
        expect(states).to(haveCount(230))
    }
}
