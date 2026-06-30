import Flutter
import UIKit
import PhotosUI
import UniformTypeIdentifiers

public class FlutterUnifiedImagePickerPlugin: NSObject, FlutterPlugin, PHPickerViewControllerDelegate {
    private var pendingResult: FlutterResult?
    private var allowMultiple = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "app.gallery/images",
            binaryMessenger: registrar.messenger()
        )
        let instance = FlutterUnifiedImagePickerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "pickImages":
            guard pendingResult == nil else {
                result(
                    FlutterError(
                        code: "ALREADY_ACTIVE",
                        message: "Image picker is already active.",
                        details: nil
                    )
                )
                return
            }
            let args = call.arguments as? [String: Any]
            allowMultiple = args?["allowMultiple"] as? Bool ?? false
            pendingResult = result
            presentPicker()
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func presentPicker() {
        DispatchQueue.main.async {
            guard let controller = self.topViewController() else {
                self.finishWithPaths([])
                return
            }
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.filter = .images
            config.selectionLimit = self.allowMultiple ? 0 : 1
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            controller.present(picker, animated: true)
        }
    }

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else {
            finishWithPaths([])
            return
        }
        let group = DispatchGroup()
        var paths: [String] = []
        let lock = NSLock()

        for item in results {
            let provider = item.itemProvider
            let type = UTType.image.identifier
            if provider.hasItemConformingToTypeIdentifier(type) {
                group.enter()
                provider.loadFileRepresentation(forTypeIdentifier: type) { url, _ in
                    defer { group.leave() }
                    guard let url = url else { return }
                    let tmp = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(url.pathExtension.isEmpty ? "jpg" : url.pathExtension)
                    do {
                        if FileManager.default.fileExists(atPath: tmp.path) {
                            try FileManager.default.removeItem(at: tmp)
                        }
                        try FileManager.default.copyItem(at: url, to: tmp)
                        lock.lock()
                        paths.append(tmp.path)
                        lock.unlock()
                    } catch {
                        // skip failed copy
                    }
                }
            }
        }

        group.notify(queue: .main) {
            self.finishWithPaths(paths)
        }
    }

    private func finishWithPaths(_ paths: [String]) {
        pendingResult?(paths)
        pendingResult = nil
    }

    private func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else {
            return nil
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
