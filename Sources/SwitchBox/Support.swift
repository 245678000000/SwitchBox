import AppKit

// MARK: - 项目信息

enum AppInfo {
    static let repo = "245678000000/SwitchBox"
    static let homepage = URL(string: "https://github.com/\(repo)")!
    static let issues = URL(string: "https://github.com/\(repo)/issues/new")!
    static let releases = URL(string: "https://github.com/\(repo)/releases")!

    static var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0" }
    static var build: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1" }

    static func sendFeedback() {
        let body = """


        ---
        SwitchBox \(version) (\(build))
        macOS \(ProcessInfo.processInfo.operatingSystemVersionString)
        """
        var c = URLComponents(url: issues, resolvingAgainstBaseURL: false)!
        c.queryItems = [URLQueryItem(name: "body", value: body)]
        NSWorkspace.shared.open(c.url ?? issues)
    }
}

// MARK: - 检查更新（GitHub Releases）

enum UpdateResult: Equatable {
    case upToDate
    case available(version: String, url: URL)
    case failed(String)
}

enum Updater {
    static func check(completion: @escaping (UpdateResult) -> Void) {
        var req = URLRequest(url: URL(string: "https://api.github.com/repos/\(AppInfo.repo)/releases/latest")!)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 15
        URLSession.shared.dataTask(with: req) { data, resp, error in
            let result: UpdateResult
            if let error {
                result = .failed(error.localizedDescription)
            } else if (resp as? HTTPURLResponse)?.statusCode == 404 {
                result = .upToDate // 还没有发布任何版本
            } else if let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tag = json["tag_name"] as? String {
                let latest = tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                let url = (json["html_url"] as? String).flatMap(URL.init(string:)) ?? AppInfo.releases
                result = isNewer(latest, than: AppInfo.version) ? .available(version: latest, url: url) : .upToDate
            } else {
                result = .failed(String(localized: "无法解析服务器响应"))
            }
            DispatchQueue.main.async { completion(result) }
        }.resume()
    }

    static func isNewer(_ a: String, than b: String) -> Bool {
        let pa = a.split(separator: ".").map { Int($0) ?? 0 }
        let pb = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(pa.count, pb.count) {
            let x = i < pa.count ? pa[i] : 0, y = i < pb.count ? pb[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}

// MARK: - 界面语言

enum AppLanguage: String, CaseIterable, Identifiable {
    case system, en, fr, zhHans = "zh-Hans", zhHant = "zh-Hant"
    var id: String { rawValue }

    /// 用各自语言显示名称
    var displayName: String {
        switch self {
        case .system: String(localized: "跟随系统")
        case .en: "English"
        case .fr: "Français"
        case .zhHans: "简体中文"
        case .zhHant: "繁體中文"
        }
    }

    static var current: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: "appLanguage") ?? "") ?? .system
    }

    static func apply(_ lang: AppLanguage) {
        let d = UserDefaults.standard
        d.set(lang.rawValue, forKey: "appLanguage")
        if lang == .system { d.removeObject(forKey: "AppleLanguages") } else { d.set([lang.rawValue], forKey: "AppleLanguages") }
    }

    /// 重新启动应用以应用新语言
    static func relaunch() {
        let path = Bundle.main.bundlePath
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "sleep 0.6; /usr/bin/open \"\(path)\""]
        try? task.run()
        NSApp.terminate(nil)
    }
}
