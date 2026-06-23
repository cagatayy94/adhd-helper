import SwiftUI

struct HeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mindful Days")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Your ADHD Companion Calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 28))
                .foregroundColor(.indigo)
                .padding(10)
                .background(Color.indigo.opacity(0.1))
                .clipShape(Circle())
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }
}
