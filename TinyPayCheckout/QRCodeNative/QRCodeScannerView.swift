
import SwiftUI
import AVFoundation

struct QRCodeScannerView: View {
    @Binding var scannedCode: String?
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            CameraPreview(scannedCode: $scannedCode, isPresented: $isPresented)
                .edgesIgnoringSafeArea(.all)

            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 240, height: 240)
                .background(Color.clear)
                .overlay(
                    Color.clear.blendMode(.destinationOut)
                )
            
            VStack {
                Text("Align QR code within the frame")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 40)
                Spacer()
                
                Button("Close") {
                    isPresented = false
                }
                .font(.title2)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .compositingGroup()
        .background(Color.black)
        .onAppear {
            // Clear old value when appearing again to avoid same QR code not triggering UI updates
            if scannedCode != nil { scannedCode = nil }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    @Binding var scannedCode: String?
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        context.coordinator.setupCaptureSession(in: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let previewLayer = uiView.layer.sublayers?.compactMap({ $0 as? AVCaptureVideoPreviewLayer }).first {
                previewLayer.frame = uiView.bounds
            }
        }
        // Restart session if it's not running when re-displayed
        if isPresented {
            context.coordinator.restartIfNeeded()
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.stopSession()
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: CameraPreview
        var captureSession: AVCaptureSession?

        init(_ parent: CameraPreview) {
            self.parent = parent
        }

        func setupCaptureSession(in view: UIView) {
            // Clean up old preview layers to prevent duplicate overlays
            view.layer.sublayers?.removeAll { $0 is AVCaptureVideoPreviewLayer }
            let session = AVCaptureSession()
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
                  let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }
            guard session.canAddInput(videoInput) else { return }
            session.addInput(videoInput)

            let metadataOutput = AVCaptureMetadataOutput()
            guard session.canAddOutput(metadataOutput) else { return }
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]

            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            DispatchQueue.main.async { previewLayer.frame = view.bounds }

            self.captureSession = session
            startSession()
        }

        func startSession() {
            guard let session = captureSession, !session.isRunning else { return }
            DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
        }

        func stopSession() {
            guard let session = captureSession, session.isRunning else { return }
            DispatchQueue.global(qos: .userInitiated).async { session.stopRunning() }
        }

        func restartIfNeeded() {
            guard let session = captureSession else { return }
            if !session.isRunning { startSession() }
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  metadataObject.type == .qr,
                  let stringValue = metadataObject.stringValue else { return }

            DispatchQueue.main.async {
                // Assign value and close popup, but don't stop immediately - handled in dismantleUIView or next rebuild
                self.parent.scannedCode = stringValue
                self.parent.isPresented = false
            }
        }
    }
}
