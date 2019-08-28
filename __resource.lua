resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

description 'ESX AutoPayBills'

version '1.0.0'

server_scripts {
	'@es_extended/locale.lua',
	'@mysql-async/lib/MySQL.lua',
	'config.lua',
	'server.lua'
}

dependencies {
	'es_extended',
	'cron'
}