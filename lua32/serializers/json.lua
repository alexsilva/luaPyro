--------------------------------------------
------------- JSON LIBRARY -----------------
--------------------------------------------

format = format or (string and string.format)
gsub = gsub or (string and string.gsub)
getn = getn or (table and table.getn)
tinsert = tinsert or (table and table.insert)
type, next, tonumber = type, next, tonumber
TRUE = true 
FALSE = false and nil 

function concat(t, sep)
	local sep = sep or '' 
	if table and table.concat then
		return table.concat(t, sep)
	else
		local s = ''
		local t = t or {}
		local i = 1
		local n = getn(t)
		while i<=n do
			if ( i > 1 ) then
				s = s .. sep
			end
			s = s..(t[i] or '')
			i=i+1
		end
		return s
	end
	
end

function isArray(o)
	if not o or (type(o) == 'table' and getn(o) == 0) then
      return FALSE
    end
	local key, _ = next(o, nil)
	while key do
		if not tonumber(key) then
			return FALSE
		end
		key, _ = next(o, key)
	end
	return TRUE
end

function normalize(s)
	s = gsub(s, "([\"])", [[\%1]]) -- replace ["] [\"] ... 
	s = gsub(s, "[\n]", [[\n]])     -- and [\n] for escaped values
	s = gsub(s, "[\t]", [[\t]])     -- and [\t] for escaped values
	s = gsub(s, "[\r]", [[\r]])     -- and [\r] for escaped values
	s = gsub(s, "[\b]", [[\b]])     -- and [\b] for escaped values
	s = gsub(s, "[\f]", [[\f]])     -- and [\f] for escaped values
	return s
end

renderPattern = {
	['nil']=function(n) return "null" end,
	['number']=function(n) return format("%d",n) end,
	['boolean']=function(n) return n==TRUE and 'true' or 'false' end,
	['string']=function(s) return format('"%s"',normalize(s)) end,
	['function']=function(n) return "null" end,
	['userdata']=function(n) return "null" end,
	['table']=function(t, level) return table2JSON(t, level) end,
}

function getRenderValue(value, level)
	local f = renderPattern[value == "false" and "boolean" or type(value)]
	return  f(value, level-1)
end

function renderObject(result, content, level)
	if type(content)=='table' then
		local first = TRUE
		local key, value = next(content, nil)
		tinsert(result, '{')
		while key do
			if first==TRUE then
				first = FALSE
			else
				tinsert(result, ',')
			end
			if tonumber(key) then
				tinsert(result, format('%d: ',tonumber(key)))
			else
				tinsert(result, format('"%s": ',normalize(key)))
			end
			tinsert(result, getRenderValue(value, level))
			key, value = next(content, key)
		end
		tinsert(result, '}')
	else
		tinsert(result, getRenderValue(content, level))
	end
end

function renderArray(result, content, size, level)
	local i = 1
	tinsert(result, '[')
	while i<=size do
		local value = content[i]
		if i~=1 then
			tinsert(result, ',')
		end
		tinsert(result, getRenderValue(value, level))
		i=i+1
	end
	tinsert(result, ']')
end

function render(result, content, level)
	level = level or 999
	if level<1 then
		content = nil
	end
	
	if isArray(content)==TRUE then
		renderArray(result, content, getn(content), level)
	else
		renderObject(result, content, level)
	end
end

--- Converts a table to a JSON string
-- will parse recursively.
-- TODO: add protection against circular references
-- @param t 		table to be converted
-- @param level 	maximum levels to recurse. default: all
function table2JSON(t, level) 
	if type(t) ~= 'table' then
		return getRenderValue(t)
	end
	local result = {}
	render(result, t, level)
	return concat(result)
end

--------------------------------------------
--------------------------------------------
--------------------------------------------


-----------------------------------------------------------------------------
-- JSON4Lua: JSON encoding / decoding support for the Lua language.
-- json Module.
-- Author: Craig Mason-Jones
-- Homepage: http://json.luaforge.net/
-- Version: 0.9.20
-- This module is released under the The GNU General Public License (GPL).
-- Please see LICENCE.txt for details.
--
-- USAGE:
-- This module exposes two functions:
--   encode(o)
--     Returns the table / string / boolean / number / nil / json.null value as a JSON-encoded string.
--   decode(json_string)
--     Returns a Lua object populated with the data encoded in the JSON string json_string.
--
-- REQUIREMENTS:
--   compat-5.1 if using Lua 5.0
--
-- CHANGELOG
--   0.9.20 Introduction of local Lua functions for private functions (removed _ function prefix). 
--          Fixed Lua 5.1 compatibility issues.
--   		Introduced json.null to have null values in associative arrays.
--          encode() performance improvement (more than 50%) through table.concat rather than ..
--          Introduced decode ability to ignore /**/ comments in the JSON string.
--   0.9.10 Fix to array encoding / decoding to correctly manage nil/null values in arrays.
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Module declaration
-----------------------------------------------------------------------------
-- Public functions

-- Private functions
local decode_scanArray
local decode_scanComment
local decode_scanConstant
local decode_scanNumber
local decode_scanObject
local decode_scanString
local decode_scanWhitespace
local encodeString
local isArray
local isEncodable

-----------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-----------------------------------------------------------------------------
--- Encodes an arbitrary Lua object / variable.
-- @param v The Lua object / variable to be JSON encoded.
-- @return String containing the JSON encoding in internal Lua string format (i.e. not unicode)
function json_encode (v)
  -- Handle nil values
  if v==nil then
    return "null"
  end
  
  local vtype = type(v)  

  -- Handle strings
  if vtype=='string' then    
    return '"' .. %encodeString(v) .. '"'	    -- Need to handle encoding in string
  end
  
  -- Handle booleans
  if vtype=='number' or vtype=='boolean' then
    return tostring(v)
  end
  
  -- Handle tables
  if vtype=='table' then
    local rval = {}
    -- Consider arrays separately
    local bArray, maxCount = %isArray(v)
    if bArray then
      local i = 1
      while ( i <= maxCount ) do
        tinsert(rval, json_encode(v[i]))
        i = i + 1
      end
    else	-- An object, not an array
      local isEncodable = %isEncodable
      local encodeString = %encodeString
      foreach(v, function (i, j)
        if %isEncodable(i) and %isEncodable(j) then
          tinsert(%rval, '"' .. %encodeString(i) .. '":' .. json_encode(j))
        end
      end)
    end
    if bArray then
      return '[' .. concat(rval,',') ..']'
    else
      return '{' .. concat(rval,',') .. '}'
    end
  end
  
  -- Handle null values
  if vtype=='function' and v==%null then
    return 'null'
  end
  
  assert(false,'encode attempt to encode unsupported type ' .. vtype .. ':' .. tostring(v))
end

--- The null function allows one to specify a null value in an associative array (which is otherwise
-- discarded if you set the value with 'nil' in Lua. Simply set t = { first=json.null }
local null = function ()
  return null -- so json.null() will also return null ;-)
end
-----------------------------------------------------------------------------
-- Internal, PRIVATE functions.
-- Following a Python-like convention, I have prefixed all these 'PRIVATE'
-- functions with an underscore.
-----------------------------------------------------------------------------

--- Scans a JSON string skipping all whitespace from the current start position.
-- Returns the position of the first non-whitespace character, or nil if the whole end of string is reached.
-- @param s The string being scanned
-- @param startPos The starting position where we should begin removing whitespace.
-- @return int The first position where non-whitespace was encountered, or string.len(s)+1 if the end of string
-- was reached.
function decode_scanWhitespace(s,startPos)
  local whitespace=" \n\r\t"
  local stringLen = strlen(s)
  while ( strfind(whitespace, strsub(s,startPos,startPos), 1, true)  and startPos <= stringLen) do
    startPos = startPos + 1
  end
  return startPos
end

--- Scans an array from JSON into a Lua object
-- startPos begins at the start of the array.
-- Returns the array and the next starting position
-- @param s The string being scanned.
-- @param startPos The starting position for the scan.
-- @return table, int The scanned array as a table, and the position of the next character to scan.
function decode_scanArray(s,startPos)
  local array = {}	-- The return value
  local stringLen = strlen(s)
  assert(strsub(s,startPos,startPos)=='[','decode_scanArray called but array does not start at position ' .. startPos .. ' in string:\n'..s )
  startPos = startPos + 1
  -- Infinite loop for array elements
  repeat
    startPos = %decode_scanWhitespace(s,startPos)
    assert(startPos<=stringLen,'JSON String ended unexpectedly scanning array.')
    local curChar = strsub(s,startPos,startPos)
    if (curChar==']') then
      return array, startPos+1
    end
    if (curChar==',') then
      startPos = %decode_scanWhitespace(s,startPos+1)
    end
    assert(startPos<=stringLen, 'JSON String ended unexpectedly scanning array.')
    object, startPos = json_decode(s,startPos)
    tinsert(array,object)
  until false==true
end

--- Scans a comment and discards the comment.
-- Returns the position of the next character following the comment.
-- @param string s The JSON string to scan.
-- @param int startPos The starting position of the comment
function decode_scanComment(s, startPos)
  assert( strsub(s,startPos,startPos+1)=='/*', "decode_scanComment called but comment does not start at position " .. startPos)
  local endPos = strfind(s,'*/',startPos+2)
  assert(endPos~=nil, "Unterminated comment in string at " .. startPos)
  return endPos+2  
end

--- Scans for given constants: true, false or null
-- Returns the appropriate Lua type, and the position of the next character to read.
-- @param s The string being scanned.
-- @param startPos The position in the string at which to start scanning.
-- @return object, int The object (true, false or nil) and the position at which the next character should be 
-- scanned.
function decode_scanConstant(s, startPos)
  local consts = { ["true"] = true, ["false"] = false, ["null"] = nil }
  local constNames = {"true","false","null"}
  
  local i, k = next( constNames, nil )
  while (i) do
  	if strsub(s,startPos, startPos + strlen(k) -1 )==k then
      return consts[k], startPos + strlen(k)
    end
  	i, k = next( constNames, i )
  end
  
  assert(nil, 'Failed to scan constant from string ' .. s .. ' at starting position ' .. startPos)
end

--- Scans a number from the JSON encoded string.
-- (in fact, also is able to scan numeric +- eqns, which is not
-- in the JSON spec.)
-- Returns the number, and the position of the next character
-- after the number.
-- @param s The string being scanned.
-- @param startPos The position at which to start scanning.
-- @return number, int The extracted number and the position of the next character to scan.
function decode_scanNumber(s,startPos)
  local endPos = startPos+1
  local stringLen = strlen(s)
  local acceptableChars = "+-0123456789.e"
  while (strfind(acceptableChars, strsub(s,endPos,endPos), 1, true)
	and endPos<=stringLen
	) do
    endPos = endPos + 1
  end
  local stringValue = 'return ' .. strsub(s,startPos, endPos-1)
  local stringEval = dostring(stringValue)
  return stringEval, endPos
end

--- Scans a JSON object into a Lua object.
-- startPos begins at the start of the object.
-- Returns the object and the next starting position.
-- @param s The string being scanned.
-- @param startPos The starting position of the scan.
-- @return table, int The scanned object as a table and the position of the next character to scan.
function decode_scanObject(s,startPos)
  local object = {}
  local stringLen = strlen(s)
  local key, value
  assert(strsub(s,startPos,startPos)=='{','decode_scanObject called but object does not start at position ' .. startPos .. ' in string:\n' .. s)
  startPos = startPos + 1
  repeat
    startPos = %decode_scanWhitespace(s,startPos)
    assert(startPos<=stringLen, 'JSON string ended unexpectedly while scanning object.')
    local curChar = strsub(s,startPos,startPos)
    if (curChar=='}') then
      return object,startPos+1
    end
    if (curChar==',') then
      startPos = %decode_scanWhitespace(s,startPos+1)
    end
    assert(startPos<=stringLen, 'JSON string ended unexpectedly scanning object.')
    -- Scan the key
    key, startPos = json_decode(s,startPos)
    assert(startPos<=stringLen, 'JSON string ended unexpectedly searching for value of key ' .. key)
    startPos = %decode_scanWhitespace(s,startPos)
    assert(startPos<=stringLen, 'JSON string ended unexpectedly searching for value of key ' .. key)
    assert(strsub(s,startPos,startPos)==':','JSON object key-value assignment mal-formed at ' .. startPos)
    startPos = %decode_scanWhitespace(s,startPos+1)
    assert(startPos<=stringLen, 'JSON string ended unexpectedly searching for value of key ' .. key)
    value, startPos = json_decode(s,startPos)
    object[key]=value
  until true==false	-- infinite loop while key-value pairs are found
end

--- Scans a JSON string from the opening inverted comma or single quote to the
-- end of the string.
-- Returns the string extracted as a Lua string,
-- and the position of the next non-string character
-- (after the closing inverted comma or single quote).
-- @param s The string being scanned.
-- @param startPos The starting position of the scan.
-- @return string, int The extracted string as a Lua string, and the next character to parse.
function decode_scanString(s,startPos)
  assert(startPos, 'decode_scanString(..) called without start position')
  local startChar = strsub(s,startPos,startPos)
  assert(startChar==[[']] or startChar==[["]],'decode_scanString called for a non-string')
  local escaped = false
  local endPos = startPos + 1
  local bEnded = false
  local stringLen = strlen(s)
  repeat
    local curChar = strsub(s,endPos,endPos)
    if escaped == false then	
      if curChar==[[\]] then
        escaped = true
      else
        bEnded = (curChar==startChar and true or false)
      end
    else
      -- If we're escaped, we accept the current character come what may
      escaped = false
    end
    endPos = endPos + 1
    assert(endPos <= stringLen+1, "String decoding failed: unterminated string at position " .. endPos)
  until (bEnded == true)
  local stringValue = 'return ' .. strsub(s, startPos, endPos-1)
  local stringEval = dostring(stringValue)
  return stringEval, endPos  
end


--- Encodes a string to be JSON-compatible.
-- This just involves back-quoting inverted commas, back-quotes and newlines, I think ;-)
-- @param s The string to return as a JSON encoded (i.e. backquoted string)
-- @return The string appropriately escaped.
function encodeString(s)
  s = gsub(s,'\\','\\\\')
  s = gsub(s,'"','\\"')
  s = gsub(s,"'","\\'")
  s = gsub(s,'\n','\\n')
  s = gsub(s,'\t','\\t')
  return s 
end

-- Determines whether the given Lua type is an array or a table / dictionary.
-- We consider any table an array if it has indexes 1..n for its n items, and no
-- other data in the table.
-- I think this method is currently a little 'flaky', but can't think of a good way around it yet...
-- @param t The table to evaluate as an array
-- @return boolean, number True if the table can be represented as an array, false otherwise. If true,
-- the second returned value is the maximum
-- number of indexed elements in the array. 
function isArray(t)
  -- Next we count all the elements, ensuring that any non-indexed elements are not-encodable 
  -- (with the possible exception of 'n')
  local maxIndex = {0}
  local isEncodable = %isEncodable
  foreach(t, function(k, v)
    if (type(k)=='number' and floor(k)==k and 1<=k) then	-- k,v is an indexed pair
      if (not %isEncodable(v)) then return false end	-- All array elements must be encodable
      %maxIndex[1] = max(%maxIndex[1],k)
    else
      if (k=='n') then
        if v ~= getn(%t) then return false end  -- False if n does not hold the number of elements
      else -- Else of (k=='n')
        if %isEncodable(v) then return false end
      end  -- End of (k~='n')
    end -- End of k,v not an indexed pair
  end)  -- End of loop across all pairs
  return true, maxIndex[1]
end

--- Determines whether the given Lua object / table / variable can be JSON encoded. The only
-- types that are JSON encodable are: string, boolean, number, nil, table and json.null.
-- In this implementation, all other types are ignored.
-- @param o The object to examine.
-- @return boolean True if the object should be JSON encoded, false if it should be ignored.
function isEncodable(o)
  local t = type(o)
  return (t=='string' or t=='boolean' or t=='number' or t=='nil' or t=='table') or (t=='function' and o==%null) 
end

--- Decodes a JSON string and returns the decoded value as a Lua data structure / value.
-- @param s The string to scan.
-- @param [startPos] Optional starting position where the JSON string is located. Defaults to 1.
-- @param Lua object, number The object that was scanned, as a Lua table / string / number / boolean or nil,
-- and the position of the first character after
-- the scanned JSON object.
function json_decode(s, startPos)
  startPos = startPos and startPos or 1
  startPos = %decode_scanWhitespace(s,startPos)
  assert(startPos<=strlen(s), 'Unterminated JSON encoded object found at position in [' .. s .. ']')
  local curChar = strsub(s,startPos,startPos)
  -- Object
  if curChar=='{' then
    return %decode_scanObject(s,startPos)
  end
  -- Array
  if curChar=='[' then
    return %decode_scanArray(s,startPos)
  end
  -- Number
  if strfind("+-0123456789.e", curChar, 1, true) then
    return %decode_scanNumber(s,startPos)
  end
  -- String
  if curChar==[["]] or curChar==[[']] then
    return %decode_scanString(s,startPos)
  end
  if strsub(s,startPos,startPos+1)=='/*' then
    return json_decode(s, %decode_scanComment(s,startPos))
  end
  -- Otherwise, it must be a constant
  return %decode_scanConstant(s,startPos)
end

--------------------------------------------
--------------------------------------------
--------------------------------------------

-- HTTP status codes
STATUS_CODE = {
   [100] = "Continue",
   [101] = "Switching Protocols",
   [200] = "OK",
   [201] = "Created",
   [202] = "Accepted",
   [203] = "Non-Authoritative Information",
   [204] = "No Content",
   [205] = "Reset Content",
   [206] = "Partial Content",
   [300] = "Multiple Choices",
   [301] = "Moved Permanently",
   [302] = "Found",
   [303] = "See Other",
   [304] = "Not Modified",
   [305] = "Use Proxy",
   [307] = "Temporary Redirect",
   [400] = "Bad Request",
   [401] = "Unauthorized",
   [402] = "Payment Required",
   [403] = "Forbidden",
   [404] = "Not Found",
   [405] = "Method Not Allowed",
   [406] = "Not Acceptable",
   [407] = "Proxy Authentication Required",
   [408] = "Request Time-out",
   [409] = "Conflict",
   [410] = "Gone",
   [411] = "Length Required",
   [412] = "Precondition Failed",
   [413] = "Request Entity Too Large",
   [414] = "Request-URI Too Large",
   [415] = "Unsupported Media Type",
   [416] = "Requested range not satisfiable",
   [417] = "Expectation Failed",
   [500] = "Internal Server Error",
   [501] = "Not Implemented",
   [502] = "Bad Gateway",
   [503] = "Service Unavailable",
   [504] = "Gateway Time-out",
   [505] = "HTTP Version not supported",
}

function escapeURL (str)
	str = gsub (str, "\n", "")
	str = gsub (str, "([^0-9a-zA-Z ])", -- locale independent
		function (c) return format ("%%%02X", strbyte(c)) end)
	str = gsub (str, "%s", "%%20")
	return str
end