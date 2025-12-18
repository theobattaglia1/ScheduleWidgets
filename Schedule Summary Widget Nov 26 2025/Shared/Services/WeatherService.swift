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
        if useDynamicLocation {
            let status = locationManager.authorizationStatus
            
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                // Try to get current location
                if let location = locationManager.location {
                    log("Using current location: \(location.coordinate)")
                    return location
                }
                
                // Request location update
                return try await withCheckedThrowingContinuation { continuation in
                    self.locationContinuation = continuation
                    locationManager.requestLocation()
                }
            }
        }
        
        // Use fallback
        log("Using fallback location")
        return CLLocation(latitude: fallbackLatitude, longitude: fallbackLongitude)
    }
    
    // MARK: - Weather Fetching
    
    /// Fetch current weather
    func fetchWeather() async throws -> WeatherData {
        let location = try await getLocation()
        
        do {
            let weather = try await weatherService.weather(for: location)
            
            let current = weather.currentWeather
            let daily = weather.dailyForecast.first
            
            let weatherData = WeatherData(
                temperature: current.temperature.value,
                temperatureHigh: daily?.highTemperature.value ?? current.temperature.value + 5,
                temperatureLow: daily?.lowTemperature.value ?? current.temperature.value - 5,
                conditionCode: current.condition.rawValue,
                conditionDescription: WeatherCondition.description(for: current.condition.rawValue),
                humidity: current.humidity,
                uvIndex: Int(current.uvIndex.value),
                windSpeed: current.wind.speed.value,
                precipitationChance: daily?.precipitationChance ?? 0,
                fetchedAt: Date(),
                locationName: await getLocationName(for: location)
            )
            
            // Cache weather data
            store.saveWeather(weatherData)
            
            log("Weather fetched: \(weatherData.temperatureFormatted), \(weatherData.conditionDescription)")
            
            return weatherData
            
        } catch {
            log("⚠️ WeatherKit error: \(error)")
            log("⚠️ Error details: \(String(describing: error))")
            
            // Try to return cached weather
            if let cached = store.loadWeather() {
                log("Returning cached weather")
                return cached
            }
            
            // Return placeholder
            log("Returning placeholder weather")
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
        if let location = locations.first {
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

