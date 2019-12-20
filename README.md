# JSON for AutoHotkey 2.0-a104
This is a JSON library for AutoHotkey versions 2.0-a104 and above. Version a104 (which came out on Aug 17, 2019) massively changed how Objects work, and added Maps and Arrays. This library is not compatible with versions a103 and below. This library has been tested and is known to work with versions a104 through a108.

License: [The Unlicense](https://unlicense.org)

## Installation
Include the file "Json.ahk" in your AHK script.

## Example code
```
obj := Object()
obj.a := 5
obj.b := Array()
obj.b.Push(7)
str := Json.Dump(obj)
areEqual := str = "{`"a`":7,`"b`":[9]}" ; areEqual is true

myMap := Json.Load(str) ; myMap is a Map object
val1 := myMap["a"] ; val1 is 5
val2 := myMap["b"][1] ; val2 is 7
```
## Some notes
- The main functions in "Json.ahk" are "Json.Load(str)" and "Json.Dump(obj)" . They return an empty string on failure.
- For 'Dump', obj can be an Object, Array, or Map.
- When Dump'ing, Objects and Maps both become JSON objects (because objects and maps are the same thing in JSON). When Load'ing, JSON objects become Maps. For this reason, if you Dump and then Load an Object, you will get a Map, not an Object.
- Also, null values are supported, via Json.Null . For example:
  ```
  arr := [1, Json.Null, 3]
  str := Json.Dump(arr) ; str will be "[1,null,3]"
  arr := Json.Load(str)
  isNull := arr[1] = Json.Null ; false
  isNull := arr[2] = Json.Null ; true
  isNull := arr[3] = Json.Null ; false
  ```