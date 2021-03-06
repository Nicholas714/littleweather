//
//  ViewController.swift
//  littleweather
//
//  Created by Nicholas Grana on 1/19/22.
//

import UIKit
import Firebase
import CoreLocation
import os

class WeatherScrollViewController: UIViewController {
    
    lazy var logger: Logger = {
        return Logger(subsystem: Bundle.main.bundleIdentifier ?? "dev.grana.littleweather", category: "application")
    }()
    
    let lm = CLLocationManager()
    
    var databaseID: String? {
        didSet {
            self.setupCitiesScrollView()
        }
    }
    
    var cityViews = [CityWeatherView]()
    
    @IBOutlet weak var citiesPageControl: UIPageControl!
    @IBOutlet weak var deleteCityButton: UIButton!
    @IBOutlet weak var addCityButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    #if !DEBUG
    var delegate: WeatherAuthenticationDelegate?
    #endif
    var citiesScrollView: UIScrollView!
    
    lazy var weather: WeatherAPI = {
        return WeatherAPI()
    }()
    
    var cityIndex: Int {
        return Int(citiesScrollView.contentOffset.x / view.frame.width)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func setupCitiesScrollView() {
        self.lm.delegate = self
        self.lm.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        self.lm.requestWhenInUseAuthorization()
        
        citiesPageControl.addTarget(self, action: #selector(pageChangedByUser(_:)), for: .valueChanged)
        
        citiesScrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        citiesScrollView.isPagingEnabled = true
        citiesScrollView.delegate = self
        citiesScrollView.showsHorizontalScrollIndicator = false
        citiesScrollView.backgroundColor = .warm0
        view.addSubview(citiesScrollView)
        
        view.backgroundColor = .white
        view.bringSubviewToFront(citiesPageControl)
        view.bringSubviewToFront(deleteCityButton)
        view.bringSubviewToFront(addCityButton)
        view.bringSubviewToFront(logoutButton)

        deleteCityButton.isEnabled = cityViews.count > 1
        
        if let databaseID = databaseID {
            Database.database().reference().child(databaseID).observeSingleEvent(of: .value, with: { snapshot in
                if let id = snapshot.value as? Array<String?> {
                    let cities = id.filter({ $0 != nil }) as! Array<String>
                    print("cities: \(cities)")
                    self.setup(with: cities)
                }
            })
        }
    }
    
    func create(city: String, at index: Int, withCompletion completion: @escaping (CityWeatherView?) -> ()) {
        let cityView = Bundle.main.loadNibNamed("CityWeatherView", owner: self, options: nil)?.first as! CityWeatherView
        cityView.frame = CGRect(x: view.frame.width * CGFloat(index), y: 0, width: view.frame.width, height: view.frame.height)
        cityView.renameCity = { [self] city in
            enterCityAlert(replacementIndex: index)
        }
        
        getWeatherResponse(forCity: city) { response, error in
            if let error = error {
                completion(nil)
                self.logger.error("Failed to get error weather response for \(city): \(error.localizedDescription)")
            } else {
                cityView.weather = response
                completion(cityView)
            }
        } imageCompletion: { image in
            if let image = image {
                cityView.mainImage.image = image
            }
        }
    }
    
    func commitChanges() {
        if let databaseID = databaseID {
            let cityNames = cityViews.map { $0.cityName }
            Database.database().reference().child(databaseID).setValue(cityNames)
            deleteCityButton.isEnabled = cityViews.count > 1
        }
    }
    
    func updateScrollViewCitiesSize() {
        citiesScrollView.contentSize = CGSize(width: view.frame.width * CGFloat(cityViews.count), height: view.frame.height)
        citiesPageControl.numberOfPages = cityViews.count
        
        for i in 0..<cityViews.count {
            // recalcualte all positions
            let cityView = cityViews[i]
            let newFrame = CGRect(x: CGFloat(i) * self.citiesScrollView.frame.width, y: 0, width: self.citiesScrollView.frame.width, height: self.citiesScrollView.frame.height)
            cityView.frame = newFrame
        }
    }
    
    func setup(with cities: [String]) {
        for (i, city) in cities.enumerated() {
            create(city: city, at: i) { cityView in
                if let cityView = cityView {
                    self.citiesScrollView.addSubview(cityView)
                    self.cityViews.append(cityView)
                    self.updateScrollViewCitiesSize()
                    self.commitChanges()
                }
            }
        }
    }
    
    @objc func pageChangedByUser(_ pageControl: UIPageControl) {
        let x = CGFloat(pageControl.currentPage) * view.frame.width
        citiesScrollView.setContentOffset(CGPoint(x: x, y: 0), animated: false)
    }
    
    @IBAction func deleteCity(_ sender: UIButton) {
        if (cityViews.count > 1) {
            cityViews[cityIndex].removeFromSuperview()
            cityViews.remove(at: cityIndex)
            
            self.commitChanges()
            self.updateScrollViewCitiesSize()
        }
    }
    
    @IBAction func addCity(_ sender: UIButton) {
        enterCityAlert()
    }
    
    @IBAction func logout(_ sender: UIButton) {
        #if !DEBUG
        delegate?.signOut()
        #endif
    }
    
    func insert(city: String, at index: Int) {
        var alreadyAddedCityIndex: Int? = nil
        for (i, cityView) in self.cityViews.enumerated() {
            if let compName = cityView.cityName, city.caseInsensitiveCompare(compName) == .orderedSame {
                alreadyAddedCityIndex = i
            }
        }
        
        if let index = alreadyAddedCityIndex {
            let newCityPoint = CGPoint(x: CGFloat(index) * self.citiesScrollView.frame.width, y: 0)
            self.citiesScrollView.setContentOffset(newCityPoint, animated: false)
        } else {
            self.create(city: city, at: index) { cityView in
                if let cityView = cityView {
                    self.citiesScrollView.addSubview(cityView)
                    if self.cityViews.isEmpty {
                        self.cityViews.append(cityView)
                    } else {
                        self.cityViews.insert(cityView, at: index)
                    }
                    self.updateScrollViewCitiesSize()
                    
                    let newCityPoint = CGPoint(x: CGFloat(index) * self.citiesScrollView.frame.width, y: 0)
                    self.citiesScrollView.setContentOffset(newCityPoint, animated: false)
                    self.commitChanges()
                }
            }
        }
    }
    
    func enterCityAlert(replacementIndex: Int? = nil) {
        let alert = UIAlertController(title: "Enter City", message: nil, preferredStyle: .alert)
        
        var inputField: UITextField!
        
        alert.addTextField { field in
            inputField = field
            field.placeholder = "City"
        }
        
        let currentLocation = UIAlertAction(title: "Current Location", style: .default) { action in
            self.lm.requestWhenInUseAuthorization()
            self.lm.requestAlwaysAuthorization()
            self.lm.requestLocation()
        }
        
        let done = UIAlertAction(title: "Done", style: .default) { action in
            if let city = inputField.text {
                self.getWeatherResponse(forCity: city) { response, error in
                    if let error = error {
                        self.logger.error("Failed to get error weather response for \(city): \(error.localizedDescription)")
                        self.presentError(text: "City not found!")
                    } else {
                        if let replacementIndex = replacementIndex {
                            self.cityViews[replacementIndex].weather = response
                            self.commitChanges()
                        } else {
                            let newCityIndex = self.cityViews.isEmpty ? 0 : self.cityIndex + 1
                            self.insert(city: city, at: newCityIndex)
                        }
                    }
                } imageCompletion: { image in
                    if let image = image, let replacementIndex = replacementIndex {
                        self.cityViews[replacementIndex].mainImage.image = image
                    }
                }
            }
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
            alert.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(currentLocation)
        alert.addAction(done)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    func getWeatherResponse(forCity city: String, completion: @escaping ((WeatherResponse?, Error?) -> ()), imageCompletion: @escaping ((UIImage?) -> ())) {
        let urlName = city.replacingOccurrences(of: " ", with: "%20").trimmingCharacters(in: .whitespacesAndNewlines)
        weather.getWeather(for: urlName) { weatherResponse, error in
            if let weatherResponse = weatherResponse {
                completion(weatherResponse, nil)
                
                self.weather.getWeatherIcon(id: weatherResponse.weather.first!.icon) { data in
                    if let data = data, let image = UIImage(data: data) {
                        imageCompletion(image)
                    } else {
                        imageCompletion(nil)
                    }
                }
            } else if let error = error {
                completion(nil, error)
                imageCompletion(nil)
            } else {
                completion(nil, nil)
                imageCompletion(nil)
            }
        }
    }
    
    func presentError(text: String) {
        let alert = UIAlertController(title: "Error", message: text, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}

extension WeatherScrollViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        citiesPageControl.currentPage = cityIndex
        if cityIndex < cityViews.count {
            let currentBackgroundColor = cityViews[cityIndex].backgroundColor
            view.backgroundColor = currentBackgroundColor
            scrollView.backgroundColor = currentBackgroundColor
        }
    }
    
}

extension WeatherScrollViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.first {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(currentLocation) { placemarks, error in
                if let placemark = placemarks?.first, let city = placemark.locality {
                    self.insert(city: city, at: self.cityIndex + 1)
                }
                if let error = error {
                    self.logger.error("Failed to get placemark \(error.localizedDescription)")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Failed to placemark \(error.localizedDescription)")
        presentError(text: "Location manager failed. \(error.localizedDescription)")
    }
    
}
