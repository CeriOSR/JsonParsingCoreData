//
//  APIService.swift
//  CoreDataTutorial
//
//  Created by Rey Cerio on 2017-03-09.
//  Copyright © 2017 James Rochabrun. All rights reserved.
//

import UIKit

class APIService: NSObject {
    
    let query = "dogs"
    lazy var endPoint: String = {
        return "https://api.flickr.com/services/feeds/photos_public.gne?format=json&tags=\(self.query)&nojsoncallback=1#"
    }()
    
    func getDataWith(completion: @escaping (Result<[[String: AnyObject]]>) -> Void) {
        guard let url = URL(string: endPoint) else {return completion(.Error("Invalid URL, we can't update your feed"))}
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard error == nil else {return completion(.Error(error!.localizedDescription))}
            guard let data = data else {return completion(.Error(error!.localizedDescription ))}
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers]) as? [String: AnyObject] {
                    guard let itemsJsonArray = json["items"] as? [[String:AnyObject]] else {return completion(.Error(error!.localizedDescription))}
                    DispatchQueue.main.async {
                        completion(.Success(itemsJsonArray))     //all closures are executed Async so we bring it back to main thread
                    }
                }
            } catch let error {
                return completion(.Error(error.localizedDescription))
            }
        }.resume() //always resume URLSessions
        
    }
    
}

enum Result<T>{     //generics are AWESOME!
    case Success(T)
    case Error(String)
}
