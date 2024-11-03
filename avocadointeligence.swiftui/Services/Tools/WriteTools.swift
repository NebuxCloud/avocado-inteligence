import SwiftUI

struct WriteTool {
    var caption: String
    var color: Color
    var icon: String
    var systemPrompt: String
    var shareable: Bool
}

let writeTools: [WriteTool] = [
    WriteTool(caption: NSLocalizedString("tool_romantic_caption", comment: "Romantic style"), color: .pink, icon: "heart.fill", systemPrompt: NSLocalizedString("tool_romantic_prompt", comment: "Prompt for romantic transformation"), shareable: false),
    WriteTool(caption: NSLocalizedString("tool_professional_caption", comment: "Professional style"), color: .blue, icon: "briefcase.fill", systemPrompt: NSLocalizedString("tool_professional_prompt", comment: "Prompt for professional transformation"), shareable: false),
    WriteTool(caption: NSLocalizedString("tool_poetic_caption", comment: "Poetic style"), color: .purple, icon: "pencil.tip", systemPrompt: NSLocalizedString("tool_poetic_prompt", comment: "Prompt for poetic transformation"), shareable: false),
    WriteTool(caption: NSLocalizedString("tool_summary_caption", comment: "Summary style"), color: .green, icon: "text.bubble", systemPrompt: NSLocalizedString("tool_summary_prompt", comment: "Prompt for summarizing text"), shareable: true),
    WriteTool(caption: NSLocalizedString("tool_keypoints_caption", comment: "Key Points style"), color: .orange, icon: "list.bullet", systemPrompt: NSLocalizedString("tool_keypoints_prompt", comment: "Prompt for extracting key points"), shareable: true)
]
