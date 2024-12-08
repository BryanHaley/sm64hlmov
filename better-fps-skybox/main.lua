-- name: Better FPS Skybox
-- incompatible: Day Night Cycle DX
-- description: Cut down version of Day Night Cycle DX just to give better skyboxes in FPS mode

DNC_HOOK_SET_LIGHTING_COLOR = 0
DNC_HOOK_SET_AMBIENT_LIGHTING_COLOR = 1
DNC_HOOK_SET_LIGHTING_DIR = 2
DNC_HOOK_SET_FOG_COLOR = 3
DNC_HOOK_SET_FOG_INTENSITY = 4
DNC_HOOK_SET_DISPLAY_TIME_COLOR = 5
DNC_HOOK_SET_DISPLAY_TIME_POS = 6
DNC_HOOK_DELETE_AT_DARK = 7
DNC_HOOK_SET_TIME = 8
DNC_HOOK_SET_SKYBOX_MODEL = 9

SKYBOX_SCALE = 600

local sDncHooks = {
    [DNC_HOOK_SET_LIGHTING_COLOR] = {},
    [DNC_HOOK_SET_AMBIENT_LIGHTING_COLOR] = {},
    [DNC_HOOK_SET_LIGHTING_DIR] = {},
    [DNC_HOOK_SET_FOG_COLOR] = {},
    [DNC_HOOK_SET_FOG_INTENSITY] = {},
    [DNC_HOOK_SET_DISPLAY_TIME_COLOR] = {},
    [DNC_HOOK_SET_DISPLAY_TIME_POS] = {},
    [DNC_HOOK_DELETE_AT_DARK] = {},
    [DNC_HOOK_SET_TIME] = {},
    [DNC_HOOK_SET_SKYBOX_MODEL] = {}
}

--- @param hookEventType integer
local function dnc_call_hook(hookEventType, ...)
    if sDncHooks[hookEventType] == nil then return end
    local ret = nil
    for hook in ipairs(sDncHooks[hookEventType]) do
        ret = sDncHooks[hookEventType][hook](...)
    end
    return ret
end

--- @param o Object
function bhv_dnc_skybox_init(o)
    o.header.gfx.skipInViewCheck = true
    set_override_far(200000)
end

--- @param o Object
function bhv_dnc_skybox_loop(o)

    vec3f_to_object_pos(o, gLakituState.pos)

    local skybox = get_skybox()

    -- do not rotate BITDW skybox
    if skybox == BACKGROUND_GREEN_SKY then return end

    local minutes = 480

    o.oFaceAngleYaw = (minutes / 24) * 0x10000
end

local function update()
    local skybox = get_skybox()
    local i = 0
    if skybox >= BACKGROUND_CUSTOM then skybox = BACKGROUND_OCEAN_SKY end
    if obj_get_first_with_behavior_id(bhvDNCSkybox) == nil and skybox ~= -1 and obj_get_first_with_behavior_id(bhvDNCNoSkybox) == nil then
        -- djui_chat_message_create("Spawning skybox");
        local model = smlua_model_util_get_id("dnc_skybox_geo")
        lastSkyBox = skybox
        local overrideModel = dnc_call_hook(DNC_HOOK_SET_SKYBOX_MODEL, i, skybox)
        if overrideModel ~= nil and type(overrideModel) == "number" then model = overrideModel end

        spawn_non_sync_object(
            bhvDNCSkybox,
            model,
            0, 0, 0,
            --- @param o Object
            function(o)
                o.oBehParams2ndByte = i
                o.oAnimState = skybox
                obj_scale(o, SKYBOX_SCALE - 10 * i)
            end
        )
    end
end

hook_event(HOOK_UPDATE, update)