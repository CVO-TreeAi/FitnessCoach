import SwiftUI

// MARK: - Multi-Select Picker
public struct MultiSelectPicker<T: Identifiable & Hashable>: View where T.ID: Hashable {
    public struct Item {
        public let data: T
        public let title: String
        public let subtitle: String?
        public let icon: String?
        public let color: Color?
        
        public init(data: T, title: String, subtitle: String? = nil, icon: String? = nil, color: Color? = nil) {
            self.data = data
            self.title = title
            self.subtitle = subtitle
            self.icon = icon
            self.color = color
        }
    }
    
    public enum Style {
        case list
        case grid
        case chips
        case tags
        case cards
    }
    
    public enum SelectionStyle {
        case checkbox
        case toggle
        case highlight
        case badge
    }
    
    private let title: String
    private let items: [Item]
    private let selectedItems: Binding<Set<T.ID>>
    private let style: Style
    private let selectionStyle: SelectionStyle
    private let allowsMultipleSelection: Bool
    private let searchable: Bool
    private let maximumSelections: Int?
    private let onSelectionChanged: ((Set<T.ID>) -> Void)?
    
    @Environment(\.theme) private var theme
    @State private var searchText = ""
    @State private var animateSelection = false
    
    public init(
        title: String,
        items: [Item],
        selectedItems: Binding<Set<T.ID>>,
        style: Style = .list,
        selectionStyle: SelectionStyle = .checkbox,
        allowsMultipleSelection: Bool = true,
        searchable: Bool = false,
        maximumSelections: Int? = nil,
        onSelectionChanged: ((Set<T.ID>) -> Void)? = nil
    ) {
        self.title = title
        self.items = items
        self.selectedItems = selectedItems
        self.style = style
        self.selectionStyle = selectionStyle
        self.allowsMultipleSelection = allowsMultipleSelection
        self.searchable = searchable
        self.maximumSelections = maximumSelections
        self.onSelectionChanged = onSelectionChanged
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            headerView
            
            if searchable {
                searchBar
            }
            
            selectionSummary
            
            Group {
                switch style {
                case .list:
                    listView
                case .grid:
                    gridView
                case .chips:
                    chipsView
                case .tags:
                    tagsView
                case .cards:
                    cardsView
                }
            }
        }
        .padding(theme.spacing.md)
        .background(theme.cardColor)
        .cornerRadius(theme.cornerRadius.card)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(title)
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(theme.textPrimary)
                
