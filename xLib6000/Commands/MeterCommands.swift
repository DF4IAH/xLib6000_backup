//
//  MeterCommands.swift
//  xLib6000
//
//  Created by Douglas Adams on 7/20/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

// --------------------------------------------------------------------------------
// MARK: - Meter Class extensions
//              - Dynamic public properties that send Commands to the Radio
// --------------------------------------------------------------------------------

extension Meter {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods that send Commands to the Radio (hardware)
  
  public class func subscribeToId(_ id: MeterId) { Api.sharedInstance.send("sub meter \(id)") }

  // ----------------------------------------------------------------------------
  // MARK: - Public properties - KVO compliant, that send Commands to the Radio (hardware)
  
  // ----- NONE -----
}
