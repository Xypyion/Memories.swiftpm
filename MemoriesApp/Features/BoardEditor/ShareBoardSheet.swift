import SwiftUI
import UIKit

/// Sharing is presented as *who is on the board*, not as a list of export
/// destinations. Collaboration is the product's centre of gravity, so the sheet
/// leads with people and treats the link as a secondary detail.
struct ShareBoardSheet: View {

    let board: Board
    let collaborators: [Friend]

    @Environment(\.dismiss) private var dismiss
    @State private var didCopy = false

    private var inviteLink: String {
        "memories://board/\(board.id.uuidString.prefix(8).lowercased())"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.unit * 4) {
                    hero

                    if !collaborators.isEmpty {
                        VStack(alignment: .leading, spacing: Space.unit * 2) {
                            SectionHeader("On this board")

                            VStack(spacing: 0) {
                                ForEach(collaborators) { person in
                                    row(for: person)

                                    if person.id != collaborators.last?.id {
                                        Divider().overlay(Palette.hairline)
                                    }
                                }
                            }
                            .glassPanel(cornerRadius: Radius.panel)
                        }
                    }

                    linkCard
                }
                .padding(Space.canvasMargin)
            }
            .background(Palette.surface)
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Palette.surface)
    }

    private var hero: some View {
        HStack(spacing: 16) {
            BoardCollage(board: board)
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .strokeBorder(Palette.hairline, lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(board.title)
                    .textStyle(TypeScale.headline)
                    .foregroundStyle(Palette.onSurface)

                Text("\(board.memoryCount) memories · \(collaborators.count) collaborators")
                    .textStyle(TypeScale.labelCaps)
                    .foregroundStyle(Palette.onSurfaceVariant)
            }

            Spacer(minLength: 0)
        }
    }

    private func row(for person: Friend) -> some View {
        HStack(spacing: 12) {
            AvatarView(
                name: person.name,
                seed: person.seed,
                size: 40,
                ring: person.ringStyle,
                imageName: person.avatarImageName
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .textStyle(TypeScale.bodyMD)
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.onSurface)

                Text(person.handle)
                    .textStyle(TypeScale.labelCaps)
                    .foregroundStyle(Palette.onSurfaceVariant)
            }

            Spacer(minLength: 8)

            if person.isActive {
                HStack(spacing: 6) {
                    PresenceDot(color: Palette.neon, size: 6)
                    Text("ACTIVE")
                        .textStyle(TypeScale.labelTiny)
                        .foregroundStyle(Palette.neon)
                }
            }
        }
        .padding(16)
    }

    private var linkCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Invite link")

            HStack(spacing: 12) {
                Text(inviteLink)
                    .textStyle(TypeScale.labelCaps)
                    .foregroundStyle(Palette.onSurfaceVariant)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 8)

                NeonButton(
                    title: didCopy ? "Copied" : "Copy",
                    icon: didCopy ? "checkmark" : "doc.on.doc",
                    isCompact: true
                ) {
                    UIPasteboard.general.string = inviteLink
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        didCopy = true
                    }
                }
            }
            .padding(16)
            .glassPanel(cornerRadius: Radius.card)

            Text("Anyone with this link can add memories to the board.")
                .textStyle(TypeScale.bodySM)
                .foregroundStyle(Palette.onSurfaceVariant.opacity(0.8))
        }
    }
}
