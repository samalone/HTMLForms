//
//  FormInputEncoder.swift
//  App
//
//  Created by Stuart A. Malone on 12/11/18.
//

import Foundation
import SwiftSoup

public enum HTMLFormEncodingError: Error {
    case cantEncodeSingleValue
    case unsupportedType
    case notImplemented
}

public protocol HTMLFormCodingKey: CodingKey {
    var label: String? { get }
    var maxLength: Int? { get }
    var size: Int? { get }
    var inputType: String? { get }
    var instructions: String? { get }
}

extension HTMLFormCodingKey {
    var label: String? { return nil }
    var maxLength: Int? { return nil }
    var size: Int? { return nil }
    var inputType: String? { return nil }
    var instructions: String? { return nil }
}

struct SingleValueFormInputEncodingContainer: SingleValueEncodingContainer {
    var codingPath: [CodingKey]
    let encoder: HTMLFormEncoder
    
    init(encoder: HTMLFormEncoder, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }
    
    mutating func encodeNil() throws {
        throw HTMLFormEncodingError.cantEncodeSingleValue
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        throw HTMLFormEncodingError.cantEncodeSingleValue
    }
}

extension String {
    var camelCaseExpanded: String {
        let regex = try! NSRegularExpression(pattern: "[A-Z]", options: [])
        return regex.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length: self.count), withTemplate: " $0")
    }
}

fileprivate struct KeyedFormInputEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    var codingPath: [CodingKey] = []
    var encoder: HTMLFormEncoder
    
    mutating func encodeNil(forKey key: Key) throws {
        throw HTMLFormEncodingError.unsupportedType
    }
    
    mutating func encode(_ value: String, forKey key: Key) throws {
        encodeDescription(value, forKey: key)
    }
    
    mutating func encode(_ value: Int, forKey key: Key) throws {
        encodeDescription(value, forKey: key, inputType: "number")
    }
    
    mutating func encode(_ value: Date, forKey key: Key) throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let input = try Element(Tag.valueOf("input"), "")
        try! input.attr("name", keyToName(key))
        try! input.attr("type", "date")
        try! input.attr("value", formatter.string(from: value))
        try! input.attr("placeholder", key.stringValue.camelCaseExpanded.lowercased())
        try encoder.container.appendChild(wrapLabelBefore(input: input, forKey: key))
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) throws {
        let input = try Element(Tag.valueOf("input"), "")
        try! input.attr("name", keyToName(key))
        try! input.attr("type", "checkbox")
        try! input.attr("value", "true")
        if (value) {
            try! input.attr("checked", "checked")
        }
        try encoder.container.appendChild(wrapLabelAfter(input: input, forKey: key))
    }
    
    private func createLabel(inputId: String, forKey key: Key) -> Element {
        let fiKey = key as? HTMLFormCodingKey
        let label = try! Element(Tag.valueOf("label"), "")
        try! label.appendText(fiKey?.label ?? key.stringValue.camelCaseExpanded.capitalized)
        try! label.attr("for", inputId)
        return label
    }
    
    private func appendErrorAndInstructions(div: Element, forKey key: Key) {
        let fiKey = key as? HTMLFormCodingKey
        let name = try! keyToName(key)
        
        if let instructions = fiKey?.instructions {
            let inst = try! div.appendElement("div")
            try! inst.addClass("instructions")
            try! inst.appendText(instructions)
        }
        
        if let error = encoder.validationErrors[name] {
            let err = try! div.appendElement("div")
            try! err.addClass("error")
            try! err.appendText(error)
        }
    }
    
    private func createFormItem() throws -> Element {
        let div = try encoder.container.appendElement("div")
        try div.addClass("form-item")
        return div
    }
    
    private func wrapLabelBefore(input: Element, forKey key: Key) -> Element {
        let inputId = "edit-\(key.stringValue)"
        try! input.attr("id", inputId)
        
        let div = try! Element(Tag.valueOf("div"), "")
        try! div.attr("class", "form-item")
        try! div.appendChild(createLabel(inputId: inputId, forKey: key))
        try! div.appendChild(input)
        
        appendErrorAndInstructions(div: div, forKey: key)
        
        return div
    }
    
    private func wrapLabelAfter(input: Element, forKey key: Key) -> Element {
        let inputId = "edit-\(key.stringValue)"
        try! input.attr("id", inputId)
        
        let div = try! Element(Tag.valueOf("div"), "")
        try! div.attr("class", "form-item")
        try! div.appendChild(input)
        try! div.appendChild(createLabel(inputId: inputId, forKey: key))
        
        appendErrorAndInstructions(div: div, forKey: key)
        
        return div
    }
    
    private func encodeDescription(_ value: CustomStringConvertible, forKey key: Key, inputType: String = "text") {
        let fiKey = key as? HTMLFormCodingKey
        let name = try! keyToName(key)
        
        let input = try! Element(Tag.valueOf("input"), "")
        try! input.attr("name", name)
        try! input.attr("type", fiKey?.inputType ?? inputType)
        try! input.attr("value", value.description)
        try! input.attr("placeholder", key.stringValue.camelCaseExpanded.lowercased())
        if encoder.validationErrors[name] != nil {
            try! input.addClass("error")
        }
        
        if let maxLength = fiKey?.maxLength {
            try! input.attr("maxlength", maxLength.description)
        }
        if let size = fiKey?.size {
            try! input.attr("size", size.description)
        }
        
        try! encoder.container.appendChild(wrapLabelBefore(input: input, forKey: key))
    }
    
    static func codingPathToName(path: [CodingKey]) throws -> String {
        guard let firstKey = path.first else {
            throw HTMLFormEncodingError.cantEncodeSingleValue
        }
        return path[0 ..< path.count].reduce(firstKey.stringValue) { (prefix, key) -> String in
            return prefix + "[\(key.stringValue)]"
        }
    }
    
    func keyToName(_ lastKey: CodingKey) throws -> String {
        if let firstKey = codingPath.first {
            return codingPath[0 ..< codingPath.count].reduce(firstKey.stringValue) { (prefix, key) -> String in
                return prefix + "[\(key.stringValue)]"
                } + "[\(lastKey.stringValue)]"
        }
        else {
            return lastKey.stringValue
        }
    }
    
