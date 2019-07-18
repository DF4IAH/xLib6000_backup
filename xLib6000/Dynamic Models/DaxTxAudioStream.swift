//
//  DaxTxAudioStream.swift
//  xLib6000
//
//  Created by Mario Illgen on 27.03.17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Cocoa

/// DaxTxAudioStream Class implementation
///
///      creates a DaxTxAudioStream instance to be used by a Client to support the
///      processing of a stream of Audio from the client to the Radio. DaxTxAudioStream
///      objects are added / removed by the incoming TCP messages. DaxTxAudioStream
///      objects periodically send Tx Audio in a UDP stream. They are collected in
///      the DaxTxAudioStreams collection on the Radio object.
///
public final class DaxTxAudioStream         : NSObject, DynamicModel {
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public private(set) var streamId          : StreamId = 0                  // Stream Id

  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _api                          = Api.sharedInstance            // reference to the API singleton
  private let _log                          = Log.sharedInstance
  private let _q                            : DispatchQueue                 // Q for object synchronization
  private var _initialized                  = false                         // True if initialized by Radio hardware

  private var _txSeq                        = 0                             // Tx sequence number (modulo 16)
  
  // ----- Backing properties - SHOULD NOT BE ACCESSED DIRECTLY, USE PUBLICS IN THE EXTENSION ------
  //                                                                                                  
  private var __clientHandle                : Handle = 0                    // Client for this DaxTxAudioStream
  private var __isTransmitChannel           = false                         // dax transmitting
  private var __txGain                      = 50                            // tx gain of stream
  private var __txGainScalar                : Float = 1.0                   // scalar gain value for multiplying
  //
  // ----- Backing properties - SHOULD NOT BE ACCESSED DIRECTLY, USE PUBLICS IN THE EXTENSION ------
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol class methods
  
  /// Parse a TxAudioStream status message
  ///
  ///   StatusParser protocol method, executes on the parseQ
  ///
  /// - Parameters:
  ///   - keyValues:      a KeyValuesArray
  ///   - radio:          the current Radio class
  ///   - queue:          a parse Queue for the object
  ///   - inUse:          false = "to be deleted"
  ///
  class func parseStatus(_ keyValues: KeyValuesArray, radio: Radio, queue: DispatchQueue, inUse: Bool = true) {
    // Format:  <streamId, > <"type", "dax_tx"> <"client_handle", handle> <"dax_tx", isTransmitChannel>
    
