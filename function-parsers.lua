M = {}

---returns a line iterator that starts when function opens and stores a "finish" boolean that is true until function closes.
---@param function_name string
---@return fun(line: string): boolean
local function functionIsOpen(function_name)

    local open_brackets_count = 0

    local start, init, finish = false, false, false

    return function(line)
        if finish then return false end
        if not start and line:match(function_name) then
            start = true
        end
        if not start then return false end
        if line:match('{') then
            init = true
            open_brackets_count = open_brackets_count + 1
        end
        if line:match('}') then
            open_brackets_count = open_brackets_count - 1
        end
        if init and open_brackets_count == 0 then
            finish = true
            return false
        end
        return true
    end
end

---Each call of the generator will store the function name in a table that maps function names to orderings. The function parsed lines are those where the defined functions are called. A table that maps function names to the order in which they are called is returned.
---@return fun(line: string):table<string, integer>
local function storeFunctionOrdering()
    local ordering = {}
    local n = 0

    local openFunctionScanner = functionIsOpen('function build%s*()')
    local reading_build_function = false

    return function(line)

        reading_build_function = openFunctionScanner(line)

        if not reading_build_function then
            return ordering
        end

        local match = line:match('$this%->%w*')
        if match then
            n = n + 1
            ordering[match:match('%w*$')] = n
        end
        return ordering
    end
end

---Use for getting a table with as many entries as functions are in the class.
---@return fun(line: string, file_lines_position: integer):table<string, {lines: string[], start: integer, length: integer}>
local function storeFunctionBodies()
    local currently_reading_function = ""
    local currentFunctionScanner = nil
    local function_bodies = {}

    return function(line, file_lines_position)
        local match = string.match(line, 'private function [^()]*()')
        if match then
            currently_reading_function = line:sub(1, match - 1):match('%w*$')
            currentFunctionScanner = functionIsOpen('function ' .. currently_reading_function .. '%s*()')
            function_bodies[currently_reading_function] = {
                lines = {},
                start = file_lines_position,
                length = 0
            }
        end
        if string.len(currently_reading_function) ~= 0 then
            local reading_current_function_is_open = currentFunctionScanner(line)
            if reading_current_function_is_open then
                table.insert(function_bodies[currently_reading_function].lines, line)
                function_bodies[currently_reading_function].length = function_bodies[currently_reading_function].length + 1
            end
        end
        return function_bodies
    end
end

M.functionIsOpen = functionIsOpen
M.storeFunctionOrdering = storeFunctionOrdering
M.storeFunctionBodies = storeFunctionBodies

return M
