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
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var weatherTitleLabel: UILabel!
    
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
    
    var temperature: Measurement<UnitTemperature>? {
        didSet {
            if let temperature = temperature {
                temperatureLabel.text = wholeNumberMeasurementFormatter.string(from: temperature)
                backgroundColor = UIColor.colorFor(temperature: temperature)
            } else {
                temperatureLabel.text = "--"
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
            cityLabel.text = cityName ?? "--"
        }
    }
    
    var weather: WeatherResponse? {
        didSet {
            if let weather = weather {
                temperature = Measurement(value: weather.main.temp, unit: .kelvin)
                cityName = weather.name
                weatherTitle = weather.weather.first?.description
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
    
}
