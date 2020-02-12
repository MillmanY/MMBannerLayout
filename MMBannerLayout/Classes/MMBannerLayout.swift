//
//  MMBanerLayout.swift
//  Pods
//
//  Created by Millman YANG on 2017/7/12.
//
//

import UIKit

@objc public protocol BannerLayoutDelegate {
    @objc optional func collectionView(_ collectionView: UICollectionView, focusAt indexPath: IndexPath?)
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

public class MMBannerLayout: UICollectionViewLayout {
    public var focusIndexPath: IndexPath? {
        didSet {
            if focusIndexPath == oldValue { return }
            (self.collectionView!.delegate as? BannerLayoutDelegate)?.collectionView?(self.collectionView!, focusAt: focusIndexPath)
        }
    }
    public var itemSpace:CGFloat = 0.0
    public var angle: CGFloat = 0.0 {
        didSet {
            self.invalidateLayout()
            if let attr = self.findCenterAttribute()  {
                let centerX = self.collectionView!.contentOffset.x + (self.collectionView!.frame.width/2)
                self._currentIdx = attributeList.firstIndex(of: attr)!
                self.collectionView!.contentOffset = CGPoint.init(x: self.collectionView!.contentOffset.x + attr.realFrame.midX - centerX, y: 0)
            }
        }
    }
    public var minimuAlpha: CGFloat = 1.0 {
        didSet {
            self.invalidateLayout()
        }
    }
    
    private var twoDistance: CGFloat {
        get {
            return itemSize.width/2+angleItemWidth/2+itemSpace
        }
    }
    
    private var radius: CGFloat{
        get {
            return angle*CGFloat.pi/180
        }
    }
    private var angleItemWidth: CGFloat {
        get {
            return itemSize.width*cos(radius)
        }
    }
    
    private var _itemSize:CGSize?
    public var itemSize: CGSize{
        set {
            self._itemSize = newValue
            attributeList.forEach { $0.realFrame = .zero}
            self.invalidateLayout()
        } get {
            return _itemSize ?? self.collectionView!.frame.size
        }
    }
    private var indexSetWhenPrepare = false
    private var _currentIdx = 0
    public var currentIdx: Int {
        get {
            return _currentIdx
        }
    }
    
    @discardableResult
    public func setCurrentIndex(_ index: Int) -> Bool {
        guard let count = self.collectionView?.calculate.totalCount, index < count else {
            return false
        }
        let isAnimate = !(!self._isInfinite && index == 0)
        if let frame = self.attributeList[safe: index]?.realFrame, frame != .zero {
            let centerX = self.collectionView!.contentOffset.x + (self.collectionView!.frame.width/2)
            let x = self.collectionView!.contentOffset.x + frame.midX - centerX
            self.collectionView!.setContentOffset(CGPoint(x: x, y: 0), animated: isAnimate)
        } else {
            let cycleStart = self._isInfinite ? twoDistance*CGFloat(self.collectionView!.calculate.totalCount*100000) : 0
            let location = twoDistance*CGFloat(index)
            let x = cycleStart + location
            self.collectionView!.setContentOffset(CGPoint(x: x, y: 0), animated: isAnimate)
        }
        self._currentIdx = index
        return true
    }
    
    private var _isInfinite = false {
        didSet {
            let cycleStart = self._isInfinite ? twoDistance*CGFloat(self.collectionView!.calculate.totalCount*100000) : 0
            let location = twoDistance*CGFloat(_currentIdx)
            let x = cycleStart + location
            self.collectionView!.setContentOffset(CGPoint(x: x, y: 0), animated: false)
            self.invalidateLayout()
        }
    }
    
    private var edgeMargin: CGFloat {
        get {
            return (self.collectionView!.frame.width-itemSize.width)/2
        }
    }
    
    private var timer: Timer?
    public var autoPlayStatus: AutoPlayStatus = .none {
        didSet {
            timer?.invalidate()
            switch autoPlayStatus {
            case .none:
                timer = nil
            case .play(let duration):
                timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(MMBannerLayout.autoScroll), userInfo: nil, repeats: true)
                RunLoop.current.add(timer!, forMode: .common)
            }
        }
    }
    
