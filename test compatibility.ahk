/**
 * The purpose of this script is to easily test future versions of AHK for breaks
 *   in compatibility with the Json class.
 * Just run this script with the version of AHK you want to test. It will create
 *   a text file 'results.txt'. If the file says '97/97' tests have succeeded,
 *   then it is compatible with that version of AHK.
 * (Or at least, it probably is. These tests may not cover every possible input,
 *   but they cover the majority of use cases.)
 */
#include Json.ahk


class DataManager
{

file := ""
testCount := 0
sectionCount := 0
sectionTestCount := 0
totalTestCount := 0
successCount := 0

__New()
{
	this.file := FileOpen("results.txt", "w")
}

__Delete()
{
	
}

result(success)
{
	this.sectionTestCount++
	this.totalTestCount++
	this.successCount += success
	this.file.Write(this.sectionTestCount "/" this.totalTestCount ": " success "`n")
}

newSection(secName)
{
	this.sectionCount++
	this.sectionTestCount := 0
	if (this.sectionCount > 1)
		this.file.Write("----------`n")
	this.file.Write(secName "`n")
}

onError(e)
{
	this.file.Write("#####################`n"
		"An error occurred`n")
	for name, value in e.OwnProps() {
		this.file.Write(name ": " value "`n")
	}
	this.file.Close()
}

done()
{
	this.file.Write("`n`nSuccess: " this.successCount " / " this.totalTestCount)
	this.file.Close()
}

}

dm := DataManager.new()
OnError(dm.GetMethod("onError").Bind(dm))

; ### Load Integer valid ###
dm.newSection("Load Integer valid")
strArr := Array()
valArr := Array()
strArr.Push("[1]")
valArr.Push(1)
strArr.Push("[-100]")
valArr.Push(-100)
strArr.Push("[4294967295]")
valArr.Push(4294967295)
strArr.Push("[0]")
valArr.Push(0)
strArr.Push("[-0]")
valArr.Push(0)
Loop (strArr.Length) {
	i := A_Index
	loadVal := Json.Load(strArr[i])
	success := (loadVal != "") and (type(loadVal[1]) = type(valArr[i])) and (loadVal[1] = valArr[i])
	dm.result(success)
}


; ### Load Integer invalid ###
dm.newSection("Load Integer invalid")
strArr := Array()
strArr.Push("[01]")
strArr.Push("[-]")
strArr.Push("[+1]")
strArr.Push("[+]")
strArr.Push("[1-]")
strArr.Push("[-1-]")
strArr.Push("[1-2]")
strArr.Push("[00]")
strArr.Push("[-00]")
Loop (strArr.Length) {
	i := A_Index
	loadVal := Json.Load(strArr[i])
	success := (loadVal = "")
	dm.result(success)
}


; ### Load Float valid ###
dm.newSection("Load Float valid")
strArr := Array()
valArr := Array()
strArr.Push("[2.0]")
valArr.Push(2.0)
strArr.Push("[-37.58]")
valArr.Push(-37.58)
strArr.Push("[1.000000009]")
valArr.Push(1.000000009)
strArr.Push("[499999999.12]")
valArr.Push(499999999.12)
strArr.Push("[4e1]")
valArr.Push(4e1)
strArr.Push("[2E+3]")
valArr.Push(2e3)
strArr.Push("[-5.98e-2]")
valArr.Push(-5.98e-2)
strArr.Push("[-6E2]")
valArr.Push(-6e2)
Loop (strArr.Length) {
	i := A_Index
	loadVal := Json.Load(strArr[i])
	success := (loadVal != "") and (type(loadVal[1]) = type(valArr[i])) and (loadVal[1] = valArr[i])
	dm.result(success)
}


; ### Load Float invalid ###
dm.newSection("Load Float invalid")
strArr := Array()
strArr.Push("[.1]")
strArr.Push("[-.1]")
strArr.Push("[1.]")
strArr.Push("[-2.1.1]")
strArr.Push("[1..2]")
strArr.Push("[1.e]")
strArr.Push("[1.e2]")
strArr.Push("[e2]")
strArr.Push("[2e]")
strArr.Push("[e]")
Loop (strArr.Length) {
	i := A_Index
	loadVal := Json.Load(strArr[i])
	success := (loadVal = "")
	dm.result(success)
}


