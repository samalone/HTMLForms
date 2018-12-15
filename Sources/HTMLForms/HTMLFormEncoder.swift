//
//  FormInputEncoder.swift
//  App
//
//  Created by Stuart A. Malone on 12/11/18.
//

import Foundation
//import SwiftSoup

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
		let input = Input(name: keyToName(key),
						  type: "date",
						  value: formatter.string(from: value),
						  placeholder: key.stringValue.camelCaseExpanded.lowercased())
		encoder.container.append(wrapLabelBefore(input: input, forKey: key))
    }
    
    mutating func encode(_ value: Bool, forKey key: Key) {
		let input = Input(name: keyToName(key), type: "checkbox", value: "true")
        if (value) {
			input["checked"] = "checked"
        }
        encoder.container.append(wrapLabelAfter(input: input, forKey: key))
    }
    
    private func createLabel(inputId: String, forKey key: Key) -> Element {
        let fiKey = key as? HTMLFormCodingKey
		let label = Label(for: inputId)
		label.append(Text(fiKey?.label ?? key.stringValue.camelCaseExpanded.capitalized))
        return label
    }
    
    private func appendErrorAndInstructions(div: Element, forKey key: Key) {
        let fiKey = key as? HTMLFormCodingKey
        let name = keyToName(key)
        
        if let instructions = fiKey?.instructions {
			let inst = Div(class: "instructions")
            inst.append(Text(instructions))
        }
        
        if let error = encoder.validationErrors[name] {
			let err = Div(class: "error")
            err.append(Text(error))
        }
    }
    
    private func createFormItem() throws -> Element {
		let div = Div(class: "form-item")
		encoder.container.append(div)
        return div
    }
    
    private func wrapLabelBefore(input: Element, forKey key: Key) -> Element {
        let inputId = "edit-\(key.stringValue)"
		input.id = inputId
        
		let div = Div(class: "form-item")
		div.append(createLabel(inputId: inputId, forKey: key))
        div.append(input)
        
        appendErrorAndInstructions(div: div, forKey: key)
        
        return div
    }
    
    private func wrapLabelAfter(input: Element, forKey key: Key) -> Element {
        let inputId = "edit-\(key.stringValue)"
		input.id = inputId
        
		let div = Div(class: "form-item")
        div.append(input)
        div.append(createLabel(inputId: inputId, forKey: key))
        
        appendErrorAndInstructions(div: div, forKey: key)
        
        return div
    }
    
    private func encodeDescription(_ value: CustomStringConvertible, forKey key: Key, inputType: String = "text") {
        let fiKey = key as? HTMLFormCodingKey
        let name = keyToName(key)
		
		let input = Input(name: name,
						  type: fiKey?.inputType ?? inputType,
						  value: value.description,
						  placeholder: key.stringValue.camelCaseExpanded.lowercased())
        if encoder.validationErrors[name] != nil {
			input.addClass("error")
        }
        
        if let maxLength = fiKey?.maxLength {
			input["maxlength"] = maxLength.description
        }
        if let size = fiKey?.size {
			input["size"] = size.description
        }
        
        encoder.container.append(wrapLabelBefore(input: input, forKey: key))
    }
    
    static func codingPathToName(path: [CodingKey]) throws -> String {
        guard let firstKey = path.first else {
            throw HTMLFormEncodingError.cantEncodeSingleValue
        }
        return path[0 ..< path.count].reduce(firstKey.stringValue) { (prefix, key) -> String in
            return prefix + "[\(key.stringValue)]"
        }
    }
    
    func keyToName(_ lastKey: CodingKey) -> String {
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
            let legend = Element("legend")
            legend.append(Text(key.stringValue.camelCaseExpanded.capitalized))
            
            let fieldset = Element("fieldset")
            fieldset.append(legend)
            
            self.encoder.push(key: key, fieldset: fieldset)
            defer { self.encoder.pop() }
            
            try e.encode(to: self.encoder)
            
        default:
            throw HTMLFormEncodingError.unsupportedType
        }
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
		let legend = Element("legend")
		legend.append(Text(key.stringValue.camelCaseExpanded.capitalized))
        
		let fieldset = Element("fieldset")
		fieldset.append(legend)
        
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
        form.append(child)
    }
    
    init(validationErrors: [String : String] = [:]) throws {
        let form = Form()
        containers = [form]
        self.validationErrors = validationErrors
    }
    
    func push(key: CodingKey, fieldset: Element) {
        container.append(fieldset)
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
