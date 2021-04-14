//
//  MapViewController.swift
//  compass
//
//  Created by Federico Zanetello on 23/04/2017.
//  Copyright © 2017 Kimchi Media. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
  var delegate: MapViewControllerDelegate!
  @IBOutlet weak var mapView: MKMapView!
  
  @IBAction func cancelTap(_ sender: UIBarButtonItem) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func resetTap(_ sender: UIBarButtonItem) {
    delegate.update(location: CLLocation(latitude: 90, longitude: 0))
    self.dismiss(animated: true, completion: nil)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    mapView.showsUserLocation = true
    if #available(iOS 9, *) {
      mapView.showsScale = true
      mapView.showsCompass = true
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MapViewController.didTap(_:)))
    mapView.addGestureRecognizer(gestureRecognizer)
  }

    @objc public func didTap(_ gestureRecognizer: UIGestureRecognizer) {
    let location = gestureRecognizer.location(in: mapView)
    let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        
    // PinID
    var pinId: String = "1";
    
    delegate.update(location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        
        // GET ALL PINS
        let urlget = URL(string: "http://192.168.2.90:5000/api/v1/pins")!

        let taskget = URLSession.shared.dataTask(with: urlget) {(data, response, error) in
            guard let data = data else { return }
            if error == nil {
                // Parse JSON
                let decoder = JSONDecoder()
                
                do{
                    let pinResponse = try decoder.decode(Pinresponse.self, from: data)
                    if(pinResponse.data?.count == 0){
                        print(pinResponse.data)
                    }else{
                        guard let dataPins = pinResponse.data else { return }
                        guard let lastDataPin = dataPins.last else { return }
                        let myInt1 = Int(lastDataPin.pinId ?? "1") ?? 0
                        let newPin = myInt1 + 1;
                        pinId = String(newPin);
                    }
                    
                    postData(longitude: coordinate.longitude, latitude: coordinate.latitude, pinId: pinId);
                }catch{
                    print(error.localizedDescription)
                }
            }
        }

        taskget.resume()
        
        
        
    self.dismiss(animated: true, completion: nil)
  }
}

func postData(longitude: Double, latitude: Double, pinId: String){
    
    // SEND COORDINATES TO MY API
    
    // prepare json data
    let json: [String: Any] = [
        "pinId": pinId,
        "location": [
            "coordinates": [longitude, latitude]
        ]
    ]

    let jsonData = try? JSONSerialization.data(withJSONObject: json)

    // create post request
    let url = URL(string: "http://192.168.2.90:5000/api/v1/pins")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    // insert json data to the request
    request.httpBody = jsonData

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print(error?.localizedDescription ?? "No data")
            return
        }
        let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
        if let responseJSON = responseJSON as? [String: Any] {
            print(responseJSON)
        }
    }

    task.resume()
}


