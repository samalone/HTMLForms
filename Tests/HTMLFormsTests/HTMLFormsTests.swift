//
//  HTMLFormsTests.swift
//  HTMLForms
//
//  Created by Stuart A. Malone on 12/13/18.
//

import XCTest
import HTMLForms

class HTMLFormsTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSimpleStruct() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        struct Foo: Codable {
            var name: String;
            var email: String;
			var birthday: Date;
			var age: Int;
			var isAdult: Bool;
        }
		let form = try HTMLFormEncoder.encode(Foo(name: "Llama", email: "llama@example.com", birthday: Date(), age: 9, isAdult: false))
        print(form.html)
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
