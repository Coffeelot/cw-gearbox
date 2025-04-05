RegisterNetEvent('cw-gearbox:server:setGear', function(vehicleNetworkId, gear)
    local networkEntity = NetworkGetEntityFromNetworkId(vehicleNetworkId)
    Entity(networkEntity).state.gearchange = gear
end)