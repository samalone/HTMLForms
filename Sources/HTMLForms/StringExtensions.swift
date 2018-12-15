//
//  StringExtensions.swift
//  HTMLForms
//
//  Created by Stuart A. Malone on 12/15/18.
//

import Foundation

public struct HtmlOutputContext {
	private let _dangerous: Set<Unicode.Scalar>
	
	private init(_ dangerous: Set<Unicode.Scalar>) {
		_dangerous = dangerous
	}
	
	public func isDangerous(_ char: Unicode.Scalar) -> Bool {
		return _dangerous.contains(char)
	}
	
	public static let text = HtmlOutputContext(["&", "<", ">"])
	public static let attributeValue = HtmlOutputContext(["&", "<", ">", "\"", "'"])
}

extension String {
	
	public func addingCharacterEntities(for context: HtmlOutputContext) -> String {
		return unicodeScalars.reduce("") { $0 + $1.escapingIfNeeded(for: context) }
	}
}

extension UnicodeScalar {
	
	///
	/// Escapes the scalar only if it needs to be escaped for Unicode pages.
	///
	/// [Reference](http://wonko.com/post/html-escaping)
	///
	fileprivate func escapingIfNeeded(for context: HtmlOutputContext) -> String {
		let escapes: [Unicode.Scalar:String] = [
			"\"": "&quot;",
			"&": "&amp;",
			"'": "&apos;",
			"<": "&lt;",
			">": "&gt;"
		]
		if context.isDangerous(self) {
			if let charEscape = escapes[self] {
				return charEscape
			}
			else {
				return "&#" + String(value) + ";"
			}
		}
		return String(self)
	}
	
}
