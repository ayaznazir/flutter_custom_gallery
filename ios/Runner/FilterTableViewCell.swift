import UIKit
import Photos

// MARK: - Filter Table View Cell
class FilterTableViewCell: UITableViewCell {
    
    private let thumbnailImageView = UIImageView()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let checkmarkImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Thumbnail Image View
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.backgroundColor = .systemGray5
        contentView.addSubview(thumbnailImageView)
        
        // Title Label
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = .white
        contentView.addSubview(titleLabel)
        
        // Count Label
        countLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        countLabel.textColor = .systemGray2
        contentView.addSubview(countLabel)
        
        // Checkmark Image View
        checkmarkImageView.image = UIImage(systemName: "checkmark")
        checkmarkImageView.tintColor = .systemBlue
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = true
        contentView.addSubview(checkmarkImageView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Thumbnail Image View
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbnailImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 60),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Title Label
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            
            // Count Label
            countLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 16),
            countLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            // Checkmark Image View
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 20),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Content View Height
            contentView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func configure(with albumName: String, count: Int, thumbnail: UIImage?, isSelected: Bool) {
        titleLabel.text = albumName
        countLabel.text = "\(count) items"
        thumbnailImageView.image = thumbnail
        checkmarkImageView.isHidden = !isSelected
        
        print("iOS: FilterTableViewCell configure - \(albumName), count: \(count), isSelected: \(isSelected)")
    }
}
