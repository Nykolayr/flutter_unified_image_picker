import Flutter
import UIKit
import Photos

public class FlutterUnifiedImagePickerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "app.gallery/images", binaryMessenger: registrar.messenger())
        let instance = FlutterUnifiedImagePickerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getImages":
            requestGalleryAccess { granted in
                if granted {
                    self.fetchGalleryImages(result: result)
                } else {
                    result(FlutterError(code: "PERMISSION_DENIED", message: "Photo library access denied", details: nil))
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func requestGalleryAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 14, *) {
            // iOS 14+ uses new API with readWrite and limited access
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            switch status {
            case .authorized, .limited:
                completion(true)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            default:
                completion(false)
            }
        } else {
            // iOS 13 and below fallback
            let status = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .authorized:
                completion(true)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { newStatus in
                    completion(newStatus == .authorized)
                }
            default:
                completion(false)
            }
        }
    }

    private func fetchGalleryImages(result: @escaping FlutterResult) {
        var imagePaths: [String] = []
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        let dispatchGroup = DispatchGroup()

        assets.enumerateObjects { asset, _, _ in
            let resources = PHAssetResource.assetResources(for: asset)
            if let resource = resources.first {
                let filename = resource.originalFilename
                let tmpDir = NSTemporaryDirectory()
                let filePath = (tmpDir as NSString).appendingPathComponent(filename)
                let url = URL(fileURLWithPath: filePath)

                if !FileManager.default.fileExists(atPath: filePath) {
                    dispatchGroup.enter()
                    let options = PHAssetResourceRequestOptions()
                    options.isNetworkAccessAllowed = true
                    PHAssetResourceManager.default().writeData(for: resource, toFile: url, options: options) { error in
                        if error == nil {
                            imagePaths.append(filePath)
                        }
                        dispatchGroup.leave()
                    }
                } else {
                    imagePaths.append(filePath)
                }
            }
        }

        // Ensure result is called after async writes finish
        dispatchGroup.notify(queue: .main) {
            result(imagePaths)
        }
    }
}
