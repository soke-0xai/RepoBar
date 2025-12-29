import Foundation

public enum PathFormatter {
    public static func expandTilde(_ path: String) -> String {
        NSString(string: path).expandingTildeInPath
    }

    public static func abbreviateHome(_ path: String) -> String {
        NSString(string: path).abbreviatingWithTildeInPath
    }

    public static func displayString(_ path: String) -> String {
        let expanded = self.expandTilde(path)
        let resolved = URL(fileURLWithPath: expanded).resolvingSymlinksInPath().path
        return self.abbreviateHome(resolved)
    }
}
