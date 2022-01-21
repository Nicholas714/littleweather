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

/*
 EXAMPLE WeatherResponse JSON
 {
    "coord":{
       "lon":-84.388,
       "lat":33.749
    },
    "weather":[
       {
          "id":500,
          "main":"Rain",
          "description":"light rain",
          "icon":"10d"
       }
    ],
    "base":"stations",
    "main":{
       "temp":276.96,
       "feels_like":274.88,
       "temp_min":274.91,
       "temp_max":280.81,
       "pressure":1020,
       "humidity":86
    },
    "visibility":10000,
    "wind":{
       "speed":2.24,
       "deg":306,
       "gust":6.26
    },
    "rain":{
       "1h":0.11
    },
    "clouds":{
       "all":100
    },
    "dt":1642707863,
    "sys":{
       "type":2,
       "id":2041852,
       "country":"US",
       "sunrise":1642682435,
       "sunset":1642719374
    },
    "timezone":-18000,
    "id":4180439,
    "name":"Atlanta",
    "cod":200
 }
 */
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
    let lon: Double
    let lat: Double
}

struct WeatherDetail: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct TemperatureDetail: Codable {
    let temp: Double
    let feels_like: Double
    let temp_min: Double
    let temp_max: Double
    let pressure: Int
    let humidity: Int
}

struct WindDetail: Codable {
    let speed: Double
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
        AF.request(iconRequest).responseString { iconResponseData in
            completion(iconResponseData.data)
        }
    }
    
}
