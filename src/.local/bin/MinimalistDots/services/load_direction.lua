-- Cargamos la dirrecion donde estan los archivos que tienen "lib" y "services"
local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/.config/hypr/?.lua"
