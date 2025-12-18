//
//  WeatherModel.swift
//  AMF Schedule
//
//  Weather data model for widget display
//

import Foundation

/// Current weather conditions for widget display
struct WeatherData: Codable {
    let temperature: Double
    let temperatureHigh: Double
    let temperatureLow: Double
    let conditionCode: String
    let conditionDescription: String
    let humidity: Double
    let uvIndex: Int
    let windSpeed: Double
    let precipitationChance: Double
    let fetchedAt: Date
    let locationName: String?
    let sunrise: Date?
    let sunset: Date?
    let dailyForecast: [DailyForecast]?
    
    /// Temperature formatted with degree symbol (no decimal)
    var temperatureFormatted: String {
        "\(Int(round(temperature)))°"
    }
    
    /// High/Low formatted
    var highLowFormatted: String {
        "H:\(Int(round(temperatureHigh)))° L:\(Int(round(temperatureLow)))°"
    }
    
    /// Sunrise formatted
    var sunriseFormatted: String? {
        guard let sunrise = sunrise else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: sunrise)
    }
    
    /// Sunset formatted
    var sunsetFormatted: String? {
        guard let sunset = sunset else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: sunset)
    }
    
    /// Check if weather data is stale (older than 2 hours)
    var isStale: Bool {
        Date().timeIntervalSince(fetchedAt) > 7200 // 2 hours
    }
    
    /// SF Symbol name for weather condition
    var symbolName: String {
        WeatherCondition.symbol(for: conditionCode)
    }
    
    /// Get forecast for a specific date
    func forecast(for date: Date) -> DailyForecast? {
        let calendar = Calendar.current
        return dailyForecast?.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    /// Get tomorrow's forecast
    var tomorrowForecast: DailyForecast? {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return nil }
        return forecast(for: tomorrow)
    }
}

/// Daily weather forecast
struct DailyForecast: Codable, Identifiable {
    var id: Date { date }
    let date: Date
    let temperatureHigh: Double
    let temperatureLow: Double
    let conditionCode: String
    let precipitationChance: Double
    let sunrise: Date?
    let sunset: Date?
    
    var highFormatted: String { "\(Int(round(temperatureHigh)))°" }
    var lowFormatted: String { "\(Int(round(temperatureLow)))°" }
    var highLowFormatted: String { "H:\(Int(round(temperatureHigh)))° L:\(Int(round(temperatureLow)))°" }
    
    var symbolName: String {
        WeatherCondition.symbol(for: conditionCode)
    }
    
    var sunriseFormatted: String? {
        guard let sunrise = sunrise else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: sunrise)
    }
    
    var sunsetFormatted: String? {
        guard let sunset = sunset else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: sunset)
    }
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
}

/// Weather condition mapping to SF Symbols
enum WeatherCondition {
    static func symbol(for code: String) -> String {
        switch code.lowercased() {
        // Clear
        case "clear", "clearday", "clear-day":
            return "sun.max"
        case "clearnight", "clear-night":
            return "moon.stars"
            
        // Cloudy
        case "cloudy", "mostlycloudy", "mostly-cloudy":
            return "cloud"
        case "partlycloudy", "partly-cloudy", "partlycloudyday", "partly-cloudy-day":
            return "cloud.sun"
        case "partlycloudynight", "partly-cloudy-night":
            return "cloud.moon"
            
        // Rain
        case "rain", "drizzle", "lightrain":
            return "cloud.rain"
        case "heavyrain":
            return "cloud.heavyrain"
        case "showers", "scatteredshowers":
            return "cloud.sun.rain"
            
        // Thunderstorm
        case "thunderstorm", "thunderstorms", "tstorms":
            return "cloud.bolt.rain"
            
        // Snow
        case "snow", "lightsnow", "heavysnow":
            return "cloud.snow"
        case "sleet", "freezingrain":
            return "cloud.sleet"
        case "flurries":
            return "cloud.snow"
            
        // Fog/Haze
        case "fog", "haze", "mist":
            return "cloud.fog"
            
        // Wind
        case "wind", "windy", "breezy":
            return "wind"
            
        // Hot/Cold
        case "hot":
            return "sun.max.trianglebadge.exclamationmark"
        case "cold", "frigid":
            return "thermometer.snowflake"
            
        // Default
        default:
            return "cloud"
        }
    }
    
    /// Minimalist description for AMF voice
    static func description(for code: String) -> String {
        switch code.lowercased() {
        case "clear", "clearday", "clear-day":
            return "Clear"
        case "clearnight", "clear-night":
            return "Clear night"
        case "cloudy", "mostlycloudy", "mostly-cloudy":
            return "Overcast"
        case "partlycloudy", "partly-cloudy", "partlycloudyday", "partly-cloudy-day":
            return "Partly cloudy"
        case "partlycloudynight", "partly-cloudy-night":
            return "Partly cloudy"
        case "rain", "drizzle", "lightrain":
            return "Rain"
        case "heavyrain":
            return "Heavy rain"
        case "showers", "scatteredshowers":
            return "Showers"
        case "thunderstorm", "thunderstorms", "tstorms":
            return "Storms"
        case "snow", "lightsnow":
            return "Snow"
        case "heavysnow":
            return "Heavy snow"
        case "sleet", "freezingrain":
            return "Sleet"
        case "fog", "haze", "mist":
            return "Fog"
        case "wind", "windy", "breezy":
            return "Windy"
        default:
            return "Mixed"
        }
    }
}

/// Fallback weather data when service is unavailable
extension WeatherData {
    static var placeholder: WeatherData {
        WeatherData(
            temperature: 72,
            temperatureHigh: 78,
            temperatureLow: 65,
            conditionCode: "clear",
            conditionDescription: "Clear",
            humidity: 0.45,
            uvIndex: 5,
            windSpeed: 8,
            precipitationChance: 0,
            fetchedAt: Date(),
            locationName: "Los Angeles",
            sunrise: Calendar.current.date(bySettingHour: 6, minute: 45, second: 0, of: Date()),
            sunset: Calendar.current.date(bySettingHour: 17, minute: 30, second: 0, of: Date()),
            dailyForecast: nil
        )
    }
}
