//
//  Future+Extensions.swift
//  Top10Places
//
//  Created by Arviejhay Alejandro on 7/15/26.
//

import Combine

extension Future where Failure == Error {
    convenience init(operation: @escaping @Sendable () async throws -> Output) {
        self.init { promise in
            nonisolated(unsafe) let promise = promise
            Task {
                do {
                    promise(.success(try await operation()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}
