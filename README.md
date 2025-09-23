# Custom Photo/Video Picker - Swift Native Implementation

A professional custom gallery picker built with Swift native code, integrated with Flutter via MethodChannel. This implementation provides a native iOS Photos app-like experience with custom selection UI and gradient indicators.

## 📱 Features

- **Native iOS Photos App UI**: Dark theme with professional styling
- **Custom Selection Indicators**: Orange-to-red gradient at 45 degrees for selected items
- **Multiple Selection**: Support for selecting multiple photos/videos
- **Album Filtering**: Dynamic album dropdown with smart albums
- **Search Functionality**: Real-time search through media assets
- **Duration Validation**: 5 seconds minimum, 20 minutes maximum
- **Preview Screen**: Native preview with asset confirmation
- **Flutter Integration**: Seamless communication via MethodChannel

## 🏗️ Architecture Overview

### **File Structure**
```
ios/Runner/
├── AppDelegate.swift (85 lines) - MethodChannel & Flutter integration
├── MediaAsset.swift (33 lines) - Data model
├── GalleryPickerDelegate.swift (7 lines) - Protocol definition
├── MediaAssetCell.swift (192 lines) - Collection view cell with gradient
├── AlbumTableViewCell.swift (53 lines) - Album dropdown cell
├── PreviewViewController.swift (429 lines) - Preview screen
└── GalleryPickerViewController.swift (466 lines) - Main gallery picker
```

### **Architecture Pattern**
- **MVC (Model-View-Controller)**: Clean separation of concerns
- **Delegate Pattern**: Communication between components
- **MethodChannel**: Flutter ↔ Swift communication
- **Protocol-Oriented Programming**: Clean interfaces

## 🔧 Core Components

### **1. MediaAsset Model**
```swift
struct MediaAsset: Codable {
    let id: String           // PHAsset local identifier
    let uri: String          // Local file URI for Flutter
    let mediaType: String    // "image" or "video"
    let duration: Int        // 5 sec for image, actual for video
}
```

**Key Methods:**
- `isImage` / `isVideo`: Type checking
- `formattedDuration`: MM:SS format display
- `durationInSeconds`: Raw duration access

### **2. GalleryPickerViewController - Main Methods**

#### **Initialization & Setup**
```swift
init() {
    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = 2
    layout.minimumLineSpacing = 2
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    super.init(nibName: nil, bundle: nil)
}
```

#### **Photo Library Access**
```swift
private func requestPhotoLibraryPermission() {
    PHPhotoLibrary.requestAuthorization { status in
        DispatchQueue.main.async {
            if status == .authorized {
                self.loadAlbums()
                self.loadMediaAssets()
            } else {
                self.delegate?.galleryPickerDidCancel()
            }
        }
    }
}
```

#### **Asset Loading**
```swift
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
}
```

#### **Selection Validation**
```swift
private func updateDoneButtonState() {
    let totalDuration = selectedAssetIds.compactMap { id in
        mediaAssets.first { $0.id == id }?.duration
    }.reduce(0, +)
    
    let isValidDuration = totalDuration >= 5 && totalDuration <= 1200 // 5 seconds to 20 minutes
    let hasSelection = !selectedAssetIds.isEmpty
    let shouldEnable = isValidDuration && hasSelection
    
    doneButton.isEnabled = shouldEnable
    
    // Update duration label
    let minutes = totalDuration / 60
    let seconds = totalDuration % 60
    durationLabel.text = "Total Duration: \(String(format: "%d:%02d", minutes, seconds))"
}
```

### **3. MediaAssetCell - Custom Selection UI**

#### **Gradient Selection Implementation**
```swift
private func updateSelectionState(isSelected: Bool) {
    // Remove any existing gradient layers first
    selectionBadge.layer.sublayers?.forEach { layer in
        if layer is CAGradientLayer {
            layer.removeFromSuperlayer()
        }
    }
    
    if isSelected {
        // Selected state: Orange to red gradient at 45 degrees
        let newGradientLayer = CAGradientLayer()
        newGradientLayer.colors = [
            UIColor.systemOrange.cgColor,
            UIColor.systemRed.cgColor
        ]
        newGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        newGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        newGradientLayer.cornerRadius = 12
        
        // Force layout update to get proper bounds
        selectionBadge.setNeedsLayout()
        selectionBadge.layoutIfNeeded()
        newGradientLayer.frame = selectionBadge.bounds
        
        selectionBadge.layer.insertSublayer(newGradientLayer, at: 0)
        selectionBadge.backgroundColor = .clear
        selectionBadge.layer.borderColor = UIColor.white.cgColor
        checkmarkImageView.isHidden = false
        
        // Ensure gradient is properly displayed
        DispatchQueue.main.async {
            newGradientLayer.frame = self.selectionBadge.bounds
        }
    } else {
        // Unselected state: Semi-transparent white background
        selectionBadge.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        selectionBadge.layer.borderColor = UIColor.white.cgColor
        checkmarkImageView.isHidden = true
    }
}
```

