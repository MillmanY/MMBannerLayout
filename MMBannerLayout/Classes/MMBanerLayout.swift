//
//  MMBanerLayout.swift
//  Pods
//
//  Created by Millman YANG on 2017/7/12.
//
//

import UIKit

@objc public protocol BannerLayoutDelegate {
    @objc optional func collectionView(_ collectionView: UICollectionView, focusAt indexPath: IndexPath)
}

public enum AutoPlayStatus {
    case none
    case play(duration: TimeInterval)
}

struct InfiniteLayoutRange {
    var start:(cycle: Int,index: Int) = (0,0)
    var end:(cycle:Int, index: Int) = (0,0)
}

class BannerLayoutAttributes: UICollectionViewLayoutAttributes {
    private var _realFrame = CGRect.zero
    var realFrame: CGRect {
        set {
            self._realFrame = newValue
            self.frame = newValue
        } get {
            return self._realFrame
        }
    }
    override func copy(with zone: NSZone? = nil) -> Any {
        let attribute = super.copy(with: zone) as! BannerLayoutAttributes
        return attribute
    }
}

public class MMBanerLayout: UICollectionViewLayout {
    public var focusIndexPath: IndexPath? {
        didSet {
            guard let f = focusIndexPath, (focusIndexPath != oldValue) else {
                return
            }
            
            (self.collectionView!.delegate as? BannerLayoutDelegate)?.collectionView?(self.collectionView!, focusAt: f)
        }
    }
    public var itemSpace:CGFloat = 0.0
    public var angle: CGFloat = 0.0 {
        didSet {
            self.invalidateLayout()
            if let attr = self.findCenterAttribute()  {
                let centerX = self.collectionView!.contentOffset.x + (self.collectionView!.frame.width/2)
                self._currentIdx = attributeList.index(of: attr)!
                self.collectionView!.contentOffset = CGPoint.init(x: self.collectionView!.contentOffset.x + attr.realFrame.midX - centerX, y: 0)
            }
        }
    }
    fileprivate var radius: CGFloat{
        get {
            return angle*CGFloat.pi/180
        }
    }
    fileprivate var angleItemWidth: CGFloat {
        get {
            return itemSize.width*cos(radius)
        }
    }
    
    fileprivate var _itemSize:CGSize?
    public var itemSize: CGSize{
        set {
            self._itemSize = newValue
            attributeList.forEach { $0.realFrame = .zero}
            self.invalidateLayout()
        } get {
            return _itemSize ?? self.collectionView!.frame.size
        }
    }
    fileprivate var indexSetWhenPrepare = false
    fileprivate var _currentIdx = 0
    public var currentIdx:Int {
        set {
            let centerX = self.collectionView!.contentOffset.x + (self.collectionView!.frame.width/2)
            
            if let attr = self.attributeList[safe: newValue] {
                let isAnimate = !(!self._isInfinite && newValue == 0)
                
                let x = self.collectionView!.contentOffset.x + attr.realFrame.midX - centerX
                self.collectionView!.setContentOffset(CGPoint(x: x, y: 0), animated: isAnimate)
            }

            self._currentIdx = newValue
            
        } get {
            return _currentIdx
        }
    }
    
    fileprivate var _isInfinite = false {
        didSet {
            if self._isInfinite {
                let twoDistance =  itemSize.width/2+angleItemWidth/2+itemSpace
                let cycleStart = twoDistance*CGFloat(self.collectionView!.calculate.totalCount*100000)
                self.collectionView!.setContentOffset(CGPoint(x: cycleStart, y: 0), animated: false)
                self.collectionView!.showsHorizontalScrollIndicator = false
            } else {
                self.collectionView!.setContentOffset(.zero, animated: false)
            }
            self.invalidateLayout()
        }
    }
    
    fileprivate var edgeMargin: CGFloat {
        get {
            return (self.collectionView!.frame.width-itemSize.width)/2
        }
    }
    
