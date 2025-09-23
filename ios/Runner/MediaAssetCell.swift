import UIKit
import Photos

// MARK: - Media Asset Cell
class MediaAssetCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    private let durationLabel = UILabel()
    private let selectionBadge = UIView()
    private let checkmarkImageView = UIImageView()
    
    private var asset: MediaAsset?
    private var imageRequestID: PHImageRequestID?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        durationLabel.text = ""
        selectionBadge.isHidden = false
        checkmarkImageView.isHidden = true
        
        // Remove any existing gradient layers
        selectionBadge.layer.sublayers?.forEach { layer in
            if layer is CAGradientLayer {
                layer.removeFromSuperlayer()
            }
        }
        
        // Cancel any pending image request
        if let requestID = imageRequestID {
            PHImageManager.default().cancelImageRequest(requestID)
            imageRequestID = nil
        }
    }
    
    private func setupUI() {
        // Image View
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        contentView.addSubview(imageView)
        
        // Duration Label (for videos)
        durationLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        durationLabel.textColor = .white
        durationLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        durationLabel.textAlignment = .center
        durationLabel.layer.cornerRadius = 4
        durationLabel.clipsToBounds = true
        contentView.addSubview(durationLabel)
        
        // Selection Badge - Always visible but with different styles
        selectionBadge.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        selectionBadge.layer.cornerRadius = 12
        selectionBadge.layer.borderWidth = 2
        selectionBadge.layer.borderColor = UIColor.white.cgColor
        selectionBadge.isHidden = false
        contentView.addSubview(selectionBadge)
        
        // Checkmark
        checkmarkImageView.image = UIImage(systemName: "checkmark")
        checkmarkImageView.tintColor = .white
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = true
        selectionBadge.addSubview(checkmarkImageView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        selectionBadge.translatesAutoresizingMaskIntoConstraints = false
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Image View
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Duration Label
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            durationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            durationLabel.heightAnchor.constraint(equalToConstant: 16),
            durationLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 30),
            
            // Selection Badge
            selectionBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            selectionBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            selectionBadge.widthAnchor.constraint(equalToConstant: 24),
            selectionBadge.heightAnchor.constraint(equalToConstant: 24),
            
            // Checkmark
            checkmarkImageView.centerXAnchor.constraint(equalTo: selectionBadge.centerXAnchor),
            checkmarkImageView.centerYAnchor.constraint(equalTo: selectionBadge.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 12),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
    
    func configure(with asset: MediaAsset, isSelected: Bool) {
        self.asset = asset
        
        // Show duration for videos
        if asset.isVideo {
            durationLabel.text = asset.formattedDuration
            durationLabel.isHidden = false
        } else {
            durationLabel.isHidden = true
        }
        
        // Update selection state
        updateSelectionState(isSelected: isSelected)
        
        // Load thumbnail
        loadThumbnail(for: asset)
    }
    
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Update gradient layer frame if it exists
        selectionBadge.layer.sublayers?.forEach { layer in
            if let gradientLayer = layer as? CAGradientLayer {
                gradientLayer.frame = selectionBadge.bounds
            }
        }
    }
    
    private func loadThumbnail(for asset: MediaAsset) {
        // Fetch the PHAsset using the local identifier
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
}
