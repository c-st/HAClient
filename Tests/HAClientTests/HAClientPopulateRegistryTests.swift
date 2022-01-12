//import Combine
//import Nimble
//import XCTest
//
//@testable import HAClient
//
//final class HAClientPopulateRegistryTests: XCTestCase {
//    var cancellables: Set<AnyCancellable>!
//
//    var mockExchange: FakeMessageExchange!
//    var client: HAClient!
//
//    override func setUp() async throws {
//        cancellables = []
//        mockExchange = FakeMessageExchange()
//        client = HAClient(messageExchange: mockExchange)
//        try await client.authenticate(token: "mytoken")
//        mockExchange.simulateIncomingMessage(
//            message: JSONCoding.serialize(AuthOkMessage())
//        )
//        mockExchange.sentMessages = []
//    }
//
//    func testUsesIncrementingIdWhenMakingRequests() {
//        client.requestRegistry()
//
//        expect(self.mockExchange.sentMessages).to(equal([
//            JSONCoding.serialize(RequestAreaRegistry(id: 1)),
//            JSONCoding.serialize(RequestDeviceRegistry(id: 2)),
//            JSONCoding.serialize(RequestEntityRegistry(id: 3)),
//        ]))
//    }
//
//    func testCallsCompletionWhenAllPopulationResponsesHaveArrived() {
//        waitUntil(timeout: .seconds(1)) { done in
//            self.client.requestRegistry()
//
//            self.mockExchange.simulateIncomingMessage(
//                message: JSONCoding.serialize(BaseResultMessage(id: 1, success: true))
//            )
//            self.mockExchange.simulateIncomingMessage(
//                message: JSONCoding.serialize(BaseResultMessage(id: 2, success: true))
//            )
//            self.mockExchange.simulateIncomingMessage(
//                message: JSONCoding.serialize(BaseResultMessage(id: 3, success: true))
//            )
//
////            expect(self.client.currentPhase) == .authenticated
//            done()
//        }
//    }
//
//    func testHandlesResponsesToPopulateRegistry() {
//        client.requestRegistry()
//
//        TestExamples.simulatePopulateRegistryResponses(mockExchange)
//
////        expect(self.client.currentPhase) == .authenticated
//
//        client.registry.allAreas.sink(receiveValue: { value in
//            expect(value).to(haveCount(2))
//        }).store(in: &cancellables)
//
//        client.registry.allDevices.sink(receiveValue: { value in
//            expect(value).to(haveCount(3))
//        }).store(in: &cancellables)
//
//        client.registry.allEntities.sink(receiveValue: { value in
//            expect(value).to(haveCount(4))
//        }).store(in: &cancellables)
//    }
//
//    func testReturnsEntitesByArea() {
//        client.requestRegistry()
//        TestExamples.simulatePopulateRegistryResponses(mockExchange)
//
//        client.registry.entitiesInArea(areaId: "living-room").sink(receiveValue: { entities in
//            expect(entities).to(haveCount(3))
//            expect(entities).to(contain([
//                Entity(
//                    id: "light.living_room_lamp",
//                    areaId: nil,
//                    deviceId: "device-id-1",
//                    platform: "mqtt"
//                ),
//                Entity(
//                    id: "sensor.living_room_humidity",
//                    areaId: nil,
//                    deviceId: "device-id-3",
//                    platform: "mqtt"
//                ),
//                Entity(
//                    id: "sensor.living_room_temperature",
//                    areaId: nil,
//                    deviceId: "device-id-3",
//                    platform: "mqtt"
//                ),
//            ]))
//        }).store(in: &cancellables)
//
//        client.registry.entitiesInArea(areaId: "bedroom").sink(receiveValue: { entities in
//            expect(entities).to(haveCount(1))
//            expect(entities).to(contain([
//                Entity(
//                    id: "light.bedroom_lamp",
//                    areaId: nil,
//                    deviceId: "device-id-2",
//                    platform: "mqtt"
//                ),
//            ]))
//        }).store(in: &cancellables)
//    }
//}