    fileprivate var timer: Timer?
    public var autoPlayStatus: AutoPlayStatus = .none {
        didSet {
            timer?.invalidate()
            switch autoPlayStatus {
            case .none:
                timer = nil
            case .play(let duration):
                timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(MMBanerLayout.autoScroll), userInfo: nil, repeats: true)
                RunLoop.current.add(timer!, forMode: .commonModes)
            }
        }
    }
    
    fileprivate var attributeList = [BannerLayoutAttributes]()
    override public var collectionViewContentSize: CGSize {
        get {
            return self.totalContentSize(isInfinite: self._isInfinite)
        }
    }
    
    fileprivate var _indexRange = InfiniteLayoutRange()
    fileprivate var indexRange: InfiniteLayoutRange {
        get {
            _indexRange.start = self.cycleAt(point: self.collectionView!.contentOffset.x)
            _indexRange.end = self.cycleAt(point: self.collectionView!.contentOffset.x + self.collectionView!.frame.width)
            return _indexRange
        }
    }

    fileprivate var setIdx = [Int]()
    
    fileprivate func cycleAt(point: CGFloat) -> (cycle: Int,index: Int) {
        let total = self.collectionView!.calculate.totalCount
        
        let twoDistance =  itemSize.width/2+angleItemWidth/2+itemSpace
        
        var cycle = Int(floor((point - edgeMargin)/(twoDistance*CGFloat(total))))
        let cycleStart = edgeMargin + twoDistance*CGFloat(total*cycle)
        var idx = Int(floor((point - cycleStart)/twoDistance))
        if !self._isInfinite && (cycle > 0) {
            cycle = 0
            idx = total - 1
        } else if total == 0 || cycle < 0 {
            cycle = 0
            idx = 0
        } else if idx >= total {
            idx = total - 1
        }
        
        return (cycle, idx)
    }
    
    public func setInfinite(isInfinite: Bool, completed:((_ success: Bool) -> Void)?) {
        
        if isInfinite {
            let twoDistance =  itemSize.width/2+angleItemWidth/2+itemSpace
            let needItem = Int(ceil(self.collectionView!.frame.width/twoDistance))
            self._isInfinite = needItem < self.collectionView!.calculate.totalCount
            completed?(self._isInfinite)
        } else {
            self._isInfinite = isInfinite
            completed?(true)
        }
    }
    
    fileprivate func totalContentSize(isInfinite: Bool) -> CGSize {
        var width:CGFloat = 0
        if isInfinite {
            width = CGFloat.greatestFiniteMagnitude
        } else {
            let twoDistance =  itemSize.width/2+angleItemWidth/2+itemSpace

            width = (twoDistance) * CGFloat(self.collectionView!.calculate.totalCount-1) + itemSize.width + 2*edgeMargin
        }
        let height = self.collectionView!.frame.height
        
        return CGSize(width: width, height: height)
    }
    
    @objc fileprivate func autoScroll() {
        if self.collectionView!.isDragging {
            return
        }
        let will = self.currentIdx + 1
        self.currentIdx = (will < self.collectionView!.calculate.totalCount) ? will : 0
    }
    
    override public func prepare() {
        super.prepare()
        self.collectionView!.decelerationRate = UIScrollViewDecelerationRateFast
        if self.collectionView!.calculate.isNeedUpdate() {
            attributeList.removeAll()
            attributeList = self.generateAttributeList()
            let reset = self._isInfinite
            self._isInfinite = reset
        }
        self.setAttributeFrame()
    }
    
    fileprivate func setAttributeFrame() {
        if self.collectionView!.contentOffset.x < 0 {
            return
        }
        setIdx.removeAll()
        let height = self.collectionView!.frame.height
        let range =  self.indexRange
        let centerX = self.collectionView!.contentOffset.x + (self.collectionView!.frame.width/2)
        let lastIdx = self.collectionView!.calculate.totalCount - 1
        var centerIdx = 0
        var preDistance = CGFloat.greatestFiniteMagnitude
        
        let twoDistance =  itemSize.width/2+angleItemWidth/2+itemSpace
        (range.start.cycle...range.end.cycle).forEach { (cycle) in
            let start = cycle == range.start.cycle ? range.start.index : 0
            let end  = cycle == range.end.cycle ? range.end.index : lastIdx
            var x:CGFloat = 0
            let cycleStart = edgeMargin + twoDistance*CGFloat(self.collectionView!.calculate.totalCount*cycle)

            (start...end).forEach({ (idx) in
                
                let location = twoDistance*CGFloat(idx)
                x = cycleStart + location
                let f = CGRect(x: x, y: (height - itemSize.height)/2, width: itemSize.width, height: itemSize.height)
                let mid = CGPoint(x: f.midX, y: f.midY)
                let distance = mid.distance(point: CGPoint(x: centerX, y: self.collectionView!.contentOffset.y))
                if preDistance > distance {
                    preDistance = distance
                    centerIdx = idx
                }
                attributeList[idx].realFrame = f
                setIdx.append(idx)
            })
        }
        let midX = attributeList[_currentIdx].frame.midX
        var percent = abs(centerX-midX)/twoDistance
        
        if percent >= 1 {
            percent = 0.0
            self._currentIdx = centerIdx
            indexSetWhenPrepare = true
        } else {
            indexSetWhenPrepare = false
        }
        self.focusIndexPath = attributeList[safe:_currentIdx]?.indexPath
        let centerLoc = setIdx.index(of: _currentIdx) ?? 0
        var transform = CATransform3DIdentity
        
        transform.m34  = -1 / 700
        setIdx.enumerated().forEach {
            switch $0.offset {
            case centerLoc-1:
                let fix = centerX < midX ? radius*(1-percent) : radius
                attributeList[$0.element].transform3D = CATransform3DRotate(transform, fix, 0, 1, 0)
            case centerLoc+1:
                let fix = centerX > midX ? -radius*(1-percent) : -radius
                attributeList[$0.element].transform3D = CATransform3DRotate(transform, fix, 0, 1, 0)

            case centerLoc:
                if centerX == midX {
                    attributeList[$0.element].transform3D = CATransform3DIdentity
                } else {
                    let fix = centerX > midX ? radius*(percent) : -radius*(percent)
                    attributeList[$0.element].transform3D = CATransform3DRotate(transform, fix, 0, 1, 0)
                }
            default:
                let r = $0.offset > centerLoc ? -radius :radius
                attributeList[$0.element].transform3D = CATransform3DRotate(transform, r, 0, 1, 0)
            }
        }
    }
    
    fileprivate func generateAttributeList() -> [BannerLayoutAttributes] {
        return (0..<self.collectionView!.numberOfSections).flatMap { (section) -> [BannerLayoutAttributes] in
            (0..<self.collectionView!.numberOfItems(inSection: section)).map({
                return BannerLayoutAttributes(forCellWith: IndexPath(row: $0, section: section))
            })
        }
    }
    
    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let first = attributeList.first(where: { $0.indexPath == indexPath }) else {
            let attr = BannerLayoutAttributes(forCellWith: indexPath)
            return attr
        }
        return first
    }
    
    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return setIdx.flatMap({ attributeList[safe:$0] })
    }
    
    override public func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        var fix = proposedContentOffset
        let lastIdx = self.collectionView!.calculate.totalCount - 1
        let centerX = self.collectionView!.contentOffset.x + (self.collectionView!.frame.width/2)
        
        if velocity.x != 0 {
            var idx = _currentIdx
            
            if velocity.x > 0{
                if indexSetWhenPrepare {
                    
                } else if !self._isInfinite {
                    idx = (_currentIdx+1 > lastIdx) ? lastIdx : _currentIdx+1
                } else {
                    idx = (_currentIdx+1 > lastIdx) ? (currentIdx)%lastIdx : _currentIdx+1                
                }
            } else {
                if indexSetWhenPrepare {
                    
                } else if !self._isInfinite {
                    idx = (_currentIdx-1 < 0) ? 0 : currentIdx-1
                } else {
                    idx = (_currentIdx-1 < 0) ? lastIdx : currentIdx-1
                }
            }
            if let attr = self.attributeList[safe: idx] {
                self._currentIdx = idx
                fix.x = self.collectionView!.contentOffset.x + attr.realFrame.midX - centerX
            }
        } else {
            if let attr = self.findCenterAttribute()  {
                self._currentIdx = attributeList.index(of: attr)!
                fix.x = self.collectionView!.contentOffset.x + attr.realFrame.midX - centerX
            }
        }
        return fix
    }
    
    fileprivate func findCenterAttribute() -> BannerLayoutAttributes? {
        let centerX = self.collectionView!.contentOffset.x + (self.collectionView!.frame.width/2)
        var attribute: BannerLayoutAttributes?
        var preDistance = CGFloat.greatestFiniteMagnitude
        attributeList.enumerated().forEach({
            let mid = CGPoint(x: $0.element.realFrame.midX, y: $0.element.realFrame.midY)
            let distance = mid.distance(point: CGPoint(x: centerX, y: self.collectionView!.contentOffset.y))
            if preDistance > distance {
                preDistance = distance
                attribute = $0.element
            }
        })
        return attribute
    }
    
    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
