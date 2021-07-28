//
//  ParametersAdapter.swift
//  Clawee
//
//  Created by Danyl Timofeyev on 05.05.2021.
//  Copyright © 2021 Noisy Miner. All rights reserved.
//

import Foundation

// MARK: - Parameter model

struct Param {
    let key: String
    let value: CustomStringConvertible?
    init(_ key: String, _ value: CustomStringConvertible?) {
        self.key = key
        self.value = value
    }
}

// MARK: - RequestParametersAdapter

struct RequestParametersAdapter: URLRequestAdaptable {
    private let query: [Param]
    private let body: [Param]
    private let isFormUrlEncoded: Bool
    private var bodyJson: [String: CustomStringConvertible] {
        var jsonParameters: [String: CustomStringConvertible] = [:]
        body.forEach { jsonParameters[$0.key] = $0.value }
        return jsonParameters
    }
    
    init(query: [Param] = [],
         body: [Param] = [],
         isFormUrlEncoded: Bool = false
    ) {
        self.query = query
        self.body = body
        self.isFormUrlEncoded = isFormUrlEncoded
    }
    
    // MARK: - URLRequestAdaptable
    
    func adapt(_ urlRequest: inout URLRequest) {
        if query.count > 0 { adaptRequestWithQuery(&urlRequest) }
        if body.count > 0 {
            isFormUrlEncoded ? adaptRequestWithBodyURLEncoded(&urlRequest) : adaptRequestWithBody(&urlRequest)
        }
    }
}

// MARK: - Private

private extension RequestParametersAdapter {

    func adaptRequestWithQuery(_ urlRequest: inout URLRequest) {
        guard let url = urlRequest.url,
              var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
        let queryItems = query
            .filter { $0.value != nil }
            .map { URLQueryItem(name: $0.key, value: $0.value?.description) }
        urlComponents.queryItems = urlComponents.queryItems ?? [] + queryItems
        urlRequest.url = urlComponents.url
    }
    
    func adaptRequestWithBody(_ urlRequest: inout URLRequest) {
        guard !bodyJson.isEmpty else { return }
        guard let jsonData = try? JSONSerialization.data(
                withJSONObject: bodyJson,
                options: .prettyPrinted) else {
            fatalError("RequestParametersAdapter: JSONSerialization fail")
        }
        urlRequest.httpBody = jsonData
    }
    
    func adaptRequestWithBodyURLEncoded(_ urlRequest: inout URLRequest) {
        var urlFormDataComponents = URLComponents()
        let queryItems = body
            .filter { $0.value != nil }
            .map { URLQueryItem(name: $0.key, value: $0.value?.description) }
        urlFormDataComponents.queryItems = queryItems
        let data = urlFormDataComponents.query?.data(using: .utf8)
        urlRequest.httpBody = data
    }
}

