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
    var images = [#imageLiteral(resourceName: "images"),#imageLiteral(resourceName: "images2"),#imageLiteral(resourceName: "images3"),#imageLiteral(resourceName: "images3"),#imageLiteral(resourceName: "images3"),#imageLiteral(resourceName: "images3"),#imageLiteral(resourceName: "images3"),#imageLiteral(resourceName: "images3"),#imageLiteral(resourceName: "images3"),#imageLiteral(resourceName: "images3")]
    @IBOutlet weak var infiniteSwitch : UISwitch!
    @IBOutlet weak var labAngle: UILabel!
    @IBOutlet weak var collection: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        collection.showsHorizontalScrollIndicator = false
        if let layout = collection.collectionViewLayout as? MMBannerLayout {
            layout.itemSpace = 10
            layout.itemSize = self.collection.frame.insetBy(dx: 40, dy: 40).size
            layout.minimuAlpha = 0.4
        }
    }
    
    @IBAction func appendAction() {
        images.removeLast()
        images.removeLast()
        collection.reloadData()
    }

    @IBAction func inifiteAction(sw: UISwitch) {
    
        (collection.collectionViewLayout as? MMBannerLayout)?.setInfinite(isInfinite: sw.isOn, completed: { [unowned self] (result) in
            if result {
                return
            }
            // Prevent your content size is enough to cycle
            let alert = UIAlertController.init(title: "Layout error", message: "Your item cant Infinite ", preferredStyle: .alert)
            

            let action = UIAlertAction(title: "Confirm", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                sw.isOn = result
            })
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    @IBAction func autoPlayAction(sw: UISwitch) {
        if sw.isOn {
            (collection.collectionViewLayout as? MMBannerLayout)?.autoPlayStatus = .play(duration: 2.0)
        } else {
            (collection.collectionViewLayout as? MMBannerLayout)?.autoPlayStatus = .none
        }
    }
    
    @IBAction func angleAction(slider: UISlider) {
        labAngle.text = "Angle: \(slider.value)"
        infiniteSwitch.isOn = false
        (collection.collectionViewLayout as? MMBannerLayout)?.setInfinite(isInfinite: false, completed: nil)
        (collection.collectionViewLayout as? MMBannerLayout)?.angle = CGFloat(slider.value)
    }
}

extension ViewController: BannerLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, focusAt indexPath: IndexPath) {
        print("Focus At \(indexPath)")
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

