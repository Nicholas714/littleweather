//
//  CityWeatherView.swift
//  littleweather
//
//  Created by Nicholas Grana on 1/20/22.
//

import UIKit

class CityWeatherView: UIView {
    
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var cityButton: UIButton!
    @IBOutlet weak var weatherTitleLabel: UILabel!
    @IBOutlet weak var highTempLabel: UILabel!
    @IBOutlet weak var lowTempLabel: UILabel!
    @IBOutlet weak var sunriseLabel: UILabel!
    @IBOutlet weak var sunsetLabel: UILabel!
    
    var renameCity: ((String?) -> ())?
    
    lazy var wholeNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.numberStyle = .none
        
        return formatter
    }()
    
    lazy var wholeNumberMeasurementFormatter: MeasurementFormatter = {
        let measureFormatter = MeasurementFormatter()
        measureFormatter.numberFormatter = wholeNumberFormatter
        return measureFormatter
    }()
    
    lazy var unixTimestampDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter
    }()
    
    var temperature: Measurement<UnitTemperature>? {
        didSet {
            if let temperature = temperature {
                temperatureLabel.text = wholeNumberMeasurementFormatter.string(from: temperature)
            } else {
                temperatureLabel.text = "--"
            }
        }
    }
    
    var highTemperature: Measurement<UnitTemperature>? {
        didSet {
            if let highTemperature = highTemperature {
                highTempLabel.text = "High: \( wholeNumberMeasurementFormatter.string(from: highTemperature))"
            } else {
                highTempLabel.text = "High: --"
            }
        }
    }
    
    var lowTemperature: Measurement<UnitTemperature>? {
        didSet {
            if let lowTemperature = lowTemperature {
                lowTempLabel.text = "Low: \( wholeNumberMeasurementFormatter.string(from: lowTemperature))"
            } else {
                lowTempLabel.text = "Low: --"
            }
        }
    }
    
    var sunrise: Date? {
        didSet {
            if let sunrise = sunrise {
                sunriseLabel.text = "Sunrise: \( unixTimestampDateFormatter.string(from: sunrise))"
            } else {
                sunriseLabel.text = "Sunrise: --"
            }
        }
    }
    
    var sunset: Date? {
        didSet {
            if let sunset = sunset {
                sunsetLabel.text = "Sunset: \( unixTimestampDateFormatter.string(from: sunset))"
            } else {
                sunsetLabel.text = "Sunset: --"
            }
        }
    }

    var weatherTitle: String? {
        didSet {
            weatherTitleLabel.text = weatherTitle?.capitalized
        }
    }

    var cityName: String? {
        didSet {
            cityButton.setTitle(cityName ?? "--", for: .normal)
        }
    }
    
    var weather: WeatherResponse? {
        didSet {
            if let weather = weather {
                temperature = Measurement(value: weather.main.temp, unit: .kelvin)
                highTemperature = Measurement(value: weather.main.temp_max, unit: .kelvin)
                lowTemperature = Measurement(value: weather.main.temp_min, unit: .kelvin)
                sunrise = Date(timeIntervalSince1970: TimeInterval(weather.sys.sunrise))
                sunset = Date(timeIntervalSince1970: TimeInterval(weather.sys.sunset))
                cityName = weather.name
                weatherTitle = weather.weather.first?.description
                
                backgroundColor = UIColor.colorFor(temperature: temperature!, cloudsPercent: CGFloat(weather.clouds.all))
            }
        }
    }
    
    init(weather: WeatherResponse) {
        self.weather = weather

        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        weather = nil
        
        super.init(coder: coder)
    }
    
    @IBAction func renameCity(_ button: UIButton) {
        if let renameCity = renameCity {
            renameCity(cityName)
        }
    }
    
}
