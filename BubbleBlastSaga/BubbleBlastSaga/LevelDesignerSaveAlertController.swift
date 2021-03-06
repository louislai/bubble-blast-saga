//
//  LevelDesignerSaveAlertController.swift
//  LevelDesigner
//
//  Created by Edmund Mok on 3/2/17.
//  Copyright © 2017 nus.cs3217.a0101010. All rights reserved.
//

import UIKit

/**
 This class is a helper viewcontroller that is in charge of the 
 save alert that will be presented upon a tap on the save button
 in the level designer.
 
 This class requires a parent view controller (must be a child of another
 viewcontroller) to present the save alert.
 */
class LevelDesignerSaveAlertController: UIViewController {
    
    private let bubbleGridModel: BubbleGridModel?
    private let bubbleGrid: UICollectionView?
    
    init(bubbleGridModel: BubbleGridModel, bubbleGrid: UICollectionView) {
        self.bubbleGridModel = bubbleGridModel
        self.bubbleGrid = bubbleGrid
        super.init(nibName: nil, bundle: nil)
    }
    
    // Give a simple implementation for this init as it is required
    // but will not be used
    required init?(coder aDecoder: NSCoder) {
        self.bubbleGridModel = nil
        self.bubbleGrid = nil
        super.init(coder: aDecoder)
    }
    
    // Presents the save alert involved in saving the current bubble
    // grid model.
    func presentSaveAlert() {
        // check if current grid was a newly created one 
        // or one that was a loaded/saved grid
        guard let currentSavedLevel = bubbleGridModel?.loadedFileName else {
            // if not only request for custom name to save as
            presentAlertToSaveAsNewFile()
            return
        }
        
        // ask if want to save as new file or overwrite current file
        presentAlertToSaveAsNewFileOrOverwriteFile(for: currentSavedLevel)
    }
    
    // Presents the alert that asks the user for a custom level name
    // to save the current bubble grid as.
    private func presentAlertToSaveAsNewFile() {
        // setup title, message and text field for the save alert
        let saveAlertTitle = Constants.saveAlertTitle
        let saveAlertMessage = Constants.saveAlertMessage
        let saveAlertTextFieldPlaceholder = Constants.saveAlertTextPlaceholder
        
        // attach title, message and text fields to the alert
        let saveAlert = UIAlertController(title: saveAlertTitle, message: saveAlertMessage,
            preferredStyle: .alert)
        saveAlert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = saveAlertTextFieldPlaceholder
            textField.addTarget(self, action: #selector(self.textChanged), for: .editingChanged)
        })
        
        // setup actions for alert
        let cancelAction = UIAlertAction(title: Constants.cancelTitle, style: .cancel)
        
        let saveAction = UIAlertAction(title: Constants.saveTitle, style: .default) {
            [weak self, weak saveAlert] (_) -> Void in
            
            // get the level name
            let levelName = saveAlert?.textFields?.first?.text ?? Constants.blankLevelName
            
            let fileURL = FileUtility.getFileURL(for: levelName, and: Constants.fileExtension)
            
            // ask user to confirm overwrite if file already exists
            guard !FileManager.default.fileExists(atPath: fileURL.relativePath) else {
                self?.presentAlertForNameAlreadyExists(for: levelName)
                return
            }
            
            // no existing file, just save
            self?.saveBubbleGridAndPresentResultAlert(levelName: levelName)
        }
        
        saveAction.isEnabled = false
        actionToEnable = saveAction
        saveAlert.addAction(cancelAction)
        saveAlert.addAction(saveAction)
     
