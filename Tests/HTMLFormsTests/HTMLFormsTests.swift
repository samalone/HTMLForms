//
//  HTMLFormsTests.swift
//  HTMLForms
//
//  Created by Stuart A. Malone on 12/13/18.
//

import XCTest
import SwiftSoup
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
        }
        let form = try HTMLFormEncoder.encode(Foo(name: "Llama", email: "llama@example.com"))
        try XCTAssertEqual(form.tag(), Tag.valueOf("form"))
        let inputs: Elements = try form.select("input")
        XCTAssertEqual(inputs.size(), 2)
        let nameInput = inputs.get(0)
        try XCTAssertEqual(nameInput.attr("name"), "name")
        try XCTAssertEqual(nameInput.attr("type"), "text")
        try XCTAssertEqual(nameInput.attr("id"), "edit-name")
        let emailInput = inputs.get(1)
        try XCTAssertEqual(emailInput.attr("name"), "email")
        try XCTAssertEqual(emailInput.attr("type"), "text")
        try XCTAssertEqual(emailInput.attr("id"), "edit-email")
        try print(form.outerHtml())
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
