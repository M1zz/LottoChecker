import SwiftUI
import AVFoundation

struct QRCodeScannerView: View {
    @Binding var isPresented: Bool
    var onScanSuccess: ([Int]) -> Void

    var body: some View {
        ZStack {
            QRScanner(onScanSuccess: { code in
                if let numbers = parseLottoQRCode(code) {
                    onScanSuccess(numbers)
                    isPresented = false
                }
            })

            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(.top, 60)
                    .padding(.trailing, 20)
                }

                Spacer()

                VStack(spacing: 20) {
                    Text("로또 용지의 QR 코드를 스캔하세요")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)

                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.green, lineWidth: 3)
                        .frame(width: 250, height: 250)
                }

                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }

    private func parseLottoQRCode(_ code: String) -> [Int]? {
        AppLogger.info("QR 코드 파싱 시작", category: AppLogger.qr)
        AppLogger.debug("QR 코드 내용: \(code)", category: AppLogger.qr)

        // 동행복권 QR 코드 형식 파싱
        // 실제 QR 코드 형식: "v1.0,숫자,숫자,숫자,숫자,숫자,숫자..." 등
        // 예시: "v1.0,1,5,12,23,34,45" 형태로 가정

        let components = code.components(separatedBy: ",")

        // 최소한 7개 이상의 요소가 있어야 함 (버전 + 6개 번호)
        guard components.count >= 7 else {
            AppLogger.debug("표준 형식이 아님, 대체 파싱 시도", category: AppLogger.qr)
            // 다른 형식 시도: 공백이나 다른 구분자로 분리된 숫자들
            let numbers = code.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap { Int($0) }
                .filter { $0 >= 1 && $0 <= 45 }

            if numbers.count >= 6 {
                let result = Array(numbers.prefix(6)).sorted()
                AppLogger.info("QR 코드 파싱 성공 (대체 형식): \(result)", category: AppLogger.qr)
                return result
            }
            AppLogger.warning("QR 코드 파싱 실패: 유효한 번호 부족", category: AppLogger.qr)
            return nil
        }

        // 버전 정보 이후의 숫자들 추출
        let numbers = components.dropFirst()
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            .filter { $0 >= 1 && $0 <= 45 }

        guard numbers.count >= 6 else {
            AppLogger.warning("QR 코드 파싱 실패: 유효한 번호가 6개 미만", category: AppLogger.qr)
            return nil
        }

        // 첫 6개 번호만 사용하고 정렬
        let result = Array(numbers.prefix(6)).sorted()
        AppLogger.info("QR 코드 파싱 성공: \(result)", category: AppLogger.qr)
        return result
    }
}

struct QRScanner: UIViewControllerRepresentable {
    var onScanSuccess: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanSuccess: onScanSuccess)
    }

    class Coordinator: NSObject, QRScannerDelegate {
        var onScanSuccess: (String) -> Void

        init(onScanSuccess: @escaping (String) -> Void) {
            self.onScanSuccess = onScanSuccess
        }

        func didFindCode(_ code: String) {
            onScanSuccess(code)
        }
    }
}

protocol QRScannerDelegate: AnyObject {
    func didFindCode(_ code: String)
}

class QRScannerViewController: UIViewController {
    weak var delegate: QRScannerDelegate?

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        AppLogger.info("QR 스캐너 초기화 시작", category: AppLogger.qr)

        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            AppLogger.error("카메라 장치를 찾을 수 없음", category: AppLogger.qr)
            showAlert(message: "카메라를 사용할 수 없습니다.")
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            AppLogger.error("카메라 입력 설정 실패", error: error, category: AppLogger.qr)
            showAlert(message: "카메라 입력을 설정할 수 없습니다.")
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            AppLogger.debug("카메라 입력 추가 성공", category: AppLogger.qr)
        } else {
            AppLogger.error("카메라 입력 추가 실패", category: AppLogger.qr)
            showAlert(message: "카메라 입력을 추가할 수 없습니다.")
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
            AppLogger.debug("메타데이터 출력 설정 성공", category: AppLogger.qr)
        } else {
            AppLogger.error("메타데이터 출력 추가 실패", category: AppLogger.qr)
            showAlert(message: "메타데이터 출력을 추가할 수 없습니다.")
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            AppLogger.info("QR 스캐너 시작됨", category: AppLogger.qr)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
                AppLogger.debug("읽을 수 없는 메타데이터 객체", category: AppLogger.qr)
                return
            }
            guard let stringValue = readableObject.stringValue else {
                AppLogger.warning("QR 코드 문자열 값이 없음", category: AppLogger.qr)
                return
            }

            AppLogger.info("QR 코드 스캔 성공", category: AppLogger.qr)
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
                AppLogger.debug("QR 스캐너 중지됨", category: AppLogger.qr)
            }

            delegate?.didFindCode(stringValue)
        }
    }
}

#Preview {
    QRCodeScannerView(isPresented: .constant(true)) { numbers in
        print("Scanned numbers: \(numbers)")
    }
}
