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
    private var currentFilter: String = "All Photos"
    private var albums: [String] = []
    private var albumCollections: [PHAssetCollection] = []
    private var imageManager = PHCachingImageManager()
    
    // MARK: - UI Components
    private let collectionView: UICollectionView
    
    // New UI Components for updated design
    private let searchButton = UIButton(type: .system)
    private let searchTextField = UITextField()
    private let searchContainerView = UIView()
    private let filterPageView = UIView()
    private let filterTableView = UITableView()
    private let overlayView = UIView()
    private let customFilterButton = UIButton(type: .system)
    
    private var isSearchActive = false
    private var isFilterPageVisible = false
    private var keyboardHeight: CGFloat = 0
    
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
        print("iOS: GalleryPickerViewController viewDidLoad called")
        setupUI()
        setupConstraints()
        requestPhotoLibraryPermission()
        
        // Debug initial state
        print("iOS: Initial searchButton.isHidden: \(searchButton.isHidden)")
        print("iOS: Initial searchTextField.isHidden: \(searchTextField.isHidden)")
        print("iOS: Initial searchContainerView.isHidden: \(searchContainerView.isHidden)")
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
        
        // Setup navigation bar with custom filter button
        setupNavigationBar()
        
        // Collection View - iOS Photos app style
        collectionView.backgroundColor = .black
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MediaAssetCell.self, forCellWithReuseIdentifier: "MediaAssetCell")
        collectionView.showsVerticalScrollIndicator = false
        view.addSubview(collectionView)
        
        // Search Button - Bottom of screen with exact specs
        searchButton.backgroundColor = UIColor(red: 0.26, green: 0.26, blue: 0.26, alpha: 1.0) // #424242
        searchButton.layer.cornerRadius = 25 // More complete radius
        searchButton.clipsToBounds = true
        
        // Add search icon and text with proper layout
        let searchIcon = UIImage(systemName: "magnifyingglass")
        let searchIconView = UIImageView(image: searchIcon)
        searchIconView.tintColor = .white
        searchIconView.contentMode = .scaleAspectFit
        
        let searchLabel = UILabel()
        searchLabel.text = "Search"
        searchLabel.textColor = .white
        searchLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        let stackView = UIStackView(arrangedSubviews: [searchIconView, searchLabel])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        
        searchButton.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchIconView.widthAnchor.constraint(equalToConstant: 18),
            searchIconView.heightAnchor.constraint(equalToConstant: 18),
            stackView.centerXAnchor.constraint(equalTo: searchButton.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: searchButton.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: searchButton.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: searchButton.trailingAnchor, constant: -20)
        ])
        
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        searchButton.isUserInteractionEnabled = true
        
        // Add tap gesture as backup
        let searchTapGesture = UITapGestureRecognizer(target: self, action: #selector(searchButtonTapped))
        searchButton.addGestureRecognizer(searchTapGesture)
        
        view.addSubview(searchButton)
        
        // Search Container View - Hidden by default
        searchContainerView.backgroundColor = .black
        searchContainerView.isHidden = true
        view.addSubview(searchContainerView)
        
        // Search Text Field - iOS Photos app style
        searchTextField.placeholder = "Search photos and videos"
        searchTextField.textColor = .white
        searchTextField.backgroundColor = UIColor(red: 0.26, green: 0.26, blue: 0.26, alpha: 1.0) // Same as search button
        searchTextField.layer.cornerRadius = 25 // Completely rounded (half of height)
        searchTextField.clipsToBounds = true
        searchTextField.borderStyle = .none
        searchTextField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        // Add padding to text field
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        searchTextField.leftView = leftPaddingView
        searchTextField.leftViewMode = .always
        
        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 50))
        searchTextField.rightView = rightPaddingView
        searchTextField.rightViewMode = .always
        
        // Set placeholder color
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search photos and videos",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.7)]
        )
        
        searchTextField.delegate = self
        searchTextField.returnKeyType = .search
        searchTextField.isHidden = true
        view.addSubview(searchTextField)
        
        // Filter Page View - Full UI page for filtering
        filterPageView.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.0) // #121212
        filterPageView.isHidden = true
        filterPageView.alpha = 0
        view.addSubview(filterPageView)
        
        // Filter Table View
        filterTableView.backgroundColor = .clear
        filterTableView.delegate = self
        filterTableView.dataSource = self
        filterTableView.register(FilterTableViewCell.self, forCellReuseIdentifier: "FilterCell")
        filterTableView.separatorStyle = .singleLine
        filterTableView.separatorColor = UIColor.systemGray4
        filterTableView.rowHeight = 80
        filterPageView.addSubview(filterTableView)
        
        // Overlay View for filter page and search
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlayView.isHidden = true
        overlayView.alpha = 0
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        overlayView.addGestureRecognizer(tapGesture)
        view.addSubview(overlayView)
        
        // Setup keyboard notifications
        setupKeyboardNotifications()
    }
    
    private func setupNavigationBar() {
        // Cancel Button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        // Done Button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = .white
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        // Custom Filter Button as titleView - Initialize with "All Photos"
        customFilterButton.setTitle("All Photos ▾", for: .normal)
        customFilterButton.setTitleColor(.white, for: .normal)
        customFilterButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        customFilterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        customFilterButton.sizeToFit()
        
        navigationItem.titleView = customFilterButton
        
        // Set navigation bar appearance
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.backgroundColor = .black
    }
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func setupConstraints() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchContainerView.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        filterPageView.translatesAutoresizingMaskIntoConstraints = false
        filterTableView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Collection View - Full screen minus search button
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: searchButton.topAnchor, constant: -16),
            
            // Search Button - Bottom of screen, compact and centered
            searchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            searchButton.heightAnchor.constraint(equalToConstant: 50),
            searchButton.widthAnchor.constraint(equalToConstant: 250),
            
            // Search Container View - Full screen when active
            searchContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            searchContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Search Text Field - Full width with 30px padding on sides
            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            searchTextField.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            searchTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Filter Page View - Full screen
            filterPageView.topAnchor.constraint(equalTo: view.topAnchor),
            filterPageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterPageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterPageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Filter Table View
            filterTableView.topAnchor.constraint(equalTo: filterPageView.safeAreaLayoutGuide.topAnchor, constant: 20),
            filterTableView.leadingAnchor.constraint(equalTo: filterPageView.leadingAnchor),
            filterTableView.trailingAnchor.constraint(equalTo: filterPageView.trailingAnchor),
            filterTableView.bottomAnchor.constraint(equalTo: filterPageView.bottomAnchor),
            
            // Overlay View - Full screen
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func cancelButtonTapped() {
        dismiss(animated: true) {
            self.delegate?.galleryPickerDidCancel()
        }
    }
    
    @objc private func filterButtonTapped() {
        showFilterPage()
    }
    
    @objc private func searchButtonTapped() {
        print("iOS: searchButtonTapped called")
        print("iOS: searchButton.isHidden before: \(searchButton.isHidden)")
        print("iOS: searchTextField.isHidden before: \(searchTextField.isHidden)")
        
        // Simple logic: hide search button, show text field
        searchButton.isHidden = true
        searchTextField.isHidden = false
        
        print("iOS: searchButton.isHidden after: \(searchButton.isHidden)")
        print("iOS: searchTextField.isHidden after: \(searchTextField.isHidden)")
        print("iOS: searchTextField.placeholder: \(searchTextField.placeholder ?? "nil")")
        print("iOS: searchTextField.leftView: \(searchTextField.leftView != nil)")
        print("iOS: searchTextField.rightView: \(searchTextField.rightView != nil)")
        
        // Make text field active
        searchTextField.becomeFirstResponder()
        
        print("iOS: Made searchTextField first responder")
    }
    
    @objc private func clearSearchTapped() {
        searchTextField.text = ""
        searchTextField.resignFirstResponder()
        searchTextField.isHidden = true
        searchButton.isHidden = false
        // Reset filtered assets to show all
        filteredAssets = mediaAssets
        collectionView.reloadData()
    }
    
    @objc private func overlayTapped() {
        if isFilterPageVisible {
            hideFilterPage()
        }
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        keyboardHeight = keyboardFrame.height
        
        // Simple keyboard handling - move search field up
        if !searchTextField.isHidden {
            UIView.animate(withDuration: 0.3) {
                self.searchTextField.transform = CGAffineTransform(translationX: 0, y: -self.keyboardHeight - 20)
            }
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        keyboardHeight = 0
        
        // Reset search field position
        if !searchTextField.isHidden {
            UIView.animate(withDuration: 0.3) {
                self.searchTextField.transform = .identity
            }
        }
    }
    
    @objc private func doneButtonTapped() {
        print("iOS: Done button tapped!")
        print("iOS: Done button is enabled: \(navigationItem.rightBarButtonItem?.isEnabled ?? false)")
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
    
    // MARK: - Filter Page Methods
    private func showFilterPage() {
        isFilterPageVisible = true
        overlayView.isHidden = false
        filterPageView.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.overlayView.alpha = 1
            self.filterPageView.alpha = 1
        }
    }
    
    private func hideFilterPage() {
        isFilterPageVisible = false
        
        UIView.animate(withDuration: 0.3) {
            self.overlayView.alpha = 0
            self.filterPageView.alpha = 0
        } completion: { _ in
            self.overlayView.isHidden = true
            self.filterPageView.isHidden = true
        }
    }
    
    // MARK: - Search Methods (Simplified)
    private func showSearchInterface() {
        // This method is no longer used - keeping for compatibility
        searchButtonTapped()
    }
    
    private func hideSearchInterface() {
        // This method is no longer used - keeping for compatibility
        searchTextField.resignFirstResponder()
        searchTextField.isHidden = true
        searchButton.isHidden = false
    }
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
                    let albumName = collection.localizedTitle ?? "Unknown"
                    self.albums.append(albumName)
                    self.albumCollections.append(collection)
                    print("iOS: Added album: '\(albumName)' with subtype: \(collection.assetCollectionSubtype.rawValue)")
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
            self.filterTableView.reloadData()
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
        
        if !filteredAssets.isEmpty {
            let assets = filteredAssets.prefix(50).compactMap { asset in
                PHAsset.fetchAssets(withLocalIdentifiers: [asset.id], options: nil).firstObject
            }
            imageManager.startCachingImages(for: assets, targetSize: itemSize, contentMode: .aspectFill, options: nil)
        }
    }
    
    private func updateDoneButtonState() {
        let totalDuration = selectedAssetIds.compactMap { id in
            filteredAssets.first { $0.id == id }?.duration
        }.reduce(0, +)
        
        let isValidDuration = totalDuration >= 5 && totalDuration <= 1200 // 5 seconds to 20 minutes
        let hasSelection = !selectedAssetIds.isEmpty
        let shouldEnable = isValidDuration && hasSelection
        
        print("iOS: updateDoneButtonState - selectedAssetIds: \(Array(selectedAssetIds))")
        print("iOS: updateDoneButtonState - totalDuration: \(totalDuration) seconds")
        print("iOS: updateDoneButtonState - isValidDuration: \(isValidDuration)")
        print("iOS: updateDoneButtonState - hasSelection: \(hasSelection)")
        print("iOS: updateDoneButtonState - shouldEnable: \(shouldEnable)")
        
        navigationItem.rightBarButtonItem?.isEnabled = shouldEnable
        
        print("iOS: Done button enabled: \(navigationItem.rightBarButtonItem?.isEnabled ?? false)")
    }
    
    private func filterAssets(for searchText: String) {
        if searchText.isEmpty {
            filteredAssets = mediaAssets
        } else {
            // Use enhanced search functionality
            filteredAssets = searchMediaAssets(searchText: searchText)
        }
        collectionView.reloadData()
    }
    
    // MARK: - Enhanced Search Functionality
    private func searchMediaAssets(searchText: String) -> [MediaAsset] {
        let searchQuery = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if searchQuery.isEmpty {
            return mediaAssets
        }
        
        // Filter by media type
        if searchQuery.contains("video") || searchQuery.contains("videos") {
            return mediaAssets.filter { $0.mediaType == "video" }
        } else if searchQuery.contains("photo") || searchQuery.contains("photos") || searchQuery.contains("image") || searchQuery.contains("images") {
            return mediaAssets.filter { $0.mediaType == "image" }
        }
        
        // For more advanced search, you would need to fetch PHAsset metadata
        return searchAssetsWithMetadata(searchText: searchQuery)
    }
    
    // MARK: - Advanced Search with PHAsset Metadata
    private func searchAssetsWithMetadata(searchText: String) -> [MediaAsset] {
        let searchQuery = searchText.lowercased()
        var filteredResults: [MediaAsset] = []
        
        // Get PHAssets for current media assets
        let assetIds = mediaAssets.map { $0.id }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetIds, options: nil)
        
        fetchResult.enumerateObjects { asset, index, _ in
            var shouldInclude = false
            
            // Search by creation date
            if let creationDate = asset.creationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                let dateString = formatter.string(from: creationDate).lowercased()
                if dateString.contains(searchQuery) {
                    shouldInclude = true
                }
                
                // Search by year, month
                formatter.dateFormat = "yyyy"
                if formatter.string(from: creationDate).contains(searchQuery) {
                    shouldInclude = true
                }
                
                formatter.dateFormat = "MMMM"
                if formatter.string(from: creationDate).lowercased().contains(searchQuery) {
                    shouldInclude = true
                }
            }
            
            // Search by duration for videos
            if asset.mediaType == .video {
                let duration = Int(asset.duration)
                let durationString = String(duration)
                if durationString.contains(searchQuery) {
                    shouldInclude = true
                }
            }
            
            // Search by media type
            let mediaTypeString = asset.mediaType == .video ? "video" : "image"
            if mediaTypeString.contains(searchQuery) {
                shouldInclude = true
            }
            
            if shouldInclude && index < self.mediaAssets.count {
                filteredResults.append(self.mediaAssets[index])
            }
        }
        
        return filteredResults
    }
    
    // MARK: - Search by Album Name
    private func searchInCurrentAlbum(searchText: String) {
        let searchQuery = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if searchQuery.isEmpty {
            filteredAssets = mediaAssets
            collectionView.reloadData()
            return
        }
        
        // Search within current album
        if currentAlbum.lowercased().contains(searchQuery) {
            // If searching for album name, show all assets in this album
            filteredAssets = mediaAssets
        } else {
            // Search within assets of current album
            filteredAssets = searchMediaAssets(searchText: searchText)
        }
        
        collectionView.reloadData()
    }
    
    // MARK: - Search State Management
    private func clearSearch() {
        searchTextField.text = ""
        filteredAssets = mediaAssets
        collectionView.reloadData()
    }
    
    // MARK: - Search Enhancements
    private func performAdvancedSearch(query: String) -> [MediaAsset] {
        let searchTerms = query.lowercased().components(separatedBy: " ").filter { !$0.isEmpty }
        
        return mediaAssets.filter { asset in
            // Check media type
            for term in searchTerms {
                if term == "video" && asset.mediaType == "video" { return true }
                if term == "photo" || term == "image" && asset.mediaType == "image" { return true }
                
                // Check duration ranges for videos
                if asset.mediaType == "video" {
                    if term == "short" && asset.duration < 30 { return true }
                    if term == "long" && asset.duration > 180 { return true }
                }
            }
            
            return false
        }
    }
    
    // Search suggestions
    private func getSearchSuggestions() -> [String] {
        return [
            "videos",
            "photos", 
            "images",
            "short videos",
            "long videos",
            "recent",
            "today",
            "yesterday",
            "this week",
            "this month"
        ]
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
        if tableView == filterTableView {
            return albums.count
        }
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == filterTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FilterCell", for: indexPath) as! FilterTableViewCell
            let albumName = albums[indexPath.row]
            let count = getAlbumCount(at: indexPath.row)
            let thumbnail = getAlbumThumbnail(at: indexPath.row)
            cell.configure(with: albumName, count: count, thumbnail: thumbnail, isSelected: albumName == currentAlbum)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AlbumCell", for: indexPath) as! AlbumTableViewCell
            let albumName = albums[indexPath.row]
            cell.configure(with: albumName, isSelected: albumName == currentAlbum)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        currentAlbum = albums[indexPath.row]
        currentFilter = albums[indexPath.row]
        
        print("iOS: tableView didSelectRowAt - Selected: \(currentFilter)")
        print("iOS: Current album: \(currentAlbum)")
        
        // Update filter button
        customFilterButton.setTitle("\(currentFilter) ▾", for: .normal)
        customFilterButton.sizeToFit()
        
        // Load assets for the selected filter
        loadAssets(for: currentFilter)
        
        // Hide filter page after selection
        if tableView == filterTableView {
            hideFilterPage()
        }
    }
    
    private func getAlbumCount(at index: Int) -> Int {
        let fetchOptions = PHFetchOptions()
        
        if index == 0 {
            // All Photos
            let assets = PHAsset.fetchAssets(with: fetchOptions)
            return assets.count
        } else {
            // Specific album
            let collectionIndex = index - 1
            if collectionIndex < albumCollections.count {
                let assets = PHAsset.fetchAssets(in: albumCollections[collectionIndex], options: fetchOptions)
                return assets.count
            }
        }
        return 0
    }
    
    private func getAlbumThumbnail(at index: Int) -> UIImage? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = 1
        
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
        
        guard let asset = assets.firstObject else { return nil }
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        
        var thumbnail: UIImage?
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 60, height: 60),
            contentMode: .aspectFill,
            options: requestOptions
        ) { image, _ in
            thumbnail = image
        }
        
        return thumbnail
    }
    
    private func loadAssets(for filter: String) {
        print("iOS: loadAssets called with filter: '\(filter)'")
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        var fetchResult: PHFetchResult<PHAsset>
        
        if filter == "All Photos" {
            print("iOS: Loading all photos")
            fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        } else if let index = albums.firstIndex(of: filter), index > 0 {
            // Album selected from albumCollections
            let collection = albumCollections[index - 1]
            print("iOS: Found album at index \(index), collection subtype: \(collection.assetCollectionSubtype.rawValue)")
            
            // Check if this is a video album by checking the collection subtype
            if collection.assetCollectionSubtype == .smartAlbumVideos {
                // For video albums, fetch only videos
                print("iOS: Loading videos only")
                fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
            } else {
                // For other albums, fetch from the specific collection
                print("iOS: Loading from specific collection")
                fetchResult = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            }
        } else {
            print("iOS: Filter not found, loading all photos")
            fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        }
        
        var assets: [MediaAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            let mediaAsset = MediaAsset(
                id: asset.localIdentifier,
                uri: "",
                mediaType: asset.mediaType == .video ? "video" : "image",
                duration: asset.mediaType == .video ? Int(asset.duration) : 5
            )
            assets.append(mediaAsset)
        }
        
        print("iOS: Loaded \(assets.count) assets")
        self.filteredAssets = assets
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.updateCachingSize()
        }
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

// MARK: - UITextFieldDelegate
extension GalleryPickerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == searchTextField {
            filterAssets(for: textField.text ?? "")
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == searchTextField {
            // Simple logic: when editing ends, hide text field and show search button
            textField.isHidden = true
            searchButton.isHidden = false
        }
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField == searchTextField {
            filterAssets(for: textField.text ?? "")
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == searchTextField {
            // Just allow text input - no right view to manage
            return true
        }
        return true
    }
}
