import UIKit
import Photos
import AVFoundation

// MARK: - Preview View Controller
class PreviewViewController: UIViewController {
    
    // MARK: - Properties
    private var selectedAssetIds: [String]
    private var mediaAssets: [MediaAsset] = []
    private var currentIndex: Int = 0
    
    var completion: (([MediaAsset]) -> Void)?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let navigationBar = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let confirmButton = UIButton(type: .system)
    
    // MARK: - Initialization
    init(selectedAssetIds: [String]) {
        self.selectedAssetIds = selectedAssetIds
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        loadSelectedAssets()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation Bar
        navigationBar.backgroundColor = .systemBackground
        view.addSubview(navigationBar)
        
        // Back Button
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(.systemBlue, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        navigationBar.addSubview(backButton)
        
        // Title Label
        titleLabel.text = "Preview (\(selectedAssetIds.count) items)"
        titleLabel.textColor = .label
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textAlignment = .center
        navigationBar.addSubview(titleLabel)
        
        // Confirm Button
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.setTitleColor(.systemBlue, for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        navigationBar.addSubview(confirmButton)
        
        // Scroll View
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        
        // Stack View
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        scrollView.addSubview(stackView)
    }
    
    private func setupConstraints() {
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Navigation Bar
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationBar.heightAnchor.constraint(equalToConstant: 44),
            
            // Back Button
            backButton.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            
            // Title Label
            titleLabel.centerXAnchor.constraint(equalTo: navigationBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            
            // Confirm Button
            confirmButton.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor, constant: -16),
            confirmButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Stack View
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func confirmButtonTapped() {
        print("iOS: PreviewScreen confirm button tapped!")
        print("iOS: PreviewScreen completion handler exists: \(completion != nil)")
        
        // Generate URIs for the assets
        generateURIsForAssets { [weak self] assetsWithURIs in
            print("iOS: PreviewScreen generateURIsForAssets completed with \(assetsWithURIs.count) assets")
            DispatchQueue.main.async {
                print("iOS: PreviewScreen calling completion handler")
                self?.completion?(assetsWithURIs)
                print("iOS: PreviewScreen completion handler called")
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadSelectedAssets() {
        let fetchOptions = PHFetchOptions()
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: selectedAssetIds, options: fetchOptions)
        
        var assets: [MediaAsset] = []
        
        fetchResult.enumerateObjects { asset, _, _ in
            let mediaAsset = MediaAsset(
                id: asset.localIdentifier,
                uri: "", // Will be filled when needed
                mediaType: asset.mediaType == .video ? "video" : "image",
                duration: asset.mediaType == .video ? Int(asset.duration) : 5
            )
            assets.append(mediaAsset)
        }
        
        self.mediaAssets = assets
        createPreviewItems()
    }
    
    private func createPreviewItems() {
        for (index, asset) in mediaAssets.enumerated() {
            let previewItem = PreviewItemView()
            previewItem.configure(with: asset, index: index + 1, total: mediaAssets.count)
            stackView.addArrangedSubview(previewItem)
        }
    }
    
    private func generateURIsForAssets(completion: @escaping ([MediaAsset]) -> Void) {
        print("iOS: PreviewViewController generateURIsForAssets called with \(selectedAssetIds.count) assets")
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: selectedAssetIds, options: nil)
        print("iOS: PreviewViewController fetched \(fetchResult.count) PHAssets")
        var assetsWithURIs: [MediaAsset] = []
        let dispatchGroup = DispatchGroup()
        
        fetchResult.enumerateObjects { asset, _, _ in
            dispatchGroup.enter()
            
            if asset.mediaType == .image {
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = false
                requestOptions.deliveryMode = .highQualityFormat
                requestOptions.isNetworkAccessAllowed = true // Enable network access for iCloud photos
                
                PHImageManager.default().requestImageDataAndOrientation(for: asset, options: requestOptions) { data, dataUTI, orientation, info in
                    // Check for errors in info dictionary
                    if let error = info?[PHImageErrorKey] as? Error {
                        print("iOS: PreviewViewController image request error: \(error)")
                    }
                    
                    if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                        print("iOS: PreviewViewController image request was cancelled")
                    }
                    
                    if let isInCloud = info?[PHImageResultIsInCloudKey] as? Bool, isInCloud {
                        print("iOS: PreviewViewController image is in iCloud, may need time to download")
                    }
                    
                    if let imageData = data {
                        // Get proper file extension based on UTI
                        let fileExtension = self.getFileExtension(for: dataUTI) ?? "jpg"
                        let fileName = "\(asset.localIdentifier.replacingOccurrences(of: "/", with: "_")).\(fileExtension)"
                        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
                        
                        // Remove existing file if it exists
                        try? FileManager.default.removeItem(at: fileURL)
                        
                        do {
                            try imageData.write(to: fileURL)
                            print("iOS: PreviewViewController successfully wrote image to: \(fileURL.path)")
                            
                            // Verify file was written and has content
                            if FileManager.default.fileExists(atPath: fileURL.path) {
                                let fileSize = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? 0
                                print("iOS: PreviewViewController image file size: \(fileSize) bytes")
                                
                                if fileSize > 0 {
                                    let mediaAsset = MediaAsset(
                                        id: asset.localIdentifier,
                                        uri: fileURL.path,
                                        mediaType: "image",
                                        duration: 5
                                    )
                                    assetsWithURIs.append(mediaAsset)
                                    print("iOS: PreviewViewController successfully created MediaAsset for image: \(asset.localIdentifier)")
                                } else {
                                    print("iOS: PreviewViewController ERROR: Image file is empty at \(fileURL.path)")
                                    let mediaAsset = MediaAsset(
                                        id: asset.localIdentifier,
                                        uri: "",
                                        mediaType: "image",
                                        duration: 5
                                    )
                                    assetsWithURIs.append(mediaAsset)
                                }
                            } else {
                                print("iOS: PreviewViewController ERROR: Image file was not created at \(fileURL.path)")
                                let mediaAsset = MediaAsset(
                                    id: asset.localIdentifier,
                                    uri: "",
                                    mediaType: "image",
                                    duration: 5
                                )
                                assetsWithURIs.append(mediaAsset)
                            }
                        } catch {
                            print("iOS: PreviewViewController error writing image file: \(error)")
                            let mediaAsset = MediaAsset(
                                id: asset.localIdentifier,
                                uri: "",
                                mediaType: "image",
                                duration: 5
                            )
                            assetsWithURIs.append(mediaAsset)
                        }
                    } else {
                        print("iOS: PreviewViewController no image data available for asset: \(asset.localIdentifier)")
                        let mediaAsset = MediaAsset(
                            id: asset.localIdentifier,
                            uri: "",
                            mediaType: "image",
                            duration: 5
                        )
                        assetsWithURIs.append(mediaAsset)
                    }
                    dispatchGroup.leave()
                }
            } else if asset.mediaType == .video {
                let requestOptions = PHVideoRequestOptions()
                requestOptions.isNetworkAccessAllowed = true // Enable network access for iCloud videos
                
                PHImageManager.default().requestAVAsset(forVideo: asset, options: requestOptions) { avAsset, _, info in
                    // Check for errors in info dictionary
                    if let error = info?[PHImageErrorKey] as? Error {
                        print("iOS: PreviewViewController video request error: \(error)")
                    }
                    
                    if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                        print("iOS: PreviewViewController video request was cancelled")
                    }
                    
                    if let isInCloud = info?[PHImageResultIsInCloudKey] as? Bool, isInCloud {
                        print("iOS: PreviewViewController video is in iCloud, may need time to download")
                    }
                    
                    if let urlAsset = avAsset as? AVURLAsset {
                        // Check if it's already a local file
                        if urlAsset.url.isFileURL {
                            // Verify the file exists and has content
                            if FileManager.default.fileExists(atPath: urlAsset.url.path) {
                                let fileSize = (try? FileManager.default.attributesOfItem(atPath: urlAsset.url.path)[.size] as? Int64) ?? 0
                                print("iOS: PreviewViewController video file size: \(fileSize) bytes")
                                
                                if fileSize > 0 {
                                    let mediaAsset = MediaAsset(
                                        id: asset.localIdentifier,
                                        uri: urlAsset.url.path,
                                        mediaType: "video",
                                        duration: Int(asset.duration)
                                    )
                                    assetsWithURIs.append(mediaAsset)
                                    print("iOS: PreviewViewController successfully created MediaAsset for local video: \(asset.localIdentifier)")
                                } else {
                                    print("iOS: PreviewViewController ERROR: Video file is empty at \(urlAsset.url.path)")
                                    let mediaAsset = MediaAsset(
                                        id: asset.localIdentifier,
                                        uri: "",
                                        mediaType: "video",
                                        duration: Int(asset.duration)
                                    )
                                    assetsWithURIs.append(mediaAsset)
                                }
                            } else {
                                print("iOS: PreviewViewController ERROR: Video file does not exist at \(urlAsset.url.path)")
                                let mediaAsset = MediaAsset(
                                    id: asset.localIdentifier,
                                    uri: "",
                                    mediaType: "video",
                                    duration: Int(asset.duration)
                                )
                                assetsWithURIs.append(mediaAsset)
                            }
                        } else {
                            // Export video to temporary file
                            self.exportVideoToTemporaryFile(asset: asset, urlAsset: urlAsset) { exportedURL in
                                if let url = exportedURL, FileManager.default.fileExists(atPath: url.path) {
                                    let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
                                    print("iOS: PreviewViewController exported video file size: \(fileSize) bytes")
                                    
                                    if fileSize > 0 {
                                        let mediaAsset = MediaAsset(
                                            id: asset.localIdentifier,
                                            uri: url.path,
                                            mediaType: "video",
                                            duration: Int(asset.duration)
                                        )
                                        assetsWithURIs.append(mediaAsset)
                                        print("iOS: PreviewViewController successfully created MediaAsset for exported video: \(asset.localIdentifier)")
                                    } else {
                                        print("iOS: PreviewViewController ERROR: Exported video file is empty")
                                        let mediaAsset = MediaAsset(
                                            id: asset.localIdentifier,
                                            uri: "",
                                            mediaType: "video",
                                            duration: Int(asset.duration)
                                        )
                                        assetsWithURIs.append(mediaAsset)
                                    }
                                } else {
                                    print("iOS: PreviewViewController ERROR: Video export failed")
                                    let mediaAsset = MediaAsset(
                                        id: asset.localIdentifier,
                                        uri: "",
                                        mediaType: "video",
                                        duration: Int(asset.duration)
                                    )
                                    assetsWithURIs.append(mediaAsset)
                                }
                                dispatchGroup.leave()
                            }
                            return // Don't call leave() here, it's called in the completion
                        }
                    } else {
                        print("iOS: PreviewViewController no video asset available for: \(asset.localIdentifier)")
                        let mediaAsset = MediaAsset(
                            id: asset.localIdentifier,
                            uri: "",
                            mediaType: "video",
                            duration: Int(asset.duration)
                        )
                        assetsWithURIs.append(mediaAsset)
                    }
                    dispatchGroup.leave()
                }
            } else {
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("iOS: PreviewViewController generateURIsForAssets completed with \(assetsWithURIs.count) assets")
            
            // Maintain original order and log all generated URIs for debugging
            let orderedAssets = assetsWithURIs.sorted { first, second in
                guard let firstIndex = self.selectedAssetIds.firstIndex(where: { $0 == first.id }),
                      let secondIndex = self.selectedAssetIds.firstIndex(where: { $0 == second.id }) else {
                    return false
                }
                return firstIndex < secondIndex
            }
            
            for (index, asset) in orderedAssets.enumerated() {
                print("iOS: PreviewViewController Asset \(index): id=\(asset.id), uri=\(asset.uri), mediaType=\(asset.mediaType), duration=\(asset.duration)")
            }
            
            completion(orderedAssets)
        }
    }
    
    // Helper function to get file extension based on UTI (same as in GalleryPickerViewController)
    private func getFileExtension(for uti: String?) -> String? {
        guard let uti = uti else { return "jpg" }
        
        switch uti {
        case "public.jpeg":
            return "jpg"
        case "public.png":
            return "png"
        case "public.heic":
            return "heic"
        case "public.heif":
            return "heif"
        case "com.compuserve.gif":
            return "gif"
        default:
            return "jpg" // Default fallback
        }
    }
    
    private func exportVideoToTemporaryFile(asset: PHAsset, urlAsset: AVURLAsset, completion: @escaping (URL?) -> Void) {
        let fileName = "\(asset.localIdentifier.replacingOccurrences(of: "/", with: "_")).mp4"
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        // Remove existing file if it exists
        try? FileManager.default.removeItem(at: outputURL)
        
        let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = .mp4
        
        exportSession?.exportAsynchronously {
            DispatchQueue.main.async {
                if exportSession?.status == .completed {
                    completion(outputURL)
                } else {
                    print("iOS: PreviewViewController video export failed: \(exportSession?.error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                }
            }
        }
    }
}

// MARK: - Preview Item View
class PreviewItemView: UIView {
    
    private let imageView = UIImageView()
    private let infoLabel = UILabel()
    private let durationLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 12
        layer.masksToBounds = true
        
        // Image View
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        addSubview(imageView)
        
        // Info Label
        infoLabel.textColor = .label
        infoLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        addSubview(infoLabel)
        
        // Duration Label
        durationLabel.textColor = .secondaryLabel
        durationLabel.font = UIFont.systemFont(ofSize: 14)
        addSubview(durationLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Image View
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12),
            
            // Info Label
            infoLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            infoLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            // Duration Label
            durationLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 4),
            durationLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            durationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            durationLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with asset: MediaAsset, index: Int, total: Int) {
        infoLabel.text = "\(asset.mediaType.capitalized) \(index) of \(total)"
        durationLabel.text = "Duration: \(asset.formattedDuration)"
        
        // Load thumbnail
        loadThumbnail(for: asset)
    }
    
    private func loadThumbnail(for asset: MediaAsset) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [asset.id], options: nil)
        
        guard let phAsset = fetchResult.firstObject else {
            return
        }
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .opportunistic
        requestOptions.resizeMode = .exact
        
        let targetSize = CGSize(width: 80 * UIScreen.main.scale, height: 80 * UIScreen.main.scale)
        
        PHImageManager.default().requestImage(
            for: phAsset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: requestOptions
        ) { [weak self] image, _ in
            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }
    }
}
