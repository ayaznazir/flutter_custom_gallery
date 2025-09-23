import UIKit
import Photos
import AVFoundation

// MARK: - Gallery Picker View Controller
class GalleryPickerViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: GalleryPickerDelegate?
    private var selectedAssetIds: Set<String> = []
    private var mediaAssets: [MediaAsset] = []
    private var filteredAssets: [MediaAsset] = []
    private var currentAlbum: String = "All Photos"
    private var albums: [String] = []
    private var albumCollections: [PHAssetCollection] = []
    private var imageManager = PHCachingImageManager()
    
    // MARK: - UI Components
    private let navigationBar = UIView()
    private let cancelButton = UIButton(type: .system)
    private let albumTitleLabel = UILabel()
    private let doneButton = UIButton(type: .system)
    private let searchBar = UISearchBar()
    private let albumTriggerButton = UIButton(type: .system)
    private let albumDropdownView = UIView()
    private let albumTableView = UITableView()
    private let collectionView: UICollectionView
    private let durationLabel = UILabel()
    private let overlayView = UIView()
    
    private var isDropdownVisible = false
    private let dropdownHeight: CGFloat = 400
    
    // MARK: - Initialization
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
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
        requestPhotoLibraryPermission()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDoneButtonState()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update caching size when layout changes
        updateCachingSize()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        // Set up full screen appearance with dark theme
        view.backgroundColor = .black
        
        // Navigation Bar - iOS Photos app style
        navigationBar.backgroundColor = .black
        navigationBar.layer.shadowColor = UIColor.black.cgColor
        navigationBar.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        navigationBar.layer.shadowOpacity = 0.1
        navigationBar.layer.shadowRadius = 0
        view.addSubview(navigationBar)
        
        // Cancel Button - iOS style
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        navigationBar.addSubview(cancelButton)
        
        // Album Title Label - Text only in navigation bar center
        albumTitleLabel.text = "All Photos"
        albumTitleLabel.textColor = .white
        albumTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        albumTitleLabel.textAlignment = .center
        navigationBar.addSubview(albumTitleLabel)
        
        // Album Trigger Button - Below search bar with styling
        albumTriggerButton.setTitle("All Photos", for: .normal)
        albumTriggerButton.setTitleColor(.label, for: .normal)
        albumTriggerButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        albumTriggerButton.backgroundColor = UIColor.systemGray5
        albumTriggerButton.layer.cornerRadius = 10
        albumTriggerButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        albumTriggerButton.addTarget(self, action: #selector(albumButtonTapped), for: .touchUpInside)
        
        // Add chevron icon to trigger button
        let chevronImage = UIImage(systemName: "chevron.down")
        albumTriggerButton.setImage(chevronImage, for: .normal)
        albumTriggerButton.semanticContentAttribute = .forceRightToLeft
        albumTriggerButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        albumTriggerButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        albumTriggerButton.tintColor = .label
        view.addSubview(albumTriggerButton)
        
        // Done Button - iOS style
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        doneButton.isEnabled = false
        navigationBar.addSubview(doneButton)
        
        // Search Bar - iOS Photos app style
        searchBar.placeholder = "Search photos and videos"
        searchBar.delegate = self
        searchBar.backgroundColor = .systemGray6
        searchBar.searchBarStyle = .minimal
        searchBar.layer.cornerRadius = 10
        searchBar.clipsToBounds = true
        view.addSubview(searchBar)
        
        // Overlay View for dropdown
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.isHidden = true
        overlayView.alpha = 0
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        overlayView.addGestureRecognizer(tapGesture)
        view.addSubview(overlayView)
        
        // Album Dropdown - iOS Photos app style
        albumDropdownView.backgroundColor = UIColor.systemGray5
        albumDropdownView.layer.cornerRadius = 10
        albumDropdownView.layer.shadowColor = UIColor.black.cgColor
        albumDropdownView.layer.shadowOffset = CGSize(width: 0, height: 2)
        albumDropdownView.layer.shadowOpacity = 0.2
        albumDropdownView.layer.shadowRadius = 4
        albumDropdownView.isHidden = true
        albumDropdownView.alpha = 0
        view.addSubview(albumDropdownView)
        
        albumTableView.backgroundColor = .clear
        albumTableView.delegate = self
        albumTableView.dataSource = self
        albumTableView.register(AlbumTableViewCell.self, forCellReuseIdentifier: "AlbumCell")
        albumTableView.separatorStyle = .singleLine
        albumTableView.separatorColor = UIColor.systemGray4
        albumTableView.layer.cornerRadius = 10
        albumTableView.clipsToBounds = true
        albumTableView.rowHeight = 44
        albumDropdownView.addSubview(albumTableView)
        
        // Collection View - iOS Photos app style
        collectionView.backgroundColor = .black
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MediaAssetCell.self, forCellWithReuseIdentifier: "MediaAssetCell")
        collectionView.showsVerticalScrollIndicator = false
        view.addSubview(collectionView)
        
        // Duration Label - iOS Photos app style
        durationLabel.text = "Total Duration: 0:00"
        durationLabel.textColor = .white
        durationLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        durationLabel.textAlignment = .center
        durationLabel.backgroundColor = .black
        view.addSubview(durationLabel)
    }
    
    private func setupConstraints() {
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        albumTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        albumTriggerButton.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        albumDropdownView.translatesAutoresizingMaskIntoConstraints = false
        albumTableView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Navigation Bar
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationBar.heightAnchor.constraint(equalToConstant: 44),
            
            // Cancel Button
            cancelButton.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            
            // Album Title Label
            albumTitleLabel.centerXAnchor.constraint(equalTo: navigationBar.centerXAnchor),
            albumTitleLabel.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            
            // Done Button
            doneButton.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor, constant: -16),
            doneButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            
            // Search Bar
            searchBar.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.heightAnchor.constraint(equalToConstant: 36),
            
            // Album Trigger Button
            albumTriggerButton.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            albumTriggerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            albumTriggerButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Overlay View
            overlayView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Album Dropdown
            albumDropdownView.topAnchor.constraint(equalTo: albumTriggerButton.bottomAnchor, constant: 8),
            albumDropdownView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            albumDropdownView.widthAnchor.constraint(equalToConstant: 200),
            albumDropdownView.heightAnchor.constraint(equalToConstant: dropdownHeight),
            
            // Album Table View
            albumTableView.topAnchor.constraint(equalTo: albumDropdownView.topAnchor),
            albumTableView.leadingAnchor.constraint(equalTo: albumDropdownView.leadingAnchor),
            albumTableView.trailingAnchor.constraint(equalTo: albumDropdownView.trailingAnchor),
            albumTableView.bottomAnchor.constraint(equalTo: albumDropdownView.bottomAnchor),
            
            // Collection View
            collectionView.topAnchor.constraint(equalTo: albumTriggerButton.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: durationLabel.topAnchor, constant: -8),
            
            // Duration Label
            durationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            durationLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            durationLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    // MARK: - Actions
    @objc private func cancelButtonTapped() {
        dismiss(animated: true) {
            self.delegate?.galleryPickerDidCancel()
        }
    }
    
    @objc private func albumButtonTapped() {
        toggleDropdown()
    }
    
    @objc private func overlayTapped() {
        hideDropdown()
    }
    
    @objc private func doneButtonTapped() {
        print("iOS: Done button tapped!")
        print("iOS: Done button is enabled: \(doneButton.isEnabled)")
        print("iOS: selectedAssetIds count: \(selectedAssetIds.count)")
        print("iOS: selectedAssetIds: \(Array(selectedAssetIds))")
        
        let selectedAssets = mediaAssets.filter { selectedAssetIds.contains($0.id) }
        print("iOS: Selected assets count: \(selectedAssets.count)")
        
        if selectedAssets.isEmpty {
            print("iOS: ERROR - No assets selected!")
            return
        }
        
        // Calculate total duration for debugging
        let totalDuration = selectedAssets.reduce(0) { $0 + $1.duration }
        print("iOS: Total duration of selected assets: \(totalDuration) seconds")
        
        // Navigate to PreviewScreen with selected asset IDs
        print("iOS: Creating PreviewViewController with \(selectedAssetIds.count) asset IDs")
        let previewVC = PreviewViewController(selectedAssetIds: Array(selectedAssetIds))
        previewVC.completion = { [weak self] assetsWithURIs in
            print("iOS: GalleryPickerViewController received completion with \(assetsWithURIs.count) assets")
            print("iOS: GalleryPickerViewController delegate exists: \(self?.delegate != nil)")
            
            DispatchQueue.main.async {
                print("iOS: GalleryPickerViewController dismissing navigation controller")
                // CRITICAL FIX: Dismiss the navigation controller that contains this gallery picker
                self?.presentingViewController?.dismiss(animated: true) {
                    print("iOS: GalleryPickerViewController calling delegate with \(assetsWithURIs.count) assets")
                    self?.delegate?.galleryPickerDidFinish(selectedAssets: assetsWithURIs)
                    print("iOS: GalleryPickerViewController delegate called")
                }
            }
        }
        
        // Push to PreviewScreen
        print("iOS: Pushing PreviewViewController to navigation controller")
        navigationController?.pushViewController(previewVC, animated: true)
    }
    
    private func toggleDropdown() {
        if isDropdownVisible {
            hideDropdown()
        } else {
            showDropdown()
        }
    }
    
    private func showDropdown() {
        isDropdownVisible = true
        overlayView.isHidden = false
        albumDropdownView.isHidden = false
        
        // Bring dropdown to front
        view.bringSubviewToFront(overlayView)
        view.bringSubviewToFront(albumDropdownView)
        
        // Set initial transform for animation
        albumDropdownView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.overlayView.alpha = 1.0
            self.albumDropdownView.alpha = 1.0
            self.albumDropdownView.transform = CGAffineTransform.identity
        }
    }
    
    private func hideDropdown() {
        isDropdownVisible = false
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.overlayView.alpha = 0.0
            self.albumDropdownView.alpha = 0.0
            self.albumDropdownView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { _ in
            self.overlayView.isHidden = true
            self.albumDropdownView.isHidden = true
            self.albumDropdownView.transform = CGAffineTransform.identity
        }
    }
    
    // MARK: - Helper Methods
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self.loadAlbums()
                    self.loadMediaAssets()
                } else {
                    // Handle permission denied
                    self.delegate?.galleryPickerDidCancel()
                }
            }
        }
    }
    
    private func loadAlbums() {
        albums = ["All Photos"]
        albumCollections = []
        
        // Load smart albums
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        smartAlbums.enumerateObjects { collection, _, _ in
            if collection.assetCollectionSubtype == .smartAlbumUserLibrary ||
               collection.assetCollectionSubtype == .smartAlbumRecentlyAdded ||
               collection.assetCollectionSubtype == .smartAlbumFavorites ||
               collection.assetCollectionSubtype == .smartAlbumVideos ||
               collection.assetCollectionSubtype == .smartAlbumSelfPortraits ||
               collection.assetCollectionSubtype == .smartAlbumScreenshots {
                
                let fetchOptions = PHFetchOptions()
                fetchOptions.fetchLimit = 1
                let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                
                if assets.count > 0 {
                    self.albums.append(collection.localizedTitle ?? "Unknown")
                    self.albumCollections.append(collection)
                }
            }
        }
        
        // Load user albums
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        userAlbums.enumerateObjects { collection, _, _ in
            let fetchOptions = PHFetchOptions()
            fetchOptions.fetchLimit = 1
            let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            
            if assets.count > 0 {
                self.albums.append(collection.localizedTitle ?? "Unknown")
                self.albumCollections.append(collection)
            }
        }
        
        DispatchQueue.main.async {
            self.albumTableView.reloadData()
        }
    }
    
    private func loadMediaAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let allPhotos = PHAsset.fetchAssets(with: fetchOptions)
        var assets: [MediaAsset] = []
        
        allPhotos.enumerateObjects { asset, _, _ in
            let mediaAsset = MediaAsset(
                id: asset.localIdentifier,
                uri: "", // Will be filled when needed
                mediaType: asset.mediaType == .video ? "video" : "image",
                duration: asset.mediaType == .video ? Int(asset.duration) : 5
            )
            assets.append(mediaAsset)
        }
        
        self.mediaAssets = assets
        self.filteredAssets = assets
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.updateCachingSize()
        }
    }
    
    private func updateCachingSize() {
        let itemSize = CGSize(width: (collectionView.frame.width - 6) / 4, height: (collectionView.frame.width - 6) / 4)
        imageManager.stopCachingImagesForAllAssets()
        
        if !mediaAssets.isEmpty {
            let assets = mediaAssets.prefix(50).compactMap { asset in
                PHAsset.fetchAssets(withLocalIdentifiers: [asset.id], options: nil).firstObject
            }
            imageManager.startCachingImages(for: assets, targetSize: itemSize, contentMode: .aspectFill, options: nil)
        }
    }
    
    private func updateDoneButtonState() {
        let totalDuration = selectedAssetIds.compactMap { id in
            mediaAssets.first { $0.id == id }?.duration
        }.reduce(0, +)
        
        let isValidDuration = totalDuration >= 5 && totalDuration <= 1200 // 5 seconds to 20 minutes
        let hasSelection = !selectedAssetIds.isEmpty
        let shouldEnable = isValidDuration && hasSelection
        
        print("iOS: updateDoneButtonState - selectedAssetIds: \(Array(selectedAssetIds))")
        print("iOS: updateDoneButtonState - totalDuration: \(totalDuration) seconds")
        print("iOS: updateDoneButtonState - isValidDuration: \(isValidDuration)")
        print("iOS: updateDoneButtonState - hasSelection: \(hasSelection)")
        print("iOS: updateDoneButtonState - shouldEnable: \(shouldEnable)")
        
        doneButton.isEnabled = shouldEnable
        
        // Update duration label
        let minutes = totalDuration / 60
        let seconds = totalDuration % 60
        durationLabel.text = "Total Duration: \(String(format: "%d:%02d", minutes, seconds))"
        
        print("iOS: Done button enabled: \(doneButton.isEnabled)")
    }
    
    private func filterAssets(for searchText: String) {
        if searchText.isEmpty {
            filteredAssets = mediaAssets
        } else {
            // For now, just return all assets since we don't have metadata
            // In a real implementation, you'd search through asset metadata
            filteredAssets = mediaAssets
        }
        collectionView.reloadData()
    }
}

