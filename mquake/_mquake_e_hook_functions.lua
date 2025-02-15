if SM64COOPDX_VERSION == nil then return end
local is_player_active,vec3f_copy,set_mario_action,perform_air_step,save_file_get_flags,save_file_set_flags,save_file_do_save,get_current_save_file_num,vec3f_dot,get_id_from_behavior,djui_hud_set_color,djui_hud_render_rect,djui_hud_print_text,djui_hud_set_resolution,djui_hud_get_screen_width,djui_hud_get_screen_height,djui_hud_set_font,vec3f_length,math_floor,djui_hud_measure_text,get_cutscene_from_mario_status,obj_get_first,obj_get_next,obj_get_nearest_object_with_behavior_id,obj_check_hitbox_overlap = is_player_active,vec3f_copy,set_mario_action,perform_air_step,save_file_get_flags,save_file_set_flags,save_file_do_save,get_current_save_file_num,vec3f_dot,get_id_from_behavior,djui_hud_set_color,djui_hud_render_rect,djui_hud_print_text,djui_hud_set_resolution,djui_hud_get_screen_width,djui_hud_get_screen_height,djui_hud_set_font,vec3f_length,math.floor,djui_hud_measure_text,get_cutscene_from_mario_status,obj_get_first,obj_get_next,obj_get_nearest_object_with_behavior_id,obj_check_hitbox_overlap

local increase_speed_color = { r = 255, g = 255, b = 255, a = 255 }
local decrease_speed_color = { r = 255, g = 0, b = 0, a = 255 }
local default_speed_color = { r = 255, g = 255, b = 255, a = 255 }

local last_hspeed = 0
local current_speed_color = { r = 255, g = 255, b = 255, a = 255 }
function safe_load_number(key, default)
	-- TODO: mod_storage_load_number actually just returns 0 if it fails. Ugh.
	if mod_storage_load_number(key) ~= nil then
		return mod_storage_load_number(key)
	end
	return default
end

function safe_load_bool(key, default)
	-- TODO: mod_storage_load_bool actually just returns false if it fails. Ugh.
	if mod_storage_load_bool(key) ~= nil then
		return mod_storage_load_bool(key)
	end
	return default
end

function no_dialog_open()
	return not (get_dialog_id() >= 0 and get_dialog_box_state() < 3)
end
-- function remove_cutscenes(m)
	-- todo: this shit breaks
    -- if m.area ~= nil and m.area.camera ~= nil then
		-- local lvl = gNetworkPlayers[m.playerIndex].currLevelNum
		-- if (cutsceneActns[m.action] ~= 1 or not no_dialog_open()) and (lvl ~= LEVEL_BOWSER_1 and lvl ~= LEVEL_BOWSER_2 and lvl ~= LEVEL_BOWSER_3) then
			-- disable_time_stop()
			-- m.area.camera.cutscene = 0
			-- m.statusForCamera.cameraEvent = 0
			-- m.freeze = 0
		-- end
    -- end
-- end

local intFix = 0

--- @param m MarioState
function active_player(m)
    local np = gNetworkPlayers[m.playerIndex]
    if m.playerIndex == 0 then
        return 1
    end
    if not np.connected then
        return 0
    end
    if np.currCourseNum ~= gNetworkPlayers[0].currCourseNum then
        return 0
    end
    if np.currActNum ~= gNetworkPlayers[0].currActNum then
        return 0
    end
    if np.currLevelNum ~= gNetworkPlayers[0].currLevelNum then
        return 0
    end
    if np.currAreaIndex ~= gNetworkPlayers[0].currAreaIndex then
        return 0
    end
    return is_player_active(m)
end

function on_set_mario_action(m) 
	if (m.playerIndex == 0) then 
		if (DM_ACTION_TRANSFERS[m.action] == 1) then
			local yVel = m.vel.y * sv_scalerate_inverse
			local fVel = m.forwardVel * sv_scalerate_inverse
			local s = gPlayerSyncTable[m.playerIndex]
			local direction = GetAngleVectors(m).forward
			vec3f_copy(m.vel,vec3_scale(direction,m.forwardVel*sv_scalerate_inverse))
			m.vel.y = yVel
			local is_underwater = m.pos.y <= m.waterLevel-sv_playersubmergelevel
			local metal_underwater = (m.flags & MARIO_METAL_CAP) ~= 0
			if ((m.action & ACT_FLAG_AIR) ~= 0) then
				set_mario_action(m, ACT_DM_AIR_MOVEMENT, 0)
				return 1
			elseif ((m.action & ACT_GROUP_SUBMERGED) ~= 0) then
				if (not metal_underwater) and (is_underwater) then 
					set_mario_action(m, ACT_DM_WATER_MOVEMENT, 0) 
					return 1
				end
				if (metal_underwater) and (is_underwater) then 
					set_mario_action(m, ACT_DM_AIR_MOVEMENT_METAL, 0) 
					return 1
				end
			end 
			set_mario_action(m, ACT_DM_GROUNDED_MOVEMENT, 0)
			return 1
		end
		if (DM_ACTION_FUNCTIONS[m.action] ~= nil) then
			local val = DM_ACTION_FUNCTIONS[m.action](m)
			if (val == 1) then return 1 end
		end
	end
end

function allow_voice(m,s) 
	if (s == CHAR_SOUND_ON_FIRE or s == CHAR_SOUND_ATTACKED or s == CHAR_SOUND_EEUH) then
		return 0
	end
end

function override_defacto(m) 
	-- if m.action == ACT_DM_AIR_MOVEMENT or m.action == ACT_DM_GROUNDED_MOVEMENT or 
	-- m.action == ACT_DM_AIR_MOVEMENT_METAL or m.action == ACT_DM_GROUNDED_MOVEMENT_METAL or m.action == ACT_DM_GROUNDED_IDLE then 
		return 1 
	-- end 
end

function on_player_connected(m)
    gPlayerSyncTable[m.playerIndex].playerCrouching = false
    gPlayerSyncTable[m.playerIndex].playerPitch = 1
    gPlayerSyncTable[m.playerIndex].playerYaw = 1