                if let maxSelections = maximumSelections {
                    Text("Select up to \(maxSelections) items")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.textTertiary)
                } else if allowsMultipleSelection {
                    Text("Select multiple items")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.textTertiary)
                } else {
                    Text("Select one item")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.textTertiary)
                }
            }
            
            Spacer()
            
            if selectedItems.wrappedValue.count > 0 {
                Button("Clear All") {
                    withAnimation(theme.animations.springFast) {
                        selectedItems.wrappedValue.removeAll()
                        onSelectionChanged?(selectedItems.wrappedValue)
                    }
                }
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.errorColor)
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.textTertiary)
            
            TextField("Search items...", text: $searchText)
                .font(theme.typography.bodyMedium)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.textTertiary)
                }
            }
        }
        .padding(theme.spacing.sm)
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.md)
    }
    
    // MARK: - Selection Summary
    
    private var selectionSummary: some View {
        Group {
            if !selectedItems.wrappedValue.isEmpty {
                HStack {
                    Text("\(selectedItems.wrappedValue.count) selected")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.primaryColor)
                    
                    Spacer()
                    
                    if let maxSelections = maximumSelections {
                        ProgressView(
                            value: Double(selectedItems.wrappedValue.count),
                            total: Double(maxSelections)
                        )
                        .tint(selectionProgressColor)
                        .frame(width: 60)
                        .scaleEffect(y: 0.8)
                    }
                }
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, theme.spacing.xs)
                .background(theme.primaryColor.opacity(0.1))
                .cornerRadius(theme.cornerRadius.sm)
            }
        }
    }
    
    // MARK: - List View
    
    private var listView: some View {
        VStack(spacing: theme.spacing.xs) {
            ForEach(filteredItems, id: \.data.id) { item in
                listItemView(item)
            }
        }
    }
    
    private func listItemView(_ item: Item) -> some View {
        Button(action: { toggleSelection(item.data.id) }) {
            HStack(spacing: theme.spacing.sm) {
                // Selection indicator
                selectionIndicator(for: item.data.id)
                
                // Icon
                if let icon = item.icon {
                    Image(systemName: icon)
                        .foregroundColor(item.color ?? theme.primaryColor)
                        .font(.title3)
                        .frame(width: 24, height: 24)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.textPrimary)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(theme.typography.labelSmall)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
                Spacer()
                
                if selectedItems.wrappedValue.contains(item.data.id) {
                    Image(systemName: "checkmark")
                        .foregroundColor(theme.primaryColor)
                        .font(.caption)
                        .scaleEffect(animateSelection ? 1.2 : 1.0)
                        .animation(theme.animations.springFast, value: animateSelection)
                }
            }
            .padding(theme.spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius.md)
                    .fill(isItemSelected(item.data.id) ? theme.primaryColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.md)
                    .stroke(
                        isItemSelected(item.data.id) ? theme.primaryColor : theme.surfaceColor,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(theme.animations.springFast, value: selectedItems.wrappedValue)
    }
    
    // MARK: - Grid View
    
    private var gridView: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: 2),
            spacing: theme.spacing.sm
        ) {
            ForEach(filteredItems, id: \.data.id) { item in
                gridItemView(item)
            }
        }
    }
    
    private func gridItemView(_ item: Item) -> some View {
        Button(action: { toggleSelection(item.data.id) }) {
            VStack(spacing: theme.spacing.sm) {
                ZStack {
                    if let icon = item.icon {
                        Image(systemName: icon)
                            .foregroundColor(item.color ?? theme.primaryColor)
                            .font(.title)
                    }
                    
                    // Selection badge
                    VStack {
                        HStack {
                            Spacer()
                            if selectedItems.wrappedValue.contains(item.data.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.primaryColor)
                                    .background(Circle().fill(Color.white))
                                    .font(.caption)
                            }
                        }
                        Spacer()
                    }
                }
                .frame(height: 60)
                
                VStack(spacing: 2) {
                    Text(item.title)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(theme.typography.labelSmall)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(theme.spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius.md)
                    .fill(isItemSelected(item.data.id) ? theme.primaryColor.opacity(0.1) : theme.surfaceColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.md)
                    .stroke(
                        isItemSelected(item.data.id) ? theme.primaryColor : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isItemSelected(item.data.id) ? 1.02 : 1.0)
            .animation(theme.animations.springFast, value: selectedItems.wrappedValue)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Chips View
    
    private var chipsView: some View {
        FlexibleView(data: filteredItems, spacing: theme.spacing.xs, alignment: .leading) { item in
            chipItemView(item)
        }
    }
    
    private func chipItemView(_ item: Item) -> some View {
        Button(action: { toggleSelection(item.data.id) }) {
            HStack(spacing: theme.spacing.xs) {
                if let icon = item.icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                
                Text(item.title)
                    .font(theme.typography.labelMedium)
                
                if selectedItems.wrappedValue.contains(item.data.id) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
            }
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xs)
            .background(
                Capsule()
                    .fill(isItemSelected(item.data.id) ? theme.primaryColor : theme.surfaceColor)
            )
            .foregroundColor(isItemSelected(item.data.id) ? .white : theme.textPrimary)
            .animation(theme.animations.springFast, value: selectedItems.wrappedValue)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Tags View
    
    private var tagsView: some View {
        FlexibleView(data: filteredItems, spacing: theme.spacing.xs, alignment: .leading) { item in
            tagItemView(item)
        }
    }
    
    private func tagItemView(_ item: Item) -> some View {
        Button(action: { toggleSelection(item.data.id) }) {
            Text(item.title)
                .font(theme.typography.labelMedium)
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, theme.spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                        .fill(isItemSelected(item.data.id) ? theme.primaryColor.opacity(0.2) : theme.surfaceColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                        .stroke(
                            isItemSelected(item.data.id) ? theme.primaryColor : theme.surfaceColor,
                            lineWidth: 1
                        )
                )
                .foregroundColor(isItemSelected(item.data.id) ? theme.primaryColor : theme.textSecondary)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(theme.animations.springFast, value: selectedItems.wrappedValue)
    }
    
    // MARK: - Cards View
    
    private var cardsView: some View {
        VStack(spacing: theme.spacing.sm) {
            ForEach(filteredItems, id: \.data.id) { item in
                cardItemView(item)
            }
        }
    }
    
    private func cardItemView(_ item: Item) -> some View {
        Button(action: { toggleSelection(item.data.id) }) {
            HStack(spacing: theme.spacing.md) {
                // Icon or color indicator
                Group {
                    if let icon = item.icon {
                        Image(systemName: icon)
                            .foregroundColor(item.color ?? theme.primaryColor)
                            .font(.title2)
                    } else if let color = item.color {
                        RoundedRectangle(cornerRadius: theme.cornerRadius.sm)
                            .fill(color)
                            .frame(width: 32, height: 32)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(item.title)
                        .font(theme.typography.bodyLarge)
                        .foregroundColor(theme.textPrimary)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                selectionIndicator(for: item.data.id)
            }
            .padding(theme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius.card)
                    .fill(theme.surfaceColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.card)
                    .stroke(
                        isItemSelected(item.data.id) ? theme.primaryColor : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isItemSelected(item.data.id) ? 1.01 : 1.0)
        .animation(theme.animations.springFast, value: selectedItems.wrappedValue)
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func selectionIndicator(for id: T.ID) -> some View {
        switch selectionStyle {
        case .checkbox:
            Image(systemName: isItemSelected(id) ? "checkmark.square.fill" : "square")
                .foregroundColor(isItemSelected(id) ? theme.primaryColor : theme.textTertiary)
                .font(.title3)
                
        case .toggle:
            Toggle("", isOn: Binding(
                get: { isItemSelected(id) },
                set: { _ in toggleSelection(id) }
            ))
            .labelsHidden()
            
        case .highlight:
            Circle()
                .fill(isItemSelected(id) ? theme.primaryColor : Color.clear)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(theme.textTertiary, lineWidth: 1)
                )
                
        case .badge:
            if isItemSelected(id) {
                Text("✓")
                    .font(theme.typography.labelSmall)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Circle().fill(theme.primaryColor))
            }
        }
    }
    
    // MARK: - Helper Properties and Methods
    
    private var filteredItems: [Item] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { item in
            item.title.localizedCaseInsensitiveContains(searchText) ||
            item.subtitle?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
    
    private var selectionProgressColor: Color {
        guard let maxSelections = maximumSelections else { return theme.primaryColor }
        let progress = Double(selectedItems.wrappedValue.count) / Double(maxSelections)
        
        switch progress {
        case 0..<0.7:
            return theme.successColor
        case 0.7..<0.9:
            return theme.warningColor
        default:
            return theme.errorColor
        }
    }
    
    private func isItemSelected(_ id: T.ID) -> Bool {
        selectedItems.wrappedValue.contains(id)
    }
    
    private func toggleSelection(_ id: T.ID) {
        withAnimation(theme.animations.springFast) {
            animateSelection = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(theme.animations.springFast) {
                animateSelection = false
            }
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        if allowsMultipleSelection {
            if selectedItems.wrappedValue.contains(id) {
                selectedItems.wrappedValue.remove(id)
            } else {
                // Check maximum selections
                if let maxSelections = maximumSelections,
                   selectedItems.wrappedValue.count >= maxSelections {
                    return
                }
                selectedItems.wrappedValue.insert(id)
            }
        } else {
            selectedItems.wrappedValue = Set([id])
        }
        
        onSelectionChanged?(selectedItems.wrappedValue)
    }
}

// MARK: - Flexible Layout View
private struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    
    @State private var availableWidth: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: alignment, vertical: .center)) {
            Color.clear
                .frame(height: 1)
                .readSize { size in
                    availableWidth = size.width
                }
            
            FlexibleViewLayout(
                availableWidth: availableWidth,
                data: data,
                spacing: spacing,
                alignment: alignment,
                content: content
            )
        }
    }
}

private struct FlexibleViewLayout<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let availableWidth: CGFloat
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    
    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            ForEach(computeRows(), id: \.self) { rowData in
                HStack(spacing: spacing) {
                    ForEach(rowData, id: \.self) { item in
                        content(item)
                    }
                }
            }
        }
    }
    
    func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentRow = 0
        var remainingWidth = availableWidth
        
        for item in data {
            let itemWidth = estimatedItemWidth(item)
            
            if remainingWidth >= itemWidth {
                rows[currentRow].append(item)
                remainingWidth -= (itemWidth + spacing)
            } else {
                rows.append([item])
                currentRow += 1
                remainingWidth = availableWidth - itemWidth
            }
        }
        
        return rows
    }
    
    func estimatedItemWidth(_ item: Data.Element) -> CGFloat {
        // This is a simple estimation - in a real implementation,
        // you might want to measure the actual content
        return 80
    }
}

