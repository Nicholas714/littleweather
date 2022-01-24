//
//  ViewController.swift
//  littleweather
//
//  Created by Nicholas Grana on 1/19/22.
//

import UIKit
import Firebase
import CoreLocation

class WeatherScrollViewController: UIViewController {
    
    let lm = CLLocationManager()
    
    var cityViews = [CityWeatherView]()
    
    @IBOutlet weak var citiesPageControl: UIPageControl!
    @IBOutlet weak var deleteCityButton: UIButton!
    @IBOutlet weak var addCityButton: UIButton!
    var citiesScrollView: UIScrollView!
    
    lazy var weather: WeatherAPI = {
        return WeatherAPI()
    }()
    
    var cityIndex: Int {
        return Int(citiesScrollView.contentOffset.x / view.frame.width)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.lm.delegate = self
        self.lm.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        self.lm.requestWhenInUseAuthorization()
        
        citiesPageControl.addTarget(self, action: #selector(pageChangedByUser(_:)), for: .valueChanged)
        
        citiesScrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        citiesScrollView.isPagingEnabled = true
        citiesScrollView.delegate = self
        citiesScrollView.showsHorizontalScrollIndicator = false
        view.addSubview(citiesScrollView)
        
        view.backgroundColor = .white
        view.bringSubviewToFront(citiesPageControl)
        view.bringSubviewToFront(deleteCityButton)
        view.bringSubviewToFront(addCityButton)

        deleteCityButton.isEnabled = cityViews.count > 1
        
        Database.database().reference().child("nick").observeSingleEvent(of: .value, with: { snapshot in
            if let id = snapshot.value as? Array<String?> {
                let cities = id.filter({ $0 != nil }) as! Array<String>
                self.setup(with: cities)
            }
        })
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
                print(error)
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
        let cityNames = cityViews.map { $0.cityName }
        Database.database().reference().child("nick").setValue(cityNames)
        deleteCityButton.isEnabled = cityViews.count > 1
    }
    
    func updateScrollViewCitiesSize() {
        citiesScrollView.contentSize = CGSize(width: view.frame.width * CGFloat(cityViews.count), height: view.frame.height)
        citiesPageControl.numberOfPages = cityViews.count
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
            
            if cityIndex + 1 >= cityViews.count {
                return
            }
            
            for i in cityIndex + 1..<cityViews.count {
                let cityView = cityViews[i]
                let newFrame = CGRect(x: cityView.frame.minX - citiesScrollView.frame.width, y: 0, width: self.citiesScrollView.frame.width, height: self.citiesScrollView.frame.height)
                cityView.frame = newFrame
            }
            
            self.updateScrollViewCitiesSize()
        }
    }
    
    @IBAction func addCity(_ sender: UIButton) {
        enterCityAlert()
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
                    if self.cityViews.isEmpty {
                        self.citiesScrollView.addSubview(cityView)
                        self.cityViews.append(cityView)
                    } else {
                        self.citiesScrollView.insertSubview(cityView, at: index)
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
            if let city = inputField.text?.replacingOccurrences(of: " ", with: "%20").trimmingCharacters(in: .whitespacesAndNewlines) {
                self.getWeatherResponse(forCity: city) { response, error in
                    if let _ = error {
                        self.presentError(text: "City not found!")
                    } else {
                        if let replacementIndex = replacementIndex {
                            self.cityViews[replacementIndex].weather = response
                            self.commitChanges()
                        } else {
                            let newCityIndex = self.cityIndex + 1
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
        weather.getWeather(for: city) { weatherResponse, error in
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
                print(error)
                completion(nil, error)
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
        if cityIndex < citiesScrollView.subviews.count {
            view.backgroundColor = citiesScrollView.subviews[cityIndex].backgroundColor
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
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        presentError(text: "Location manager failed. \(error.localizedDescription)")
    }
    
}
