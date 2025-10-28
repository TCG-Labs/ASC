// NetworkReachability.swift
// ASC - Alamofire Swift Client

// Network connectivity monitoring using NWPathMonitor.

@preconcurrency import Combine
import Foundation
import Network

/// Monitors network connectivity status.
///
/// Uses Apple's `Network.framework` to monitor network reachability in real-time.
/// Provides both synchronous status checks and an async stream for reactive monitoring.
///
/// Example:
/// ```swift
/// let reachability = NetworkReachability()
/// reachability.startMonitoring()
///
/// // Check current status
/// if case .reachable = reachability.currentStatus {
///     print("Network is available")
/// }
///
/// // Monitor changes
/// Task {
///     for await status in reachability.statusStream {
///         print("Network status changed: \(status)")
///     }
/// }
/// ```
public final class NetworkReachability: @unchecked Sendable {
    // MARK: - Types

    /// Network connectivity status.
    public enum Status: Sendable {
        /// Network is reachable.
        ///
        /// - Parameter connectionType: The type of connection available
        case reachable(ConnectionType)

        /// Network is not reachable.
        case unreachable

        /// The type of network connection.
        public enum ConnectionType: Sendable {
            /// Wi-Fi connection
            case wifi
            /// Cellular connection
            case cellular
            /// Wired Ethernet connection
            case wired
            /// Other connection type
            case other
        }

        /// Returns true if network is reachable.
        public var isReachable: Bool {
            if case .reachable = self {
                return true
            }
            return false
        }
    }

    // MARK: - Properties

    /// Network path monitor.
    private let monitor: NWPathMonitor

    /// Dispatch queue for monitoring.
    private let queue: DispatchQueue

    /// Current network status (thread-safe via CurrentValueSubject).
    private let statusSubject: CurrentValueSubject<Status, Never>

    /// Cancellables storage.
    private var cancellables = Set<AnyCancellable>()

    /// Returns the current network status.
    ///
    /// This property is thread-safe and can be accessed from any queue.
    public var currentStatus: Status {
        statusSubject.value
    }

    /// Combine publisher for network status changes.
    ///
    /// Emits status whenever network connectivity changes.
    ///
    /// Example:
    /// ```swift
    /// reachability.statusPublisher
    ///     .sink { status in
    ///         print("Network status: \(status)")
    ///     }
    ///     .store(in: &cancellables)
    /// ```
    public var statusPublisher: AnyPublisher<Status, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    /// Async stream of network status changes.
    ///
    /// Emits status whenever network connectivity changes.
    /// The stream completes when monitoring is stopped.
    ///
    /// Example:
    /// ```swift
    /// for await status in reachability.statusStream {
    ///     switch status {
    ///     case .reachable(let type):
    ///         print("Network available: \(type)")
    ///     case .unreachable:
    ///         print("Network unavailable")
    ///     }
    /// }
    /// ```
    public var statusStream: AsyncStream<Status> {
        AsyncStream { continuation in
            let cancellable = statusSubject
                .sink { status in
                    continuation.yield(status)
                }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    // MARK: - Initialization

    /// Creates a new network reachability monitor.
    ///
    /// - Parameter queue: Dispatch queue for monitoring (default: background queue)
    public init(queue: DispatchQueue = DispatchQueue(label: "com.asc.reachability", qos: .background)) {
        self.monitor = NWPathMonitor()
        self.queue = queue

        // Get initial status synchronously from current path
        let initialStatus = Self.determineStatus(from: monitor.currentPath)
        self.statusSubject = CurrentValueSubject(initialStatus)

        setupMonitor()
    }

    /// Creates a new network reachability monitor for specific interface type.
    ///
    /// - Parameters:
    ///   - requiredInterfaceType: Required network interface type to monitor
    ///   - queue: Dispatch queue for monitoring (default: background queue)
    public init(
        requiredInterfaceType: NWInterface.InterfaceType,
        queue: DispatchQueue = DispatchQueue(label: "com.asc.reachability", qos: .background)
    ) {
        self.monitor = NWPathMonitor(requiredInterfaceType: requiredInterfaceType)
        self.queue = queue

        // Get initial status synchronously from current path
        let initialStatus = Self.determineStatus(from: monitor.currentPath)
        self.statusSubject = CurrentValueSubject(initialStatus)

        setupMonitor()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    /// Starts monitoring network connectivity.
    ///
    /// Call this method to begin receiving status updates.
    /// Status changes will be available through `currentStatus` and `statusStream`.
    public func startMonitoring() {
        monitor.start(queue: queue)
    }

    /// Stops monitoring network connectivity.
    ///
    /// After calling this method, no more status updates will be received.
    /// The publisher and stream will complete.
    public func stopMonitoring() {
        monitor.cancel()
        statusSubject.send(completion: .finished)
        cancellables.removeAll()
    }

    // MARK: - Private Methods

    /// Sets up the network path monitor.
    private func setupMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            let status = Self.determineStatus(from: path)
            self.statusSubject.send(status)
        }
    }

    /// Determines the status from a network path.
    private static func determineStatus(from path: NWPath) -> Status {
        guard path.status == .satisfied else {
            return .unreachable
        }

        let connectionType: Status.ConnectionType
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wired
        } else {
            connectionType = .other
        }

        return .reachable(connectionType)
    }
}