end

function before_set_mario_action(m,incoming) 
	if (DM_ACTION_PREFUNCS_ALL[incoming] ~= nil) then
		local val = DM_ACTION_PREFUNCS_ALL[incoming](m)
		if (val == 1) then return 1 end
	end
	
	if (m.playerIndex == 0) then 
		if (DM_ACTION_PREFUNCS[incoming] ~= nil) then
			return DM_ACTION_PREFUNCS[incoming](m)
		elseif (DM_ACTIONS[incoming] ~= 1) then
			m.controller.buttonPressed = 0
			local is_underwater = m.pos.y <= m.waterLevel-sv_playersubmergelevel
			local metal_underwater = (m.flags & MARIO_METAL_CAP) ~= 0
			if ((incoming & ACT_FLAG_AIR) ~= 0) then
				set_mario_action(m, ACT_DM_AIR_MOVEMENT, 0)
				return 1
			elseif ((incoming & ACT_FLAG_SWIMMING) ~= 0) or ((incoming & ACT_GROUP_SUBMERGED) ~= 0) then
				if (not metal_underwater) and (is_underwater) then 
					set_mario_action(m, ACT_DM_WATER_MOVEMENT, 0) 
					return 1
				end
				if (metal_underwater) and (is_underwater) then 
					set_mario_action(m, ACT_DM_AIR_MOVEMENT_METAL, 0) 
					return 1
				end
			end 
			set_mario_action(m, ACT_DM_GROUNDED_MOVEMENT, 0)
			return 1
		end
	end
end

function before_phys_step(m) 
	local act = m.action
	if (DM_ACTIONS[act] ~= 1) then return 0 end
	if ((act == ACT_DM_AIR_MOVEMENT or act == ACT_DM_AIR_MOVEMENT_METAL or act == ACT_DM_WATER_MOVEMENT or act == ACT_GROUND_POUND) and m.playerIndex == 0 and m.ceil ~= nil) then
		local h = m.marioObj.hitboxHeight
		if (m.ceilHeight <= m.pos.y + h) then
			m.pos.y = m.ceilHeight - h - 4
			return 0
		end
		
		if (m.pos.y + h + 4 + sv_camerayoffset > m.ceilHeight) then
			SV_PlayerMovement_Scale(m,true)
			vec3f_copy(m.vel, PHYS_CollideWithNormal(m.vel,m.ceil.normal,0.25))
			SV_PlayerMovement_Scale(m,false)
			m.pos.y = m.pos.y - 4
			return perform_air_step(m,0)
		end
	end
end


function on_interact(m,o,i,b) 
	if (intFix > 0) then return end
	if DM_ACTION_QPHYS[m.action] == 1 then
		if (i == INTERACT_BOUNCE_TOP or i == INTERACT_BOUNCE_TOP2) and not (m.action == ACT_GROUND_POUND or m.action == ACT_DM_GROUND_POUND_METAL) then
			if (o.oInteractStatus & INT_STATUS_WAS_ATTACKED) ~= 0 then
				m.vel.y = 160
				return
			end
		end
		if (o.oInteractStatus & INT_STATUS_ATTACKED_MARIO) ~= 0 and m.health > 0xFF then
			m.invincTimer = 30
			gLakituState.roll = 2730*(m.hurtCounter*0.25)
			gLakituState.oldRoll = gLakituState.roll
			cl_red = 128
			return
		end
		if i == INTERACT_STAR_OR_KEY then
			local lvl = gNetworkPlayers[m.playerIndex].currLevelNum
			if (lvl == LEVEL_BOWSER_1) then
				if ((save_file_get_flags() & (SAVE_FLAG_UNLOCKED_BASEMENT_DOOR)) == 0) then 
					save_file_set_flags(SAVE_FLAG_UNLOCKED_BASEMENT_DOOR)
					save_file_do_save(get_current_save_file_num()-1,true)
				end
			end
			if (lvl == LEVEL_BOWSER_2) then
				if ((save_file_get_flags() & (SAVE_FLAG_UNLOCKED_UPSTAIRS_DOOR)) == 0) then 
					save_file_set_flags(SAVE_FLAG_UNLOCKED_UPSTAIRS_DOOR)
					save_file_do_save(get_current_save_file_num()-1,true)
				end
			end
			return
		end
	end
end

function allow_interact(m,o,i) 
	if (intFix > 0) then return end
	if DM_ACTION_QPHYS[m.action] == 1 then
		if (i == INTERACT_POLE and no_dialog_open()) then
			if (vec3f_dot({x=o.oPosX-m.pos.x,y=0,z=o.oPosZ-m.pos.z},{x=m.vel.x,y=0,z=m.vel.z}) > 0) and (m.controller.buttonDown & B_BUTTON) ~= 0 then 
				m.usedObj = o
				cl_poleY = o.oPosY
				set_mario_action(m,ACT_DM_POLE_MOVEMENT,0)
			end 
			return false 
		end
		if (i == INTERACT_IGLOO_BARRIER) then
			if (m.controller.buttonDown & Z_TRIG ~= 0) then 
				return false 
			end 
		end
		if (m.action == ACT_DM_GROUND_POUND_METAL) then
			o.oInteractStatus = (o.oInteractStatus | INT_GROUND_POUND)
		end
	end
	if (get_id_from_behavior(o.behavior) == id_bhvToadMessage) then
		return false
	end
end

function on_pvp(m,v) 
	if (intFix > 0) then return end
	if DM_ACTION_QPHYS[v.action] == 1 then
		v.invincTimer = 30
		if (v.playerIndex == 0) then
			gLakituState.roll = 2730*(v.hurtCounter*0.25)
			gLakituState.oldRoll = gLakituState.roll
			cl_red = 128
		end
	end
end

