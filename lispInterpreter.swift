import Foundation

let path = "/Users/mbp13/Documents/lisp interpreter/blah.txt"
let fileContents = (try? String(contentsOfFile: path, encoding:String.Encoding.utf8))!
var file = fileContents[fileContents.startIndex...]

typealias ParseResult = (output: Any, rest: Substring)?
typealias Parser = (Substring) -> ParseResult

var env = [String: Any] ()
env = ["+" : {(input: [Double]) -> Any in (input.reduce(0, {$0 + $1}))},
       "*" : {(input: [Double]) -> Any in (input.reduce(1, {$0 * $1}))},
       "/": {(input: [Double]) -> Any in (input.reduce(1, {$0 * $1}) / (input[1]*input[1]))},
       "-": {(input: [Double]) -> Any in (input.reduce(2 * input[0], {$0 - $1})) },
       ">": {(input: [Double]) -> Any in (input[0] > input[1])},
       ">=": {(input: [Double]) -> Any in (input[0] >= input[1])},
       "<": {(input: [Double]) -> Any in (input[0] < input[1])},
       "<=": {(input: [Double]) -> Any in (input[0] <= input[1])},
       "=": {(input: [Double]) -> Any in (input[0] == input[1])},
       "abc": 8
]

func paranthesisParser(input: Substring) -> (output: Any, rest: Substring)? {
    if input[input.startIndex] == "(" {
        return ("(", input[input.index(after: input.startIndex)...])
    }
    return nil
}


func isAlphabet (char: Character) -> Bool {
    if (char >= "a" && char <= "z") || (char >= "A" && char <= "Z") {
        return true
    }
    return false
}


func boolParser (input: Substring) -> ParseResult {
    if input.count < 2 {
        return nil
    }
    if input[...input.index(input.startIndex, offsetBy: 1)] == "#t" {
        return(true, input[input.index(input.startIndex, offsetBy: 2)...])
    }
    if input[...input.index(input.startIndex, offsetBy: 1)] == "#f" {
        return(false, input[input.index(input.startIndex, offsetBy: 2)...])
    }
    return nil
}


func isDigit(value: Character) -> Bool {
    if value >= "0" && value <= "9" {
        return true
    }
    return false
}


func digitParser(input: Substring) -> ParseResult {
    var index = input.startIndex
    if !isDigit(value: input[input.startIndex]) {
        return nil
    }
    while isDigit(value: input[index]) {
        index = input.index(after: index)
        if index == input.endIndex {
            break
        }
    }
    return (input[input.startIndex..<index], input[index...])
}


func exponentParser (input: Substring) -> ParseResult {
    if input[input.startIndex] == "e" || input[input.startIndex] == "E" {
        var index = input.startIndex
        
        if input[input.index(after: index)] == "+" || input[input.index(after: index)] == "-" {
            index = input.index(after: index)
        }
        if let result = digitParser(input: input[input.index(after: index)...]) {
            let length = (result.output as! Substring).count
            index = input.index(index, offsetBy: length)
        }
        return (input[...index], input[input.index(after: index)...])
    }
    return nil
}


func fractionParser(input: Substring) -> ParseResult {
    if input[input.startIndex] == "." {
        var index = input.startIndex
        if let result = digitParser(input: input[input.index(after: index)...]) {
            let length = (result.output as! Substring).count
            index = input.index(index, offsetBy: length)
        }
        return (input[...index], input[input.index(after: index)...])
    }
    return nil
}


func zeroParser(input: Substring) -> ParseResult {
    if input[input.startIndex] != "0" {
        return nil
    }
    var index = input.startIndex
    if let result = fractionParser(input: input[input.index(after: index)...]) {
        let length = (result.output as! Substring).count
        index = input.index(index, offsetBy: length)
    }
    if let result = exponentParser(input: input[input.index(after: index)...]) {
        let length = (result.output as! Substring).count
        index = input.index(index, offsetBy: length)
    }
    return (input[...index], input[input.index(after: index)...])
}


func intFloatParser (input: Substring) -> ParseResult {
    if input[input.startIndex] == "0" || !isDigit(value: input[input.startIndex]) {
        return nil
    }
    var index = input.startIndex
    if let result = digitParser(input: input[input.index(after: index)...]) {
        let length = (result.output as! Substring).count
        index = input.index(index, offsetBy: length)
        if index == input.endIndex {
            index = input.endIndex
        }
    }
    if let result = fractionParser(input: input[input.index(after: index)...]) {
        let length = (result.output as! Substring).count
        index = input.index(index, offsetBy: length)
    }
    if let result = exponentParser(input: input[input.index(after: index)...]) {
        let length = (result.output as! Substring).count
        index = input.index(index, offsetBy: length)
    }
    return (input[input.startIndex...index], "")
}


func numberParser(input: Substring) -> ParseResult {
    var index = input.startIndex
    if input[index] == "-" {
        index = input.index(after: index)
    }
    if !isDigit(value: input[index])  {
        return nil
    }
    if let result = zeroParser(input: input[index...]) {
        let length = (result.output as! Substring).count
        index = input.index(index, offsetBy: length)
    }
    if let result = intFloatParser(input: input[index...]) {
        let length = (result.output as! Substring).count
        index = input.index(index, offsetBy: length)
    }
    return (Double(input[..<index])!, input[index...] )
}


