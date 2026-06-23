import SwiftUI

struct SwipeToDeleteModifier: ViewModifier {
    let onDelete: () -> Void
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    
    func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            // Delete Action Background
            Button(action: {
                withAnimation(.spring()) {
                    offset = 0
                    isSwiped = false
                }
                onDelete()
            }) {
                ZStack {
                    Color.red
                    Image(systemName: "trash.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .frame(width: 80)
                .cornerRadius(16)
            }
            .padding(.vertical, 1)
            
            content
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 {
                                let target = isSwiped ? -80 + value.translation.width : value.translation.width
                                offset = max(target, -100)
                            } else if isSwiped && value.translation.width > 0 {
                                offset = -80 + value.translation.width
                                offset = min(offset, 0)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if value.translation.width < -40 {
                                    offset = -80
                                    isSwiped = true
                                } else {
                                    offset = 0
                                    isSwiped = false
                                }
                            }
                        }
                )
        }
    }
}

extension View {
    func swipeToDelete(onDelete: @escaping () -> Void) -> some View {
        self.modifier(SwipeToDeleteModifier(onDelete: onDelete))
    }
}
