//
//  WeatherClusterView.swift
//  AMFScheduleWidget
//
//  Minimalist weather display component for widgets
//

import SwiftUI

// Note: Color.init(hex:) is defined in AMFScheduleWidget.swift
// Note: WidgetTheme is defined in WidgetTheme.swift

struct WeatherClusterView: View {
    let weather: WeatherData?
    let size: WeatherClusterSize
    var theme: WidgetTheme = .classic
    
    enum WeatherClusterSize {
        case small
        case medium
        case large
        case detailed  // For Today view with sunset
    }
    
    var body: some View {
        if let weather = weather {
            switch size {
            case .small:
                smallView(weather)
            case .medium:
                mediumView(weather)
            case .large:
                largeView(weather)
            case .detailed:
                detailedView(weather)
            }
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Small (just temp + icon)
    
    private func smallView(_ weather: WeatherData) -> some View {
        HStack(spacing: 4) {
            Image(systemName: weather.symbolName)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(theme.primaryTextColor.color)
            
            Text(weather.temperatureFormatted)
                .font(.custom("HelveticaNeue", size: 12))
                .foregroundColor(theme.primaryTextColor.color)
        }
    }
    
    // MARK: - Medium (temp + icon + condition)
    
    private func mediumView(_ weather: WeatherData) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: weather.symbolName)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(theme.primaryTextColor.color)
                
                Text(weather.temperatureFormatted)
                    .font(.custom("HelveticaNeue-Medium", size: 16))
                    .foregroundColor(theme.primaryTextColor.color)
            }
            
            Text(weather.conditionDescription)
                .font(.custom("HelveticaNeue", size: 10))
                .foregroundColor(theme.secondaryTextColor.color)
        }
    }
    
    // MARK: - Large (full weather cluster)
    
    private func largeView(_ weather: WeatherData) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: weather.symbolName)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(theme.primaryTextColor.color)
                
                Text(weather.temperatureFormatted)
                    .font(.custom("HelveticaNeue-Medium", size: 20))
                    .foregroundColor(theme.primaryTextColor.color)
            }
            
            Text(weather.conditionDescription)
                .font(.custom("HelveticaNeue", size: 11))
                .foregroundColor(theme.secondaryTextColor.color)
            
            Text(weather.highLowFormatted)
                .font(.custom("HelveticaNeue", size: 10))
                .foregroundColor(theme.secondaryTextColor.color.opacity(0.8))
        }
    }
    
    // MARK: - Detailed (Today view with sunset) - 3 lines max
    
    private func detailedView(_ weather: WeatherData) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            // Line 1: Temperature and icon
            HStack(spacing: 4) {
                Image(systemName: weather.symbolName)
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(theme.primaryTextColor.color)
                
                Text(weather.temperatureFormatted)
                    .font(.custom("HelveticaNeue-Medium", size: 18))
                    .foregroundColor(theme.primaryTextColor.color)
            }
            
            // Line 2: Condition + High/Low combined
            HStack(spacing: 4) {
                Text(weather.conditionDescription)
                    .font(.custom("HelveticaNeue", size: 9))
                    .foregroundColor(theme.secondaryTextColor.color)
                
                Text("•")
                    .font(.custom("HelveticaNeue", size: 9))
                    .foregroundColor(theme.secondaryTextColor.color.opacity(0.5))
                
                Text(weather.highLowFormatted)
                    .font(.custom("HelveticaNeue", size: 9))
                    .foregroundColor(theme.secondaryTextColor.color.opacity(0.8))
            }
            
            // Line 3: Sunset
            if let sunset = weather.sunsetFormatted {
                HStack(spacing: 3) {
                    Image(systemName: "sunset.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "FF9500"))
                    Text("Sunset \(sunset)")
                        .font(.custom("HelveticaNeue", size: 9))
                        .foregroundColor(theme.secondaryTextColor.color.opacity(0.8))
                }
            }
        }
    }
}

// MARK: - Tomorrow Weather Badge

struct TomorrowWeatherBadge: View {
    let weather: WeatherData?
    var theme: WidgetTheme = .classic
    
    var body: some View {
        if let weather = weather, let tomorrow = weather.tomorrowForecast {
            HStack(spacing: 4) {
                Image(systemName: tomorrow.symbolName)
                    .font(.system(size: 9, weight: .light))
                    .foregroundColor(theme.secondaryTextColor.color)
                
                Text(tomorrow.highLowFormatted)
                    .font(.custom("HelveticaNeue", size: 8))
                    .foregroundColor(theme.secondaryTextColor.color.opacity(0.8))
                
                if let sunrise = tomorrow.sunriseFormatted {
                    HStack(spacing: 1) {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 7))
                            .foregroundColor(Color(hex: "FF9500"))
                        Text(sunrise)
                            .font(.custom("HelveticaNeue", size: 8))
                            .foregroundColor(theme.secondaryTextColor.color.opacity(0.8))
                    }
                }
            }
        }
    }
}

// MARK: - Mini Day Weather (for 5-day and Next Week views)

struct MiniDayWeather: View {
    let forecast: DailyForecast?
    
    var body: some View {
        if let forecast = forecast {
            HStack(spacing: 2) {
                Image(systemName: forecast.symbolName)
                    .font(.system(size: 8, weight: .light))
                    .foregroundColor(Color(hex: "666666"))
                
                Text("\(forecast.highFormatted)/\(forecast.lowFormatted)")
                    .font(.custom("HelveticaNeue", size: 8))
                    .foregroundColor(Color(hex: "888888"))
            }
        }
    }
}

