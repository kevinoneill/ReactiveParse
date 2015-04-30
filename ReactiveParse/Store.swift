//
//  Store.swift
//  Object Writer
//
//  Created by Kevin O'Neill on 21/04/2015.
//  Copyright (c) 2015 Kevin O'Neill. All rights reserved.
//

import ReactiveCocoa
import Parse

public struct Store<T : PFObject> {
  
  public typealias Producer = SignalProducer<T, NSError>

  public static func save(instance : T) -> Producer {
    return personalize(instance)
      |> flatMap(FlattenStrategy.Concat) { self.saveEventually($0) }
  }
  
  private static func saveEventually(instance : T) -> Producer {
    return Producer { observer, disposible in
      instance.saveEventually { success, error in
        if nil != error {
          sendError(observer, error!)
        } else {
          sendNext(observer, instance)
          sendCompleted(observer)
        }
      }
    }
  }
  
  public static func publish(instance : T) -> Producer {
    return personalize(instance)
      |> flatMap(FlattenStrategy.Concat) { self.saveInBackground($0) }
  }
  
  private static func saveInBackground(instance : T) -> Producer {
    return Producer { observer, disposible in
      instance.saveInBackgroundWithBlock { success, error in
        if nil != error {
          sendError(observer, error!)
        } else {
          sendNext(observer, instance)
          sendCompleted(observer)
        }
      }
    }
  }
  
  private static func personalize(instance : T) -> Producer {
    if var userstorage = instance as? UserStorage {
      return User.current()
        |> map { user in
          userstorage.user = user;
          if let privatestorage = userstorage as? ProtectedStorage {
            // if no security has been assigned
            if (instance.ACL == nil) {
              instance.ACL = PFACL(user: user)
            }
          }
          return instance
      }
    } else {
      return Producer(value: instance)
    }
  }

  public static func find(config : QueryConfig = QueryConfigDefault) -> SignalProducer<[T], NSError> {
    let query = T.query(config)
    return self.producer(query)
  }
  
  public static func pin(configuration : QueryConfig = QueryConfigDefault) -> SignalProducer<[T], NSError> {
    let query = T.query() {
      return configuration($0)
    }
    
    return self.producer(query)
      |> flatMap(.Merge) {
        let pin = self.pin($0)
        let values = SignalProducer<[T], NSError>(value: $0)
        
        let actions =  SignalProducer<SignalProducer<[T], NSError>, NSError>(values: [pin, values])
        return actions |> flatten(FlattenStrategy.Merge)
    }
  }
  
  public static func pin(items : [T]) -> SignalProducer<[T], NSError> {
    return SignalProducer<[T], NSError> { observer, disposible in
      T.pinAllInBackground(items, block: { result, error in
        if nil != error {
          sendError(observer, error!)
        } else {
          sendCompleted(observer)
        }
      })
    }
  }
  
  static func local(configuration : QueryConfig) -> SignalProducer<[T], NSError> {
    let query = T.query() { (configuration + QueryConfigLocal)($0) }
    return producer(query)
  }
  
  private static func producer(query: PFQuery?) -> SignalProducer<[T], NSError>  {
    
    let request : SignalProducer<[T], NSError>
    
    if let query = query {
      
      request = SignalProducer<[T], NSError> { observer, disposible in
        query.findObjectsInBackgroundWithBlock { result, error in
          if nil != error {
            sendError(observer, error!)
          } else {
            sendNext(observer, result as! [T])
            sendCompleted(observer)
          }
        }
        
        disposible.addDisposable { query.cancel() }
      }
      
    } else {
      request = SignalProducer.empty
    }
    
    return request
  }
}