// MARK: - Enhanced Publishers

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension NetworkReachability {
    /// Debounced status publisher that prevents rapid status changes.
    ///
    /// Useful for UI updates to avoid flickering when network status changes rapidly.
    /// Debounces changes for 500ms and removes duplicate consecutive reachability states.
    ///
    /// Example:
    /// ```swift
    /// reachability.debouncedStatusPublisher
    ///     .sink { status in
    ///         updateUI(for: status)
    ///     }
    ///     .store(in: &cancellables)
    /// ```
    var debouncedStatusPublisher: AnyPublisher<Status, Never> {
        statusPublisher
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates { $0.isReachable == $1.isReachable }
            .eraseToAnyPublisher()
    }

    /// Publisher that emits only when network becomes available.
    ///
    /// Filters out unreachable states and emits the connection type when network is available.
    /// Useful for triggering sync operations or showing "back online" notifications.
    ///
    /// Example:
    /// ```swift
    /// reachability.networkAvailablePublisher
    ///     .sink { connectionType in
    ///         print("Network available via \(connectionType)")
    ///         syncData()
    ///     }
    ///     .store(in: &cancellables)
    /// ```
    var networkAvailablePublisher: AnyPublisher<Status.ConnectionType, Never> {
        statusPublisher
            .compactMap { status in
                if case .reachable(let type) = status {
                    return type
                }
                return nil
            }
            .eraseToAnyPublisher()
    }

    /// Publisher that emits only when network becomes unavailable.
    ///
    /// Filters out reachable states and emits when network connection is lost.
    /// Useful for pausing operations or showing offline UI.
    ///
    /// Example:
    /// ```swift
    /// reachability.networkUnavailablePublisher
    ///     .sink { _ in
    ///         print("Network unavailable")
    ///         pauseSync()
    ///     }
    ///     .store(in: &cancellables)
    /// ```
    var networkUnavailablePublisher: AnyPublisher<Void, Never> {
        statusPublisher
            .compactMap { status in
                if case .unreachable = status {
                    return ()
                }
                return nil
            }
            .eraseToAnyPublisher()
    }

    /// Publisher that emits boolean reachability status.
    ///
    /// Simplifies status to true/false for basic reachability checks.
    /// Removes duplicate consecutive values to reduce noise.
    ///
    /// Example:
    /// ```swift
    /// reachability.isReachablePublisher
    ///     .sink { isReachable in
    ///         statusLabel.text = isReachable ? "Online" : "Offline"
    ///     }
    ///     .store(in: &cancellables)
    /// ```
    var isReachablePublisher: AnyPublisher<Bool, Never> {
        statusPublisher
            .map(\.isReachable)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
