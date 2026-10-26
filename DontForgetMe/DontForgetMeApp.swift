import SwiftUI

@main
struct DontForgetMeApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(model).preferredColorScheme(.light)
                .onChange(of: phase) { _, value in if value == .active { model.refreshPermissions() } }
        }
    }
}

extension Color {
    static let ink = Color(red: 0.12, green: 0.22, blue: 0.22)
    static let leaf = Color(red: 0.29, green: 0.66, blue: 0.36)
    static let cream = Color(red: 0.98, green: 0.98, blue: 0.95)
    static let mint = Color(red: 0.89, green: 0.95, blue: 0.85)
}
struct ChunkyButton: ButtonStyle {
    var color: Color = .leaf
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(.headline, design: .rounded, weight: .heavy))
            .frame(maxWidth: .infinity).padding(.vertical, 18).foregroundStyle(.white)
            .background(color, in: RoundedRectangle(cornerRadius: 19))
            .shadow(color: color.opacity(0.5), radius: 0, y: configuration.isPressed ? 0 : 5)
            .offset(y: configuration.isPressed ? 4 : 0)
    }
}
struct Card: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(20).background(.white, in: RoundedRectangle(cornerRadius: 25))
            .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.ink.opacity(0.10), lineWidth: 2))
    }
}

/// Original vector backpack mascot; scales with the interface without image assets.
struct Smile: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in p.move(to: CGPoint(x: rect.minX, y: rect.minY)); p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.maxY * 1.6)) }
    }
}
struct Backpack: View {
    var happy = true
    var body: some View {
        ZStack {
            Ellipse().fill(Color.ink.opacity(0.08)).frame(width: 160, height: 22).offset(y: 92)
            RoundedRectangle(cornerRadius: 15).stroke(Color.ink, lineWidth: 9).frame(width: 50, height: 35).offset(y: -72)
            Capsule().fill(Color.ink).frame(width: 18, height: 40).rotationEffect(.degrees(15)).offset(x: -42, y: 82)
            Capsule().fill(Color.ink).frame(width: 18, height: 40).rotationEffect(.degrees(-15)).offset(x: 42, y: 82)
            RoundedRectangle(cornerRadius: 34).fill(Color.leaf).frame(width: 144, height: 157)
                .overlay(RoundedRectangle(cornerRadius: 34).stroke(Color.ink, lineWidth: 4))
            RoundedRectangle(cornerRadius: 22).fill(Color.mint).frame(width: 112, height: 64).offset(y: 36)
            HStack(spacing: 30) {
                Capsule().fill(Color.ink).frame(width: 10, height: 17)
                Capsule().fill(Color.ink).frame(width: 10, height: 17)
            }.offset(y: -23)
            Smile().stroke(Color.ink, style: StrokeStyle(lineWidth: 4, lineCap: .round)).frame(width: 25, height: 12).offset(y: 1)
            HStack(spacing: 57) { Ellipse().fill(.pink.opacity(0.5)).frame(width: 18, height: 9); Ellipse().fill(.pink.opacity(0.5)).frame(width: 18, height: 9) }.offset(y: -8)
            Image(systemName: "heart.fill").font(.system(size: 23)).foregroundStyle(Color.leaf).offset(y: 39)
            Image(systemName: "sparkle").font(.system(size: 28, weight: .bold)).foregroundStyle(.orange).offset(x: -99, y: -55)
            Image(systemName: "sparkle").font(.system(size: 20, weight: .bold)).foregroundStyle(Color.leaf).offset(x: 96, y: 22)
        }.frame(height: 218).frame(maxWidth: .infinity).accessibilityLabel("Pip, your friendly backpack buddy")
    }
}

