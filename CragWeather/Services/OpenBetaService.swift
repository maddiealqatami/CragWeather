//
//  OpenBetaService.swift
//  CragWeather
//

import Foundation

enum OpenBetaServiceError: LocalizedError {
    case invalidResponse(statusCode: Int?, detail: String?)
    case graphQLError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse(let statusCode, let detail):
            if let statusCode {
                return "Invalid response from OpenBeta (HTTP \(statusCode)). \(detail ?? "Try again.")"
            }
            return "Invalid response from OpenBeta. \(detail ?? "Try again.")"
        case .graphQLError(let message):
            return "OpenBeta error: \(message)"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

struct OpenBetaService {
    static let endpoint = URL(string: "https://api.openbeta.io/graphql")!
    static let pageSize = 50
    static let maxRetries = 4
    static let pageDelayNanoseconds: UInt64 = 250_000_000

    // MARK: - Configuration

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 300
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }()

    // MARK: - GraphQL queries

    private static let leafAreasQuery = """
    query LeafAreas($tokens: [String!]!, $limit: Int!, $offset: Int!) {
      areas(
        filter: {
          path_tokens: { tokens: $tokens }
          leaf_status: { isLeaf: true }
        }
        limit: $limit
        offset: $offset
      ) {
        uuid
        area_name
        pathTokens
        metadata { lat lng }
        climbs { type { sport trad bouldering alpine tr } }
      }
    }
    """

    private static let regionAreasQuery = """
    query RegionAreas($limit: Int!, $offset: Int!) {
      areas(
        filter: {
          path_tokens: { tokens: ["USA", "Colorado"] }
          leaf_status: { isLeaf: false }
        }
        limit: $limit
        offset: $offset
      ) {
        uuid
        area_name
        pathTokens
        metadata { lat lng }
      }
    }
    """

    // MARK: - Public API

    func fetchCrags(
        forRegion region: String,
        progress: (@MainActor (Int) -> Void)? = nil
    ) async throws -> [OpenBetaAreaDTO] {
        try await fetchLeafAreas(
            pathTokens: ["USA", "Colorado", region],
            progress: progress
        )
    }

    func fetchColoradoRegions() async throws -> [OpenBetaRegionDTO] {
        var allAreas: [OpenBetaArea] = []
        var offset = 0

        while true {
            let page = try await fetchRegionPage(limit: Self.pageSize, offset: offset)
            allAreas.append(contentsOf: page)

            if page.count < Self.pageSize {
                break
            }

            offset += Self.pageSize
            try await Task.sleep(nanoseconds: Self.pageDelayNanoseconds)
        }

        return allAreas.compactMap { OpenBetaRegionDTO(area: $0) }
    }

    // MARK: - Pagination

    private func fetchLeafAreas(
        pathTokens: [String],
        progress: (@MainActor (Int) -> Void)? = nil
    ) async throws -> [OpenBetaAreaDTO] {
        var allCrags: [OpenBetaAreaDTO] = []
        var offset = 0

        while true {
            let page = try await fetchLeafPage(
                pathTokens: pathTokens,
                limit: Self.pageSize,
                offset: offset
            )
            let dtos = page.compactMap { OpenBetaAreaDTO(area: $0) }
            allCrags.append(contentsOf: dtos)
            if let progress {
                await progress(allCrags.count)
            }

            if page.count < Self.pageSize {
                break
            }

            offset += Self.pageSize
            try await Task.sleep(nanoseconds: Self.pageDelayNanoseconds)
        }

        return allCrags
    }

    private func fetchLeafPage(pathTokens: [String], limit: Int, offset: Int) async throws -> [OpenBetaArea] {
        try await fetchPage(
            query: Self.leafAreasQuery,
            variables: [
                "tokens": pathTokens,
                "limit": limit,
                "offset": offset
            ],
            offset: offset
        )
    }

    private func fetchRegionPage(limit: Int, offset: Int) async throws -> [OpenBetaArea] {
        try await fetchPage(
            query: Self.regionAreasQuery,
            variables: [
                "limit": limit,
                "offset": offset
            ],
            offset: offset
        )
    }

    // MARK: - HTTP / retry

    private func fetchPage(
        query: String,
        variables: [String: Any],
        offset: Int
    ) async throws -> [OpenBetaArea] {
        var lastError: Error = OpenBetaServiceError.invalidResponse(statusCode: nil, detail: nil)

        for attempt in 1...Self.maxRetries {
            do {
                return try await fetchPageOnce(query: query, variables: variables, offset: offset)
            } catch {
                lastError = error
                guard attempt < Self.maxRetries, shouldRetry(error) else {
                    throw error
                }

                let backoff = UInt64(attempt) * 750_000_000
                try await Task.sleep(nanoseconds: backoff)
            }
        }

        throw lastError
    }

    private func shouldRetry(_ error: Error) -> Bool {
        switch error {
        case OpenBetaServiceError.invalidResponse(let statusCode, _):
            guard let statusCode else { return true }
            return statusCode == 429 || statusCode == 502 || statusCode == 503 || statusCode == 504
        case OpenBetaServiceError.networkError(let underlying):
            if let urlError = underlying as? URLError {
                switch urlError.code {
                case .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost:
                    return true
                default:
                    return false
                }
            }
            return true
        case OpenBetaServiceError.graphQLError:
            return false
        default:
            return false
        }
    }

    private func fetchPageOnce(
        query: String,
        variables: [String: Any],
        offset: Int
    ) async throws -> [OpenBetaArea] {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "query": query,
            "variables": variables
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await Self.session.data(for: request)
        } catch {
            throw OpenBetaServiceError.networkError(error)
        }

        let statusCode = (response as? HTTPURLResponse)?.statusCode
        guard let statusCode, (200...299).contains(statusCode) else {
            let detail = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(120)
                .description
            throw OpenBetaServiceError.invalidResponse(statusCode: statusCode, detail: detail)
        }

        let decoded: OpenBetaAreasResponse
        do {
            decoded = try JSONDecoder().decode(OpenBetaAreasResponse.self, from: data)
        } catch {
            throw OpenBetaServiceError.invalidResponse(
                statusCode: statusCode,
                detail: "Could not parse OpenBeta data."
            )
        }

        if let errors = decoded.errors, let first = errors.first {
            throw OpenBetaServiceError.graphQLError(first.message)
        }
        guard let areas = decoded.data?.areas else {
            throw OpenBetaServiceError.invalidResponse(
                statusCode: statusCode,
                detail: "Missing area data at offset \(offset)."
            )
        }
        return areas
    }
}
