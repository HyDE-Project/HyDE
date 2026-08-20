



















local tinytoml = {}








local TOML_VERSION = "1.1.0"
tinytoml._VERSION = "tinytoml 1.0.0"
tinytoml._TOML_VERSION = TOML_VERSION
tinytoml._DESCRIPTION = "a single-file pure Lua TOML parser"
tinytoml._URL = "https://github.com/FourierTransformer/tinytoml"
tinytoml._LICENSE = "MIT"

























































































































local sbyte = string.byte
local chars = {
   SINGLE_QUOTE = sbyte("'"),
   DOUBLE_QUOTE = sbyte('"'),
   OPEN_BRACKET = sbyte("["),
   CLOSE_BRACKET = sbyte("]"),
   BACKSLASH = sbyte("\\"),
   COMMA = sbyte(","),
   POUND = sbyte("#"),
   DOT = sbyte("."),
   CR = sbyte("\r"),
   LF = sbyte("\n"),
}


local function replace_control_chars(s)
   return string.gsub(s, "[%z\001-\008\011-\031\127]", function(c)
      return string.format("\\x%02x", string.byte(c))
   end)
end

local function _error(sm, message, anchor)
   local error_message = {}



   if sm.filename then
      error_message = { "\n\nIn '", sm.filename, "', line ", sm.line_number, ":\n\n  " }

      local _, end_line = sm.input:find(".-\n", sm.line_number_char_index)
      error_message[#error_message + 1] = sm.line_number
      error_message[#error_message + 1] = " | "
      error_message[#error_message + 1] = replace_control_chars(sm.input:sub(sm.line_number_char_index, end_line))
      error_message[#error_message + 1] = (end_line and "\n" or "\n\n")
   end

   error_message[#error_message + 1] = message
   error_message[#error_message + 1] = "\n"

   if anchor ~= nil then
      error_message[#error_message + 1] = "\nSee https://toml.io/en/v"
      error_message[#error_message + 1] = TOML_VERSION
      error_message[#error_message + 1] = "#"
      error_message[#error_message + 1] = anchor
      error_message[#error_message + 1] = " for more details"
   end

   error(table.concat(error_message))
end


local _unpack = unpack or table.unpack
local _tointeger = math.tointeger or tonumber

local _utf8char = utf8 and utf8.char or function(cp)
   if cp < 128 then
      return string.char(cp)
   end
   local suffix = cp % 64
   local c4 = 128 + suffix
   cp = (cp - suffix) / 64
   if cp < 32 then
      return string.char(192 + (cp), (c4))
   end
   suffix = cp % 64
   local c3 = 128 + suffix
   cp = (cp - suffix) / 64
   if cp < 16 then
      return string.char(224 + (cp), c3, c4)
   end
   suffix = cp % 64
   cp = (cp - suffix) / 64
   return string.char(240 + (cp), 128 + (suffix), c3, c4)
end

local function validate_utf8(input, toml_sub)
   local i, len, line_number, line_number_start = 1, #input, 1, 1
   local byte, second, third, fourth = 0, 129, 129, 129
   toml_sub = toml_sub or false
   while i <= len do
      byte = sbyte(input, i)

      if byte <= 127 then
         if toml_sub then
            if byte < 9 then return false, line_number, line_number_start, "TOML only allows some control characters, but they must be escaped in double quoted strings"
            elseif byte == chars.CR and sbyte(input, i + 1) ~= chars.LF then return false, line_number, line_number_start, "TOML requires all '\\r' be followed by '\\n'"
            elseif byte == chars.LF then
               line_number = line_number + 1
               line_number_start = i + 1
            elseif byte >= 11 and byte <= 31 and byte ~= 13 then return false, line_number, line_number_start, "TOML only allows some control characters, but they must be escaped in double quoted strings"
            elseif byte == 127 then return false, line_number, line_number_start, "TOML only allows some control characters, but they must be escaped in double quoted strings" end
         end
         i = i + 1

      elseif byte >= 194 and byte <= 223 then
         second = sbyte(input, i + 1)
         i = i + 2

      elseif byte == 224 then
         second = sbyte(input, i + 1); third = sbyte(input, i + 2)

         if second ~= nil and second >= 128 and second <= 159 then return false, line_number, line_number_start, "Invalid UTF-8 Sequence" end
         i = i + 3

      elseif byte == 237 then
         second = sbyte(input, i + 1); third = sbyte(input, i + 2)

         if second ~= nil and second >= 160 and second <= 191 then return false, line_number, line_number_start, "Invalid UTF-8 Sequence" end
         i = i + 3

      elseif (byte >= 225 and byte <= 236) or byte == 238 or byte == 239 then
         second = sbyte(input, i + 1); third = sbyte(input, i + 2)
         i = i + 3

      elseif byte == 240 then
         second = sbyte(input, i + 1); third = sbyte(input, i + 2); fourth = sbyte(input, i + 3)

         if second ~= nil and second >= 128 and second <= 143 then return false, line_number, line_number_start, "Invalid UTF-8 Sequence" end
         i = i + 4

      elseif byte == 241 or byte == 242 or byte == 243 then
         second = sbyte(input, i + 1); third = sbyte(input, i + 2); fourth = sbyte(input, i + 3)
         i = i + 4

      elseif byte == 244 then
         second = sbyte(input, i + 1); third = sbyte(input, i + 2); fourth = sbyte(input, i + 3)

         if second ~= nil and second >= 160 and second <= 191 then return false, line_number, line_number_start, "Invalid UTF-8 Sequence" end
         i = i + 4

      else

         return false, line_number, line_number_start, "Invalid UTF-8 Sequence"
      end


      if second == nil or second < 128 or second > 191 then return false, line_number, line_number_start, "Invalid UTF-8 Sequence" end
      if third == nil or third < 128 or third > 191 then return false, line_number, line_number_start, "Invalid UTF-8 Sequence" end
      if fourth == nil or fourth < 128 or fourth > 191 then return false, line_number, line_number_start, "Invalid UTF-8 Sequence" end

   end
   return true
end

local function find_newline(sm)
   sm._, sm.end_seq = sm.input:find("\r?\n", sm.i)

   if sm.end_seq == nil then
      sm._, sm.end_seq = sm.input:find(".-$", sm.i)
   end
   sm.line_number = sm.line_number + 1
   sm.i = sm.end_seq + 1
   sm.line_number_char_index = sm.i
end

local escape_sequences = {
   ['b'] = '\b',
   ['t'] = '\t',
   ['n'] = '\n',
   ['f'] = '\f',
   ['r'] = '\r',
   ['e'] = '\027',
   ['\\'] = '\\',
   ['"'] = '"',
}


local function handle_backslash_escape(sm)


   if sm.multiline_string then
      if sm.input:find("^\\[ \t]-\r?\n", sm.i) then
         sm._, sm.end_seq = sm.input:find("%S", sm.i + 1)
         sm.i = sm.end_seq - 1
         return "", false
      end
   end


   sm._, sm.end_seq, sm.match = sm.input:find('^([\\btrfne"])', sm.i + 1)
   local escape = escape_sequences[sm.match]
   if escape then
      sm.i = sm.end_seq
      if sm.match == '"' then
         return escape, true
      else
         return escape, false
      end
   end


   sm._, sm.end_seq, sm.match, sm.ext = sm.input:find("^(x)([0-9a-fA-F][0-9a-fA-F])", sm.i + 1)
   if sm.match then
      local codepoint_to_insert = _utf8char(tonumber(sm.ext, 16))
      if not validate_utf8(codepoint_to_insert) then
         _error(sm, "Escaped UTF-8 sequence not valid UTF-8 character: '\\" .. sm.match .. sm.ext .. "'", "string")
      end
      sm.i = sm.end_seq
      return codepoint_to_insert, false
   end


   sm._, sm.end_seq, sm.match, sm.ext = sm.input:find("^(u)([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])", sm.i + 1)
   if not sm.match then
      sm._, sm.end_seq, sm.match, sm.ext = sm.input:find("^(U)([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])", sm.i + 1)
   end
   if sm.match then
      local codepoint_to_insert = _utf8char(tonumber(sm.ext, 16))
      if not validate_utf8(codepoint_to_insert) then
         _error(sm, "Escaped UTF-8 sequence not valid UTF-8 character: '\\" .. sm.match .. sm.ext .. "'", "string")
      end
      sm.i = sm.end_seq
      return codepoint_to_insert, false
   end

   return nil
end

local function close_string(sm)
   local escape
   local reset_quote
   local start_field, end_field = sm.i + 1, 0
   local second, third = sbyte(sm.input, sm.i + 1), sbyte(sm.input, sm.i + 2)
   local quote_count = 0
   local output = {}
   local found_closing_quote = false
   sm.multiline_string = false


   if second == chars.DOUBLE_QUOTE and third == chars.DOUBLE_QUOTE then
      if sm.mode == "table" then _error(sm, "Cannot have multiline strings as table keys", "table") end
      sm.multiline_string = true
      start_field = sm.i + 3

      second, third = sbyte(sm.input, sm.i + 3), sbyte(sm.input, sm.i + 4)
      if second == chars.LF then
         start_field = start_field + 1
      elseif second == chars.CR and third == chars.LF then
         start_field = start_field + 2
      end
      sm.i = start_field - 1
   end

   while found_closing_quote == false and sm.i <= sm.input_length do
      sm.i = sm.i + 1
      sm.byte = sbyte(sm.input, sm.i)
      if sm.byte == chars.BACKSLASH then
         output[#output + 1] = sm.input:sub(start_field, sm.i - 1)

         escape, reset_quote = handle_backslash_escape(sm)
         if reset_quote then quote_count = 0 end

         if escape ~= nil then
            output[#output + 1] = escape
         else
            sm._, sm._, sm.match = sm.input:find("(.-[^'\"])", sm.i + 1)
            _error(sm, "TOML only allows specific escape sequences. Invalid escape sequence found: '\\" .. sm.match .. "'", "string")
         end

         start_field = sm.i + 1

      elseif sm.multiline_string then
         if sm.byte == chars.DOUBLE_QUOTE then
            quote_count = quote_count + 1
            if quote_count == 5 then
               end_field = sm.i - 3
               output[#output + 1] = sm.input:sub(start_field, end_field)
               found_closing_quote = true
               break
            end
         else
            if quote_count >= 3 then
               end_field = sm.i - 4
               output[#output + 1] = sm.input:sub(start_field, end_field)
               found_closing_quote = true
               sm.i = sm.i - 1
               break
            else
               quote_count = 0
            end
         end

      else
         if sm.byte == chars.DOUBLE_QUOTE then
            end_field = sm.i - 1
            output[#output + 1] = sm.input:sub(start_field, end_field)
            found_closing_quote = true
            break
         elseif sm.byte == chars.CR or sm.byte == chars.LF then
            _error(sm, "String does not appear to be closed. Use multi-line (triple quoted) strings if non-escaped newlines are desired.", "string")
         end
      end
   end

   if not found_closing_quote then
      if sm.multiline_string then
         _error(sm, "Unable to find closing triple-quotes for multi-line string", "string")
      else
         _error(sm, "Unable to find closing quote for string", "string")
      end
   end

   sm.i = sm.i + 1
   sm.value = table.concat(output)
   sm.value_type = "string"
end

local function close_literal_string(sm)
   sm.byte = 0
   local start_field, end_field = sm.i + 1, 0
   local second, third = sbyte(sm.input, sm.i + 1), sbyte(sm.input, sm.i + 2)
   local quote_count = 0
   sm.multiline_string = false


   if second == chars.SINGLE_QUOTE and third == chars.SINGLE_QUOTE then
      if sm.mode == "table" then _error(sm, "Cannot have multiline strings as table keys", "table") end
      sm.multiline_string = true
      start_field = sm.i + 3

      second, third = sbyte(sm.input, sm.i + 3), sbyte(sm.input, sm.i + 4)
      if second == chars.LF then
         start_field = start_field + 1
      elseif second == chars.CR and third == chars.LF then
         start_field = start_field + 2
      end
      sm.i = start_field
   end

   while end_field ~= 0 or sm.i <= sm.input_length do
      sm.i = sm.i + 1
      sm.byte = sbyte(sm.input, sm.i)
      if sm.multiline_string then
         if sm.byte == chars.SINGLE_QUOTE then
            quote_count = quote_count + 1
            if quote_count == 5 then
               end_field = sm.i - 3
               break
            end
         else
            if quote_count >= 3 then
               end_field = sm.i - 4
               sm.i = sm.i - 1
               break
            else
               quote_count = 0
            end
         end

      else
         if sm.byte == chars.SINGLE_QUOTE then
            end_field = sm.i - 1
            break
         elseif sm.byte == chars.CR or sm.byte == chars.LF then
            _error(sm, "String does not appear to be closed. Use multi-line (triple quoted) strings if non-escaped newlines are desired.", "string")
         end
      end
   end

   if end_field == 0 then
      if sm.multiline_string then
         _error(sm, "Unable to find closing triple quotes for multi-line literal string", "string")
      else
         _error(sm, "Unable to find closing quote for literal string", "string")
      end
   end

   sm.i = sm.i + 1
   sm.value = sm.input:sub(start_field, end_field)
   sm.value_type = "string"
end

local function close_bare_string(sm)
   sm._, sm.end_seq, sm.match = sm.input:find("^([a-zA-Z0-9-_]+)", sm.i)
   if sm.match then
      sm.i = sm.end_seq + 1
      sm.multiline_string = false
      sm.value = sm.match
      sm.value_type = "string"
   else
      _error(sm, "Bare keys can only contain 'a-zA-Z0-9-_'. Invalid bare key found: '" .. sm.input:sub(sm.input:find("[^ #\r\n,]+", sm.i)) .. "'", "keys")
   end
end


local function remove_underscores_number(sm, number, anchor)
   if number:find("_") then
      if number:find("__") then _error(sm, "Numbers cannot have consecutive underscores. Found " .. anchor .. ": '" .. number .. "'", anchor) end
      if number:find("^_") or number:find("_$") then _error(sm, "Underscores are not allowed at beginning or end of a number. Found " .. anchor .. ": '" .. number .. "'", anchor) end
      if number:find("%D_%d") or number:find("%d_%D") then _error(sm, "Underscores must have digits on either side. Found " .. anchor .. ": '" .. number .. "'", anchor) end
      number = number:gsub("_", "")
   end
   return number
end

local integer_match = {
   ["b"] = { "^0b([01_]+)$", 2 },
   ["o"] = { "^0o([0-7_]+)$", 8 },
   ["x"] = { "^0x([0-9a-fA-F_]+)$", 16 },
}

local function validate_integer(sm, value)
   sm._, sm._, sm.match = value:find("^([-+]?[%d_]+)$")
   if sm.match then
      if sm.match:find("^[-+]?0[%d_]") then _error(sm, "Integers can't start with a leading 0. Found integer: '" .. sm.match .. "'", "integer") end
      sm.match = remove_underscores_number(sm, sm.match, "integer")
      sm.value = _tointeger(sm.match)
      sm.value_type = "integer"
      return true
   end

   if value:find("^0[box]") then
      local pattern_bits = integer_match[value:sub(2, 2)]
      sm._, sm._, sm.match = value:find(pattern_bits[1])
      if sm.match then
         sm.match = remove_underscores_number(sm, sm.match, "integer")
         sm.value = tonumber(sm.match, pattern_bits[2])
         sm.value_type = "integer"
         return true
      end
   end
end

local function validate_float(sm, value)
   sm._, sm._, sm.match, sm.ext = value:find("^([-+]?[%d_]+%.[%d_]+)(.*)$")
   if sm.match then
      if sm.match:find("%._") or sm.match:find("_%.") then _error(sm, "Underscores in floats must have a number on either side. Found float: '" .. sm.match .. sm.ext .. "'", "float") end
      if sm.match:find("^[-+]?0[%d_]") then _error(sm, "Floats can't start with a leading 0. Found float: '" .. sm.match .. sm.ext .. "'", "float") end
      sm.match = remove_underscores_number(sm, sm.match, "float")
      if sm.ext ~= "" then
         if sm.ext:find("^[eE][-+]?[%d_]+$") then
            sm.ext = remove_underscores_number(sm, sm.ext, "float")
            sm.value = tonumber(sm.match .. sm.ext)
            sm.value_type = "float"
            return true
         end
      else
         sm.value = tonumber(sm.match)
         sm.value_type = "float"
         return true
      end
   end

   sm._, sm._, sm.match = value:find("^([-+]?[%d_]+[eE][-+]?[%d_]+)$")
   if sm.match then
      if sm.match:find("_[eE]") or sm.match:find("[eE]_") then _error(sm, "Underscores in floats cannot be before or after the e. Found float: '" .. sm.match .. sm.ext .. "'", "float") end
      sm.match = remove_underscores_number(sm, sm.match, "float")
      sm.value = tonumber(sm.match)
      sm.value_type = "float"
      return true
   end
end

local max_days_in_month = { 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
local function validate_seconds(sm, sec, anchor)
   if sec > 60 then _error(sm, "Seconds must be less than 61. Found second: " .. sec .. " in: '" .. sm.match .. "'", anchor) end
end

local function validate_hours_minutes(sm, hour, min, anchor)
   if hour > 23 then _error(sm, "Hours must be less than 24. Found hour: " .. hour .. " in: '" .. sm.match .. "'", anchor) end
   if min > 59 then _error(sm, "Minutes must be less than 60. Found minute: " .. min .. " in: '" .. sm.match .. "'", anchor) end
end

local function validate_month_date(sm, year, month, day, anchor)
   if month == 0 or month > 12 then _error(sm, "Month must be between 01-12. Found month: " .. month .. " in: '" .. sm.match .. "'", anchor) end
   if day == 0 or day > max_days_in_month[month] then
      local months = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }
      _error(sm, "Too many days in the month. Found " .. day .. " days in " .. months[month] .. ", which only has " .. max_days_in_month[month] .. " days in: '" .. sm.match .. "'", anchor)
   end
   if month == 2 then
      local leap_year = (year % 4 == 0) and not (year % 100 == 0) or (year % 400 == 0)
      if leap_year == false then
         if day > 28 then _error(sm, "Too many days in month. Found " .. day .. " days in February, which only has 28 days if it's not a leap year in: '" .. sm.match .. "'", anchor) end
      end
   end
end

local function assign_time_local(sm, match, hour, min, sec, msec)
   sm.value_type = "time-local"
   if sm.options.parse_datetime_as == "string" then
      sm.value = sm.options.type_conversion[sm.value_type](match)
   else
      sm.value = sm.options.type_conversion[sm.value_type]({ hour = hour, min = min, sec = sec, msec = msec })
   end
end

local function assign_date_local(sm, match, year, month, day)
   sm.value_type = "date-local"
   if sm.options.parse_datetime_as == "string" then
      sm.value = sm.options.type_conversion[sm.value_type](match)
   else
      sm.value = sm.options.type_conversion[sm.value_type]({ year = year, month = month, day = day })
   end
end

local function assign_datetime_local(sm, match, year, month, day, hour, min, sec, msec)
   sm.value_type = "datetime-local"
   if sm.options.parse_datetime_as == "string" then
      sm.value = sm.options.type_conversion[sm.value_type](match)
   else
      sm.value = sm.options.type_conversion[sm.value_type]({ year = year, month = month, day = day, hour = hour, min = min, sec = sec, msec = msec or 0 })
   end
end

local function assign_datetime(sm, match, year, month, day, hour, min, sec, msec, tz)
   if tz then
      local hour_s, min_s
      sm._, sm._, hour_s, min_s = tz:find("^[+-](%d%d):(%d%d)$")
      validate_hours_minutes(sm, _tointeger(hour_s), _tointeger(min_s), "offset-date-time")
   end
   sm.value_type = "datetime"
   if sm.options.parse_datetime_as == "string" then
      sm.value = sm.options.type_conversion[sm.value_type](match)
   else
      sm.value = sm.options.type_conversion[sm.value_type]({ year = year, month = month, day = day, hour = hour, min = min, sec = sec, msec = msec or 0, time_offset = tz or "00:00" })
   end
end

local function validate_datetime(sm, value)
   local hour_s, min_s, sec_s, msec_s
   local hour, min, sec
   sm._, sm._, sm.match, hour_s, min_s, sm.ext = value:find("^((%d%d):(%d%d))(.*)$")
   if sm.match then
      hour, min = _tointeger(hour_s), _tointeger(min_s)
      validate_hours_minutes(sm, hour, min, "local-time")

      if sm.ext ~= "" then
         sm._, sm._, sec_s = sm.ext:find("^:(%d%d)$")
         if sec_s then
            sec = _tointeger(sec_s)
            validate_seconds(sm, sec, "local-time")
            assign_time_local(sm, sm.match .. sm.ext, hour, min, sec, 0)
            return true
         end

         sm._, sm._, sec_s, msec_s = sm.ext:find("^:(%d%d)%.(%d+)$")
         if sec_s then
            sec = _tointeger(sec_s)
            validate_seconds(sm, sec, "local-time")
            assign_time_local(sm, sm.match .. sm.ext, hour, min, sec, _tointeger(msec_s))
            return true
         end
      else
         assign_time_local(sm, sm.match .. ":00", hour, min, 0, 0)
         return true
      end
   end

   local year_s, month_s, day_s
   local year, month, day
   sm._, sm._, sm.match, year_s, month_s, day_s = value:find("^((%d%d%d%d)%-(%d%d)%-(%d%d))$")
   if sm.match then
      year, month, day = _tointeger(year_s), _tointeger(month_s), _tointeger(day_s)
      validate_month_date(sm, year, month, day, "local-date")
      assign_date_local(sm, sm.match, year, month, day)



      local potential_end_seq



      if sm.input:find("^ %d", sm.i) then
         sm._, potential_end_seq, sm.match = sm.input:find("^ ([%S]+)", sm.i)
         value = value .. " " .. sm.match
         sm.end_seq = potential_end_seq
         sm.i = sm.end_seq + 1
      else
         return true
      end
   end

   sm._, sm._, sm.match, year_s, month_s, day_s, hour_s, min_s, sm.ext =
   value:find("^((%d%d%d%d)%-(%d%d)%-(%d%d)[Tt ](%d%d):(%d%d))(.*)$")

   if sm.match then
      hour, min = _tointeger(hour_s), _tointeger(min_s)
      validate_hours_minutes(sm, hour, min, "local-time")
      year, month, day = _tointeger(year_s), _tointeger(month_s), _tointeger(day_s)
      validate_month_date(sm, year, month, day, "local-date-time")


      local temp_ext
      sm._, sm._, sec_s, temp_ext = sm.ext:find("^:(%d%d)(.*)$")
      if sec_s then
         sec = _tointeger(sec_s)
         validate_seconds(sm, sec, "local-time")
         sm.match = sm.match .. ":" .. sec_s
         sm.ext = temp_ext
      else
         sm.match = sm.match .. ":00"
      end


      if sm.ext ~= "" then
         sm.match = sm.match .. sm.ext
         if sm.ext:find("^%.%d+$") then
            sm._, sm._, msec_s = sm.ext:find("^%.(%d+)Z$")
            assign_datetime_local(sm, sm.match, year, month, day, hour, min, sec, _tointeger(msec_s))
            return true
         elseif sm.ext:find("^%.%d+Z$") then
            sm._, sm._, msec_s = sm.ext:find("^%.(%d+)Z$")
            assign_datetime(sm, sm.match, year, month, day, hour, min, sec, _tointeger(msec_s))
            return true
         elseif sm.ext:find("^%.%d+[+-]%d%d:%d%d$") then
            local tz_s
            sm._, sm._, msec_s, tz_s = sm.ext:find("^%.(%d+)([+-]%d%d:%d%d)$")
            assign_datetime(sm, sm.match, year, month, day, hour, min, sec, _tointeger(msec_s), tz_s)
            return true
         elseif sm.ext:find("^[Zz]$") then
            assign_datetime(sm, sm.match, year, month, day, hour, min, sec)
            return true
         elseif sm.ext:find("^[+-]%d%d:%d%d$") then
            local tz_s
            sm._, sm._, tz_s = sm.ext:find("^([+-]%d%d:%d%d)$")
            assign_datetime(sm, sm.match, year, month, day, hour, min, sec, 0, tz_s)
            return true
         end
      else
         assign_datetime_local(sm, sm.match, year, month, day, hour, min, sec)
         return true
      end
   end
end

local validators = {
   validate_integer,
   validate_float,
   validate_datetime,
}

local exact_matches = {
   ["true"] = { true, "bool" },
   ["false"] = { false, "bool" },
   ["+inf"] = { math.huge, "float" },
   ["inf"] = { math.huge, "float" },
   ["-inf"] = { -math.huge, "float" },
   ["+nan"] = { (0 / 0), "float" },
   ["nan"] = { (0 / 0), "float" },
   ["-nan"] = { (-(0 / 0)), "float" },
}

local function close_other_value(sm)
   local successful_type
   sm._, sm.end_seq, sm.match = sm.input:find("^([^ #\r\n,%[{%]}]+)", sm.i)
   if sm.match == nil then
      _error(sm, "Key has been assigned, but value doesn't seem to exist", "keyvalue-pair")
   end
   sm.i = sm.end_seq + 1

   local value = sm.match
   local exact_value = exact_matches[value]
   if exact_value ~= nil then
      sm.value = exact_value[1]
      sm.value_type = exact_value[2]
      return
   end

   for _, validator in ipairs(validators) do
      successful_type = validator(sm, value)
      if successful_type == true then
         return
      end
   end

   _error(sm, "Unable to determine type of value for: '" .. value .. "'", "keyvalue-pair")
end

local function create_array(sm)
   sm.nested_arrays = sm.nested_arrays + 1
   if sm.nested_arrays >= sm.options.max_nesting_depth then
      _error(sm, "Maximum nesting depth has exceeded " .. sm.options.max_nesting_depth .. ". If this larger nesting depth is required, feel free to set 'max_nesting_depth' in the parser options.")
   end
   sm.arrays[sm.nested_arrays] = {}
   sm.i = sm.i + 1
end

local function add_array_comma(sm)
   table.insert(sm.arrays[sm.nested_arrays], sm.value)
   sm.value = nil

   sm.i = sm.i + 1
end

local function close_array(sm)

   if sm.value ~= nil then
      add_array_comma(sm)
   else
      sm.i = sm.i + 1
   end
   sm.value = sm.arrays[sm.nested_arrays]
   sm.value_type = "array"
   sm.nested_arrays = sm.nested_arrays - 1
   if sm.nested_arrays == 0 then
      return "assign"
   else
      return "inside_array"
   end
end

local function create_table(sm)
   sm.tables = {}
   sm.byte = sbyte(sm.input, sm.i + 1)

   if sm.byte == chars.OPEN_BRACKET then
      sm.i = sm.i + 2
      sm.table_type = "arrays_of_tables"
   else
      sm.i = sm.i + 1
      sm.table_type = "table"
   end
end

local function add_table_dot(sm)
   sm.tables[#sm.tables + 1] = sm.value
   sm.i = sm.i + 1
end

local function close_table(sm)
   sm.byte = sbyte(sm.input, sm.i + 1)

   if sm.table_type == "arrays_of_tables" and sm.byte ~= chars.CLOSE_BRACKET then
      _error(sm, "Arrays of Tables should be closed with ']]'", "array-of-tables")
   end

   if sm.byte == chars.CLOSE_BRACKET then
      sm.i = sm.i + 2
   else
      sm.i = sm.i + 1
   end

   sm.tables[#sm.tables + 1] = sm.value

   local out_table = sm.output
   local meta_out_table = sm.meta_table

   for i = 1, #sm.tables - 1 do
      if out_table[sm.tables[i]] == nil then

         out_table[sm.tables[i]] = {}
         out_table = out_table[sm.tables[i]]

         meta_out_table[sm.tables[i]] = { type = "auto-dictionary" }
         meta_out_table = meta_out_table[sm.tables[i]]
      else
         if (meta_out_table[sm.tables[i]]).type == "value" then
            _error(sm, "Cannot override previously definied value '" .. sm.tables[i] .. "' with new table definition: '" .. table.concat(sm.tables, ".") .. "'")
         end

         local next_table = out_table[sm.tables[i]][#out_table[sm.tables[i]]]
         local next_meta_table = meta_out_table[sm.tables[i]][#meta_out_table[sm.tables[i]]]

         if next_table == nil then
            out_table = out_table[sm.tables[i]]
            meta_out_table = meta_out_table[sm.tables[i]]
         else
            out_table = next_table
            meta_out_table = next_meta_table
         end
      end
   end
   local final_table = sm.tables[#sm.tables]

   if sm.table_type == "table" then
      if out_table[final_table] == nil then
         out_table[final_table] = {}
         meta_out_table[final_table] = { type = "dictionary" }
      elseif (meta_out_table[final_table]).type == "value" then
         _error(sm, "Cannot override existing value '" .. sm.value .. "' with new table")
      elseif (meta_out_table[final_table]).type == "dictionary" then
         _error(sm, "Cannot override existing table '" .. sm.value .. "' with new table")
      elseif (meta_out_table[final_table]).type == "array" then
         _error(sm, "Cannot override existing array '" .. sm.value .. "' with new table")
      elseif (meta_out_table[final_table]).type == "value-dictionary" then
         _error(sm, "Cannot override existing value '" .. sm.value .. "' with new table")
      end
      (meta_out_table[final_table]).type = "dictionary"
      sm.current_table = out_table[final_table]
      sm.current_meta_table = meta_out_table[final_table]

   elseif sm.table_type == "arrays_of_tables" then
      if out_table[final_table] == nil then
         out_table[final_table] = {}
         meta_out_table[final_table] = { type = "array" }
      elseif (meta_out_table[final_table]).type == "value" then
         _error(sm, "Cannot override existing value '" .. sm.value .. "' with new table")
      elseif (meta_out_table[final_table]).type == "dictionary" then
         _error(sm, "Cannot override existing table '" .. sm.value .. "' with new table")
      elseif (meta_out_table[final_table]).type == "auto-dictionary" then
         _error(sm, "Cannot override existing table '" .. sm.value .. "' with new table")
      elseif (meta_out_table[final_table]).type == "value-dictionary" then
         _error(sm, "Cannot override existing value '" .. sm.value .. "' with new table")
      end
      table.insert(out_table[final_table], {})
      table.insert(meta_out_table[final_table], { type = "dictionary" })
      sm.current_table = out_table[final_table][#out_table[final_table]]
      sm.current_meta_table = meta_out_table[final_table][#meta_out_table[final_table]]
   end

end

local function assign_key(sm)
   if sm.multiline_string == false then
      sm.keys[#sm.keys + 1] = sm.value
   else
      _error(sm, "Cannot have multi-line string as keys. Found key: '" .. tostring(sm.value) .. "'", "keys")
   end


   sm.value = nil
   sm.value_type = nil

   sm.i = sm.i + 1
end

local function assign_value(sm)
   local output = {}
   output = sm.value


   local out_table = sm.current_table
   local meta_out_table = sm.current_meta_table
   for i = 1, #sm.keys - 1 do
      if out_table[sm.keys[i]] == nil then
         out_table[sm.keys[i]] = {}
         meta_out_table[sm.keys[i]] = { type = "value-dictionary" }
      elseif (meta_out_table[sm.keys[i]]).type == "value" then
         _error(sm, "Cannot override existing value '" .. sm.keys[i] .. "' in '" .. table.concat(sm.keys, ".") .. "'")
      elseif (meta_out_table[sm.keys[i]]).type == "dictionary" then
         _error(sm, "Cannot override existing table '" .. sm.keys[i] .. "' in '" .. table.concat(sm.keys, ".") .. "'")
      elseif (meta_out_table[sm.keys[i]]).type == "array" then
         _error(sm, "Cannot override existing array '" .. sm.keys[i] .. "' in '" .. table.concat(sm.keys, ".") .. "'")
      end
      out_table = out_table[sm.keys[i]]
      meta_out_table = meta_out_table[sm.keys[i]]
   end


   local last_table = sm.keys[#sm.keys]

   if out_table[last_table] ~= nil then
      _error(sm, "Cannot override previously defined key '" .. sm.keys[#sm.keys] .. "'")
   end

   out_table[last_table] = output
   meta_out_table[last_table] = { type = "value" }

   sm.keys = {}
   sm.value = nil
end

local function error_invalid_state(sm)
   local error_message = "Incorrectly formatted TOML. "
   local found = sm.input:sub(sm.i, sm.i); if found == "\r" or found == "\n" then found = "newline character" end
   if sm.mode == "start_of_line" then error_message = error_message .. "At start of line, could not find a key. Found '='"
   elseif sm.mode == "inside_table" then error_message = error_message .. "In a table definition, expected a '.' or ']'. Found: '" .. found .. "'"
   elseif sm.mode == "inside_key" then error_message = error_message .. "In a key defintion, expected a '.' or '='. Found: '" .. found .. "'"
   elseif sm.mode == "value" then error_message = error_message .. "Unspecified value, key was specified, but no value provided."
   elseif sm.mode == "inside_array" then error_message = error_message .. "Inside an array, expected a ']', '}' (if inside inline table), ',', newline, or comment. Found: " .. found
   elseif sm.mode == "wait_for_newline" then error_message = error_message .. "Just assigned value or created table. Expected newline or comment before continuing."
   end
   _error(sm, error_message)
end

local function create_inline_table(sm)
   sm.nested_inline_tables = sm.nested_inline_tables + 1

   if sm.nested_inline_tables >= sm.options.max_nesting_depth then
      _error(sm, "Maximum nesting depth has exceeded " .. sm.options.max_nesting_depth .. ". If this larger nesting depth is required, feel free to set 'max_nesting_depth' in the parser options.")
   end

   local backup = {
      previous_state = sm.mode,
      meta_table = sm.meta_table,
      current_table = sm.current_table,
      keys = { _unpack(sm.keys) },
   }

   local new_inline_table = {}
   sm.current_table = new_inline_table

   sm.inline_table_backup[sm.nested_inline_tables] = backup

   sm.current_table = {}
   sm.meta_table = {}
   sm.keys = {}

   sm.i = sm.i + 1
end

local function close_inline_table(sm)
   if sm.value ~= nil then
      assign_value(sm)
   end
   sm.i = sm.i + 1
   sm.value = sm.current_table
   sm.value_type = "inline-table"

   local restore = sm.inline_table_backup[sm.nested_inline_tables]
   sm.keys = restore.keys
   sm.meta_table = restore.meta_table
   sm.current_table = restore.current_table

   sm.nested_inline_tables = sm.nested_inline_tables - 1

   if restore.previous_state == "array" then
      return "inside_array"
   elseif restore.previous_state == "value" then
      return "assign"
   else
      _error(sm, "close_inline_table should not be called from the previous state: " .. restore.previous_state .. ". Please submit an issue with your TOML file so we can look into the issue!")
   end
end

local function skip_comma(sm)
   sm.i = sm.i + 1
end

local transitions = {
   ["start_of_line"] = {
      [sbyte("#")] = { find_newline, "start_of_line" },
      [sbyte("\r")] = { find_newline, "start_of_line" },
      [sbyte("\n")] = { find_newline, "start_of_line" },
      [sbyte('"')] = { close_string, "inside_key" },
      [sbyte("'")] = { close_literal_string, "inside_key" },
      [sbyte("[")] = { create_table, "table" },
      [sbyte("=")] = { error_invalid_state, "error" },
      [sbyte("}")] = { close_inline_table, "?" },
      [0] = { close_bare_string, "inside_key" },
   },
   ["table"] = {
      [sbyte('"')] = { close_string, "inside_table" },
      [sbyte("'")] = { close_literal_string, "inside_table" },
      [0] = { close_bare_string, "inside_table" },
   },
   ["inside_table"] = {
      [sbyte(".")] = { add_table_dot, "table" },
      [sbyte("]")] = { close_table, "wait_for_newline" },
      [0] = { error_invalid_state, "error" },
   },
   ["key"] = {
      [sbyte('"')] = { close_string, "inside_key" },
      [sbyte("'")] = { close_literal_string, "inside_key" },
      [sbyte("}")] = { close_inline_table, "?" },
      [sbyte("\r")] = { find_newline, "key" },
      [sbyte("\n")] = { find_newline, "key" },
      [sbyte("#")] = { find_newline, "key" },
      [0] = { close_bare_string, "inside_key" },
   },
   ["inside_key"] = {
      [sbyte(".")] = { assign_key, "key" },
      [sbyte("=")] = { assign_key, "value" },
      [0] = { error_invalid_state, "error" },
   },
   ["value"] = {
      [sbyte("'")] = { close_literal_string, "assign" },
      [sbyte('"')] = { close_string, "assign" },
      [sbyte("{")] = { create_inline_table, "key" },
      [sbyte("[")] = { create_array, "array" },
      [sbyte("\n")] = { error_invalid_state, "error" },
      [sbyte("\r")] = { error_invalid_state, "error" },
      [0] = { close_other_value, "assign" },
   },
   ["array"] = {
      [sbyte("'")] = { close_literal_string, "inside_array" },
      [sbyte('"')] = { close_string, "inside_array" },
      [sbyte("[")] = { create_array, "array" },
      [sbyte("]")] = { close_array, "?" },
      [sbyte("#")] = { find_newline, "array" },
      [sbyte("\r")] = { find_newline, "array" },
      [sbyte("\n")] = { find_newline, "array" },
      [sbyte("{")] = { create_inline_table, "key" },
      [0] = { close_other_value, "inside_array" },
   },
   ["inside_array"] = {
      [sbyte(",")] = { add_array_comma, "array" },
      [sbyte("]")] = { close_array, "?" },
      [sbyte("}")] = { close_inline_table, "?" },
      [sbyte("#")] = { find_newline, "inside_array" },
      [sbyte("\r")] = { find_newline, "inside_array" },
      [sbyte("\n")] = { find_newline, "inside_array" },
      [0] = { error_invalid_state, "error" },
   },
   ["assign"] = {
      [sbyte(",")] = { assign_value, "wait_for_key" },
      [sbyte("}")] = { close_inline_table, "?" },
      [0] = { assign_value, "wait_for_newline" },
   },
   ["wait_for_key"] = {
      [sbyte(",")] = { skip_comma, "key" },
   },
   ["wait_for_newline"] = {
      [sbyte("#")] = { find_newline, "start_of_line" },
      [sbyte("\r")] = { find_newline, "start_of_line" },
      [sbyte("\n")] = { find_newline, "start_of_line" },
      [0] = { error_invalid_state, "error" },
   },
}

local function generic_type_conversion(raw_value) return raw_value end

function tinytoml.parse(filename, options)
   local sm = {}

   local default_options = {
      max_nesting_depth = 1000,
      max_filesize = 100000000,
      load_from_string = false,
      parse_datetime_as = "string",
      type_conversion = {
         ["datetime"] = generic_type_conversion,
         ["datetime-local"] = generic_type_conversion,
         ["date-local"] = generic_type_conversion,
         ["time-local"] = generic_type_conversion,
      },
   }

   if options then

      if options.max_nesting_depth ~= nil then
         assert(type(options.max_nesting_depth) == "number", "the tinytoml option 'max_nesting_depth' takes in a 'number'. You passed in the value '" .. tostring(options.max_nesting_depth) .. "' of type '" .. type(options.max_nesting_depth) .. "'")
      end

      if options.max_filesize ~= nil then
         assert(type(options.max_filesize) == "number", "the tinytoml option 'max_filesize' takes in a 'number'. You passed in the value '" .. tostring(options.max_filesize) .. "' of type '" .. type(options.max_filesize) .. "'")
      end

      if options.load_from_string ~= nil then
         assert(type(options.load_from_string) == "boolean", "the tinytoml option 'load_from_string' takes in a 'function'. You passed in the value '" .. tostring(options.load_from_string) .. "' of type '" .. type(options.load_from_string) .. "'")
      end

      if options.parse_datetime_as ~= nil then
         assert(type(options.parse_datetime_as) == "string", "the tinytoml option 'parse_datetime_as' takes in either the 'string' or 'table' (as type 'string'). You passed in the value '" .. tostring(options.parse_datetime_as) .. "' of type '" .. type(options.parse_datetime_as) .. "'")
      end

      if options.type_conversion ~= nil then
         assert(type(options.type_conversion) == "table", "the tinytoml option 'type_conversion' takes in a 'table'. You passed in the value '" .. tostring(options.type_conversion) .. "' of type '" .. type(options.type_conversion) .. "'")
         for key, value in pairs(options.type_conversion) do
            assert(type(key) == "string")
            if not default_options.type_conversion[key] then
               error("")
            end
            assert(type(value) == "function")
         end
      end


      options.max_nesting_depth = options.max_nesting_depth or default_options.max_nesting_depth
      options.max_filesize = options.max_filesize or default_options.max_filesize
      options.load_from_string = options.load_from_string or default_options.load_from_string
      options.parse_datetime_as = options.parse_datetime_as or default_options.parse_datetime_as
      options.type_conversion = options.type_conversion or default_options.type_conversion


      if options.load_from_string == true then
         sm.input = filename
         sm.filename = "string input"
      end


      for key, value in pairs(default_options.type_conversion) do
         if options.type_conversion[key] == nil then
            options.type_conversion[key] = value
         end
      end

   else
      options = default_options
   end


   sm.options = options

   if options.load_from_string == false then
      local file = io.open(filename, "r")
      if not file then error("Unable to open file: '" .. filename .. "'") end
      if file:seek("end") > options.max_filesize then error("Filesize is larger than 100MB. If this is intentional, please set the 'max_filesize' (in bytes) in options") end
      file:seek("set")
      sm.input = file:read("*all")
      file:close()
      sm.filename = filename
   end

   sm.i = 1
   sm.keys = {}
   sm.arrays = {}
   sm.output = {}
   sm.meta_table = {}
   sm.line_number = 1
   sm.line_number_char_index = 1
   sm.nested_arrays = 0
   sm.inline_table_backup = {}
   sm.nested_inline_tables = 0
   sm.table_type = "table"
   sm.input_length = #sm.input
   sm.current_table = sm.output
   sm.current_meta_table = sm.meta_table


   if sm.input_length == 0 then return {} end

   local valid, line_number, line_number_start, message = validate_utf8(sm.input, true)
   if not valid then
      sm.line_number = line_number
      sm.line_number_char_index = line_number_start
      _error(sm, message, "preliminaries")
   end

   sm.mode = "start_of_line"
   local dynamic_next_mode = "start_of_line"
   local transition = nil
   sm._, sm.i = sm.input:find("[^ \t]", sm.i)


   if not sm.i then return {} end

   while sm.i <= sm.input_length do
      sm.byte = sbyte(sm.input, sm.i)

      transition = transitions[sm.mode][sm.byte]
      if transition == nil then
         transition = transitions[sm.mode][0]
      end

      if transition[2] == "?" then
         dynamic_next_mode = transition[1](sm)
         sm.mode = dynamic_next_mode
      else
         transition[1](sm)
         sm.mode = transition[2]
      end

      sm._, sm.i = sm.input:find("[^ \t]", sm.i)
      if sm.i == nil then
         break
      end
   end

   if sm.mode == "assign" then

      sm.i = sm.input_length
      assign_value(sm)
   end
   if sm.mode == "inside_array" or sm.mode == "array" then
      _error(sm, "Unable to find closing bracket of array", "array")
   end
   if sm.mode == "key" then
      _error(sm, "Incorrect formatting for key", "keys")
   end
   if sm.mode == "value" then
      _error(sm, "Key has been assigned, but value doesn't seem to exist", "keyvalue-pair")
   end
   if sm.nested_inline_tables ~= 0 then
      _error(sm, "Unable to find closing bracket of inline table", "inline-table")
   end

   return sm.output
end







local function is_array(input_table)
   local count = #(input_table)
   return count > 0 and next(input_table, count) == nil
end

local short_sequences = {
   [sbyte('\b')] = '\\b',
   [sbyte('\t')] = '\\t',
   [sbyte('\n')] = '\\n',
   [sbyte('\f')] = '\\f',
   [sbyte('\r')] = '\\r',
   [sbyte('\t')] = '\\t',
   [sbyte('\\')] = '\\\\',
   [sbyte('"')] = '\\"',
}

local function escape_string(str, multiline, is_key)


   if not is_key and #str >= 5 and str:find("%d%d") then




      local sm = { input = str, i = 1, line_number = 1, line_number_char_index = 1 }
      sm.options = {}
      sm.options.type_conversion = {
         ["datetime"] = generic_type_conversion,
         ["datetime-local"] = generic_type_conversion,
         ["date-local"] = generic_type_conversion,
         ["time-local"] = generic_type_conversion,
      }
      sm.options.parse_datetime_as = "string"


      sm._, sm.end_seq, sm.match = sm.input:find("^([^ #\r\n,%[{%]}]+)", sm.i)
      sm.i = sm.end_seq + 1

      if validate_datetime(sm, sm.match) then
         if sm.value_type == "datetime" or sm.value_type == "datetime-local" or
            sm.value_type == "date-local" or sm.value_type == "time-local" then
            return sm.value
         end
      end
   end

   local byte
   local found_newline = false
   local final_string = string.gsub(str, '[%z\001-\031\127\\"]', function(c)
      byte = sbyte(c)
      if short_sequences[byte] then
         if multiline and (byte == chars.CR or byte == chars.LF) then
            found_newline = true
            return c
         else
            return short_sequences[byte]
         end
      else
         return string.format("\\x%02x", byte)
      end
   end)
   if found_newline then
      final_string = '"""' .. final_string .. '"""'
   else
      final_string = '"' .. final_string .. '"'
   end

   if not validate_utf8(final_string, true) then
      error("String is not valid UTF-8, cannot encode to TOML")
   end
   return final_string

end

local function escape_key(str)
   if str:find("^[A-Za-z0-9_-]+$") then
      return str
   else
      return escape_string(str, false, true)
   end
end

local to_inf_and_beyound = {
   ["inf"] = true,
   ["-inf"] = true,
   ["nan"] = true,
   ["-nan"] = true,
}


local function float_to_string(x)


   if to_inf_and_beyound[tostring(x)] then
      return tostring(x)
   end
   for precision = 15, 17 do

      local s = ('%%.%dg'):format(precision):format(x)

      if tonumber(s) == x then
         return s
      end
   end

   return tostring(x)
end

local function encode_element(element, allow_multiline_strings)
   if type(element) == "table" then
      local encoded_string = {}
      if is_array(element) then
         table.insert(encoded_string, "[")

         local remove_trailing_comma = false
         for _, array_element in ipairs(element) do
            remove_trailing_comma = true
            table.insert(encoded_string, encode_element(array_element, allow_multiline_strings))
            table.insert(encoded_string, ", ")
         end
         if remove_trailing_comma then table.remove(encoded_string) end

         table.insert(encoded_string, "]")

         return table.concat(encoded_string)

      else
         table.insert(encoded_string, "{")

         local remove_trailing_comma = false
         for k, v in pairs(element) do
            remove_trailing_comma = true
            table.insert(encoded_string, k)
            table.insert(encoded_string, " = ")
            table.insert(encoded_string, encode_element(v, allow_multiline_strings))
            table.insert(encoded_string, ", ")
         end
         if remove_trailing_comma then table.remove(encoded_string) end

         table.insert(encoded_string, "}")

         return table.concat(encoded_string)

      end

   elseif type(element) == "string" then
      return escape_string(element, allow_multiline_strings, false)

   elseif type(element) == "number" then
      return float_to_string(element)

   elseif type(element) == "boolean" then
      return tostring(element)

   else
      error("Unable to encode type '" .. type(element) .. "' into a TOML type")
   end
end

local function encode_depth(encoded_string, depth)
   table.insert(encoded_string, '\n[')
   table.insert(encoded_string, table.concat(depth, '.'))
   table.insert(encoded_string, ']\n')
end

local function encoder(input_table, encoded_string, depth, options)
   local printed_table_info = false
   for k, v in pairs(input_table) do
      if type(v) ~= "table" or (type(v) == "table" and is_array(v)) then
         if not printed_table_info and #depth > 0 then
            encode_depth(encoded_string, depth)
            printed_table_info = true
         end
         table.insert(encoded_string, escape_key(k))
         table.insert(encoded_string, " = ")
         local status, error_or_encoded_element = pcall(encode_element, v, options.allow_multiline_strings)
         if not status then
            local error_message = { "\n\nWhile encoding '" }
            local _
            if #depth > 0 then
               error_message[#error_message + 1] = table.concat(depth, ".")
               error_message[#error_message + 1] = "."
            end
            error_message[#error_message + 1] = escape_key(k)
            error_message[#error_message + 1] = "', received the following error message:\n\n"
            _, _, error_or_encoded_element = error_or_encoded_element:find(".-:.-: (.*)")
            error_message[#error_message + 1] = error_or_encoded_element
            error(table.concat(error_message))
         end
         table.insert(encoded_string, error_or_encoded_element)
         table.insert(encoded_string, "\n")
      end
   end
   for k, v in pairs(input_table) do
      if type(v) == "table" and not is_array(v) then
         if next(v) == nil then
            table.insert(depth, escape_key(k))
            encode_depth(encoded_string, depth)
            table.remove(depth)


         else
            table.insert(depth, escape_key(k))
            encoder(v, encoded_string, depth, options)
            table.remove(depth)
         end
      end
   end
   return encoded_string
end

function tinytoml.encode(input_table, options)
   options = options or {
      allow_multiline_strings = false,
   }
   return table.concat(encoder(input_table, {}, {}, options))
end

return tinytoml
