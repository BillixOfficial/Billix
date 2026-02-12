import SwiftUI

struct MetadataPillView: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MetadataPillView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
        HStack(spacing: 8) {
        MetadataPillView(icon: "target", text: "10 Stops")
        MetadataPillView(icon: "arrow.right", text: "Sequential")
        }
        
        HStack(spacing: 8) {
        MetadataPillView(icon: "shuffle", text: "Randomized")
        MetadataPillView(icon: "gamecontroller.fill", text: "0 plays")
        }
        }
        .padding()
    }
}