    private var attributeList = [BannerLayoutAttributes]()
    override public var collectionViewContentSize: CGSize {
        get {
            return self.totalContentSize(isInfinite: self._isInfinite)
        }
    }
    
    private var _indexRange = InfiniteLayoutRange()
    private var setIdx = [Int]()
    
    private func cycleAt(point: CGFloat) -> (cycle: Int,index: Int) {
        let total = self.collectionView!.calculate.totalCount
        var cycle = Int(floor((point - edgeMargin)/(twoDistance*CGFloat(total))))
        let cycleStart = edgeMargin + twoDistance*CGFloat(total*cycle)
        var idx = Int(floor((point - cycleStart)/twoDistance))
        if total == 0 || cycle < 0 {
            cycle = 0
            idx = 0
        } else if idx >= total {
            idx = total - 1
        }
        return (cycle, idx)
    }
    
    public func setInfinite(isInfinite: Bool, completed:((_ success: Bool) -> Void)?) {
        self.collectionView!.calculate.setNeedUpdate()
        if isInfinite {
            let needItem = Int(ceil(self.collectionView!.frame.width/twoDistance))
            self._isInfinite = needItem < self.collectionView!.calculate.totalCount
            completed?(self._isInfinite)
        } else {
            self._isInfinite = isInfinite
            completed?(true)
        }
    }
    
    private func totalContentSize(isInfinite: Bool) -> CGSize {
        var width:CGFloat = 0
        if isInfinite {
            width = CGFloat.greatestFiniteMagnitude
        } else {
            width = (twoDistance) * CGFloat(self.collectionView!.calculate.totalCount-1) + itemSize.width + 2*edgeMargin
        }
        let height = self.collectionView!.frame.height
        
        return CGSize(width: width, height: height)
    }
    
    @objc private func autoScroll() {
        guard let collect = self.collectionView else {
            timer?.invalidate()
            timer = nil
            return
        }
        if collect.isDragging { return }
        let will = self.currentIdx + 1
        let convert = (will < self.collectionView!.calculate.totalCount) ? will : 0
        self.setCurrentIndex(convert)
    }
    
    override public func prepare() {
        super.prepare()
        self.collectionView!.decelerationRate = UIScrollView.DecelerationRate.fast
        if self.collectionView!.calculate.isNeedUpdate {
            let reset = self._isInfinite
            self._isInfinite = reset
            attributeList.removeAll()
            attributeList = self.generateAttributeList()
            self.focusIndexPath = nil
            _currentIdx = 0
            if !reset {
                self.collectionView?.contentOffset = .zero
            }
        }
        self.setAttributeFrame(offset: self.collectionView!.contentOffset)
    }
    