local function render_speed(w2,h2,textWidth,h_offset,hspeed_text,scale,height) 
	local scale1 = scale*0.5
	djui_hud_set_color(0,0,0,100)
	djui_hud_render_rect((w2*0.5) - (textWidth*scale1) - 1,(h2*h_offset),textWidth*scale + 2,height)
	djui_hud_set_color(current_speed_color.r,current_speed_color.g,current_speed_color.b,current_speed_color.a)
	djui_hud_print_text(hspeed_text, (w2*0.5) - (textWidth*scale1),(h2*h_offset),scale)
end

function render_hud_effects() 
	local m = gMarioStates[0]
	if (m ~= nil) then
		gLakituState.focus.y = gLakituState.pos.y
		gLakituState.curFocus.y = gLakituState.curPos.y
		
		djui_hud_set_resolution(RESOLUTION_DJUI)
		local w = djui_hud_get_screen_width()
		local h = djui_hud_get_screen_height()
		if (cl_red > 0) then 
			djui_hud_set_color(255,0,0,cl_red*0.5)
			djui_hud_render_rect(0,0,w,h)
		end
		local c = m.area.camera
		if (c ~= nil) then 
			if (c.pos.y < m.waterLevel) then
				djui_hud_set_color(38,139,255,100)
				djui_hud_render_rect(0,0,w,h)
			end
		end
		
		if (m.health <= 0xFF or m.action == ACT_UNINITIALIZED or m.action == ACT_DISAPPEARED) then return end
		
		djui_hud_set_resolution(RESOLUTION_N64)
		djui_hud_set_font(FONT_NORMAL)
		
		local w2 = djui_hud_get_screen_width()
		local h2 = djui_hud_get_screen_height()
		
		local hspeed = m.forwardVel*sv_scalerate_inverse ; if (DM_ACTION_QPHYS[m.action] == 1) then hspeed = vec3f_length({x=m.vel.x,y=0,z=m.vel.z}) end

		if hspeed > last_hspeed then
			current_speed_color = increase_speed_color
		end

		if hspeed == last_hspeed then

			current_speed_color = default_speed_color
		end

		if hspeed < last_hspeed then

			current_speed_color = decrease_speed_color
		end

		local hspeed_text = tostring(math.floor(hspeed))
		local textWidth = djui_hud_measure_text(hspeed_text)
		render_speed(w2,h2,textWidth,0.8,hspeed_text,0.5,15)
		
		local vspeed = m.vel.y ; if (DM_ACTION_QPHYS[m.action] ~= 1) then vspeed = vspeed * sv_scalerate_inverse end
		local vspeed_text = tostring(math.floor(vspeed))
		local vtextWidth = djui_hud_measure_text(vspeed_text)
		render_speed(w2,h2,vtextWidth,0.75,vspeed_text,0.25,7.5)
		
		-- local vspeed_text = tostring(m.area.camera.cutscene)
		-- local vTextWidth = djui_hud_measure_text(vspeed_text)
		-- render_speed(w2,h2,vTextWidth,0.75,vspeed_text,0.25,7.5)
		
		-- local usedObjT = tostring(m.usedObj ~= nil)
		-- local usedObj = djui_hud_measure_text(usedObjT)
		-- render_speed(w2,h2,usedObj,0.6,usedObjT,0.25,7.5)
		
		-- local usedObjT2 = tostring(get_cutscene_from_mario_status(m.area.camera))
		-- local usedObj2 = djui_hud_measure_text(usedObjT2)
		-- render_speed(w2,h2,usedObj2,0.55,usedObjT2,0.25,7.5)
		
		if (m.capTimer > 0) then
			local capTimer_Seconds = math.floor(m.capTimer * 0.03333333333333333)
			local capText = "Cap Timer: " .. tostring(capTimer_Seconds)
			local capWidth = djui_hud_measure_text(capText)
			render_speed(w2,h2,capWidth,0.875,capText,0.5,15)
		end
		-- m.area.camera.cutscene = 0
		-- m.statusForCamera.cameraEvent = 0
		-- if (m.area.camera.cutscene > 0) then
			-- local at = "Area Cutscene: " .. tostring(m.area.camera.cutscene)
			-- local aw = djui_hud_measure_text(at)
			-- render_speed(w2,h2,aw,0.1,at,0.5,15)
		-- end
		-- if (m.statusForCamera.cameraEvent > 0) then
			-- local at2 = "Mario Cutscene: " .. tostring(m.statusForCamera.cameraEvent)
			-- local aw2 = djui_hud_measure_text(at2)
			-- render_speed(w2,h2,aw2,0.2,at2,0.5,15)
		-- end
		
		if (not sv_gunmod_loaded) then -- crosshair
			-- djui_hud_set_color(0,0,0,255)
			-- djui_hud_render_rect((w2*0.5) - 6,(h2*0.5) - 1,11,3)
			-- djui_hud_render_rect((w2*0.5) - 2,(h2*0.5) - 5,3,11)
			
			djui_hud_set_color(255,255,255,255)
			djui_hud_render_rect((w2*0.5) - 5,(h2*0.5),9,1)
			djui_hud_render_rect((w2*0.5) - 1,(h2*0.5) - 4,1,9)
		end
		last_hspeed = hspeed
	end
end

function allow_pvp(m,v) 
	if (intFix > 0) then return end
	if (m.action == ACT_DM_AIR_MOVEMENT or m.action == ACT_DM_AIR_MOVEMENT_METAL or m.action == ACT_DM_WATER_MOVEMENT) then
		return false
	end
end

