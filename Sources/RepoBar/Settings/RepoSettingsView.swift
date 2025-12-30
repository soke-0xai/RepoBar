import RepoBarCore
import SwiftUI

struct RepoSettingsView: View {
    @Bindable var session: Session
    let appState: AppState
    @State private var newRepoInput = ""
    @State private var newRepoVisibility: RepoVisibility = .pinned
    @State private var selection = Set<String>()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manage which repositories are pinned in the menubar and which are hidden.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            RepoInputRow(
                placeholder: "owner/name",
                buttonTitle: "Add",
                text: self.$newRepoInput,
                onCommit: self.addNewRepo,
                session: self.session,
                appState: self.appState
            ) {
                Picker("Visibility", selection: self.$newRepoVisibility) {
                    ForEach([RepoVisibility.pinned, .hidden], id: \.id) { vis in
                        Text(vis.label).tag(vis)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            Table(self.rows, selection: self.$selection) {
                TableColumn("Repository") { row in
                    Text(row.name).lineLimit(1).truncationMode(.middle)
                }
                .width(min: 180, ideal: 240, max: .infinity)

                TableColumn("Visibility") { row in
                    Picker("", selection: Binding(
                        get: { row.visibility },
                        set: { newValue in Task { await self.set(row.name, to: newValue) } }
                    )) {
                        ForEach(RepoVisibility.allCases) { vis in
                            Text(vis.label).tag(vis)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140, alignment: .leading)
                }
                .width(min: 140, ideal: 160, max: 180)
            }
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .frame(minHeight: 240)
            .onDeleteCommand { self.deleteSelection() }
            .contextMenu(forSelectionType: String.self) { selection in
                Button("Pin") { Task { await self.bulkSet(selection, to: .pinned) } }
                Button("Hide") { Task { await self.bulkSet(selection, to: .hidden) } }
                Button("Set Visible") { Task { await self.bulkSet(selection, to: .visible) } }
            }

            HStack(spacing: 10) {
                Button {
                    self.deleteSelection()
                } label: {
                    Label("Remove", systemImage: "trash")
                }
                .disabled(self.selection.isEmpty)

                Spacer()

                Button("Refresh Now") {
                    self.appState.requestRefresh(cancelInFlight: true)
                }
            }
        }
        .padding()
        .onAppear {
            Task { try? await self.appState.github.prefetchedRepositories() }
        }
    }

    private var rows: [RepoRow] {
        var out: [RepoRow] = []
        for (index, name) in self.session.settings.repoList.pinnedRepositories.enumerated() {
            out.append(RepoRow(name: name, visibility: .pinned, sortKey: index))
        }
        for name in self.session.settings.repoList.hiddenRepositories where !out.contains(where: { $0.name == name }) {
            out.append(RepoRow(name: name, visibility: .hidden, sortKey: Int.max))
        }
        return out.sorted { lhs, rhs in
            if lhs.sortKey != rhs.sortKey { return lhs.sortKey < rhs.sortKey }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func addNewRepo(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        self.newRepoInput = ""
        Task { await self.set(trimmed, to: self.newRepoVisibility) }
    }

    private func set(_ name: String, to visibility: RepoVisibility) async {
        await self.appState.setVisibility(for: name, to: visibility)
    }

    private func bulkSet(_ ids: Set<String>, to visibility: RepoVisibility) async {
        for id in ids {
            await self.set(id, to: visibility)
        }
        await MainActor.run { self.selection.removeAll() }
    }

    private func deleteSelection() {
        let ids = self.selection
        Task {
            await self.bulkSet(ids, to: .visible)
        }
    }
}

// MARK: - Autocomplete helper

private struct RepoRow: Identifiable, Hashable {
    var id: String { self.name }
    let name: String
    var visibility: RepoVisibility
    let sortKey: Int
}

private struct RepoInputRow<Accessory: View>: View {
    let placeholder: String
    let buttonTitle: String
    @Binding var text: String
    var onCommit: (String) -> Void
    @Bindable var session: Session
    let appState: AppState
    var accessory: () -> Accessory
    @State private var suggestions: [Repository] = []
    @State private var isLoading = false
    @State private var showSuggestions = false
    @State private var selectedIndex = -1
    @State private var keyboardNavigating = false
    @State private var textFieldSize: CGSize = .zero
    @FocusState private var isFocused: Bool
    @State private var searchTask: Task<Void, Never>?

    private var trimmedText: String {
        self.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                ZStack(alignment: .trailing) {
                    TextField(self.placeholder, text: self.$text)
                        .textFieldStyle(.roundedBorder)
                        .focused(self.$isFocused)
                        .onChange(of: self.text) { _, _ in
                            self.keyboardNavigating = false
                            self.scheduleSearch()
                        }
                        .onSubmit { self.commit() }
                        .onTapGesture {
                            self.showSuggestions = true
                            self.scheduleSearch(immediate: true)
                        }
                        .onMoveCommand(perform: self.handleMove)
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear { self.textFieldSize = geometry.size }
                                    .onChange(of: geometry.size) { _, newSize in
                                        self.textFieldSize = newSize
                                    }
                            })
                        .background(
                            RepoAutocompleteWindowView(
                                suggestions: self.suggestions,
                                selectedIndex: self.$selectedIndex,
                                keyboardNavigating: self.keyboardNavigating,
                                onSelect: { suggestion in
                                    self.commit(suggestion)
                                    DispatchQueue.main.async {
                                        self.isFocused = true
                                    }
                                },
                                width: self.textFieldSize.width,
                                isShowing: Binding(
                                    get: {
                                        self.showSuggestions && self.isFocused && !self.suggestions.isEmpty
                                    },
                                    set: { self.showSuggestions = $0 })
                            )
                        )

                    if self.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 8)
                    }
                }

                self.accessory()

                Button(self.buttonTitle) { self.commit() }
                    .disabled(self.trimmedText.isEmpty)
            }
        }
        .onChange(of: self.isFocused) { _, newValue in
            if newValue {
                self.scheduleSearch(immediate: true)
            } else {
                self.hideSuggestionsSoon()
            }
        }
        .onDisappear { self.searchTask?.cancel() }
    }

    private func commit(_ value: String? = nil) {
        let trimmed = (value ?? self.trimmedText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        self.text = ""
        self.suggestions = []
        self.showSuggestions = false
        self.selectedIndex = -1
        self.onCommit(trimmed)
    }

    private func scheduleSearch(immediate: Bool = false) {
        self.searchTask?.cancel()
        let query = self.text
        self.searchTask = Task {
            // Debounce to avoid hammering GitHub as the user types.
            if !immediate { try? await Task.sleep(nanoseconds: 450_000_000) }
            await self.loadSuggestions(query: query)
        }
    }

    private func loadSuggestions(query: String) async {
        await MainActor.run {
            self.isLoading = true
            self.showSuggestions = self.isFocused
        }
        defer {
            Task { @MainActor in self.isLoading = false }
        }

        do {
            let includeForks = await MainActor.run { self.session.settings.repoList.showForks }
            let includeArchived = await MainActor.run { self.session.settings.repoList.showArchived }
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            let prefetched = try? await self.appState.github.prefetchedRepositories()

            let filteredPrefetched = prefetched.map {
                RepositoryFilter.apply($0, includeForks: includeForks, includeArchived: includeArchived)
            }

            let localScored: [ScoredSuggestion] = {
                guard let filteredPrefetched else { return [] }
                return filteredPrefetched.compactMap { repo in
                    guard let score = Self.score(repo: repo, query: trimmed) else { return nil }
                    return ScoredSuggestion(repo: repo, score: score + 30, sourceRank: 0)
                }
            }()

            var merged = Self.sorted(localScored)

            if trimmed.count >= 3 {
                let remote = try await self.appState.github.searchRepositories(matching: trimmed)
                let filteredRemote = RepositoryFilter.apply(remote, includeForks: includeForks, includeArchived: includeArchived)
                let remoteScored = filteredRemote.compactMap { repo in
                    guard let score = Self.score(repo: repo, query: trimmed) else { return nil }
                    return ScoredSuggestion(repo: repo, score: score, sourceRank: 1)
                }
                merged = Self.mergeScored(local: merged, remote: remoteScored, limit: 8)
            } else {
                merged = Array(merged.prefix(8))
            }

            if merged.isEmpty, let filteredPrefetched {
                merged = filteredPrefetched.prefix(8).map { repo in
                    ScoredSuggestion(repo: repo, score: 0, sourceRank: 0)
                }
            }

            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.suggestions = merged.map(\.repo)
                if self.selectedIndex >= self.suggestions.count {
                    self.selectedIndex = -1
                }
                // Keep suggestions visible while typing even if focus flickers.
                self.showSuggestions = !self.suggestions.isEmpty && (self.isFocused || !self.trimmedText.isEmpty)
            }
        } catch {
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.suggestions = []
                self.showSuggestions = false
                self.selectedIndex = -1
            }
        }
    }

    private func hideSuggestionsSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.showSuggestions = false
            self.selectedIndex = -1
        }
    }

    private struct ScoredSuggestion {
        let repo: Repository
        let score: Int
        let sourceRank: Int
    }

    private func handleMove(_ direction: MoveCommandDirection) {
        guard !self.suggestions.isEmpty else { return }
        switch direction {
        case .down:
            self.keyboardNavigating = true
            let next = self.selectedIndex + 1
            self.selectedIndex = min(next, self.suggestions.count - 1)
        case .up:
            self.keyboardNavigating = true
            let prev = self.selectedIndex - 1
            self.selectedIndex = max(prev, 0)
        default:
            break
        }
    }

    private static func sorted(_ scored: [ScoredSuggestion]) -> [ScoredSuggestion] {
        scored.sorted {
            if $0.score != $1.score { return $0.score > $1.score }
            if $0.sourceRank != $1.sourceRank { return $0.sourceRank < $1.sourceRank }
            return $0.repo.fullName.localizedCaseInsensitiveCompare($1.repo.fullName) == .orderedAscending
        }
    }

    private static func mergeScored(
        local: [ScoredSuggestion],
        remote: [ScoredSuggestion],
        limit: Int
    ) -> [ScoredSuggestion] {
        var bestByKey: [String: ScoredSuggestion] = [:]
        let insert: (ScoredSuggestion) -> Void = { scored in
            let key = scored.repo.fullName.lowercased()
            if let existing = bestByKey[key] {
                if scored.score > existing.score {
                    bestByKey[key] = scored
                }
            } else {
                bestByKey[key] = scored
            }
        }
        local.forEach(insert)
        remote.forEach(insert)
        return Array(Self.sorted(Array(bestByKey.values)).prefix(limit))
    }

    private static func score(repo: Repository, query: String) -> Int? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lowerQuery = trimmed.lowercased()
        let fullName = repo.fullName.lowercased()
        if fullName == lowerQuery { return 1_000 }
        if fullName.hasPrefix(lowerQuery) { return 700 }

        let parts = lowerQuery.split(separator: "/", omittingEmptySubsequences: false)
        let ownerQuery = parts.count > 1 ? String(parts[0]) : nil
        let repoQuery = parts.count > 1 ? String(parts[1]) : lowerQuery

        let ownerScore = Self.componentScore(
            query: ownerQuery ?? "",
            target: repo.owner,
            exact: 200,
            prefix: 120,
            substring: 80,
            subsequence: 40)
        let repoScore = Self.componentScore(
            query: repoQuery,
            target: repo.name,
            exact: 600,
            prefix: 420,
            substring: 260,
            subsequence: 160)

        var score = 0
        if let ownerScore, ownerQuery != nil {
            score += ownerScore
        }
        if let repoScore {
            score += repoScore
        }

        if ownerQuery == nil {
            if repoScore == nil {
                let ownerFallback = Self.componentScore(
                    query: lowerQuery,
                    target: repo.owner,
                    exact: 120,
                    prefix: 80,
                    substring: 60,
                    subsequence: 30)
                guard let ownerFallback else { return nil }
                score += ownerFallback
            }
        } else if (ownerScore == nil && repoScore == nil) {
            return nil
        }

        if ownerScore != nil, repoScore != nil {
            score += 40
        }
        return score == 0 ? nil : score
    }

    private static func componentScore(
        query: String,
        target: String,
        exact: Int,
        prefix: Int,
        substring: Int,
        subsequence: Int
    ) -> Int? {
        guard !query.isEmpty else { return 0 }
        let lowerTarget = target.lowercased()
        if lowerTarget == query { return exact }
        if lowerTarget.hasPrefix(query) { return prefix }
        if lowerTarget.contains(query) { return substring }
        if Self.isSubsequence(query, of: lowerTarget) { return subsequence }
        return nil
    }

    private static func isSubsequence(_ needle: String, of haystack: String) -> Bool {
        var needleIndex = needle.startIndex
        var haystackIndex = haystack.startIndex

        while needleIndex < needle.endIndex && haystackIndex < haystack.endIndex {
            if needle[needleIndex] == haystack[haystackIndex] {
                needleIndex = needle.index(after: needleIndex)
            }
            haystackIndex = haystack.index(after: haystackIndex)
        }

        return needleIndex == needle.endIndex
    }
}
