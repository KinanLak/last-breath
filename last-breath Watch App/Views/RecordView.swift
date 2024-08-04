import HealthKit
import SwiftUI
import Combine
import WatchKit

struct RecordView: View {
    @State private var isRecording = false
    @State private var isOver = false
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var heartRate: Double = 0
    
    @State private var timer: AnyCancellable?
    @State private var workoutSession: HKWorkoutSession?
    @State private var heartRateQuery: HKQuery?
    
    @AppStorage("sessionsList") private var sessionsListData: Data = Data()
    @State private var sessionsList: [Session] = []
    
    @State private var currentBPMList: [BPMCheck] = []
    
    private let healthStore: HKHealthStore?
    private var currentSession: Session? = nil
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        } else {
            healthStore = nil
            print("HealthKit is not available on this device")
        }
    }
    
    var body: some View {
        TabView {
            recordingView
            SessionsListView(sessionsList: $sessionsList, onDelete: deleteSession)
        }.tabViewStyle(.carousel)
            .onAppear(perform: {
                setupHealthKit()
                startHeartRateQuery()
                loadSessionsList()
            })
            .onDisappear(perform: {
                stopHeartRateQuery()
                saveRecordedTimes()
            })
    }
    
    private func loadSessionsList() {
        if let decodedSessions = try? JSONDecoder().decode([Session].self, from: sessionsListData) {
            sessionsList = decodedSessions
        }
    }
    
    public func saveRecordedTimes() {
        if let encodedSessions = try? JSONEncoder().encode(sessionsList) {
            sessionsListData = encodedSessions
        }
    }
    
    private func deleteSession(at offsets: IndexSet) {
        sessionsList.remove(atOffsets: offsets)
        saveRecordedTimes()
    }
    
    private var recordingView: some View {
        
            
            VStack(spacing: 0) {
                
                timerDisplay
                heartRateDisplay
                RecordButton
                BPMStatsView
            }
            
        
    }
    
    private func clearCurrentSessions() {
        currentBPMList = []
        isOver = false
    }
    
    private var RecordButton : some View {
        
        var text: String
        var color: Color
        var icon: String
        var action = {}
        
        if isRecording {
            text = "Stop"
            color = .red
            icon = "stop.fill"
            action = {stopRecording()}
            
        } else {
            if isOver {
                text = "Restart"
                icon = "arrow.clockwise"
                color = .blue
            } else {
                text = "Start"
                icon = "play.fill"
                color = .green
            }
            
            action = {startRecording()}
        }
        
        if #available(watchOS 11.0, *) {
            return Button(text, systemImage: icon, action: action)
                .bold()
                .foregroundColor(color)
                .font(.title2)
                .handGestureShortcut(.primaryAction)
        } else {
            return Button(text, systemImage: icon, action: action)
                .bold()
                .foregroundColor(color)
                .font(.title2)
        }
    }
    
    private var  BPMStatsView : some View {
        return HStack (spacing: 10) {
            if let min = currentBPMList.minBPM(),
               let max = currentBPMList.maxBPM(),
               let avg = currentBPMList.avgBPM() {
                
                HStack (spacing: 2) {
                    Text(Image(systemName: "arrow.down.heart.fill"))
                        .foregroundColor(.green)
                    Text(String(min))
                        .foregroundColor(.green)
                }
                HStack (spacing: 2) {
                    Text(Image(systemName: "arrow.up.heart.fill"))
                        .foregroundColor(.red)
                    Text(String(max))
                        .foregroundColor(.red)
                }
                HStack (spacing: 2) {
                    Text(Image(systemName: "plus.forwardslash.minus"))
                        .foregroundColor(.blue)
                    Text(String(avg))
                        .foregroundColor(.blue)
                }
            } else {
                //Text("Non disponible")
            }
        }
        .font(.system(size: 12, weight: .semibold))
        .padding(.top, 10)
    }
    
    private func hapticTimer() {
        let elapsed = Int(elapsedTime)
        
        if elapsed % 60 == 0 && elapsed != 0 {
            // Grosse vibration chaque minute
            WKInterfaceDevice.current().play(.notification)
        } else if elapsed % 30 == 0 && elapsed != 0 {
            // Petite vibration chaque 30 secondes
            WKInterfaceDevice.current().play(.click)
        }
    }
    
    private var timerDisplay: some View {
        
        let elapsed = formatTime(timeInterval: elapsedTime)
        
        return HStack {
            if elapsed.minutes == 0 {
                Text(String(elapsed.seconds))
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("sec")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gray)
                    .padding(.leading, 5)
            } else {
                Text(String(elapsed.minutes))
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("mn")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gray)
                    .padding(.leading, 5)
                Text(String(format: "%02d", elapsed.seconds))
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("s")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gray)
                    .padding(.leading, 5)
            }
        }.padding(.top, -10)
        .padding(.bottom, -10)    }
    
    private var heartRateDisplay: some View {
        HStack {
            if heartRate == 0 {
                Text("--")
                    .foregroundColor(.red)
                    .font(.system(size: 50))
                
            } else {
                Text(String(Int(heartRate)))
                    .foregroundColor(.red)
                    .font(.system(size: 50, weight: .bold, design: .rounded))
            }
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .font(.system(size: 40))
            
        }.padding(.bottom, 5)
    }
    
    private func setupHealthKit() {
        guard let healthStore = healthStore else {
            print("HealthStore is not available")
            return
        }
        
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            print("Heart rate type is no longer available in HealthKit")
            return
        }
        
        healthStore.requestAuthorization(toShare: [heartRateType], read: [heartRateType]) { success, error in
            if success {
                print("HealthKit authorization successful")
            } else if let error = error {
                print("HealthKit authorization failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func startRecording() {
        
        
        if isOver == true {
            //timer?.cancel()
            timer = nil
            
            isOver = false
        }
        
        isRecording = true
        elapsedTime = 0
        currentBPMList = []  // Clear the BPM list for the new session
        
        let startTime = Date()
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.elapsedTime = Date().timeIntervalSince(startTime)
                self.hapticTimer()
            }
        
        startWorkoutSession()
    }
    
    private func stopRecording() {
        isRecording = false
        timer?.cancel()
        //timer = nil
        
        if elapsedTime >= 15 {
            let newSession = Session(
                date: Date(),
                duration: elapsedTime,
                BPMList: currentBPMList,
                highestBPM: currentBPMList.maxBPM(),
                lowestBPM: currentBPMList.minBPM(),
                averageBPM: currentBPMList.avgBPM()
            )
            
            sessionsList.append(newSession)
            saveRecordedTimes()
        }
        
        isOver = true
        
        stopWorkoutSession()
        
        // Reset the current BPM list for the next session
        //currentBPMList = []
    }
    
    private func startWorkoutSession() {
        guard let healthStore = healthStore else {
            print("HealthStore is not available")
            return
        }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        
        
        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutSession = session
            session.startActivity(with: Date())
            
            
            
            print("Workout session started")
        } catch {
            print("Failed to start workout session: ", (error.localizedDescription))
        }
    }
    
    private func stopWorkoutSession() {
        workoutSession?.stopActivity(with: Date())
        workoutSession?.end()
        workoutSession = nil
    }
    
    private func startHeartRateQuery() {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let healthStore = healthStore else { return }
        
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, queryAnchor, error in
            
            guard let samples = samples as? [HKQuantitySample] else { return }
            
            DispatchQueue.main.async {
                if let latestSample = samples.last {
                    let bpm = Int(latestSample.quantity.doubleValue(for: HKUnit(from: "count/min")))
                    self.heartRate = Double(bpm)
                    
                    if self.isRecording {
                        // Add the new BPM check to the list only if recording
                        let newBPMCheck = BPMCheck(seconds: self.elapsedTime, BPM: bpm)
                        if newBPMCheck.seconds + 1 > self.currentBPMList.last?.seconds ?? -1 {
                            self.currentBPMList.append(newBPMCheck)
                        }
                    }
                }
            }
        }
        
        let query = HKAnchoredObjectQuery(
            type: quantityType,
            predicate: devicePredicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit,
            resultsHandler: updateHandler)
        
        query.updateHandler = updateHandler
        
        healthStore.execute(query)
        self.heartRateQuery = query
    }
    
    private func stopHeartRateQuery() {
        guard let healthStore = healthStore, let query = self.heartRateQuery else { return }
        healthStore.stop(query)
    }
}

#Preview {
    RecordView()
}