function on_object_render(o) 
	if (get_id_from_behavior(o.behavior) == id_bhvMario) then
		local m = gMarioStates[0]
		if (o == m.marioObj) then
			o.header.gfx.shadowInvisible = true
			o.header.gfx.disableAutomaticShadowPos = true
			local flag = cutsceneActns[m.action] ~= 1
			if (m.heldObj ~= nil and flag) then
				local cYaw = m.area.camera.yaw + 0x8000
				local fA = m.faceAngle.y + 0x4000
			
				local offsetX_FaceAngle = 40 * sins(fA)
				local offsetZ_FaceAngle = 40 * coss(fA)
				
				local factorY_CameraAngle = sins(gLakituState.oldPitch)
				
				local offsetX_CameraAngle_Fixup = (sins(cYaw)) * factorY_CameraAngle
				local offsetZ_CameraAngle_Fixup = (coss(cYaw)) * factorY_CameraAngle
				
				local finalOffsetX = offsetX_FaceAngle + offsetX_CameraAngle_Fixup
				local finalOffsetY = -60
				local finalOffsetZ = offsetZ_FaceAngle + offsetZ_CameraAngle_Fixup
				
			
				m.marioObj.header.gfx.pos.x = m.marioBodyState.heldObjLastPosition.x + finalOffsetX
				m.marioObj.header.gfx.pos.y = m.marioBodyState.heldObjLastPosition.y + finalOffsetY
				m.marioObj.header.gfx.pos.z = m.marioBodyState.heldObjLastPosition.z + finalOffsetZ
			elseif (m.heldObj == nil and m.heldByObj ~= nil and flag) then
				vec3f_copy(m.pos,m.marioObj.header.gfx.pos)
			end
		end
	end
end

-- Temporary hack while I figure out how to deal with this
local mod_storage_version = 1

function create_default_sm64hlmov_config()
	mod_storage_save_bool("default.ss",DefaultSettings.stickySlope) -- sticky slope
	mod_storage_save_bool("default.gp",DefaultSettings.groundPound) -- ground pound
	mod_storage_save_bool("default.wj",DefaultSettings.wallJump) -- wall jump
	mod_storage_save_bool("default.i",DefaultSettings.interact) -- interact
	mod_storage_save_bool("default.as",DefaultSettings.autoStrafe) -- auto strafe
	mod_storage_save_bool("default.eb",DefaultSettings.ebrake) -- e-brake
	mod_storage_save_bool("default.ah",DefaultSettings.autoHop) -- auto hop
	mod_storage_save_number("default.j",DefaultSettings.jumpHeight) -- jump height 
	mod_storage_save_number("default.f",DefaultSettings.friction) -- friction
	mod_storage_save_number("default.s",DefaultSettings.speed) -- speed
	mod_storage_save_number("default.aa",DefaultSettings.airAcceleration) -- air acceleration
	mod_storage_save_number("default.a",DefaultSettings.acceleration) -- accelerate
	mod_storage_save_number("default.ac",DefaultSettings.airClamp) -- air clamp
	mod_storage_save_number("default.g",DefaultSettings.gravity) -- gravity
	mod_storage_save_number("default.efm",DefaultSettings.edgeFrictionMultiplier) -- edge friction multiplier
	mod_storage_save_number("default.efgo",DefaultSettings.efGroundOffset) -- edge friction ground offset
	mod_storage_save_number("default.effcd",DefaultSettings.efForwardCheckDistance) -- edge friction forward check distance
	mod_storage_save_number("default.efdcd",DefaultSettings.efDownCheckDistance) -- edge friction downwards check distance
	mod_storage_save_number("default.ebm",DefaultSettings.ebrakeFrictionMultiplier) -- e-brak friction multiplier

	mod_storage_save_number("default.msv",mod_storage_version)
end

function load_config(config)
	if (mod_storage_load_number(config .. ".s") ~= nil and mod_storage_load_number(config .. ".s") > 0) then
		gGlobalSyncTable.Convar_Gravity = safe_load_number(config .. ".g", DefaultSettings.gravity)
		gGlobalSyncTable.Convar_Accelerate = safe_load_number(config .. ".a", DefaultSettings.acceleration)
		gGlobalSyncTable.Convar_AirAccelerate = safe_load_number(config .. ".aa", DefaultSettings.airAcceleration)
		gGlobalSyncTable.Convar_AirClamp = safe_load_number(config .. ".ac", DefaultSettings.airClamp)
		gGlobalSyncTable.Convar_PlayerSpeed = safe_load_number(config .. ".s", DefaultSettings.speed)
		gGlobalSyncTable.Convar_PlayerFriction = safe_load_number(config .. ".f", DefaultSettings.friction)
		gGlobalSyncTable.Convar_PlayerJumpHeight = safe_load_number(config .. ".j", DefaultSettings.jumpHeight)
		gGlobalSyncTable.Convar_PlayerAllow_GroundPound = safe_load_bool(config .. ".gp", DefaultSettings.groundPound)
		gGlobalSyncTable.Convar_PlayerAllow_WallJump = safe_load_bool(config .. ".wj", DefaultSettings.wallJump)
		gGlobalSyncTable.Convar_PlayerAllow_Interact = safe_load_bool(config .. ".i", DefaultSettings.interact)
		gGlobalSyncTable.Convar_StickySlope = safe_load_bool(config .. ".ss", DefaultSettings.stickySlope)
		gFirstPersonCamera.centerL = safe_load_bool(config .. ".as", DefaultSettings.autoStrafe)
		gGlobalSyncTable.Convar_PlayerAutoHop = safe_load_bool(config .. ".ah", DefaultSettings.autoHop)
		gGlobalSyncTable.Convar_EdgeFrictionMultiplier = safe_load_number(config .. ".efm", DefaultSettings.edgeFrictionMultiplier)
		gGlobalSyncTable.Convar_EdgeFrictionGroundOffset = safe_load_number(config .. ".efgo", DefaultSettings.efGroundOffset)
		gGlobalSyncTable.Convar_EdgeFrictionForwardCheckDistance = safe_load_number(config .. ".effcd", DefaultSettings.efForwardCheckDistance)
		gGlobalSyncTable.Convar_EdgeFrictionDownCheckDistance = safe_load_number(config .. ".efdcd", DefaultSettings.efDownCheckDistance)
		djui_chat_message_create("\\#A0FFE0\\Loaded config: " .. config)

		-- Temporary hack while I figure out how to deal with this
		if (mod_storage_load_number(config .. ".msv") == nil or mod_storage_load_number(config .. ".msv") < 1) then
			gGlobalSyncTable.Convar_PlayerAutoHop = true -- Set autohop default true
			save_config(config)
		end
	elseif (mod_storage_load_number("default.s") ~= nil and mod_storage_load_number("default.s") > 0) then
		djui_chat_message_create("\\#A0FFE0\\CANNOT FIND CONFIG: " .. config)
		load_config("default")
	else
		djui_chat_message_create("\\#A0FFE0\\CANNOT FIND CONFIG: " .. config)
		create_default_sm64hlmov_config()
		load_config("default")
	end	
