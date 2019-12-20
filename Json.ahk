/**
 * Class name: Json
 * List of public methods:
 *   Load(ByRef str)
 *   Dump(obj)
 * Compatibility:
 *   This has been tested and is known to work with versions: 2.0-a104 through a108 .
 *   This will NOT work with versions: a103 and below.
 * Project repository:
 *   https://github.com/rothor/JSON_for_AutoHotkey2.0-a104
 */
class Json
{

/**
 * Method name: Load
 * Params:
 *   str - the JSON string to be parsed
 * Return values:
 *   Returns a Map or Array on success. 
 *   Returns an empty string on failure.
 * Implementation notes:
 *   - JSON objects become Maps, and JSON arrays become Arrays.
 *   - 'null' values are set to Json.Null . You can test if a value is null like this:
 *      if (x = Json.Null)
 */
static Load(ByRef str)
{
	strObj := Json.StrManager.new(str)
	
	elementBegin := 1
	success := Json.getElement(strObj, elementBegin, element, elementEnd)
	if (!success) {
		return ""
	}
	if (SubStr(strObj.str, elementEnd + 1) != "") { ; make sure there are no chars after the object
		return ""
	}
	return element
}

class StrManager
{
	str := ""
	length := 0
	
	__New(ByRef str)
	{
		this.str := Json.removeWhiteSpace(str)
		this.length := StrLen(str)
	}
	
