//
//  HTTPHeader+Extension.swift
//  ASC
//
//  Created by Vyacheslav Razumeenko on 27.10.2025.
//

import Alamofire
import Foundation

public extension HTTPHeader {
    /// Authentication required marker header.
    ///
    /// This header marks requests that require authentication.
    /// When present, `AuthInterceptor` will inject the access token.
    static var authenticationRequired: Self {
        .init(name: "X-ASC-Auth-Required", value: "true")
    }
}
