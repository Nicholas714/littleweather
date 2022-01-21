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
    
    var temperature: Measurement<UnitTemperature>? {
        didSet {
            if let temperature = temperature {
                temperatureLabel.text = wholeNumberMeasurementFormatter.string(from: temperature)
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
            cityButton.setTitle(cityName ?? "--", for: .normal)
        }
    }
    
    var weather: WeatherResponse? {
        didSet {
            if let weather = weather {
                temperature = Measurement(value: weather.main.temp, unit: .kelvin)
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
