//
//  File.swift
//  
//
//  Created by Noah Kamara on 13.03.22.
//

// MARK: Solution to 'setTimer' not found
// found on SO: https://stackoverflow.com/a/39864295/11450810
import Foundation
import JavaScriptCore
import OSLog

let timerJSSharedInstance = TimerJS()

@objc protocol TimerJSExport : JSExport {
    
    func setTimeout(_ callback : JSValue,_ ms : Double) -> String
    
    func clearTimeout(_ identifier: String)
    
    func setInterval(_ callback : JSValue,_ ms : Double) -> String
}

// Custom class must inherit from `NSObject`
@objc class TimerJS: NSObject, TimerJSExport {
	static let logger = Logger(subsystem: "com.noahkamara.readability", category: "TimerJS")
	
    var timers = [String: Task<(),Never>]()
    
    static func registerInto(jsContext: JSContext, forKeyedSubscript: String = "timerJS") {
        jsContext.setObject(timerJSSharedInstance,
                            forKeyedSubscript: forKeyedSubscript as (NSCopying & NSObjectProtocol))
        jsContext.evaluateScript(
            "function setTimeout(callback, ms) {" +
            "    return timerJS.setTimeout(callback, ms)" +
            "}" +
            "function clearTimeout(indentifier) {" +
            "    timerJS.clearTimeout(indentifier)" +
            "}" +
            "function clearInterval(indentifier) {" +
            "    timerJS.clearTimeout(indentifier)" +
            "}" +
            "function setInterval(callback, ms) {" +
            "    return timerJS.setInterval(callback, ms)" +
            "}"
        )
    }
    
    func clearTimeout(_ identifier: String) {
		Self.logger.debug("clear")
        let timer = timers.removeValue(forKey: identifier)
		timer?.cancel()
    }
    
    func setInterval(_ callback: JSValue,_ ms: Double) -> String {
		Self.logger.debug("setInterval: \(ms)ms")
        return createTimer(callback: callback, ms: ms, repeats: true)
    }
    
    func setTimeout(_ callback: JSValue, _ ms: Double) -> String {
		Self.logger.debug("setTimeout: \(ms)ms")
        return createTimer(callback: callback, ms: ms, repeats: false)
    }
    
    func createTimer(callback: JSValue, ms: Double, repeats : Bool) -> String {
		let id = UUID().uuidString
		Self.logger.debug("[\(id)]: createTimer \(ms)ms repeats:\(repeats)")
        
        
        // make sure that we are queueing it all in the same executable queue...
        // JS calls are getting lost if the queue is not specified... that's what we believe... ;)
		self.timers[id] = Task {
			try? await Task.sleep(for: .milliseconds(ms))
			Self.logger.debug("[\(id)]: trigger")
			callback.call(withArguments: [])
		}
        
        return id
    }
}
