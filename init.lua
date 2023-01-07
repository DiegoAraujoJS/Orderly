local parsers = require("function-parsers")

local function orderClassFunctionsByCallOrder(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    local file_lines = {}
    local orderStorer = parsers.storeFunctionOrdering()
    local ordering = {}

    local functionBodiesStorer = parsers.storeFunctionBodies()
    local function_bodies = {}

    local lines = file:lines()
    for l in lines do
        table.insert(file_lines, l)

        ordering = orderStorer(l)
        function_bodies = functionBodiesStorer(l, #file_lines)

    end
    io.close(file)
    return file_lines, function_bodies, ordering
end

---@param file_lines string[]
---@param function_bodies table<string, {lines: string[], start: integer, length: integer}>
---@param ordering table<string, integer>
---@return string
local function reArrangeWithSortedFunctionBodies(file_lines, function_bodies, ordering)
    local first_function_first_line, last_function_last_line = #file_lines, -1

    for _, v in pairs(function_bodies) do
        if v.start + v.length > last_function_last_line then last_function_last_line = v.start + v.length end
        if v.start < first_function_first_line then first_function_first_line = v.start end
    end

    local result = ""
    for k, v in pairs(file_lines) do
        if k == first_function_first_line - 1 then
            result = result .. v
            break
        end
        result = result .. v .. "\n"
    end
    result = result .. "\n"

    local sorted_functions = {}
    for k, _ in pairs(function_bodies) do
        table.insert(sorted_functions, k)
    end
    table.sort(sorted_functions, function(a, b)
        return ordering[a] < ordering[b]
    end)

    for _, v in pairs(sorted_functions) do
        for _, s in pairs(function_bodies[v].lines) do
            result = result .. s .. "\n"
        end
        result = result .. "}\n\n"
    end

    while file_lines[last_function_last_line + 1] ~= nil do
        result = result .. file_lines[last_function_last_line] .. "\n"
        last_function_last_line = last_function_last_line + 1
    end
    return result
end

local function writeNewOrderedFile(path, target)
    local result = reArrangeWithSortedFunctionBodies(orderClassFunctionsByCallOrder(path))
    local file = io.open(target, "w")
    if file == nil then
        return nil
    end
    file:write(result)
    file:close()
end

writeNewOrderedFile("RebuildExercise2.php", "RebuildOrdered2.php")
