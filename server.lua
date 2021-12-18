ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function SocietyInvest(d, h, m)
	TriggerEvent('esx_addonaccount:getSharedAccount', 'society_police', function(account)
		account.addMoney(Config.SocietyPolice)
	end)
	TriggerEvent('esx_addonaccount:getSharedAccount', 'society_ambulance', function(account)
		account.addMoney(Config.SocietyAmbulance)
	end)
end

function PayBills(d, h, m)
	if Config.Debug then print("AutoPayBills start") end
	CreateThread(function()
		Wait(0)
		MySQL.Async.fetchAll('SELECT * FROM billing', {}, function (result)
			for i=1, #result, 1 do
				Wait(100)--Slow down process
				local xPlayer = ESX.GetPlayerFromIdentifier(result[i].identifier)
				
				-- message player if connected
				if xPlayer then
					local accountMoney = xPlayer.getAccount('bank').money

					if accountMoney > 0 then
						if ESX.Math.Round(accountMoney/100*Config.MaxPercentPay) >= result[i].amount then
							xPlayer.removeAccountMoney('bank', result[i].amount)
							TriggerClientEvent('esx:showNotification', xPlayer.source, "Vous avez payer ".. ESX.Math.GroupDigits(result[i].amount).." sur une factures passé due")
							if result[i].target_type == "society" then
								TriggerEvent('esx_addonaccount:getSharedAccount', result[i].target, function(account)
									account.addMoney(result[i].amount)
								end)
							elseif result[i].target_type == "player" then
								local xTarget = ESX.GetPlayerFromIdentifier(result[i].target)

								if xTarget then--target player is online
									xTarget.addAccountMoney('bank', result[i].amount)
								else--target player not online
									MySQL.Async.fetchScalar('SELECT accounts FROM users WHERE identifier = @identifier', 
									{
										['@identifier'] = result[i].target
									}, function(targetAccounts)
										local xtargetAccounts = json.decode(targetAccounts)

										xtargetAccounts.bank = xtargetAccounts.bank + result[i].amount
										MySQL.Sync.execute('UPDATE users SET accounts = @accounts WHERE identifier = @identifier',
										{
											['@accounts']   = json.encode(xtargetAccounts),
											['@identifier'] = result[i].target
										})
									end)
								end
							else
								print("BanSql Error : Invalid target_type '",result[i].target_type,"' in sql table 'billing'")
							end
							MySQL.Sync.execute('DELETE FROM billing WHERE id = @id',
							{
								['@id'] = result[i].id
							})
							if Config.Debug then print(xPlayer.name.." pay "..result[i].amount.." from bill to "..result[i].target) end
						else
							local amount = ESX.Math.Round(accountMoney/100*Config.MaxPercentPay)
							xPlayer.removeAccountMoney('bank', amount)
							TriggerClientEvent('esx:showNotification', xPlayer.source, "Vous avez payer ".. ESX.Math.GroupDigits(amount).." sur une factures passé due")
							if result[i].target_type == "society" then
								TriggerEvent('esx_addonaccount:getSharedAccount', result[i].target, function(account)
									account.addMoney(amount)
								end)
							elseif result[i].target_type == "player" then
								local xTarget = ESX.GetPlayerFromIdentifier(result[i].target)

								if xTarget then
									xTarget.addAccountMoney('bank', amount)
								else
									MySQL.Async.fetchScalar('SELECT accounts FROM users WHERE identifier = @identifier', 
									{
										['@identifier'] = result[i].target
									}, function(targetAccounts)
										local xtargetAccounts = json.decode(targetAccounts)

										xtargetAccounts.bank = xtargetAccounts.bank + amount
										MySQL.Sync.execute('UPDATE users SET accounts = @accounts WHERE identifier = @identifier',
										{
											['@accounts']   = json.encode(xtargetAccounts),
											['@identifier'] = result[i].target
										})
									end)
								end
							else
								print("BanSql Error : Invalid target_type '",result[i].target_type,"' in sql table 'billing'")
							end

							MySQL.Sync.execute('UPDATE billing SET amount = amount - @amount WHERE id = @id',
							{
								['@amount'] = amount,
								['@id'] = result[i].id
							})
							if Config.Debug then print(xPlayer.name.." pay "..(amount).." from bill to "..result[i].target) end
						end
						
					end
				else -- pay rent either way
					MySQL.Async.fetchScalar('SELECT accounts FROM users WHERE identifier = @identifier', 
					{
						['@identifier'] = result[i].identifier
					}, function(jsonAccounts)
						local accounts = json.decode(jsonAccounts)
						if accounts.bank > 0 then
							if ESX.Math.Round(accounts.bank/100*Config.MaxPercentPay) >= result[i].amount then
								accounts.bank = accounts.bank - result[i].amount
								MySQL.Sync.execute('UPDATE users SET accounts = @accounts WHERE identifier = @identifier',
								{
									['@accounts']   = json.encode(accounts),
									['@identifier'] = result[i].identifier
								})
								if result[i].target_type == "society" then
									TriggerEvent('esx_addonaccount:getSharedAccount', result[i].target, function(account)
										account.addMoney(result[i].amount)
									end)
								elseif result[i].target_type == "player" then
									local xTarget = ESX.GetPlayerFromIdentifier(result[i].target)

									if xTarget then--target player is online
										xTarget.addAccountMoney('bank', result[i].amount)
									else--target player not online
										MySQL.Async.fetchScalar('SELECT accounts FROM users WHERE identifier = @identifier', 
										{
											['@identifier'] = result[i].target
										}, function(targetAccounts)
											local xtargetAccounts = json.decode(targetAccounts)

											xtargetAccounts.bank = xtargetAccounts.bank + result[i].amount
											MySQL.Sync.execute('UPDATE users SET accounts = @accounts WHERE identifier = @identifier',
											{
												['@accounts']   = json.encode(xtargetAccounts),
												['@identifier'] = result[i].target
											})
										end)
									end
								else
									print("BanSql Error : Invalid target_type '",result[i].target_type,"' in sql table 'billing'")
								end
								MySQL.Sync.execute('DELETE FROM billing WHERE `id` = @id',
								{
									['@id'] = result[i].id
								})
								if Config.Debug then print(result[i].identifier.." pay "..(result[i].amount).." from bill to "..result[i].target) end
							else
								local amount = ESX.Math.Round(accounts.bank/100*Config.MaxPercentPay)
								accounts.bank = accounts.bank - amount
								MySQL.Sync.execute('UPDATE users SET accounts = @accounts WHERE identifier = @identifier',
								{
									['@accounts']   = json.encode(accounts),
									['@identifier'] = result[i].identifier
								})
								MySQL.Sync.execute('UPDATE billing SET amount = amount - @amount WHERE id = @id',
								{
									['@amount']       = amount,
									['@id'] = result[i].id
								})
								if result[i].target_type == "society" then
									TriggerEvent('esx_addonaccount:getSharedAccount', result[i].target, function(account)
										account.addMoney(accounts.bank/100*Config.MaxPercentPay)
									end)
								elseif result[i].target_type == "player" then
									local xTarget = ESX.GetPlayerFromIdentifier(result[i].target)
									if xTarget then
										xTarget.addAccountMoney('bank', amount)
									else
										MySQL.Async.fetchScalar('SELECT accounts FROM users WHERE identifier = @identifier', 
										{
											['@identifier'] = result[i].target
										}, function(targetAccounts)
											local xtargetAccounts = json.decode(targetAccounts)
											xtargetAccounts.bank = xtargetAccounts.bank + amount
											MySQL.Sync.execute('UPDATE users SET accounts = @accounts WHERE identifier = @identifier',
											{
												['@accounts']   = json.encode(xtargetAccounts),
												['@identifier'] = result[i].target
											})
										end)
									end
								else
									print("BanSql Error : Invalid target_type '",result[i].target_type,"' in sql table 'billing'")
								end
								if Config.Debug then print(result[i].identifier.." pay "..(amount).." from bill to "..result[i].target) end
							end
						end
					end)
				end
			end
		end)
	end)
end

if Config.SocietyInvest then
	TriggerEvent('cron:runAt', 22, 0, SocietyInvest)
end

if Config.AutoPayBills then
	TriggerEvent('cron:runAt', 8, 0, PayBills)
end

if Config.Debug then
	RegisterCommand("test", function(source, args, raw)
		if source == 0 then
			PayBills()
		end
	end, true)
end