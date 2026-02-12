import SwiftUI

struct TimelineConnector: View {
    let isUnlocked: Bool
    let height: CGFloat

    init(isUnlocked: Bool, height: CGFloat = 40) {
        self.isUnlocked = isUnlocked
        self.height = height
    }

    var body: some View {
        Rectangle()
            .fill(isUnlocked ? Color(hex: "#F97316") : Color(.systemGray4))
            .frame(width: 4, height: height)
            .offset(x: 30)  // Align with icon box center (60px / 2 = 30px)
    }
}

struct TimelineConnector_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
        Rectangle()
        .fill(Color.white)
        .frame(height: 100)
        .border(Color.gray.opacity(0.3))
        
        TimelineConnector(isUnlocked: true, height: 40)
        
        Rectangle()
        .fill(Color.white)
        .frame(height: 100)
        .border(Color.gray.opacity(0.3))
        
        TimelineConnector(isUnlocked: false, height: 40)
        
        Rectangle()
        .fill(Color.white)
        .frame(height: 100)
        .border(Color.gray.opacity(0.3))
        }
        .padding()
        .background(Color(hex: "#FAFAFA"))
    }
}
