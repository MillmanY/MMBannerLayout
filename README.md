# MMBannerLayout

[![CI Status](http://img.shields.io/travis/millmanyang@gmail.com/MMBannerLayout.svg?style=flat)](https://travis-ci.org/millmanyang@gmail.com/MMBannerLayout)
[![Version](https://img.shields.io/cocoapods/v/MMBannerLayout.svg?style=flat)](http://cocoapods.org/pods/MMBannerLayout)
[![License](https://img.shields.io/cocoapods/l/MMBannerLayout.svg?style=flat)](http://cocoapods.org/pods/MMBannerLayout)
[![Platform](https://img.shields.io/cocoapods/p/MMBannerLayout.svg?style=flat)](http://cocoapods.org/pods/MMBannerLayout)

## Demo
![demo](https://github.com/MillmanY/MMBannerLayout/blob/master/mid_demo.gif)

## Setting

![demo](https://github.com/MillmanY/MMBannerLayout/blob/master/demo.png)

## Use Banner
        if let layout = collection.collectionViewLayout as? MMBanerLayout {
            // Space every Item
            layout.itemSpace = 5.0
            // Size for banner cell
            layout.itemSize = self.collection.frame.insetBy(dx: 40, dy: 40).size
            // scroll to inifite (ex. completed block check your content size is enough to cycle infinite)
           (collection.collectionViewLayout as? MMBanerLayout)?.setInfinite(isInfinite: true, completed: { [unowned self]                    (result) in
                // result false mean you cant infinite
           })
            // auto play
            (collection.collectionViewLayout as? MMBanerLayout)?.autoPlayStatus = .play(duration: 2.0)
            // angle need to be (0~90)
            layout.angle = 45
        }
## Use BannerLayoutDelegate 

        //(Just setting self.collectionView.delegate = [your target])
        extension [your Target]: BannerLayoutDelegate {
                 // Current IndexPath on center
                func collectionView(_ collectionView: UICollectionView, focusAt indexPath: IndexPath) {
                     print("Focus on \(indexPath)")
                }
        }


## Installation

MMBannerLayout is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
(if you cant find pod command "pod repo update")
pod "MMBannerLayout"
```

## Author

millmanyang@gmail.com

## License

MMBannerLayout is available under the MIT license. See the LICENSE file for more info.
