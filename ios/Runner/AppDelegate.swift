import Flutter
import UIKit
import Photos
import PhotosUI
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let galleryChannel = FlutterMethodChannel(name: "custom_photovideo_picker/gallery",
                                              binaryMessenger: controller.binaryMessenger)
    
    galleryChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      print("iOS: MethodChannel received call: \(call.method)")
      print("iOS: MethodChannel handler is working!")
      if call.method == "openGalleryPicker" {
        print("iOS: MethodChannel: openGalleryPicker method called!")
        print("iOS: MethodChannel: Creating gallery picker")
        
        // CRITICAL FIX: Create gallery picker directly in MethodChannel handler
        guard let rootViewController = self.window?.rootViewController else {
          print("iOS: MethodChannel: ERROR - No root view controller")
          result(FlutterError(code: "NO_ROOT_VC", message: "No root view controller", details: nil))
          return
        }
        
        let galleryPicker = GalleryPickerViewController()
        galleryPicker.delegate = GalleryPickerDelegateImpl(result: result)
        
        // Create navigation controller to enable pushing to PreviewViewController
        let navigationController = UINavigationController(rootViewController: galleryPicker)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .coverVertical
        
        print("iOS: MethodChannel: Presenting gallery picker with navigation controller")
        rootViewController.present(navigationController, animated: true)
        
      } else {
        print("iOS: Method not implemented: \(call.method)")
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

class GalleryPickerDelegateImpl: GalleryPickerDelegate {
  private let result: FlutterResult
  
  init(result: @escaping FlutterResult) {
    self.result = result
  }
  
  func galleryPickerDidFinish(selectedAssets: [MediaAsset]) {
    print("iOS: GalleryPickerDelegateImpl: Received \(selectedAssets.count) assets")
    
    // Convert MediaAsset objects to dictionaries for JSON serialization
    let assetDictionaries = selectedAssets.map { asset in
      print("iOS: GalleryPickerDelegateImpl Asset: id=\(asset.id), uri=\(asset.uri), mediaType=\(asset.mediaType), duration=\(asset.duration)")
      return [
        "id": asset.id,
        "uri": asset.uri,
        "mediaType": asset.mediaType,
        "duration": asset.duration
      ]
    }
    
    print("iOS: GalleryPickerDelegateImpl: Sending \(assetDictionaries.count) assets to Flutter")
    print("iOS: GalleryPickerDelegateImpl: Asset dictionaries: \(assetDictionaries)")
    result(assetDictionaries as [Any])
    print("iOS: GalleryPickerDelegateImpl: Result sent to Flutter")
  }
  
  func galleryPickerDidCancel() {
    result(FlutterError(code: "CANCELLED", message: "User cancelled gallery picker", details: nil))
  }
}
