fx_version 'cerulean'
lua54 'yes'

game 'gta5'
author 'Coffeelot'
description 'Manual gearing by Coffeelot'

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua', -- comment/remove this line if you dont use oxlib
}

client_scripts{
    'client.lua',
}

server_scripts{
    'server.lua',
}

dependency{
    'oxmysql',
}
