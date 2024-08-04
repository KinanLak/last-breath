import Foundation

func formatTime(timeInterval: TimeInterval) -> ElapsedTime {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    
    return ElapsedTime(minutes: minutes, seconds: seconds)    
}

func formatDate(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm 'on' dd MMMM yyyy"
    return formatter.string(from: date)
}
