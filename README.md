# MMBannerLayout

[![CI Status](http://img.shields.io/travis/millmanyang@gmail.com/MMBannerLayout.svg?style=flat)](https://travis-ci.org/millmanyang@gmail.com/MMBannerLayout)
[![Version](https://img.shields.io/cocoapods/v/MMBannerLayout.svg?style=flat)](http://cocoapods.org/pods/MMBannerLayout)
[![License](https://img.shields.io/cocoapods/l/MMBannerLayout.svg?style=flat)](http://cocoapods.org/pods/MMBannerLayout)
[![Platform](https://img.shields.io/cocoapods/p/MMBannerLayout.svg?style=flat)](http://cocoapods.org/pods/MMBannerLayout)

## Demo
![demo](https://github.com/MillmanY/MMBannerLayout/blob/master/demo.gif)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Use Banner
        if let layout = collection.collectionViewLayout as? MMBanerLayout {
            // Space every Item
            layout.itemSpace = 5.0
            // Size for banner cell
            layout.itemSize = self.collection.frame.insetBy(dx: 40, dy: 40).size
            // scroll to inifite
            layout.isInfinite = true
            // auto play
            layout.autoPlayBanner = true
            // angle need to be (0~90)
            layout.angle = 45
        }

## Installation

MMBannerLayout is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "MMBannerLayout"
```

## Author

millmanyang@gmail.com, millmanyang@gmail.com

## License

MMBannerLayout is available under the MIT license. See the LICENSE file for more info.