func stringParser(input: Substring) -> ParseResult {
    if input[input.startIndex] != "\"" {
        return nil
    }
    var isEscape = true
    func inspectChar(char: Character) -> Bool {
        if char == "\"" && !isEscape {
            return true
        }
        if char == "\\" {
            isEscape = true
        } else {
            isEscape = false
        }
        return false
    }
    if let index = input.index(where: inspectChar) {
        let emptyIndex = input.index(after: input.startIndex)
        if input[emptyIndex] == "\"" {
            return("", input[input.index(after: emptyIndex)...])
        } else {
            return (input[input.index(after: input.startIndex)...input.index(before: index)],
                    input[input.index(after: index)...])
        }
    }
    return nil
}


func isSpace(space: Character) -> Bool {
    switch space {
    case " ", "\t", "\n", "\r": return true
    default: return false
    }
}


func spaceParser (input: Substring) -> ParseResult  {
    if !isSpace(space: input[input.startIndex]) {
        return nil
    }
    var index = input.startIndex
    while isSpace(space: input[index]) {
        index = input.index(after: index)
    }
    return(input[..<index], input[index...])
}

func factoryParser (parsers: Parser...) -> Parser {
    func newParser(input: Substring) -> ParseResult {
        for parser in parsers {
            if let result = parser(input) {
                return result
            }
        }
        return nil
    }
    return newParser
}


func symbolParser (input: Substring) -> ParseResult {
    var index = input.startIndex
    if isSpace(space: input[index]) {
        return nil
    }
    while !isSpace(space: input[index]) {
        index = input.index(after: index)
        if input[index] == ")" {
            break
        }
    }
    return(input[..<index], input[index...])
}

func identifier (input: Substring) -> ParseResult {
    var index = input.startIndex
    var output: Any?
    if !isAlphabet(char: input[index]) {
        return nil
    }
    while isAlphabet(char: input[index]) {
        index = input.index(after: index)
    }
    if env.keys.contains(String(describing: input[..<index])) {
        output = env[String(describing: input[..<index])]
    }
    return (output!, input[index...])
}


func defineParser(input: Substring) -> ParseResult {
    var rest = input
    var output = [String: Any]()
    var key = ""
    var value: Any?
    if let result = paranthesisParser(input: rest) {
        rest = result.rest
    } else {
        return nil
    }
    if let result = symbolParser(input: rest) {
        rest = result.rest
        if String(describing: result.output) != "define" {
            return nil
        }
    }
    while rest[rest.startIndex] != ")" {
        if let result = spaceParser(input: rest) {
            rest = result.rest
        }
        if let result = symbolParser(input: rest) {
            rest = result.rest
            key = String(describing: result.output)
        }
        if let result = spaceParser(input: rest) {
            rest = result.rest
        }
        if let result = expressionParser(rest) {
            value = result.output
            result.output
            rest = result.rest
        }
        output[key] = value
        env[key] = value
    }
    rest.remove(at: rest.startIndex)
    return (output, rest)
}


func ifParser (input: Substring) -> ParseResult {
    var rest = input
    var output: Any?
    var expressionArray = [Any]()
    if let result = paranthesisParser(input: rest) {
        rest = result.rest
    }
    var index = rest.startIndex
    if rest[...rest.index(after: index)] != "if" {
        return nil
    }
    index = input.index(after: index)
    rest = input[input.index(after: index)...]
    while rest[rest.startIndex] != ")" {
        if let result = spaceParser(input: rest) {
            rest = result.rest
        }
        if let result = expressionParser(rest) {
            rest = result.rest
            expressionArray.append(result.output)
        }
    }
    if String(describing: expressionArray[0]) == "true" {
        output = expressionArray[1]
    }
    if String(describing: expressionArray[0]) == "false" {
        output = expressionArray[2]
    }
    rest.remove(at: rest.startIndex)
    return (output as Any, rest)
}


func sExpressionParser (input: Substring) -> ParseResult {
    var rest = input
    var output: Any?
    var argArray = [Double]()
    var symbol: Any?
    
    if let result = paranthesisParser(input: rest) {
        rest = result.rest
    } else {
        return nil
    }
    if let result = lambdaParser(input: rest) {
        rest = result.rest
        symbol = result.output
    }
    if let result = symbolParser(input: rest) {
        rest = result.rest
        if env.keys.contains(String(describing: result.output)) {
            symbol = env[String(describing: result.output)]
        }
    }
    while rest[rest.startIndex] != ")" {
        if let result = spaceParser(input: rest) {
            rest = result.rest
        }
        if let result = expressionParser(rest) {
            rest = result.rest
            argArray.append(result.output as! Double)
        }
    }
    output = (symbol as! ([Double]) -> Any)(argArray)
    rest.remove(at: rest.startIndex)
    return (output!, rest)
}


func lambdaParser (input: Substring) -> ParseResult {
    var rest = input
    var output: Any?
    if let result = paranthesisParser(input: rest) {
        rest = result.rest
    }
    if let result = spaceParser(input: rest) {
        rest = result.rest
    }
    if let result = symbolParser(input: rest) {
        rest = result.rest
        if String(describing: result.output) != "lambda" {
            return nil
        }
    }
    var index = rest.startIndex
    while rest[index] != ")" {
        index = rest.index(after: index)
    }
    index = rest.index(index, offsetBy: 3)
    rest = rest[index...]
    if let result = paranthesisParser(input: rest) {
        rest = result.rest
    }
    if let result = symbolParser(input: rest) {
        output = env[String(describing: result.output)]
        rest = result.rest
        index = rest.startIndex
    }
    while rest[index] != ")" {
        index = rest.index(after: index)
    }
    rest = rest[rest.index(index, offsetBy: 2)...]
    return (output as Any, rest)
}

let expressionParser = factoryParser(parsers: boolParser, numberParser, stringParser, lambdaParser, sExpressionParser, identifier)

defineParser(input: file)
