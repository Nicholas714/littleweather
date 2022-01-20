//
//  ViewController.swift
//  littleweather
//
//  Created by Nicholas Grana on 1/19/22.
//

import UIKit

class WeatherScrollViewController: UIViewController {
        
    let cities = ["atlanta", "florida", "mumbai", "japan", "Chicago", "seattle", "new%20york%20city"]
    
    @IBOutlet weak var citiesPageControl: UIPageControl!
    var citiesScrollView: UIScrollView!
    
    lazy var weather: WeatherAPI = {
        return WeatherAPI()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        citiesPageControl.numberOfPages = cities.count

        citiesScrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        citiesScrollView.contentSize = CGSize(width: view.frame.width * CGFloat(cities.count), height: view.frame.height)
        citiesScrollView.isPagingEnabled = true
        citiesScrollView.delegate = self
        citiesScrollView.showsHorizontalScrollIndicator = false
        view.addSubview(citiesScrollView)
        
        for (i, city) in cities.enumerated() {
            let cityView = Bundle.main.loadNibNamed("CityWeatherView", owner: self, options: nil)?.first as! CityWeatherView
            cityView.frame = CGRect(x: view.frame.width * CGFloat(i), y: 0, width: view.frame.width, height: view.frame.height)
            citiesScrollView.addSubview(cityView)
            
            weather.getWeather(for: city) { weatherResponse, error in
                if let weatherResponse = weatherResponse {
                    cityView.weather = weatherResponse
                    
                    self.weather.getWeatherIcon(id: weatherResponse.weather.first!.icon) { data in
                        if let data = data, let image = UIImage(data: data) {
                            cityView.mainImage.image = image
                        }
                    }

                } else if let error = error {
                    print(error)
                }
            }
        }
        
        view.backgroundColor = .white
        
        view.bringSubviewToFront(citiesPageControl)
    }
}

extension WeatherScrollViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        citiesPageControl.currentPage = Int(scrollView.contentOffset.x / view.frame.width)
    }
    
}
