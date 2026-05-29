//
//  DataCollectionViewModel.swift
//  Real-time Sport Analyzer Watch App
//

import SwiftUI
import CoreMotion
import WatchKit

final class DataCollectionViewModel: NSObject, ObservableObject {
    @Published var status: String = "Idle"
    @Published var timeRemaining: Int = 10
    @Published var isCollecting: Bool = false
    @Published var motionData: [MotionDataModel] = []

    private let motionManager = CMMotionManager()
    private let pedometer = CMPedometer()
    private var collectionTimer: Timer?
    private var currentPace: Double = 0.0
    private var currentStepCount: Int = 0
    private var currentCadence: Double = 0.0
    private var numTrans: Int = 0
    private var currentActivity: String = ""

    func startCollectingData(for activity: String) {
        timeRemaining = 10
        isCollecting = true
        motionData = []

        if currentActivity != activity {
            numTrans = 0
        }
        currentActivity = activity

        guard motionManager.isDeviceMotionAvailable else {
            status = "No Motion Data"
            return
        }

        provideHapticFeedback()
        startPedometerUpdates()
        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: OperationQueue.current!) { [weak self] data, _ in
            guard let self, let validData = data else { return }

            let record = MotionDataModel(
                activity: activity,
                accelX: validData.userAcceleration.x,
                accelY: validData.userAcceleration.y,
                accelZ: validData.userAcceleration.z,
                gyroX: validData.rotationRate.x,
                gyroY: validData.rotationRate.y,
                gyroZ: validData.rotationRate.z,
                magX: validData.magneticField.field.x,
                magY: validData.magneticField.field.y,
                magZ: validData.magneticField.field.z,
                pace: self.currentPace,
                stepCount: self.currentStepCount,
                cadence: self.currentCadence
            )
            self.motionData.append(record)
        }

        collectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }

        status = "Collecting \(activity) data"
    }

    private func provideHapticFeedback() {
        WKInterfaceDevice.current().play(.start)
    }

    private func startPedometerUpdates() {
        pedometer.startUpdates(from: Date()) { [weak self] pedometerData, error in
            guard let pedometerData, error == nil else { return }
            DispatchQueue.main.async {
                self?.currentPace = pedometerData.currentPace?.doubleValue ?? 0
                self?.currentStepCount = pedometerData.numberOfSteps.intValue
                self?.currentCadence = pedometerData.currentCadence?.doubleValue ?? 0
            }
        }
    }

    private func updateCountdown() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            stopCollectingData()
        }
    }

    func stopCollectingData() {
        stopCycle()
        if numTrans < 100 {
            numTrans += 1
            startCollectingData(for: currentActivity)
        }
    }

    func stopCycle() {
        motionManager.stopDeviceMotionUpdates()
        pedometer.stopUpdates()
        collectionTimer?.invalidate()
        collectionTimer = nil
        isCollecting = false
        status = "Collection stopped"
    }
}
