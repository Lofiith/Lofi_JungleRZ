fx_version 'cerulean'
game 'gta5'

author 'Lofi'
description 'Jungle RZ'
version '1.0.1'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    "framework/esx/client.lua",
    "framework/qbcore/client.lua",
    "framework/ox/client.lua", 
    'client/client.lua'
}

server_scripts {
    "framework/esx/server.lua",
    "framework/qbcore/server.lua",
    "framework/ox/server.lua",
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/main.js',
    'html/styles.css'
}