struct RootView: View {
    @EnvironmentObject var model: AppModel
    @State private var tab = 0
    var body: some View {
        Group {
            if !model.state.onboarded { WelcomeView() }
            else {
                TabView(selection: $tab) {
                    HomeView().tabItem { Label("Today", systemImage: "house.fill") }.tag(0)
                    ItemsView().tabItem { Label("My things", systemImage: "backpack.fill") }.tag(1)
                    SettingsView().tabItem { Label("Settings", systemImage: "gearshape.fill") }.tag(2)
                }.tint(.leaf)
            }
        }.fontDesign(.rounded).foregroundStyle(Color.ink)
            .fullScreenCover(isPresented: Binding(get: { model.state.reminder != nil && model.state.onboarded }, set: { _ in })) { ChecklistView().environmentObject(model).interactiveDismissDisabled() }
            .alert("A little heads-up", isPresented: Binding(get: { model.issue != nil }, set: { if !$0 { model.issue = nil } })) { Button("OK") { model.issue = nil } } message: { Text(model.issue ?? "") }
    }
}

struct WelcomeView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("DON’T FORGET ME").font(.system(.caption, design: .rounded, weight: .black)).tracking(3).padding(.top, 30)
                Backpack()
                Text("Big adventures.\nNothing left behind.").font(.system(size: 35, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
                Text("Meet Pip, your tiny buddy for the things\nthat always seem to wander off.").font(.body).multilineTextAlignment(.center).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 21) {
                    step("1", "Settle in", "Stay in one place for 20 minutes.")
                    step("2", "Head out", "Pip reminds you as you leave the area.")
                    step("3", "Check & go", "Grab your things. Stop reminders in the app.")
                }.modifier(Card())
                Button("LET’S PACK") { model.finishOnboarding() }.buttonStyle(ChunkyButton()).accessibilityIdentifier("getStarted")
                Text("Your location stays on your phone. Always.").font(.footnote).foregroundStyle(.secondary)
            }.padding(24)
        }.background(Color.cream)
    }
    func step(_ number: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Text(number).font(.headline).frame(width: 35, height: 35).background(Color.mint, in: Circle())
            VStack(alignment: .leading, spacing: 3) { Text(title).bold(); Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) { Text("A LITTLE CHECK. A BIG RELIEF.").font(.system(size: 10, weight: .black)).tracking(1.5).foregroundStyle(.secondary); Text("Hey, you’re all set.").font(.system(size: 28, weight: .heavy)) }
                        Spacer()
                        Label("\(model.state.successfulChecks)", systemImage: "star.fill").font(.headline).foregroundStyle(.orange).padding(12).background(.white, in: Capsule()).accessibilityLabel("\(model.state.successfulChecks) completed checks")
                    }
                    VStack(spacing: 4) {
                        Text(model.state.monitoring && model.canLocate ? "I’ve got your back(pack)." : "Let’s look out for your things.").font(.system(.headline, design: .rounded, weight: .bold)).padding(.top, 24)
                        Backpack()
                        HStack(spacing: 7) { Circle().fill(model.state.monitoring && model.canLocate ? Color.leaf : .orange).frame(width: 8, height: 8); Text(model.state.monitoring && model.canLocate ? "PIP IS ON THE LOOKOUT" : "PIP IS TAKING A BREAK").font(.system(size: 11, weight: .black)).tracking(1) }.padding(.bottom, 23)
                    }.frame(maxWidth: .infinity).background(Color.mint, in: RoundedRectangle(cornerRadius: 30))
                    if !model.notificationAllowed || !model.canLocate || model.locationStatus != .authorizedAlways || !model.precise {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Give Pip a little superpower", systemImage: "sparkles").font(.headline)
                            Text("Enable notifications and Always location for reminders with your phone locked.").font(.subheadline).foregroundStyle(.secondary)
                            if !model.notificationAllowed { Button("Enable notifications") { Task { await model.requestNotifications() } }.font(.headline).accessibilityIdentifier("enableNotifications") }
                            if !model.precise { Button("Enable Precise Location in Settings") { model.openSettings() } }
                            if model.locationStatus != .authorizedAlways { Button(model.canLocate ? "Allow Always location" : "Enable location") { model.requestLocation() }.font(.headline) }
                        }.modifier(Card())
                    }
                    VStack(alignment: .leading, spacing: 15) {
                        HStack { Text("Your safety net").font(.title3.bold()); Spacer(); Text("20 MIN").font(.caption.bold()).foregroundStyle(Color.leaf).padding(8).background(Color.mint, in: Capsule()) }
                        Text(model.state.stay == nil ? "Once you settle in, Pip gets ready for your next goodbye." : "You’ve settled somewhere. Pip will check your things when you leave after 20 minutes.").foregroundStyle(.secondary)
                        Button(model.state.monitoring ? "PAUSE LOOKOUT" : "START LOOKOUT") { model.setMonitoring(!model.state.monitoring) }.buttonStyle(ChunkyButton())
                        if model.state.monitoring && !model.canLocate { Text("Lookout needs location permission to work.").font(.caption).foregroundStyle(.orange) }
                    }.modifier(Card())
                    HStack { Text("Packed for your day").font(.title3.bold()); Spacer(); Text("\(model.state.items.filter(\.enabled).count) things").font(.subheadline).foregroundStyle(.secondary) }
                    ForEach(model.state.items.filter(\.enabled)) { item in
                        HStack(spacing: 16) { Image(systemName: item.symbol).font(.title2).foregroundStyle(Color.leaf).frame(width: 44, height: 44).background(Color.mint, in: RoundedRectangle(cornerRadius: 13)); Text(item.name).font(.headline); Spacer(); Image(systemName: "checkmark.shield.fill").foregroundStyle(Color.leaf) }.modifier(Card())
                    }
                    if model.state.items.filter(\.enabled).isEmpty { Text("Add or enable a thing in My things to receive reminders.").foregroundStyle(.secondary) }
                    Button("Try a practice check") { model.beginReminder() }.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 10).accessibilityIdentifier("practiceCheck")
                    Text("A small habit. A lighter mind.").font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }.padding(22)
            }.background(Color.cream).toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct ItemsView: View {
    @EnvironmentObject var model: AppModel
    @State private var adding = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("The little things matter.").font(.title.bold())
                    Text("Choose what Pip should remind you to bring. Your checklist, your everyday essentials.").foregroundStyle(.secondary)
                    ForEach(model.state.items) { item in
                        HStack(spacing: 14) {
                            Image(systemName: item.symbol).font(.title2).foregroundStyle(Color.leaf).frame(width: 40)
                            Toggle(item.name, isOn: Binding(get: { model.state.items.first(where: { $0.id == item.id })?.enabled ?? false }, set: { value in if let i = model.state.items.firstIndex(where: { $0.id == item.id }) { model.state.items[i].enabled = value; model.save() } })).tint(.leaf).font(.headline)
                            Button { model.state.items.removeAll { $0.id == item.id }; model.save() } label: { Image(systemName: "minus.circle").foregroundStyle(.secondary) }.accessibilityLabel("Delete \(item.name)")
                        }.modifier(Card())
                    }
                    Button { adding = true } label: { Label("ADD A THING", systemImage: "plus") }.buttonStyle(ChunkyButton()).accessibilityIdentifier("addThing")
                    Label("Changes apply to your next reminder.", systemImage: "heart.fill").font(.footnote).foregroundStyle(.secondary).padding(.top, 10)
                }.padding(22)
            }.background(Color.cream).navigationTitle("My things").navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $adding) { AddItemView() }
        }
    }
}
struct AddItemView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var symbol = "bag.fill"
    let symbols = ["bag.fill", "person.text.rectangle.fill", "waterbottle.fill", "key.fill", "wallet.bifold.fill", "headphones", "umbrella.fill", "eyeglasses"]
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 25) {
                Text("Every thing deserves\na way home.").font(.largeTitle.bold())
                TextField("e.g. My headphones", text: $name).textFieldStyle(.roundedBorder).accessibilityIdentifier("itemName").onChange(of: name) { _, value in name = String(value.prefix(40)) }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                    ForEach(symbols, id: \.self) { value in Button { symbol = value } label: { Image(systemName: value).font(.title2).frame(width: 58, height: 58).background(symbol == value ? Color.mint : Color.cream, in: RoundedRectangle(cornerRadius: 14)) }.accessibilityLabel(value).accessibilityAddTraits(symbol == value ? .isSelected : []) }
                }
                Button("ADD TO MY THINGS") {
                    model.state.items.append(Belonging(name: name.trimmingCharacters(in: .whitespacesAndNewlines), symbol: symbol)); model.save(); dismiss()
                }.buttonStyle(ChunkyButton()).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1).accessibilityIdentifier("saveThing")
                Spacer()
            }.padding(24).background(Color.cream).toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }.fontDesign(.rounded)
    }
}
struct ChecklistView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("THE BEFORE-YOU-GO CHECK").font(.caption.bold()).tracking(2).padding(.top, 20)
                Backpack()
                Text("Wait! Got everything?").font(.system(size: 30, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
                Text("A quick pocket pat. A peek in your bag.\nLet’s bring everyone home.").multilineTextAlignment(.center).foregroundStyle(.secondary)
                if let reminder = model.state.reminder {
                    ProgressView(value: Double(reminder.checked.count), total: Double(max(1, reminder.items.count))).tint(.leaf).accessibilityLabel("Checklist progress")
                    ForEach(reminder.items) { item in
                        Button { model.toggleCheck(item.id) } label: {
                            HStack(spacing: 15) { Image(systemName: item.symbol).font(.title2).frame(width: 35); Text(item.name).font(.headline); Spacer(); Image(systemName: reminder.checked.contains(item.id) ? "checkmark.circle.fill" : "circle").font(.title2) }.foregroundStyle(reminder.checked.contains(item.id) ? Color.leaf : Color.ink).modifier(Card())
                        }.accessibilityIdentifier("check-\(item.name)").accessibilityValue(reminder.checked.contains(item.id) ? "Packed" : "Not checked")
                    }
                    #if DEBUG
                    if model.isUITest {
                        Text("Repeat interval: \(model.repeatInterval)s")
                        Text("Delivered repeats: \(model.deliveredRepeatCount)")
                    }
                    #endif
                    Text("Reminders repeat every minute until you stop them here. Checking items is optional.").font(.footnote).multilineTextAlignment(.center).foregroundStyle(.secondary)
                }
            }.padding(24)
        }.background(Color.cream).fontDesign(.rounded).foregroundStyle(Color.ink)
            .safeAreaInset(edge: .bottom) {
                if let reminder = model.state.reminder {
                    Button(reminder.checked.count == reminder.items.count ? "ALL PACKED. LET’S GO!" : "STOP REMINDERS") { model.stopReminder() }.buttonStyle(ChunkyButton()).accessibilityIdentifier("stopReminders")
                        .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 12).background(Color.cream)
                }
            }
    }
}
struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        NavigationStack {
            List {
                Section("Pip’s routine") {
                    LabeledContent("Time to settle", value: "20 minutes")
                    LabeledContent("Leaving distance", value: "About 150 meters")
                    LabeledContent("Repeat reminder", value: "Every minute")
                }
                Section("Permissions") {
                    LabeledContent("Notifications", value: model.notificationAllowed ? "Enabled" : "Not enabled")
                    LabeledContent("Location", value: model.locationStatus == .authorizedAlways ? "Always" : model.canLocate ? "While using" : "Not enabled")
                    LabeledContent("Precise location", value: model.precise ? "On" : "Off")
                    Button("Open iPhone settings") { model.openSettings() }
                }
                Section("Made for real life") {
                    Text("Pip detects when your phone leaves a place, not whether an item is physically with you. GPS can drift, and reminders may arrive after you have left the building.")
                    Text("Allow Always location and Precise Location. Keep Background App Refresh enabled. Force-quitting the app, Focus, disabled notifications, or system battery management can delay or prevent alerts.")
                    Text("Lookout uses background location and may increase battery use. Pause it when you don’t need it. Pausing does not dismiss an existing reminder.")
                }
                Section("Private by nature") { Text("Your items and current stay are saved only on this device. No account, ads, server, or location history.") }
                #if DEBUG
                Section("Developer verification") {
                    Button("Simulate 21-minute stay & leave") { model.simulateStayAndDeparture() }.accessibilityIdentifier("simulateDeparture")
                    Text("Pending reminders: \(model.pendingCount)").accessibilityIdentifier("pendingReminders")
                    Button("Refresh notification status") { Task { await model.refreshPending() } }
                }
                #endif
            }.navigationTitle("Settings").tint(.leaf)
        }
    }
}
