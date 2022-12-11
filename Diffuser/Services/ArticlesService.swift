//
//  ArticlesService.swift
//  Diffuser
//
//  Created by Roman Mazeev on 03/12/2022.
//

import Foundation
import Dependencies
import XCTestDynamicOverlay

struct ArticlesService: Sendable {
    var getArticles: @Sendable () async throws -> ArticleResponse
}

// MARK: Live

extension ArticlesService: DependencyKey {
    static var liveValue: Self {
        let apiKey = "a6e0dcb957d94b1583760c5f84edd544"
        let url = URL(string: "https://newsapi.org/v2/top-headlines?country=us&apiKey=\(apiKey)")!

        lazy var decoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            return decoder
        }()

        lazy var dateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            return dateFormatter
        }()

        return Self(
            getArticles: { [decoder] in
                let (data, _) = try await URLSession.shared.data(from: url)
                return try decoder.decode(ArticleResponse.self, from: data)
            }
        )
    }
}

// MARK: - Dependency

extension DependencyValues {
    var articlesService: ArticlesService {
        get { self[ArticlesService.self] }
        set { self[ArticlesService.self] = newValue }
    }
}

#if DEBUG
extension ArticlesService: TestDependencyKey {
    static let testValue = Self(
        getArticles: unimplemented("\(Self.self).getArticles")
    )
}
#endif

// MARK: - Models

struct ArticleResponse: Equatable, Codable {
    let status: String
    let totalResults: Int
    let articles: [Article]
}

struct Article: Codable, Hashable {
    let source: Source
    let author, description, content: String?
    let title: String
    let url, urlToImage: URL?
    let publishedAt: Date

    func hash(into hasher: inout Hasher) {
        hasher.combine(source)
        hasher.combine(author)
        hasher.combine(title)
        hasher.combine(description)
        hasher.combine(content)
        hasher.combine(url)
        hasher.combine(urlToImage)
        hasher.combine(publishedAt)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        source = try container.decode(Source.self, forKey: .source)
        author = try container.decode(String?.self, forKey: .author)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String?.self, forKey: .description)
        content = try container.decode(String?.self, forKey: .content)
        url = try container.decode(URL.self, forKey: .url)

        let urlToImageFull = try container.decode(String?.self, forKey: .urlToImage)
        if let urlToImageFull {
            urlToImage = URL(string: urlToImageFull.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        } else {
            urlToImage = nil
        }

        let publishedAtString = try container.decode(String.self, forKey: .publishedAt)
        publishedAt = ISO8601DateFormatter().date(from: publishedAtString)!
    }

    init(source: Source,
         author: String,
         title: String,
         description: String,
         content: String,
         url: URL,
         urlToImage: URL,
         publishedAt: Date) {
        self.source = source
        self.author = author
        self.title = title
        self.description = description
        self.content = content
        self.url = url
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
    }
}

struct Source: Codable, Hashable {
    let id: String?
    let name: String
}

// MARK: Mock

#if DEBUG
extension Article {
    static var mocked: Self {
        .init(
            source: .init(id: "techcrunch", name: "TechCrunch"),
            author: "Taylor Hatmaker",
            title: "Elon Musk just brought an infamous neo-Nazi back to twitter",
            description: "Neo-Nazi Andrew Anglin re-appeared on the site, tweeting from a new handle associated with his account banned back in 2015.",
            content: "Ye might have crossed the line by tweeting a swastika superimposed with a Star of David, but you cant blame other Nazi apologists for getting mixed signals.\r\nOn Thursday night, Musk personally interv… [+3996 chars]",
            url: URL(string: "https://techcrunch.com/2022/12/02/elon-musk-nazis-kanye-twitter-andrew-anglin/")!,
            urlToImage: URL(string: "https://techcrunch.com/wp-content/uploads/2022/10/musk-buys-twitter-splash.jpg?resize=1200,675")!,
            publishedAt: .init()
        )
    }
}
#endif
