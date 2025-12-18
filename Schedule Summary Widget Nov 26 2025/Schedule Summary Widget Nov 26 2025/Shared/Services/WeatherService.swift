//
//  WeatherService.swift
//  AMF Schedule
//
//  WeatherKit integration for widget weather display
//

import Foundation
import WeatherKit
import CoreLocation

/// Weather service using WeatherKit with location support
final class WeatherService: NSObject {
    
    // MARK: - Configuration
    
    /// Fallback coordinates (Los Angeles)
    private let fallbackLatitude = 34.07845
    private let fallbackLongitude = -118.25317
    
    /// Use dynamic geolocation
    private let useDynamicLocation = true
    
    // MARK: - Singleton
    
    static let shared = WeatherService()
    
    // MARK: - Dependencies
    
    private let weatherService = WeatherKit.WeatherService.shared
    private let locationManager = CLLocationManager()
    private let store = AppGroupStore.shared
    
    private var currentLocation: CLLocation?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    #if DEBUG
    private let debugLogging = true
    #else
    private let debugLogging = false
    #endif
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    private func log(_ message: String) {
        if debugLogging {
            print("[WeatherService] \(message)")
        }
    }
    
    // MARK: - Location
    
    /// Request location permission
    func requestLocationPermission() {
        let status = locationManager.authorizationStatus
        print("[WeatherService] Current location authorization: \(status.rawValue)")
        
        if status == .notDetermined {
            print("[WeatherService] Requesting location permission...")
            locationManager.requestWhenInUseAuthorization()
        } else if status == .denied || status == .restricted {
            print("[WeatherService] ⚠️ Location permission denied or restricted")
        } else {
            print("[WeatherService] ✓ Location already authorized")
        }
    }
    
    /// Get current location or fallback
    private func getLocation() async throws -> CLLocation {
        let status = locationManager.authorizationStatus
        print("[WeatherService] 📍 Location auth status: \(status.rawValue)")
        
        #if os(iOS)
        let isAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
        #elseif os(macOS)
        let isAuthorized = status == .authorizedAlways
        #else
        let isAuthorized = status == .authorizedAlways
        #endif
        
        if isAuthorized {
            // First try cached location if recent (within 10 minutes)
            if let location = locationManager.location {
                let age = Date().timeIntervalSince(location.timestamp)
                if age < 600 { // 10 minutes
                    print("[WeatherService] 📍 Using cached location (age: \(Int(age))s): \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    return location
                }
            }
            
            // Request fresh location
            print("[WeatherService] 📍 Requesting fresh location...")
            locationManager.startUpdatingLocation()
            
            return try await withCheckedThrowingContinuation { continuation in
                self.locationContinuation = continuation
                
                // Set a timeout
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                    if self.locationContinuation != nil {
                        print("[WeatherService] 📍 Location timeout, using last known or fallback")
                        self.locationManager.stopUpdatingLocation()
                        
                        if let lastLocation = self.locationManager.location {
                            self.locationContinuation?.resume(returning: lastLocation)
                        } else {
                            let fallback = CLLocation(latitude: self.fallbackLatitude, 
                                                     longitude: self.fallbackLongitude)
                            self.locationContinuation?.resume(returning: fallback)
                        }
                        self.locationContinuation = nil
                    }
                }
            }
        } else if status == .notDetermined {
            print("[WeatherService] 📍 Location not determined, requesting permission...")
            locationManager.requestWhenInUseAuthorization()
            // Use fallback for now
        } else {
            print("[WeatherService] 📍 Location denied/restricted, using fallback")
        }
        
        // Use fallback
        print("[WeatherService] 📍 Using fallback location: LA")
        return CLLocation(latitude: fallbackLatitude, longitude: fallbackLongitude)
    }
    
    // MARK: - Weather Fetching
    
