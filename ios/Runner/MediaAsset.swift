import Foundation

// MARK: - MediaAsset Model
struct MediaAsset: Codable {
    let id: String
    let uri: String
    let mediaType: String   // "image" or "video"
    let duration: Int       // 5 sec for image, actual duration for video
    
    init(id: String, uri: String, mediaType: String, duration: Int) {
        self.id = id
        self.uri = uri
        self.mediaType = mediaType
        self.duration = duration
    }
}

extension MediaAsset {
    var isImage: Bool {
        return mediaType == "image"
    }
    
    var isVideo: Bool {
        return mediaType == "video"
    }
    
    var durationInSeconds: Int {
        return duration
    }
    
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
