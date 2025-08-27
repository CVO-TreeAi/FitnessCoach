import SwiftUI

// MARK: - Form Field Components

public struct ThemedTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let isSecure: Bool
    let errorMessage: String?
    
    @Environment(\.theme) private var theme
    
    public init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false,
        errorMessage: String? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.isSecure = isSecure
        self.errorMessage = errorMessage
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(title)
                .font(theme.bodyMediumFont)
                .foregroundColor(theme.textPrimary)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .padding(theme.spacing.md)
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                    .stroke(errorMessage != nil ? theme.errorColor : Color.clear, lineWidth: 1)
            )
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.errorColor)
            }
        }
    }
}

public struct ThemedTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let minHeight: CGFloat
    
    @Environment(\.theme) private var theme
    
    public init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        minHeight: CGFloat = 100
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(title)
                .font(theme.bodyMediumFont)
                .foregroundColor(theme.textPrimary)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: minHeight)
                
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(theme.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
            .padding(theme.spacing.md)
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
        }
    }
}

public struct ThemedPicker<SelectionValue: Hashable & CustomStringConvertible>: View {
    let title: String
    @Binding var selection: SelectionValue
    let options: [SelectionValue]
    
    @Environment(\.theme) private var theme
    
    public init(
        _ title: String,
        selection: Binding<SelectionValue>,
        options: [SelectionValue]
    ) {
        self.title = title
        self._selection = selection
        self.options = options
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(title)
                .font(theme.bodyMediumFont)
                .foregroundColor(theme.textPrimary)
            
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option.description)
                        .tag(option)
                }
            }
            .pickerStyle(.menu)
            .padding(theme.spacing.md)
            .background(theme.surfaceColor)
            .cornerRadius(theme.cornerRadius.medium)
        }
    }
}

public struct ThemedSegmentedControl<SelectionValue: Hashable & CustomStringConvertible>: View {
    let title: String?
    @Binding var selection: SelectionValue
    let options: [SelectionValue]
    
    @Environment(\.theme) private var theme
    
    public init(
        _ title: String? = nil,
        selection: Binding<SelectionValue>,
        options: [SelectionValue]
    ) {
        self.title = title
        self._selection = selection
        self.options = options
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if let title = title {
                Text(title)
                    .font(theme.bodyMediumFont)
                    .foregroundColor(theme.textPrimary)
            }
            
            Picker(title ?? "", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option.description)
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

public struct ThemedDatePicker: View {
    let title: String
    @Binding var selection: Date
    let displayedComponents: DatePickerComponents
    let dateRange: ClosedRange<Date>?
    
    @Environment(\.theme) private var theme
    
    public init(
        _ title: String,
        selection: Binding<Date>,
        displayedComponents: DatePickerComponents = [.date],
        in range: ClosedRange<Date>? = nil
    ) {
        self.title = title
        self._selection = selection
        self.displayedComponents = displayedComponents
        self.dateRange = range
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(title)
                .font(theme.bodyMediumFont)
                .foregroundColor(theme.textPrimary)
            
            if let range = dateRange {
                DatePicker(
                    title,
                    selection: $selection,
                    in: range,
                    displayedComponents: displayedComponents
                )
                .labelsHidden()
            } else {
                DatePicker(
                    title,
                    selection: $selection,
                    displayedComponents: displayedComponents
                )
                .labelsHidden()
            }
        }
    }
}

public struct ThemedSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    
    @Environment(\.theme) private var theme
    
    public init(
        _ title: String,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1.0,
        unit: String = ""
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.unit = unit
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Text(title)
                    .font(theme.bodyMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("\(Int(value))\(unit)")
                    .font(theme.bodyMediumFont)
                    .foregroundColor(theme.primaryColor)
            }
            
            Slider(
                value: $value,
                in: range,
                step: step
            )
            .accentColor(theme.primaryColor)
            
            HStack {
                Text("\(Int(range.lowerBound))")
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.textTertiary)
                
                Spacer()
                
                Text("\(Int(range.upperBound))")
                    .font(theme.bodySmallFont)
                    .foregroundColor(theme.textTertiary)
            }
        }
    }
}

public struct ThemedToggle: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    @Environment(\.theme) private var theme
    
    public init(
        _ title: String,
        isOn: Binding<Bool>,
        subtitle: String? = nil
    ) {
        self.title = title
        self._isOn = isOn
        self.subtitle = subtitle
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.bodyMediumFont)
                    .foregroundColor(theme.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(theme.bodySmallFont)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: theme.primaryColor))
        }
    }
}

// MARK: - Multi-Selection Components

