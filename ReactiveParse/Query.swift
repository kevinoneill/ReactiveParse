//
//  PFObject+OW.swift
//  Object Writer
//
//  Created by Kevin O'Neill on 21/04/2015.
//  Copyright (c) 2015 Kevin O'Neill. All rights reserved.
//

import ReactiveCocoa
import Parse

public typealias QueryConfig = (PFQuery -> Void)

public let QueryConfigDefault : QueryConfig = { $0 }
public let QueryConfigLocal : QueryConfig = { $0.fromLocalDatastore() }

extension PFObject {
  
  public static func query(configuration : QueryConfig) -> PFQuery? {
    let query = self.query()
    if let query = query {
      configuration(query)
    }
    
    return query
  }
  
  public func write() -> SignalProducer<PFObject, NSError> {
    return Store<PFObject>.save(self)
  }
}

public func +(lhs : QueryConfig, rhs : QueryConfig) -> QueryConfig {
  return { query in lhs(query); rhs(query) }
}