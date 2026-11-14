import Foundation

/// Match confidence result for song migration
public enum MatchConfidence: Equatable {
    case exactISRC                     // 100% confidence via international standard code
    case highConfidence(score: Double)  // Score >= threshold with duration match
    case alternate(score: Double)       // Mid band → Rematch Inbox
    case missing                        // No plausible candidates
}

public struct MatchResult {
    public let sourceTrack: UniversalTrack
    public let matchedTrack: UniversalTrack?
    public let confidence: MatchConfidence
    public let score: Double
}

/// Matching threshold profile driven by Move advanced settings.
public struct MatchingThresholds: Equatable {
    public let highConfidenceMinimum: Double
    public let alternateMinimum: Double
    
    public static let strict = MatchingThresholds(highConfidenceMinimum: 0.92, alternateMinimum: 0.72)
    public static let flexible = MatchingThresholds(highConfidenceMinimum: 0.85, alternateMinimum: 0.55)
    
    public init(highConfidenceMinimum: Double, alternateMinimum: Double) {
        self.highConfidenceMinimum = highConfidenceMinimum
        self.alternateMinimum = alternateMinimum
    }
}

/// Precomputed candidate lookup — O(1) ISRC + optional title-prefix blocking for fuzzy scan.
public struct MatchCandidateIndex {
    public let all: [UniversalTrack]
    public let byISRC: [String: UniversalTrack]
    /// Normalized title first character → candidate indices (speeds fuzzy pass).
    public let byTitlePrefix: [Character: [Int]]
    
    public init(candidates: [UniversalTrack]) {
        self.all = candidates
        var isrcMap: [String: UniversalTrack] = [:]
        var prefixMap: [Character: [Int]] = [:]
        
        for (idx, candidate) in candidates.enumerated() {
            if let isrc = candidate.isrc?.uppercased(), !isrc.isEmpty, isrcMap[isrc] == nil {
                isrcMap[isrc] = candidate
            }
            let normalized = MatchingEngine.normalizeStatic(candidate.title)
            if let first = normalized.first {
                prefixMap[first, default: []].append(idx)
            } else {
                prefixMap["#", default: []].append(idx)
            }
        }
        
        self.byISRC = isrcMap
        self.byTitlePrefix = prefixMap
    }
}

/// 3-Tier Multi-Level Matching Engine (Plan 3 Specification)
public final class MatchingEngine {
    public var thresholds: MatchingThresholds = .strict
    
    public init(thresholds: MatchingThresholds = .strict) {
        self.thresholds = thresholds
    }
    
    /// Convenience — builds an index each call (fine for small pools / tests).
    public func match(
        source: UniversalTrack,
        candidates: [UniversalTrack]
    ) -> MatchResult {
        match(source: source, index: MatchCandidateIndex(candidates: candidates))
    }
    
    /// Preferred entry — reuse one index across a full dry-run / migration.
    public func match(
        source: UniversalTrack,
        index: MatchCandidateIndex
    ) -> MatchResult {
        // Tier 1: Exact ISRC Match (O(1))
        if let sourceISRC = source.isrc?.uppercased(), !sourceISRC.isEmpty,
           let isrcMatch = index.byISRC[sourceISRC] {
            return MatchResult(
                sourceTrack: source,
                matchedTrack: isrcMatch,
                confidence: .exactISRC,
                score: 1.0
            )
        }
        
        // Tier 2: Fuzzy — title-prefix block first, then full-scan fallback when weak
        // (prefix can miss "The Night" ↔ "Night" after normalize).
        let cleanSourceTitle = normalizeString(source.title)
        let cleanSourceArtist = normalizeString(ArtistMatchText.joined(from: source))
        let prefix = cleanSourceTitle.first ?? "#"
        var candidateIndices = index.byTitlePrefix[prefix] ?? []
        if candidateIndices.isEmpty {
            candidateIndices = Array(index.all.indices)
        }
        
        var (bestCandidate, highestScore) = bestFuzzyMatch(
            cleanSourceTitle: cleanSourceTitle,
            cleanSourceArtist: cleanSourceArtist,
            sourceDurationMs: source.durationMs,
            index: index,
            indices: candidateIndices
        )
        
        if highestScore < thresholds.highConfidenceMinimum,
           candidateIndices.count < index.all.count {
            let full = bestFuzzyMatch(
                cleanSourceTitle: cleanSourceTitle,
                cleanSourceArtist: cleanSourceArtist,
                sourceDurationMs: source.durationMs,
                index: index,
                indices: Array(index.all.indices)
            )
            if full.score > highestScore {
                bestCandidate = full.candidate
                highestScore = full.score
            }
        }
        
        if highestScore >= thresholds.highConfidenceMinimum {
            return MatchResult(
                sourceTrack: source,
                matchedTrack: bestCandidate,
                confidence: .highConfidence(score: highestScore),
                score: highestScore
            )
        } else if highestScore >= thresholds.alternateMinimum {
            return MatchResult(
                sourceTrack: source,
                matchedTrack: bestCandidate,
                confidence: .alternate(score: highestScore),
                score: highestScore
            )
        } else {
            return MatchResult(
                sourceTrack: source,
                matchedTrack: nil,
                confidence: .missing,
                score: highestScore
            )
        }
    }
    
