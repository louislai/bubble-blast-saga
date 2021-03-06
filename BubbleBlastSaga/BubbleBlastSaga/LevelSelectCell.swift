//
//  LevelSelectCell.swift
//  BubbleBlastSaga
//
//  Created by Edmund Mok on 25/2/17.
//  Copyright © 2017 nus.cs3217.a0093960x. All rights reserved.
//

import UIKit

class LevelSelectCell: UICollectionViewCell {
    
    @IBOutlet weak var levelImage: UIImageView!
    @IBOutlet weak var levelName: UILabel!
    @IBOutlet weak var highScore: UILabel!
    @IBOutlet weak var deleteButton: LevelSelectCellButton!
    @IBOutlet weak var playLoadButton: LevelSelectCellButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Set up the style for the level select cell.
    func setStyle() {
        layer.cornerRadius = frame.width
            / Constants.levelSelectCellCornerMultiplier
        
        layer.masksToBounds = true
        
        levelImage.frame.size.width = frame.width
        levelImage.frame.size.height = frame.width
            * Constants.levelSelectCellAspectRatio
        
        levelImage.clipsToBounds = true
        levelImage.alpha = Constants.levelSelectImageAlpha

    }
    
    // Set the index path associated with this cell.
    func set(indexPath: IndexPath) {
        deleteButton.indexPath = indexPath
        playLoadButton.indexPath = indexPath
    }
    
}
