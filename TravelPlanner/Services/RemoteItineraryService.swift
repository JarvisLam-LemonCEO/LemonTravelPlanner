import Foundation

struct RemoteItineraryService: ItineraryService {
    enum ServiceError: LocalizedError {
        case invalidURL
        case invalidResponse
        case serverError(statusCode: Int, message: String)
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "The itinerary service URL is invalid."

            case .invalidResponse:
                return "The server returned an invalid response."

            case .serverError(_, let message):
                return message

            case .decodingFailed:
                return "The itinerary response could not be read."
            }
        }
    }

    private let baseURL: URL
    private let session: URLSession

    init(
        baseURL: URL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    func generateItinerary(
        for trip: Trip
    ) async throws -> GeneratedItineraryResponse {
        let endpoint = baseURL.appendingPathComponent(
            "api/itineraries/generate"
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        let payload = ItineraryGenerationRequest(
            tripTitle: trip.title,
            destination: trip.destination,
            startDate: Self.apiDateFormatter.string(
                from: trip.startDate
            ),
            endDate: Self.apiDateFormatter.string(
                from: trip.endDate
            ),
            budget: trip.budget,
            currencyCode: trip.currencyCode,
            travelPace: trip.travelPace,
            interests: trip.interests
        )

        request.httpBody = try JSONEncoder().encode(
            payload
        )

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(
                for: request
            )
        } catch {
            throw error
        }

        guard let httpResponse =
            response as? HTTPURLResponse
        else {
            throw ServiceError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let serverMessage =
                decodeServerMessage(from: data)
                ?? "The server returned status \(httpResponse.statusCode)."

            throw ServiceError.serverError(
                statusCode: httpResponse.statusCode,
                message: serverMessage
            )
        }

        do {
            return try JSONDecoder().decode(
                GeneratedItineraryResponse.self,
                from: data
            )
        } catch {
            print(
                "Itinerary decoding error:",
                error
            )

            throw ServiceError.decodingFailed
        }
    }

    private func decodeServerMessage(
        from data: Data
    ) -> String? {
        struct ErrorResponse: Decodable {
            let message: String?
            let error: String?
        }

        guard let response =
            try? JSONDecoder().decode(
                ErrorResponse.self,
                from: data
            )
        else {
            return nil
        }

        return response.message ?? response.error
    }

    private static let apiDateFormatter:
        DateFormatter = {

        let formatter = DateFormatter()
        formatter.calendar = Calendar(
            identifier: .gregorian
        )
        formatter.locale = Locale(
            identifier: "en_US_POSIX"
        )
        formatter.timeZone = TimeZone(
            secondsFromGMT: 0
        )
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter
    }()
}
