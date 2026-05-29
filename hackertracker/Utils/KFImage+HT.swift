//
//  KFImage+HT.swift
//  hackertracker
//
//  Phase 2: Kingfisher downsampling helper. Apply to large remote images
//  (speaker headshots, org logos, product media) to avoid decoding the
//  full-resolution bitmap into memory for thumbnails.
//

import SwiftUI
import Kingfisher

extension KFImage {
    /// Downsample the cached/remote image to the on-screen point size so
    /// scrolling speaker/org grids no longer pin full-res JPEGs in memory.
    ///
    /// - Parameter maxSize: Logical (point) size of the rendered image. The
    ///   processor scales to `maxSize * screen.scale` for retina fidelity.
    func htDownsampled(maxSize: CGSize) -> KFImage {
        let scale = UIScreen.main.scale
        let pixelSize = CGSize(width: maxSize.width * scale, height: maxSize.height * scale)
        return self
            .setProcessor(DownsamplingImageProcessor(size: pixelSize))
            .scaleFactor(scale)
            .cacheOriginalImage(false)
            .fade(duration: 0.15)
    }

    /// Convenience for square thumbnails.
    func htDownsampled(side: CGFloat) -> KFImage {
        htDownsampled(maxSize: CGSize(width: side, height: side))
    }
}
