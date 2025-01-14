//
//  ContentView.swift
//  scrolltest
//
//  Created by Elisa Carrillo on 1/11/25.
//

import SwiftUI
import Charts

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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entity.timestamp, ascending: true)],
        animation: .default
    ) private var wpmEntries: FetchedResults<Entity>
    // Calculate the maximum WPM
    func calculateMaxWPM(from entries: FetchedResults<Entity>) -> Int {
        return entries.map { Int($0.wpm) }.max() ?? 0
    }

    // Calculate the minimum WPM
    func calculateMinWPM(from entries: FetchedResults<Entity>) -> Int {
        return entries.map { Int($0.wpm) }.min() ?? 0
    }
    func filteredEntries(for timeFrame: TimeFrame) -> [Entity] {
        

        let now = Date()
        switch timeFrame {
        case .day:
            print("ASKING FOR DAY")
//            print(wpmEntries.filter { $0.timestamp ?? now > Calendar.current.date(byAdding: .day, value: -1, to: now)! })
            return wpmEntries.filter { $0.timestamp ?? now > Calendar.current.date(byAdding: .day, value: -1, to: now)! }
        case .week:
            print("ASKING FOR week")
//            print(wpmEntries.filter { $0.timestamp ?? now > Calendar.current.date(byAdding: .day, value: -7, to: now)! })
            return wpmEntries.filter { $0.timestamp ?? now > Calendar.current.date(byAdding: .day, value: -7, to: now)! }
        case .month:
            print("ASKING FOR month")
            return wpmEntries.filter { $0.timestamp ?? now > Calendar.current.date(byAdding: .day, value: -30, to: now)! }
        case .all:
            return Array(wpmEntries)
        }
    }
    
    enum TimeFrame: String, CaseIterable, Identifiable {
        case day = "1 Day"
        case week = "7 Days"
        case month = "30 Days"
        case all = "All Time"
        
        var id: String { self.rawValue }
    }


    // Calculate the average WPM
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
            //        VStack(spacing: 20) {
            //            // Display the last key pressed
            //            Text("Last Key Pressed")
            //                .font(.title)
            //                .bold()
            //
            //            Text(keyboardTracker.lastKeyPressed)
            //                .font(.largeTitle)
            //                .foregroundColor(.blue)
            //                .padding()
            //                .background(Color.gray.opacity(0.2))
            //                .cornerRadius(8)
            //
            //
            //        }
            //        .padding()
            //
            VStack(alignment: .leading, spacing: 20) {
                
                // MARK: - WPM Entries for testing!!!
                // Display each WPMEntry as a separate "row"
//                VStack(alignment: .leading, spacing: 10) {
//                    Text("Last Two Entries")
//                        .font(.headline)
//                        .bold()
//
//                    ForEach(wpmEntries.suffix(2), id: \.self) { entry in
//                        VStack(alignment: .leading) {
//                            Text("User: \(entry.userId ?? "Unknown")")
//                                .font(.subheadline)
//                            Text("WPM: \(entry.wpm)")
//                                .font(.title3)
//                                .bold()
//                            Text("Time: \(entry.timestamp ?? Date(), formatter: dateFormatter)")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//
//
//                        }
//                        .padding()
//                        .background(Color(.white))
//                        .cornerRadius(8)
//                        .shadow(radius: 2)
//
//                        Text("Total Data Entries")
//                            .font(.headline)
//                            .bold()
//
//                        Text("\(wpmEntries.count) entries")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                }
//                .padding(.horizontal)
                
                
                
                // MARK: - Header + Stats Section
                VStack(spacing: 20) {
                    
                    // App Header
                    Text("WPM Tracker")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.gray)
                        .padding(.top)
                    
                    
                    
                    // Current Stats Section
                    VStack(spacing: 10) {
                        Text("Current Stats")
                            .font(.title2)
                            .bold()
                        VStack {
                            Text(keyboardTracker.isTrackingPublic ?  "You’re on fire! 🔥": "You’re taking a break 😴")
                                .font(.headline)
                                .foregroundColor(!keyboardTracker.isTrackingPublic ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                                .scaleEffect(keyboardTracker.isTrackingPublic ? 1.0 : 1.1) // Adds a subtle bounce
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: keyboardTracker.isTrackingPublic)
                        }
                        HStack {
                            VStack {
                                Text("Elapsed Time")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(keyboardTracker.minuteTimerString)")
                                    .font(.title3)
                                    .bold()
                            }
                            Spacer()
                            VStack {
                                Text("Total Time")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(keyboardTracker.elapsedTimeString)")
                                    .font(.title3)
                                    .bold()
                            }
                            Spacer()
                            VStack {
                                Text("Current WPM")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(keyboardTracker.currentWPM)")
                                    .font(.title3)
                                    .bold()
                            }
                            
                        }
                        .padding()
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }
                    
                    
                    VStack(spacing: 20) {
                        // Picker for Time Frame
                        Picker("Time Frame", selection: $selectedTimeFrame) {
                            ForEach(TimeFrame.allCases) { timeFrame in
                                Text(timeFrame.rawValue).tag(timeFrame)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()

                        // Filtered WPM Entries
                        let filteredWPMEntries = filteredEntries(for: selectedTimeFrame)

                        // Statistics Section
                        VStack(spacing: 10) {
                            Text("Statistics")
                                .font(.title2)
                                .bold()
                            
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
                            
                            Chart {
                                ForEach(calculateWPMFrequencyDistribution(from: filteredWPMEntries), id: \.zone) { data in
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

                        // Past WPM Over Time
                        VStack(spacing: 10) {
                            Text("Past WPM Over Time")
                                .font(.title2)
                                .bold()
                            
                            Chart {
                                ForEach(Array(filteredWPMEntries.enumerated()), id: \.offset) { index, entry in
                                    LineMark(
                                        x: .value("Interval", index * 10), // Use the index or a timestamp for the x-axis
                                        y: .value("WPM", entry.wpm) // Use `entry.wpm` directly if it's already an Int
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
    }
}
struct WPMZone: Identifiable {
    let zone: String
    let count: Int
    var id: String { zone }
}
func calculateWPMFrequencyDistribution(from entries: [Entity]) -> [WPMZone] {
    // Define WPM zones in a fixed order
    let zones: [(name: String, range: ClosedRange<Int>)] = [
        ("1-10 WPM zone", 1...10),
        ("11-20 WPM zone", 11...20),
        ("21-25 WPM zone", 21...25),
        ("26-30 WPM zone", 26...30),
        ("31-35 WPM zone", 31...35),
        ("36-40 WPM zone", 36...40),
        ("41-45 WPM zone", 41...45),
        ("46-50 WPM zone", 46...50),
        ("51-55 WPM zone", 51...55),
        ("56-60 WPM zone", 56...60),
        ("61-65 WPM zone", 61...65),
        ("66-70 WPM zone", 66...70),
        ("71-80 WPM zone", 71...80),
        ("81-90 WPM zone", 81...90),
        ("91-100 WPM zone", 91...100),
        ("101-110 WPM zone", 101...110),
        ("111-120 WPM zone", 111...120),
        ("121-140 WPM zone", 121...140),
        ("141-160 WPM zone", 141...160),
        ("161-180 WPM zone", 161...180),
        ("181-269 WPM zone", 181...269)
    ]

    // Extract WPM values from the entries
    let wpms = entries.map { Int($0.wpm) }

    // Calculate counts for each zone
    let distribution = zones.map { zone -> WPMZone in
        let count = wpms.filter { zone.range.contains($0) }.count
        return WPMZone(zone: zone.name, count: count)
    }

    return distribution
}