end

function save_config(config)
	mod_storage_save_bool(config .. ".ss",gGlobalSyncTable.Convar_StickySlope) 
	mod_storage_save_bool(config .. ".gp",gGlobalSyncTable.Convar_PlayerAllow_GroundPound) 
	mod_storage_save_bool(config .. ".wj",gGlobalSyncTable.Convar_PlayerAllow_WallJump) 
	mod_storage_save_bool(config .. ".i",gGlobalSyncTable.Convar_PlayerAllow_Interact) 
	mod_storage_save_bool(config .. ".ah",gGlobalSyncTable.Convar_PlayerAutoHop)
	mod_storage_save_bool(config .. ".eb",gGlobalSyncTable.Convar_EBrakeEnabled)
	mod_storage_save_number(config .. ".j",gGlobalSyncTable.Convar_PlayerJumpHeight) 
	mod_storage_save_number(config .. ".f",gGlobalSyncTable.Convar_PlayerFriction) 
	mod_storage_save_number(config .. ".s",gGlobalSyncTable.Convar_PlayerSpeed)
	mod_storage_save_number(config .. ".aa",gGlobalSyncTable.Convar_AirAccelerate)
	mod_storage_save_number(config .. ".a",gGlobalSyncTable.Convar_Accelerate)
	mod_storage_save_number(config .. ".ac",gGlobalSyncTable.Convar_AirClamp)
	mod_storage_save_number(config .. ".g",gGlobalSyncTable.Convar_Gravity)
	mod_storage_save_number(config .. ".as",gFirstPersonCamera.centerL)
	mod_storage_save_number(config .. ".efm",gGlobalSyncTable.Convar_EdgeFrictionMultiplier)
	mod_storage_save_number(config .. ".efgo",gGlobalSyncTable.Convar_EdgeFrictionGroundOffset)
	mod_storage_save_number(config .. ".effcd",gGlobalSyncTable.Convar_EdgeFrictionForwardCheckDistance)
	mod_storage_save_number(config .. ".efdcd",gGlobalSyncTable.Convar_EdgeFrictionDownCheckDistance)
	mod_storage_save_number(config .. ".ebm",gGlobalSyncTable.Convar_EBrakeFrictionMultiplier)
	mod_storage_save_number(config .. ".msv",mod_storage_version)
end

local modLoad = false
function on_level_init()
	gFirstPersonCamera.offset.y = sv_camerayoffset
	gLakituState.roll = 0
	cl_red = 0
	intFix = 10
	local lastList = 0
	local obj = obj_get_first(ObjectLists[lastList])
	while obj ~= nil do
		obj.header.gfx.skipInViewCheck = true
		local nextObj = obj_get_next(obj)
		if (nextObj == nil) then
			while nextObj == nil and lastList < 9 do
				lastList = lastList + 1
				nextObj = obj_get_first(ObjectLists[lastList])
			end
		end
		obj = nextObj
	end
	
	
	if (not modLoad) then
        djui_chat_message_create("\\#FFE0A0\\Welcome to \\#FFAA00\\mQuake\\#FFE0A0\\!\nPlease check the list of commands with '/mq list'.")
	end
	
	if (not modLoad and network_is_server()) then
        djui_chat_message_create("\\#A0FFE0\\Please check the server settings with '/mq_server list'.")
		-- Create a default profile with sm64hlmov settings if it doesn't exist already
		if (mod_storage_load_number("default.s") == nil or mod_storage_load_number("default.s") == 0.0) then
			create_default_sm64hlmov_config()
		end

		-- Load default profile
		if (mod_storage_load_number("default.s") ~= nil) then	
			load_config("default")
			-- Print a couple important convars for verification purposes. We can only really print a couple visible lines here
			djui_chat_message_create("\\#A0FFE0\\MQ Edge Friction Multiplier: " .. gGlobalSyncTable.Convar_EdgeFrictionMultiplier)
			djui_chat_message_create("\\#A0FFE0\\MQ Air Clamp: " .. gGlobalSyncTable.Convar_AirClamp)
			djui_chat_message_create("\\#A0FFE0\\MQ Jump Height: " .. gGlobalSyncTable.Convar_PlayerJumpHeight)
			djui_chat_message_create("\\#A0FFE0\\MQ Gravity: " .. gGlobalSyncTable.Convar_Gravity)
			djui_chat_message_create("\\#A0FFE0\\MQ Accelerate: " .. gGlobalSyncTable.Convar_Accelerate)
			djui_chat_message_create("\\#A0FFE0\\MQ Air Accelerate: " .. gGlobalSyncTable.Convar_AirAccelerate)
			djui_chat_message_create("\\#A0FFE0\\MQ Player Speed: " .. gGlobalSyncTable.Convar_PlayerSpeed)
			djui_chat_message_create("\\#A0FFE0\\MQ Player Friction: " .. gGlobalSyncTable.Convar_PlayerFriction)
			djui_chat_message_create("\\#A0FFE0\\MQ Auto Strafe: " .. tostring(gFirstPersonCamera.centerL))
		end
	end
	
	modLoad = true
