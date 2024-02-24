fx_version 'cerulean'
lua54 'yes'

game 'gta5'
author 'Coffeelot'
description 'Manual gearing'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua',
    '@ox_lib/init.lua',
}

client_scripts{
    'client/*.lua',
}

server_scripts{
}

dependency{
    'oxmysql',
}

exports {
}