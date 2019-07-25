//
//  Amplifier.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/7/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

public typealias AmplifierId = String

/// Amplifier Class implementation
///
///      creates an Amplifier instance to be used by a Client to support the
///      control of an external Amplifier. Amplifier objects are added, removed and
///      updated by the incoming TCP messages. They are collected in the amplifiers
///      collection on the Radio object.
///
public final class Amplifier                : NSObject, DynamicModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  static let kOperate                       = "OPERATE"
  static let kStandby                       = "STANDBY"

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public private(set) var id                : AmplifierId = ""              // Id that uniquely identifies this Amplifier

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _api                          = Api.sharedInstance            // reference to the API singleton
  private let _log                          = Log.sharedInstance
  private let _q                            : DispatchQueue                 // Q for object synchronization
  private var _initialized                  = false                         // True if initialized by Radio hardware

  // ----- Backing properties - SHOULD NOT BE ACCESSED DIRECTLY, USE PUBLICS IN THE EXTENSION ------
  //
  private var __ant                         = ""                            // Antenna list
  private var __ip                          = ""                            // Ip Address (dotted decimal)
  private var __model                       = ""                            // Amplifier model
  private var __mode                        = ""                            // Amplifier mode
  private var __port                        = 0                             //
  private var __serialNumber                = ""                            // Serial number
  //                                                                                              
  // ----- Backing properties - SHOULD NOT BE ACCESSED DIRECTLY, USE PUBLICS IN THE EXTENSION ------
    
  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods
  
  /// Parse an Amplifier status message
  ///
  ///   StatusParser Protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ keyValues: KeyValuesArray, radio: Radio, queue: DispatchQueue, inUse: Bool = true) {
    // TODO: Add format
    
    
    // TODO: verify
    
    
    //get the AmplifierId (remove the "0x" prefix)
    let streamId = String(keyValues[0].key.dropFirst(2))
    
    // is the Amplifier in use
    if inUse {
      
      // YES, does the Amplifier exist?
      if radio.amplifiers[streamId] == nil {
        
        // NO, create a new Amplifier & add it to the Amplifiers collection
        radio.amplifiers[streamId] = Amplifier(id: streamId, queue: queue)
      }
      // pass the remaining key values to the Amplifier for parsing
      radio.amplifiers[streamId]!.parseProperties( Array(keyValues.dropFirst(1)) )
      
    } else {
      
      // NO, notify all observers
      NC.post(.amplifierWillBeRemoved, object: radio.amplifiers[streamId] as Any?)
      
      // remove it
      radio.amplifiers[streamId] = nil
    }
  }

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an Amplifier
  ///
  /// - Parameters:
  ///   - id:                 an Xvtr Id
  ///   - queue:              Concurrent queue
  ///
  public init(id: AmplifierId, queue: DispatchQueue) {
    
    self.id = id
    _q = queue
    
    super.init()
  }

  // ------------------------------------------------------------------------------
  // MARK: - Protocol instance methods
  
  /// Parse Amplifier key/value pairs
  ///
  ///   PropertiesParser Protocol method, , executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // check for unknown Keys
      guard let token = Token(rawValue: property.key) else {
        // log it and ignore the Key
        _log.msg("Unknown Amplifier token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .ant:
        willChangeValue(for: \.ant)
        _ant = property.value
        didChangeValue(for: \.ant)

      case .ip:
        willChangeValue(for: \.ip)
        _ip = property.value
        didChangeValue(for: \.ip)

      case .model:
        willChangeValue(for: \.model)
        _model = property.value
        didChangeValue(for: \.model)

      case .port:
        willChangeValue(for: \.port)
        _port = property.value.iValue
        didChangeValue(for: \.port)

      case .serialNumber:
       willChangeValue(for: \.serialNumber)
       _serialNumber = property.value
       didChangeValue(for: \.serialNumber)

      case .mode:      // never received from Radio
        break
      }
    }
    // is the Amplifier initialized?
    if _initialized == false && _ip != "" && _port != 0 {
      
      // YES, the Radio (hardware) has acknowledged this Amplifier
      _initialized = true
      
      // notify all observers
      NC.post(.amplifierHasBeenAdded, object: self as Any?)
    }
  }
}

extension Amplifier {
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  // listed in alphabetical order
  internal var _ant: String {
    get { return _q.sync { __ant } }
    set { _q.sync(flags: .barrier) {__ant = newValue } } }
  
  internal var _ip: String {
    get { return _q.sync { __ip } }
    set { _q.sync(flags: .barrier) {__ip = newValue } } }
  
  internal var _model: String {
    get { return _q.sync { __model } }
    set { _q.sync(flags: .barrier) {__model = newValue } } }
  
  internal var _mode: String {
    get { return _q.sync { __mode } }
    set { _q.sync(flags: .barrier) {__mode = newValue } } }
  
  internal var _port: Int {
    get { return _q.sync { __port } }
    set { _q.sync(flags: .barrier) {__port = newValue } } }
  
  internal var _serialNumber: String {
    get { return _q.sync { __serialNumber } }
    set { _q.sync(flags: .barrier) {__serialNumber = newValue } } }
  
  // ----------------------------------------------------------------------------
  // MARK: - Tokens
  
  /// Properties
  ///
  internal enum Token : String {
    case ant
    case ip
    case model
    case mode        // never received from Radio (values = KOperate or kStandby)
    case port
    case serialNumber                       = "serial_num"
  }
}

