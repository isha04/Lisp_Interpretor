import Foundation

let path = "/Users/mbp13/Documents/lisp interpreter/blah.txt"
let fileContents = (try? String(contentsOfFile: path, encoding:String.Encoding.utf8))!
var file = fileContents[fileContents.startIndex...]

typealias ParseResult = (output: Any, rest: Substring)?

var env = [String: Any] ()
env = ["+" : {(input: [Double]) -> Any in (input.reduce(0, {$0 + $1}))},
       "*" : {(input: [Double]) -> Any in (input.reduce(1, {$0 * $1}))},
       "/": {(input: [Double]) -> Any in (input.reduce(1, {$0 * $1}) / (input[1]*input[1]))},
       "-": {(input: [Double]) -> Any in (input.reduce(2 * input[0], {$0 - $1})) },
       ">": {(input: [Double]) -> Any in (input[0] > input[1])},
       ">=": {(input: [Double]) -> Any in (input[0] >= input[1])},
       "<": {(input: [Double]) -> Any in (input[0] < input[1])},
       "<=": {(input: [Double]) -> Any in (input[0] <= input[1])},
       "=": {(input: [Double]) -> Any in (input[0] == input[1])}
]

func paranthesisParser(input: Substring) -> (output: Any, rest: Substring)? {
    if input[input.startIndex] == "(" {
        return ("(", input[input.index(after: input.startIndex)...])
    }
    return nil
}

func isOperator (arithmaticOperator: Character) -> Bool {
    switch arithmaticOperator {
    case "+", "-", "*", "/", ">", "<", "=" : return true
    default: return false
    }
}

func isAlphabet (char: Character) -> Bool {
    if (char >= "a" && char <= "z") || (char >= "A" && char <= "Z") {
        return true
    }
    return false
}

func identifier (input: Substring) -> ParseResult {
    var index = input.startIndex
    if isOperator(arithmaticOperator: input[index]) {
        if input[input.index(after: index)] == "=" {
            index = input.index(after: index)
        }
        return(input[...index], input[input.index(after: index)...])
    }
    if isAlphabet(char: input[index]) {
        while isAlphabet(char: input[index]) {
            index = input.index(after: index)
        }
        return(input[..<index], input[index...])
    }
    return nil
}


func boolParser (input: Substring) -> ParseResult {
    if input.count < 5 {
        return nil
    }
    if input[...input.index(input.startIndex, offsetBy: 3)] == "true" {
        return(true, input[input.index(input.startIndex, offsetBy: 4)...])
    }
    if input[...input.index(input.startIndex, offsetBy: 4)] == "false" {
        return(false, input[input.index(input.startIndex, offsetBy: 5)...])
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


func NumberParser(input: Substring) -> ParseResult {
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
    let output = Double(input[..<index])!
    return (output, input[index...] )
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


func defineParser(input: Substring) -> ParseResult {
    if identifier(input: input)?.output as! String == "define" {
        return ("define", input[input.index(input.startIndex, offsetBy: 5)...])
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
        if let result = sExpressionParser(input: rest) {
            rest = result.rest
            expressionArray.append(result.output)
        }
        if let result = ifParser(input: rest) {
            rest = result.rest
            output = result.output
        }
    }
    if String(describing: expressionArray[0]) == "true" {
        output = expressionArray[1]
    } else {
        if String(describing: expressionArray[0]) == "false" {
            output = expressionArray[2]
        }
    }
    return (output!, rest)
}


func expressionParser (input: Substring) -> ParseResult {
    var output: Any?
    var rest = input
    
    if let result = identifier(input: rest) {
        output = result.output
        rest = result.rest
    }
    if let result = boolParser(input: rest) {
        output = result.output
        rest = result.rest
    }
    if let result = stringParser(input: rest) {
        output = result.output
        rest = result.rest
    }
    if let result = NumberParser(input: rest) {
        output = result.output
        rest = result.rest
    }
    if let result = ifParser(input: rest) {
        rest = result.rest
        output = result.output
    }
    if let result = sExpressionParser(input: rest) {
        output = result.output
        rest = result.rest
    }
    return (output as Any, rest)
}


func sExpressionParser (input: Substring) -> ParseResult {
    var rest = input
    var output: Any?
    var argArray = [Double]()
    var Operator = ""
    if rest[rest.startIndex] != "(" {
        return nil
    }
    if let result = paranthesisParser(input: rest) {
        rest = result.rest
    }
    if let result = identifier(input: rest) {
        rest = result.rest
        if env.keys.contains(String(describing: result.output)) {
            Operator = String(describing: result.output)
        }
    }
    while rest[rest.startIndex] != ")" {
        if let result = spaceParser(input: rest) {
            rest = result.rest
        }
        if let result = expressionParser(input: rest) {
            rest = result.rest
            argArray.append(result.output as! Double)
            if argArray.count > 1 {
                output = (env[Operator] as! ([Double]) -> Any)(argArray)
            }
        }
    }
    rest = rest[input.index(after: rest.startIndex)...]
    return (output!, rest)
}

expressionParser(input: file)?.output
