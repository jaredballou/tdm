include("shared.lua")
include("player.lua")
include("sv_rounds.lua")

--Classes
include("player_class/noclass.lua")
include("player_class/assault.lua")
include("player_class/infantry.lua")

--Map Voting (Not My Code)
include("mapvote/mapvote.lua")
include("mapvote/sv_mapvote.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_menus.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_welcome.lua")
AddCSLuaFile("cl_pickclass.lua")
AddCSLuaFile("mapvote/cl_mapvote.lua")

--Classes For Client
AddCSLuaFile("player_class/noclass.lua")
AddCSLuaFile("player_class/assault.lua")
AddCSLuaFile("player_class/infantry.lua")

------------------------------------------
--			Opening VGUI				--
------------------------------------------

function GM:ShowHelp( ply ) -- F1
	ply:ConCommand("chooseTeam") --cl_menus.lua
end

function GM:ShowTeam( ply ) -- F2 
	ply:ConCommand("pickClass") --cl_picklass.lua
end

function GM:ShowSpare2( ply ) -- F4
	-- Coming soon -- cL_help.lua
end

------------------------------------------
--		Connecting/Disconnecting		--
------------------------------------------

function GM:PlayerConnect ( name, ip )
	print("Player: " .. name .. " has connected.")
end


function GM:PlayerAuthed ( ply, steamID, uniqueID )
	print ("Player: " .. ply:Nick() .. " ( " .. ply:SteamID() .. " ) has authenticated.")
end

function GM:PlayerDisconnected( ply )
	print("Player: " .. ply:Nick() .. " has disconnected.")
end

------------------------------------------
--				Spawning				--
------------------------------------------

function GM:PlayerInitialSpawn ( ply )
	print("Player: " .. ply:Nick() .. " has joined.")

	if (ply:IsBot()) then
		ply:SetGamemodeTeam( math.random(0, 1) )

		player_manager.OnPlayerSpawn( ply )
		player_manager.SetPlayerClass( ply, "infantry" )
        player_manager.RunClass( ply, "Spawn" )
        hook.Call( "PlayerLoadout", GAMEMODE, ply )
        hook.Call( "PlayerSetModel", GAMEMODE, ply )
		ply:KillSilent()
		ply:Spawn()
	else
		ply:StripWeapons()
		ply:SetTeam( TEAM_SPEC )
		ply:Spectate( OBS_MODE_ROAMING )

		player_manager.OnPlayerSpawn( ply )
		player_manager.SetPlayerClass( ply, "noclass" )
        player_manager.RunClass( ply, "Spawn" )
        hook.Call( "PlayerLoadout", GAMEMODE, ply )
        hook.Call( "PlayerSetModel", GAMEMODE, ply )

		ply:ConCommand("welcomePlayer")
	end
end

function GM:PlayerSpawn ( ply )
	if ply:Team() == TEAM_SPEC then 
		ply:Spectate( OBS_MODE_ROAMING )
	elseif ply:Team() == TEAM_RED then
		ply:SetupHands()
		player_manager.OnPlayerSpawn( ply )
        player_manager.RunClass( ply, "Spawn" )
        hook.Call( "PlayerLoadout", GAMEMODE, ply )
        hook.Call( "PlayerSetModel", GAMEMODE, ply )

	elseif ply:Team() == TEAM_BLUE then
		ply:SetupHands()
		player_manager.OnPlayerSpawn( ply )
        player_manager.RunClass( ply, "Spawn" )
        hook.Call( "PlayerLoadout", GAMEMODE, ply )
        hook.Call( "PlayerSetModel", GAMEMODE, ply )

	end

	--not my code, displaying hand models
	if ply:Team() != TEAM_SPEC then
		local oldhands = ply:GetHands()
		if ( IsValid( oldhands ) ) then oldhands:Remove() end

		local hands = ents.Create( "gmod_hands" )
		if ( IsValid( hands ) ) then
	    	ply:SetHands( hands )
	    	hands:SetOwner( ply )

		    -- Which hands should we use?
		    local cl_playermodel = ply:GetInfo( "cl_playermodel" )
		    local info = player_manager.TranslatePlayerHands( cl_playermodel )
	    		if ( info ) then
			    	hands:SetModel( info.model )
			   		hands:SetSkin( info.skin )
			    	hands:SetBodyGroups( info.body )
	    		end

		    -- Attach them to the viewmodel
		    local vm = ply:GetViewModel( 0 )
		    hands:AttachToViewmodel( vm )

		    vm:DeleteOnRemove( hands )
		    ply:DeleteOnRemove( hands )

		    hands:Spawn()
	  	end
	end
end

