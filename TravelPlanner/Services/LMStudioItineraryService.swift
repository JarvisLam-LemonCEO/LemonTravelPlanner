import Foundation

struct LMStudioItineraryService: ItineraryService {
    enum ServiceError: LocalizedError {
        case invalidResponse
        case noGeneratedContent
        case serverError(statusCode: Int, message: String)
        case invalidGeneratedJSON
        case decodingFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "LM Studio returned an invalid response."

            case .noGeneratedContent:
                return "The local model did not generate an itinerary."

            case .serverError(_, let message):
                return message

            case .invalidGeneratedJSON:
                return "The local model returned invalid JSON."

            case .decodingFailed(let details):
                return "The itinerary could not be decoded: \(details)"
            }
        }
    }

    private let baseURL: URL
    private let modelIdentifier: String
    private let session: URLSession
    private let apiToken: String?

    init(
        baseURL: URL = URL(
            string: "http://127.0.0.1:1234"
        )!,
        modelIdentifier: String,
        apiToken: String? = nil,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.modelIdentifier = modelIdentifier
        self.apiToken = apiToken
        self.session = session
    }

    func generateItinerary(
        for trip: Trip
    ) async throws -> GeneratedItineraryResponse {
        let endpoint = baseURL.appending(
            path: "v1/chat/completions"
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 180

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        if let apiToken,
           !apiToken.isEmpty {
            request.setValue(
                "Bearer \(apiToken)",
                forHTTPHeaderField: "Authorization"
            )
        }

        let requestBody = ChatCompletionRequest(
            model: modelIdentifier,
            messages: [
                ChatMessage(
                    role: "system",
                    content: systemPrompt
                ),
                ChatMessage(
                    role: "user",
                    content: userPrompt(for: trip)
                )
            ],
            responseFormat: ResponseFormat(
                type: "json_schema",
                jsonSchema: JSONSchemaContainer(
                    name: "travel_itinerary",
                    strict: true,
                    schema: itinerarySchema
                )
            ),
            temperature: 0.4,
            maxTokens: 8_000,
            stream: false
        )

        request.httpBody = try JSONEncoder().encode(
            requestBody
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
            let message =
                decodeServerError(from: data)
                ?? "LM Studio returned status \(httpResponse.statusCode)."

            throw ServiceError.serverError(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }

        let completionResponse: ChatCompletionResponse

        do {
            completionResponse = try JSONDecoder().decode(
                ChatCompletionResponse.self,
                from: data
            )
        } catch {
            throw ServiceError.decodingFailed(
                error.localizedDescription
            )
        }

        guard let content =
            completionResponse
                .choices
                .first?
                .message
                .content,
              !content.isEmpty
        else {
            throw ServiceError.noGeneratedContent
        }

        guard let itineraryData =
            content.data(using: .utf8)
        else {
            throw ServiceError.invalidGeneratedJSON
        }

        do {
            return try JSONDecoder().decode(
                GeneratedItineraryResponse.self,
                from: itineraryData
            )
        } catch {
            print("Generated content:", content)
            print("Itinerary decode error:", error)

            throw ServiceError.decodingFailed(
                error.localizedDescription
            )
        }
    }

    private var systemPrompt: String {
        """
        You are a professional travel itinerary planner.

        Create a practical day-by-day travel itinerary.

        Requirements:
        - Use the exact dates supplied by the user.
        - Do not create overlapping activities.
        - Use 24-hour HH:mm time values.
        - Keep activities geographically reasonable.
        - Respect the user's budget and travel pace.
        - Use reasonable estimated prices.
        - Do not claim prices, opening hours, availability, or coordinates are verified live.
        - Return only JSON matching the provided schema.
        """
    }

    private func userPrompt(
        for trip: Trip
    ) -> String {
        let payload = ItineraryGenerationRequest(
            tripTitle: trip.title,
            destination: trip.destination,
            startDate: Self.dateFormatter.string(
                from: trip.startDate
            ),
            endDate: Self.dateFormatter.string(
                from: trip.endDate
            ),
            budget: trip.budget,
            currencyCode: trip.currencyCode,
            travelPace: trip.travelPace,
            interests: trip.interests
        )

        guard let data = try? JSONEncoder().encode(
            payload
        ),
        let json = String(
            data: data,
            encoding: .utf8
        ) else {
            return """
            Create an itinerary for \(trip.destination).
            """
        }

        return """
        Create an itinerary for this trip:

        \(json)
        """
    }

    private func decodeServerError(
        from data: Data
    ) -> String? {
        struct ErrorEnvelope: Decodable {
            let error: ErrorDetail?
            let message: String?

            struct ErrorDetail: Decodable {
                let message: String?
            }
        }

        guard let response =
            try? JSONDecoder().decode(
                ErrorEnvelope.self,
                from: data
            )
        else {
            return nil
        }

        return response.error?.message
            ?? response.message
    }

    private static let dateFormatter: DateFormatter = {
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
    
    private var itinerarySchema: JSONValue {
        .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "summary": .object([
                    "type": .string("string")
                ]),
                "days": .object([
                    "type": .string("array"),
                    "items": .object([
                        "type": .string("object"),
                        "additionalProperties": .bool(false),
                        "properties": .object([
                            "dayNumber": .object([
                                "type": .string("integer")
                            ]),
                            "date": .object([
                                "type": .string("string")
                            ]),
                            "city": .object([
                                "type": .string("string")
                            ]),
                            "hotelCost": .object([
                                "type": .string("number")
                            ]),
                            "foodCost": .object([
                                "type": .string("number")
                            ]),
                            "activities": .object([
                                "type": .string("array"),
                                "items": activitySchema
                            ])
                        ]),
                        "required": .array([
                            .string("dayNumber"),
                            .string("date"),
                            .string("city"),
                            .string("hotelCost"),
                            .string("foodCost"),
                            .string("activities")
                        ])
                    ])
                ])
            ]),
            "required": .array([
                .string("summary"),
                .string("days")
            ])
        ])
    }

    private var activitySchema: JSONValue {
        .object([
            "type": .string("object"),
            "additionalProperties": .bool(false),
            "properties": .object([
                "name": .object([
                    "type": .string("string")
                ]),
                "description": .object([
                    "type": .string("string")
                ]),
                "category": .object([
                    "type": .string("string"),
                    "enum": .array([
                        .string("attraction"),
                        .string("food"),
                        .string("hotel"),
                        .string("transportation"),
                        .string("shopping"),
                        .string("relaxation"),
                        .string("other")
                    ])
                ]),
                "startTime": .object([
                    "type": .string("string")
                ]),
                "endTime": .object([
                    "type": .string("string")
                ]),
                "locationName": .object([
                    "type": .string("string")
                ]),
                "latitude": .object([
                    "type": .array([
                        .string("number"),
                        .string("null")
                    ])
                ]),
                "longitude": .object([
                    "type": .array([
                        .string("number"),
                        .string("null")
                    ])
                ]),
                "admissionFee": .object([
                    "type": .string("number")
                ]),
                "transportationCost": .object([
                    "type": .string("number")
                ])
            ]),
            "required": .array([
                .string("name"),
                .string("description"),
                .string("category"),
                .string("startTime"),
                .string("endTime"),
                .string("locationName"),
                .string("latitude"),
                .string("longitude"),
                .string("admissionFee"),
                .string("transportationCost")
            ])
        ])
    }
}
