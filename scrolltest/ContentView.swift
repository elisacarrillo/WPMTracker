//
//  ContentView.swift
//  scrolltest
//
//  Created by Elisa Carrillo on 1/11/25.
//

import SwiftUI
import Charts

enum FrequencyFilterOption: String, CaseIterable, Identifiable {
    case oneTo200 = "1-200"
    case oneTo100 = "1-100"
    case fiftyTo100 = "50-100"
    case oneHundredTo200 = "100-200"
    
    var id: String { rawValue }
}


struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .bold()
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}



struct ContentView: View {
    @EnvironmentObject var keyboardTracker: HIDKeyboardMonitor
    @Environment(\.managedObjectContext) private var context
    @State private var selectedTimeFrame: TimeFrame = .all
    @State private var selectedFrequencyFilter: FrequencyFilterOption = .oneTo200

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entity.timestamp, ascending: true)],
        animation: .default
    ) private var wpmEntries: FetchedResults<Entity>
    
    func generateZones(start: Int, end: Int, step: Int = 10) -> [(name: String, range: ClosedRange<Int>)] {
        var currentStart = start
        var zones: [(name: String, range: ClosedRange<Int>)] = []
        
        while currentStart <= end {
            let nextEnd = min(currentStart + step - 1, end)
            let name = "\(currentStart)-\(nextEnd) WPM"
            zones.append((name, currentStart...nextEnd))
            currentStart += step
        }
        
        return zones
    }
    func zones(for option: FrequencyFilterOption) -> [(name: String, range: ClosedRange<Int>)] {
        switch option {
        case .oneTo200:
            return generateZones(start: 1, end: 200, step: 10)
        case .oneTo100:
            return generateZones(start: 1, end: 100, step: 10)
        case .fiftyTo100:
            return generateZones(start: 50, end: 100, step: 10)
        case .oneHundredTo200:
            return generateZones(start: 100, end: 200, step: 10)
        }
    }
    
    func averageWPM(for entries: [Entity], frequencyFilter: FrequencyFilterOption) -> Double {
        // Determine which zones to include
        let currentZones = zones(for: frequencyFilter)
        
        // Convert each Entity’s wpm to Int
        let wpmValues = entries.map { Int($0.wpm) }
        
        // Filter to only those WPMs that fall within any of the currentZones
        let relevantWPMs = wpmValues.filter { wpm in
            currentZones.contains { $0.range.contains(wpm) }
        }
        
        // Compute average
        guard !relevantWPMs.isEmpty else { return 0.0 }
        let total = relevantWPMs.reduce(0, +)
        return Double(total) / Double(relevantWPMs.count)
    }

    
    
    func calculateWPMFrequencyDistribution(
        from entries: [Entity],
        using zones: [(name: String, range: ClosedRange<Int>)]
    ) -> [WPMZone] {
        let wpms = entries.map { Int($0.wpm) }
        
        return zones.map { zone in
            let count = wpms.filter { zone.range.contains($0) }.count
            return WPMZone(zone: zone.name, count: count)
        }
    }


    // Filter entries based on selected time frame
    func filteredEntries(for timeFrame: TimeFrame) -> [Entity] {
        let now = Date()
        switch timeFrame {
        case .minute1:
            return wpmEntries.filter { $0.timestamp ?? now > Calendar.current.date(byAdding: .minute, value: -1, to: now)! }
        case .day:
            return wpmEntries.filter { $0.timestamp ?? now > Calendar.current.date(byAdding: .day, value: -1, to: now)! }
        case .week:
            return wpmEntries.filter { $0.timestamp ?? now > Calendar.current.date(byAdding: .day, value: -7, to: now)! }
        case .month:
            return wpmEntries.filter { $0.timestamp ?? now > Calendar.current.date(byAdding: .day, value: -30, to: now)! }
        case .all:
            return Array(wpmEntries)
        }
    }
    
    enum TimeFrame: String, CaseIterable, Identifiable {
        case minute1 = "1 Minute"
        case day = "1 Day"
        case week = "7 Days"
        case month = "30 Days"
        case all = "All Time"
        
        var id: String { self.rawValue }
    }
    
    func calculateMaxWPM(from entries: [Entity]) -> Int {
        return entries.map { Int($0.wpm) }.max() ?? 0
    }
    
    func calculateMinWPM(from entries: [Entity]) -> Int {
        return entries.map { Int($0.wpm) }.min() ?? 0
    }
    
    func calculateAvgWPM(from entries: [Entity]) -> Double {
        let wpms = entries.map { Int($0.wpm) }
        guard !wpms.isEmpty else { return 0.0 }
        return Double(wpms.reduce(0, +)) / Double(wpms.count)
    }
    
    func calculateMedianWPM(from entries: [Entity]) -> Double {
        let wpms = entries.map { Int($0.wpm) }.sorted()
        guard !wpms.isEmpty else { return 0.0 }
        
        let count = wpms.count
        if count % 2 == 0 {
            return Double(wpms[count / 2 - 1] + wpms[count / 2]) / 2.0
        } else {
            return Double(wpms[count / 2])
        }
    }
    
    func calculateStdDevWPM(from entries: [Entity]) -> Double {
        let wpms = entries.map { Int($0.wpm) }
        guard !wpms.isEmpty else { return 0.0 }
        
        let mean = calculateAvgWPM(from: entries)
        let variance = wpms.map { pow(Double($0) - mean, 2) }.reduce(0, +) / Double(wpms.count)
        return sqrt(variance)
    }
    
    
    
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        

        

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // App Header
//                Text("WPM Tracker")
//                    .font(.largeTitle)
//                    .bold()
//                    .foregroundColor(.gray)
//                    .padding(.top)
//                    .frame(maxWidth: .infinity, alignment: .center)
                
                                //
                
                
                
                // Current Stats Section
                VStack(spacing: 10) {
                    
                    VStack {
                        
                        
                        HStack {
                            VStack {
                                Text("Elapsed Time")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(keyboardTracker.minuteTimerString)")
                                    .font(.title2)
                                    .bold()
                            }
                            Spacer()
                            VStack {
                                Text("Total Time")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(keyboardTracker.elapsedTimeString)")
                                    .font(.title2)
                                    .bold()
                            }
                            Spacer()
                            VStack {
                                Text("Current WPM")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(keyboardTracker.currentWPM)")
                                    .font(.title2)
                                    .bold()
                            }
                        }
                        
                        
                    }
                    .padding()
                    .padding(.horizontal, 16)
                    
                    .contentMargins(2)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }.padding(.horizontal, 16)
                    .padding(.top, 16)
                Text(keyboardTracker.isTrackingPublic ?  "You’re on fire! 🔥": "You’re taking a break 😴")
                    .font(.headline)
                    .foregroundColor(!keyboardTracker.isTrackingPublic ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
//                    .padding()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .scaleEffect(keyboardTracker.isTrackingPublic ? 1.0 : 1.1) // Adds a subtle bounce
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: keyboardTracker.isTrackingPublic)
                
                Text("Past Statistics")
                    .font(.title2)
                    .bold()
                //                    .padding(.top)
                    .frame(maxWidth: .infinity, alignment: .center)
                Picker("", selection: $selectedTimeFrame) {
                    ForEach(TimeFrame.allCases) { timeFrame in
                        Text(timeFrame.rawValue).tag(timeFrame)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Filtered WPM Entries
                let filteredWPMEntries :[Entity] = filteredEntries(for: selectedTimeFrame)
                let currentZones = zones(for: selectedFrequencyFilter)
                let frequencyData = calculateWPMFrequencyDistribution(
                    from: filteredWPMEntries,
                    using: currentZones
                )
                let rangeAverage = averageWPM(for: filteredWPMEntries, frequencyFilter: selectedFrequencyFilter)
                
                VStack(spacing: 10) {
                    
                    
                    
                    //
                    
                    
                    HStack(spacing: 20) {
                        StatCard(title: "Max WPM", value: "\(calculateMaxWPM(from: filteredWPMEntries))")
                        StatCard(title: "Min WPM", value: "\(calculateMinWPM(from: filteredWPMEntries))")
                        StatCard(title: "Avg WPM", value: String(format: "%.2f", calculateAvgWPM(from: filteredWPMEntries)))
                        StatCard(title: "Median WPM", value: String(format: "%.2f", calculateMedianWPM(from: filteredWPMEntries)))
                        StatCard(title: "Std Dev WPM", value: String(format: "%.2f", calculateStdDevWPM(from: filteredWPMEntries)))
                    }
                }
                
                // WPM Frequency Distribution
                VStack(spacing: 10) {
                    Text("WPM Frequency Distribution")
                        .font(.title2)
                        .bold()
                    
//                    Chart {
//                        ForEach(calculateWPMFrequencyDistribution(from: filteredWPMEntries), id: \.zone) { data in
//                            BarMark(
//                                x: .value("WPM Zone", data.zone),
//                                y: .value("Count", data.count)
//                            )
//                        }
//                    }
//                    .frame(height: 300)
//                    .padding()
//                    .cornerRadius(12)
                    
//                    .shadow(radius: 5)
                    
                    
                    Chart {
                        ForEach(frequencyData, id: \.id) { data in
                            BarMark(
                                x: .value("WPM Zone", data.zone),
                                y: .value("Count", data.count)
                            )
                        }
                    }
                    .frame(height: 300)
                    .padding()
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }
                
                Text("Range Average: \(rangeAverage, specifier: "%.2f")")
                                .font(.title3)
                                .bold()
                                .padding(.horizontal)
                Picker("WPM Range", selection: $selectedFrequencyFilter) {
                    ForEach(FrequencyFilterOption.allCases) { filterOption in
                        Text(filterOption.rawValue).tag(filterOption)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Past WPM Over Time
                VStack(spacing: 10) {
                    Text("Past WPM Over Time")
                        .font(.title2)
                        .bold()
                    
                    Chart {
                        ForEach(Array(filteredWPMEntries.enumerated()), id: \.offset) { index, entry in
                            LineMark(
                                x: .value("Interval", index * 10),
                                y: .value("WPM", entry.wpm)
                            )
                        }
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }
                
                
                
                
               
                

            }
        }
    }
}

struct WPMZone: Identifiable {
    let zone: String
    let count: Int
    var id: String { zone }
}
//
//func calculateWPMFrequencyDistribution(from entries: [Entity]) -> [WPMZone] {
//    let zones: [(name: String, range: ClosedRange<Int>)] = [
//        ("1-10 WPM zone", 1...10),
//        ("11-20 WPM zone", 11...20),
//        ("21-25 WPM zone", 21...25),
//        ("26-30 WPM zone", 26...30),
//        ("31-35 WPM zone", 31...35),
//        ("36-40 WPM zone", 36...40),
//        ("41-45 WPM zone", 41...45),
//        ("46-50 WPM zone", 46...50),
//        ("51-55 WPM zone", 51...55),
//        ("56-60 WPM zone", 56...60),
//        ("61-65 WPM zone", 61...65),
//        ("66-70 WPM zone", 66...70),
//        ("71-80 WPM zone", 71...80),
//        ("81-90 WPM zone", 81...90),
//        ("91-100 WPM zone", 91...100),
//        ("101-110 WPM zone", 101...110),
//        ("111-120 WPM zone", 111...120),
//        ("121-140 WPM zone", 121...140),
//        ("141-160 WPM zone", 141...160),
//        ("161-180 WPM zone", 161...180),
//        ("181-269 WPM zone", 181...269)
//    ]
//    
//    let wpms = entries.map { Int($0.wpm) }
//    return zones.map { zone in
//        let count = wpms.filter { zone.range.contains($0) }.count
//        return WPMZone(zone: zone.name, count: count)
//    }
//}