end
function local_update(m) 
	if (m == nil) then return true end

	-- Make ABSOLUTELY CERTAIN the configs aren't buggered
	if (gGlobalSyncTable.Convar_PlayerSpeed <= 0) then
		load_config("default")
	end
	
	if (m.health <= 0xFF) then
		gFirstPersonCamera.offset.y = -110
		gLakituState.roll = 0
		m.invincTimer = 0
		cl_red = 192
		return false
	end
	
	if (cl_airstrafelimiter > 0) then
		cl_airstrafelimiter = cl_airstrafelimiter * 0.95
		if (cl_airstrafelimiter <= 0.1) then cl_airstrafelimiter = 0 end 
	end
	
	local btnDown = m.controller.buttonDown
	local btnPressed = m.controller.buttonPressed
	-- if (cl_interacttimer > 0) then cl_interacttimer = cl_interacttimer - 1 end
	if (cl_red > 0) then cl_red = cl_red - 32 end

	m.marioObj.hookRender = 1
	
	if (m.heldObj ~= nil) then
		held_obj_update(m)
	end
	
	if (m.usedObj ~= nil and cl_toadTalkedTo and no_dialog_open()) then
		m.usedObj.oToadMessageState = 4
		m.usedObj = nil
		cl_toadTalkedTo = false
	end
	
	if (DM_ACTION_QPHYS[m.action] == 1) then
		if (m.controller.buttonDown & B_BUTTON) ~= 0 and (m.flags & MARIO_UNKNOWN_31) == 0 then
			m.flags = m.flags | MARIO_UNKNOWN_31
		elseif (m.flags & MARIO_UNKNOWN_31) ~= 0 then
			m.flags = m.flags & ~MARIO_UNKNOWN_31
		end
	end
	
	if (cl_bowserthrow) then 
		cl_bowserthrow_previousYaw = m.faceAngle.y
		cl_bowserthrow = m.heldObj ~= nil 
		m.faceAngle.y = m.area.camera.yaw + 0x8000
	end
	
	SV_HandleSpecialFloors(m,false)
	
	local shouldCrouch = ((((m.controller.buttonDown & Z_TRIG) ~= 0 and m.health > 0xFF) or m.action == ACT_GROUND_POUND or m.action == ACT_DM_GROUND_POUND_METAL) and m.action ~= ACT_DM_WATER_MOVEMENT) or (gPlayerSyncTable[m.playerIndex].playerCrouching and m.ceilHeight < m.pos.y + m.marioObj.hitboxHeight)
	if (DM_ACTION_FORCEANGLE[m.action] ~= nil and not cl_bowserthrow) then 
		m.faceAngle.y = m.area.camera.yaw + (0x8000*DM_ACTION_FORCEANGLE[m.action])
	end
	
	if (DM_ACTIONS_CROUCHAIR[m.action] == 1) then
		if (shouldCrouch ~= gPlayerSyncTable[m.playerIndex].playerCrouching) then
			if (shouldCrouch) then 
				m.pos.y = m.pos.y + sv_crouchoffset 
			else 
				if (m.pos.y - sv_crouchoffset < m.floorHeight) then
					m.pos.y = m.floorHeight
				else
					m.pos.y = m.pos.y - sv_crouchoffset 
				end
			end
		end
	end
	
	gPlayerSyncTable[m.playerIndex].playerCrouching = shouldCrouch
	
	if (m.action ~= ACT_SQUISHED) then gFirstPersonCamera.offset.y = ifelse(shouldCrouch, sv_camerayoffset-sv_crouchoffset, sv_camerayoffset) end
	
	-- if (m.health <= 0xFF) then
	gLakituState.roll = gLakituState.roll * 0.75
	if (DM_ACTIONS_ALLOWGRAB[m.action] == 1 and no_dialog_open() and sv_interact) then
		mario_handle_grab_and_punch_custom(m) 
	end
	-- end
	
	m.marioObj.hitboxHeight = ifelse(shouldCrouch, sv_playerheight-sv_crouchoffset, sv_playerheight)

	local warp = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvFadingWarp)
	if warp ~= nil and m.heldObj == nil and m.action ~= ACT_TELEPORT_FADE_OUT and m.action ~= ACT_TELEPORT_FADE_IN and obj_check_hitbox_overlap(m.marioObj, warp) and vec3f_length(m.vel) < sv_stopspeed and gPlayerSyncTable[m.playerIndex].playerCrouching then
		m.interactObj = warp
		m.usedObj = warp
		m.forwardVel = 0
		set_mario_action(m, ACT_TELEPORT_FADE_OUT, 0)
		m.controller.buttonDown = btnDown
		m.controller.buttonPressed = btnPressed
		frameCalculatedAngles = false
		return false
	end
	
	m.controller.buttonDown = btnDown
	m.controller.buttonPressed = btnPressed
	
	frameCalculatedAngles = false
	return true
end
function on_game_update(m) 
	local m = gMarioStates[0]
	
	if (m == nil) then return end
	m.peakHeight = m.pos.y
	
	local a = m.action
	
	if (DM_ACTION_DONT_OVERRIDE_FP[a] ~= 1) then set_first_person_enabled(true) end
	-- remove_cutscenes(m)
	
	gFirstPersonCamera.forceRoll = false
	gFirstPersonCamera.fov = cl_fov	
	
	if (a == ACT_SQUISHED and m.ceil ~= nil) then 
		gFirstPersonCamera.offset.y = m.ceilHeight - m.pos.y - 120
	end
	
	if (intFix > 0) then intFix = intFix -1 end
end