// MARK: - Size Reading Extension
private extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

// MARK: - Preview
#Preview {
    struct PreviewItem: Identifiable, Hashable {
        let id = UUID()
        let name: String
    }
    
    @State var selectedItems: Set<UUID> = []
    
    let items: [MultiSelectPicker<PreviewItem>.Item] = [
        .init(data: PreviewItem(name: "Cardio"), title: "Cardio", subtitle: "Heart health", icon: "heart.fill", color: .red),
        .init(data: PreviewItem(name: "Strength"), title: "Strength", subtitle: "Build muscle", icon: "dumbbell.fill", color: .blue),
        .init(data: PreviewItem(name: "Flexibility"), title: "Flexibility", subtitle: "Stay mobile", icon: "figure.yoga", color: .green),
        .init(data: PreviewItem(name: "Balance"), title: "Balance", subtitle: "Core stability", icon: "figure.mind.and.body", color: .purple),
        .init(data: PreviewItem(name: "Endurance"), title: "Endurance", subtitle: "Stay longer", icon: "figure.run", color: .orange),
        .init(data: PreviewItem(name: "Recovery"), title: "Recovery", subtitle: "Rest well", icon: "bed.double.fill", color: .cyan)
    ]
    
    return ScrollView {
        VStack(spacing: 32) {
            MultiSelectPicker(
                title: "Choose Workout Types",
                items: items,
                selectedItems: $selectedItems,
                style: .list,
                selectionStyle: .checkbox,
                searchable: true,
                maximumSelections: 3
            )
            
            MultiSelectPicker(
                title: "Grid Style",
                items: items,
                selectedItems: $selectedItems,
                style: .grid,
                selectionStyle: .highlight
            )
            
            MultiSelectPicker(
                title: "Chips Style",
                items: items,
                selectedItems: $selectedItems,
                style: .chips
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .theme(FitnessTheme())
}