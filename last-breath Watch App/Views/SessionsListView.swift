import SwiftUI

struct SessionsListView: View {
    @Binding var sessionsList: [Session]
    var onDelete: (IndexSet) -> Void
    
    var sortedSessions: [Session] {
        sessionsList.sorted(by: { $0.date > $1.date })
    }
    
    var body: some View {
        if sessionsList.isEmpty {
            Text("L'historique de vos temps s'affichera ici")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, -60)
        } else {
            List {
                ForEach(sortedSessions) { session in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            let elapsed = formatTime(timeInterval: session.duration)
                            if elapsed.minutes > 0 {
                                Text("\(elapsed.minutes) min \(elapsed.seconds) sec")
                                    .bold()
                            } else {
                                Text("\(elapsed.seconds) sec")
                                    .bold()
                            }
                            Spacer()
                            Text(formatDate(date: session.date))
                                .foregroundColor(.gray)
                                .font(.system(size: 12))
                        }
                        
                        HStack (spacing: 10) {
                            if let min = session.BPMList.minBPM(),
                               let max = session.BPMList.maxBPM(),
                               let avg = session.BPMList.avgBPM() {
                                Spacer()
                                HStack (spacing: 2) {
                                    Text(Image(systemName: "arrow.down.to.line"))
                                        .foregroundColor(.green)
                                    Text(String(min))
                                        .foregroundColor(.green)
                                }
                                HStack (spacing: 2) {
                                    Text(Image(systemName: "arrow.up.to.line"))
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
                                Text("Non disponible")
                            }
                        }
                        .font(.system(size: 12, weight: .semibold))
                    }
                }
                .onDelete(perform: delete)
            }
        }
    }
    
    private func delete(at offsets: IndexSet) {
        let sortedIndices = offsets.map { sortedSessions[$0] }
        let indicesToRemove = sessionsList.indices.filter { sortedIndices.contains(sessionsList[$0]) }
        onDelete(IndexSet(indicesToRemove))
    }
}