    private func setAttributeFrame(offset: CGPoint) {
        if offset.x < 0 || self.collectionView?.calculate.totalCount == 0 {
            return
        }
        _indexRange.start = self.cycleAt(point: offset.x)
        _indexRange.end = self.cycleAt(point: offset.x + self.collectionView!.frame.width)
        let range =  self._indexRange
        setIdx.removeAll()
        let height = self.collectionView!.frame.height
        let centerX = offset.x + (self.collectionView!.frame.width/2)
        let lastIdx = self.collectionView!.calculate.totalCount - 1
        var centerIdx = 0
        var preDistance = CGFloat.greatestFiniteMagnitude
        
        (range.start.cycle...range.end.cycle).forEach { (cycle) in
            let start = cycle == range.start.cycle ? range.start.index : 0
            let end  = cycle == range.end.cycle ? range.end.index : lastIdx
            var x:CGFloat = 0
            let convert = self._isInfinite ? cycle : 0
            let cycleStart = edgeMargin + twoDistance*CGFloat(self.collectionView!.calculate.totalCount*convert)
            
            (start...end).forEach({ (idx) in
                
                let location = twoDistance*CGFloat(idx)
                x = cycleStart + location
                let f = CGRect(x: x, y: (height - itemSize.height)/2, width: itemSize.width, height: itemSize.height)
                let mid = CGPoint(x: f.midX, y: f.midY)
                let distance = mid.distance(point: CGPoint(x: centerX, y: offset.y))
                if preDistance > distance {
                    preDistance = distance
                    centerIdx = idx
                }
                attributeList[idx].realFrame = f
                setIdx.append(idx)
            })
        }
        let midIdx = _currentIdx > self.collectionView!.calculate.totalCount-1 ? centerIdx : _currentIdx
        let midX = attributeList[midIdx].frame.midX
        var percent = abs(centerX-midX)/twoDistance
        if percent >= 1 {
            percent = 0.0
            self._currentIdx = centerIdx
            indexSetWhenPrepare = true
        } else {
            indexSetWhenPrepare = false
        }
        self.focusIndexPath = attributeList[safe:_currentIdx]?.indexPath
        let centerLoc = setIdx.firstIndex(of: _currentIdx) ?? 0
        var transform = CATransform3DIdentity
        
        transform.m34  = -1 / 700
        setIdx.enumerated().forEach {
            switch $0.offset {
            case centerLoc-1:
                
                if centerX < midX {
                    attributeList[$0.element].transform3D = CATransform3DRotate(transform, radius*(1-percent), 0, 1, 0)
                    attributeList[$0.element].alpha = minimuAlpha + (1-minimuAlpha)*percent
                    
                } else {
                    attributeList[$0.element].transform3D = CATransform3DRotate(transform, radius, 0, 1, 0)
                    attributeList[$0.element].alpha = minimuAlpha
                }
                
            case centerLoc+1:
                
                if centerX > midX {
                    attributeList[$0.element].alpha = minimuAlpha + (1-minimuAlpha)*percent
                    attributeList[$0.element].transform3D = CATransform3DRotate(transform, -radius*(1-percent), 0, 1, 0)
                } else {
                    attributeList[$0.element].alpha = minimuAlpha
                    attributeList[$0.element].transform3D = CATransform3DRotate(transform, -radius, 0, 1, 0)
                }
            case centerLoc:
                if centerX == midX {
                    attributeList[$0.element].alpha = 1.0
                    attributeList[$0.element].transform3D = CATransform3DIdentity
                } else if centerX > midX {
                    attributeList[$0.element].alpha = minimuAlpha + (1-minimuAlpha)*(1-percent)
                    attributeList[$0.element].transform3D = CATransform3DRotate(transform, radius*(percent), 0, 1, 0)
                    
                } else {
                    attributeList[$0.element].alpha = minimuAlpha + (1-minimuAlpha)*(1-percent)
                    attributeList[$0.element].transform3D = CATransform3DRotate(transform, -radius*(percent), 0, 1, 0)
                }
                
            default:
                attributeList[$0.element].alpha = 0.5
                let r = $0.offset > centerLoc ? -radius :radius
                attributeList[$0.element].transform3D = CATransform3DRotate(transform, r, 0, 1, 0)
            }
        }
    }
    
    private func generateAttributeList() -> [BannerLayoutAttributes] {
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
        return setIdx.compactMap({ attributeList[safe:$0] })
    }
    
    override public func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        var fix = proposedContentOffset
        
        let lastIdx = self.collectionView!.calculate.totalCount - 1
        let centerX = proposedContentOffset.x + (self.collectionView!.frame.width/2)
        
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
            
            if self.attributeList[safe: idx]?.realFrame == .zero {
                self.setAttributeFrame(offset: proposedContentOffset)
            }
            
            if let attr = self.attributeList[safe: idx] {
                self._currentIdx = idx
                fix.x = proposedContentOffset.x + attr.realFrame.midX - centerX
            }
        } else {
            if let attr = self.findCenterAttribute()  {
                self._currentIdx = attributeList.firstIndex(of: attr)!
                fix.x = self.collectionView!.contentOffset.x + attr.realFrame.midX - centerX
            }
        }
        return fix
    }
    
    private func findCenterAttribute() -> BannerLayoutAttributes? {
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
