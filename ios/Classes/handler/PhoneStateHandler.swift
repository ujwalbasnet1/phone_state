//
//  PhoneStateHandler.swift
//  phone_state
//
//  Created by Andrea Mainella on 28/02/22.
//

import Foundation
import CallKit

@available(iOS 10.0, *)
class PhoneStateHandler: NSObject, FlutterStreamHandler, CXCallObserverDelegate{
    
    private var _eventSink: FlutterEventSink?
    private var callObserver = CXCallObserver()
    
    override init() {
        super.init()
        callObserver.setDelegate(self, queue: nil)
    }
    
    public func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        var status = PhoneStateStatus.NOTHING
        if call.isOutgoing == false && call.hasConnected == false && call.hasEnded == false {
            status = PhoneStateStatus.CALL_INCOMING
        } else if (call.isOutgoing == false && call.hasConnected == true && call.hasEnded == false)
                    || (call.hasConnected == true && call.hasEnded == false && call.isOnHold == false) {
            status = PhoneStateStatus.CALL_STARTED
        } else if call.isOutgoing == false && call.hasEnded == true {
            status = PhoneStateStatus.CALL_ENDED
        } else {
            status = PhoneStateStatus.NOTHING
        }
        // Map
        if(_eventSink != nil) { 
            
            fetchFirstCallFromHistory { firstCall in
                if let firstCall = firstCall {
                    let phoneNumber = firstCall.phoneNumber
                    let callType = firstCall.callType
                    let date = firstCall.date
                    print("First call from history:")
                    print("Phone Number: \(phoneNumber)")
                    print("Call Type: \(callType)")
                    print("Date: \(date)")

                     _eventSink!(
                        [
                            "status": status.rawValue,
                            "phoneNumber": phoneNumber
                        ]
                    )

                } else {
                    print("No call history available.")
                }
            }
        }
    }

    func fetchFirstCallFromHistory(completion: @escaping (CXCallRecord?) -> Void) {
        let store = CXCallDirectoryProvider.shared
        store.getCallHistory() { callHistory, error in
            if let error = error {
                print("Error fetching call history: \(error.localizedDescription)")
                completion(nil)
                return
            }

            // Sort call history by date
            let sortedCallHistory = callHistory.sorted { $0.date > $1.date }

            // Return the first item of the sorted call history
            completion(sortedCallHistory.first)
        }
    }


    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        _eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        _eventSink = nil
        return nil
    }
    
}
