//
//  OpenBetaDTO.swift
//  CragWeather
//

import Foundation

struct OpenBetaGraphQLRequest: Encodable {
    let query: String
    let variables: [String: OpenBetaVariable]
}

enum OpenBetaVariable: Encodable {
    case int(Int)
    case string(String)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

struct OpenBetaAreasResponse: Decodable {
    let data: OpenBetaAreasData?
    let errors: [OpenBetaGraphQLError]?
}

struct OpenBetaGraphQLError: Decodable {
    let message: String
}

struct OpenBetaAreasData: Decodable {
    let areas: [OpenBetaArea]
}

struct OpenBetaArea: Decodable {
    let uuid: String
    let areaName: String
    let pathTokens: [String]?
    let metadata: OpenBetaMetadata?
    let climbs: [OpenBetaClimb]?

    enum CodingKeys: String, CodingKey {
        case uuid
        case areaName = "area_name"
        case pathTokens
        case metadata
        case climbs
    }
}

struct OpenBetaMetadata: Decodable {
    let lat: Double?
    let lng: Double?
}

struct OpenBetaClimb: Decodable {
    let type: OpenBetaClimbType?
}

struct OpenBetaClimbType: Decodable {
    let sport: Bool?
    let trad: Bool?
    let bouldering: Bool?
    let alpine: Bool?
    let tr: Bool?
}

struct OpenBetaAreaDTO {
    let openBetaId: String
    let name: String
    let region: String
    let latitude: Double
    let longitude: Double
    let climbTypes: [ClimbType]

    init?(area: OpenBetaArea) {
        guard let lat = area.metadata?.lat, let lng = area.metadata?.lng else {
            return nil
        }

        openBetaId = area.uuid
        name = area.areaName
        region = OpenBetaAreaDTO.region(from: area.pathTokens ?? [])
        latitude = lat
        longitude = lng

        var types = Set<ClimbType>()
        for climb in area.climbs ?? [] {
            if let climbType = climb.type {
                ClimbType.fromOpenBeta(type: climbType).forEach { types.insert($0) }
            }
        }
        climbTypes = Array(types).sorted { $0.displayName < $1.displayName }
    }

    private static func region(from pathTokens: [String]) -> String {
        if pathTokens.count > 2 {
            return pathTokens[2]
        }
        if pathTokens.count > 1 {
            return pathTokens[1]
        }
        return "Colorado"
    }
}
