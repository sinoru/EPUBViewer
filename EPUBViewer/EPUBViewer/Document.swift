//
//  Document.swift
//  EPUBViewer
//
//  Created by Jaehong Kang on 2020/01/03.
//  Copyright © 2020 Jaehong Kang. All rights reserved.
//

import UIKit

class Document: UIDocument {
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        return Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
    }
}

