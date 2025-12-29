import SwiftUI
import PocketMeshServices

/// Information about a single repeater that relayed a message
struct RepeaterInfo: Identifiable, Codable, Sendable {
    var id: String { prefix }
    let prefix: String
    let snr: Double?
    let heardAt: Date
}

/// Configuration for message bubble appearance and behavior
struct MessageBubbleConfiguration: Sendable {
    let accentColor: Color
    let showSenderName: Bool
    let senderNameResolver: (@Sendable (MessageDTO) -> String)?
    let contacts: [ContactDTO]

    static let directMessage = MessageBubbleConfiguration(
        accentColor: .blue,
        showSenderName: false,
        senderNameResolver: nil,
        contacts: []
    )

    static func channel(isPublic: Bool, contacts: [ContactDTO]) -> MessageBubbleConfiguration {
        MessageBubbleConfiguration(
            accentColor: isPublic ? .green : .blue,
            showSenderName: true,
            senderNameResolver: { message in
                resolveSenderName(for: message, contacts: contacts)
            },
            contacts: contacts
        )
    }

    private static func resolveSenderName(for message: MessageDTO, contacts: [ContactDTO]) -> String {
        // First, try parsed sender name from channel message
        if let senderName = message.senderNodeName, !senderName.isEmpty {
            return senderName
        }

        // Fallback: key prefix lookup
        guard let prefix = message.senderKeyPrefix else {
            return "Unknown"
        }

        // Try to find matching contact
        if let contact = contacts.first(where: { contact in
            contact.publicKey.count >= prefix.count &&
            Array(contact.publicKey.prefix(prefix.count)) == Array(prefix)
        }) {
            return contact.displayName
        }

        // Fallback to hex representation
        if prefix.count >= 2 {
            return prefix.prefix(2).map { String(format: "%02X", $0) }.joined()
        }
        return "Unknown"
    }
}

/// Unified message bubble for both direct and channel messages
struct UnifiedMessageBubble: View {
    let message: MessageDTO
    let contactName: String
    let contactNodeName: String
    let deviceName: String
    let configuration: MessageBubbleConfiguration
    let showTimestamp: Bool
    let onRetry: (() -> Void)?
    let onReply: ((String) -> Void)?
    let onDelete: (() -> Void)?
    
    @State private var showingRepeaterDetails = false

