//
//  DiffusionService.swift
//  Diffuser
//
//  Created by Roman Mazeev on 03/12/2022.
//

import ComposableArchitecture
import XCTestDynamicOverlay
import StableDiffusion
import Foundation
import CoreImage

struct DiffusionService: Sendable {
    var startTask: @Sendable (String) -> AsyncThrowingStream<StableDiffusionPipeline.Progress, Error>
}

enum DiffusionServiceError: Equatable, LocalizedError, Sendable {
    case wrongModelsFolderURL
    case cantGenerateImage(onStep: Int)

    var errorDescription: String? {
        switch self {
        case .wrongModelsFolderURL:
            return "Wrong models folder URL"
        case .cantGenerateImage(let step):
            return "Can't generate image on step \(step)"
        }
    }
}

struct DiffusionResponse: Equatable {
    let progress: Double
    let image: CGImage?

    init(progress: Double, image: CGImage?) {
        self.progress = progress
        self.image = image
    }

    init(progress: StableDiffusionPipeline.Progress) {
        self.progress = Double(progress.step) / Double(progress.stepCount)
        image = progress.currentImages.compactMap { $0 }.first
    }
}

// MARK: - Live

extension DiffusionService: DependencyKey {
    static var liveValue: Self {
        lazy var pipeline: StableDiffusionPipeline = {
            do {
                let modelsURL = Bundle.main.url(forResource: "MLModels", withExtension: nil)!
                return try StableDiffusionPipeline(resourcesAt: modelsURL)
            } catch {
                fatalError(error.localizedDescription)
            }
        }()

        return Self(
            startTask: { [pipeline] text in
                pipeline.generateImages(prompt: text, seed: Int.random(in: 0..<100))
            }
        )
    }
}

// MARK: - Dependency

extension DependencyValues {
    var diffusionService: DiffusionService {
        get { self[DiffusionService.self] }
        set { self[DiffusionService.self] = newValue }
    }
}

#if DEBUG
extension DiffusionService: TestDependencyKey {
    static let testValue = Self(
        startTask: unimplemented("\(Self.self).startTask")
    )
}
#endif

extension AsyncStream {
    public func map<Transformed>(_ transform: @escaping (Self.Element) -> Transformed) -> AsyncStream<Transformed> {
        return AsyncStream<Transformed> { continuation in
            Task {
                for await element in self {
                    continuation.yield(transform(element))
                }
                continuation.finish()
            }
        }
    }

    public func map<Transformed>(_ transform: @escaping (Self.Element) async -> Transformed) -> AsyncStream<Transformed> {
        return AsyncStream<Transformed> { continuation in
            Task {
                for await element in self {
                    continuation.yield(await transform(element))
                }
                continuation.finish()
            }
        }
    }
}
