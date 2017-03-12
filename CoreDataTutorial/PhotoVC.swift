//
//  ViewController.swift
//  CoreDataTutorial
//
//  Created by James Rochabrun on 3/1/17.
//  Copyright © 2017 James Rochabrun. All rights reserved.
//

import UIKit
import CoreData

class PhotoVC: UITableViewController {
    
    private let cellID = "cellID"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Photos Feed"
        view.backgroundColor = .white
        tableView.register(PhotoCell.self, forCellReuseIdentifier: cellID)
        updateTableContent()
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! PhotoCell
        
        if let photo = fetchedResultController.object(at: indexPath) as? Photo {
            cell.setPhotoCellWith(photo: photo)
        }
        
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = fetchedResultController.sections?.first?.numberOfObjects {
            return count
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.width + 100 //100 = sum of labels height + height of divider line
    }
    
    func showAlertWith(title: String, message: String, style: UIAlertControllerStyle = .alert) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        let action = UIAlertAction(title: title, style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func createPhotoEntityFrom(dictionary: [String: AnyObject]) -> NSManagedObject? {
        let context = CoreDataStack.shareInstance.persistentContainer.viewContext
        if let photoEntity = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: context) as? Photo {
            photoEntity.author = dictionary["author"] as? String
            photoEntity.tags = dictionary["tags"] as? String
            let mediaDictionary = dictionary["media"] as? [String: AnyObject]
            photoEntity.mediaURL = mediaDictionary?["m"] as? String
            return photoEntity
        }
        return nil
    }
    
    private func saveInCoreDataWith(array: [[String: AnyObject]]) {
        _ = array.map{self.createPhotoEntityFrom(dictionary: $0)}
        do {
            try CoreDataStack.shareInstance.persistentContainer.viewContext.save()
        } catch let error {
            print(error)
        }
    }
    
    lazy var fetchedResultController: NSFetchedResultsController<NSFetchRequestResult> = {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Photo.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "author", ascending: true)]
        let context = CoreDataStack.shareInstance.persistentContainer.viewContext
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
        
    }()
    
    private func clearData() {
        do {
            let context = CoreDataStack.shareInstance.persistentContainer.viewContext
            let fetchedRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
            do {
                let objects = try context.fetch(fetchedRequest) as? [NSManagedObject]
                _ = objects.map{$0.map{context.delete($0)}}
                CoreDataStack.shareInstance.saveContext()
            }catch let error {
                print(error)
            }
        }
    }
    
    func updateTableContent() {
        do {
            try self.fetchedResultController.performFetch()
            print("count fetched first: \(self.fetchedResultController.sections?[0].numberOfObjects)")
        }catch let error {
            print(error)
        }
        
        
        let service = APIService()
        service.getDataWith { (result) in
            switch result {
            case .Success(let data):
                self.clearData()
                self.saveInCoreDataWith(array: data)
            //print(data)
            case .Error(let message):
                DispatchQueue.main.async {
                    self.showAlertWith(title: "Error", message: message)
                }
            }
        }
    }
}











