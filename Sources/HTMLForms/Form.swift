//
//  Form.swift
//  HTMLForms
//
//  Created by Stuart A. Malone on 12/14/18.
//

import Foundation

public protocol Node {
	var html: String { get }
}

public class Element: Node {
	public var tag: String
	public var attributes: [String: String] = [:]
	public var children: [Node] = []
	
	init(_ tag: String, id: String? = nil, class: String? = nil, attributes: [String:String] = [:]) {
		self.tag = tag
		self.attributes = attributes
		self.id = id
		if let c = `class` {
			self.class = [c]
		}
	}
	
	public var html: String {
		var result = "<\(tag)"
		for (attr, value) in attributes {
			result += " \(attr)"
			if attr != value {
				result += "='\(value.addingCharacterEntities(for: .attributeValue))'"
			}
		}
		result += ">"
		result += children.map { $0.html }.joined()
		result += "</\(tag)>"
		return result
	}
	
	public subscript(attribute: String) -> String? {
		get {
			return attributes[attribute]
		}
		set(newValue) {
			attributes[attribute] = newValue
		}
	}
	
	public var id: String? {
		get {
			return attributes["id"]
		}
		set {
			attributes["id"] = newValue
		}
	}
	
	public var `class`: Set<String> {
		get {
			if let values = attributes["class"] {
				return Set<String>(values.split(separator: " ").map(String.init))
			}
			else {
				return []
			}
		}
		set {
			attributes["class"] = newValue.joined(separator: " ")
		}
	}
	
	public func addClass(_ c: String) {
		self.class = self.class.union([c])
	}
	
	public func removeClass(_ c: String) {
		self.class = self.class.subtracting([c])
	}
	
	public func append(_ child: Node) {
		children.append(child)
	}
	
	public func prepend(_ child: Node) {
		children.insert(child, at: 0)
	}
}

public class Text: Node {
	public var value: String
	
	public var html: String {
		return value.addingCharacterEntities(for: .text)
	}
	
	public init() {
		value = ""
	}
	
	public init(_ value: String) {
		self.value = value
	}
}

public class Html: Node {
	public var value: String
	
	public var html: String {
		return value
	}
	
	public init() {
		value = ""
	}
	
	public init(_ value: String) {
		self.value = value
	}
}

public class Div: Element {
	public init(class: String? = nil) {
		super.init("div")
		if let c = `class` {
			self.class = [c]
		}
	}
}

public class Label: Element {
	public init(for: String? = nil) {
		super.init("label")
		self.for = `for`
	}
	
	public var `for`: String? {
		get {
			return attributes["for"]
		}
		set {
			attributes["for"] = newValue
		}
	}
}

public class Form: Element {
	public init() {
		super.init("form")
		self.method = "post"
		self.acceptCharset = "UTF-8"
	}
	
	public var method: String {
		get {
			return attributes["method"]!
		}
		set {
			attributes["method"] = newValue
		}
	}
	
	public var action: String? {
		get {
			return attributes["action"]
		}
		set {
			attributes["action"] = newValue
		}
	}
	
	public var acceptCharset: String {
		get {
			return attributes["accept-charset"]!
		}
		set {
			attributes["accept-charset"] = newValue
		}
	}
	
	public var name: String? {
		get {
			return attributes["name"]
		}
		set {
			attributes["name"] = newValue
		}
	}
	
	public var enctype: String? {
		get {
			return attributes["name"]
		}
		set {
			attributes["name"] = newValue
		}
	}
}

public class Input: Element {
	public init(name: String, type: String, value: String? = nil, placeholder: String? = nil) {
		super.init("input")
		self.name = name
		self.type = type
		self.value = value
		self.placeholder = placeholder
	}
	
	public var type: String {
		get {
			return attributes["type"]!
		}
		set {
			attributes["type"] = newValue
		}
	}
	
	public var name: String {
		get {
			return attributes["name"]!
		}
		set {
			attributes["name"] = newValue
		}
	}
	
	public var value: String? {
		get {
			return attributes["value"]
		}
		set {
			attributes["value"] = newValue
		}
	}
	
	public var placeholder: String? {
		get {
			return attributes["placeholder"]
		}
		set {
			attributes["placeholder"] = newValue
		}
	}
}
