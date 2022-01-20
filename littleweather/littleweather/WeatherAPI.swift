//
//  WeatherAPI.swift
//  littleweather
//
//  Created by Nicholas Grana on 1/19/22.
//

import Foundation
import Alamofire

struct WeatherErrorResponse: Codable {
    let cod: String
    let message: String
}

struct WeatherResponse: Codable {
    let coord: Coordinate
    let weather: [WeatherDetail]
    let base: String
    let main: TemperatureDetail
    let visibility: Int
    let wind: WindDetail
    let clouds: CloudDetail
    let dt: Int
    let sys: SysDetail
    let timezone: Int
    let id: Int
    let name: String
    let cod: Int
}

struct Coordinate: Codable {
    let lon: Float
    let lat: Float
}

struct WeatherDetail: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct Landmark: Codable {
    var name: String
    var foundingYear: Int
    var location: Coordinate
    var vantagePoints: [Coordinate]
    
    enum CodingKeys: String, CodingKey {
        case name = "title"
        case foundingYear = "founding_date"
        
        case location
        case vantagePoints
    }
}

struct TemperatureDetail: Codable {
    let temp: Float
    let feels_like: Float
    let temp_min: Float
    let temp_max: Float
    let pressure: Int
    let humidity: Int
}

struct WindDetail: Codable {
    let speed: Float
    let deg: Int
}

struct CloudDetail: Codable {
    let all: Int
}

struct SysDetail: Codable {
    let type: Int
    let id: Int
    let country: String
    let sunrise: Int
    let sunset: Int
}

class WeatherAPI {
    
    let weatherGETPrefix = "https://api.openweathermap.org/data/2.5/weather?q="
    let appId = "429d0f2a08ddbcc5c12dba22214c7aba"
    
    let iconGETPrefix = "https://openweathermap.org/img/wn/"
    
    func getWeather(for city: String, completion: @escaping (WeatherResponse?, Error?) -> ()) {
        let requestLink = "\(weatherGETPrefix)\(city)&appid=\(appId)"

        AF.request(requestLink).responseString { weatherResponseData in
            print(weatherResponseData.value!)
            if let responseData = weatherResponseData.data {
                do {
                    let decoder = JSONDecoder()
                    let weatherResponse = try decoder.decode(WeatherResponse.self, from: responseData)
                    completion(weatherResponse, nil)
                } catch let error {
                    let decoder = JSONDecoder()
                    let weatherErrorResponse = try? decoder.decode(WeatherErrorResponse.self, from: responseData)
                    if let weatherErrorResponse = weatherErrorResponse {
                        completion(nil, NSError(domain: "littleweather", code: Int(weatherErrorResponse.cod)!, userInfo: [NSLocalizedDescriptionKey : weatherErrorResponse.message]))
                    } else {
                        completion(nil, error)
                    }
                }
            }
        }
    }
    
    func getWeatherIcon(id icon: String, completion: @escaping (Data?) -> ()) {
        let iconRequest = "\(iconGETPrefix)\(icon)@2x.png"
        print(iconRequest)
        AF.request(iconRequest).responseString { iconResponseData in
            completion(iconResponseData.data)
        }
    }
    
}