// MARK: - UISearchBarDelegate
extension GalleryPickerViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterAssets(for: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension GalleryPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlbumCell", for: indexPath) as! AlbumTableViewCell
        let albumName = albums[indexPath.row]
        cell.configure(with: albumName, isSelected: albumName == currentAlbum)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        currentAlbum = albums[indexPath.row]
        albumTitleLabel.text = currentAlbum
        albumTriggerButton.setTitle(currentAlbum, for: .normal)
        hideDropdown()
        
        // Load assets for selected album
        loadAssetsForAlbum(at: indexPath.row)
    }
    
    private func loadAssetsForAlbum(at index: Int) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        var assets: PHFetchResult<PHAsset>
        
        if index == 0 {
            // All Photos
            assets = PHAsset.fetchAssets(with: fetchOptions)
        } else {
            // Specific album
            let collectionIndex = index - 1
            if collectionIndex < albumCollections.count {
                assets = PHAsset.fetchAssets(in: albumCollections[collectionIndex], options: fetchOptions)
            } else {
                assets = PHAsset.fetchAssets(with: fetchOptions)
            }
        }
        
        var mediaAssets: [MediaAsset] = []
        assets.enumerateObjects { asset, _, _ in
            let mediaAsset = MediaAsset(
                id: asset.localIdentifier,
                uri: "",
                mediaType: asset.mediaType == .video ? "video" : "image",
                duration: asset.mediaType == .video ? Int(asset.duration) : 5
            )
            mediaAssets.append(mediaAsset)
        }
        
        self.mediaAssets = mediaAssets
        self.filteredAssets = mediaAssets
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.updateCachingSize()
        }
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension GalleryPickerViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaAssetCell", for: indexPath) as! MediaAssetCell
        let asset = filteredAssets[indexPath.item]
        cell.configure(with: asset, isSelected: selectedAssetIds.contains(asset.id))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = filteredAssets[indexPath.item]
        print("iOS: Item selected: \(asset.id), mediaType: \(asset.mediaType)")
        
        if selectedAssetIds.contains(asset.id) {
            selectedAssetIds.remove(asset.id)
            print("iOS: Removed from selection. Current count: \(selectedAssetIds.count)")
        } else {
            selectedAssetIds.insert(asset.id)
            print("iOS: Added to selection. Current count: \(selectedAssetIds.count)")
        }
        
        print("iOS: Selected asset IDs: \(Array(selectedAssetIds))")
        collectionView.reloadItems(at: [indexPath])
        updateDoneButtonState()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 2
        let numberOfColumns: CGFloat = 4
        let totalSpacing = (numberOfColumns - 1) * spacing
        let width = (collectionView.frame.width - totalSpacing) / numberOfColumns
        return CGSize(width: width, height: width)
    }
}
