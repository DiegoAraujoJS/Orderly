local M = {}

---@param body string The content of the new file.
---@param target string The name of the new file.
---@return nil
M.writeFile = function(body, target)
    local file = io.open(target, "w")
    if file == nil then
        return nil
    end
    file:write(body)
    file:close()
end

return M
