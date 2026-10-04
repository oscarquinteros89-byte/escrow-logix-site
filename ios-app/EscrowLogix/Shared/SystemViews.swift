import SwiftUI
import SafariServices
import WebKit
import Contacts
import ContactsUI

/// A web address to open in an in-app Safari sheet.
struct WebLink: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

/// In-app Safari for escrowlogix.com pages, the 24/7 Assistant and Google Reviews.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(Palette.accent)
        controller.dismissButtonStyle = .done
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

/// Hosts ShareFile's Remote Upload Form. The file goes straight to ShareFile, never through the app.
struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.allowsBackForwardNavigationGestures = true
        view.load(URLRequest(url: url))
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {}
}

/// Apple's "New Contact" card, filled in with the office's verified details.
struct NewContactView: UIViewControllerRepresentable {
    let onFinish: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = CNContactViewController(forNewContact: Self.officeContact())
        controller.delegate = context.coordinator
        return UINavigationController(rootViewController: controller)
    }

    func updateUIViewController(_ controller: UINavigationController, context: Context) {}

    static func officeContact() -> CNMutableContact {
        let contact = CNMutableContact()
        contact.contactType = .organization
        contact.organizationName = "Escrow Logix"
        contact.phoneNumbers = [
            CNLabeledValue(label: CNLabelWork, value: CNPhoneNumber(stringValue: Office.phoneForContacts)),
            CNLabeledValue(label: CNLabelPhoneNumberWorkFax, value: CNPhoneNumber(stringValue: Office.faxForContacts))
        ]
        let address = CNMutablePostalAddress()
        address.street = Office.street
        address.city = Office.city
        address.state = Office.state
        address.postalCode = Office.zip
        address.country = "United States"
        contact.postalAddresses = [CNLabeledValue(label: CNLabelWork, value: address)]
        contact.urlAddresses = [CNLabeledValue(label: CNLabelURLAddressHomePage, value: Office.website.absoluteString as NSString)]
        return contact
    }

    final class Coordinator: NSObject, CNContactViewControllerDelegate {
        let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            onFinish()
        }
    }
}

/// Calls the office and reports click_to_call with where the tap came from.
struct CallButton<Label: View>: View {
    /// header, contact card, faq, footer, form, requests (same values as the website).
    let location: String
    @ViewBuilder var label: () -> Label
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            Analytics.track(.clickToCall, ["link_location": location])
            openURL(Office.phoneURL)
        } label: {
            label()
        }
        .accessibilityHint("Calls Escrow Logix at \(Office.phoneDisplay)")
    }
}
