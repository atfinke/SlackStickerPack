//
//  ViewController.swift
//  SlackStickerPack
//
//  Created by Andrew Finke on 3/17/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit
import SlackEmojiKit
import MobileCoreServices
import UIKit

class ViewController: UIViewController {

      let emojiManager = SlackEmojiManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.blue

        let te = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        te.text = emojiManager.savedEmojis().description
        view.addSubview(te)

        let url = Bundle.main.url(forResource: "50096a1020", withExtension: "gif")!
        let image = CGImageSourceCreateWithURL(url as CFURL, nil)
        animatedImageWithSource(image!)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        emojiManager.fetchEmoji(from: self) { (result) in
            print(result)
        }
    }






    internal  func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1

        // Get dictionaries
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifPropertiesPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 0)
        if CFDictionaryGetValueIfPresent(cfProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque(), gifPropertiesPointer) == false {
            return delay
        }

        let gifProperties:CFDictionary = unsafeBitCast(gifPropertiesPointer.pointee, to: CFDictionary.self)

        // Get delay time
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                             Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }

        delay = delayObject as? Double ?? 0

        if delay < 0.1 {
            delay = 0.1 // Make sure they're not too fast
        }

        return delay
    }

    internal  func animatedImageWithSource(_ source: CGImageSource)  {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        let rul = urls.appendingPathComponent("imag.gif")


        let frameCount = CGImageSourceGetCount(source)
        guard let destination = CGImageDestinationCreateWithURL(rul as CFURL,
                                                                kUTTypeGIF,
                                                                frameCount, nil),
            let sourceProperties = CGImageSourceCopyProperties(source, nil) else {
            fatalError()
        }
        CGImageDestinationSetProperties(destination, sourceProperties)

        let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
        for imageIndex in 0..<frameCount {

            guard let frameImage = CGImageSourceCreateImageAtIndex(source, imageIndex, nil),
                let frameProperties = CGImageSourceCopyPropertiesAtIndex(source, imageIndex, nil) else {
                    continue
            }

            let newSize = CGSize(width: frameImage.width * 2, height: frameImage.height * 2)
            let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

            // Actually do the resizing to the rect using the ImageContext stuff
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            UIImage(cgImage: frameImage).draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            guard let image = newImage?.cgImage else {
                fatalError()
            }

            CGImageDestinationAddImage(destination, image, frameProperties)
        }
        guard CGImageDestinationFinalize(destination) else {
            fatalError()
        }
    }

}



//                guard let image = CIImage(cgImage: image) else {
//                    fatalError()
//                }
//
//                let filter = CIFilter(name: "CILanczosScaleTransform")!
//                filter.setValue(image, forKey: "inputImage")
//                filter.setValue(1.5, forKey: "inputScale")
//                filter.setValue(1.0, forKey: "inputAspectRatio")
//
//                guard let outputImage = filter.value(forKey: "outputImage") as? CIImage,
//                    let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) else {
//                        fatalError()
//                }
//
//                guard let data = CIContext(options: [kCIContextUseSoftwareRenderer: false])
//                    .pngRepresentation(of: outputImage,
//                                       format: kCIFormatRGBA8,
//                                       colorSpace:colorSpace,
//                                       options: [:]) else {
//                                        fatalError()
//                }
//                return data
