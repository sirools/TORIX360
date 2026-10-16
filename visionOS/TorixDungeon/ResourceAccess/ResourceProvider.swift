import Foundation

/// Accès découplé aux ressources (texte, audio, modèles…).
///
/// Le reste de l'app ne connaît que des chemins relatifs, par exemple
/// `Narration/narration.json` ou `Audio/phrase_01.m4a`. D'où viennent les octets
/// (bundle de l'app, NAS sur le réseau local, cache…) est l'affaire du provider.
///
/// Pour le NAS, reproduire la même arborescence derrière l'URL de base :
/// `http://nas.local:8080/torix/Narration/narration.json`, etc.
protocol ResourceProvider: Sendable {
    /// Nom lisible, pour les logs.
    var name: String { get }

    /// Renvoie le contenu brut de la ressource, ou lève `ResourceError`.
    func data(for path: String) async throws -> Data
}

enum ResourceError: LocalizedError {
    case notFound(path: String, provider: String)
    case badStatus(path: String, status: Int)

    var errorDescription: String? {
        switch self {
        case let .notFound(path, provider):
            "Ressource introuvable « \(path) » (\(provider))"
        case let .badStatus(path, status):
            "Réponse HTTP \(status) pour « \(path) »"
        }
    }
}

extension ResourceProvider {
    /// Décode un fichier JSON.
    func decode<T: Decodable>(_ type: T.Type, from path: String) async throws -> T {
        let data = try await data(for: path)
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Copie la ressource dans le cache disque et renvoie son URL locale.
    /// Utile pour les API qui exigent un fichier (ex. `Entity(contentsOf:)` pour un USDZ venu du NAS).
    func localFileURL(for path: String) async throws -> URL {
        let caches = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask,
                                                 appropriateFor: nil, create: true)
        let url = caches.appendingPathComponent("TorixResources", isDirectory: true)
            .appendingPathComponent(path)
        if FileManager.default.fileExists(atPath: url.path) { return url }
        let data = try await data(for: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
        return url
    }
}

// MARK: - Bundle local

/// Lit les ressources embarquées dans l'app.
///
/// Xcode « aplatit » les ressources dans le bundle : `Narration/narration.json` y devient
/// `narration.json`. On essaie donc d'abord le chemin complet, puis le simple nom de fichier.
struct BundleResourceProvider: ResourceProvider {
    var name: String { "bundle" }

    func data(for path: String) async throws -> Data {
        let nsPath = path as NSString
        let fileName = nsPath.lastPathComponent as NSString
        let base = fileName.deletingPathExtension
        let ext = fileName.pathExtension.isEmpty ? nil : fileName.pathExtension
        let directory = nsPath.deletingLastPathComponent

        let url = Bundle.main.url(forResource: base, withExtension: ext,
                                  subdirectory: directory.isEmpty ? nil : directory)
            ?? Bundle.main.url(forResource: base, withExtension: ext)

        guard let url else { throw ResourceError.notFound(path: path, provider: name) }
        return try Data(contentsOf: url)
    }
}

// MARK: - NAS / réseau local

/// Récupère les ressources en HTTP depuis une machine du réseau local (le futur NAS).
/// Timeout court : si le NAS ne répond pas, on bascule vite sur le bundle.
struct LocalNetworkResourceProvider: ResourceProvider {
    let baseURL: URL
    var timeout: TimeInterval = 3

    var name: String { "nas(\(baseURL.absoluteString))" }

    func data(for path: String) async throws -> Data {
        let url = baseURL.appendingPathComponent(path)
        let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData,
                                 timeoutInterval: timeout)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ResourceError.badStatus(path: path, status: http.statusCode)
        }
        return data
    }
}

// MARK: - Chaîne de repli

/// Essaie chaque provider dans l'ordre et renvoie le premier succès.
struct FallbackResourceProvider: ResourceProvider {
    let providers: [any ResourceProvider]

    init(_ providers: [any ResourceProvider]) {
        self.providers = providers
    }

    var name: String { providers.map { $0.name }.joined(separator: " → ") }

    func data(for path: String) async throws -> Data {
        var lastError: Error = ResourceError.notFound(path: path, provider: name)
        for provider in providers {
            do {
                return try await provider.data(for: path)
            } catch {
                lastError = error
            }
        }
        throw lastError
    }
}