--- commands
function mquake(msg)
    if msg == 'list' then
        djui_chat_message_create("\\#FFE0A0\\'/mq alt_walljump [on/off]'\\#FFFFFF\\ - Set alternate walljump key (Holding B)")
        djui_chat_message_create("\\#FFE0A0\\'/mq predict [on/off]'\\#FFFFFF\\ - Set prediction for acceleration")
        djui_chat_message_create("\\#FFE0A0\\'/mq moveset'\\#FFFFFF\\ - A short tutorial on the moveset")
        djui_chat_message_create("\\#FFE0A0\\'/mq fov [45-120]'\\#FFFFFF\\ - Set the FOV")
        return true
    elseif msg == 'alt_walljump off' then
        djui_chat_message_create("\\#FFE0A0\\Alternative Walljump Key:\\#FF1414\\ Off")
		mod_storage_save_bool("mq_altwallj",false)
		cl_altWalljumpKey = false
        return true
    elseif msg == 'predict off' then
        djui_chat_message_create("\\#FFE0A0\\Acceleration Prediction:\\#FF1414\\ Off")
		mod_storage_save_bool("mq_accelpred",true) 
		cl_disableAccelPred = true
        return true
    elseif msg == 'alt_walljump on' then
        djui_chat_message_create("\\#FFE0A0\\Alternative Walljump Key:\\#14FF14\\ On")
		mod_storage_save_bool("mq_altwallj",true)
		cl_altWalljumpKey = true
        return true
    elseif msg == 'predict on' then
        djui_chat_message_create("\\#FFE0A0\\Acceleration Prediction:\\#14FF14\\ On")
		mod_storage_save_bool("mq_accelpred",true) 
		cl_disableAccelPred = true
        return true
    elseif msg == 'moveset' then
        djui_chat_message_create("\\#FFE0A0\\Ground Pound - \\#FFFFFF\\Let go of (A) and press [Z] to start a ground pound.\nPressing [Z] again will cancell all horizontal velocity, sending you straight down!")
        djui_chat_message_create("\\#FFE0A0\\Ground Pound Jump - \\#FFFFFF\\Hold (A) after starting a ground pound to ground pound jump when you land. \nThis converts some velocity to upwards momentum while carrying the rest!")
        djui_chat_message_create("\\#FFE0A0\\Crouch Jump - \\#FFFFFF\\Continue to hold (A) after jumping then press and hold [Z] to stay in the air longer and land on higher up platforms!")
        djui_chat_message_create("\\#FFE0A0\\Interacting - \\#FFFFFF\\Pressing (B) will interact with objects.\nLook at the object you wish to either punch, grab or talk to and press (B).\nHolding (B) will let you push metal boxes around and grab trees or poles!")
        djui_chat_message_create("\\#FFE0A0\\Throwing Bowser - \\#FFFFFF\\To throw bowser, flick your view to the left or right and press (B)!")
        return true
    end
	
	local space = string.find(msg,' ')
	if (space == nil or space < 1) then return end
	local args = {[1]=string.sub(msg,1,space-1),[2]=string.sub(msg,-(string.len(msg)-space))}
	
	if (args[2] == nil or args[2] == "") then return false end
	if (args[1] == nil or args[1] == "") then return false end
	
	if args[1] == "fov" and args[2] ~= nil then
		cl_fov = clampf(tonumber(args[2]),45,120)
		mod_storage_save_number("mq_fov",cl_fov) 
		return true
	end
    return false
end