	getSegment(begin, end)
	{
		return SubStr(this.str, begin, end - begin + 1)
	}
}

static LoadArray(strObj, begin, end)
{
	arrayOut := Array()
	elementBegin := begin + 1
	if (elementBegin = end) { ; This is to handle the case where the array is completely empty
		return arrayOut
	}
	while (true) {
		success := Json.getElement(strObj, elementBegin, element, elementEnd)
		if (!success) {
			return ""
		}
		arrayOut.Push(element)
		
		if (elementEnd == end - 1) { ; if we have reached the end of the string
			break
		}
		else if (elementEnd > end - 1) { ; if we went past the end, something went wrong
			return ""
		}
		
		if (SubStr(strObj.str, elementEnd + 1, 1) != ",") { ; the next char should be a comma
			return ""
		}
		elementBegin := elementEnd + 2 ; the next element begins after the comma
		if (elementBegin >= end) { ; This happens when the last character before the closing bracket is a comma.
			return ""
		}
	}
	
	return arrayOut
}

static LoadMap(strObj, begin, end)
{
	objOut := Map()
	keyBegin := begin + 1
	if (keyBegin = end) { ; This is to handle the case where the map is completely empty
		return objOut
	}
	while (true) {
		; Get key name
		c := SubStr(strObj.str, keyBegin, 1)
		if (c != "`"") {
			return ""
		}
		keyEnd := Json.getClosingQuotePos(strObj, keyBegin)
		if (keyEnd == 0) {
			return ""
		}
		key := strObj.getSegment(keyBegin + 1, keyEnd - 1) ; get str between quotes
		if (Json.unescapeStr(key, keyUnescaped) = 0) {
			return ""
		}
		if (SubStr(strObj.str, keyEnd + 1, 1) != ":") { ; next char should be ':'
			return ""
		}
		
		; Get value
		elementBegin := keyEnd + 2
		success := Json.getElement(strObj, elementBegin, element, elementEnd)
		if (!success) {
			return ""
		}
		objOut[keyUnescaped] := element
		
		if (elementEnd == end - 1) { ; if we have reached the end of the string
			break
		}
		else if (elementEnd > end - 1) { ; if we went past the end, something went wrong
			return ""
		}
		
		if (SubStr(strObj.str, elementEnd + 1, 1) != ",") { ; the next char should be a comma
			return ""
		}
		keyBegin := elementEnd + 2 ; the next element begins after the comma
		if (keyBegin >= end) { ; This happens when the last character before the closing brace is a comma.
			return ""
		}
	}
	
	return objOut
}

; Returns 1 on success, 0 on failure
static getElement(strObj, elementBegin, ByRef element, ByRef elementEnd)
{
	c := SubStr(strObj.str, elementBegin, 1)
	if (c == "{") { ; if it's an object
		elementEnd := Json.getClosingBracePos(strObj, elementBegin)
		if (elementEnd == 0) {
			return 0
		}
		element := Json.LoadMap(strObj, elementBegin, elementEnd)
		if (element == "") {
			return 0
		}
		return 1
	}
	else if (c == "[") { ; if it's an array
		elementEnd := Json.getClosingBracketPos(strObj, elementBegin)
		if (elementEnd == 0) {
			return 0
		}
		element := Json.LoadArray(strObj, elementBegin, elementEnd)
		if (element == "") {
			return 0
		}
		return 1
	}
	else if (c == "`"") { ; if it's a string
		elementEnd := Json.getClosingQuotePos(strObj, elementBegin)
		if (elementEnd == 0) {
			return 0
		}
		element := strObj.getSegment(elementBegin + 1, elementEnd - 1) ; get str between quotes
		if (Json.unescapeStr(element, elementUnescaped) = 0) {
			return 0
		}
		element := elementUnescaped
		return 1
	}
	else if (InStr("0123456789.-", c)) { ; if it's a number
		elementEnd := Json.getNumEndPos(strObj, elementBegin)
		if (elementEnd == 0) {
			return 0
		}
		element := strObj.getSegment(elementBegin, elementEnd)
		element := element + 0 ; force number
		return 1
	}
	else if (c = "t" and SubStr(strObj.str, elementBegin, 4) = "true") {
		elementEnd := elementBegin + 3
		element := 1
		return 1
	}
	else if (c = "f" and SubStr(strObj.str, elementBegin, 5) = "false") {
		elementEnd := elementBegin + 4
		element := 0
		return 1
	}
	else if (c = "n" and SubStr(strObj.str, elementBegin, 4) = "null") { ; if it's null
		elementEnd := elementBegin + 3
		element := Json.Null
		return 1
	}
	else {
		return 0
	}
}

; Returns 1 on success, 0 on failure
static unescapeStr(str, ByRef outStr)
{
	outStr := ""
	pos := 1
	escapeNextChar := false
	while (pos <= StrLen(str)) {
		c := SubStr(str, pos, 1)
		if (escapeNextChar) {
			if (InStr("\/`"", c)) {
				outStr .= c
			}
			else if (c = "b") {
				outStr .= "`b"
			}
			else if (c = "f") {
				outStr .= "`f"
			}
			else if (c = "n") {
				outStr .= "`n"
			}
			else if (c = "r") {
				outStr .= "`r"
			}
			else if (c = "t") {
				outStr .= "`t"
			}
			else if (c == "u") { ; Must be a lowercase 'u'
				code := SubStr(str, pos + 1, 4)
				if (StrLen(code) < 4) {
					return 0
				}
				numChars := "0123456789abcdefABCDEF"
				if (!InStr(numChars, SubStr(code, 1, 1)) or
					!InStr(numChars, SubStr(code, 2, 1)) or
					!InStr(numChars, SubStr(code, 3, 1)) or
					!InStr(numChars, SubStr(code, 4, 1))) {
					return 0
				}
				outStr .= Chr(("0x" code) + 0)
				pos += 4
			}
			else { ; Cannot escape this character in JSON
				return 0
			}
			escapeNextChar := false
		}
		else if (c = "\") {
			escapeNextChar := true
		}
		else {
			outStr .= c
			escapeNextChar := false
		}
		
		pos++
	}
	
	return 1
}

; Returns 0 on failure
static getClosingBracketPos(strObj, begin)
{
	pos := begin + 1
	insideStr := false
	ignoreNextQuote := false
	closeCount := 1
	while (pos <= strObj.length) {
		c := SubStr(strObj.str, pos, 1)
		if (!insideStr) {
			if (c = "[") {
				closeCount++
			}
			else if (c = "]") {
				closeCount--
				if (closeCount = 0) {
					return pos
				}
			}
		}
		
		if (c = "`"" and !ignoreNextQuote) {
			insideStr := !insideStr
		}
		
		if (c = "\") {
			ignoreNextQuote := true
		}
		else {
			ignoreNextQuote := false
		}
		
		pos++
	}
	
	return 0
}

; Returns 0 on failure
static getClosingBracePos(strObj, begin)
{
	pos := begin + 1
	insideStr := false
	ignoreNextQuote := false
	closeCount := 1
	while (pos <= strObj.length) {
		c := SubStr(strObj.str, pos, 1)
		if (!insideStr) {
			if (c = "{") {
				closeCount++
			}
			else if (c = "}") {
				closeCount--
				if (closeCount = 0) {
					return pos
				}
			}
		}
		
		if (c = "`"" and !ignoreNextQuote) {
			insideStr := !insideStr
		}
		
		if (c = "\") {
			ignoreNextQuote := true
		}
		else {
			ignoreNextQuote := false
		}
		
		pos++
	}
	
	return 0
}

; Returns 0 on failure
static getClosingQuotePos(strObj, begin)
{
	pos := begin + 1
	ignoreNextQuote := false
	while (pos <= strObj.length) {
		c := SubStr(strObj.str, pos, 1)
		if (c = "`"" and !ignoreNextQuote) {
			return pos
		}
		
		if (c = "\") {
			ignoreNextQuote := true
		}
		else {
			ignoreNextQuote := false
		}
		
		pos++
	}
	
	return 0
}

; Returns 0 on failure
static getNumEndPos(strObj, begin)
{
	pos := begin + 1
	while (pos <= strObj.length) {
		c := SubStr(strObj.str, pos, 1)
		if (!InStr("0123456789.+-eE", c)) {
			break
		}
		pos++
	}
	end := pos - 1
	numStr := strObj.getSegment(begin, end)
	
	; make sure str is in the format "-2.4e7" or something like that
	; Note: '.2' is invalid -> '0.2' is valid
	reg := "^(-?(?:[1-9][0-9]*|0)(?:[.][0-9]+)?(?:[eE][+-]?[0-9]+)?)$"
	found := RegExMatch(numStr, reg)
	if (found) {
		return end
	}
	else {
		return 0
	}
}

static removeWhiteSpace(ByRef str)
{
	newStr := ""
	pos := 1
	insideStr := false
	ignoreNextQuote := false
	while (pos <= StrLen(str)) {
		c := SubStr(str, pos, 1)
		if (insideStr) {
			newStr .= c
		}
		else if (!InStr("`n`r`t`s", c)) {
			newStr .= c
		}
		
		if (c = "`"" and !ignoreNextQuote) {
			insideStr := !insideStr
		}
		
		if (c = "\") {
			ignoreNextQuote := true
		}
		else {
			ignoreNextQuote := false
		}
		
		pos++
	}
	
	return newStr
}

static Null := Object()


/**
 * Method name: Dump
 * Params:
 *   obj - the Array, Map, or Object to be dumped
 * Return values:
 *   Returns JSON string on success.
 *   Returns an empty string on failure.
 * Notes:
 *   While Dump converts Objects and Maps to JSON objects, Load converts all JSON objects
 *     to Maps. Therefore, if you Dump and then Load an Object, you'll end up
 *     with a Map, not an Object.
 *   If you want to Dump a value of 'null', set it to Json.Null .
 *     i.e. [2, Json.Null] will Dump to "[2,null]"
 */
static Dump(obj)
{
	if (obj is Map) {
		return Json.DumpMap(obj)
	}
	else if (obj is Array) {
		return Json.DumpArray(obj)
	}
	else if (obj is Object) {
		return Json.DumpObj(obj)
	}
	else {
		return ""
	}
}

static DumpObj(obj)
{
	str := "{"
	first := true
	for k, v in obj.OwnProps() {
		if (first) {
			first := false
		}
		else {
			str .= ","
		}	
		str .= "`"" k "`":"
		str .= Json.DumpVar(v)
	}
	
	str .= "}"
	return str
}

static DumpMap(obj)
{
	str := "{"
	first := true
	for k, v in obj {
		if (first) {
			first := false
		}
		else {
			str .= ","
		}
		str .= "`"" k "`":"
		str .= Json.DumpVar(v)
	}
	str .= "}"
	return str
}

static DumpArray(obj)
{
	str := "["
	first := true
	i := 1
	while (i <= obj.Length) {
		if (first) {
			first := false
		}
		else {
			str .= ","
		}
		str .= Json.DumpVar(obj[i])
		i++
	}
	str .= "]"
	return str
}

static DumpVar(ByRef v)
{
	if (v is Map) {
		return Json.DumpMap(v)
	}
	else if (v is Array) {
		return Json.DumpArray(v)
	}
	else if (v = Json.Null) {
		return "null"
	}
	else if (IsObject(v)) {
		return Json.DumpObj(v)
	}
	else if (v is "number") { ; Integer or float
		return (v "") ; force string
	}
	else { ; String
		return ("`"" Json.escapeString(v) "`"")
	}
}

static escapeString(ByRef str)
{
	outStr := ""
	pos := 1
	len := StrLen(str)
	while (pos <= len) {
		c := SubStr(str, pos, 1)
		if (c = "\") {
			outStr .= "\\"
		}
		else if (c = "`"") {
			outStr .= "\`""
		}
		else if (c = "`b") {
			outStr .= "\b"
		}
		else if (c = "`n") {
			outStr .= "\n"
		}
		else if (c = "`f") {
			outStr .= "\f"
		}
		else if (c = "`r") {
			outStr .= "\r"
		}
		else if (c = "`t") {
			outStr .= "\t"
		}
		else if (Ord(c) <= 0x1F) {
			outStr .= "\u00"
			; The code below just takes the ascii code of c and converts it to hexadecimal
			last := Ord(c)
			if (last >= 0x10) {
				outStr .= "1"
				last -= 0x10
			}
			else {
				outStr .= "0"
			}
			if (last <= 9) {
				outStr .= last
			}
			else {
				outStr .= Chr(last - 10 + Ord("A"))
			}
		}
		else {
			outStr .= c
		}
		pos++
	}
	return outStr
}

}