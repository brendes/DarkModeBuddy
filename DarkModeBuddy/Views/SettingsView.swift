//
//  SettingsView.swift
//  DarkModeBuddy
//
//  Created by Guilherme Rambo on 23/02/21.
//

import SwiftUI
import DarkModeBuddyCore

struct SettingsView: View {
    @EnvironmentObject var reader: DMBAmbientLightSensorReader
    @EnvironmentObject var settings: DMBSettings

    private let darknessInterval: ClosedRange<Double> = 0...30000

    // Use a logarithmic scale so sliding over lower values feels less sensitive
    // as you approach the low end of the spectrum. value = (max+1)^position - 1
    // over the range.
    private func value(forSliderPosition position: Double) -> Double {
        pow(darknessInterval.upperBound + 1, position) - 1
    }

    private func sliderPosition(forValue value: Double) -> Double {
        log(value + 1) / log(darknessInterval.upperBound + 1)
    }

    private var darknessThresholdSliderBinding: Binding<Double> {
        Binding(
            get: { sliderPosition(forValue: settings.darknessThreshold) },
            set: { settings.darknessThreshold = value(forSliderPosition: $0) }
        )
    }

    @State private var isShowingDarknessValueOutOfBoundsAlert = false
    @State private var isEditingAmbientLightLevelManually = false
    @State private var editingAmbientLightManuallyTextFieldStore = ""
    
    var body: some View {
        Group {
            if reader.isSensorReady {
                settingsControls
            } else {
                UnsupportedMacView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding([.top, .bottom])
        .padding([.leading, .trailing], 22)
        .onAppear { reader.activate() }
    }
    
    private var settingsControls: some View {
        VStack(alignment: .leading, spacing: 32) {
            Toggle(
                "Launch at Login",
                isOn: $settings.isLaunchAtLoginEnabled
            )
            
            Toggle(
                "Change Theme Automatically",
                isOn: $settings.isChangeSystemAppearanceBasedOnAmbientLightEnabled
            )
            
            Group {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Go Dark When Ambient Light Falls Below:")
                    
                    HStack(alignment: .firstTextBaseline) {
                        Slider(value: darknessThresholdSliderBinding, in: 0...1)
                            .frame(maxWidth: 300)
                        if isEditingAmbientLightLevelManually {
                            TextField("", text: $editingAmbientLightManuallyTextFieldStore, onCommit: {
                                guard let newValue = Double(editingAmbientLightManuallyTextFieldStore),
                                      newValue >= darknessInterval.lowerBound,
                                      newValue <= darknessInterval.upperBound else {
                                    isShowingDarknessValueOutOfBoundsAlert = true
                                    return
                                }
                                settings.darknessThreshold = newValue
                                isEditingAmbientLightLevelManually = false
                            })
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12, weight: .medium).monospacedDigit())
                            .frame(width: 60)
                        } else {
                            Text("\(settings.darknessThreshold.formattedNoFractionDigits)")
                                .font(.system(size: 12, weight: .medium).monospacedDigit())
                                .padding(.vertical, 2)
                                .padding(.horizontal, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(Color(NSColor.separatorColor), lineWidth: 1)
                                )
                                .onTapGesture {
                                    self.editingAmbientLightManuallyTextFieldStore = "\(settings.darknessThreshold.formattedNoFractionDigits)"
                                    isEditingAmbientLightLevelManually = true
                                }
                                .help("Click to edit")
                        }
                    }
                    .alert(isPresented: $isShowingDarknessValueOutOfBoundsAlert) {
                        Alert(title: Text("Error"),
                              message: Text("The threshold value must be in the interval [\(darknessInterval.lowerBound.formattedNoFractionDigits), \(darknessInterval.upperBound.formattedNoFractionDigits)]"),
                              dismissButton: .default(Text("OK")))
                    }
                    
                    HStack(alignment: .firstTextBaseline) {
                        Text("Current Ambient Light Level:")
                        Text("\(reader.ambientLightValue.formattedNoFractionDigits)")
                            .font(.system(size: 12).monospacedDigit())
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Color(NSColor.secondaryLabelColor))
                    
                    
                    Text("Delay Time:")
                        .padding(.top, 22)
                    
                    HStack(alignment: .firstTextBaseline) {
                        Slider(value: $settings.darknessThresholdIntervalInSeconds, in: 15...600, step: 15)
                        Text(settings.darknessThresholdIntervalInSeconds.formattedTime)
                            .font(.system(size: 12, weight: .medium).monospacedDigit())
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
            .disabled(!settings.isChangeSystemAppearanceBasedOnAmbientLightEnabled)
            
            Text(settings.currentSettingsDescription)
                .font(.system(size: 11))
                .foregroundColor(Color(NSColor.tertiaryLabelColor))
//                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
    }
}

extension NumberFormatter {
    static let noFractionDigits: NumberFormatter = {
        let f = NumberFormatter()
        
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        
        return f
    }()
}

extension Double {
    var formattedNoFractionDigits: String {
        NumberFormatter.noFractionDigits.string(from: NSNumber(value: self)) ?? "!!!"
    }
    var formattedTime: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        return (formatter.string(from: self) ?? "!!!" ) + "s"
    }
    var formattedLongTime: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        return formatter.string(from: self) ?? "!!!"
    }
}

extension DMBSettings {
    var currentSettingsDescription: String {
        guard isChangeSystemAppearanceBasedOnAmbientLightEnabled else {
            return "Dark Mode will not be enabled automatically based on ambient light."
        }
        
        return "Dark Mode will be enabled when the ambient light stays below \(darknessThreshold.formattedNoFractionDigits) for over \(darknessThresholdIntervalInSeconds.formattedLongTime)."
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .frame(maxWidth: 385)
            .environmentObject(DMBAmbientLightSensorReader(frequency: .realtime))
            .environmentObject(DMBSettings(forPreview: true))
            .previewLayout(.sizeThatFits)
    }
}
