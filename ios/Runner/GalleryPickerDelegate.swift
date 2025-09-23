import Foundation

// MARK: - Gallery Picker Delegate Protocol
protocol GalleryPickerDelegate: AnyObject {
    func galleryPickerDidFinish(selectedAssets: [MediaAsset])
    func galleryPickerDidCancel()
}
