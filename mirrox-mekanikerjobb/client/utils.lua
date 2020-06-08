function Draw3DText(x, y, z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
 
    local scale = (1/dist)*1
    local fov = (1/GetGameplayCamFov())*100
    local scale = 1.9
   
    if onScreen then
        SetTextScale(0.0*scale, 0.18*scale)
        SetTextFont(4)
        SetTextProportional(1)
        -- SetTextScale(0.0, 0.55)
        SetTextColour(0, 0, 0, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
	local factor = (string.len(text)) / 600
    DrawRect(_x,_y+0.0115, 0.01+ factor, 0.025, 41, 11, 41, 68)
    
    end
end

function Marker(hint, type, x, y, z)
   --ESX.Game.Utils.DrawText3D({x = x, y = y, z = z + 1.0}, hint, 0.4)
    Draw3DText(x, y, z + 1.0, hint)
	--DrawMarker(type, x, y, z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.5, 1.5, 1.0, 64, 224, 208, 225, false, true, 2, true, false, false, false)
    DrawMarker(6, x, y, z, 0, 0, 0, -1, 0, 0, 1.5, 1.5, 1.5, 0, 119, 119, 50, 0, 0, 0, 0)
end

