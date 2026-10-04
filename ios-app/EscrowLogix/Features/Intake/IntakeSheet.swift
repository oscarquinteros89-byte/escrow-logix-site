import SwiftUI

/// The Open Escrow sheet: header with progress, one step at a time, and a sticky bottom button.
struct IntakeSheet: View {
    @Bindable var model: IntakeModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focus: Field?
    @State private var confirmingClose = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollViewReader { proxy in
                ScrollView {
                    stepContent
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 28)
                }
                .scrollDismissesKeyboard(.interactively)
                .id(model.step)
                .transition(stepTransition)
                .onChange(of: model.focusRequest) { _, request in
                    guard let request else { return }
                    withAnimation(.smooth(duration: 0.3)) {
                        proxy.scrollTo(request.field, anchor: .center)
                    }
                    if Self.textFields.contains(request.field) { focus = request.field }
                }
                .onAppear {
                    guard let demo = model.demoScroll else { return }
                    model.demoScroll = nil
                    Task {
                        try? await Task.sleep(for: .milliseconds(350))
                        proxy.scrollTo(demo.field, anchor: demo.atBottom ? .bottom : .top)
                        if demo.focuses { focus = demo.field }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        }
        .background(Palette.bg.ignoresSafeArea())
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .smooth(duration: 0.38), value: model.step)
        .onChange(of: focus) { previous, _ in
            model.didLeave(previous)
        }
        .onChange(of: model.form) { _, _ in
            model.formDidChange()
        }
        .sensoryFeedback(.error, trigger: model.errorCount)
        .sensoryFeedback(.success, trigger: model.isFinished) { _, finished in finished }
        .sensoryFeedback(.selection, trigger: model.form.type)
        .interactiveDismissDisabled(model.hasContent && !model.isFinished)
        .presentationBackground(Palette.bg)
        .confirmationDialog("Keep this request for later?", isPresented: $confirmingClose, titleVisibility: .visible) {
            Button("Save as draft") {
                dismiss()
            }
            Button("Delete it", role: .destructive) {
                model.discardDraft()
                dismiss()
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("Drafts stay on this iPhone, under Requests.")
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                if model.step == 1 {
                    CircleIconButton(systemName: "xmark", label: "Close") { close() }
                } else if model.isFinished {
                    Color.clear.frame(width: 44, height: 44)
                } else {
                    CircleIconButton(systemName: "chevron.left", label: "Back") { model.back() }
                }
                Spacer(minLength: 8)
                VStack(spacing: 1) {
                    Text("Open Escrow")
                        .font(.headline)
                        .foregroundStyle(Palette.heading)
                    Text(model.subtitle)
                        .font(.caption)
                        .foregroundStyle(Palette.text2)
                        .contentTransition(.opacity)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                if model.step == 1 {
                    Color.clear.frame(width: 44, height: 44)
                } else {
                    CircleIconButton(systemName: "xmark", label: "Close") { close() }
                }
            }
            if !model.isFinished {
                ProgressSegments(step: model.step)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    // MARK: Steps

    @ViewBuilder
    private var stepContent: some View {
        switch model.step {
        case 1: StepTypeView(model: model)
        case 2: StepContactView(model: model, focus: $focus)
        case 3: StepTransactionView(model: model, focus: $focus)
        case 4: StepDocumentsView(model: model, focus: $focus)
        case 5: StepReviewView(model: model)
        default: SuccessView(model: model)
        }
    }

    /// The new step slides in from the side it comes from; the old one fades.
    private var stepTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .offset(x: model.movingForward ? 44 : -44).combined(with: .opacity),
            removal: .opacity
        )
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 6) {
            if model.step == 5, let message = model.submitError {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Palette.error)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 4)
            }
            Button {
                primaryAction()
            } label: {
                HStack(spacing: 10) {
                    if model.isSubmitting {
                        ProgressView().tint(Palette.primaryForeground)
                    }
                    Text(model.primaryTitle)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!model.canContinue || model.isSubmitting)
            if model.isFinished {
                Button("Open another escrow") {
                    model.startOver()
                }
                .font(.headline)
                .foregroundStyle(Palette.accent)
                .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 8)
        .background {
            LinearGradient(
                stops: [
                    .init(color: Palette.bg.opacity(0), location: 0),
                    .init(color: Palette.bg.opacity(0.92), location: 0.3),
                    .init(color: Palette.bg, location: 0.6)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private func primaryAction() {
        switch model.step {
        case 5:
            focus = nil
            Task { await model.submit() }
        case 6:
            dismiss()
        default:
            focus = nil
            model.advance()
        }
    }

    private func close() {
        focus = nil
        if model.isFinished || !model.hasContent {
            dismiss()
        } else {
            confirmingClose = true
        }
    }

    private static let textFields: Set<Field> = [
        .firstName, .lastName, .email, .phone, .company, .street, .city, .state, .zip, .apn,
        .salePrice, .deposit, .buyerNames, .sellerNames, .otherAgent,
        .loanAmount, .lender, .borrowerNames, .loanOfficer, .notes, .senderName, .senderEmail
    ]
}
