import SwiftUI

// MARK: - Themed Search Bar
public struct ThemedSearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSearch: (() -> Void)?
    
    @Environment(\.theme) private var theme
    @FocusState private var isFocused: Bool
    @State private var isSearching = false
    
    public init(
        text: Binding<String>,
        placeholder: String = "Search...",
        onSearch: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSearch = onSearch
    }
    
    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.textSecondary)
                .font(.body)
            
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit {
                    onSearch?()
                }
            
            if !text.isEmpty {
                Button {
                    text = ""
                    onSearch?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.textSecondary)
                        .font(.body)
                }
            }
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.sm)
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .stroke(isFocused ? theme.primaryColor : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Filter Bar
public struct FilterBar<T: Hashable>: View {
    let items: [T]
    @Binding var selectedItem: T?
    let getTitle: (T) -> String
    let allowDeselect: Bool
    
    @Environment(\.theme) private var theme
    
    public init(
        items: [T],
        selectedItem: Binding<T?>,
        getTitle: @escaping (T) -> String,
        allowDeselect: Bool = true
    ) {
        self.items = items
        self._selectedItem = selectedItem
        self.getTitle = getTitle
        self.allowDeselect = allowDeselect
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.sm) {
                if allowDeselect {
                    FilterChip(
                        title: "All",
                        isSelected: selectedItem == nil
                    ) {
                        selectedItem = nil
                    }
                }
                
                ForEach(items, id: \.self) { item in
                    FilterChip(
                        title: getTitle(item),
                        isSelected: selectedItem == item
                    ) {
                        if selectedItem == item && allowDeselect {
                            selectedItem = nil
                        } else {
                            selectedItem = item
                        }
                    }
                }
            }
            .padding(.horizontal, theme.spacing.md)
        }
    }
}

// MARK: - Filter Chip
public struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.theme) private var theme
    
    public init(
        title: String,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(theme.typography.bodyMedium)
                .foregroundColor(isSelected ? .white : theme.textPrimary)
                .padding(.horizontal, theme.spacing.md)
                .padding(.vertical, theme.spacing.sm)
                .background(
                    isSelected ? theme.primaryColor : theme.surfaceColor
                )
                .cornerRadius(theme.cornerRadius.pill)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.pill)
                        .stroke(
                            isSelected ? Color.clear : theme.textTertiary.opacity(0.2),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Date Picker
public struct ThemedDatePicker: View {
    @Binding var date: Date
    let title: String
    let displayedComponents: DatePickerComponents
    
    @Environment(\.theme) private var theme
    
    public init(
        title: String,
        date: Binding<Date>,
        displayedComponents: DatePickerComponents = [.date]
    ) {
        self.title = title
        self._date = date
        self.displayedComponents = displayedComponents
    }
    
    public var body: some View {
        DatePicker(
            title,
            selection: $date,
            displayedComponents: displayedComponents
        )
        .font(theme.typography.bodyMedium)
        .foregroundColor(theme.textPrimary)
        .tint(theme.primaryColor)
    }
}

// MARK: - Segmented Control
public struct ThemedSegmentedControl<T: Hashable>: View {
    let items: [T]
    @Binding var selection: T
    let getTitle: (T) -> String
    
    @Environment(\.theme) private var theme
    @Namespace private var animationNamespace
    
    public init(
        items: [T],
        selection: Binding<T>,
        getTitle: @escaping (T) -> String
    ) {
        self.items = items
        self._selection = selection
        self.getTitle = getTitle
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                SegmentButton(
                    title: getTitle(item),
                    isSelected: selection == item,
                    namespace: animationNamespace
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = item
                    }
                }
            }
        }
        .padding(4)
        .background(theme.surfaceColor)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

private struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(theme.typography.bodyMedium)
                .fontWeight(isSelected ? .medium : .regular)
                .foregroundColor(isSelected ? .white : theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.sm)
                .background(
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                                .fill(theme.primaryColor)
                                .matchedGeometryEffect(id: "selected", in: namespace)
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}