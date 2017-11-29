//
//  FutureTests.swift
//  FunctionalKitTests
//
//  Created by Pallas, Ricardo on 11/23/17.
//

import XCTest
@testable import FunctionalKit

class ResultTests: XCTestCase {
    
    struct User {
        var name: String
    }
    
    struct Street {
        var name: String
    }
    
    enum ResultError: Error {
        case invalidResult
    }
    func getUserName(user: User) -> String{
        return user.name
    }
    
    func getNames(user: User, street: Street) -> [String] {
        return [user.name, street.name]
    }
    
    typealias MyResult<T> = Result<ResultError, T>

    override func setUp() {
        enum ResultError: Error {
            case invalidResult
        }
    }

    func testMap() {
        let result1:Result<ResultError, String> = Result.success("Result 1")
        let result12 = result1.map { value in
            return value + "2"
        }
        XCTAssert(result12.tryRight! == "Result 12")
    }
    
    func testApply() {
        let ricardo = User(name: "Ricardo")
        let userResult = MyResult.success(ricardo)
        
        let printUserResult = MyResult.success(getUserName)
        let userNameResult = userResult.apply(printUserResult)
        
        XCTAssert(userNameResult.tryRight! == "Ricardo")
    }
    
    func testLift(){
        let ricardo = User(name: "Ricardo")
        
        let userResult = MyResult.success(ricardo)
        let liftedGetUserName = MyResult.lift(getUserName)
        
        let userNameResult = liftedGetUserName(userResult)
        XCTAssert(userNameResult.tryRight! == "Ricardo")
    }
    
    func testLift2(){
        let userResult = MyResult.success(User(name: "Ricardo"))
        let streetResult = MyResult.success(Street(name: "Fake Street"))
        
        let liftedGetUserNames = MyResult.lift2(getNames)
        
        let namesResult = liftedGetUserNames(userResult, streetResult)
        
        XCTAssert(namesResult.tryRight! == ["Ricardo", "Fake Street"])
    }

    
}
