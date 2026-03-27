import Cocoa

final class AsyncImageView: NSImageView {
    private static let cache = NSCache<NSURL, NSImage>()
    private var activeURL: NSURL?
    private var activeTask: URLSessionDataTask?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        imageScaling = .scaleProportionallyUpOrDown
        imageAlignment = .alignCenter
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func load(from url: URL?, placeholder: NSImage? = nil) {
        activeTask?.cancel()
        image = placeholder
        activeURL = url as NSURL?

        guard let url else { return }

        if let cached = Self.cache.object(forKey: url as NSURL) {
            image = cached
            return
        }

        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15)
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard
                let self,
                let data,
                let image = NSImage(data: data)
            else { return }

            Self.cache.setObject(image, forKey: url as NSURL)

            DispatchQueue.main.async {
                guard self.activeURL == url as NSURL else { return }
                self.image = image
            }
        }

        activeTask = task
        task.resume()
    }
}
