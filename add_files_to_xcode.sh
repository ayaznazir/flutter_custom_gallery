#!/bin/bash

# Script to add separated Swift files to Xcode project
PROJECT_FILE="/Users/apple/StudioProjects/gitlab/custom_picker/ios/Runner.xcodeproj/project.pbxproj"

# Generate unique IDs for the new files
generate_id() {
    echo $(openssl rand -hex 12 | tr '[:lower:]' '[:upper:]')
}

# Generate IDs for all new files
MEDIA_ASSET_ID=$(generate_id)
GALLERY_DELEGATE_ID=$(generate_id)
MEDIA_CELL_ID=$(generate_id)
ALBUM_CELL_ID=$(generate_id)
PREVIEW_VC_ID=$(generate_id)
GALLERY_PICKER_ID=$(generate_id)

MEDIA_ASSET_BUILD_ID=$(generate_id)
GALLERY_DELEGATE_BUILD_ID=$(generate_id)
MEDIA_CELL_BUILD_ID=$(generate_id)
ALBUM_CELL_BUILD_ID=$(generate_id)
PREVIEW_VC_BUILD_ID=$(generate_id)
GALLERY_PICKER_BUILD_ID=$(generate_id)

echo "Generated IDs:"
echo "MediaAsset: $MEDIA_ASSET_ID"
echo "GalleryDelegate: $GALLERY_DELEGATE_ID"
echo "MediaCell: $MEDIA_CELL_ID"
echo "AlbumCell: $ALBUM_CELL_ID"
echo "PreviewVC: $PREVIEW_VC_ID"
echo "GalleryPicker: $GALLERY_PICKER_ID"

# Create backup
cp "$PROJECT_FILE" "$PROJECT_FILE.backup"

echo "Backup created. Now adding files to Xcode project..."

# This is a complex operation that requires careful editing of the project.pbxproj file
# For now, let's provide the manual steps
echo "Please follow these manual steps to add the files to Xcode:"
echo ""
echo "1. Open Xcode: open /Users/apple/StudioProjects/gitlab/custom_picker/ios/Runner.xcworkspace"
echo "2. In Xcode Project Navigator, right-click on 'Runner' folder"
echo "3. Select 'Add Files to Runner'"
echo "4. Navigate to: /Users/apple/StudioProjects/gitlab/custom_picker/ios/Runner/"
echo "5. Select these files:"
echo "   - MediaAsset.swift"
echo "   - GalleryPickerDelegate.swift"
echo "   - MediaAssetCell.swift"
echo "   - AlbumTableViewCell.swift"
echo "   - PreviewViewController.swift"
echo "   - GalleryPickerViewController.swift"
echo "6. Make sure 'Add to target: Runner' is checked"
echo "7. Click 'Add'"
echo "8. Build the project (Cmd+B)"
echo ""
echo "This will resolve the Swift compiler errors."
