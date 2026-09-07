import Foundation
import MiniinCore
import Testing

@Suite("Media vocabulary")
struct MediaVocabularyTests {
    @Test("Frame rate reduces to lowest terms")
    func frameRateReduces() throws {
        let rate = try #require(FrameRate(numerator: 60, denominator: 2))

        #expect(rate == FrameRate.fps30)
        #expect(rate.numerator == 30)
        #expect(rate.denominator == 1)
    }

    @Test("NTSC frame rates keep their exact rational value")
    func ntscRatesStayExact() {
        #expect(FrameRate.fps30NTSC.numerator == 30000)
        #expect(FrameRate.fps30NTSC.denominator == 1001)
        #expect(abs(FrameRate.fps30NTSC.value - 29.97) < 0.001)
    }

    @Test("Non-positive frame rate components are rejected")
    func frameRateRejectsNonPositive() {
        #expect(FrameRate(numerator: 30, denominator: 0) == nil)
        #expect(FrameRate(numerator: 0, denominator: 1) == nil)
    }

    @Test("A persisted frame rate with a zero denominator fails to decode")
    func frameRateDecodeRejectsZeroDenominator() {
        let payload = Data(#"{"numerator":30,"denominator":0)"#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(FrameRate.self, from: payload)
        }
    }

    @Test("Persisted raw values are pinned")
    func rawValuesArePinned() {
        #expect(OutputContainer.allCases.map(\.rawValue) == ["mp4", "mov"])
        #expect(OutputVideoCodec.allCases.map(\.rawValue) == ["h264", "hevc"])
        #expect(OutputAudioCodec.allCases.map(\.rawValue) == ["aac"])
    }
}
