import Foundation
import MapKit
import Observation

/// Apple Maps address suggestions for the property street, biased to Southern California.
/// No location permission is needed.
@Observable
final class AddressSearch: NSObject, MKLocalSearchCompleterDelegate {
    struct Suggestion: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let subtitle: String
        fileprivate let completion: MKLocalSearchCompletion

        static func == (lhs: Suggestion, rhs: Suggestion) -> Bool { lhs.id == rhs.id }
    }

    struct Resolved {
        var street: String
        var city: String
        var state: String
        var zip: String
    }

    private(set) var suggestions: [Suggestion] = []
    private let searchCompleter = MKLocalSearchCompleter()
    @ObservationIgnored private var lastQuery = ""

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
        searchCompleter.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.19, longitude: -118.45),
            span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        )
    }

    func update(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != lastQuery else { return }
        lastQuery = trimmed
        if trimmed.count < 3 {
            searchCompleter.cancel()
            suggestions = []
        } else {
            searchCompleter.queryFragment = trimmed
        }
    }

    func clear() {
        searchCompleter.cancel()
        lastQuery = ""
        suggestions = []
    }

    /// Looks up the full address so city, state and ZIP can be filled in.
    func resolve(_ suggestion: Suggestion) async -> Resolved? {
        let request = MKLocalSearch.Request(completion: suggestion.completion)
        request.resultTypes = .address
        guard let response = try? await MKLocalSearch(request: request).start(),
              let placemark = response.mapItems.first?.placemark else { return nil }
        let street = [placemark.subThoroughfare, placemark.thoroughfare].compactMap { $0 }.joined(separator: " ")
        return Resolved(
            street: street.isEmpty ? suggestion.title : street,
            city: placemark.locality ?? "",
            state: placemark.administrativeArea ?? "CA",
            zip: placemark.postalCode ?? ""
        )
    }

    // MARK: MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results.prefix(4).map { result in
            Suggestion(
                title: result.title,
                subtitle: result.subtitle
                    .replacingOccurrences(of: ", United States", with: "")
                    .replacingOccurrences(of: "  ", with: " "),
                completion: result
            )
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}