    init(
        message: MessageDTO,
        contactName: String,
        contactNodeName: String,
        deviceName: String = "Me",
        configuration: MessageBubbleConfiguration,
        showTimestamp: Bool = false,
        onRetry: (() -> Void)? = nil,
        onReply: ((String) -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.message = message
        self.contactName = contactName
        self.contactNodeName = contactNodeName
        self.deviceName = deviceName
        self.configuration = configuration
        self.showTimestamp = showTimestamp
        self.onRetry = onRetry
        self.onReply = onReply
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(spacing: 2) {
            // Centered timestamp (iMessage-style)
            if showTimestamp {
                MessageTimestampView(date: message.date)
            }

            // Bubble content (aligned based on direction)
            HStack(alignment: .bottom, spacing: 4) {
                if message.isOutgoing {
                    Spacer(minLength: 60)
                }

                VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 2) {
                    // Sender name for incoming channel messages
                    if !message.isOutgoing && configuration.showSenderName {
                        Text(senderName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Message text with context menu
                    MentionText(message.text, baseColor: textColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(bubbleColor)
                        .clipShape(.rect(cornerRadius: 16))
                        .contextMenu {
                            contextMenuContent
                        }
                        .sheet(isPresented: $showingRepeaterDetails) {
                            repeaterDetailsSheet
                        }

                    // Status row for outgoing messages
                    if message.isOutgoing {
                        statusRow
                    }
                }

                if !message.isOutgoing {
                    Spacer(minLength: 60)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Computed Properties

    private var senderName: String {
        configuration.senderNameResolver?(message) ?? "Unknown"
    }

    private var bubbleColor: Color {
        if message.isOutgoing {
            return message.hasFailed ? .red.opacity(0.8) : configuration.accentColor
        } else {
            return Color(.systemGray5)
        }
    }

    private var textColor: Color {
        message.isOutgoing ? .white : .primary
    }

    // MARK: - Context Menu
    //
    // HIG: "Hide unavailable menu items, don't dim them"
    // Only show actions that have handlers provided

    @ViewBuilder
    private var contextMenuContent: some View {
        // Only show Reply for incoming messages (not outgoing)
        if let onReply, !message.isOutgoing {
            Button {
                let replyText = buildReplyText()
                onReply(replyText)
            } label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left")
            }
        }

        Button {
            UIPasteboard.general.string = message.text
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }

        // Outgoing message details shown directly (no submenu)
        if message.isOutgoing {
            Text("Sent: \(message.date.formatted(date: .abbreviated, time: .shortened))")

            if message.status == .delivered && message.heardRepeats > 0 {
                Text("Heard: \(message.heardRepeats) repeat\(message.heardRepeats == 1 ? "" : "s")")
            }

            if let rtt = message.roundTripTime {
                Text("Round trip: \(rtt)ms")
            }
            
            // Show repeater details button if available
            if shouldShowRepeaterDetails {
                Button {
                    showingRepeaterDetails = true
                } label: {
                    Label("Repeater Details", systemImage: "antenna.radiowaves.left.and.right")
                }
            }
        }

        // Incoming message details in submenu (more fields)
        if !message.isOutgoing {
            Menu {
                Text("Sent: \(message.date.formatted(date: .abbreviated, time: .shortened))")
                Text("Received: \(message.createdAt.formatted(date: .abbreviated, time: .shortened))")

                if let snr = message.snr {
                    Text("SNR: \(snrFormatted(snr))")
                }

                Text("Hops: \(hopCountFormatted(message.pathLength))")
            } label: {
                Label("Details", systemImage: "info.circle")
            }
        }

        // Only show Delete if handler is provided
        if let onDelete {
            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Status Row

    private var statusRow: some View {
        HStack(spacing: 4) {
            // Only show retry button for failed messages (not retrying)
            if message.status == .failed, let onRetry {
                Button {
                    onRetry()
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.caption2)
                }
                .buttonStyle(.borderless)
            }

            // Show spinner for retrying status
            if message.status == .retrying {
                ProgressView()
                    .controlSize(.mini)
            }

            // Only show icon for failed status
            if message.status == .failed {
                Image(systemName: "exclamationmark.circle")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }

            Text(statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            // Show heard repeats for channel messages (tap message to see details)
            if shouldShowHeardRepeats {
                Text("(\(message.heardRepeats) repeat\(message.heardRepeats == 1 ? "" : "s"))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.trailing, 4)
    }
    
    /// Determines if heard repeats count should be displayed
    private var shouldShowHeardRepeats: Bool {
        message.isOutgoing &&        // Only outgoing messages
        message.isChannelMessage &&  // Only channel messages (not DMs)
        message.heardRepeats > 0     // Only if we heard repeats (including 0 to show "Sent (0 repeats)")
    }
    
    /// Determines if repeater details button should be shown in context menu
    private var shouldShowRepeaterDetails: Bool {
        message.isOutgoing &&        // Only outgoing messages
        message.isChannelMessage &&  // Only channel messages
        message.heardRepeats > 0     // Only if we heard repeats
    }

    // MARK: - Repeater Details Sheet
    
    @ViewBuilder
    private var repeaterDetailsSheet: some View {
        NavigationStack {
            Group {
                if let repeaters = parseRepeaters(), !repeaters.isEmpty {
                    List {
                        Section {
                            HStack {
                                Text("Total Repeats Heard")
                                Spacer()
                                Text("\(message.heardRepeats)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Section("Repeaters") {
                            ForEach(repeaters) { repeater in
                                repeaterRow(for: repeater)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("Repeater Details", systemImage: "antenna.radiowaves.left.and.right")
                    } description: {
                        VStack(spacing: 12) {
                            Text("This message was heard being repeated \(message.heardRepeats) time\(message.heardRepeats == 1 ? "" : "s") by the mesh network.")
                            Text("Detailed repeater information is not yet available.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Repeater Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingRepeaterDetails = false
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func repeaterRow(for repeater: RepeaterInfo) -> some View {
        let contactName = findContactName(for: repeater.prefix)
        
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if let name = contactName {
                        Text(name)
                            .font(.headline)
                        Text("Node \(repeater.prefix)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Node \(repeater.prefix)")
                            .font(.headline)
                    }
                }
                Spacer()
                if let snr = repeater.snr {
                    let (quality, color) = signalQuality(snr: snr)
                    Text(quality)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.2))
                        .foregroundStyle(color)
                        .clipShape(.capsule)
                }
            }
            
            HStack {
                Label {
                    Text(repeater.heardAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let snr = repeater.snr {
                    Spacer()
                    Label {
                        Text("\(snr.formatted(.number.precision(.fractionLength(1)))) dB")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "waveform")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    /// Find contact name by matching the hex prefix (typically 1 byte = 2 hex chars)
    /// Only searches repeater-type contacts for efficiency and correctness
    private func findContactName(for hexPrefix: String) -> String? {
        // Normalize hex string (uppercase, remove spaces)
        let normalizedHex = hexPrefix.uppercased().replacingOccurrences(of: " ", with: "")
        
        // Must be valid hex (even number of chars, at least 2)
        guard normalizedHex.count >= 2, normalizedHex.count % 2 == 0 else { 
            print("⚠️ Invalid hex prefix: \(hexPrefix)")
            return nil 
        }
        
        // Convert hex prefix string to Data
        var prefixData = Data()
        var index = normalizedHex.startIndex
        while index < normalizedHex.endIndex {
            let nextIndex = normalizedHex.index(index, offsetBy: 2)
            let hexByte = String(normalizedHex[index..<nextIndex])
            if let byte = UInt8(hexByte, radix: 16) {
                prefixData.append(byte)
            }
            index = nextIndex
        }
        
        guard !prefixData.isEmpty else { 
            print("⚠️ Empty prefix data from: \(hexPrefix)")
            return nil 
        }
        
        // Filter to only repeater-type contacts for efficiency and correctness
        let repeaters = configuration.contacts.filter { $0.type == .repeater }
        
        print("🔍 Looking for repeater matching prefix: \(prefixData.map { String(format: "%02X", $0) }.joined()) (\(prefixData.count) byte(s))")
        print("📋 Searching through \(repeaters.count) repeater(s) (out of \(configuration.contacts.count) total contacts)")
        
        // Try to match against repeaters only
        for repeater in repeaters {
            let repeaterPrefix = repeater.publicKey.prefix(prefixData.count)
            let repeaterPrefixHex = repeaterPrefix.map { String(format: "%02X", $0) }.joined()
            let prefixHex = prefixData.map { String(format: "%02X", $0) }.joined()
            
            // Check if repeater's public key starts with this prefix
            if repeater.publicKey.count >= prefixData.count &&
               repeaterPrefix == prefixData {
                print("   ✅ MATCH! \(repeater.displayName): \(repeaterPrefixHex) matches \(prefixHex)")
                return repeater.displayName
            } else {
                print("   ❌ \(repeater.displayName): \(repeaterPrefixHex) != \(prefixHex)")
            }
        }
        
        print("   ❌ No repeater found matching prefix: \(prefixData.map { String(format: "%02X", $0) }.joined())")
        return nil
    }
    
    private func signalQuality(snr: Double) -> (String, Color) {
        switch snr {
        case 10...:
            return ("Excellent", .green)
        case 5..<10:
            return ("Good", .blue)
        case 0..<5:
            return ("Fair", .orange)
        case -10..<0:
            return ("Poor", .orange)
        default:
            return ("Very Poor", .red)
        }
    }
    
    private func parseRepeaters() -> [RepeaterInfo]? {
        guard let jsonString = message.repeaterInfoJSON,
              let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([RepeaterInfo].self, from: jsonData)
        } catch {
            print("Failed to decode repeater info: \(error)")
            return nil
        }
    }

    private var statusText: String {
        switch message.status {
        case .pending:
            return "Sending..."
        case .sending:
            return "Sending..."
        case .sent:
            return "Sent"
        case .delivered:
            return "Delivered"
        case .failed:
            return "Failed"
        case .retrying:
            return "Retrying..."
        }
    }

    // MARK: - Helpers

    /// Builds reply preview text with mention and proper Unicode/locale handling
    ///
    /// Format: @[nodeContactName]"preview.."\n
    ///
    /// Per CLAUDE.md: Use localizedStandard APIs for text filtering.
    /// This handles:
    /// - Unicode word boundaries (emoji, CJK characters)
    /// - RTL languages (Arabic, Hebrew)
    /// - Messages without spaces (Asian languages)
    private func buildReplyText() -> String {
        // Determine the mesh network name for the mention
        let mentionName: String
        if configuration.showSenderName {
            // Channel message - use sender's node name (from message)
            mentionName = message.senderNodeName ?? senderName
        } else {
            // Direct message - use contact's mesh network name
            mentionName = contactNodeName
        }

        // Use locale-aware word enumeration for proper Unicode handling
        // Count up to 3 words to know if there's more than 2
        var wordCount = 0
        var secondWordEndIndex = message.text.startIndex
        message.text.enumerateSubstrings(
            in: message.text.startIndex...,
            options: [.byWords, .localized]
        ) { _, range, _, stop in
            wordCount += 1
            if wordCount <= 2 {
                secondWordEndIndex = range.upperBound
            }
            if wordCount >= 3 {
                stop = true
            }
        }

        // Build preview
        let preview: String
        let hasMore: Bool
        if wordCount > 0 {
            preview = String(message.text[..<secondWordEndIndex]).trimmingCharacters(in: .whitespaces)
            // Only show ".." if message has more than 2 words
            hasMore = wordCount > 2
        } else {
            // Fallback for messages without word boundaries (pure emoji, etc.)
            // Take first ~20 characters
            let maxChars = min(20, message.text.count)
            let index = message.text.index(message.text.startIndex, offsetBy: maxChars)
            preview = String(message.text[..<index])
            hasMore = maxChars < message.text.count
        }

        let suffix = hasMore ? ".." : ""
        let mention = MentionUtilities.createMention(for: mentionName)
        return "\(mention)\"\(preview)\(suffix)\"\n"
    }

    private func snrFormatted(_ snr: Double) -> String {
        let quality: String
        switch snr {
        case 10...:
            quality = "Excellent"
        case 5..<10:
            quality = "Good"
        case 0..<5:
            quality = "Fair"
        case -10..<0:
            quality = "Poor"
        default:
            quality = "Very Poor"
        }
        return "\(snr.formatted(.number.precision(.fractionLength(1)))) dB (\(quality))"
    }

    private func hopCountFormatted(_ pathLength: UInt8) -> String {
        switch pathLength {
        case 0, 0xFF:  // 0 = zero hops, 0xFF = direct/unknown (no route tracking)
            return "Direct"
        default:
            return "\(pathLength)"
        }
    }
}

// MARK: - Previews

#Preview("Direct - Outgoing Sent") {
    let message = Message(
        deviceID: UUID(),
        contactID: UUID(),
        text: "Hello! How are you doing today?",
        directionRawValue: MessageDirection.outgoing.rawValue,
        statusRawValue: MessageStatus.sent.rawValue
    )
    return UnifiedMessageBubble(
        message: MessageDTO(from: message),
        contactName: "Alice",
        contactNodeName: "Alice",
        deviceName: "My Device",
        configuration: .directMessage
    )
}

#Preview("Direct - Outgoing Delivered") {
    let message = Message(
        deviceID: UUID(),
        contactID: UUID(),
        text: "This message was delivered successfully!",
        directionRawValue: MessageDirection.outgoing.rawValue,
        statusRawValue: MessageStatus.delivered.rawValue,
        roundTripTime: 1234,
        heardRepeats: 2
    )
    return UnifiedMessageBubble(
        message: MessageDTO(from: message),
        contactName: "Bob",
        contactNodeName: "Bob",
        deviceName: "My Device",
        configuration: .directMessage
    )
}

#Preview("Direct - Outgoing Failed") {
    let message = Message(
        deviceID: UUID(),
        contactID: UUID(),
        text: "This message failed to send",
        directionRawValue: MessageDirection.outgoing.rawValue,
        statusRawValue: MessageStatus.failed.rawValue
    )
    return UnifiedMessageBubble(
        message: MessageDTO(from: message),
        contactName: "Charlie",
        contactNodeName: "Charlie",
        deviceName: "My Device",
        configuration: .directMessage,
        onRetry: { print("Retry tapped") }
    )
}

#Preview("Channel - Public Incoming") {
    let message = Message(
        deviceID: UUID(),
        channelIndex: 1,
        text: "Hello from the public channel!",
        directionRawValue: MessageDirection.incoming.rawValue,
        statusRawValue: MessageStatus.delivered.rawValue,
        senderNodeName: "RemoteNode"
    )
    return UnifiedMessageBubble(
        message: MessageDTO(from: message),
        contactName: "General",
        contactNodeName: "General",
        deviceName: "My Device",
        configuration: .channel(isPublic: true, contacts: [])
    )
}

#Preview("Channel - Private Outgoing") {
    let message = Message(
        deviceID: UUID(),
        channelIndex: 2,
        text: "Private channel message",
        directionRawValue: MessageDirection.outgoing.rawValue,
        statusRawValue: MessageStatus.sent.rawValue
    )
    return UnifiedMessageBubble(
        message: MessageDTO(from: message),
        contactName: "Private Group",
        contactNodeName: "Private Group",
        deviceName: "My Device",
        configuration: .channel(isPublic: false, contacts: [])
    )
}
#Preview("Channel - Outgoing with 2 Repeats") {
    let message = Message(
        deviceID: UUID(),
        channelIndex: 0,
        text: "Hey that's good news!",
        directionRawValue: MessageDirection.outgoing.rawValue,
        statusRawValue: MessageStatus.sent.rawValue,
        heardRepeats: 2
    )
    return UnifiedMessageBubble(
        message: MessageDTO(from: message),
        contactName: "Public Channel",
        contactNodeName: "Public Channel",
        deviceName: "My Device",
        configuration: .channel(isPublic: true, contacts: [])
    )
    .padding()
}

#Preview("Channel - Outgoing with 5 Repeats") {
    let message = Message(
        deviceID: UUID(),
        channelIndex: 0,
        text: "Message with many repeaters!",
        directionRawValue: MessageDirection.outgoing.rawValue,
        statusRawValue: MessageStatus.sent.rawValue,
        heardRepeats: 5
    )
    return UnifiedMessageBubble(
        message: MessageDTO(from: message),
        contactName: "Public Channel",
        contactNodeName: "Public Channel",
        deviceName: "My Device",
        configuration: .channel(isPublic: true, contacts: [])
    )
    .padding()
}

#Preview("Channel - Outgoing with 0 Repeats") {
    let message = Message(
        deviceID: UUID(),
        channelIndex: 0,
        text: "Just sent, no repeats heard yet",
        directionRawValue: MessageDirection.outgoing.rawValue,
        statusRawValue: MessageStatus.sent.rawValue,
        heardRepeats: 0
    )
    return UnifiedMessageBubble(
        message: MessageDTO(from: message),
        contactName: "Public Channel",
        contactNodeName: "Public Channel",
        deviceName: "My Device",
        configuration: .channel(isPublic: true, contacts: [])
    )
    .padding()
}

#Preview("Direct - Outgoing with Repeats (Should NOT show)") {
    let message = Message(
        deviceID: UUID(),
        contactID: UUID(),
        text: "Direct message with repeats (won't show count)",
        directionRawValue: MessageDirection.outgoing.rawValue,
        statusRawValue: MessageStatus.delivered.rawValue,
        heardRepeats: 3
    )
    return UnifiedMessageBubble(
        message: MessageDTO(from: message),
        contactName: "Alice",
        contactNodeName: "Alice",
        deviceName: "My Device",
        configuration: .directMessage
    )
    .padding()
}

#Preview("Channel - With Repeater Details") {
    // Example: Message went through 2 repeaters: 56 (JT repeater) and E0
    let jsonString = """
    [
        {"prefix":"56","snr":12.5,"heardAt":"2024-12-28T10:30:00Z"},
        {"prefix":"E0","snr":-4.8,"heardAt":"2024-12-28T10:30:01Z"}
    ]
    """
    
    let message = Message(
        deviceID: UUID(),
        channelIndex: 0,
        text: "Message with detailed repeater info! Long press to see details.",
        directionRawValue: MessageDirection.outgoing.rawValue,
        statusRawValue: MessageStatus.sent.rawValue,
        heardRepeats: 2,
        repeaterInfoJSON: jsonString
    )
    return UnifiedMessageBubble(
        message: MessageDTO(from: message),
        contactName: "Public Channel",
        contactNodeName: "Public Channel",
        deviceName: "My Device",
        configuration: .channel(isPublic: true, contacts: [])
    )
    .padding()
}

#Preview("Channel - With Named Repeaters") {
    // Create mock contacts that match the repeater prefixes
    let deviceID = UUID()
    
    // JT repeater with public key starting with 0x56
    let jtRepeater = Contact(
        deviceID: deviceID,
        publicKey: Data([0x56, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
        name: "JT Repeater",
        typeRawValue: 1 // Repeater type
    )
    
    // Mountain repeater with public key starting with 0xE0
    let mountainRepeater = Contact(
        deviceID: deviceID,
        publicKey: Data([0xE0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
        name: "Mountain Repeater",
        typeRawValue: 1
    )
    
    let contacts = [
        ContactDTO(from: jtRepeater),
        ContactDTO(from: mountainRepeater)
    ]
    
    let jsonString = """
    [
        {"prefix":"56","snr":12.5,"heardAt":"2024-12-28T10:30:00Z"},
        {"prefix":"E0","snr":-4.8,"heardAt":"2024-12-28T10:30:01Z"}
    ]
    """
    
    let message = Message(
        deviceID: deviceID,
        channelIndex: 0,
        text: "This message shows named repeaters! Long press to see 'JT Repeater' and 'Mountain Repeater'.",
        directionRawValue: MessageDirection.outgoing.rawValue,
        statusRawValue: MessageStatus.sent.rawValue,
        heardRepeats: 2,
        repeaterInfoJSON: jsonString
    )
    
    return UnifiedMessageBubble(
        message: MessageDTO(from: message),
        contactName: "Public Channel",
        contactNodeName: "Public Channel",
        deviceName: "My Device",
        configuration: .channel(isPublic: true, contacts: contacts)
    )
    .padding()
}

