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
	print("Paiement des factures en cours le serveur peut lag momentanément")
	CreateThread(function()
		Wait(0)
		MySQL.Async.fetchAll('SELECT * FROM billing', {}, function (result)
			print(#result)
			for i=1, #result, 1 do
				local xPlayer = ESX.GetPlayerFromIdentifier(result[i].identifier)
				
				-- message player if connected
				if xPlayer then
					local accountMoney = xPlayer.getAccount('bank').money
					
					if accountMoney > 0 then
						if math.floor(accountMoney/100*Config.MaxPercentPay) >= result[i].amount then
							xPlayer.removeAccountMoney('bank', result[i].amount)
							TriggerClientEvent('esx:showNotification', xPlayer.source, "Vous avez payer ".. ESX.Math.GroupDigits(result[i].amount).." sur une factures passé due")
							TriggerEvent('esx_addonaccount:getSharedAccount', result[i].target, function(account)
								account.addMoney(result[i].amount)
							end)
							MySQL.Sync.execute('DELETE FROM billing WHERE id = @id',
							{
								['@id'] = result[i].id
							})
							print(xPlayer.name.." a payer "..result[i].amount.." d'une factures due a "..result[i].target)
						else
							xPlayer.removeAccountMoney('bank', math.floor(accountMoney/100*Config.MaxPercentPay))
							TriggerClientEvent('esx:showNotification', xPlayer.source, "Vous avez payer ".. ESX.Math.GroupDigits(math.floor(accountMoney/100*Config.MaxPercentPay)).." sur une factures passé due")
							TriggerEvent('esx_addonaccount:getSharedAccount', result[i].target, function(account)
								account.addMoney(math.floor(accountMoney/100*Config.MaxPercentPay))
							end)
							MySQL.Sync.execute('UPDATE billing SET amount = amount - @amount WHERE id = @id',
							{
								['@amount'] = math.floor(accountMoney/100*Config.MaxPercentPay),
								['@id'] = result[i].id
							})
							print(xPlayer.name.." a payer "..(math.floor(accountMoney/100*Config.MaxPercentPay)).." d'une factures due a "..result[i].target)
						end
						
					end
				else -- pay rent either way
					MySQL.Async.fetchScalar('SELECT accounts FROM users WHERE identifier = @identifier', 
					{
						['@identifier'] = result[i].identifier
					}, function(jsonAccounts)
						local accounts = json.decode(jsonAccounts)
						if accounts.bank > 0 then
							if math.floor(accounts.bank/100*Config.MaxPercentPay) >= result[i].amount then
								accounts.bank = accounts.bank - result[i].amount
								MySQL.Sync.execute('UPDATE users SET accounts = @accounts WHERE identifier = @identifier',
								{
									['@accounts']   = json.encode(accounts),
									['@identifier'] = result[i].identifier
								})
								TriggerEvent('esx_addonaccount:getSharedAccount', result[i].target, function(account)
									account.addMoney(result[i].amount)
								end)
								MySQL.Sync.execute('DELETE FROM billing WHERE `id` = @id',
								{
									['@id'] = result[i].id
								})
								print(result[i].identifier.." a payer "..(result[i].amount).." d'une factures due a "..result[i].target)
							else
								accounts.bank = accounts.bank - math.floor(accounts.bank/100*Config.MaxPercentPay)
								MySQL.Sync.execute('UPDATE users SET accounts = @accounts WHERE identifier = @identifier',
								{
									['@accounts']   = json.encode(accounts),
									['@identifier'] = result[i].identifier
								})
								MySQL.Sync.execute('UPDATE billing SET amount = amount - @amount WHERE id = @id',
								{
									['@amount']       = math.floor(accounts.bank/100*Config.MaxPercentPay),
									['@id'] = result[i].id
								})
								print(result[i].identifier.." a payer "..(math.floor(accounts.bank/100*Config.MaxPercentPay)).." d'une factures due a "..result[i].target)
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
