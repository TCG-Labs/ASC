//
//  Data+Extension.swift
//  ASC
//
//  Created by Vyacheslav Razumeenko on 07.01.2026.
//

import Foundation

extension Data {
    var toString: String {
        .init(bytes: self, encoding: .utf8) ?? ""
    }

    // NSString gives us a nice sanitized debugDescription
    var prettyPrintedJSONString: NSString? {
        guard
            let object = try? JSONSerialization.jsonObject(with: self, options: []),
            let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
            let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        else { return nil }

        return prettyPrintedString
    }
}
