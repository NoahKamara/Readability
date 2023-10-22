import XCTest
@testable import Readability

final class ReadabilityTests: XCTestCase {
    func testExample() async throws {
		let url = URL(string: "https://www.spiegel.de/ausland/jim-jordan-will-offenbar-doch-ein-drittes-mal-fuer-das-sprecheramt-kandidieren-a-f4a25517-2602-4319-bad5-3ef89823d0a6#ref=rss")!
		
		let readability = Readability(inspectable: true)
		
		do {
			let (data, _ ) = try await URLSession.shared.data(from: url)
			
			guard let htmlString = String(data: data, encoding: .utf8) else {
				return
			}
			
			let result = try await readability.parseArticle(url: url, html: htmlString)
			
			print(result.content ?? "")
			XCTAssert(result.title == "Überraschende Wende: Jim Jordan will offenbar doch ein drittes Mal für das US-Repräsentantenhaus kandidieren")
		} catch {
			print("Error", error)
			XCTFail("Threw Error")
		}
    }
}
