//
//  ViewController.swift
//  guitarvision
//
//  Created by Dennis Münchow on 07.12.23.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            guard let convertedCIImage = CIImage(image: userPickedImage) else {
                fatalError("cannot convert to CIImage")
            }
            
            detect(image: convertedCIImage)
            
            imageView.image = userPickedImage
        }
        imagePicker.dismiss(animated: true, completion: nil )
    }
    
    func detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: guitarvisionML5().model) else {
            
            fatalError("Cannot import model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                
                fatalError("x")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(guitarName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
        }
        catch {
            print(error)
        }
        
    }
    
    func requestInfo(guitarName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts",
            "exintro" : "",
            "explaintext" : "",
            "titles" : guitarName,
            "indexpageids" : "",
            "redirects" : "1",
        ]
        
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { response in
            if case .success(let value) = response.result {
                print("Got the wikipedia Info")
                print(value)
                
                let guitarJSON : JSON =  JSON(response.result.value!)
                
                let pageID = guitarJSON["query"]["pageid"][0].stringValue
                 
                let guitarDescription = guitarJSON["query"]["pages"]["pageid"]["extract"].stringValue
                
                self.descriptionLabel.text = guitarDescription
                print(self.descriptionLabel.text)
                
            } else if case .failure(let error) = response.result {
                print("Error: \(error)")
            }
        }

    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    
}

