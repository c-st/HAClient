# HAClient

![HAClient](https://github.com/c-st/HAClient/workflows/HAClient/badge.svg)

A Swift client for the HomeAssistant WebSocket API. 

## Usage

### Add HAClient to your project

Add the following lines to your `Package.swift` or use Xcode's "Add Package Dependency…" menu.

```swift
// `Package.swift`

dependencies: [
    // ...
    .package(url: "https://github.com/c-st/HAClient.git"),
    // ...
]
```

### Use in your code

```swift
let url = "ws://homeassistant.raspberrypi.localdomain/api/websocket"
let client = HAClient(messageExchange: WebSocketStream(url))

// Authenticate
let token = "insert long-lived access token"
try await client.authenticate(token: token)

// Make API requests
let areas = try await client.listAreas()
let devices = try await client.listDevices()
let entities = try await client.listEntities()
let states = try await client.retrieveStates()
```

## Reference

[WebSocket API documentation](https://developers.home-assistant.io/docs/api/websocket/)
