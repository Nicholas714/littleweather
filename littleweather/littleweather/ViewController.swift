//
//  ViewController.swift
//  littleweather
//
//  Created by Nicholas Grana on 1/19/22.
//

import UIKit

class ViewController: UIViewController {

    var weather: WeatherAPI!
    var weatherResponse: WeatherResponse!
    
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var temperature: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        weather = WeatherAPI()
        
        weather.getWeather(for: "Mumbai") { weatherResponse, error in
            if let weatherResponse = weatherResponse {
                print(weatherResponse)
                self.weatherResponse = weatherResponse
                
                self.temperature.text = "\(self.weatherResponse.name) \(self.kelvinToFahr(kelvin: self.weatherResponse.main.temp))"
                print(self.weatherResponse.weather)
                self.weather.getWeatherIcon(id: weatherResponse.weather.first!.icon) { data in
                    if let data = data, let image = UIImage(data: data) {
                        self.mainImage.image = image
                    }
                }

            } else if let error = error {
                print(error)
                fatalError()
            }
        }
    }
 
    func kelvinToFahr(kelvin: Float) -> Float {
        return (kelvin - 273.15) * 9/5 + 32
    }
}

