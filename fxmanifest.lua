fx_version 'cerulean'
game 'gta5'
lua54 'yes'

client_scripts {
    '@ox_lib/init.lua',
    'client/main.lua'
}

files {
    'client/*.lua',
    'web/index.html',
    'web/index.js',
}

ui_page 'web/index.html'
