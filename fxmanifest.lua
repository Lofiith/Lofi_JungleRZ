fx_version 'cerulean'
game 'gta5'

author 'Lofi'
description 'Advanced Jungle RZ'
version '1.0.1'
lua54 'yes'

shared_script 'config.lua'

client_scripts {
    'framework/esx/client.lua',
    'framework/qbcore/client.lua',
    'client/client.lua',
    'client/open.lua',
}

server_scripts {
    'framework/esx/server.lua',
    'framework/qbcore/server.lua',
    'server/server.lua',
    'server/open.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/styles.css',
    'html/main.js'
}
