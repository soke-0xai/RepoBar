import Foundation

/// Centralized constants so limits/TTLs stay obvious and discoverable.
public enum RepoCacheConstants {
    /// Upper bound for how many repos we prefetch from `/user/repos` to power autocomplete.
    public static let maxRepositoriesToPrefetch = 1000

    /// How long the prefetched repo list stays warm before we refetch.
    public static let cacheTTL: TimeInterval = 60 * 60 // 1 hour
}
