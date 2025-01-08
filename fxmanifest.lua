fx_version 'cerulean'
game 'gta5'

lua54 'on'

author 'DeeBee'
description 'NPC Doktor'
version '1.0.0'

client_scripts {
    'config.lua',
    'client.lua'
}

server_scripts {
    'server.lua'
}

shared_scripts {
    '@ox_lib/init.lua'
}

dependencies {
    'qtarget'
}
