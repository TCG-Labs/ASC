// ASCLoggerTests.swift
// ASC - Alamofire Swift Client Tests
//
//  Copyright (c) 2025 TCG Labs
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Testing
import Foundation
import Alamofire
@testable import ASC

@Suite("ASCLogger Tests")
struct ASCLoggerTests {
    // MARK: - Initialization Tests

    @Test("Logger initializes with specified log level")
    func testLoggerInitialization() {
        // Given: Log level configuration
        let logLevel = ASCLogLevel.debug
        
        // When: Creating logger instance
        let logger = ASCLogger(logLevel: logLevel)
        
        // Then: Logger should be initialized with correct queue
        #expect(logger.queue.label == "com.asc.logger")
    }

    @Test("Logger initializes with custom subsystem and category")
    func testLoggerInitializationWithCustomSubsystem() {
        // Given: Custom subsystem and category
        let subsystem = "com.test.subsystem"
        let category = "TestCategory"
        let logLevel = ASCLogLevel.info
        
        // When: Creating logger with custom configuration
        let logger = ASCLogger(
            logLevel: logLevel,
            subsystem: subsystem,
            category: category
        )
        
        // Then: Logger should use shared queue regardless of configuration
        #expect(logger.queue.label == "com.asc.logger")
    }

    @Test("Logger instances share the same queue")
    func testLoggerHasSharedQueue() {
        // Given: Multiple logger instances with different configurations
        let logger1 = ASCLogger(logLevel: .debug)
        let logger2 = ASCLogger(logLevel: .verbose)
        
        // When: Accessing queue property
        let queue1 = logger1.queue
        let queue2 = logger2.queue
        
        // Then: Both loggers should use the same shared queue instance
        #expect(queue1 === queue2)
    }
}

