//
//  User.swift
//  Object Writer
//
//  Created by Kevin O'Neill on 20/04/2015.
//  Copyright (c) 2015 Kevin O'Neill. All rights reserved.
//

import Parse
import ReactiveCocoa

protocol UserStorage {
  var user : User { get set }
}

protocol ProtectedStorage : UserStorage {
  
}

public final class User: PFUser, PFSubclassing {
  
  class func current() -> SignalProducer<User, NSError> {
    return SignalProducer<User, NSError> { observer, disposible in
      PFAnonymousUtils.logInWithBlock { user, error in
        if let error = error {
          sendError(observer, error)
        } else {
          sendNext(observer, user as! User)
          sendCompleted(observer)
        }
      }
    }
  }
  
  static func save<T:PFObject>(object : T) -> SignalProducer<T, NSError> {
    return current()
      |> flatMap(FlattenStrategy.Concat) { $0.write(object) }
  }
  
  func write<T:PFObject>(object : T) -> SignalProducer<T, NSError> {
    object["user"] = self
    return Store<T>.save(object)
  }
}
