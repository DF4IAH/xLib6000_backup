//
//  XvtrCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/19/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// --------------------------------------------------------------------------------
// MARK: - Xvtr Class extensions
//              - Dynamic public properties that send commands to the Radio
// --------------------------------------------------------------------------------

extension Xvtr {
  
  //
  //  NOTE:   Xvtr Commands are in one of the following formats:
  //
  //              xvtr set <Id> <valueName>=<value>
  //              xvtr create
  //              xvtr remove <XvtrId>
  //
  
  static let kCreateCmd                     = "xvtr create"                 // Command prefixes
  static let kRemoveCmd                     = "xvtr remove "
  static let kSetCmd                        = "xvtr set "

  // ----------------------------------------------------------------------------
  // MARK: - Private methods - Command helper methods
  
  /// Set an Xvtr property on the Radio
  ///
  /// - Parameters:
  ///   - token:      the parse token
  ///   - value:      the new value
  ///
  private func xvtrCmd(_ token: Token, _ value: Any) {
    
    Api.sharedInstance.send(Xvtr.kSetCmd + "\(id) " + token.rawValue + "=\(value)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties - KVO compliant, that send Commands to the Radio (hardware)
  
  // listed in alphabetical order
  @objc dynamic public var ifFrequency: Int {
    get { return _ifFrequency }
    set { if _ifFrequency != newValue { _ifFrequency = newValue ; xvtrCmd( .ifFrequency, newValue) } } }
  
  @objc dynamic public var loError: Int {
    get { return _loError }
    set { if _loError != newValue { _loError = newValue ; xvtrCmd( .loError, newValue) } } }
  
  @objc dynamic public var name: String {
    get { return _name }
    set { if _name != newValue { _name = newValue ; xvtrCmd( .name, newValue) } } }
  
  @objc dynamic public var maxPower: Int {
    get { return _maxPower }
    set { if _maxPower != newValue { _maxPower = newValue ; xvtrCmd( .maxPower, newValue) } } }
  
  @objc dynamic public var order: Int {
    get { return _order }
    set { if _order != newValue { _order = newValue ; xvtrCmd( .order, newValue) } } }
  
  @objc dynamic public var rfFrequency: Int {
    get { return _rfFrequency }
    set { if _rfFrequency != newValue { _rfFrequency = newValue ; xvtrCmd( .rfFrequency, newValue) } } }
  
  @objc dynamic public var rxGain: Int {
    get { return _rxGain }
    set { if _rxGain != newValue { _rxGain = newValue ; xvtrCmd( .rxGain, newValue) } } }
  
  @objc dynamic public var rxOnly: Bool {
    get { return _rxOnly }
    set { if _rxOnly != newValue { _rxOnly = newValue ; xvtrCmd( .rxOnly, newValue) } } }
}