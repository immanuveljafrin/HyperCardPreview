//
//  SchemaInterpolation.swift
//  HyperCardCommon
//
//  Created by Pierre Lorenzi on 26/08/2019.
//  Copyright © 2019 Pierre Lorenzi. All rights reserved.
//



extension Schema: ExpressibleByStringInterpolation, ExpressibleByStringLiteral {
    
    public typealias StringInterpolation = SchemaInterpolation
    public typealias StringLiteralType = String
    
    public convenience init(stringLiteral: String) {
        
        self.init()
        
        let string = HString(stringLiteral: stringLiteral)
        let tokenizer = Tokenizer(string: string)
        var subSchemas: [SubSchema] = []
        
        while let token = tokenizer.readNextToken() {
            
            let subSchema = ValueSubSchema(accept: { $0 == token }, minCount: 1, maxCount: 1, update: Schema<T>.Update<Token>.none)
            
            subSchemas.append(subSchema)
        }
        
        self.branches = [ Branch(subSchemas: subSchemas) ]
    }
    
    public convenience init(stringInterpolation: SchemaInterpolation) {
        
        self.init()
        
        let subSchemas: [SubSchema] = stringInterpolation.creators.map({ $0.create(for: self) })
        let branch = Branch(subSchemas: subSchemas)
        
        self.branches = [branch]
    }
}

public struct SchemaInterpolation: StringInterpolationProtocol {
    
    public typealias StringLiteralType = String
    
    fileprivate var creators: [SubSchemaCreator] = []
    
    fileprivate class SubSchemaCreator {
        
        var minCount: Int
        var maxCount: Int?
        
        init(minCount: Int, maxCount: Int?) {
            self.minCount = minCount
            self.maxCount = maxCount
        }
        
        func create<T>(for schema: Schema<T>) -> Schema<T>.SubSchema {
            fatalError()
        }
    }
    
    private class TypedSubSchemaCreator<U>: SubSchemaCreator {
        
        var schema: Schema<U>
        
        init(schema: Schema<U>, minCount: Int, maxCount: Int?) {
            
            self.schema = schema
            
            super.init(minCount: minCount, maxCount: maxCount)
        }
        
        override func create<T>(for _: Schema<T>) -> Schema<T>.SubSchema {
            
            if T.self == U.self {
                
                /* So, if an interpolation has a type, the strings will pass the values */
                return Schema<T>.TypedSubSchema<U>(schema: self.schema, minCount: self.minCount, maxCount: self.maxCount, update: Schema<T>.Update<U>.initialization({ (value: U) -> T in
                    return value as! T
                }))
            }
            
            return Schema<T>.TypedSubSchema<U>(schema: self.schema, minCount: self.minCount, maxCount: self.maxCount, update: Schema<T>.Update<U>.none)
        }
    }
    
    private class ValueSubSchemaCreator: SubSchemaCreator {
        
        var token: Token
        
        init(token: Token) {
            
            self.token = token
            super.init(minCount: 1, maxCount: 1)
        }
        
        override func create<T>(for _: Schema<T>) -> Schema<T>.SubSchema {
            
            let token = self.token
            return Schema<T>.ValueSubSchema(accept: { $0 == token }, minCount: 1, maxCount: 1, update: Schema<T>.Update<Token>.none)
        }
    }
    
    public init(literalCapacity: Int, interpolationCount: Int) {
        
    }
    
    public mutating func appendLiteral(_ literal: String) {
        
        let string = HString(converting: literal)!
        let tokenizer = Tokenizer(string: string)
        
        while let token = tokenizer.readNextToken() {
            
            let creator = ValueSubSchemaCreator(token: token)
            self.creators.append(creator)
        }
        
    }
    
    public mutating func appendInterpolation<U>(_ schema: Schema<U>) {
        
        let creator = TypedSubSchemaCreator(schema: schema, minCount: 1, maxCount: 1)
        
        self.creators.append(creator)
    }
    
    public mutating func appendInterpolation<U>(multiple schema: Schema<U>, atLeast minCount: Int = 0, atMost maxCount: Int? = nil) {
        
        let creator = TypedSubSchemaCreator(schema: schema, minCount: minCount, maxCount: maxCount)
        
        self.creators.append(creator)
    }
    
    public mutating func appendInterpolation<U>(maybe schema: Schema<U>) {
        
        let creator = TypedSubSchemaCreator(schema: schema, minCount: 0, maxCount: 1)
        
        self.creators.append(creator)
    }
    
    public mutating func appendInterpolation(variants schemas: [Schema<Void>]) {
        
        // intended for string literal schemas, because they lack types
        
        // We can't make a typed disjunction in a string literal
        let globalSchema = Schema<Void>()
        globalSchema.branches = schemas.map({ (schema: Schema<Void>) -> Schema<Void>.Branch in
            Schema<Void>.Branch(subSchemas: [Schema<Void>.TypedSubSchema<Void>(schema: schema, minCount: 1, maxCount: 1, update: Schema<Void>.Update<Void>.none)])
        })
        
        let creator = TypedSubSchemaCreator(schema: globalSchema, minCount: 0, maxCount: 1)
        
        self.creators.append(creator)
    }
}




