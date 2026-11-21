import SwiftUI

struct DropZoneView: View {
    let isTargeted: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "folder.fill")
                .font(.system(size: 72))
                .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary)
                .scaleEffect(isTargeted ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTargeted)

            VStack(spacing: 8) {
                Text("Drop a Session Folder Here")
                    .font(.title2.weight(.medium))

                Text("Adds the missing \u{201C}Hasselblad\u{201D} prefix to camera model metadata in .fff files. Originals are backed up before any changes are made.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
                    .padding(.horizontal, 12)
            }

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.35),
                    style: StrokeStyle(lineWidth: isTargeted ? 2.5 : 1.5, dash: [8, 5])
                )
                .animation(.easeInOut(duration: 0.15), value: isTargeted)
                .padding(16)
        )
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isTargeted ? Color.accentColor.opacity(0.06) : Color.clear)
                .padding(16)
                .animation(.easeInOut(duration: 0.15), value: isTargeted)
        )
    }
}

#Preview {
    DropZoneView(isTargeted: false)
        .frame(width: 500, height: 380)
}
