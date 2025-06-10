fx_version 'cerulean'
games { 'gta5' }
author 'Lofi'
description 'Jungle RZ'
version '2.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/api.lua'
}

client_scripts {
    'client/framework.lua',
    'client/client.lua',
}

server_scripts {
    'server/server.lua',
    'server/framework.lua',
    'server/version.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/main.js',
    'html/styles.css'
}
