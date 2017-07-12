//
//  ViewController.swift
//  MMBannerLayout
//
//  Created by millmanyang@gmail.com on 07/12/2017.
//  Copyright (c) 2017 millmanyang@gmail.com. All rights reserved.
//

import UIKit
import MMBannerLayout
class ViewController: UIViewController {
    var images = [#imageLiteral(resourceName: "images"),#imageLiteral(resourceName: "images2"),#imageLiteral(resourceName: "images3"),#imageLiteral(resourceName: "images4"),#imageLiteral(resourceName: "images5"),#imageLiteral(resourceName: "images6")]
    @IBOutlet weak var labAngle: UILabel!
    @IBOutlet weak var collection: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let layout = collection.collectionViewLayout as? MMBanerLayout {
            layout.itemSpace = 5.0
            layout.itemSize = self.collection.frame.insetBy(dx: 40, dy: 40).size
        }
    }
    
    @IBAction func inifiteAction(sw: UISwitch) {
        (collection.collectionViewLayout as? MMBanerLayout)?.isInfinite = sw.isOn
    }
    
    @IBAction func autoPlayAction(sw: UISwitch) {
        (collection.collectionViewLayout as? MMBanerLayout)?.autoPlayBanner = sw.isOn
    }
    
    @IBAction func angleAction(slider: UISlider) {
        labAngle.text = "Angle: \(slider.value)"
        (collection.collectionViewLayout as? MMBanerLayout)?.isInfinite = false
        (collection.collectionViewLayout as? MMBanerLayout)?.angle = CGFloat(slider.value)
    }
}

extension ViewController: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCell {
            cell.imgView.image = images[indexPath.row]
            cell.labTitle.text = "section: \(indexPath.section) row: \(indexPath.row)"
            return cell
        }
        return UICollectionViewCell()
    }
}