if (network_is_server()) then
	function mquake_server(msg)
		if msg == 'list' then
			djui_chat_message_create("\\#A0FFE0\\'/mq_server StickySlope [on/off]'\\#FFFFFF\\ - Default is off")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server Accelerate [value]'\\#FFFFFF\\ - Default is 10")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server AirAccelerate [value]'\\#FFFFFF\\ - Default is 10")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server AirClamp [value]'\\#FFFFFF\\ - Default is 30")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server Gravity [value]'\\#FFFFFF\\ - Default is 800")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server PlayerSpeed [value]'\\#FFFFFF\\ - Default is 1.0")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server PlayerFriction [value]'\\#FFFFFF\\ - Default is 1.0")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server EdgeFrictionMultiplier [value]'\\#FFFFFF\\ - Default is 1.5")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server PlayerJumpHeight [value]'\\#FFFFFF\\ - Default is 1.0")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server EBrake [on/off]'\\#FFFFFF\\ - Default is on")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server EBrakeFrictionMultiplier [value]'\\#FFFFFF\\ - Default is 2.0")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server GroundPound [on/off]'\\#FFFFFF\\ - Default is on")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server WallJump [on/off]'\\#FFFFFF\\ - Default is on")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server Interact [on/off]'\\#FFFFFF\\ - Default is on")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server AutoStrafe [on/off]'\\#FFFFFF\\ - Default is off")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server SaveConfig [name]'\\#FFFFFF\\ - Save the current server settings to mod storage ")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server LoadConfig [name]'\\#FFFFFF\\ - Load settings from mod storage")
			djui_chat_message_create("\\#A0FFE0\\'/mq_server DeleteConfig [name]'\\#FFFFFF\\ - Delete settings from mod storage")
			return true	
		end
		
		local space = string.find(msg,' ')
		if (space == nil or space < 1) then return end
		local args = {[1]=string.sub(msg,1,space-1),[2]=string.sub(msg,-(string.len(msg)-space))}
		
		if (args[2] == nil or args[2] == "") then return false end
		if (args[1] == nil or args[1] == "") then return false end
		
		if args[1] == "StickySlope" and args[2] ~= nil then
			gGlobalSyncTable.Convar_StickySlope = args[2]=="on"
			djui_chat_message_create("\\#A0FFE0\\StickySlope changed to " .. tostring(gGlobalSyncTable.Convar_StickySlope))
			return true
		end
		if args[1] == "AutoStrafe" and args[2] ~= nil then
			gFirstPersonCamera.centerL = args[2]=="on"
			djui_chat_message_create("\\#A0FFE0\\AutoStrafe changed to " .. tostring(gFirstPersonCamera.centerL))
			return true
		end
		if args[1] == "AutoHop" and args[2] ~= nil then
			gGlobalSyncTable.Convar_PlayerAutoHop = args[2]=="on"
			djui_chat_message_create("\\#A0FFE0\\AutoHop changed to " .. tostring(gGlobalSyncTable.Convar_PlayerAutoHop))
			return true
		end
		if args[1] == "Accelerate" and args[2] ~= nil then
			gGlobalSyncTable.Convar_Accelerate = tonumber(args[2])
			djui_chat_message_create("\\#A0FFE0\\Accelerate changed to " .. gGlobalSyncTable.Convar_Accelerate)
			return true
		end
		if args[1] == "AirAccelerate" and args[2] ~= nil then
			gGlobalSyncTable.Convar_AirAccelerate = tonumber(args[2])
			djui_chat_message_create("\\#A0FFE0\\AirAccelerate changed to " .. gGlobalSyncTable.Convar_AirAccelerate)
			return true
		end
		if args[1] == "AirClamp" and args[2] ~= nil then
			gGlobalSyncTable.Convar_AirClamp = tonumber(args[2])
			djui_chat_message_create("\\#A0FFE0\\AirClamp changed to " .. gGlobalSyncTable.Convar_AirClamp)
			return true
		end
		if args[1] == "Gravity" and args[2] ~= nil then
			gGlobalSyncTable.Convar_Gravity = tonumber(args[2])
			djui_chat_message_create("\\#A0FFE0\\Gravity changed to " .. gGlobalSyncTable.Convar_Gravity)
			return true
		end
		if args[1] == "PlayerSpeed" and args[2] ~= nil then
			gGlobalSyncTable.Convar_PlayerSpeed = tonumber(args[2])
			djui_chat_message_create("\\#A0FFE0\\PlayerSpeed changed to " .. gGlobalSyncTable.Convar_PlayerSpeed)
			return true
		end
		if args[1] == "PlayerFriction" and args[2] ~= nil then
			gGlobalSyncTable.Convar_PlayerFriction = tonumber(args[2])
			djui_chat_message_create("\\#A0FFE0\\PlayerFriction changed to " .. gGlobalSyncTable.Convar_PlayerFriction)
			return true
		end
		if args[1] == "EdgeFrictionMultiplier" and args[2] ~= nil then
			gGlobalSyncTable.Convar_EdgeFrictionMultiplier = tonumber(args[2])
			djui_chat_message_create("\\#A0FFE0\\EdgeFrictionMultiplier changed to " .. gGlobalSyncTable.Convar_EdgeFrictionMultiplier)
			return true
		end
		if args[1] == "EdgeFrictionGroundOffset" and args[2] ~= nil then
			gGlobalSyncTable.Convar_EdgeFrictionGroundOffset = tonumber(args[2])
			djui_chat_message_create("\\#A0FFE0\\EdgeFrictionGroundOffset changed to " .. gGlobalSyncTable.Convar_EdgeFrictionGroundOffset)
			return true
		end
		if args[1] == "EdgeFrictionForwardCheckDistance" and args[2] ~= nil then
			gGlobalSyncTable.Convar_EdgeFrictionForwardCheckDistance = tonumber(args[2])
			djui_chat_message_create("\\#A0FFE0\\EdgeFrictionForwardCheckDistance changed to " .. gGlobalSyncTable.Convar_EdgeFrictionForwardCheckDistance)
			return true
		end
		if args[1] == "EdgeFrictionDownCheckDistance" and args[2] ~= nil then
			gGlobalSyncTable.Convar_EdgeFrictionDownCheckDistance = tonumber(args[2])
			djui_chat_message_create("\\#A0FFE0\\EdgeFrictionDownCheckDistance changed to " .. gGlobalSyncTable.Convar_EdgeFrictionDownCheckDistance)
			return true
		end
		if args[1] == "EBrake" and args[2] ~= nil then
			gGlobalSyncTable.Convar_EBrakeEnabled = args[2]=="on"
			djui_chat_message_create("\\#A0FFE0\\EBrakeEnabled changed to " .. tostring(gGlobalSyncTable.Convar_EdgeFrictionMultiplier))
			return true
		end
		if args[1] == "EBrakeFrictionMultiplier" and args[2] ~= nil then
			gGlobalSyncTable.Convar_EBrakeFrictionMultiplier = tonumber(args[2])
			djui_chat_message_create("\\#A0FFE0\\EBrakeFrictionMultiplier changed to " .. gGlobalSyncTable.Convar_EBrakeFrictionMultiplier)
			return true
		end
		if args[1] == "PlayerJumpHeight" and args[2] ~= nil then
			gGlobalSyncTable.Convar_PlayerJumpHeight = tonumber(args[2])
			djui_chat_message_create("\\#A0FFE0\\PlayerJumpHeight changed to " .. gGlobalSyncTable.Convar_PlayerJumpHeight)
			return true
		end
		if args[1] == "GroundPound" and args[2] ~= nil then
			gGlobalSyncTable.Convar_PlayerAllow_GroundPound = args[2]=="on"
			djui_chat_message_create("\\#A0FFE0\\GroundPound changed to " .. tostring(gGlobalSyncTable.Convar_PlayerAllow_GroundPound))
			return true
		end
		if args[1] == "WallJump" and args[2] ~= nil then
			gGlobalSyncTable.Convar_PlayerAllow_WallJump = args[2]=="on"
			djui_chat_message_create("\\#A0FFE0\\WallJump changed to " .. tostring(gGlobalSyncTable.Convar_PlayerAllow_WallJump))
			return true
		end
		if args[1] == "Interact" and args[2] ~= nil then
			gGlobalSyncTable.Convar_PlayerAllow_Interact = args[2]=="on"
			djui_chat_message_create("\\#A0FFE0\\Interact changed to " .. tostring(gGlobalSyncTable.Convar_PlayerAllow_Interact))
			return true
		end
		
		if args[1] == "SaveConfig" and args[2] ~= nil then
			save_config(args[2])
			djui_chat_message_create("\\#A0FFE0\\Saved settings to '" .. args[2] .. "'")
			return true
		end
		
		if args[1] == "LoadConfig" and args[2] ~= nil then
			load_config(args[2])
			return true
		end

		if args[1] == "DeleteConfig" and args[2] == "default" then
			create_default_sm64hlmov_config()
			djui_chat_message_create("\\#A0FFE0\\Restored default config")
			load_config("default")
			return true
		elseif args[1] == "DeleteConfig" and args[2] ~= nil then
			if (mod_storage_load_number(args[2] .. ".s") ~= nil) then
				mod_storage_remove(args[2] .. ".s") -- TODO: since keys are limited, we should delete all of them
				djui_chat_message_create("\\#A0FFE0\\Deleted config '" .. args[2] .. "'")
				return true
			else
				djui_chat_message_create("\\#A0FFE0\\No config found '" .. args[2] .. "'")
				return true
			end
		end
	end
else
	function mquake_server(msg)
		return false
	end
end