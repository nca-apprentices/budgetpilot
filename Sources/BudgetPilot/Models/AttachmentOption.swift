enum AttachmentOption: CaseIterable {
    case camera, photos, scanReceipt, files

    var title: String {
        switch self {
        case .camera: "Camera"
        case .photos: "Photos"
        case .scanReceipt: "Scan receipt"
        case .files: "Files"
        }
    }

    var subtitle: String? {
        switch self {
        case .scanReceipt: "Detect amount automatically"
        default: nil
        }
    }

    var systemImage: String {
        switch self {
        case .camera: "camera"
        case .photos: "photo"
        case .scanReceipt: "doc.viewfinder"
        case .files: "folder"
        }
    }
}
