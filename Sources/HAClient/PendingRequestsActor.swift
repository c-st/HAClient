actor PendingRequestsActor {
    typealias RequestID = Int

    private var lastUsedRequestId: RequestID?
    private var pendingRequests: [RequestID: CommandType] = [:]
    
    private var responses: [RequestID: Any] = [:]
    
    public func insert(type: CommandType) -> RequestID {
        let id = getAndIncrementId()
        pendingRequests[id] = type
        return id
    }
    
    public func getType(_ id: RequestID) -> CommandType? {
        return pendingRequests[id] ?? nil
    }
    
    public func addResponse(id: RequestID, _ message: Any) {
        responses[id] = message
    }
    
    public func getResponse(_ id: RequestID) -> Any? {
        return responses[id] ?? nil
    }
    
    public func remove(id: RequestID) -> Void {
        pendingRequests.removeValue(forKey: id)
        responses.removeValue(forKey: id)
    }
    
    private func getAndIncrementId() -> Int {
        let id = (lastUsedRequestId ?? 0) + 1
        lastUsedRequestId = id
        return id
    }
}
