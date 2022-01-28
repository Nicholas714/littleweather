//
//  CityWeatherView.swift
//  littleweather
//
//  Created by Nicholas Grana on 1/20/22.
//

import UIKit

struct TemperatureRange {
    let low: Measurement<UnitTemperature>
    let high: Measurement<UnitTemperature>
}

class CityWeatherView: UIView {
    
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var cityButton: UIButton!
    @IBOutlet weak var weatherTitleLabel: UILabel!
    @IBOutlet weak var highLowTemp: UILabel!
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
    
    var temperatureRange: TemperatureRange? {
        didSet {
            if let temperatureRange = temperatureRange {
                highLowTemp.text = "H: \(wholeNumberMeasurementFormatter.string(from: temperatureRange.high)) L: \(wholeNumberMeasurementFormatter.string(from: temperatureRange.low))"
            } else {
                highLowTemp.text = "H: -- L: --"
            }
        }
    }
    
    var sunrise: Date? {
        didSet {
            if let sunrise = sunrise {
                sunriseLabel.text = "\(unixTimestampDateFormatter.string(from: sunrise))"
            } else {
                sunriseLabel.text = "--"
            }
        }
    }
    
    var sunset: Date? {
        didSet {
            if let sunset = sunset {
                sunsetLabel.text = "\(unixTimestampDateFormatter.string(from: sunset))"
            } else {
                sunsetLabel.text = "--"
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
                temperatureRange = TemperatureRange(low: Measurement(value: weather.main.temp_min, unit: .kelvin), high: Measurement(value: weather.main.temp_max, unit: .kelvin))
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
