//
//  File.swift
//  
//
//  Created by Noah Kamara on 21.10.23.
//
import Foundation
import JavaScriptCore
import OSLog

public enum ReadabilityError: Error {
	case context
	case unknown
	case resource(String)
	case exception(_ context: JSContext?, _ value: JSValue?)
}

public class Readability {
	static let logger = Logger(subsystem: "com.noahkamara.readability", category: "Readability")
	
	private let inspectable: Bool
	
	public init(inspectable: Bool = false) {
		self.inspectable = inspectable
	}
	
	public static let shared: Readability = .init()
	
	
	/// Loads readability.js from bundle
	/// - Returns: readability.js code as string
	private static func loadScript() throws -> String {
		Self.logger.debug("loadScript: start")
		
		do {
			guard let path = Bundle.module.url(forResource: "readability", withExtension: "js") else {
				throw ReadabilityError.resource("Missing 'readability.js' in Bundle")
			}
			
			guard let data = try? Data(contentsOf: path) else {
				throw ReadabilityError.resource("Couldn't to read 'readability.js'")
			}
			guard let string = String(data: data, encoding: .utf8) else {
				throw ReadabilityError.resource("Couldn't decode contents of 'readability.js'")
			}
			
			Self.logger.debug("loadScript: success")
			return "var window = this; \(string)"
		} catch let error {
			if let error = error as? ReadabilityError, case let .resource(msg) = error {
				Self.logger.error("loadScript: \(msg, privacy: .public)")
			} else {
				Self.logger.error("loadScript: unknown error")
			}
			throw error
		}
	}
	
	private static func makeContext() async throws -> JSContext {
		guard let context = JSContext() else {
			Self.logger.error("makeContext: JSContext initializer returned nil")
			throw ReadabilityError.context
		}
		
		return try await withCheckedThrowingContinuation { cont in
			context.exceptionHandler = { self.exceptionHandler($0, $1, continuation: cont) }
			
			// Inject TimerJS
			Self.logger.debug("makeContext: injecting TimerJS")
			TimerJS.registerInto(jsContext: context)
			
			
			// Load readbility.js into context
			Self.logger.debug("makeContext: loading readability")
			do {
				let script = try loadScript()
				context.evaluateScript(script)
				context.exceptionHandler = nil
				cont.resume(returning: context)
			} catch {
				cont.resume(throwing: error)
			}
		}
	}
	
	private static func exceptionHandler<T>(
		_ context: JSContext?,
		_ value: JSValue?,
		continuation: CheckedContinuation<T,any Error>
	) -> Void {
		Self.logger.error("exceptionHandler: \(value)")
		continuation.resume(throwing: ReadabilityError.exception(context, value))
	}
	
	public func parseArticle(url: URL, html: String) async throws -> ReadabilityArticle {
		let context = try await Self.makeContext()
		
		// Set Inspectability
		context.isInspectable = inspectable
		
		// Retrieve API fn
		guard let function = context.objectForKeyedSubscript("parseArticle") else {
			throw ReadabilityError.unknown
		}
		
		
		async let output: JSValue? = try withCheckedThrowingContinuation { continuation in
			var hasResumed: Bool = false
			
			context.exceptionHandler = {
				hasResumed = true;
				Self.exceptionHandler($0, $1, continuation: continuation)
			}
			
			Self.logger.debug("parse: calling readability.js")
			let res = function.call(withArguments: [url.absoluteString, html])
			Self.logger.debug("parse: parsing complete \(res?.debugDescription ?? "-")")
			
			Self.logger.debug("parse: parsing complete")
			guard !hasResumed else {
				return
			}
			continuation.resume(returning: res)
		}
		
		let result: JSValue?
		
		do {
			result = try await output
		} catch {
			try await Task.sleep(for: .seconds(60))
			throw error
		}
		
		
		guard let result, !result.isNull, result.isObject else {
			print("ERR", result as Any)
			throw ReadabilityError.unknown
		}
		
		debugPrint("RESULT")
		return ReadabilityArticle(from: result.toDictionary())
	}
}
