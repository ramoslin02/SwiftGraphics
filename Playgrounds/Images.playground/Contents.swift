//: Playground - noun: a place where people can play

import Cocoa
import CoreGraphics

import SwiftGraphics

extension NSImage {
    var CGImage:Cocoa.CGImage? {
        return CGImageForProposedRect(nil, context:nil, hints:nil)
    }
}

extension CGImage {
    var size: CGSize {
        return CGSize(width:CGImageGetWidth(self), height:CGImageGetHeight(self))
    }

    var NSImage:Cocoa.NSImage! {
        return Cocoa.NSImage(CGImage: self, size: self.size)
    }
}

extension CGSize {
    func toRect() -> CGRect {
        return CGRect(size: self)
    }
}

extension CGImage {
    func resized(size:CGSize, keepAspectRatio:Bool = false) -> CGImage {
        let rect:CGRect
        if keepAspectRatio == true {
            rect = scaleAndAlignRectToRect(source: self.size.toRect(), destination: size.toRect(), scaling: .proportionally, alignment: .center)
        }
        else {
            rect = size.toRect()
        }

        let context = CGContext.bitmapContext(size)
        context.with() {
            CGContextDrawImage(context, rect, self)
        }
        return context.image
    }
}

extension CGImage {
    func cropped(rect:CGRect) -> CGImage {
        let context = CGContext.bitmapContext(rect.size)
        context.with() {
            CGContextDrawImage(context, rect, self)
        }
        return context.image
    }

    func cropped(size:CGSize, scaling: SwiftGraphics.Scaling = .none, alignment: SwiftGraphics.Alignment) -> CGImage {
        let rect = scaleAndAlignRectToRect(source: self.size.toRect(), destination: size.toRect(), scaling: scaling, alignment: alignment)
        let context = CGContext.bitmapContext(size)
        context.with() {
            CGContextDrawImage(context, rect, self)
        }
        return context.image
    }
}

extension CGImage {
    func clipped(path:CGPath) -> CGImage {
        let context = CGContext.bitmapContext(size)
        context.with() {
            CGContextAddPath(context, path)
            CGContextClip(context)
            CGContextDrawImage(context, CGRect(size:size), self)
        }
        return context.image
    }

    func clipped(pathable:CGPathable) -> CGImage {
        return clipped(pathable.cgpath)
    }
}

extension CGImage: Drawable {
    public func drawInContext(context: CGContextRef) {
        CGContextDrawImage(context, size.toRect(), self)
    }
}

extension CGImage {
    func composite(other:CGImage, blendMode:CGBlendMode? = nil, alpha:CGFloat = 1.0) -> CGImage {
        let context = CGContext.bitmapContext(size)
        context.with() {
            context.draw(self)
            if let blendMode = blendMode {
                context.blendMode = blendMode
            }
            context.alpha = alpha
            context.draw(other)
        }
        return context.image
    }
}

extension CGColor {
    func toImage(size:CGSize = CGSize(width:1, height:1)) -> CGImage {
        let context = CGContext.bitmapContext(size)
        context.with() {
            context.fillColor = self
            CGContextFillRect(context, size.toRect())
        }
        return context.image
    }
}

extension CGImage {
    static func with(size:CGSize, contextDraw:CGContext -> Void) -> CGImage {
        let context = CGContext.bitmapContext(size)
        context.with() {
            contextDraw(context)
        }
        return context.image
    }
    func with(size:CGSize? = nil, contextDraw:CGContext -> Void) -> CGImage {
        let size = size ?? self.size
        let context = CGContext.bitmapContext(size)
        context.with() {
            drawInContext(context)
            contextDraw(context)
        }
        return context.image
    }

}

enum Error: ErrorType {
    case noImages
}

func composite(imageables:[Imageable], blendMode:CGBlendMode? = nil, alpha:CGFloat = 1.0) -> CGImage {

    let images = imageables.map() { return $0.toImage() }


    guard let firstImage = images.first else {
        preconditionFailure()
    }

    let context = CGContext.bitmapContext(firstImage.size)
    context.with() {
        context.draw(firstImage)
        if let blendMode = blendMode {
            context.blendMode = blendMode
        }
        context.alpha = alpha
        for var image in images[1...(images.count - 1)] {
            if image === firstImage {
                continue
            }
            image = image.resized(firstImage.size)
            context.draw(image)
        }
    }
    return context.image
}

extension CGSize {
    var min:CGFloat {
        let result = Swift.min(width, height)
        return result
    }
}

protocol Imageable {
    func toImage() -> CGImage
}

extension CGColor: Imageable {
    func toImage() -> CGImage {
        return toImage(CGSize(w:1, h:1))
    }
}

extension CGImage: Imageable {
    func toImage() -> CGImage {
        return self
    }
}

extension Circle {
    func circleWithRadius(radius:CGFloat) -> Circle {
        return Circle(center: center, radius: radius)
    }

    func inset(delta:CGFloat) -> Circle {
        return circleWithRadius(radius + delta)
    }
}

var image = NSImage(named: "albert-einstein-tongue")!.CGImage!

image = image.cropped(CGSize(w:image.size.min, h:image.size.min), alignment:.center)

image = image.resized(CGSize(w:800, h:800), keepAspectRatio:true)

image = composite([image, CGColor.redColor()], blendMode:.Normal, alpha:0.15)

let r = image.size.min * 0.5
let circle = Circle(center: CGPoint(x:r, y:r), radius: r - 10)
image = image.clipped(circle.inset(-20))

image = image.with() {

    $0.lineWidth = 20
    $0.strokeColor = CGColor.blueColor().withAlpha(0.25)
    circle.drawInContext($0)
}


image.NSImage






