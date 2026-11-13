import SwiftUI
import PhotosUI
import AVFoundation

struct PhotoSubmissionView: View {
    let bar: Bar
    @Environment(RewardsStore.self) private var rewards
    @Environment(\.dismiss) private var dismiss
    @State private var receipt = false
    @State private var amount: Decimal = 0
    @State private var caption = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photo: Data?
    @State private var showingCamera = false
    @State private var loading = false
    @State private var message = ""
    @State private var showingMessage = false

    var body: some View {
        Form {
            Section {
                Picker("Photo type", selection: $receipt) {
                    Text("Bar photo").tag(false)
                    Text("Receipt").tag(true)
                }
                .pickerStyle(.segmented)
                Text(receipt ? "Spend $25 or more · earn 100 demo points" : "If the bar is lit, take a picture! Get 50 demo points.")
                Text("One of each offer per bar per day. Duplicate images cannot earn points.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Your photo") {
                Button("Take Picture", systemImage: "camera") {
                    Task { await openCamera() }
                }
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose from Photos", systemImage: "photo")
                }
                if loading { ProgressView("Loading photo") }
                if let photo, let image = UIImage(data: photo) {
                    Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 250)
                }
                if receipt {
                    TextField("Receipt total ($)", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                    Text("Receipts are private and never appear in the gallery. This demo does not verify purchases.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    TextField("Add a caption", text: $caption, axis: .vertical)
                    Text("Only post photos you have permission to share. This demo gallery is saved on your device.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section {
                Button(receipt ? "Submit receipt · +100 demo points" : "Post photo · +50 demo points") {
                    guard let photo else { return }
                    do {
                        try rewards.submit(photo: photo, barID: bar.id, caption: caption,
                                           receipt: receipt, amount: amount)
                        dismiss()
                    } catch {
                        message = error.localizedDescription
                        showingMessage = true
                    }
                }
                .disabled(photo == nil || loading || (receipt && amount < 25))
            }
        }
        .navigationTitle(bar.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        .task(id: selectedPhoto) {
            guard let selectedPhoto else { return }
            loading = true
            photo = nil
            defer { loading = false }
            do {
                guard let data = try await selectedPhoto.loadTransferable(type: Data.self),
                      let image = UIImage(data: data),
                      let normalized = normalizedPhoto(image) else { throw RewardsError.invalidPhoto }
                try Task.checkCancellation()
                photo = normalized
            } catch {
                if !Task.isCancelled {
                    message = "Could not load this photo. Please choose another."
                    showingMessage = true
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraCapture { image in
                if let image { photo = normalizedPhoto(image) }
                showingCamera = false
            }
            .ignoresSafeArea()
        }
        .alert("Photo submission", isPresented: $showingMessage) { Button("OK", role: .cancel) {} } message: { Text(message) }
    }

    private func openCamera() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            message = "A camera is not available on this device. Choose a photo from your library."
            showingMessage = true
            return
        }
        let allowed = await AVCaptureDevice.requestAccess(for: .video)
        if allowed { showingCamera = true } else {
            message = "Allow camera access in Settings to take a picture, or choose one from Photos."
            showingMessage = true
        }
    }

    private func normalizedPhoto(_ image: UIImage) -> Data? {
        let longest = max(image.size.width, image.size.height)
        guard longest > 0 else { return nil }
        let scale = min(1, 1200 / longest)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }.jpegData(compressionQuality: 0.8)
    }
}

private struct CameraCapture: UIViewControllerRepresentable {
    let completion: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (UIImage?) -> Void
        init(completion: @escaping (UIImage?) -> Void) { self.completion = completion }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            completion(info[.originalImage] as? UIImage)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { completion(nil) }
    }
}