    /// Fetch current weather with extended forecast
    func fetchWeather() async throws -> WeatherData {
        print("[WeatherService] 🌤️ Starting weather fetch...")
        
        let location: CLLocation
        do {
            location = try await getLocation()
            print("[WeatherService] 📍 Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        } catch {
            print("[WeatherService] ❌ Location error: \(error)")
            throw error
        }
        
        do {
            print("[WeatherService] 🌤️ Calling WeatherKit API...")
            let weather = try await weatherService.weather(for: location)
            print("[WeatherService] ✅ WeatherKit returned data!")
            
            let current = weather.currentWeather
            let todayForecast = weather.dailyForecast.first
            
            // Convert to Fahrenheit explicitly
            let tempF = current.temperature.converted(to: .fahrenheit).value
            let highF = todayForecast?.highTemperature.converted(to: .fahrenheit).value ?? tempF + 5
            let lowF = todayForecast?.lowTemperature.converted(to: .fahrenheit).value ?? tempF - 5
            
            print("[WeatherService] 🌡️ Temperature: \(Int(tempF))°F (High: \(Int(highF))°F, Low: \(Int(lowF))°F)")
            
            // Build daily forecast (up to 14 days for next week view)
            var dailyForecasts: [DailyForecast] = []
            for dayForecast in weather.dailyForecast.prefix(14) {
                let forecast = DailyForecast(
                    date: dayForecast.date,
                    temperatureHigh: dayForecast.highTemperature.converted(to: .fahrenheit).value,
                    temperatureLow: dayForecast.lowTemperature.converted(to: .fahrenheit).value,
                    conditionCode: dayForecast.condition.rawValue,
                    precipitationChance: dayForecast.precipitationChance,
                    sunrise: dayForecast.sun.sunrise,
                    sunset: dayForecast.sun.sunset
                )
                dailyForecasts.append(forecast)
            }
            print("[WeatherService] 📅 Got \(dailyForecasts.count) day forecast")
            
            let weatherData = WeatherData(
                temperature: tempF,
                temperatureHigh: highF,
                temperatureLow: lowF,
                conditionCode: current.condition.rawValue,
                conditionDescription: WeatherCondition.description(for: current.condition.rawValue),
                humidity: current.humidity,
                uvIndex: Int(current.uvIndex.value),
                windSpeed: current.wind.speed.value,
                precipitationChance: todayForecast?.precipitationChance ?? 0,
                fetchedAt: Date(),
                locationName: await getLocationName(for: location),
                sunrise: todayForecast?.sun.sunrise,
                sunset: todayForecast?.sun.sunset,
                dailyForecast: dailyForecasts
            )
            
            // Cache weather data
            store.saveWeather(weatherData)
            
            print("[WeatherService] ✅ Weather: \(weatherData.temperatureFormatted), \(weatherData.conditionDescription)")
            if let sunset = weatherData.sunsetFormatted {
                print("[WeatherService] 🌅 Sunset: \(sunset)")
            }
            
            return weatherData
            
        } catch {
            print("[WeatherService] ❌ WeatherKit ERROR: \(error)")
            print("[WeatherService] ❌ Error type: \(type(of: error))")
            print("[WeatherService] ❌ Error description: \(error.localizedDescription)")
            
            // Check for specific errors
            if let nsError = error as NSError? {
                print("[WeatherService] ❌ NSError domain: \(nsError.domain)")
                print("[WeatherService] ❌ NSError code: \(nsError.code)")
                print("[WeatherService] ❌ NSError userInfo: \(nsError.userInfo)")
            }
            
            // Try to return cached weather
            if let cached = store.loadWeather() {
                print("[WeatherService] 📦 Returning cached weather")
                return cached
            }
            
            // Return placeholder
            print("[WeatherService] ⚠️ Returning placeholder weather")
            return WeatherData.placeholder
        }
    }
    
    /// Get cached weather or fetch new
    func getWeather() async -> WeatherData {
        print("[WeatherService] Getting weather...")
        
        // Check cache first
        if let cached = store.loadWeather(), !cached.isStale {
            print("[WeatherService] ✓ Using cached weather: \(cached.temperatureFormatted)")
            return cached
        }
        
        // Fetch fresh
        print("[WeatherService] Cache stale or missing, fetching fresh...")
        do {
            let weather = try await fetchWeather()
            print("[WeatherService] ✓ Fetched: \(weather.temperatureFormatted)")
            return weather
        } catch {
            print("[WeatherService] ⚠️ Failed to fetch weather: \(error)")
            let fallback = store.loadWeather() ?? WeatherData.placeholder
            print("[WeatherService] Using fallback: \(fallback.temperatureFormatted)")
            return fallback
        }
    }
    
    // MARK: - Reverse Geocoding
    
    private func getLocationName(for location: CLLocation) async -> String? {
        // Note: CLGeocoder is deprecated in macOS 26.0, but still functional
        // TODO: Migrate to MapKit's MKReverseGeocodingRequest in the future
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return placemarks.first?.locality
        } catch {
            return nil
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        
        if let location = locations.last {
            print("[WeatherService] 📍 Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            currentLocation = location
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log("Location error: \(error)")
        
        // Return fallback location on error
        let fallback = CLLocation(latitude: fallbackLatitude, longitude: fallbackLongitude)
        locationContinuation?.resume(returning: fallback)
        locationContinuation = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        log("Location authorization: \(manager.authorizationStatus.rawValue)")
    }
}