        self.parent?.present(saveAlert, animated: true)
    }
    
    // Used to validate the textfield to ensure only alphanumeric characters for level name
    weak var actionToEnable: UIAlertAction?
    
    // On text change, only enable the save alert's save action button 
    // if the name in the text field is alphanumeric.
    @objc private func textChanged(_ sender: UITextField) {
        self.actionToEnable?.isEnabled = sender.text?.isAlphanumeric ?? false
    }
    
    // Presents the alert that asks the user to confirm whether the bubblegrid
    // should be saved as the current level name (overwrite) or as another level name.
    private func presentAlertToSaveAsNewFileOrOverwriteFile(for levelName: String) {
        let title = "Save as \(levelName)?"
        let message = "Please confirm if you would like to save as \(levelName) or as another file."
        let saveAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        saveAlert.addAction(UIAlertAction(title: "Save as \(levelName)", style: .default) {
            [weak self] (_) -> Void in
            
            // user wants to save as current name (overwrite file), just save
            self?.saveBubbleGridAndPresentResultAlert(levelName: levelName)
        })
        saveAlert.addAction(UIAlertAction(title: Constants.saveAsAnotherTitle, style: .default) {
            [weak self] (_) -> Void in
            
            // user wants to save as different name, bring up the 
            // custom name alert
            self?.presentAlertToSaveAsNewFile()
        })
        saveAlert.addAction(UIAlertAction(title: Constants.cancelTitle, style: .cancel))
        self.parent?.present(saveAlert, animated: true)
    }
    
    // Saves the current bubble grid model and presents the save result
    // (success or failure) through a result alert.
    private func saveBubbleGridAndPresentResultAlert(levelName: String) {
        // attempt to save the bubble grid model
        let isSaveSuccessful = self.bubbleGridModel?.save(as: levelName) ?? false
        
        guard let currentGrid = self.bubbleGrid else {
            presentAlertForSaveFailure(for: levelName)
            return
        }
        
        // save a picture of the current grid also
        UIGraphicsBeginImageContext(currentGrid.frame.size)
        
        guard let currentContext = UIGraphicsGetCurrentContext() else {
            presentAlertForSaveFailure(for: levelName)
            return
        }
        
        currentGrid.layer.render(in: currentContext)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            presentAlertForSaveFailure(for: levelName)
            return
        }
        
        UIGraphicsEndImageContext()
        let imageData = UIImagePNGRepresentation(image)
        
        // saving image
        let fileURL = FileUtility.getFileURL(for: levelName, and: Constants.pngExtension)
        try? imageData?.write(to: fileURL, options: .atomic)
        
        // save new info list
        let levelInfoURL = FileUtility.getFileURL(for: levelName, and: Constants.plistExtension)
        let levelInfoDict = NSMutableDictionary()
        
        let _ = levelInfoDict.write(to: levelInfoURL, atomically: true)
        
        
        // Present alert on whether save is successful
        guard isSaveSuccessful else {
            presentAlertForSaveFailure(for: levelName)
            return
        }
        
        presentAlertForSaveSuccess(for: levelName)
    }
    
    // Presents the alert for when the file name to save as already exists.
    private func presentAlertForNameAlreadyExists(for levelName: String) {
        let title = "\(levelName) already exists."
        let message = "Overwrite the existing saved \(levelName)?"
        let fileNameExistsAlert = UIAlertController(title: title, message: message,
            preferredStyle: .alert)
        
        fileNameExistsAlert.addAction(UIAlertAction(title: Constants.yesTitle, style: .default) {
            [weak self] (_) -> Void in
            
            // user confirmed to overwrite, go ahead and save
            self?.saveBubbleGridAndPresentResultAlert(levelName: levelName)
        })
        
        fileNameExistsAlert.addAction(UIAlertAction(title: Constants.noTitle, style: .cancel) {
            [weak self] (_) -> Void in
            
            // do not overwrite, present custom name alert again
            // for user to specify another name
            self?.presentAlertToSaveAsNewFile()
        })
        
        self.parent?.present(fileNameExistsAlert, animated: true)
    }
    
    // Presents the alert for a save success.
    private func presentAlertForSaveSuccess(for levelName: String) {
        let title =  "\(levelName) saved successfully."
        let saveSuccessAlert = UIAlertController(title: title, message: Constants.blankMessage,
            preferredStyle: .alert)
        saveSuccessAlert.addAction(UIAlertAction(title: Constants.okTitle, style: .cancel))
        self.parent?.present(saveSuccessAlert, animated: true)
    }
    
    // Presents the alert for a save failure.
    private func presentAlertForSaveFailure(for levelName: String) {
        let title = "\(levelName) could not be saved."
        let message = Constants.tryAgainMessage
        let saveFailureAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        saveFailureAlert.addAction(UIAlertAction(title: Constants.okTitle, style: .cancel) {
            [weak self] (_) -> Void in
            // on OK, presents the save alert again to provide an opportunity for user to save again
            self?.presentSaveAlert()
        })
        self.parent?.present(saveFailureAlert, animated: true)
    }
    
}
