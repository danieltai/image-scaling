//
//  ContentView.swift
//  Gallery
//
//  Created by Daniel Tai on 27/2/2024.
//

import SwiftUI

struct ImageSize: Identifiable, Hashable {
  let width: Int
  let height: Int

  var id: String { "\(width) x \(height)" }
}

struct ContentView: View {
  static let imageSizes = [
    ImageSize(width: 622, height: 467),
    ImageSize(width: 930, height: 698),
    ImageSize(width: 939, height: 704),
    ImageSize(width: 1540, height: 1155),
  ]

  private let densityScale = UIScreen.main.scale
  private let iPhone12Size = CGSize(width: 390.0, height: 844.0)
  private let columns: [GridItem] = Array(
    repeating: .init(.flexible(), spacing: 1),
    count: 2
  )

  @State private var frame: CGRect = .zero
  @State private var requestedSize: ImageSize = Self.imageSizes[0]
  @State private var isPresented = false

  var imageURL: URL? {
    URL(string: "https://i2.au.reastatic.net/\(requestedSize.width)x\(requestedSize.height)-format=webp/496efb6b5497337d33442d05fcbe084d269449c76f326ca61e3fb552600f7854/image.jpg")
  }

  var body: some View {
    List {
      Section {
        image
          .captureFrame(frame: $frame)
          .onTapGesture {
            isPresented.toggle()
          }
          .sheet(isPresented: $isPresented) {
            image
          }
      }

      Section("Image view") {
        HStack {
          Text("Aspect ratio")
          Spacer()
          Text("4:3")
            .foregroundStyle(.secondary)
        }
        HStack {
          Text("Size in points")
          Spacer()
          Text(frame.size.description)
            .foregroundStyle(.secondary)
        }
        HStack {
          Text("Size in pixels")
          Spacer()
          Text(sizeInPixels().description)
            .foregroundStyle(.secondary)
        }
        Picker("Requested size", selection: $requestedSize) {
          ForEach(Self.imageSizes) {
            Text($0.id).tag($0)
          }
        }
      }

      Section("Screen") {
        HStack {
          Text("Scale")
          Spacer()
          Text(String(format: "%.1fx", densityScale))
            .foregroundStyle(.secondary)
        }
        HStack {
          Text("Size")
          Spacer()
          Text(UIScreen.main.bounds.size.description)
            .foregroundStyle(.secondary)
        }
      }

      Section("Relative to iPhone 12 (390.0 x 844.0)") {
        HStack {
          VStack(alignment: .leading) {
            Text("Relative scale")
            Text("By width")
              .foregroundStyle(.secondary)
          }
          Spacer()
          relativeScaleView
        }
        HStack {
          VStack(alignment: .leading) {
            Text("Adjusted scale")
            Text(String(format: "%.1fx", adjustmentFactor))
              .foregroundStyle(.secondary)
          }
          Spacer()
          adjustedScaleView
        }
        HStack {
          VStack(alignment: .leading) {
            Text("Rounded scale")
            Text("Nearest 0.5")
              .foregroundStyle(.secondary)
          }
          Spacer()
          roundedScaleView
        }
      }
    }
  }

  var image: some View {
    AsyncImage(url: imageURL) { image in
      image.resizable()
    } placeholder: {
      ProgressView()
    }
    .aspectRatio(4 / 3, contentMode: .fit)
    .border(.red)
  }

  private func sizeInPixels() -> CGSize {
    CGSize(width: frame.width * densityScale, height: frame.height * densityScale)
  }

  // Based on iPhone 12
  let referenceScreenSize = CGSize(width: 390.0, height: 844.0)
  let referenceImageSize = CGSize(width: 310.0, height: 232.5)

  let adjustmentFactor = 1.2

  var relativeScale: Double {
    let targetScreenSize = UIScreen.main.bounds.size
    // Account for screen orientation
    let targetScreenWidth = min(targetScreenSize.width, targetScreenSize.height)

    return targetScreenWidth / referenceScreenSize.width
  }

  var adjustedScale: Double { relativeScale * adjustmentFactor }
  var roundedScale: Double { adjustedScale.roundedToNearestHalf() }

  private var relativeScaleView: some View {
    let relativeScale = relativeScale
    let scaledSize = CGSize(
      width: referenceImageSize.width * densityScale * relativeScale,
      height: referenceImageSize.height * densityScale * relativeScale
    )

    return VStack(alignment: .trailing) {
      Text(String(format: "%.1fx", relativeScale))
      Text(scaledSize.description)
    }
    .foregroundStyle(.secondary)
  }

  private var adjustedScaleView: some View {
    let adjustedScale = adjustedScale
    let scaledSize = CGSize(
      width: referenceImageSize.width * densityScale * adjustedScale,
      height: referenceImageSize.height * densityScale * adjustedScale
    )

    return VStack(alignment: .trailing) {
      Text(String(format: "%.1fx", adjustedScale))
      Text(scaledSize.description)
    }
    .foregroundStyle(.secondary)
  }

  private var roundedScaleView: some View {
    let roundedScale = roundedScale
    let scaledSize = CGSize(
      width: referenceImageSize.width * densityScale * roundedScale,
      height: referenceImageSize.height * densityScale * roundedScale
    )

    return VStack(alignment: .trailing) {
      Text(String(format: "%.1fx", roundedScale))
      Text(scaledSize.description)
    }
    .foregroundStyle(.secondary)
  }
}

extension Double {
  func roundedToNearestHalf() -> Double {
    (self * 2).rounded() / 2
  }
}


extension CGSize {
  var description: String { "\(String(format: "%.1f", width)) x \(String(format: "%.1f", height))" }
}

struct Item: View {
  @Binding var frame: CGRect

  var body: some View {
    VStack {
      Text(frame.size.description)
        .foregroundStyle(.gray)
        .font(.title)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(UIColor.systemGray4))
    .aspectRatio(4 / 3, contentMode: .fit)
    .captureFrame(frame: $frame)
  }
}

#Preview {
  ContentView()
}

struct FrameCaptureModifier: ViewModifier {
  let coordinateSpace: CoordinateSpace
  @Binding var frame: CGRect

  init(coordinateSpace: CoordinateSpace, frame: Binding<CGRect>) {
    self.coordinateSpace = coordinateSpace
    self._frame = frame
  }

  func body(content: Content) -> some View {
    content
      .background(
        GeometryReader { geometry in
          Color.clear
            .onAppear {
              frame = geometry.frame(in: coordinateSpace)
            }
            .onChange(of: geometry.frame(in: coordinateSpace)) {
              frame = $0
            }
        }
      )
  }
}

extension View {
  public func captureFrame(
    coordinateSpace: CoordinateSpace = .global,
    frame: Binding<CGRect>
  ) -> some View {
    modifier(FrameCaptureModifier(
      coordinateSpace: coordinateSpace,
      frame: frame
    ))
  }
}
