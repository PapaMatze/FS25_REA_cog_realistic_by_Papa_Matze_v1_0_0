-- REAcog wrapper to load patched file
if g_currentModDirectory ~= nil then
	dofile(g_currentModDirectory .. "REAcog_patched.lua")
else
	dofile("REAcog_patched.lua")
end