    //get the StreamId
    if let streamId = keyValues[0].key.streamId {
      
      // does the Stream exist?
      if radio.daxTxAudioStreams[streamId] == nil {
        
        // exit if this stream is not for this client
        if isForThisClient(handle: keyValues[3].value ) == false { return }
        
        // create a new Stream & add it to the collection
        radio.daxTxAudioStreams[streamId] = DaxTxAudioStream(streamId: streamId, queue: queue)
      }
      // pass the remaining key values to parsing
      radio.daxTxAudioStreams[streamId]!.parseProperties( Array(keyValues.dropFirst(1)) )
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an TX Audio Stream
  ///
  /// - Parameters:
  ///   - id:                 Dax stream Id
  ///   - queue:              Concurrent queue
  ///
  init(streamId: StreamId, queue: DispatchQueue) {
    
    self.streamId = streamId
    _q = queue
    
    super.init()
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Public instance methods
  
  private var _vita: Vita?
  /// Send Tx Audio to the Radio
  ///
  /// - Parameters:
  ///   - left:                   array of left samples
  ///   - right:                  array of right samples
  ///   - samples:                number of samples
  /// - Returns:                  success
  ///
  public func sendTXAudio(left: [Float], right: [Float], samples: Int) -> Bool {
    
    // skip this if we are not the DAX TX Client
    if !_isTransmitChannel { return false }
    
    // get a TxAudio Vita
    if _vita == nil { _vita = Vita(type: .txAudio, streamId: streamId) }
    
    let kMaxSamplesToSend = 128     // maximum packet samples (per channel)
    let kNumberOfChannels = 2       // 2 channels
    
    // create new array for payload (interleaved L/R samples)
    let payloadData = [UInt8](repeating: 0, count: kMaxSamplesToSend * kNumberOfChannels * MemoryLayout<Float>.size)
    
    // get a raw pointer to the start of the payload
    let payloadPtr = UnsafeMutableRawPointer(mutating: payloadData)
    
    // get a pointer to 32-bit chunks in the payload
    let wordsPtr = payloadPtr.bindMemory(to: UInt32.self, capacity: kMaxSamplesToSend * kNumberOfChannels)
    
    // get a pointer to Float chunks in the payload
    let floatPtr = payloadPtr.bindMemory(to: Float.self, capacity: kMaxSamplesToSend * kNumberOfChannels)
    
    var samplesSent = 0
    while samplesSent < samples {
      
      // how many samples this iteration? (kMaxSamplesToSend or remainder if < kMaxSamplesToSend)
      let numSamplesToSend = min(kMaxSamplesToSend, samples - samplesSent)
      let numFloatsToSend = numSamplesToSend * kNumberOfChannels
      
      // interleave the payload & scale with tx gain
      for i in 0..<numSamplesToSend {                                         // TODO: use Accelerate
        floatPtr.advanced(by: 2 * i).pointee = left[i + samplesSent] * _txGainScalar
        floatPtr.advanced(by: (2 * i) + 1).pointee = left[i + samplesSent] * _txGainScalar

//        payload[(2 * i)] = left[i + samplesSent] * _txGainScalar
//        payload[(2 * i) + 1] = right[i + samplesSent] * _txGainScalar
      }
      
      // swap endianess of the samples
      for i in 0..<numFloatsToSend {
        wordsPtr.advanced(by: i).pointee = CFSwapInt32HostToBig(wordsPtr.advanced(by: i).pointee)
      }
      
      _vita!.payloadData = payloadData

      // set the length of the packet
      _vita!.payloadSize = numFloatsToSend * MemoryLayout<UInt32>.size            // 32-Bit L/R samples
      _vita!.packetSize = _vita!.payloadSize + MemoryLayout<VitaHeader>.size      // payload size + header size
      
      // set the sequence number
      _vita!.sequence = _txSeq
      
      // encode the Vita class as data and send to radio
      if let data = Vita.encodeAsData(_vita!) {
        
        // send packet to radio
        _api.sendVitaData(data)
      }
      // increment the sequence number (mod 16)
      _txSeq = (_txSeq + 1) % 16
      
      // adjust the samples sent
      samplesSent += numSamplesToSend
    }
    return true
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Protocol instance methods

  /// Parse TX Audio Stream key/value pairs
  ///
  ///   PropertiesParser protocol method, executes on the parseQ
  ///
  /// - Parameter properties:       a KeyValuesArray
  ///
  func parseProperties(_ properties: KeyValuesArray) {
    
    // process each key/value pair, <key=value>
    for property in properties {
      
      // check for unknown keys
      guard let token = Token(rawValue: property.key) else {
        // unknown Key, log it and ignore the Key
        _log.msg("Unknown DaxTxAudioStream token: \(property.key) = \(property.value)", level: .warning, function: #function, file: #file, line: #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .clientHandle:
        willChangeValue(for: \.clientHandle)
        _clientHandle = property.value.handle ?? 0
        didChangeValue(for: \.clientHandle)
        
      case .isTransmitChannel:
        willChangeValue(for: \.isTransmitChannel)
        _isTransmitChannel = property.value.bValue
        didChangeValue(for: \.isTransmitChannel)
      }
    }
    // is the AudioStream acknowledged by the radio?
    if _initialized == false && _clientHandle != 0 {
      
      // YES, the Radio (hardware) has acknowledged this Audio Stream
      _initialized = true
      
      // notify all observers
      NC.post(.daxTxAudioStreamHasBeenAdded, object: self as Any?)
    }
  }
}

extension DaxTxAudioStream {
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  internal var _clientHandle: Handle {
    get { return _q.sync { __clientHandle } }
    set { _q.sync(flags: .barrier) { __clientHandle = newValue } } }
  
  internal var _isTransmitChannel: Bool {
    get { return _q.sync { __isTransmitChannel } }
    set { _q.sync(flags: .barrier) { __isTransmitChannel = newValue } } }
  
  internal var _txGain: Int {
    get { return _q.sync { __txGain } }
    set { _q.sync(flags: .barrier) { __txGain = newValue } } }
  
  internal var _txGainScalar: Float {
    get { return _q.sync { __txGainScalar } }
    set { _q.sync(flags: .barrier) { __txGainScalar = newValue } } }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties (KVO compliant)
  
  @objc dynamic public var txGain: Int {
    get { return _txGain  }
    set {
      if _txGain != newValue {
        let value = newValue.bound(0, 100)
        if _txGain != value {
          _txGain = value
          if _txGain == 0 {
            _txGainScalar = 0.0
            return
          }
          let db_min:Float = -10.0;
          let db_max:Float = +10.0;
          let db:Float = db_min + (Float(_txGain) / 100.0) * (db_max - db_min);
          _txGainScalar = pow(10.0, db / 20.0);
        }
      }
    }
  }
  @objc dynamic public var clientHandle: Handle {
    get { return _clientHandle  }
    set { if _clientHandle != newValue { _clientHandle = newValue} } }
  
  // ----------------------------------------------------------------------------
  // MARK: - Tokens
  
  /// Properties
  ///
  internal enum Token: String {
    case clientHandle         = "client_handle"
    case isTransmitChannel    = "dax_tx"
  }
}