#### **Thumbnail Loading**
```swift
private func loadThumbnail(for asset: MediaAsset) {
    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [asset.id], options: nil)
    
    guard let phAsset = fetchResult.firstObject else {
        return
    }
    
    let requestOptions = PHImageRequestOptions()
    requestOptions.isSynchronous = false
    requestOptions.deliveryMode = .opportunistic
    requestOptions.resizeMode = .exact
    
    let targetSize = CGSize(width: frame.width * UIScreen.main.scale, height: frame.height * UIScreen.main.scale)
    
    imageRequestID = PHCachingImageManager.default().requestImage(
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
```

## 🔄 Data Flow

### **1. Flutter → Swift**
```
Flutter calls openGalleryPicker() 
→ MethodChannel receives call
→ Creates GalleryPickerViewController
→ Presents with UINavigationController
```

### **2. User Interaction**
```
User selects assets
→ MediaAssetCell updates selection state
→ Gradient indicator appears
→ Done button enables/disables based on duration
```

### **3. Asset Processing**
```
User taps Done
→ Navigates to PreviewViewController
→ Generates local file URIs
→ Exports images/videos to temporary files
→ Returns MediaAsset array with file paths
```

### **4. Swift → Flutter**
```
PreviewViewController completion
→ GalleryPickerDelegateImpl processes assets
→ Converts to JSON dictionaries
→ Returns via MethodChannel
→ Flutter receives List<MediaAsset>
```

## 📱 Flutter Integration

### **MethodChannel Communication**
```dart
static const MethodChannel _channel = MethodChannel('custom_photovideo_picker/gallery');

static Future<List<MediaAsset>?> openGalleryPicker() async {
  try {
    final dynamic rawResult = await _channel.invokeMethod('openGalleryPicker');
    
    if (rawResult == null || rawResult is! List) {
      return null;
    }
    
    final List<dynamic> result = rawResult as List<dynamic>;
    final List<MediaAsset> assets = result.map((json) {
      return MediaAsset.fromJson(json as Map<String, dynamic>);
    }).toList();
    
    return assets;
  } on PlatformException catch (e) {
    if (e.code == 'CANCELLED') {
      return null; // User cancelled
    }
    rethrow;
  }
}
```

### **Data Model**
```dart
class MediaAsset {
  final String id;
  final String uri;
  final String mediaType;
  final int duration;

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: json['id'] as String,
      uri: json['uri'] as String,
      mediaType: json['mediaType'] as String,
      duration: json['duration'] as int,
    );
  }
}
```

## 🚀 Key Technical Features

### **Memory Management**
- **Weak References**: Prevents retain cycles
- **Request Cancellation**: Cancels pending image requests
- **Gradient Cleanup**: Removes old gradient layers
- **Cell Reuse**: Proper `prepareForReuse` implementation

### **Performance Optimization**
- **PHCachingImageManager**: Efficient thumbnail caching
- **Async Operations**: Non-blocking UI operations
- **DispatchGroup**: Coordinated async operations
- **Target Size Calculation**: Proper image sizing

### **Professional Standards**
- **MARK Comments**: Clear code organization
- **Proper Naming**: Swift conventions followed
- **Separation of Concerns**: Each class has single responsibility
- **Protocol Usage**: Clean interfaces and communication

## 🎯 Usage

### **From Flutter**
```dart
final selectedAssets = await GalleryPickerService.openGalleryPicker();
if (selectedAssets != null) {
  // Process selected assets
  for (final asset in selectedAssets) {
    print('Asset: ${asset.id}, URI: ${asset.uri}');
  }
}
```

### **Direct Swift Usage**
```swift
let galleryPicker = GalleryPickerViewController()
galleryPicker.delegate = yourDelegate
let navController = UINavigationController(rootViewController: galleryPicker)
present(navController, animated: true)
```

## 🏆 Benefits

- **Native Performance**: Full iOS Photos framework integration
- **Professional UI**: iOS Photos app-like experience
- **Custom Styling**: Orange-red gradient selection indicators
- **Memory Efficient**: Proper caching and cleanup
- **Flutter Compatible**: Seamless integration via MethodChannel
- **Maintainable Code**: Clean architecture and separation of concerns

This implementation provides a production-ready, professional custom gallery picker that maintains the native iOS experience while offering custom styling and Flutter integration.