; ### Load String valid ###
dm.newSection("Load String valid")
strArr := Array()
valArr := Array()
strArr.Push("[`"1`"]")
valArr.Push("1")
strArr.Push("[`"[]`"]")
valArr.Push("[]")
strArr.Push("[`"abcdeABCDE asdf`"]")
valArr.Push("abcdeABCDE asdf")
strArr.Push("[`"\`"`"]")
valArr.Push("`"")
strArr.Push("[`"\\a\/`"]")
valArr.Push("\a/")
strArr.Push("[`"\\a/`"]")
valArr.Push("\a/")
strArr.Push("[`"abc\u0060def`"]")
valArr.Push("abc" Chr(0x60) "def")
strArr.Push("[`"\`"\`"a\`"`"]")
valArr.Push("`"`"a`"")
strArr.Push("[`"\b\n\f\r\t`"]")
valArr.Push("`b`n`f`r`t")
strArr.Push("[`" %% `"]")
valArr.Push(" %% ")
strArr.Push("[`"z\\u001z`"]")
valArr.Push("z\u001z")
Loop (strArr.Length) {
	i := A_Index
	loadVal := Json.Load(strArr[i])
	success := (loadVal != "") and (type(loadVal[1]) = type(valArr[i])) and (loadVal[1] = valArr[i])
	dm.result(success)
}


; ### Load String invalid ###
dm.newSection("Load String invalid")
strArr := Array()
strArr.Push("[`"]")
strArr.Push("[`"`"`"]")
strArr.Push("[`"a]")
strArr.Push("[a`"]")
strArr.Push("[`"\`"]")
strArr.Push("[`"\\\`"]")
strArr.Push("[`"\u001`"]")
strArr.Push("[`"a\u001z`"]")
strArr.Push("[`"\u 0010`"]")
Loop (strArr.Length) {
	i := A_Index
	loadVal := Json.Load(strArr[i])
	success := (loadVal = "")
	dm.result(success)
}


; ### Load Array valid ###
dm.newSection("Load Array valid")
str := "[]"
loadVal := Json.Load(str)
dm.result((loadVal != "") and (loadVal is Array) and (loadVal.Length = 0))

str := "[1,[21],[31,[321]]]"
loadVal := Json.Load(str)
dm.result((loadVal != "") and (loadVal is Array) and (loadVal.Length = 3) and (loadVal[1] = 1))
dm.result((loadVal != "") and (loadVal is Array) and (loadVal.Length = 3) and (loadVal[2] is Array) and (loadVal[2].Length = 1) and (loadVal[2][1] = 21))
dm.result((loadVal != "") and (loadVal is Array) and (loadVal.Length = 3) and (loadVal[3] is Array) and (loadVal[3].Length = 2) and (loadVal[3][1] = 31))
dm.result((loadVal != "") and (loadVal is Array) and (loadVal.Length = 3) and (loadVal[3] is Array) and (loadVal[3].Length = 2) and (loadVal[3][2] is Array) and (loadVal[3][2].Length = 1) and (loadVal[3][2][1] = 321))


; ### Load Array invalid ###
dm.newSection("Load Array invalid")
strArr := Array()
strArr.Push("[,]")
strArr.Push("[1,]")
strArr.Push("[,1]")
strArr.Push("[1,1")
strArr.Push("1,1]")
strArr.Push("[[]")
strArr.Push("[]]")
strArr.Push("[1,[1,]]")
Loop (strArr.Length) {
	i := A_Index
	loadVal := Json.Load(strArr[i])
	success := (loadVal = "")
	dm.result(success)
}


; ### Load Object valid ###
dm.newSection("Load Object valid")
str := "{}"
loadVal := Json.Load(str)
dm.result((loadVal != "") and (loadVal is Map) and (loadVal.Count = 0))

str := "{`"a`":`"a`",`"b`":{`"a`":`"ba`"},`"c`":{`"a`":`"ca`",`"b`":{`"a`":`"cba`"}}}"
loadVal := Json.Load(str)
dm.result((loadVal != "") and (loadVal is Map) and (loadVal.Count = 3) and (loadVal["a"] = "a"))
dm.result((loadVal != "") and (loadVal is Map) and (loadVal.Count = 3) and (loadVal["b"] is Map) and (loadVal["b"].Count = 1) and (loadVal["b"]["a"] = "ba"))
dm.result((loadVal != "") and (loadVal is Map) and (loadVal.Count = 3) and (loadVal["c"] is Map) and (loadVal["c"].Count = 2) and (loadVal["c"]["a"] = "ca"))
dm.result((loadVal != "") and (loadVal is Map) and (loadVal.Count = 3) and (loadVal["c"] is Map) and (loadVal["c"].Count = 2) and (loadVal["c"]["b"] is Map) and (loadVal["c"]["b"].Count = 1) and (loadVal["c"]["b"]["a"] = "cba"))


; ### Load Object invalid ###
dm.newSection("Load Object invalid")
strArr := Array()
strArr.Push("{`"a`":}")
strArr.Push("{`"a:1}")
strArr.Push("{a`":}")
strArr.Push("{`"a`":1")
strArr.Push("{`"a`"1}")
strArr.Push("{`"a`"}")
strArr.Push("{a:1}")
strArr.Push("{`"a`":1,}")
strArr.Push("{,`"a`":1}")
strArr.Push("{`"a`":1}1")
Loop (strArr.Length) {
	i := A_Index
	loadVal := Json.Load(strArr[i])
	success := (loadVal = "")
	dm.result(success)
}


; ### Dump Integer ###
dm.newSection("Dump Integer")
valArr := Array()
strArr := Array()
valArr.Push(Array(0))
strArr.Push("[0]")
valArr.Push(Array(-123))
strArr.Push("[-123]")
valArr.Push(Array(4294967295))
strArr.Push("[4294967295]")
Loop (valArr.Length) {
	i := A_Index
	dumpVal := Json.Dump(valArr[i])
	success := (dumpVal = strArr[i])
	dm.result(success)
}


; ### Dump Float ###
dm.newSection("Dump Float")
valArr := Array()
strArr := Array()
valArr.Push(Array(0.0))
strArr.Push("[0.0]")
valArr.Push(Array(-123.456))
strArr.Push("[-123.456]")
valArr.Push(Array(1.0000000090000005))
strArr.Push("[1.0000000090000005]")
Loop (valArr.Length) {
	i := A_Index
	dumpVal := Json.Dump(valArr[i])
	success := (dumpVal = strArr[i])
	dm.result(success)
}


; ### Dump String ###
dm.newSection("Dump String")
valArr := Array()
strArr := Array()
valArr.Push(Array(""))
strArr.Push("[`"`"]")
valArr.Push(Array("ab"))
strArr.Push("[`"ab`"]")
valArr.Push(Array("a`"b"))
strArr.Push("[`"a\`"b`"]")
valArr.Push(Array("a" Chr(0x1E) "b"))
strArr.Push("[`"a\u001Eb`"]")
valArr.Push(Array("\\`"\`"`""))
strArr.Push("[`"\\\\\`"\\\`"\`"`"]")
Loop (valArr.Length) {
	i := A_Index
	dumpVal := Json.Dump(valArr[i])
	success := (dumpVal = strArr[i])
	dm.result(success)
}


; ### Dump Object ###
dm.newSection("Dump Object")
obj := Object()
dumpVal := Json.Dump(obj)
dm.result(dumpVal = "{}")

obj := Object()
obj.a := "a"
obj.b := Object()
obj.b.a := "ba"
obj.b.b := "bb"
dumpVal := Json.Dump(obj)
dm.result(dumpVal = "{`"a`":`"a`",`"b`":{`"a`":`"ba`",`"b`":`"bb`"}}")


; ### Dump Map ###
dm.newSection("Dump Map")
m := Map()
dumpVal := Json.Dump(m)
dm.result(dumpVal = "{}")

m := Map()
m["a"] := "a"
m["b"] := Map()
m["b"]["a"] := "ba"
m["b"]["b"] := "bb"
dumpVal := Json.Dump(m)
dm.result(dumpVal = "{`"a`":`"a`",`"b`":{`"a`":`"ba`",`"b`":`"bb`"}}")


; ### Dump Array ###
dm.newSection("Dump Array")
arr := Array()
dumpVal := Json.Dump(arr)
dm.result(dumpVal = "[]")

arr := Array()
arr.Push(1)
arr.Push(Array())
arr[2].Push(21)
arr[2].Push(22)
dumpVal := Json.Dump(arr)
dm.result(dumpVal = "[1,[21,22]]")


dm.done()