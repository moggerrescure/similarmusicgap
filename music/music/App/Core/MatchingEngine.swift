import Foundation

/// Match confidence result for song migration
public enum MatchConfidence: Equatable {
    case exactISRC                     // 100% confidence via international standard code
    case highConfidence(score: Double)  // Score >= 0.88 with duration match
    case alternate(score: Double)       // Score 0.65 - 0.87 -> Goes to Rematch Inbox
    case missing                        // No plausible candidates
}

public struct MatchResult {
    public let sourceTrack: UniversalTrack
    public let matchedTrack: UniversalTrack?
    public let confidence: MatchConfidence
    public let score: Double
}

/// 3-Tier Multi-Level Matching Engine (Plan 3 Specification)
public final class MatchingEngine {
    public init() {}
    
    /// Main match entry point
    public func match(
        source: UniversalTrack,
        candidates: [UniversalTrack]
    ) -> MatchResult {
        // Tier 1: Exact ISRC Match
        if let sourceISRC = source.isrc, !sourceISRC.isEmpty {
            if let isrcMatch = candidates.first(where: { $0.isrc == sourceISRC }) {
                return MatchResult(
                    sourceTrack: source,
                    matchedTrack: isrcMatch,
                    confidence: .exactISRC,
                    score: 1.0
                )
            }
        }
        
        // Tier 2: Normalized Title + Artist + Duration Fuzzy Match
        var bestCandidate: UniversalTrack?
        var highestScore: Double = 0.0
        
        let cleanSourceTitle = normalizeString(source.title)
        let cleanSourceArtist = normalizeString(source.primaryArtist)
        
        for candidate in candidates {
            let cleanCandidateTitle = normalizeString(candidate.title)
            let cleanCandidateArtist = normalizeString(candidate.primaryArtist)
            
            let titleSim = jaroWinklerSimilarity(cleanSourceTitle, cleanCandidateTitle)
            let artistSim = jaroWinklerSimilarity(cleanSourceArtist, cleanCandidateArtist)
            
            // Duration penalty calculation
            let durationDelta = abs(source.durationMs - candidate.durationMs)
            let durationScore = max(0.0, 1.0 - (Double(durationDelta) / 10_000.0))
            
            // Weighted Composite Score: 50% Title, 35% Artist, 15% Duration
            let compositeScore = (0.50 * titleSim) + (0.35 * artistSim) + (0.15 * durationScore)
            
            if compositeScore > highestScore {
                highestScore = compositeScore
                bestCandidate = candidate
            }
        }
        
        // Evaluation
        if highestScore >= 0.88 {
            return MatchResult(
                sourceTrack: source,
                matchedTrack: bestCandidate,
                confidence: .highConfidence(score: highestScore),
                score: highestScore
            )
        } else if highestScore >= 0.65 {
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
    
    // MARK: - Normalization Engine
    public func normalizeString(_ text: String) -> String {
        var str = text.lowercased()
        
        // Remove remaster, deluxe, live suffixes
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
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                str = regex.stringByReplacingMatches(in: str, range: NSRange(str.startIndex..., in: str), withTemplate: "")
            }
        }
        
        // Remove punctuation and extra whitespace
        let allowed = CharacterSet.alphanumerics.union(.whitespaces)
        str = str.unicodeScalars.filter { allowed.contains($0) }.map { String($0) }.joined()
        return str.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Jaro-Winkler Metric
    private func jaroWinklerSimilarity(_ s1: String, _ s2: String) -> Double {
        if s1 == s2 { return 1.0 }
        if s1.isEmpty || s2.isEmpty { return 0.0 }
        
        let a = Array(s1)
        let b = Array(s2)
        let maxDist = max(a.count, b.count) / 2 - 1
        
        var aMatches = [Bool](repeating: false, count: a.count)
        var bMatches = [Bool](repeating: false, count: b.count)
        
        var matches = 0
        for i in 0..<a.count {
            let start = max(0, i - maxDist)
            let end = min(i + maxDist + 1, b.count)
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
        
        // Prefix scale
        var prefixLength = 0
        for i in 0..<min(4, min(a.count, b.count)) {
            if a[i] == b[i] { prefixLength += 1 } else { break }
        }
        
        return jaro + (Double(prefixLength) * 0.1 * (1.0 - jaro))
    }
}