function GM:Think()
	self:RoundThink()
end

--Doing this just in case, team.SetSpawnPoint wasn't working. Works now.
function GM:PlayerSelectSpawn( ply ) 
 
    local spawns = ents.FindByClass( "info_player_terrorist" ) 
    local truespawn = table.Random(spawns)

    if (ply:Team() == TEAM_RED) then

        return truespawn

    end 


    local spawns = ents.FindByClass( "info_player_counterterrorist" ) 
    local truespawn = table.Random(spawns)

    if (ply:Team() == TEAM_BLUE) then

        return truespawn

    end 

end

------------------------------------------
--	Player Loadout (Just in case)		--
------------------------------------------

function GM:PlayerLoadout( ply )
	if ply:Team() == TEAM_SPEC then return false end

	if ply:Team() == TEAM_RED then
		player_manager.RunClass( ply, "Loadout" )
		return true
	elseif ply:Team() == TEAM_BLUE then
		player_manager.RunClass( ply, "Loadout" )
		return true
	end
end

------------------------------------------
--			Taking Damage				--
------------------------------------------

function GM:CanPlayerSuicide( ply )
	if ply:Team() == TEAM_SPEC then return false end
	return true
end

function GM:GetFallDamage( ply, flFallSpeed )
	
	return flFallSpeed / 8
	
end

function GM:PlayerShouldTakeDamage( ply, attacker )

	if ( IsValid( attacker ) ) then
		if ( attacker.Team && ply:Team() == attacker:Team() && ply != attacker ) then return false end
	end
	
	return true
end

function GM:DoPlayerDeath( victim, attacker, dmginfo )

	victim:CreateRagdoll()
	
	victim:AddDeaths( 1 )

	if ( attacker:IsValid() && attacker:IsPlayer() ) then
	
		if ( attacker == victim ) then
			attacker:AddFrags( -1 )
		else
			attacker:AddFrags( 1 )
		end
		
	end

	if victim:Team() == TEAM_RED then

		local blueKills = GetGlobalInt( "TDM_BlueKills" )
		SetGlobalInt( "TDM_BlueKills", blueKills + 1 )

	elseif victim:Team() == TEAM_BLUE then

		local redKills = GetGlobalInt( "TDM_RedKills" )
		SetGlobalInt( "TDM_RedKills", redKills + 1 )

	end

end
------------------------------------------
--			Team Switching				--
------------------------------------------
-- Unless spectating, upon switching team player will be forced to choose a class. 
-- Need to add a team switching restriction system

function stTeamSpec( ply )
	ply:KillSilent()
	player_manager.SetPlayerClass( ply, "noclass" )
	ply:UnSpectate()
	ply:SetGamemodeTeam( TEAM_SPEC )
	ply:StripWeapons()
	ply:Spectate( OBS_MODE_ROAMING )
	for k,v in pairs(player.GetAll()) do
		v:ChatPrint( "Player "..ply:GetName().." has become a " .. team.GetName( ply:Team() ) .. "." )
	end
end
concommand.Add( "stTeamSpec", stTeamSpec )

function stTeamT( ply )
	ply:UnSpectate()
	ply:StripWeapons()
	ply:SetGamemodeTeam( TEAM_RED )
	ply:KillSilent()
	ply:ConCommand("pickClass")
	for k,v in pairs(player.GetAll()) do
		v:ChatPrint( "Player "..ply:GetName().." has joined the " .. team.GetName( ply:Team() ) .. " Team.")
	end
end
concommand.Add( "stTeamT", stTeamT )

function stTeamCT( ply )
	ply:UnSpectate()
	ply:StripWeapons()
	ply:SetGamemodeTeam( TEAM_BLUE )
	ply:KillSilent()
	ply:ConCommand("pickClass")
	for k,v in pairs(player.GetAll()) do
		v:ChatPrint( "Player "..ply:GetName().." has joined the " .. team.GetName( ply:Team() ) .. " Team." )
	end
end
concommand.Add( "stTeamCT", stTeamCT )

------------------------------------------
--			Class Switching				--
------------------------------------------
--Class system will be overhauled. Two classes to test if system works. It does.

function assaultClass( ply )
	if ply:Alive() then ply:KillSilent() end
	ply:StripWeapons()
	player_manager.SetPlayerClass( ply, "assault" )
	ply:Spawn()
end
concommand.Add( "assaultClass", assaultClass )

function infantryClass( ply )
	if ply:Alive() then ply:KillSilent() end
	ply:StripWeapons()
	player_manager.SetPlayerClass( ply, "infantry" )
	ply:Spawn()
end
concommand.Add( "infantryClass", infantryClass )