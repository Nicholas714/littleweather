//
//  ViewController.swift
//  littleweather
//
//  Created by Nicholas Grana on 1/19/22.
//

import UIKit
import Firebase

class WeatherScrollViewController: UIViewController {
    
    var cities = [String]() {
        didSet {
            deleteCityButton.isEnabled = cities.count > 1
            Database.database().reference().child("nick").setValue(cities)
            setup(with: cities)
        }
    }
    
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

        deleteCityButton.isEnabled = cities.count > 1
        
        Database.database().reference().child("nick").observeSingleEvent(of: .value, with: { snapshot in
            if let id = snapshot.value as? Array<String?> {
                self.cities = id.filter({ $0 != nil }) as! Array<String>
            }
        })
    }
    
    func setup(with cities: [String]) {
        citiesScrollView.contentSize = CGSize(width: view.frame.width * CGFloat(cities.count), height: view.frame.height)
        citiesScrollView.subviews.forEach({ $0.removeFromSuperview() })
        citiesPageControl.numberOfPages = cities.count
        
        for (i, city) in cities.enumerated() {
            createCityView(index: i, city: city) { cityWeatherView in
                if let weatherCity = cityWeatherView {
                    self.citiesScrollView.insertSubview(weatherCity, at: i)
                }
            }
        }
    }
    
    @objc func pageChangedByUser(_ pageControl: UIPageControl) {
        let x = CGFloat(pageControl.currentPage) * view.frame.width
        citiesScrollView.setContentOffset(CGPoint(x: x, y: 0), animated: false)
    }
    
    @IBAction func deleteCity(_ sender: UIButton) {
        if (cityIndex < cities.count) {
            cities.remove(at: cityIndex)
        }
    }
    
    @IBAction func addCity(_ sender: UIButton) {
        enterCityAlert()
    }
    
    func enterCityAlert(replaceCity: String? = nil) {
        let alert = UIAlertController(title: "Enter City", message: nil, preferredStyle: .alert)
        
        var inputField: UITextField!
        
        alert.addTextField { field in
            inputField = field
            field.placeholder = "City"
        }
        
        let done = UIAlertAction(title: "Done", style: .default) { action in
            if let city = inputField.text?.replacingOccurrences(of: " ", with: "%20") {
                self.createCityView(index: self.cityIndex, city: city) { cityWeatherView in
                    if let _ = cityWeatherView {
                        if let replaceCity = replaceCity {
                            if let replaceIndex = self.cities.firstIndex(of: replaceCity) {
                                self.cities[replaceIndex] = city
                            }
                        } else {
                            self.cities.insert(city, at: self.cityIndex + 1)
                        }
                    } else {
                        self.presentError(text: "City not found!")
                    }
                }
            }
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
            alert.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(done)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    func createCityView(index: Int, city: String, completion: @escaping (CityWeatherView?) -> ()) {
        let cityView = Bundle.main.loadNibNamed("CityWeatherView", owner: self, options: nil)?.first as! CityWeatherView
        cityView.frame = CGRect(x: view.frame.width * CGFloat(index), y: 0, width: view.frame.width, height: view.frame.height)
        cityView.renameCity = { [self] city in
            enterCityAlert(replaceCity: city)
        }
        
        weather.getWeather(for: city) { weatherResponse, error in
            if let weatherResponse = weatherResponse {
                cityView.weather = weatherResponse
                
                self.weather.getWeatherIcon(id: weatherResponse.weather.first!.icon) { data in
                    if let data = data, let image = UIImage(data: data) {
                        cityView.mainImage.image = image
                    }
                    
                    completion(cityView)
                }

            } else if let error = error {
                print(error)
                completion(nil)
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
