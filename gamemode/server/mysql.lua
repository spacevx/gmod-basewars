BaseWars.MySQL = BaseWars.MySQL or {}
local storage = BaseWars.MySQL

storage.Host = storage.Host or "127.0.0.1"
storage.Port = storage.Port or 3306
storage.User = storage.User or ""
storage.Password = storage.Password or ""
storage.Database = storage.Database or ""

local columns = { money = true, karma = true, time = true, xp = true, level = true }
local pending = {}
local playerLoads = {}
local ready = false
local connecting = false
local goobie
local sessionID = tostring(os.time()) .. "-" .. tostring(math.random(1, 2147483647))

local function fail(context, err)
	ErrorNoHalt("[BaseWars SQL] " .. context .. ": " .. tostring(err) .. "\n")
end

local function playerID(ply)
	local sid = IsValid(ply) and ply:IsPlayer() and ply:SteamID64() or (isstring(ply) and ply)
	if not sid or not sid:match("^%d+$") then return nil end
	return sid
end

local function playerAlive(ply)
	return not isentity(ply) or IsValid(ply)
end

local function enqueue(work)
	if ready then return work(storage.DbObj) end
	pending[#pending + 1] = work
	if not connecting then storage.Connect() end
end

local function finishLoad(ply)
	local state = playerLoads[ply]
	if not state or state.dispatching or state.remaining ~= 0 or not playerAlive(ply) then return end
	playerLoads[ply] = nil
	hook.Run("PostLoadData", ply)
end

function storage.Connect(callback)
	if ready then
		if callback then callback() end
		return
	end
	if callback then pending[#pending + 1] = function() callback() end end
	if connecting then return end
	connecting = true
	if not goobie then
		local ok, lib = pcall(include, "server/thirdparty/goobie-sql.lua")
		if not ok or not lib or not lib.NewConn then
			connecting = false
			error("BaseWars requires goobie-sql.lua in gamemode/server/thirdparty: " .. tostring(lib))
		end
		goobie = lib
	end
	if storage.User == "" or storage.Database == "" then
		connecting = false
		error("Configure BaseWars.MySQL.User and Database in gamemode/server/mysql.lua")
	end
	storage.DbObj = goobie.NewConn({
		driver = "mysql",
		host = storage.Host,
		port = storage.Port,
		username = storage.User,
		password = storage.Password,
		database = storage.Database,
		charset = "utf8mb4",
		on_error = function(err) fail("connection", err) end,
	}, function(err)
		if err then
			connecting = false
			storage.DbObj = nil
			fail("connect", err)
			return
		end
		storage.DbObj:Run([[
			CREATE TABLE IF NOT EXISTS basewars (
				sid64 VARCHAR(20) CHARACTER SET ascii COLLATE ascii_bin NOT NULL PRIMARY KEY,
				money BIGINT UNSIGNED NOT NULL DEFAULT 0,
				karma INT NOT NULL DEFAULT 0,
				`time` BIGINT UNSIGNED NOT NULL DEFAULT 0,
				xp INT NOT NULL DEFAULT 0,
				level INT NOT NULL DEFAULT 1
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
		]], {callback = function(schemaErr)
			if schemaErr then
				connecting = false
				return fail("create players table", schemaErr)
			end
			storage.DbObj:Run([[
				CREATE TABLE IF NOT EXISTS basewars_crash_refunds (
					sid64 VARCHAR(20) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
					session_id VARCHAR(32) NOT NULL,
					amount BIGINT UNSIGNED NOT NULL,
					PRIMARY KEY (sid64, session_id)
				) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
			]], {callback = function(refundErr)
				if refundErr then
					connecting = false
					return fail("create refunds table", refundErr)
				end
				storage.DbObj:Run([[
					CREATE TABLE IF NOT EXISTS basewars_textscreen_configs (
						sid64 VARCHAR(20) CHARACTER SET ascii COLLATE ascii_bin NOT NULL PRIMARY KEY,
						config TEXT NOT NULL
					) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
				]], {callback = function(configErr)
					if configErr then
						connecting = false
						return fail("create textscreen table", configErr)
					end
					ready = true
					connecting = false
					BaseWars.UTIL.Log("Connected to MySQL with goobie-sql")
					local queued = pending
					pending = {}
					for _, work in ipairs(queued) do work(storage.DbObj) end
				end})
			end})
		end})
	end)
end

function storage.Disconnect()
	if not storage.DbObj then return end
	local err = storage.DbObj:DisconnectSync()
	if err then fail("disconnect", err) end
	storage.DbObj = nil
	ready = false
end

function storage.FullInitPlayer(ply)
	local sid = playerID(ply)
	if not sid then return end
	enqueue(function(db)
		db:Run("INSERT IGNORE INTO basewars (sid64, money) VALUES ({1}, {2})", {
			params = {sid, tonumber(BaseWars.Config.StartMoney) or 5000},
			callback = function(err)
				if err then return fail("initialize player " .. sid, err) end
				if not playerAlive(ply) then return end
				playerLoads[ply] = {dispatching = true, remaining = 0}
				hook.Run("LoadData", ply)
				playerLoads[ply].dispatching = false
				finishLoad(ply)
			end,
		})
	end)
end

function storage.InitPlayer() end

function storage.SaveVar(ply, var, val, callback)
	local sid = playerID(ply)
	if not sid or not columns[var] then return fail("invalid player or column", var) end
	val = tonumber(val)
	if not val or val ~= val or val == math.huge or val == -math.huge then
		return fail("invalid value for " .. var, val)
	end
	val = math.Round(val)
	enqueue(function(db)
		db:Run("UPDATE basewars SET `" .. var .. "` = {1} WHERE sid64 = {2}", {
			params = {val, sid},
			callback = function(err)
				if err then return fail("save " .. var .. " for " .. sid, err) end
				if callback and playerAlive(ply) then callback(ply, var, val) end
			end,
		})
	end)
end

function storage.LoadVar(ply, var, callback)
	local sid = playerID(ply)
	if not sid or not columns[var] then return fail("invalid player or column", var) end
	local state = playerLoads[ply]
	if state then state.remaining = state.remaining + 1 end
	enqueue(function(db)
		db:FetchOne("SELECT `" .. var .. "` FROM basewars WHERE sid64 = {1}", {
			params = {sid},
			callback = function(err, row)
				if err then return fail("load " .. var .. " for " .. sid, err) end
				if not row or row[var] == nil then return fail("missing " .. var .. " for " .. sid, "no row") end
				if callback and playerAlive(ply) then callback(ply, var, row[var]) end
				if state then
					state.remaining = state.remaining - 1
					finishLoad(ply)
				end
			end,
		})
	end)
end

function storage.SaveTextscreenConfig(ply, config)
	local sid = playerID(ply)
	if not sid or not isstring(config) or #config > 16000 then return end
	enqueue(function(db)
		db:Run("INSERT INTO basewars_textscreen_configs (sid64, config) VALUES ({1}, {2}) ON DUPLICATE KEY UPDATE config = {2}", {
			params = {sid, config},
			callback = function(err) if err then fail("save textscreen config for " .. sid, err) end end,
		})
	end)
end

function storage.LoadTextscreenConfig(ply)
	local sid = playerID(ply)
	if not sid then return end
	enqueue(function(db)
		db:FetchOne("SELECT config FROM basewars_textscreen_configs WHERE sid64 = {1}", {
			params = {sid},
			callback = function(err, row)
				if err then return fail("load textscreen config for " .. sid, err) end
				if not playerAlive(ply) then return end
				local config = row and row.config or ""
				net.Start("textscreens_config")
				net.WriteUInt(#config, 16)
				if #config > 0 then net.WriteData(config, #config) end
				net.Send(ply)
			end,
		})
	end)
end

util.AddNetworkString("textscreens_config")
hook.Add("PostLoadData", "BaseWars.LoadTextscreenConfig", storage.LoadTextscreenConfig)

function storage.SaveCrashRefunds(refunds)
	enqueue(function(db)
		for sid, amount in pairs(refunds) do
			if playerID(sid) then
				db:Run("INSERT INTO basewars_crash_refunds (sid64, session_id, amount) VALUES ({1}, {2}, {3}) ON DUPLICATE KEY UPDATE amount = {3}", {
					params = {sid, sessionID, math.max(0, math.Round(tonumber(amount) or 0))},
					callback = function(err) if err then fail("save crash refund for " .. sid, err) end end,
				})
			end
		end
	end)
end

function storage.ClearCrashRefund(ply)
	local sid = playerID(ply)
	if not sid then return end
	enqueue(function(db)
		db:Run("DELETE FROM basewars_crash_refunds WHERE sid64 = {1} AND session_id = {2}", {
			params = {sid, sessionID},
			callback = function(err) if err then fail("clear crash refund for " .. sid, err) end end,
		})
	end)
end

function storage.RefundFromCrash(ply)
	local sid = playerID(ply)
	if not sid then return end
	enqueue(function(db)
		db:Begin(function(err, txn)
			if err then return fail("begin crash refund for " .. sid, err) end
			local fetchErr, rows = txn:Fetch("SELECT amount FROM basewars_crash_refunds WHERE sid64 = {1} AND session_id <> {2} FOR UPDATE", {
				params = {sid, sessionID},
			})
			if fetchErr then
				txn:Rollback()
				return fail("load crash refund for " .. sid, fetchErr)
			end
			if not rows or #rows == 0 or not playerAlive(ply) then return txn:Rollback() end
			local amount = 0
			for _, row in ipairs(rows) do amount = amount + (tonumber(row.amount) or 0) end
			local updateErr = txn:Execute("UPDATE basewars SET money = money + {1} WHERE sid64 = {2}", {
				params = {amount, sid},
			})
			if updateErr then
				txn:Rollback()
				return fail("credit crash refund for " .. sid, updateErr)
			end
			local deleteErr = txn:Execute("DELETE FROM basewars_crash_refunds WHERE sid64 = {1} AND session_id <> {2}", {
				params = {sid, sessionID},
			})
			if deleteErr then
				txn:Rollback()
				return fail("claim crash refund for " .. sid, deleteErr)
			end
			local commitErr = txn:Commit()
			if commitErr then return fail("commit crash refund for " .. sid, commitErr) end
			if not playerAlive(ply) then return end
			BaseWars.Economy:UpdateMoney(ply, ply:GetMoney() + amount)
			ply:ChatPrint(BaseWars.LANG.WelcomeBackCrash)
			ply:ChatPrint(string.format(BaseWars.LANG.Refunded, BaseWars.NumberFormat(amount)))
		end)
	end)
end

function storage.ClearAllCrashRefunds()
	if not ready then return end
	local err = storage.DbObj:RunSync("DELETE FROM basewars_crash_refunds WHERE session_id = {1}", {
		params = {sessionID},
	})
	if err then fail("clear crash refunds on shutdown", err) end
end
