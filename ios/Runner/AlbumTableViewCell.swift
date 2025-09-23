import UIKit

// MARK: - Album Table View Cell
class AlbumTableViewCell: UITableViewCell {
    
    private let titleLabel = UILabel()
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
        
        // Title Label
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        titleLabel.textColor = .label
        contentView.addSubview(titleLabel)
        
        // Checkmark Image View
        checkmarkImageView.image = UIImage(systemName: "checkmark")
        checkmarkImageView.tintColor = .systemBlue
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = true
        contentView.addSubview(checkmarkImageView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // Checkmark Image View
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 20),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Content View Height
            contentView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func configure(with albumName: String, isSelected: Bool) {
        titleLabel.text = albumName
        checkmarkImageView.isHidden = !isSelected
    }
}