public struct MultiSelectView<Item: Hashable & CustomStringConvertible>: View {
    let title: String
    let items: [Item]
    @Binding var selectedItems: Set<Item>
    
    @Environment(\.theme) private var theme
    
    public init(
        _ title: String,
        items: [Item],
        selectedItems: Binding<Set<Item>>
    ) {
        self.title = title
        self.items = items
        self._selectedItems = selectedItems
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(title)
                .font(theme.bodyMediumFont)
                .foregroundColor(theme.textPrimary)
            
            LazyVStack(spacing: theme.spacing.xs) {
                ForEach(items, id: \.self) { item in
                    HStack {
                        Text(item.description)
                            .font(theme.bodyMediumFont)
                            .foregroundColor(theme.textPrimary)
                        
                        Spacer()
                        
                        if selectedItems.contains(item) {
                            Image(systemName: "checkmark")
                                .foregroundColor(theme.primaryColor)
                        }
                    }
                    .padding(theme.spacing.md)
                    .background(
                        selectedItems.contains(item) ?
                        theme.primaryColor.opacity(0.1) :
                        theme.surfaceColor
                    )
                    .cornerRadius(theme.cornerRadius.medium)
                    .onTapGesture {
                        if selectedItems.contains(item) {
                            selectedItems.remove(item)
                        } else {
                            selectedItems.insert(item)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Rating Component

public struct StarRatingView: View {
    let title: String
    @Binding var rating: Int
    let maxRating: Int
    
    @Environment(\.theme) private var theme
    
    public init(
        _ title: String,
        rating: Binding<Int>,
        maxRating: Int = 5
    ) {
        self.title = title
        self._rating = rating
        self.maxRating = maxRating
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(title)
                .font(theme.bodyMediumFont)
                .foregroundColor(theme.textPrimary)
            
            HStack(spacing: theme.spacing.xs) {
                ForEach(1...maxRating, id: \.self) { index in
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .foregroundColor(index <= rating ? theme.primaryColor : theme.textTertiary)
                        .onTapGesture {
                            rating = index
                        }
                }
                
                if rating > 0 {
                    Text("(\(rating)/\(maxRating))")
                        .font(theme.bodySmallFont)
                        .foregroundColor(theme.textSecondary)
                        .padding(.leading, theme.spacing.sm)
                }
            }
        }
    }
}

// MARK: - Form Container

public struct ThemedForm<Content: View>: View {
    let title: String?
    let content: () -> Content
    
    @Environment(\.theme) private var theme
    
    public init(
        title: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.content = content
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            if let title = title {
                Text(title)
                    .font(theme.titleLargeFont)
                    .foregroundColor(theme.textPrimary)
            }
            
            content()
        }
        .padding(theme.spacing.lg)
        .background(theme.backgroundColor)
    }
}

// MARK: - Previews

#Preview("Form Components") {
    ScrollView {
        ThemedForm(title: "Sample Form") {
            VStack(spacing: 20) {
                ThemedTextField(
                    "Email",
                    text: .constant(""),
                    placeholder: "Enter your email",
                    keyboardType: .emailAddress
                )
                
                ThemedTextField(
                    "Password",
                    text: .constant(""),
                    placeholder: "Enter your password",
                    isSecure: true,
                    errorMessage: "Password must be at least 8 characters"
                )
                
                ThemedTextEditor(
                    "Notes",
                    text: .constant(""),
                    placeholder: "Enter your notes here..."
                )
                
                ThemedPicker(
                    "Difficulty",
                    selection: .constant("Beginner"),
                    options: ["Beginner", "Intermediate", "Advanced"]
                )
                
                ThemedSegmentedControl(
                    "Goal",
                    selection: .constant("Weight Loss"),
                    options: ["Weight Loss", "Muscle Gain", "Maintenance"]
                )
                
                ThemedDatePicker(
                    "Date of Birth",
                    selection: .constant(Date())
                )
                
                ThemedSlider(
                    "Weight",
                    value: .constant(150),
                    in: 50...300,
                    step: 1,
                    unit: " lbs"
                )
                
                ThemedToggle(
                    "Enable Notifications",
                    isOn: .constant(true),
                    subtitle: "Receive workout reminders"
                )
                
                StarRatingView(
                    "Rate your workout",
                    rating: .constant(4)
                )
                
                MultiSelectView(
                    "Muscle Groups",
                    items: ["Chest", "Back", "Shoulders", "Arms", "Legs", "Core"],
                    selectedItems: .constant(Set(["Chest", "Arms"]))
                )
            }
        }
    }
    .theme(FitnessTheme())
}