# Escrow Logix iPhone app (side experiment)

A native SwiftUI version of the Open Escrow page: same brand, copy, questions, checks and CRM payload as the website, refined for iPhone. It lives only in this `ios-app/` folder on the `claude/project-thread-f1nci0` branch. The website files (`index.html`, `404.html`, `images/`) are not touched.

## Open and run

1. Open `ios-app/EscrowLogix.xcodeproj` in Xcode 26 or later.
2. Pick an iPhone simulator (for example iPhone 17 Pro) and press Run.

The app runs on iOS 17 and later; on iOS 26 it uses Liquid Glass. No sign-in or Apple Developer team is needed for the simulator. To run on a real iPhone, choose your team under Signing & Capabilities.

## What's in it

- **Home**: the hero with both Open buttons, the four numbers, the rep card when opened from a rep link, How it works, and the wire-fraud warning.
- **Open Escrow** (a sheet, five steps): type, contact, transaction (with Apple Maps address lookup), documents (reference plus the ShareFile upload), review with consent, and the confirmation. Progress saves as a draft while you type.
- **Requests**: the draft and every request sent from this iPhone, with its reference, Call and Upload.
- **Contact**: call the office (with an Open now / Closed chip), directions, the 24/7 Assistant, Save to Contacts, and the team.
- **Help**: the website's FAQ, adapted for the app, and what the app keeps on the phone.

## Settings to fill before launch

All in `EscrowLogix/App/AppConfig.swift`, mirroring the website's `CONFIG` block:

| Setting | What it does | Today |
| --- | --- | --- |
| `crmEndpoint` | Webhook that receives the request (same JSON as the website, source "iPhone App – Open Escrow") | empty: prototype mode, nothing is sent |
| `shareFile` | ShareFile Remote Upload Form links for Purchase Contracts and 1003s | empty: the upload button explains it isn't connected |
| `reps` | Names, titles and photos for rep links | Andrea Kawawaki |

Analytics uses the website's event names (`escrow_step`, `generate_lead`, `escrow_submit_failed`, `click_to_call`, `faq_open`) and is off until Escrow Logix picks an account (see `Shared/Analytics.swift`). Nothing typed into the form is ever sent to analytics.

## Rep links

`escrowlogix://open?rep=andrea-kawawaki`, `escrowlogix://andrea-kawawaki` and `escrowlogix://rep/andrea-kawawaki` all credit Andrea, and UTM tags ride along. Add `&type=purchase` or `&type=refinance` to open the form straight away. As on the website today, rep credit lasts for the current app session. Web links that open the app (Universal Links) need the production domain first.

## Demo screens (Debug builds only)

The app can open on any screen with sample data, which is how the screenshots are made:

```sh
xcrun simctl launch booted com.escrowlogix.openescrow -demo step3-details
xcrun simctl io booted screenshot step3-details.png
```

Screens: `home`, `home-rep`, `step1`, `step2`, `step3-address`, `step3-details`, `step4`, `step4-sender`, `step5`, `step5-submit`, `success`, `requests`, `requests-empty`, `contact`, `team`, `help`, `draft-choice`. Use `xcrun simctl ui booted appearance dark` for dark mode. Demo runs never touch saved requests. In Xcode, the scheme has a `-demo home-rep` argument you can switch on under Product > Scheme > Edit Scheme > Arguments.

`design/reference/` holds the design pictures the app was built from, for side-by-side checks.

## Before the App Store

- Apple Developer Program membership ($99 a year) and the team set in Signing.
- A live CRM webhook and ShareFile links (App Review won't accept a form that sends nothing), or review notes that explain the prototype.
- A privacy policy link, and App Privacy answers that match `EscrowLogix/PrivacyInfo.xcprivacy` (name, email, phone, property address and deal amounts, used only to open the escrow, no tracking).
- Escrow Logix confirms the wire-fraud wording, license and privacy disclosures.
- Screenshots: the demo screens above at 6.9" and 6.5" sizes.