//    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : CustomStringConvertible {
//        encoder.append("<input name='\(key.stringValue)' value='\(value.description)'>")
//    }
    
    mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        print(value)
        
        switch value {
        case let d as Date:
            try encode(d, forKey: key)
        case let e as Encodable:
            let legend = try Element(Tag.valueOf("legend"), "")
            try! legend.appendText(key.stringValue.camelCaseExpanded.capitalized)
            
            let fieldset = try Element(Tag.valueOf("fieldset"), "")
            try! fieldset.appendChild(legend)
            
            self.encoder.push(key: key, fieldset: fieldset)
            defer { self.encoder.pop() }
            
            try e.encode(to: self.encoder)
            
        default:
            throw HTMLFormEncodingError.unsupportedType
        }
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let legend = try! Element(Tag.valueOf("legend"), "")
        try! legend.appendText(key.stringValue.camelCaseExpanded.capitalized)
        
        let fieldset = try! Element(Tag.valueOf("fieldset"), "")
        try! fieldset.appendChild(legend)
        
        encoder.push(key: key, fieldset: fieldset)
        defer { encoder.pop() }
        
        return KeyedEncodingContainer(KeyedFormInputEncodingContainer<NestedKey>(encoder: encoder,
                                                                                 forCodingPath: codingPath + [key]))
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        return encoder.unkeyedContainer()
    }
    
    mutating func superEncoder() -> Encoder {
        return encoder
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        return encoder
    }
    
    init(encoder: HTMLFormEncoder) {
        self.encoder = encoder
        self.codingPath = encoder.codingPath
    }
    
    init(encoder: HTMLFormEncoder, forCodingPath path: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = path
    }
}


struct UnkeyedFormInputEncodingContainer: UnkeyedEncodingContainer, SingleValueEncodingContainer {
    
    var codingPath: [CodingKey] = []
    var count: Int = 0
    var encoder: HTMLFormEncoder
    
    mutating func encodeNil() throws {
        abort()
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return encoder.container(keyedBy: keyType)
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return self
    }
    
    mutating func superEncoder() -> Encoder {
        return encoder
    }
    
    init(encoder: HTMLFormEncoder) {
        self.encoder = encoder
    }
    
    func encode<T>(_ value: T) throws where T: Encodable {
        abort()
    }
}

public class HTMLFormEncoder: Encoder {
    public var codingPath: [CodingKey] = []
    
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    var containers: [Element]
    let validationErrors: [String : String]
    
    var container: Element {
        return containers.last!
    }
    
    var form: Element {
        return containers.first!
    }
    
    public static func encode(_ value: Encodable) throws -> Element {
        let encoder = try HTMLFormEncoder()
        try value.encode(to: encoder)
        return encoder.form
    }
    
    func append(_ child: Node) {
        try! form.appendChild(child)
    }
    
    init(validationErrors: [String : String] = [:]) throws {
        let form = try Element(Tag.valueOf("form"), "")
        try! form.attr("method", "post")
        try! form.attr("accept-charset", "UTF-8")
        
        containers = [form]
        self.validationErrors = validationErrors
    }
    
    func push(key: CodingKey, fieldset: Element) {
        try! container.appendChild(fieldset)
        codingPath.append(key)
        containers.append(fieldset)
    }
    
    func pop() {
        codingPath.removeLast()
        containers.removeLast()
    }
    
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(KeyedFormInputEncodingContainer<Key>(encoder: self))
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedFormInputEncodingContainer(encoder: self)
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return SingleValueFormInputEncodingContainer(encoder: self, codingPath: codingPath)
    }
    
}