    private func bestFuzzyMatch(
        cleanSourceTitle: String,
        cleanSourceArtist: String,
        sourceDurationMs: Int,
        index: MatchCandidateIndex,
        indices: [Int]
    ) -> (candidate: UniversalTrack?, score: Double) {
        var bestCandidate: UniversalTrack?
        var highestScore: Double = 0.0
        
        for idx in indices {
            let candidate = index.all[idx]
            let cleanCandidateTitle = normalizeString(candidate.title)
            let cleanCandidateArtist = normalizeString(ArtistMatchText.joined(from: candidate))
            
            let titleSim = jaroWinklerSimilarity(cleanSourceTitle, cleanCandidateTitle)
            let artistSim = jaroWinklerSimilarity(cleanSourceArtist, cleanCandidateArtist)
            
            let durationDelta = abs(sourceDurationMs - candidate.durationMs)
            let durationScore = max(0.0, 1.0 - (Double(durationDelta) / 10_000.0))
            
            let compositeScore = (0.50 * titleSim) + (0.35 * artistSim) + (0.15 * durationScore)
            
            if compositeScore > highestScore {
                highestScore = compositeScore
                bestCandidate = candidate
            }
        }
        
        return (bestCandidate, highestScore)
    }
    
    // MARK: - Normalization Engine
    
    private static let suffixRegexes: [NSRegularExpression] = {
        let patterns = [
            "\\(.*?remaster.*?\\)",
            "\\[.*?remaster.*?\\]",
            "\\(.*?deluxe.*?\\)",
            "\\[.*?deluxe.*?\\]",
            "\\(.*?live.*?\\)",
            "\\(.*?bonus track.*?\\)",
            "\\(.*?radio edit.*?\\)",
            "- single version",
            "- remastered"
        ]
        return patterns.compactMap {
            try? NSRegularExpression(pattern: $0, options: .caseInsensitive)
        }
    }()
    
    public static func normalizeStatic(_ text: String) -> String {
        var str = text.lowercased()
        for regex in suffixRegexes {
            str = regex.stringByReplacingMatches(
                in: str,
                range: NSRange(str.startIndex..., in: str),
                withTemplate: ""
            )
        }
        let allowed = CharacterSet.alphanumerics.union(.whitespaces)
        str = str.unicodeScalars.filter { allowed.contains($0) }.map { String($0) }.joined()
        str = str.trimmingCharacters(in: .whitespacesAndNewlines)
        // Drop leading articles so "The Night" ↔ "Night" share a prefix block + fuzzy score.
        for article in ["the ", "a ", "an "] {
            if str.hasPrefix(article) {
                str = String(str.dropFirst(article.count))
                break
            }
        }
        return str.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public func normalizeString(_ text: String) -> String {
        Self.normalizeStatic(text)
    }
    
    // MARK: - Jaro-Winkler Metric
    private func jaroWinklerSimilarity(_ s1: String, _ s2: String) -> Double {
        if s1 == s2 { return 1.0 }
        if s1.isEmpty || s2.isEmpty { return 0.0 }
        
        let a = Array(s1)
        let b = Array(s2)
        // Clamp: for 1-char strings `count/2 - 1` is negative and crashes Range.
        let maxDist = max(0, max(a.count, b.count) / 2 - 1)
        
        var aMatches = [Bool](repeating: false, count: a.count)
        var bMatches = [Bool](repeating: false, count: b.count)
        
        var matches = 0
        for i in 0..<a.count {
            let start = max(0, i - maxDist)
            let end = min(i + maxDist + 1, b.count)
            guard start < end else { continue }
            for j in start..<end {
                if bMatches[j] || a[i] != b[j] { continue }
                aMatches[i] = true
                bMatches[j] = true
                matches += 1
                break
            }
        }
        
        if matches == 0 { return 0.0 }
        
        var transpositions = 0
        var k = 0
        for i in 0..<a.count {
            if !aMatches[i] { continue }
            while !bMatches[k] { k += 1 }
            if a[i] != b[k] { transpositions += 1 }
            k += 1
        }
        
        let m = Double(matches)
        let jaro = (m / Double(a.count) + m / Double(b.count) + (m - Double(transpositions / 2)) / m) / 3.0
        
        var prefixLength = 0
        for i in 0..<min(4, min(a.count, b.count)) {
            if a[i] == b[i] { prefixLength += 1 } else { break }
        }
        
        return jaro + (Double(prefixLength) * 0.1 * (1.0 - jaro))
    }
}
