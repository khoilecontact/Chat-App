//
//  LocationPickerViewController.swift
//  Chat App
//
//  Created by KhoiLe on 15/09/2021.
//

import UIKit
import CoreLocation
import MapKit

class LocationPickerViewController: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D) -> Void)?
    private var coordinate: CLLocationCoordinate2D?
    private var isPickable = true
    
    private let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    init(coordinate: CLLocationCoordinate2D?) {
        super.init(nibName: nil, bundle: nil)
        self.coordinate = coordinate
        self.isPickable = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendButtonTapped))
            
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(gesture)
            map.isUserInteractionEnabled = true
        } else {
            guard let coordinate = self.coordinate else {
                return
            }
            //Drop a pin on that location
            let pin = MKPointAnnotation()
            pin.coordinate = coordinate
            map.addAnnotation(pin)
        }
        
        view.addSubview(map)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
    
    @objc func sendButtonTapped() {
        guard let coordinate = coordinate else {
            print("Coordinates are nil - LocationPickerViewController")
            return
        }
        navigationController?.popViewController(animated: true)
        completion?(coordinate)
    }
    
    @objc func didTapMap(_ gesture: UITapGestureRecognizer) {
        let locationInView = gesture.location(in: map)
        let coordinate = map.convert(locationInView, toCoordinateFrom: map)
        self.coordinate = coordinate
        
        for annotation in map.annotations {
            map.removeAnnotation(annotation)
        }
        
        //Drop a pin on that location
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        map.addAnnotation(pin)
    }
}
