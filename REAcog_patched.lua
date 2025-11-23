-- REAcog_patched.lua
-- Lightweight wrapper for FS25 to avoid missing resource errors.
-- Original logic is contained in REAcog.lua (converted from REA_cog_realistic.lua).

-- In FS25, this file is only kept for compatibility. It can safely be empty or forward to REAcog.
if REAcog == nil and REAcogInit ~= nil then
    -- optional init hook if original script defines something like this
    pcall(function() REAcogInit() end)
end
