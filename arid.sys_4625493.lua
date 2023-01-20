_DEBUG = true
--start ffi region#--
--ui.get_style("Button")

local gradient = require("neverlose/gradient")
local clipboard = require("neverlose/clipboard")
local base64 = require("neverlose/base64")
local color_p = require("neverlose/color_print")
local drag_system = require("neverlose/drag_system")
local timer = require("neverlose/timer")
local aa_library = require("neverlose/anti_aim")
local http_lib = require("neverlose/http_lib")
local discord_webhooks = require("neverlose/discord_webhooks")
local tbl = {}
local texts = render.measure_text
local aridfunc = {}
local arid = {}
local x, y = render.screen_size().x, render.screen_size().y
local urlmon = ffi.load 'UrlMon'
local wininet = ffi.load 'WinInet'
width_ka5 = 0
drag2 = false
drag3 = false
drag4 = false


local lerp = function(time,a,b)
    return a * (1-time) + b * time
end


local function render_gradient_text(r1, g1, b1, a1, r2, g2, b2, a2, text)
    local output = ''
    local len = #text-1
    local rinc = (r2 - r1) / len
    local ginc = (g2 - g1) / len
    local binc = (b2 - b1) / len
    local ainc = (a2 - a1) / len
    for i=1, len+1 do
        output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, text:sub(i, i))
        r1 = r1 + rinc
        g1 = g1 + ginc
        b1 = b1 + binc
        a1 = a1 + ainc
    end

    return output
end

ffi_handlers = {

    bind_argument = function(fn, arg)
        return function(...)
            return fn(arg, ...)
        end
    end,
    

    open_link = function (link)
        local steam_overlay_API = panorama.SteamOverlayAPI
        local open_external_browser_url = steam_overlay_API.OpenExternalBrowserURL
        open_external_browser_url(link)
    end,


}

ffi.cdef[[
    typedef void*(__thiscall* get_client_entity_t)(void*, int);
    typedef uintptr_t (__thiscall* GetClientEntity_4242425_t)(void*, int);
    int VirtualFree(void* lpAddress, unsigned long dwSize, unsigned long dwFreeType);
    void* VirtualAlloc(void* lpAddress, unsigned long dwSize, unsigned long  flAllocationType, unsigned long flProtect);
    int VirtualProtect(void* lpAddress, unsigned long dwSize, unsigned long flNewProtect, unsigned long* lpflOldProtect);


    typedef struct
    {
        float x;
        float y;
        float z;
    } Vector_t;

    typedef struct {
        unsigned short wYear;
        unsigned short wMonth;
        unsigned short wDayOfWeek;
        unsigned short wDay;
        unsigned short wHour;
        unsigned short wMinute;
        unsigned short wSecond;
        unsigned short wMilliseconds;
    } SYSTEMTIME, *LPSYSTEMTIME;
    void GetSystemTime(LPSYSTEMTIME lpSystemTime);
    void GetLocalTime(LPSYSTEMTIME lpSystemTime);

    
    typedef struct
    {
        char    pad0[0x60]; // 0x00
        void* pEntity; // 0x60
        void* pActiveWeapon; // 0x64
        void* pLastActiveWeapon; // 0x68
        float        flLastUpdateTime; // 0x6C
        int            iLastUpdateFrame; // 0x70
        float        flLastUpdateIncrement; // 0x74
        float        flEyeYaw; // 0x78
        float        flEyePitch; // 0x7C
        float        flGoalFeetYaw; // 0x80
        float        flLastFeetYaw; // 0x84
        float        flMoveYaw; // 0x88
        float        flLastMoveYaw; // 0x8C // changes when moving/jumping/hitting ground
        float        flLeanAmount; // 0x90
        char    pad1[0x4]; // 0x94
        float        flFeetCycle; // 0x98 0 to 1
        float        flMoveWeight; // 0x9C 0 to 1
        float        flMoveWeightSmoothed; // 0xA0
        float        flDuckAmount; // 0xA4
        float        flHitGroundCycle; // 0xA8
        float        flRecrouchWeight; // 0xAC
        Vector_t        vecOrigin; // 0xB0
        Vector_t        vecLastOrigin;// 0xBC
        Vector_t        vecVelocity; // 0xC8
        Vector_t        vecVelocityNormalized; // 0xD4
        Vector_t        vecVelocityNormalizedNonZero; // 0xE0
        float        flVelocityLenght2D; // 0xEC
        float        flJumpFallVelocity; // 0xF0
        float        flSpeedNormalized; // 0xF4 // clamped velocity from 0 to 1
        float        flRunningSpeed; // 0xF8
        float        flDuckingSpeed; // 0xFC
        float        flDurationMoving; // 0x100
        float        flDurationStill; // 0x104
        bool        bOnGround; // 0x108
        bool        bHitGroundAnimation; // 0x109
        char    pad2[0x2]; // 0x10A
        float        flNextLowerBodyYawUpdateTime; // 0x10C
        float        flDurationInAir; // 0x110
        float        flLeftGroundHeight; // 0x114
        float        flHitGroundWeight; // 0x118 // from 0 to 1, is 1 when standing
        float        flWalkToRunTransition; // 0x11C // from 0 to 1, doesnt change when walking or crouching, only running
        char    pad3[0x4]; // 0x120
        float        flAffectedFraction; // 0x124 // affected while jumping and running, or when just jumping, 0 to 1
        char    pad4[0x208]; // 0x128
        float        flMinBodyYaw; // 0x330
        float        flMaxBodyYaw; // 0x334
        float        flMinPitch; //0x338
        float        flMaxPitch; // 0x33C
        int            iAnimsetVersion; // 0x340
    } CCSGOPlayerAnimationState_534535_t;
    
    void* __stdcall URLDownloadToFileA(void* LPUNKNOWN, const char* LPCSTR, const char* LPCSTR2, int a, int LPBINDSTATUSCALLBACK);

    bool DeleteUrlCacheEntryA(const char* lpszUrlName);
]]
local engine_client = ffi.cast(ffi.typeof('void***'), utils.create_interface('engine.dll', 'VEngineClient014'))
local console_is_visible = ffi.cast(ffi.typeof('bool(__thiscall*)(void*)'), engine_client[0][11])

local function current_time()
    local local_time = ffi.new("SYSTEMTIME")
    ffi.C.GetLocalTime(local_time)
    return ("%02d:%02d:%02d"):format(local_time.wHour, local_time.wMinute, local_time.wSecond)
end

entity_list_pointer = ffi.cast('void***', utils.create_interface('client.dll', 'VClientEntityList003'))
get_client_entity_fn = ffi.cast('GetClientEntity_4242425_t', entity_list_pointer[0][3])
function get_entity_address(ent_index)
    local addr = get_client_entity_fn(entity_list_pointer, ent_index)
    return addr
end

function aridfunc:contains(list, x)
	for _, v in pairs(list) do
		if v == x then return true end
	end
	return false
end
function aridfunc:get_neverlose_path()
    return common.get_game_directory():sub(1, -5) .. "nl\\"
end

function aridfunc:Download(from, to)
    wininet.DeleteUrlCacheEntryA(from)
    urlmon.URLDownloadToFileA(nil, from, to, 0,0)
end
function aridfunc:file_exists(file, path_id)
    local func_file_exists = ffi.cast("bool (__thiscall*)(void*, const char*, const char*)", ffi.cast(ffi.typeof("void***"), utils.create_interface("filesystem_stdio.dll", "VBaseFileSystem011"))[0][10])
    return func_file_exists(ffi.cast(ffi.typeof("void***"), utils.create_interface("filesystem_stdio.dll", "VBaseFileSystem011")), file, path_id)
end

files.create_folder(aridfunc:get_neverlose_path().."arid\\")

if not aridfunc:file_exists(aridfunc:get_neverlose_path().."arid\\smallest_pixel-7.tff", "GAME") then
	aridfunc:Download('https://github.com/fakeangle/neverlose_bettervisuals/blob/main/smallest_pixel-7.ttf?raw=true', aridfunc:get_neverlose_path().."arid\\smallest_pixel-7.tff")
end


if not aridfunc:file_exists(aridfunc:get_neverlose_path().."arid\\Astronomy.ttf", "GAME") then
	aridfunc:Download('https://cdn.discordapp.com/attachments/1061023248365666314/1061369634391068762/Astronomy.ttf', aridfunc:get_neverlose_path().."arid\\Astronomy.ttf")
end

files.write(aridfunc:get_neverlose_path().."arid\\1", "W3RydWUsZmFsc2UsMTY2My4wLDEyOC4wLHRydWUsWyJPbiBkYW1hZ2UgZGVhbCJdLHRydWUsMTY1LjAsNDMzLjAsMjUwLjAsMjUwLjAsdHJ1ZSwiQ29uZGljdGlvbmFsIixbIlN0YXRpYyBsZWdzIGluIGFpciIsIkxlZ3MgZGlyZWN0aW9uIl0sWyJBbnRpLUJhY2tzdGFiIiwiRG9ybWFudCBBaW1ib3QiXSx0cnVlLHRydWUsdHJ1ZSx0cnVlLGZhbHNlLGZhbHNlLCJNb2Rlcm4iLDE3NjQuMCwyOC4wLHRydWUsIk1vZGVybiIsdHJ1ZSxbIlNjcmVlbiIsIkNvbnNvbGUiXSx0cnVlLDIxLjAsMi4wLHRydWUsdHJ1ZSx0cnVlLDkuMCxmYWxzZSxmYWxzZSw2OC4wLDIuNSwwLjAsLTEuNSx0cnVlLDUwLjAsNDAuMCx0cnVlLHRydWUsNy4wLC03LjAsIkNlbnRlciIsLTU2LjAsWyJKaXR0ZXIiXSwiT2ZmIiwiT3Bwb3NpdGUiLCJPcHBvc2l0ZSIsNjAuMCw2MC4wLHRydWUsLTYuMCw2LjAsIkNlbnRlciIsLTcwLjAsWyJKaXR0ZXIiXSwiT2ZmIiwiT3Bwb3NpdGUiLCJPcHBvc2l0ZSIsNjAuMCw2MC4wLHRydWUsNy4wLC03LjAsIkNlbnRlciIsLTczLjAsWyJKaXR0ZXIiXSwiT2ZmIiwiT3Bwb3NpdGUiLCJPcHBvc2l0ZSIsNTUuMCw1NS4wLHRydWUsOC4wLC04LjAsIkNlbnRlciIsLTY1LjAsWyJKaXR0ZXIiXSwiT2ZmIiwiT3Bwb3NpdGUiLCJPcHBvc2l0ZSIsNTQuMCw1NC4wLHRydWUsLTUuMCw1LjAsIkNlbnRlciIsLTI3LjAsWyJBdm9pZCBPdmVybGFwIiwiSml0dGVyIl0sIlBlZWsgRmFrZSIsIkZyZWVzdGFuZGluZyIsIk9wcG9zaXRlIiw2MC4wLDYwLjAsdHJ1ZSw3LjAsLTcuMCwiQ2VudGVyIiwtODAuMCxbIkppdHRlciJdLCJPZmYiLCJPcHBvc2l0ZSIsIk9wcG9zaXRlIiw1Ny4wLDU3LjAsdHJ1ZSw3LjAsLTcuMCwiQ2VudGVyIiwtNzQuMCxbIkppdHRlciJdLCJPZmYiLCJPcHBvc2l0ZSIsIk9wcG9zaXRlIiw1My4wLDU2LjAsdHJ1ZSwwLjAsMC4wLCJEaXNhYmxlZCIsMC4wLFtdLCJPZmYiLCJEZWZhdWx0IiwiRGlzYWJsZWQiLDYwLjAsNjAuMF0=")
files.write(aridfunc:get_neverlose_path().."arid\\2", "W3RydWUsdHJ1ZSwyOS4wLDUwOS4wLHRydWUsWyJPbiBkYW1hZ2UgZGVhbCJdLHRydWUsMTcxLjAsNTAzLjAsMTcyLjAsNjU4LjAsdHJ1ZSwiQ29uZGljdGlvbmFsIixbIlN0YXRpYyBsZWdzIGluIGFpciIsIkxlZ3MgZGlyZWN0aW9uIiwiWmVybyBwaXRjaCBvbiBsYW5kIl0sWyJBbnRpLUJhY2tzdGFiIiwiRG9ybWFudCBBaW1ib3QiLCJEaXNhYmxlIEFBIG9uIFdhcm11cCJdLHRydWUsdHJ1ZSx0cnVlLHRydWUsdHJ1ZSx0cnVlLCJNb2Rlcm4iLDIyLjAsNjc5LjAsdHJ1ZSwiTW9kZXJuIix0cnVlLFsiU2NyZWVuIiwiQ29uc29sZSJdLHRydWUsMjEuMCwyLjAsdHJ1ZSx0cnVlLHRydWUsMTMuMCx0cnVlLHRydWUsNjguMCwyLjUsMC4wLC0xLjUsdHJ1ZSw1MC4wLDQwLjAsdHJ1ZSx0cnVlLDcuMCwtNy4wLCJDZW50ZXIiLC01Ni4wLFsiSml0dGVyIl0sIk9mZiIsIk9wcG9zaXRlIiwiT3Bwb3NpdGUiLDYwLjAsNjAuMCx0cnVlLDkuMCw5LjAsIkNlbnRlciIsLTY5LjAsWyJKaXR0ZXIiXSwiT2ZmIiwiU3dpdGNoIiwiT3Bwb3NpdGUiLDYwLjAsNjAuMCx0cnVlLDcuMCwtNy4wLCJDZW50ZXIiLC03NC4wLFsiSml0dGVyIl0sIk9mZiIsIlN3aXRjaCIsIk9wcG9zaXRlIiw2MC4wLDYwLjAsdHJ1ZSw4LjAsLTguMCwiQ2VudGVyIiwtOS4wLFsiSml0dGVyIl0sIk9mZiIsIk9wcG9zaXRlIiwiT3Bwb3NpdGUiLDYwLjAsNjAuMCx0cnVlLC01LjAsMTguMCwiQ2VudGVyIiwzNy4wLFsiQXZvaWQgT3ZlcmxhcCIsIkppdHRlciJdLCJQZWVrIEZha2UiLCJGcmVlc3RhbmRpbmciLCJPcHBvc2l0ZSIsNjAuMCw2MC4wLHRydWUsNy4wLC03LjAsIkNlbnRlciIsLTk3LjAsWyJKaXR0ZXIiXSwiT2ZmIiwiU3dpdGNoIiwiT3Bwb3NpdGUiLDYwLjAsNjAuMCx0cnVlLDcuMCwtNy4wLCJDZW50ZXIiLC05Mi4wLFsiSml0dGVyIl0sIk9mZiIsIk9wcG9zaXRlIiwiT3Bwb3NpdGUiLDYwLjAsNjAuMCx0cnVlLDAuMCwwLjAsIkRpc2FibGVkIiwwLjAsW10sIk9mZiIsIkRlZmF1bHQiLCJEaXNhYmxlZCIsNjAuMCw2MC4wXQ==")

--end ffi region#--
arid.sidebar_selection = ui.get_style("Switch Active") 
local sidebar_color = arid.sidebar_selection:to_hex()
local colorek = arid.sidebar_selection


--start menu region#--
local arid = {
        menu = {
            icon = {
                export = ui.get_icon("file-export"),
                import = ui.get_icon("file-import"),
                default = ui.get_icon("cloud"),
                sidemenu = ui.get_icon("cannabis"),
                discordserver = ui.get_icon("location-arrow"),                      
            },
            color = {
            },
            ui = {
                global_main = ui.create("\a".. sidebar_color .."".. ui.get_icon("home") .."\aFFFFFFFF Home", "\a".. sidebar_color .."".. ui.get_icon("info") .."\aFFFFFFFF  Information"),
                global_configs = ui.create("\a".. sidebar_color .."".. ui.get_icon("home") .."\aFFFFFFFF Home", "\a".. sidebar_color .."".. ui.get_icon("file") .."\aFFFFFFFF  Configs"),
                antiaim_menu = ui.create("\a".. sidebar_color .."".. ui.get_icon("running") .."\aFFFFFFFF Anti-Aim", "\a".. sidebar_color ..""..ui.get_icon("street-view").. "\aFFFFFFFF  Main"),
                antiaim_builder = ui.create("\a".. sidebar_color .."".. ui.get_icon("running") .."\aFFFFFFFF Anti-Aim", "\a".. sidebar_color ..""..ui.get_icon("street-view")..  "\aFFFFFFFF  Anti-Aim Builder"),
                antiaim_antibrute = ui.create("\a".. sidebar_color .."".. ui.get_icon("running") .."\aFFFFFFFF Anti-Aim", "\a".. sidebar_color ..""..ui.get_icon("hammer").. "\aFFFFFFFF  Anti-Bruteforce"),
                antiaim_configs = ui.create("\a".. sidebar_color .."".. ui.get_icon("running") .."\aFFFFFFFF Anti-Aim",  "\a".. sidebar_color ..""..ui.get_icon("file").. "\aFFFFFFFF  Configs"),
                additions_interface = ui.create("\a".. sidebar_color .."".. ui.get_icon("user-edit") .. "\aFFFFFFFF Additions ",  "\a".. sidebar_color ..""..ui.get_icon("palette").. "\aFFFFFFFF  Interface"),
                additions_ragebot = ui.create("\a".. sidebar_color .."".. ui.get_icon("user-edit") .. "\aFFFFFFFF Additions ",  "\a".. sidebar_color ..""..ui.get_icon("crosshairs").. "\aFFFFFFFF  Ragebot"),
                additions_visuals = ui.create("\a".. sidebar_color .."".. ui.get_icon("user-edit") .. "\aFFFFFFFF Additions ",  "\a".. sidebar_color ..""..ui.get_icon("paint-brush").. "\aFFFFFFFF  Visuals"),
                additions_misc = ui.create("\a".. sidebar_color .."".. ui.get_icon("user-edit") .. "\aFFFFFFFF Additions ",  "\a".. sidebar_color ..""..ui.get_icon("cog").. "\aFFFFFFFF  Misc"),
            },
            create = {
                global_text = render_gradient_text(255, 255, 255,221,arid.sidebar_selection.r,arid.sidebar_selection.g,arid.sidebar_selection.b,255,'arid.sys beta'),
                sidebar_text = render_gradient_text(255, 255, 255,221,arid.sidebar_selection.r,arid.sidebar_selection.g,arid.sidebar_selection.b,255,'arid.sys'),
                nickname = render_gradient_text(255, 255, 255,221,arid.sidebar_selection.r,arid.sidebar_selection.g,arid.sidebar_selection.b,255, common.get_username()),
                anims = render_gradient_text(255, 255, 255,221,arid.sidebar_selection.r,arid.sidebar_selection.g,arid.sidebar_selection.b,255, "Anim. Breakers"),
                script = render_gradient_text(255, 255, 255,221,arid.sidebar_selection.r,arid.sidebar_selection.g,arid.sidebar_selection.b,255,'2.0'),
                version = render_gradient_text(255, 255, 255,221,arid.sidebar_selection.r,arid.sidebar_selection.g,arid.sidebar_selection.b,255,'Beta'),
                --onlineusers = render_gradient_text(255,255,255,221,arid.sidebar_selection.r,arid.sidebar_selection.g,arid.sidebar_selection.b,255, online),
                condition = render_gradient_text(255, 255, 255,221,arid.sidebar_selection.r,arid.sidebar_selection.g,arid.sidebar_selection.b,255,'Condition'),
                ovr_aa = render_gradient_text(255, 255, 255,221,arid.sidebar_selection.r,arid.sidebar_selection.g,arid.sidebar_selection.b,255,'Override Anti-Aim'),
                ovr_vis = render_gradient_text(255, 255, 255,221,arid.sidebar_selection.r,arid.sidebar_selection.g,arid.sidebar_selection.b,255,'Override Visuals'),
                ovr_infa = render_gradient_text(255, 255, 255,221,arid.sidebar_selection.r,arid.sidebar_selection.g,arid.sidebar_selection.b,255,'Override Interface'),
                ovr_rage = render_gradient_text(255, 255, 255,221,arid.sidebar_selection.r,arid.sidebar_selection.g,arid.sidebar_selection.b,255,'Override Ragebot'),
                ovr_misc = render_gradient_text(255, 255, 255,221,arid.sidebar_selection.r,arid.sidebar_selection.g,arid.sidebar_selection.b,255,'Override Miscellaneous'),
                beta = render_gradient_text(255, 255, 255,221,arid.sidebar_selection.r,arid.sidebar_selection.g,arid.sidebar_selection.b,255,'[BETA]'),
                fix = render_gradient_text(255, 255, 255,221,arid.sidebar_selection.r,arid.sidebar_selection.g,arid.sidebar_selection.b,255,'[FIX]'),
            },

            globals = {
                tab = {

                },
                rage = {

                },
                antiaim = {

                },
                visuals = {
                    
                },
            },
        },
        entitys = {},
        config = {},
        functions = {},
        js = {},
        globals = {},
        working_functions = {},

        antiaim = {
            aa_states = {
                "Global", 
                "Stand", 
                "Move", 
                "Slowwalk", 
                "Crouch", 
                "Jump", 
                "Jump+Crouch",
                "Fakeduck",
            },
            aa_states2 = {
                "G", 
                "S", 
                "M", 
                "SW",
                "C", 
                "J", 
                "J+C",
                "FD",
                --"FL",
            },
        },


        visuals = {
            font = {
                pixel9 = render.load_font(aridfunc:get_neverlose_path().."arid\\smallest_pixel-7.tff", 10, "o"),
                verdanaanim = render.load_font("Verdana", 100, "bdoi"),  
                verdanabold = render.load_font("Verdana", 21, "bd"),  
                verdanab = render.load_font("Verdana", 12, "bd"),
                astronomy = render.load_font(aridfunc:get_neverlose_path().."arid\\Astronomy.ttf", 18),  
            },
            indicators = {
                states = {
                    [1] = "standing",
                    [2] = "moving",
                    [3] = "walking",
                    [4] = "crouching",
                    [5] = "air",
                    [6] = "air+crouch",
                },
            },
        },

        globals = {
            info = {
                username = common.get_username(),
            }
        },
        



}

--[[arid.working_functions.get_colorek = function()
    local colordojebania = ui.get_style("Switch Active")
        common.reload_script()
    end 
end--]]


ui.sidebar(arid.menu.create.sidebar_text, arid.menu.icon.sidemenu)

aa_refs = {
    pitch = ui.find("Aimbot", "Anti Aim", "Angles", "Pitch"),
    yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw"),
    base = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Base"),
    offset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Offset"),
    backstab = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Avoid Backstab"),
    yaw_modifier = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier"),
    modifier_offset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier", "Offset"),
    body_yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw"),
    inverter = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Inverter"),
    left_limit = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Left Limit"),
    right_limit = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Right Limit"),
    options = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Options"),
    desync_freestanding = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Freestanding"),
    on_shot = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "On Shot"),
    lby_mode = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "LBY Mode"),
    slowwalk = ui.find("Aimbot", "Anti Aim", "Misc", "Slow Walk"),
    fakeduck = ui.find("Aimbot", "Anti Aim", "Misc", "Fake Duck"),
}

arid.ref = {
    fakeduck = ui.find('Aimbot','Anti Aim',"Misc","Fake Duck"),
    slowwalk = ui.find('Aimbot','Anti Aim',"Misc","Slow Walk"),
    pitch = ui.find('Aimbot','Anti Aim',"Angles","Pitch"),
    yaw = ui.find('Aimbot','Anti Aim',"Angles","Yaw"),
    yawbase = ui.find('Aimbot','Anti Aim',"Angles","Yaw",'Base'),
    yawadd = ui.find('Aimbot','Anti Aim',"Angles","Yaw",'Offset'),
    fake_lag_limit = ui.find('Aimbot','Anti Aim',"Fake Lag","Limit"),
    yawjitter = ui.find('Aimbot','Anti Aim',"Angles","Yaw Modifier"),
    yawjitter_offset = ui.find('Aimbot','Anti Aim',"Angles","Yaw Modifier",'Offset'),
    fakeangle = ui.find('Aimbot','Anti Aim',"Angles","Body Yaw"),
    inverter = ui.find('Aimbot','Anti Aim',"Angles","Body Yaw","Inverter"),
    left_limit = ui.find('Aimbot','Anti Aim',"Angles","Body Yaw","Left Limit"),
    right_limit = ui.find('Aimbot','Anti Aim',"Angles","Body Yaw","Right Limit"),
    fakeoption = ui.find('Aimbot','Anti Aim',"Angles","Body Yaw","Options"),
    fsbodyyaw = ui.find('Aimbot','Anti Aim',"Angles","Body Yaw","Freestanding"),
    onshot = ui.find('Aimbot','Anti Aim',"Angles","Body Yaw","On Shot"),
    lby = ui.find('Aimbot','Anti Aim',"Angles","Body Yaw","LBY Mode"),
    freestanding = ui.find('Aimbot','Anti Aim',"Angles","Freestanding"),
    dsyawfs = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding", "Disable Yaw Modifiers"),
    bodyfreestanding = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding", "Body Freestanding"),
    disableyaw_modifier = ui.find('Aimbot','AntiAim',"Angles","Freestanding","Disable Yaw Modifiers"),
    body_freestanding = ui.find('Aimbot','Anti Aim',"Angles","Freestanding","Body Freestanding"),
    roll = ui.find('Aimbot','Anti Aim',"Angles","Extended Angles"),
    roll_pitch = ui.find('Aimbot','Anti Aim',"Angles","Extended Angles","Extended Pitch"),
    roll_roll = ui.find('Aimbot','Anti Aim',"Angles","Extended Angles","Extended Roll"),
    leg_movement = ui.find('Aimbot','Anti Aim',"Misc","Leg Movement"),
    hitchance = ui.find('Aimbot','Ragebot',"Selection","Hit Chance"),
    air_strafe = ui.find('Miscellaneous',"Main","Movement",'Air Strafe'),
    antibackstab = ui.find('Aimbot','Anti Aim','Yaw','Avoid Backstab'),
    minimum_damage = ui.find("Aimbot","Ragebot","Selection","Minimum Damage"),
    dt_opt = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Lag Options"),
    dt_fl = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Fake Lag Limit"),
    os_type = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots", "Options"),
    dormant_aimbot = ui.find("Aimbot", "Ragebot", "Main", "Enabled", "Dormant Aimbot"),
    hs = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots"),
    sp = ui.find("Aimbot", "Ragebot", "Safety", "Safe Points"),
    ba = ui.find("Aimbot", "Ragebot", "Safety", "Body Aim"),
    da = ui.find("Aimbot", "Ragebot", "Main", "Enabled", "Dormant Aimbot"),
    fakel = ui.find("Miscellaneous", "Main", "Other", "Fake Latency"),
    dt = ui.find("Aimbot", "Ragebot", "Main", "Double Tap"),
    minimumdmg = ui.find("Aimbot", "Ragebot", "Selection", "Minimum Damage"),
    hitchance = ui.find("Aimbot", "Ragebot", "Selection", "Hit Chance"),
}
local hooked_function, is_jumping = nil, false
local hitgroup_str = {
    [0] = 'generic',
    'head', 'chest', 'stomach',
    'left arm', 'right arm',
    'left leg', 'right leg',
    'neck', 'generic', 'gear'
}
--start ui region#--



arid.menu.globals.tab.global_label = arid.menu.ui.global_main:label("Welcome to ".. arid.menu.create.global_text .."")
--arid.menu.globals.tab.global_label = arid.menu.ui.global_main:label("Build : ".. arid.menu.create.version.."")
--arid.menu.globals.tab.global_label1 = arid.menu.ui.global_main:label("Script Version: "..arid.menu.create.script.."")

arid.menu.globals.tab.global_label2 = arid.menu.ui.global_main:label("Join our discord server to get role and support with bugs from stuff , update logs can be found on marketplace / discord")
arid.menu.globals.tab.global_label3 = arid.menu.ui.global_main:label("If you find any bugs or have suggestions, please report it in our discord!")
arid.menu.globals.tab.loading_animation = arid.menu.ui.global_main:switch("Loading Animation", true)
local function discordbutton()
    panorama.SteamOverlayAPI.OpenExternalBrowserURL("https://discord.gg/84W3VfEMhm")
    utils.console_exec(string.format("playvol buttons/bell1.wav 1"))
end

arid.menu.globals.tab.discord_button = arid.menu.ui.global_main:button("\a".. sidebar_color ..""..arid.menu.icon.discordserver .."\aFFFFFFFF Discord server", discordbutton, true)

-- antiaim
arid.menu.globals.antiaim.enable_antiaim = arid.menu.ui.antiaim_menu:switch("\a"..sidebar_color..""..ui.get_icon("code").." "..arid.menu.create.ovr_aa)
arid.menu.globals.antiaim.custom_aa = arid.menu.ui.antiaim_menu:combo("Mode", {"Default", "Condictional",})  arid.menu.globals.antiaim.custom_aa:set_tooltip("Type of AntiAim \n Disabled: No AA \n Condictional: Builder")
manual_yaw_base = arid.menu.ui.antiaim_menu:combo("Yaw Base", {"Disabled", "Forward", "Left", "Right"})
arid.menu.globals.antiaim.animation_breakers = arid.menu.ui.antiaim_menu:selectable("\a"..sidebar_color..""..ui.get_icon("user-secret").." "..arid.menu.create.anims, {'Static legs in air', 'Legs direction', 'Zero pitch on land'}, 0)
arid.menu.globals.antiaim.aa_tweaks = arid.menu.ui.antiaim_menu:selectable("Antiaim Tweaks", {'Anti-Backstab', 'Dormant Aimbot', 'Fake Pitch Exploit', "Disable AA on Warmup"}, 0)

arid.menu.globals.antiaim.condition = arid.menu.ui.antiaim_builder:combo("\a"..sidebar_color..""..ui.get_icon("users").." "..arid.menu.create.condition, arid.antiaim.aa_states)


--[[ Interface ]]
arid.menu.globals.visuals.enable_interface = arid.menu.ui.additions_interface:switch("\a"..sidebar_color..""..ui.get_icon("list").." "..arid.menu.create.ovr_infa)


arid.menu.globals.visuals.watermark_enable = arid.menu.ui.additions_interface:switch("\a".. sidebar_color .."".. ui.get_icon("image") .."\aFFFFFFFF  Watermark")
arid.menu.globals.visuals.debug_enable = arid.menu.ui.additions_interface:switch("\a".. sidebar_color .."".. ui.get_icon("pen") .."\aFFFFFFFF  Debug Panel")
arid.menu.globals.visuals.watermark = arid.menu.globals.visuals.watermark_enable:create()
arid.menu.globals.visuals.debug = arid.menu.globals.visuals.debug_enable:create()
arid.menu.globals.visuals.gradient = arid.menu.globals.visuals.watermark:switch("Rect Behind State Panel", true)
arid.menu.globals.visuals.uiclr = arid.menu.globals.visuals.watermark:color_picker("State Panel Color", color(colorek.r, colorek.g, colorek.b, 255))
arid.menu.globals.visuals.watermark_x = arid.menu.globals.visuals.watermark:slider("Slider 1", 0, render.screen_size().x, 1764)
arid.menu.globals.visuals.watermark_y = arid.menu.globals.visuals.watermark:slider("Slider 2", 0, render.screen_size().y, 28)
arid.menu.globals.visuals.uiclr_debug = arid.menu.globals.visuals.debug:color_picker("Debug Panel Color", color(colorek.r, colorek.g, colorek.b, 255))
arid.menu.globals.visuals.debug_x = arid.menu.globals.visuals.debug:slider("Slider 11", 0, render.screen_size().x, 42)
arid.menu.globals.visuals.debug_y = arid.menu.globals.visuals.debug:slider("Slider 22", 0, render.screen_size().y, 507)

arid.menu.globals.visuals.keybinds_enable = arid.menu.ui.additions_interface:switch("\a".. sidebar_color .."".. ui.get_icon("keyboard") .."\aFFFFFFFF  Keybinds")
arid.menu.globals.visuals.spectators_enable = arid.menu.ui.additions_interface:switch("\a".. sidebar_color .."".. ui.get_icon("glasses") .."\aFFFFFFFF  Spectators")

arid.menu.globals.visuals.interface_design = arid.menu.ui.additions_interface:label("\a".. sidebar_color .."".. ui.get_icon("layer-group") .."\aFFFFFFFF  Interface Design")
arid.menu.globals.visuals.interface = arid.menu.globals.visuals.interface_design:create()
arid.menu.globals.visuals.solus_combo = arid.menu.globals.visuals.interface:combo("Style", {"Default", "Modern"}, 2)
arid.menu.globals.visuals.accent_col = arid.menu.globals.visuals.interface:color_picker("Solus UI Color", color(colorek.r, colorek.g, colorek.b))



--[[ Visuals ]]

arid.menu.globals.visuals.enable_visuals = arid.menu.ui.additions_visuals:switch("\a"..sidebar_color..""..ui.get_icon("palette").." "..arid.menu.create.ovr_vis)
arid.menu.globals.visuals.indicators2 = arid.menu.ui.additions_visuals:switch("Screen Indicators")
arid.menu.globals.visuals.indicators_wel = arid.menu.globals.visuals.indicators2:create()
arid.menu.globals.visuals.indicators_type = arid.menu.globals.visuals.indicators_wel:combo("Indicators Type", {'Default','Modern'}, 0)
arid.menu.globals.visuals.color23 = arid.menu.globals.visuals.indicators_wel:color_picker('Indicators Color', color(colorek.r, colorek.g, colorek.b, 255))
arid.menu.globals.visuals.aimbot_logs = arid.menu.ui.additions_visuals:switch('Aimbot Logs')
arid.menu.globals.visuals.aimbot_refs = arid.menu.globals.visuals.aimbot_logs:create()
arid.menu.globals.visuals.logs_features = arid.menu.globals.visuals.aimbot_refs:selectable("", {'Dev', 'Screen', 'Console'}, 0)
arid.menu.globals.visuals.gradientcolor2 = arid.menu.globals.visuals.aimbot_refs:color_picker("Aimbot Logs Color", color(colorek.r, colorek.g, colorek.b, 255))


arid.menu.globals.visuals.custom_scope_overlay = arid.menu.ui.additions_visuals:switch("Custom Scope")
arid.menu.globals.visuals.custom_scope_overlay_group = arid.menu.globals.visuals.custom_scope_overlay:create()
arid.menu.globals.visuals.custom_scope_overlay_line = arid.menu.globals.visuals.custom_scope_overlay_group:slider("Line", 0, 100, 60)

arid.menu.globals.visuals.custom_scope_overlay_gap = arid.menu.globals.visuals.custom_scope_overlay_group:slider("Gap", 0, 100, 5)
arid.menu.globals.visuals.custom_scope_overlay_color = arid.menu.globals.visuals.custom_scope_overlay_group:color_picker("Color", color(143, 178, 255, 255))


--[[ Misc ]]

arid.menu.globals.tab.enable_misc = arid.menu.ui.additions_misc:switch("\a"..sidebar_color..""..ui.get_icon("cloud").." "..arid.menu.create.ovr_misc)
arid.menu.globals.tab.aspect_ratio = arid.menu.ui.additions_misc:switch('Aspect Ratio')
arid.menu.globals.tab.aspectratio_ref = arid.menu.globals.tab.aspect_ratio:create()
arid.menu.globals.tab.aspect_ratio_change = arid.menu.globals.tab.aspectratio_ref:slider('Value',5,20,13,0.1)

arid.menu.globals.tab.trashtalk = arid.menu.ui.additions_misc:switch('Trashtalk')

arid.menu.globals.tab.viewmodel =  arid.menu.ui.additions_misc:switch("Viewmodel")
arid.menu.globals.tab.viewmodel_group = arid.menu.globals.tab.viewmodel:create()
arid.menu.globals.tab.viewmodel_fov = arid.menu.globals.tab.viewmodel_group:slider("FOV", -100, 100, 68)
arid.menu.globals.tab.viewmodel_x = arid.menu.globals.tab.viewmodel_group:slider("X", -10, 10, 2.5)
arid.menu.globals.tab.viewmodel_y = arid.menu.globals.tab.viewmodel_group:slider("Y", -10, 10, 0) 
arid.menu.globals.tab.viewmodel_z = arid.menu.globals.tab.viewmodel_group:slider("Z", -10, 10, -1.5)

arid.menu.globals.tab.hitchance_modifier =  arid.menu.ui.additions_misc:switch("Hitchance Modifier")
arid.menu.globals.tab.hitchance_modifier_group = arid.menu.globals.tab.hitchance_modifier:create()
arid.menu.globals.tab.hitchance_modifier_noscope = arid.menu.globals.tab.hitchance_modifier_group:slider("Noscope HC", 0, 100, 50)
arid.menu.globals.tab.hitchance_modifier_inair = arid.menu.globals.tab.hitchance_modifier_group:slider("In air HC", 0, 100, 40)

arid.menu.globals.tab.notifications =  arid.menu.ui.additions_misc:switch("Notifications")
arid.menu.globals.tab.notifications_group = arid.menu.globals.tab.notifications:create()
arid.menu.globals.tab.notifications_select = arid.menu.globals.tab.notifications_group:selectable("Notifications", {"On damage deal", "Anti-bruteforce"})


arid.menu.globals.tab.jumpscout_fix = arid.menu.ui.additions_misc:switch(arid.menu.create.beta.."\aC6D1DAFF  Jumpscout Strafe")

arid.menu.globals.tab.fastladder =  arid.menu.ui.additions_misc:switch(arid.menu.create.beta.."\aC6D1DAFF  Fast Ladder")

--start visuals region#--



local x, y = render.screen_size().x, render.screen_size().y

local notify=(function() notify_cache={} local a={callback_registered=false,maximum_count=4} 
    function a:set_callback()
        if self.callback_registered then return end; 
        events.render:set(function() 
            local c={x,y} 
            local d={0,0,0} 
            local e=1; 
            local f=notify_cache; 
            for g=#f,1,-1 do 
                notify_cache[g].time=notify_cache[g].time-globals.frametime; 
                local h,i=255,0; 
                local i2 = 0; 
                local lerpy = 150; 
                local lerp_circ1 = 0.5; 
                local j=f[g] 
                if j.time<0 then 
                    table.remove(notify_cache,g) 
                else 
                    local k=j.def_time-j.time; 
                    local k=k>1 and 1 or k; 
                    if j.time<1 or k<1 then 
                        i=(k<1 and k or j.time)/1; 
                        i2=(k<1 and k or j.time)/1; 
                        h=i*255; lerpy=i*150; 
                        lerp_circ1=i*0.5;
                        if i<0.2 then e=e+8*(1.0-i/0.2) end 
                    end; 
                    local m={math.floor(render.measure_text(1, nil, "[aridsys]  "..j.draw).x*1.03),math.floor(render.measure_text(1, nil, "[aridsys] "..j.draw).y*1.03)} 
                    local n={render.measure_text(1, nil, "[aridsys]  ").x,render.measure_text(1, nil, "[aridsys]  ").y} 
                    local o={render.measure_text(1, nil, j.draw).x,render.measure_text(1, nil, j.draw).y} 
                    local p={c[1]/2-m[1]/2+3,c[2]-c[2]/100*13.4+e}
                    local col = arid.menu.globals.visuals.gradientcolor2:get()
                   render.shadow(vector(p[1], p[2]-19), vector(p[1]+m[1], p[2]), color(col.r, col.g, col.b, h-100), 20, 0, 5)
                   render.rect(vector(p[1], p[2]-19), vector(p[1]+m[1], p[2]), color(20, 20, 20, h>240 and 240 or h),5)
                   render.text(arid.visuals.font.astronomy, vector(p[1]+m[1]/2-o[1]/2,p[2]-8), color(col.r, col.g, col.b,h), "c", "a")
                   render.text(1, vector(p[1]+m[1]/2+n[1]/2-2-10,p[2] - 10), color(255, 255, 255,h), "c", j.draw)
                    e=e-33
                end 
            end; 
            self.callback_registered=true 
        end) 
    end;
    function a:push(q,r) 
        local s=tonumber(q)+1; 
        for g=self.maximum_count,2,-1 do 
            notify_cache[g]=notify_cache[g-1] 
        end; 
        notify_cache[1]={time=s,def_time=s,draw=r} 
        self:set_callback()
    end;
    return a 
end) () 

local col_welcome = arid.menu.globals.visuals.gradientcolor2:get()
local color_welcome = col_welcome:to_hex()
notify:push(4, " Welcome Back \a"..color_welcome.."".. arid.globals.info.username .."\aFFFFFFFF build : ".. "\a"..color_welcome.."beta")

arid.working_functions.fastladder_init = function(cmd)
    if not arid.menu.globals.tab.fastladder:get() and arid.menu.globals.tab.enable_misc:get() then return end
    local local_player = entity.get_local_player()
    if local_player == nil then return end

    local pitch = render.camera_angles()
    if local_player["m_MoveType"] == 9 then
        if cmd.forwardmove > 0 then
        if pitch.x < 45 then
            cmd.view_angles.x = 89
            cmd.view_angles.y = cmd.view_angles.y + 89
            cmd.in_moveright = 1
            cmd.in_moveleft = 0
            cmd.in_forward = 0
            cmd.in_back = 1
            if cmd.sidemove == 0 then
                cmd.move_yaw = cmd.move_yaw + 90
            end
            if cmd.sidemove < 0 then
                cmd.move_yaw = cmd.move_yaw + 150
            end
            if cmd.sidemove > 0 then
                cmd.move_yaw = cmd.move_yaw + 30
            end
        end
    end
    
    if cmd.forwardmove < 0 then
        cmd.view_angles.x = 89
        cmd.view_angles.y = cmd.view_angles.y + 89
        cmd.in_moveright = 1
        cmd.in_moveleft = 0
        cmd.in_forward = 1
        cmd.in_back = 0
        if cmd.sidemove == 0 then
            cmd.move_yaw = cmd.move_yaw + 90
        end
        if cmd.sidemove > 0 then
            cmd.move_yaw = cmd.move_yaw + 150
        end
        if cmd.sidemove < 0 then
            cmd.move_yaw = cmd.move_yaw + 30
        end
    end
end
end




arid.working_functions.in_air = function()
    local localplayer = entity.get_local_player()
    local b = entity.get_local_player()
        if b == nil then
            return
        end
    local flags = localplayer["m_fFlags"]
 
    if bit.band(flags, 1) == 0 then
        return true
    end
 
    return false
end


arid.working_functions.disable_aa = function()
    if arid.menu.globals.antiaim.enable_antiaim:get() then
        if arid.menu.globals.antiaim.aa_tweaks:get('Disable AA on Warmup') then
    local localplayer = entity.get_local_player()
    local b = entity.get_local_player()
    local rules = entity.get_game_rules()
    --local game = rules["DT_CSGameRulesProxy"]
    local game_rules = entity.get_game_rules()
    if not game_rules then
        return
    end
    local RoundTime = game_rules["m_bWarmupPeriod"]
  
    local aa = ui.find("Aimbot", "Anti Aim", "Angles", "Pitch")
    local aa2 = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw")
    local aa3 = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw")

        if b == nil then
            return
        end
        if RoundTime then
            aa:set("Disabled")
            aa2:set("Disabled")
            aa3:set(false)
        else
            aa:set("Down")
            aa2:set("Backward")
            aa3:set(true)
        end
    end
end
end




events.aim_ack:set(function(e)
    local me = entity.get_local_player()
    local target = entity.get(e.target)
    local damage = e.damage
    local wanted_damage = e.wanted_damage
    local wanted_hitgroup = hitgroup_str[e.wanted_hitgroup]
    local hitchance = e.hitchance
    local state = e.state
    local bt = e.backtrack
    if not target then return end
    if target == nil then return end
    local health = target["m_iHealth"]


    local hitgroup = hitgroup_str[e.hitgroup]

    local col = arid.menu.globals.visuals.gradientcolor2:get()
    local color = col:to_hex()

    if arid.menu.globals.visuals.aimbot_logs:get() and state == nil and arid.menu.globals.visuals.enable_visuals:get()  then
    if not globals.is_connected then return end
    if arid.menu.globals.visuals.logs_features:get('Screen') and arid.menu.globals.visuals.enable_visuals:get()  then
        notify:push(4, ("Hit \a"..color.."%s's \aFFFFFFFF%s for \a"..color.."%d\aFFFFFFFF ("..string.format("%.f", wanted_damage)..") [bt: \a"..color.."%s \aFFFFFFFF| hp: \a"..color..""..health.."\aFFFFFFFF]"):format(target:get_name(), hitgroup, e.damage, bt))
    end
    if arid.menu.globals.visuals.logs_features:get('Console') and arid.menu.globals.visuals.enable_visuals:get() then
        print_raw(("\aA9ACFF[arid] \aA0FB87Registered \aD5D5D5shot at %s's %s for \aA0FB87%d("..string.format("%.f", wanted_damage)..") \aD5D5D5damage (hp: "..health..") (aimed: "..wanted_hitgroup..") (bt: %s)"):format(target:get_name(), hitgroup, e.damage, bt))
    end
    if arid.menu.globals.visuals.logs_features:get('Dev') and arid.menu.globals.visuals.enable_visuals:get() then
        print_dev(("[arid] Registered shot at %s's %s for %d("..string.format("%.f", wanted_damage)..") damage (hp: "..health..") (aimed: "..wanted_hitgroup..") (bt: %s)"):format(target:get_name(), hitgroup, e.damage, bt))
    end
    elseif arid.menu.globals.visuals.aimbot_logs:get() and arid.menu.globals.visuals.enable_visuals:get() then
    if arid.menu.globals.visuals.logs_features:get('Screen') and arid.menu.globals.visuals.enable_visuals:get() then
        notify:push(4, ('Missed \a'..color..'%s \aFFFFFFFFin the %s due to \a'..color..''..state..' \aFFFFFFFF(hc: '..string.format("%.f", hitchance)..') (damage: '..string.format("%.f", wanted_damage)..')'):format(target:get_name(), wanted_hitgroup, state1))
    end
    if arid.menu.globals.visuals.logs_features:get('Console') and arid.menu.globals.visuals.enable_visuals:get() then
        print_raw(('\aA9ACFF[arid] \aE94B4BMissed \aFFFFFFshot in %s in the %s due to \aE94B4B'..state..' \aFFFFFF(hc: '..string.format("%.f", hitchance)..') (damage: '..string.format("%.f", wanted_damage)..')'):format(target:get_name(), wanted_hitgroup, state1))
    end
    if arid.menu.globals.visuals.logs_features:get('Dev') and arid.menu.globals.visuals.enable_visuals:get() then
        print_dev(('[arid] Missed shot in %s in the %s due to '..state..' (hc: '..string.format("%.f", hitchance)..') (damage: '..string.format("%.f", wanted_damage)..')'):format(target:get_name(), wanted_hitgroup, state1))
    end
end
end)

events.player_hurt:set(function(e)
    local me = entity.get_local_player()
    local attacker = entity.get(e.attacker, true)
    local weapon = e.weapon
    local type_hit = 'Hit'

    if weapon == 'hegrenade' then 
        type_hit = 'Naded'
    end

    if weapon == 'inferno' then
        type_hit = 'Burned'
    end

    if weapon == 'knife' then 
        type_hit = 'Knifed'
    end

    if weapon == 'hegrenade' or weapon == 'inferno' or weapon == 'knife' then

    if me == attacker then
        local user = entity.get(e.userid, true)
        if arid.menu.globals.visuals.aimbot_logs:get() and arid.menu.globals.visuals.enable_visuals:get() then
        print_raw(('\aA9ACFF[arid] \aD5D5D5'..type_hit..' %s for %d damage (%d health remaining)'):format(user:get_name(), e.dmg_health, e.health))
        notify:push(4, (''..type_hit..' %s for %d damage (%d health remaining)'):format(user:get_name(), e.dmg_health, e.health))
    end

    end
end
end)

-- solus ui

function lerpx(time,a,b) return a * (1-time) + b * time end

function window(x, y, w, h, name, alpha) 
	local name_size = render.measure_text(1, "", name) 
	local r, g, b = arid.menu.globals.visuals.accent_col:get().r, arid.menu.globals.visuals.accent_col:get().g, arid.menu.globals.visuals.accent_col:get().b
    local r2, g2, b2 = arid.menu.globals.visuals.accent_col:get().r, arid.menu.globals.visuals.accent_col:get().g, arid.menu.globals.visuals.accent_col:get().b

    if arid.menu.globals.visuals.solus_combo:get() == 'Modern' then
        render.rect(vector(x + 2, y), vector(x + w-1, y + 1), color(r2, g2, b2, alpha/2), 0)
        render.rect(vector(x, y + 1), vector(x + w + 3, y + 16), color(20, 20, 20, alpha/1.5), 4)
        render.circle_outline(vector(x + 3, y + 4), color(r2, g2, b2, alpha), 4.5, 175, 0.33, 1)
        render.circle_outline(vector(x + w, y + 4), color(r2, g2, b2, alpha), 4.5, 260, 0.30, 1)
        render.gradient(vector(x - 1, y + 2), vector(x, y + h - 4), color(r2, g2, b2, alpha), color(r2, g2, b2, 0), color(r2, g2, b2, alpha/2), color(r2, g2, b2, 0))
        render.gradient(vector(x + w + 3, y + 2), vector(x + w + 4, y + h - 4), color(r2, g2, b2, alpha), color(r2, g2, b2, 0), color(r2, g2, b2, alpha/2), color(r2, g2, b2, 0))
        render.text(1, vector(x+1 + w / 2 + 1 - name_size.x / 2,	y + h / 2 -  name_size.y/2), color(255, 255, 255, alpha), "", name)
        render.rect_outline(vector(x, y), vector(x + w + 3, y + 1), color(r, g, b, alpha/5), 1, 0)
        elseif arid.menu.globals.visuals.solus_combo:get() == 'Default' then
        render.rect(vector(x, y), vector(x + w + 3, y + 1), color(r2, g2, b2, alpha), 4)
        render.rect(vector(x, y + 2), vector(x + w + 3, y + 19), color(0, 0, 0, alpha/3), 0)
        render.text(1, vector(x+1 + w / 2 + 1 - name_size.x / 2,	y + 2 + h / 2 -  name_size.y/2), color(255, 255, 255, alpha), "", name)
    end
end

local x, y, alphabinds, alpha_k, width_k, width_ka, data_k, width_spec, width_water = render.screen_size().x, render.screen_size().y, 0, 1, 0, 0, { [''] = {alpha_k = 0}}, 1, 1

local pos_x = arid.menu.ui.additions_interface:slider("posx", 0, x, 234)
local pos_y = arid.menu.ui.additions_interface:slider("posy", 0, y, 454)
local pos_x1 = arid.menu.ui.additions_interface:slider("posx1", 0, x, 250)
local pos_y1 = arid.menu.ui.additions_interface:slider("posy1", 0, y, 250)

--@: sowus - keybinds
local new_drag_object = drag_system.register({pos_x, pos_y}, vector(120, 60), "Test", function(self)
    if arid.menu.globals.visuals.keybinds_enable:get() and arid.menu.globals.visuals.enable_interface:get() then
    local max_width = 0
    local frametime = globals.frametime * 16
    local add_y = 0
    local total_width = 66
    local active_binds = {}

    local binds = ui.get_binds()
    for i = 1, #binds do
            local bind = binds[i]
            local get_mode = binds[i].mode == 1 and 'holding' or (binds[i].mode == 2 and 'toggled') or '[?]'
            local get_value = binds[i].value

            local c_name = binds[i].name
            if c_name == 'Peek Assist' then c_name = 'Quick peek assist' end
            if c_name == 'Edge Jump' then c_name = 'Jump at edge' end
            if c_name == 'Hide Shots' then c_name = 'On shot anti-aim' end
            if c_name == 'Minimum Damage' then c_name = 'Minimum damage' end
            if c_name == 'Fake Latency' then c_name = 'Ping spike' end
            if c_name == 'Fake Duck' then c_name = 'Duck peek assist' end
            if c_name == 'Safe Points' then c_name = 'Safe point' end
            if c_name == 'Body Aim' then c_name = 'Body aim' end
            if c_name == 'Double Tap' then c_name = 'Double tap' end
            if c_name == 'Yaw Base' then c_name = 'Manual override' end
            if c_name == 'Slow Walk' then c_name = 'Slow motion' end


            local bind_state_size = render.measure_text(1, "", get_mode)
            local bind_name_size = render.measure_text(1, "", c_name)
            if data_k[bind.name] == nil then data_k[bind.name] = {alpha_k = 0} end
            data_k[bind.name].alpha_k = lerpx(frametime, data_k[bind.name].alpha_k, (bind.active and 255 or 0))

            if arid.menu.globals.visuals.solus_combo:get() == 'Modern' then
                render.text(1, vector(self.position.x+3, self.position.y + 19 + add_y), color(255, data_k[bind.name].alpha_k), '', c_name)

                if c_name == 'Minimum damage' or c_name == 'Ping spike' then
                    render.text(1, vector(self.position.x + (width_ka - bind_state_size.x) - render.measure_text(1, nil, get_value).x + 28, self.position.y + 19 + add_y), color(255, data_k[bind.name].alpha_k), '',  '['..get_value..']')
                else
                    render.text(1, vector(self.position.x + (width_ka - bind_state_size.x - 8), self.position.y + 19 + add_y), color(255, data_k[bind.name].alpha_k), '',  '['..get_mode..']')
                end
            else
                render.text(1, vector(self.position.x+3, self.position.y + 22 + add_y), color(255, data_k[bind.name].alpha_k), '', c_name)

                if c_name == 'Minimum damage' or c_name == 'Ping spike' then
                    render.text(1, vector(self.position.x + (width_ka - bind_state_size.x) - render.measure_text(1, nil, get_value).x + 28, self.position.y + 22 + add_y), color(255, data_k[bind.name].alpha_k), '',  '['..get_value..']')
                else
                    render.text(1, vector(self.position.x + (width_ka - bind_state_size.x - 8), self.position.y + 22 + add_y), color(255, data_k[bind.name].alpha_k), '',  '['..get_mode..']')
                end
            end
            
            add_y = add_y + 16 * data_k[bind.name].alpha_k/255

            --drag
            local width_k = bind_state_size.x + bind_name_size.x + 18
            if width_k > 130-11 then
                if width_k > max_width then
                    max_width = width_k
                end
            end

            if binds.active then
                    table.insert(active_binds, binds)
                end
            end

            alpha_k = lerpx(frametime, alpha_k, (ui.get_alpha() > 0 or add_y > 0) and 1 or 0)
            width_ka = lerpx(frametime,width_ka, math.max(max_width, 130-11))
            if ui.get_alpha()>0 or add_y > 6 then alphabinds = lerpx(frametime, alphabinds, math.max(ui.get_alpha()*255, (add_y > 1 and 255 or 0)))
            elseif add_y < 15.99 and ui.get_alpha() == 0 then alphabinds = lerpx(frametime, alphabinds, 0) end
            if ui.get_alpha() or #active_binds > 0 then
            window(self.position.x, self.position.y, width_ka, 16, 'keybinds', alphabinds)
            end
    end
end)

local fnay = render.load_image(network.get("https://avatars.cloudflare.steamstatic.com/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb_medium.jpg"), vector(50, 50))

local new_drag_object1 = drag_system.register({pos_x1, pos_y1}, vector(120, 60), "Test2", function(self)
    if arid.menu.globals.visuals.enable_interface:get() then
    if arid.menu.globals.visuals.spectators_enable:get() then
    local width_spec = 120
    if width_spec > 160-11 then
        if width_spec > max_width then
            max_width = width_spec
        end
    end

        if ui.get_alpha() > 0.3 or (ui.get_alpha() > 0.3 and not globals.is_in_game) then window(self.position.x, self.position.y, width_spec, 16, 'spectators', 255) end

        local me = entity.get_local_player()
        if me == nil then return end

        local speclist = me:get_spectators()

        if me.m_hObserverTarget and (me.m_iObserverMode == 4 or me.m_iObserverMode == 5) then
            me = me.m_hObserverTarget
        end

        local speclist = me:get_spectators()
        if speclist == nil then return end
        for idx,player_ptr in pairs(speclist) do
            local name = player_ptr:get_name()
            local tx = render.measure_text(1, '', name).x
            name_sub = string.len(name) > 30 and string.sub(name, 0, 30) .. "..." or name;
            local avatar = player_ptr:get_steam_avatar()
            if (avatar == nil or avatar.width <= 5) then avatar = fnay end

            if player_ptr:is_bot() and not player_ptr:is_player() then goto skip end
            render.text(1, vector(self.position.x + 17, self.position.y + 5 + (idx*15)), color(), 'u', name_sub)
            render.texture(avatar, vector(self.position.x + 1, self.position.y + 5 + (idx*15)), vector(12, 12), color(), 'f', 0)
            ::skip::
        end

    
        if #me:get_spectators() > 0 or (me.m_iObserverMode == 4 or me.m_iObserverMode == 5) then
            window(self.position.x, self.position.y, width_spec, 16, 'spectators', 255)
        end
        
        end
    end
end)


events.mouse_input:set(function()
        if ui.get_alpha() > 0.3 then return false end
end)

-- solus ui end


-- animation breakers

hook_helper = {
    copy = function(dst, src, len)
    return ffi.copy(ffi.cast('void*', dst), ffi.cast('const void*', src), len)
    end,

    virtual_protect = function(lpAddress, dwSize, flNewProtect, lpflOldProtect)
    return ffi.C.VirtualProtect(ffi.cast('void*', lpAddress), dwSize, flNewProtect, lpflOldProtect)
    end,

    virtual_alloc = function(lpAddress, dwSize, flAllocationType, flProtect, blFree)
    local alloc = ffi.C.VirtualAlloc(lpAddress, dwSize, flAllocationType, flProtect)
    if blFree then
        table.insert(buff.free, function()
        ffi.C.VirtualFree(alloc, 0, 0x8000)
        end)
    end
    return ffi.cast('intptr_t', alloc)
end
}

buff = {free = {}}
vmt_hook = {hooks = {}}

function vmt_hook.new(vt)
    local new_hook = {}
    local org_func = {}
    local old_prot = ffi.new('unsigned long[1]')
    local virtual_table = ffi.cast('intptr_t**', vt)[0]

    new_hook.this = virtual_table
    new_hook.hookMethod = function(cast, func, method)
    org_func[method] = virtual_table[method]
    hook_helper.virtual_protect(virtual_table + method, 4, 0x4, old_prot)

    virtual_table[method] = ffi.cast('intptr_t', ffi.cast(cast, func))
    hook_helper.virtual_protect(virtual_table + method, 4, old_prot[0], old_prot)

    return ffi.cast(cast, org_func[method])
end

new_hook.unHookMethod = function(method)
    hook_helper.virtual_protect(virtual_table + method, 4, 0x4, old_prot)
    local alloc_addr = hook_helper.virtual_alloc(nil, 5, 0x1000, 0x40, false)
    local trampoline_bytes = ffi.new('uint8_t[?]', 5, 0x90)

    trampoline_bytes[0] = 0xE9
    ffi.cast('int32_t*', trampoline_bytes + 1)[0] = org_func[method] - tonumber(alloc_addr) - 5

    hook_helper.copy(alloc_addr, trampoline_bytes, 5)
    virtual_table[method] = ffi.cast('intptr_t', alloc_addr)

    hook_helper.virtual_protect(virtual_table + method, 4, old_prot[0], old_prot)
    org_func[method] = nil
end

new_hook.unHookAll = function()
    for method, func in pairs(org_func) do
        new_hook.unHookMethod(method)
    end
end

table.insert(vmt_hook.hooks, new_hook.unHookAll)
    return new_hook
end

events.shutdown:set(function()
    for _, reset_function in ipairs(vmt_hook.hooks) do
        reset_function()
    end
end)

hooked_function = nil
ground_ticks, end_time = 1, 0
function updateCSA_hk(thisptr, edx)
    if entity.get_local_player() == nil or ffi.cast('uintptr_t', thisptr) == nil then return end
    local local_player = entity.get_local_player()
    local lp_ptr = get_entity_address(local_player:get_index())
    if arid.menu.globals.antiaim.animation_breakers:get("Legs direction") and arid.menu.globals.antiaim.enable_antiaim:get() then
        ffi.cast('float*', lp_ptr+10104)[0] = arid.ref.leg_movement:get('Sliding') and arid.ref.leg_movement:get('Default') or 
        (
            globals.tickcount % 4 == 0 and 0.5 or 0
        )
        local ticks = globals.tickcount
        if ticks % 3 == 0 then arid.ref.leg_movement:set('Sliding')
        elseif ticks % 3 == 1 then arid.ref.leg_movement:set('Default')
        end
    end
    if arid.menu.globals.antiaim.animation_breakers:get("Zero pitch on land") and arid.menu.globals.antiaim.enable_antiaim:get() then
        ffi.cast('float*', lp_ptr+10104)[12] = 0
    end
    hooked_function(thisptr, edx)
    if arid.menu.globals.antiaim.animation_breakers:get("Static legs in air") and arid.menu.globals.antiaim.enable_antiaim:get() then
        ffi.cast('float*', lp_ptr+10104)[6] = 1
    end
    if arid.menu.globals.antiaim.animation_breakers:get("Zero pitch on land") and arid.menu.globals.antiaim.enable_antiaim:get() then
        if bit.band(entity.get_local_player()["m_fFlags"], 1) == 1 then
            ground_ticks = ground_ticks + 1
        else
            ground_ticks = 0
            end_time = globals.curtime  + 1
        end
        if not arid.working_functions.in_air() and ground_ticks > 1 and end_time > globals.curtime then
            ffi.cast('float*', lp_ptr+10104)[12] = 0.5
        end
    end
    if arid.menu.globals.antiaim.animation_breakers:get("Move Body Lean") and arid.menu.globals.antiaim.enable_antiaim:get() then
    end
end


function anim_state_hook()
    local local_player = entity.get_local_player()
    if not local_player then return end

    local local_player_ptr = get_entity_address(local_player:get_index())
    if not local_player_ptr or hooked_function then return end
    local C_CSPLAYER = vmt_hook.new(local_player_ptr)
    hooked_function = C_CSPLAYER.hookMethod('void(__fastcall*)(void*, void*)', updateCSA_hk, 224)
end

events.createmove_run:set(anim_state_hook)
-- animation breakers end


arid.working_functions.viewmodel_changer = function()
    if arid.menu.globals.tab.viewmodel:get() and arid.menu.globals.tab.enable_misc:get() then
        cvar.viewmodel_fov:int(arid.menu.globals.tab.viewmodel_fov:get(), true)
		cvar.viewmodel_offset_x:float(arid.menu.globals.tab.viewmodel_x:get(), true)
		cvar.viewmodel_offset_y:float(arid.menu.globals.tab.viewmodel_y:get(), true)
		cvar.viewmodel_offset_z:float(arid.menu.globals.tab.viewmodel_z:get(), true)
    else
        cvar.viewmodel_fov:int(68)
        cvar.viewmodel_offset_x:float(2.5)
        cvar.viewmodel_offset_y:float(0)
        cvar.viewmodel_offset_z:float(-1.5)
    end
end

arid.working_functions.debug_panel = function()
    if arid.menu.globals.visuals.debug_enable:get() and arid.menu.globals.visuals.enable_interface:get()  then

    local lp = entity.get_local_player()
	if not lp then return end 
    local x_b, y_b = arid.menu.globals.visuals.debug_x:get(), arid.menu.globals.visuals.debug_y:get()
	local screensize = render.screen_size()
	local x = screensize.x
	local y = screensize.y                                         --
	local clr = arid.menu.globals.visuals.uiclr_debug:get()
    local clr_debug = clr:to_hex()
    local max_width = 0
    
    local net = utils.net_channel()
    local outgoing, incoming = net.latency[0], net.latency[1]
    local ping = math.max(0, (incoming-outgoing)*2500) 
    local body_yaw = math.min(math.abs(aa_refs.lby_mode:get("Opposite") and (rage.antiaim:get_max_desync() - rage.antiaim:get_rotation()/2) or (rage.antiaim:get_max_desync() - rage.antiaim:get_rotation())), 58)
    local alpha = math.min(math.floor(math.sin((globals.curtime%3) * 2) * 175+20), 255)

    render.rect(vector(x_b - 5, y_b + 17 ), vector(x_b + 97, y_b + 97 ), color(20, 20, 20, 220), 0)
    render.text(2, vector(x_b +18 , y_b ), color(255, 255, 255, 255), nil, "DEBUG    |  \a"..clr_debug.."  PANEL")
    render.text(2, vector(x_b , y_b + 27), color(255,255,255,255), nil, string.upper("\aFFFFFFFFNAME   | \a"..clr_debug.. "  "..common.get_username()))
    render.text(2, vector(x_b , y_b + 39), color(255,255,255,255), nil, string.upper("\a"..clr_debug.."PING \aFFFFFFFF  |  "..math.floor(ping).. " ms"))
    render.text(2, vector(x_b , y_b + 51), color(255,255,255,255), nil, string.upper("\aFFFFFFFFBODY  YAW   | \a"..clr_debug.. "  "..math.floor(body_yaw).." ° "))
    render.text(2, vector(x_b , y_b + 63), color(255,255,255,255), nil, string.upper("\a"..clr_debug.."BUILD \aFFFFFFFF  |  BETA"))
    render.text(2, vector(x_b , y_b + 75), color(255,255,255,255), nil, string.upper("\aFFFFFFFFPRESET   |  \a"..clr_debug.. ""..get_player_state()))
    render.rect_outline(vector(x_b - 15, y_b - 7 ), vector(x_b + 107, y_b + 117 ), color(255, 255, 255, ui.get_alpha()*255))--]]
    render.rect_outline(vector(x_b - 6, y_b + 14 ), vector(x_b + 98, y_b + 98 ), color(0, 0, 0, 255))
    render.rect(vector(x_b - 5, y_b + 15 ), vector(x_b + 97, y_b + 17 ), color(clr.r,clr.g,clr.b, alpha+240), 0)

    local mouse = ui.get_mouse_position()
        if common.is_button_down(1) and (ui.get_alpha() > 0.9) then
            if mouse.x >= x_b and mouse.y >= y_b and mouse.x <= x_b + 130 and mouse.y <= y_b + 117 or drag4 then
                if not drag4 then
                    drag4 = true
                else
                    arid.menu.globals.visuals.debug_x:set(mouse.x )
                    arid.menu.globals.visuals.debug_y:set(mouse.y )
                end
            end
        else
            drag4 = false
        end
    end
end

arid.working_functions.solusui = function()
    if arid.menu.globals.visuals.watermark_enable:get() and arid.menu.globals.visuals.enable_interface:get()  then

    local lp = entity.get_local_player()
	if not lp then return end 
    local x_b, y_b = arid.menu.globals.visuals.watermark_x:get(), arid.menu.globals.visuals.watermark_y:get()
	local screensize = render.screen_size()
	local x = screensize.x
	local y = screensize.y                                         --
	local clr = arid.menu.globals.visuals.uiclr:get()
    local max_width = 0
    local frametime = globals.frametime * 16
    width_ka5 = lerp(frametime,width_ka5,math.max(max_width, 150-11))
    


    local avatar = lp:get_steam_avatar()
	local alpha = math.abs(1 * math.cos(2 * math.pi * (globals.curtime + 3) / 5)) * 255
	local alpha2 = math.abs(1 * math.cos(2 * math.pi * globals.curtime / 5)) * 255
    local anim = render_gradient_text(clr.r, clr.g, clr.b, alpha, 255, 255, 255, 0, string.upper('USER  :  '..common.get_username()..''))
	local anim1 = render_gradient_text(255, 255, 255, 0, clr.r, clr.g, clr.b, alpha2, string.upper('USER  :  '..common.get_username()..''))
    if arid.menu.globals.visuals.gradient:get() then
    render.rect(vector(x_b - 2, y_b - 2  ),  vector(x_b + 125, y_b + 40 ), color(20,20,20,240), 8)
    render.circle_outline(vector(x_b+2, y_b + 34.75), color(clr.r,clr.g,clr.b,240), 6, 100, 0.30, 2)
    render.circle_outline(vector(x_b + 121.5, y_b + 34.75), color(clr.r,clr.g,clr.b,240), 6, -30, 0.35, 2)
    render.rect(vector(x_b, y_b + 38  ),  vector(x_b + 123, y_b + 40), color(clr.r,clr.g,clr.b,240), 8)
    end
    render.texture(avatar, vector(x_b + 5, y_b + 3), vector(30, 30), color(), 0)
    render.text(2, vector(x_b + 40, y_b + 6), color(255, 255, 255, 255), "", string.upper("arid.sys"))
    render.text(2, vector(x_b + 40, y_b + 17), color(255,255,255,255), "", string.upper("USER  :  "..common.get_username()..""))
    render.text(2, vector(x_b + 40, y_b + 17), color(0, 0, 0), nil, anim)
    render.text(2, vector(x_b + 40, y_b + 17), color(0, 0, 0), nil, anim1)
    render.rect_outline(vector(x_b - 7, y_b - 7 ), vector(x_b + 130, y_b + 45 ), color(255, 255, 255, ui.get_alpha()*255))--]]

    local mouse = ui.get_mouse_position()
        if common.is_button_down(1) and (ui.get_alpha() > 0.9) then
            if mouse.x >= x_b and mouse.y >= y_b and mouse.x <= x_b + 130 and mouse.y <= y_b + 70 or drag2 then
                if not drag2 then
                    drag2 = true
                else
                    arid.menu.globals.visuals.watermark_x:set(mouse.x )
                    arid.menu.globals.visuals.watermark_y:set(mouse.y )
                end
            end
        else
            drag2 = false
        end
    end
end

function leerp(start, vend, time)
    return start + (vend - start) * time
end

local screen_size = render.screen_size()
local screen_center = screen_size / 2

local custom_scope_positions = {}
local custom_scope_generate = function()
    local line = arid.menu.globals.visuals.custom_scope_overlay_line:get() * 4.2
    local gap = arid.menu.globals.visuals.custom_scope_overlay_gap:get() * 5.5
    local overlay_color = arid.menu.globals.visuals.custom_scope_overlay_color:get()


    
    local hash = tostring(line) .. tostring(gap) .. tostring(overlay_color)
    if not custom_scope_positions[hash] then
        custom_scope_positions[hash] = {}

        -- right
        custom_scope_positions[hash][#custom_scope_positions[hash] + 1] = {
            position = {screen_center + vector(gap + 1, 0), screen_center + vector(line, 1)},
            color = {overlay_color, color(overlay_color.r, overlay_color.g, overlay_color.b, 0), overlay_color, color(overlay_color.r, overlay_color.g, overlay_color.b, 0)}
        }

        -- left
        custom_scope_positions[hash][#custom_scope_positions[hash] + 1] = {
            position = {screen_center - vector(gap, -1), screen_center - vector(line, 0)},
            color = {overlay_color, color(overlay_color.r, overlay_color.g, overlay_color.b, 0), overlay_color, color(overlay_color.r, overlay_color.g, overlay_color.b, 0)}
        }

        -- up
        custom_scope_positions[hash][#custom_scope_positions[hash] + 1] = {
            position = {screen_center - vector(0, gap), screen_center - vector(-1, line)},
            color = {overlay_color, overlay_color, color(overlay_color.r, overlay_color.g, overlay_color.b, 0), color(overlay_color.r, overlay_color.g, overlay_color.b, 0)}
        }

        -- down
        custom_scope_positions[hash][#custom_scope_positions[hash] + 1] = {
            position = {screen_center + vector(0, gap + 1), screen_center + vector(1, line)},
            color = {overlay_color, overlay_color, color(overlay_color.r, overlay_color.g, overlay_color.b, 0), color(overlay_color.r, overlay_color.g, overlay_color.b, 0)}
        }
    end

    return custom_scope_positions[hash]
end

local anim1 = 0
local scope_overlay = ui.find("Visuals", "World", "Main", "Override Zoom", "Scope Overlay")

arid.working_functions.customscope = function()
    local local_player = entity.get_local_player()
    if not local_player then
        return
    end

    if not local_player:is_alive() then
        return
    end
    
    if not local_player.m_bIsScoped then return end

    
    anim1 = local_player.m_bIsScoped and leerp(globals.frametime * 75, anim1, 100) or leerp(globals.frametime * 75, anim1, 0)
    

    
    scope_overlay:override()
    if arid.menu.globals.visuals.custom_scope_overlay:get() and arid.menu.globals.visuals.enable_visuals:get() then
        scope_overlay:override("Remove All")
        
        local scope_overlay = custom_scope_generate()
        for key, value in pairs(scope_overlay) do
            local color1, color2, color3, color4 = value.color[1], value.color[2], value.color[3], value.color[4]
            color1 = color(color1.r, color1.g, color1.b, color1.a * anim1)
            color2 = color(color2.r, color2.g, color2.b, color2.a * anim1)
            color3 = color(color3.r, color3.g, color3.b, color3.a * anim1)
            color4 = color(color4.r, color4.g, color4.b, color4.a * anim1)
            
            render.gradient(value.position[1], value.position[2], color1, color2, color3, color4)
        end
    end
end


function state()
    if not entity.get_local_player() then return end
    local flags = entity.get_local_player().m_fFlags
    local first_velocity = entity.get_local_player()['m_vecVelocity[0]']
    local second_velocity = entity.get_local_player()['m_vecVelocity[1]']
    local velocity = math.floor(math.sqrt(first_velocity*first_velocity+second_velocity*second_velocity))
    if bit.band(flags, 1) == 1 then
        if bit.band(flags, 4) == 4 then
            return 4
        else
            if velocity <= 3 then
                return 1
            else
                if ui.find("Aimbot", "Anti Aim", "Misc", "Slow Walk"):get() then
                    return 3
                else
                    return 2
                end
            end
        end
    elseif bit.band(flags, 1) == 0 then
        if bit.band(flags, 4) == 4 then
            return 6
        else
            return 5
        end
    end
end


function leerp(time, start, endd)
    return start * (1-time) + endd * time
end

local isMD = ui.find("Aimbot", "Ragebot", "Selection", "Minimum Damage")
local isBA = ui.find("Aimbot", "Ragebot", "Safety", "Body Aim")
local isSP = ui.find("Aimbot", "Ragebot", "Safety", "Safe Points")
local isDT = ui.find("Aimbot", "Ragebot", "Main", "Double Tap")
local isAP = ui.find("Aimbot", "Ragebot", "Main", "Peek Assist")
local isSW = ui.find("Aimbot", "Anti Aim", "Misc", "Slow Walk")
local isHS = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots")
local isFS = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding")
local isFD = ui.find("Aimbot", "Anti Aim", "Misc", "Fake Duck")
local scope_overlay = ui.find("Visuals", "World", "Main", "Override Zoom", "Scope Overlay")
arid.anim_dt = 0
arid.anim_dt_alpha = 0
arid.anim_hs = 0
arid.anim_hs_alpha = 0
arid.anim_qp = 0
arid.anim_qp_alpha = 0
arid.anim_ba_alpha = 0
arid.anim_sp_alpha = 0
arid.anim_fs_alpha = 0
arid.anim_scoped = 0
arid.anim_scoped_dt = 0
arid.anim_scoped_beta = 0
arid.anim_scoped_sp = 0
arid.lerp_box = 0
arid.anim_dt_2 = 0
arid.anim_dt_fake = 0
arid.anim_hs_fake = 0
arid.anim_fake = 0
arid.anim_scoped_arid = 0
arid.anim_scoped_fake = 0
arid.anim_scoped_condition = 0
arid.anim_scoped_charging = 0
arid.anim_scoped_ready = 0
arid.anim_scoped_charging1 = 0
arid.anim_scoped_ready1 = 0



arid.working_functions.indicatorsy = function()
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return end
    if not arid.menu.globals.visuals.indicators2:get() and arid.menu.globals.visuals.indicators_type:get() == 'Default' and arid.menu.globals.visuals.enable_visuals:get()  then return end

    if arid.menu.globals.visuals.indicators2:get() and arid.menu.globals.visuals.indicators_type:get() == 'Default' and arid.menu.globals.visuals.enable_visuals:get()  then
        local x = render.screen_size().x
        local y = render.screen_size().y
        local local_player = entity.get_local_player()

        local scoped = local_player.m_bIsScoped
        local eternal_ts = render.measure_text(arid.visuals.font.pixel9, nil, "arid.sys")
        local eternal_ts_beta = render.measure_text(arid.visuals.font.pixel9, nil, "beta")
        local eternal_ts_ts = render.measure_text(arid.visuals.font.pixel9, nil, "DT")
    
if scoped then
arid.anim_scoped = leerp(globals.frametime * 8, arid.anim_scoped, (eternal_ts.x/2)+4)
arid.anim_scoped_sp = leerp(globals.frametime * 8, arid.anim_scoped_sp, 25)
arid.anim_scoped_dt = leerp(globals.frametime * 8, arid.anim_scoped_dt, 10)
arid.anim_scoped_beta = leerp(globals.frametime * 8, arid.anim_scoped_beta, (eternal_ts_beta.x/2)+4)
 else
arid.anim_scoped = leerp(globals.frametime * 8, arid.anim_scoped, 0)
arid.anim_scoped_dt = leerp(globals.frametime * 8, arid.anim_scoped_dt, 0)
arid.anim_scoped_beta = leerp(globals.frametime * 8, arid.anim_scoped_beta, 0)
arid.anim_scoped_sp = leerp(globals.frametime * 8, arid.anim_scoped_sp, 0)
end

        local indclr = arid.menu.globals.visuals.color23:get()

        local ay = 24
        local alpha = math.min(math.floor(math.sin((globals.curtime%3) * 2) * 175+20), 255)
        render.text(arid.visuals.font.pixel9, vector(x/2 - eternal_ts_beta.x/2 + arid.anim_scoped_beta, y/2+ay-9), color(255,255,255, alpha+220), nil, "beta")
        local lp_ax = 9
        render.text(arid.visuals.font.pixel9, vector(x/2 + arid.anim_scoped - eternal_ts.x/2, y/2+ay-9+lp_ax), color(indclr.r, indclr.g, indclr.b, 255), nil, "arid.sys")
        
        local asadsa = math.min(math.floor(math.sin((rage.exploit:get()%2) *1) * 122), 100)
        

        if isDT:get() then
            arid.anim_dt = leerp(globals.frametime * 8, arid.anim_dt, 9)
            arid.anim_dt_alpha = leerp(globals.frametime * 8, arid.anim_dt_alpha, 255)
        else
            arid.anim_dt = leerp(globals.frametime * 8, arid.anim_dt, 0)
            arid.anim_dt_alpha = leerp(globals.frametime * 8, arid.anim_dt_alpha, 0)
        end

        
        if isBA:get() == "Force" then
            arid.anim_ba_alpha = leerp(globals.frametime * 8, arid.anim_ba_alpha, 255)
        else
            arid.anim_ba_alpha = leerp(globals.frametime * 8, arid.anim_ba_alpha, 128)
        end

        
        if isSP:get() == "Force" then
            arid.anim_sp_alpha = leerp(globals.frametime * 8, arid.anim_sp_alpha, 255)
        else
            arid.anim_sp_alpha = leerp(globals.frametime * 8, arid.anim_sp_alpha, 128)
        end

        
        if isFS:get() then
            arid.anim_fs_alpha = leerp(globals.frametime * 8, arid.anim_fs_alpha, 255)
        else
            arid.anim_fs_alpha = leerp(globals.frametime * 8, arid.anim_fs_alpha, 128)
        end

        if isDT:get() then
            render.text(arid.visuals.font.pixel9, vector(x/2 + arid.anim_scoped_dt - eternal_ts_ts.x/2, y/2+ay + arid.anim_dt), rage.exploit:get() == 1 and color(255, 255, 255, arid.anim_dt_alpha) or color(255, 0, 0, arid.anim_dt_alpha), nil, "DT")
        else
            render.text(arid.visuals.font.pixel9, vector(x/2 + arid.anim_scoped_dt - eternal_ts_ts.x/2, y/2+ay + arid.anim_dt), rage.exploit:get() == 1 and color(0, 255, 0, arid.anim_dt_alpha) or color(255, 0, 0, arid.anim_dt_alpha), nil, "DT")
        end





        local ax = 0
        if isHS:get() then
            arid.anim_hs = leerp(globals.frametime * 8, arid.anim_hs, 9)
            arid.anim_hs_alpha = leerp(globals.frametime * 8, arid.anim_hs_alpha, 255)
        else
            arid.anim_hs = leerp(globals.frametime * 8, arid.anim_hs, 0)
            arid.anim_hs_alpha = leerp(globals.frametime * 8, arid.anim_hs_alpha, 0)
        end
        if isHS:get() then
            render.text(arid.visuals.font.pixel9, vector(x/2 + arid.anim_scoped_dt - 6, y/2+ay + arid.anim_hs + arid.anim_dt), color(255, 255, 255, arid.anim_hs_alpha), nil, "HS")
        end


        local ax = 0
        if isAP:get() then
            arid.anim_qp = leerp(globals.frametime * 8, arid.anim_qp, 9) 
            arid.anim_qp_alpha = leerp(globals.frametime * 8, arid.anim_qp_alpha, 255)
        else
            arid.anim_qp = leerp(globals.frametime * 8, arid.anim_qp, 0)
            arid.anim_qp_alpha = leerp(globals.frametime * 8, arid.anim_qp_alpha, 0)
        end
        if isAP:get() then
            render.text(arid.visuals.font.pixel9, vector(x/2 + arid.anim_scoped_dt - 6, y/2+ay + arid.anim_qp + arid.anim_hs + arid.anim_dt), color(255, 255, 255, arid.anim_qp_alpha), nil, "QP")
        end

        render.text(arid.visuals.font.pixel9, vector(x/2 + arid.anim_scoped_sp - 21, y/2+ay + 9 + arid.anim_qp +arid.anim_dt+arid.anim_hs), color(255, 255, 255, arid.anim_ba_alpha), nil, "BA")
        ax = ax + render.measure_text(arid.visuals.font.pixel9, nil, "DMG ").x

        render.text(arid.visuals.font.pixel9, vector(x/2+ax + arid.anim_scoped_sp - 29, y/2+ay + 9 + arid.anim_qp +arid.anim_dt+arid.anim_hs), color(255, 255, 255, arid.anim_sp_alpha), nil, "SP")
        ax = ax + render.measure_text(arid.visuals.font.pixel9, nil, "SP ").x

        render.text(arid.visuals.font.pixel9, vector(x/2+ax + arid.anim_scoped_sp - 31, y/2+ay + 9 + arid.anim_qp +arid.anim_dt+arid.anim_hs),  color(255, 255, 255, arid.anim_fs_alpha), nil, "FS")
        ax = ax + render.measure_text(arid.visuals.font.pixel9, nil, "FS ").x
    end

    if arid.menu.globals.visuals.indicators2:get() and arid.menu.globals.visuals.indicators_type:get() == 'Modern' and arid.menu.globals.visuals.enable_visuals:get()  then
        local x = render.screen_size().x
        local y = render.screen_size().y
        local local_player = entity.get_local_player()

       local scoped = local_player.m_bIsScoped
       local color_1 = arid.menu.globals.visuals.color23:get()
       local eternal_ts = render.measure_text(arid.visuals.font.pixel9, nil, "arid.sys")
       local eternal_ts6 = render.measure_text(arid.visuals.font.pixel9, nil, "arid.sys yaw")
       local eternal_ts2 = render.measure_text(arid.visuals.font.pixel9, nil, "FAKELAG")
       local eternal_ts3 = render.measure_text(arid.visuals.font.pixel9, nil, "-"..get_player_state().."-")
       local eternal_ts4 = render.measure_text(arid.visuals.font.pixel9, nil, "DT CHARGING")
       local eternal_ts5 = render.measure_text(arid.visuals.font.pixel9, nil, "DT READY")

        if scoped then
            arid.anim_scoped_arid = leerp(globals.frametime * 8, arid.anim_scoped_arid, eternal_ts6.x/2+3)
            arid.anim_scoped_fake = leerp(globals.frametime * 8, arid.anim_scoped_fake, eternal_ts2.x/2+5)
            arid.anim_scoped_condition = leerp(globals.frametime * 8, arid.anim_scoped_condition, eternal_ts3.x/2+5)
            arid.anim_scoped_charging = leerp(globals.frametime * 8, arid.anim_scoped_charging, eternal_ts4.x/2+5)
            arid.anim_scoped_ready = leerp(globals.frametime * 8, arid.anim_scoped_ready, eternal_ts5.x/2+5)
        else
            arid.anim_scoped_arid = leerp(globals.frametime * 8, arid.anim_scoped_arid, 0)
            arid.anim_scoped_fake = leerp(globals.frametime * 8, arid.anim_scoped_fake, 0)
            arid.anim_scoped_condition = leerp(globals.frametime * 8, arid.anim_scoped_condition, 0)
            arid.anim_scoped_charging = leerp(globals.frametime * 8, arid.anim_scoped_charging, 0)
            arid.anim_scoped_ready = leerp(globals.frametime * 8, arid.anim_scoped_ready, 0)
        end

        local indclr = arid.menu.globals.visuals.color23:get()


        local ay = 24
        local alpha = math.min(math.floor(math.sin((globals.curtime%3) * 2) * 175+20), 255)
        if isDT:get() then
            arid.anim_dt = leerp(globals.frametime * 8, arid.anim_dt, 9)
            arid.anim_dt_fake = leerp(globals.frametime * 8, arid.anim_dt_fake, 0)
            arid.anim_dt_alpha = leerp(globals.frametime * 8, arid.anim_dt_alpha, 255)
        else
            arid.anim_dt = leerp(globals.frametime * 8, arid.anim_dt, 0)
            arid.anim_dt_fake = leerp(globals.frametime * 8, arid.anim_dt_fake, 9)
            arid.anim_dt_alpha = leerp(globals.frametime * 8, arid.anim_dt_alpha, 0)
        end

        if isHS:get() then
            arid.anim_hs = leerp(globals.frametime * 8, arid.anim_hs, 9)
            arid.anim_hs_fake = leerp(globals.frametime * 8, arid.anim_hs_fake, 0)
            arid.anim_hs_alpha = leerp(globals.frametime * 8, arid.anim_hs_alpha, 255)
        else
            arid.anim_hs = leerp(globals.frametime * 8, arid.anim_hs, 0)
            arid.anim_hs_fake = leerp(globals.frametime * 8, arid.anim_hs_fake, 9)
            arid.anim_hs_alpha = leerp(globals.frametime * 8, arid.anim_hs_alpha, 0)
        end


        render.text(arid.visuals.font.pixel9, vector(x/2 + arid.anim_scoped_arid - eternal_ts.x/2 - 8, y/2+8), color(255, 255, 255, 255), nil, "arid.sys")
        render.text(arid.visuals.font.pixel9, vector(x/2 + arid.anim_scoped_arid + 11, y/2+8), color(indclr.r, indclr.g, indclr.b, alpha+220), nil, "yaw")

        local gradient_animation = gradient.text_animate("READY", -2, {
            color(255, 255, 255), 
            color(123, 255, 36)
        })
        local gradient_animation2 = gradient.text_animate("CHARGING", -2, {
            color(140, 140, 140), 
            color(255, 0, 0)
        })
        local gradient_animation3 = gradient.text_animate("FAKELAG", -2, {
            color(140, 140, 140), 
            color(255, 255, 255)
        })
    if isDT:get() then
        arid.anim_fake = leerp(globals.frametime * 8, arid.anim_fake, 0)
        if rage.exploit:get() == 1 then
            arid.anim_dt_2 = leerp(globals.frametime * 8, arid.anim_dt_2, 15)
            render.text(arid.visuals.font.pixel9, vector(x/2 + arid.anim_scoped_ready - 4 - arid.anim_dt_2, y/2 + arid.anim_dt+8), color(255, 255, 255, arid.anim_dt_alpha), nil, "DT "..gradient_animation:get_animated_text())
        elseif rage.exploit:get() ~= 1 then
            arid.anim_dt_2 = leerp(globals.frametime * 8, arid.anim_dt_2, 24)
            render.text(arid.visuals.font.pixel9, vector(x/2 + arid.anim_scoped_charging - 4 - arid.anim_dt_2, y/2 + arid.anim_dt+8), color(255, 255, 255, arid.anim_dt_alpha), nil, "DT "..gradient_animation2:get_animated_text())
        end
    else
        arid.anim_fake = leerp(globals.frametime * 8, arid.anim_fake, 255)
        render.text(arid.visuals.font.pixel9, vector(x/2 + arid.anim_scoped_fake - eternal_ts2.x/2, y/2 + arid.anim_dt_fake+8), color(255, 255, 255, arid.anim_fake), nil, gradient_animation3:get_animated_text())
    end
    render.text(arid.visuals.font.pixel9, vector(x/2 + arid.anim_scoped_condition - eternal_ts3.x/2, y/2 + arid.anim_dt + arid.anim_dt_fake+17), color(255, 255, 255), nil,"-"..get_player_state().."-")
        gradient_animation:animate()
        gradient_animation2:animate()
        gradient_animation3:animate()
    end
end



--end visuals region#--

--start global region#--

arid.menu.globals.aspect_ratio = function()
    if not arid.menu.globals.tab.enable_misc:get() then return end
    if arid.menu.globals.tab.aspect_ratio:get() then
        cvar.r_aspectratio:float(arid.menu.globals.tab.aspect_ratio_change:get()/10)
    end

end

local phrases = {
   "最好的 arid.LUA！想击败世界上最好的吗？使用 arid.SYS，您将永远领先对手一步",
   "чертов бот",
   "блядь, иди умывайся",
   "1",
   "ты ебаный аист",
   "оближи мой член и я убью тебя за это время",
   "Я использую arid.SYS и горжусь (`・ω・´)",
   "Ты слышал о КУРУМИ, потому что ты просто лжешь облажался. ლ(ಠ益ಠლ",
   "трахни всю свою семью с тобой на земле",
   "но я трахнул тебя хахахаха",
   "Трахни меня, учись играть",
   "1 собака бля что случилось?",
   "тебе лучше записаться на какой-нибудь класс",
   "почему ты плачешь каждый день?",
   "генетическое и скриптовое доминирование",
   "fucking botik hahahhah! 1",
   "𝕘𝕖𝕥 𝕠𝕨𝕟𝕖𝕕 𝕒𝕟𝕕 𝕤𝕥𝕒𝕪 𝕤𝕒𝕗𝕖 𝕨𝕚𝕥𝕙 𝕒𝕣𝕚𝕕",
   "wait who r u??",
   "подожди, как тебя зовут, блядь, без имени?",
   "最好的 arid.LUA！想击败世界上最好的吗？使用 arid.SYS，您将永远领先对手一步",
   "𝕘𝕖𝕥 𝕠𝕨𝕟𝕖𝕕 𝕒𝕟𝕕 𝕤𝕥𝕒𝕪 𝕤𝕒𝕗𝕖 𝕨𝕚𝕥𝕙 𝕒𝕣𝕚𝕕",
   "هل تعتقد حقًا أن antiaim 90 درجة كافٍ لـarid user?????",
   "𝕚 𝕒𝕞 𝕥𝕠𝕡 𝟙 𝕗𝕠𝕣 𝕞𝕪 𝙛𝙖𝙢𝙞𝙡𝙮 𝕒𝕟𝕕 𝙖𝙧𝙞𝙙.𝙡𝙪𝙖",
   "i off ur antiaim with arid  (◣_◢)",
   "。。。。我的意思是有arid beta的就是300 没arid beta的就是600 都是全套啊。。。。",
   "ANGRY CUZ OWNED ? ? ? ? arid BETA。。 arid.sbs 操你的屁股",
   "獲取arid beta，然後與狗交談",
   "принадлежит вашей собаке по оси бета arid.sbs",
   "𝕕𝕚𝕕 𝕦 𝕣𝕝𝕪 𝕥𝕙𝕚𝕟𝕜 𝕦 𝕔𝕒𝕟 𝕜𝕚𝕝𝕝 𝕒𝕣𝕚𝕕 𝕦𝕤𝕖𝕣 ?? ?  ? (◣_◢)",
   "𝔀𝓮𝓪𝓴 𝓻𝓪𝓽 𝓸𝔀𝓷𝓮𝓭 𝓯𝓽. 𝓪𝓻𝓲𝓭"

}

local function get_phrase()
    return phrases[utils.random_int(1, #phrases)]:gsub('"', '')
end


events.player_death:set(function(e)
    local localplayer = entity.get_local_player()
    local victim = entity.get(e.userid, true)
    
    if arid.menu.globals.tab.trashtalk:get() and arid.menu.globals.tab.enable_misc:get() then
    local me = entity.get_local_player()
    local attacker = entity.get(e.attacker, true)

    if me == attacker then
        utils.console_exec('say "' .. get_phrase() .. '"')
    end
end
end)


--end global region#--

--start anti-brute region#--



--end anti-brute region#--

--start builder region#--


menu_condition = {}
for a, b in pairs(arid.antiaim.aa_states2) do
    menu_condition[a] = {
        enable = arid.menu.ui.antiaim_builder:switch("Enable " .. arid.antiaim.aa_states[a]),
        left_yaw_add = arid.menu.ui.antiaim_builder:slider("["..b.."] Left Yaw Add", -180, 180, 0),
        right_yaw_add = arid.menu.ui.antiaim_builder:slider("["..b.."] Right Yaw Add", -180, 180, 0),
        yaw_modifier = arid.menu.ui.antiaim_builder:combo("["..b.."] Yaw Modifier", aa_refs.yaw_modifier:get_list()),
        modifier_offset = arid.menu.ui.antiaim_builder:slider("["..b.."] Modifier Offset", -180, 180, 0),
        options = arid.menu.ui.antiaim_builder:selectable("["..b.."] Options", aa_refs.options:get_list()),
        desync_freestanding = arid.menu.ui.antiaim_builder:combo("["..b.."] Freestanding", aa_refs.desync_freestanding:get_list()),
        on_shot = arid.menu.ui.antiaim_builder:combo("["..b.."] On Shot", aa_refs.on_shot:get_list()),
        lby_mode = arid.menu.ui.antiaim_builder:combo("["..b.."] Lby Mode", aa_refs.lby_mode:get_list()),
        left_limit = arid.menu.ui.antiaim_builder:slider("["..b.."] Left Limit", 0, 60, 60),
        right_limit = arid.menu.ui.antiaim_builder:slider("["..b.."] Right Limit", 0, 60, 60),
    }
end



get_player_state = function()
    local_player = entity.get_local_player()
    if not local_player then return "Not connected" end
    
    on_ground = bit.band(local_player.m_fFlags, 1) == 1
    jump = bit.band(local_player.m_fFlags, 1) == 0
    crouch = local_player.m_flDuckAmount > 0.7
    fakeduck2 = aa_refs.fakeduck:get()
    vx, vy, vz = local_player.m_vecVelocity.x, local_player.m_vecVelocity.y, local_player.m_vecVelocity.z
    math_velocity = math.sqrt(vx ^ 2 + vy ^ 2)
    move = math_velocity > 5

    if fakeduck2 then return "Fakeduck" end
    if jump and crouch then return "Jump+Crouch" end
    if jump then return "Jump" end
    if crouch then return "Crouch" end
    if on_ground and aa_refs.slowwalk:get() and move then return "Slowwalk" end
    if on_ground and not move then return "Standing" end
    if on_ground and move then return "Running" end
end

arid.working_functions.antiaim = function()
    if arid.menu.globals.antiaim.enable_antiaim:get() then
    aa_refs.backstab:override(arid.menu.globals.antiaim.aa_tweaks:get('Anti-Backstab'))
    arid.ref.dormant_aimbot:override(arid.menu.globals.antiaim.aa_tweaks:get('Dormant Aimbot'))
    end
    if arid.menu.globals.antiaim.aa_tweaks:get('Fake Pitch Exploit') and arid.menu.globals.antiaim.enable_antiaim:get() then
        if globals.tickcount % 4 == math.random(0,10) then
            aa_refs.pitch:set("Fake Up")
        else
            aa_refs.pitch:set("Down")
        end
    end
    local_player = entity.get_local_player()
    if not local_player then return end
    if arid.menu.globals.antiaim.enable_antiaim:get() == false then return end
    if arid.menu.globals.antiaim.custom_aa:get() == "Condictional" == false then return end

    invert_state = (math.normalize_yaw(local_player:get_anim_state().eye_yaw - local_player:get_anim_state().abs_yaw) <= 0)

    if menu_condition[2].enable:get() and get_player_state() == "Standing" then aaid = 2
    elseif menu_condition[3].enable:get() and get_player_state() == "Running" then aaid = 3
    elseif menu_condition[4].enable:get() and get_player_state() == "Slowwalk" then aaid = 4
    elseif menu_condition[5].enable:get() and get_player_state() == "Crouch" then aaid = 5
    elseif menu_condition[6].enable:get() and get_player_state() == "Jump" then aaid = 6
    elseif menu_condition[7].enable:get() and get_player_state() == "Jump+Crouch" then aaid = 7 
    elseif menu_condition[8].enable:get() and get_player_state() == "Fakeduck" then aaid = 8
    elseif menu_condition[8].enable:get() and get_player_state() == "Fakelag" then aaid = 9
    else
        aaid = 1
    end

    left_yaw_add = menu_condition[aaid].left_yaw_add:get()
    right_yaw_add = menu_condition[aaid].right_yaw_add:get()
    yaw_modifier = menu_condition[aaid].yaw_modifier:get()
    modifier_offset = menu_condition[aaid].modifier_offset:get()
    options = menu_condition[aaid].options:get()
    desync_freestanding = menu_condition[aaid].desync_freestanding:get()
    on_shot = menu_condition[aaid].on_shot:get()
    lby_mode = menu_condition[aaid].lby_mode:get()
    left_limit = menu_condition[aaid].left_limit:get()
    right_limit = menu_condition[aaid].right_limit:get()
    
    aa_refs.offset:override(invert_state and right_yaw_add or left_yaw_add)
    aa_refs.yaw_modifier:override(yaw_modifier)
    aa_refs.modifier_offset:override(modifier_offset)
    aa_refs.options:override(options)
    aa_refs.desync_freestanding:override(desync_freestanding)
    aa_refs.on_shot:override(on_shot)
    aa_refs.lby_mode:override(lby_mode)
    aa_refs.left_limit:override(left_limit)
    aa_refs.right_limit:override(right_limit)
    aa_refs.base:override(aa_refs.base:get())

    if manual_yaw_base:get() == "Left" then
        aa_refs.offset:override(-85)
        aa_refs.base:override("Local View")
    elseif manual_yaw_base:get() == "Right" then
        aa_refs.offset:override(85)
        aa_refs.base:override("Local View")
    elseif manual_yaw_base:get() == "Forward" then
        aa_refs.offset:override(180)
        aa_refs.base:override("Local View")
    end
end

arid.working_functions.menu_ui = function()
    menu_condition[1].enable:set(true)
    aa_work = arid.menu.globals.antiaim.enable_antiaim:get()
    builder_work = arid.menu.globals.antiaim.custom_aa:get() == "Condictional"
    cond_select = arid.menu.globals.antiaim.condition:get()
    all_work = aa_work and builder_work
    arid.menu.globals.antiaim.condition:set_visible(all_work)
    manual_yaw_base:set_visible(aa_work)
    
    for a, b in pairs(arid.antiaim.aa_states2) do
        need_select = cond_select == arid.antiaim.aa_states[a]
        all_work2 = all_work and menu_condition[a].enable:get() and cond_select == arid.antiaim.aa_states[a]
        menu_condition[a].enable:set_visible(all_work and need_select)
        menu_condition[1].enable:set_visible(false)
        menu_condition[a].left_yaw_add:set_visible(all_work2)
        menu_condition[a].right_yaw_add:set_visible(all_work2)
        menu_condition[a].yaw_modifier:set_visible(all_work2)
        menu_condition[a].modifier_offset:set_visible(all_work2 and menu_condition[a].yaw_modifier:get() ~= "Disabled")
        menu_condition[a].options:set_visible(all_work2)
        menu_condition[a].desync_freestanding:set_visible(all_work2)
        menu_condition[a].on_shot:set_visible(all_work2)
        menu_condition[a].lby_mode:set_visible(all_work2)
        menu_condition[a].left_limit:set_visible(all_work2)
        menu_condition[a].right_limit:set_visible(all_work2)
    end
end











arid.menu.globals.tab.configs_list = arid.menu.ui.global_configs:list("Currently loaded:", {"Default \a"..sidebar_color.."(by admin)", "Meta Preset \a"..sidebar_color.."(experimental preset)","My Preset \a"..sidebar_color.."(by "..common.get_username()..")"}) -- ventu 1 -- default 2


----- CONFIG SYSTERM

arid.functions.get_config_from_elements = {
    arid.menu.globals.tab.loading_animation,
    arid.menu.globals.visuals.debug_enable,
    arid.menu.globals.visuals.debug_x,
    arid.menu.globals.visuals.debug_y,
    arid.menu.globals.tab.notifications,
    arid.menu.globals.tab.notifications_select,
    arid.menu.globals.tab.jumpscout_fix,
    pos_x,
    pos_y,
    pos_x1,
    pos_y1,
    arid.menu.globals.antiaim.enable_antiaim,
    arid.menu.globals.antiaim.custom_aa,
    arid.menu.globals.antiaim.animation_breakers,
    arid.menu.globals.antiaim.aa_tweaks,
    arid.menu.globals.visuals.enable_visuals,
    arid.menu.globals.visuals.enable_interface,     
    arid.menu.globals.visuals.keybinds_enable,
    arid.menu.globals.visuals.watermark_enable,
    arid.menu.globals.visuals.debug_enable,
    arid.menu.globals.visuals.spectators_enable,
    arid.menu.globals.visuals.solus_combo,
    arid.menu.globals.visuals.watermark_x,
    arid.menu.globals.visuals.watermark_y,
    arid.menu.globals.visuals.indicators2,
    arid.menu.globals.visuals.indicators_type,
    arid.menu.globals.visuals.aimbot_logs,
    arid.menu.globals.visuals.logs_features,
    arid.menu.globals.visuals.custom_scope_overlay,
    arid.menu.globals.visuals.custom_scope_overlay_line,
    arid.menu.globals.visuals.custom_scope_overlay_gap,
    arid.menu.globals.tab.jumpscout_fix,
    arid.menu.globals.tab.enable_misc,
    arid.menu.globals.tab.aspect_ratio,
    arid.menu.globals.tab.aspect_ratio_change,
    arid.menu.globals.tab.trashtalk,
    arid.menu.globals.tab.viewmodel,
    arid.menu.globals.tab.viewmodel_fov,
    arid.menu.globals.tab.viewmodel_x,
    arid.menu.globals.tab.viewmodel_y,
    arid.menu.globals.tab.viewmodel_z,
    arid.menu.globals.tab.hitchance_modifier,
    arid.menu.globals.tab.hitchance_modifier_noscope,
    arid.menu.globals.tab.hitchance_modifier_inair,
    arid.menu.globals.tab.fastladder,
    menu_condition[8].enable,
    menu_condition[8].left_yaw_add,
    menu_condition[8].right_yaw_add,
    menu_condition[8].yaw_modifier,
    menu_condition[8].modifier_offset,
    menu_condition[8].options,
    menu_condition[8].desync_freestanding,
    menu_condition[8].on_shot,
    menu_condition[8].lby_mode,
    menu_condition[8].left_limit,
    menu_condition[8].right_limit,
    menu_condition[7].enable,
    menu_condition[7].left_yaw_add,
    menu_condition[7].right_yaw_add,
    menu_condition[7].yaw_modifier,
    menu_condition[7].modifier_offset,
    menu_condition[7].options,
    menu_condition[7].desync_freestanding,
    menu_condition[7].on_shot,
    menu_condition[7].lby_mode,
    menu_condition[7].left_limit,
    menu_condition[7].right_limit,
    menu_condition[6].enable,
    menu_condition[6].left_yaw_add,
    menu_condition[6].right_yaw_add,
    menu_condition[6].yaw_modifier,
    menu_condition[6].modifier_offset,
    menu_condition[6].options,
    menu_condition[6].desync_freestanding,
    menu_condition[6].on_shot,
    menu_condition[6].lby_mode,
    menu_condition[6].left_limit,
    menu_condition[6].right_limit,
    menu_condition[5].enable,
    menu_condition[5].left_yaw_add,
    menu_condition[5].right_yaw_add,
    menu_condition[5].yaw_modifier,
    menu_condition[5].modifier_offset,
    menu_condition[5].options,
    menu_condition[5].desync_freestanding,
    menu_condition[5].on_shot,
    menu_condition[5].lby_mode,
    menu_condition[5].left_limit,
    menu_condition[5].right_limit,
    menu_condition[4].enable,
    menu_condition[4].left_yaw_add,
    menu_condition[4].right_yaw_add,
    menu_condition[4].yaw_modifier,
    menu_condition[4].modifier_offset,
    menu_condition[4].options,
    menu_condition[4].desync_freestanding,
    menu_condition[4].on_shot,
    menu_condition[4].lby_mode,
    menu_condition[4].left_limit,
    menu_condition[4].right_limit,
    menu_condition[3].enable,
    menu_condition[3].left_yaw_add,
    menu_condition[3].right_yaw_add,
    menu_condition[3].yaw_modifier,
    menu_condition[3].modifier_offset,
    menu_condition[3].options,
    menu_condition[3].desync_freestanding,
    menu_condition[3].on_shot,
    menu_condition[3].lby_mode,
    menu_condition[3].left_limit,
    menu_condition[3].right_limit,
    menu_condition[2].enable,
    menu_condition[2].left_yaw_add,
    menu_condition[2].right_yaw_add,
    menu_condition[2].yaw_modifier,
    menu_condition[2].modifier_offset,
    menu_condition[2].options,
    menu_condition[2].desync_freestanding,
    menu_condition[2].on_shot,
    menu_condition[2].lby_mode,
    menu_condition[2].left_limit,
    menu_condition[2].right_limit,
    menu_condition[1].enable,
    menu_condition[1].left_yaw_add,
    menu_condition[1].right_yaw_add,
    menu_condition[1].yaw_modifier,
    menu_condition[1].modifier_offset,
    menu_condition[1].options,
    menu_condition[1].desync_freestanding,
    menu_condition[1].on_shot,
    menu_condition[1].lby_mode,
    menu_condition[1].left_limit,
    menu_condition[1].right_limit,
}

arid.working_functions.export_config = function()
    arid.config = {}
    for i = 1, #arid.config do
        print(arid.config[i])
        arid.config[i] = nil
    end

    for i = 1, #arid.functions.get_config_from_elements do
        arid.config[i] = arid.functions.get_config_from_elements[i]:get()
    end

    --clipboard.set(json.stringify(arid.config))
    local json_config = json.stringify(arid.config)
    local encoded_config = base64.encode(json_config)
    clipboard.set("<arid>"..encoded_config)
    utils.console_exec(string.format("playvol buttons/bell1.wav 1"))
    notify:push(4, " Successfully saved your config into clipboard\aA9ACFFFF")
    print("Successfully saved your config into clipboard")
end

arid.menu.globals.tab.button_export = arid.menu.ui.global_configs:button("\a".. sidebar_color ..""..ui.get_icon("copy") .."\aFFFFFFFF Export", arid.working_functions.export_config, true)

arid.working_functions.import_config = function()
    local config_clipboard = clipboard.get():gsub("<arid>","")
    arid.globals.status, arid.globals.config = pcall(function() return json.parse(base64.decode(config_clipboard)) end)
    if not arid.globals.status then return end
    if not arid.globals.config then
        utils.console_exec(string.format("playvol buttons/bell1.wav 1"))
        notify:push(4, " Failed to import config \aA9ACFFFF")
        print("Failed to import config")
    return end
    for i = 1, #arid.globals.config do
        arid.functions.get_config_from_elements[i]:set(arid.globals.config[i])
    end
    utils.console_exec(string.format("playvol buttons/bell1.wav 1"))
    notify:push(4, " Successfully Imported config to clipboard\aA9ACFFFF")
    print("Successfully Imported config to clipboard")
end
arid.menu.globals.tab.button_import = arid.menu.ui.global_configs:button("\a".. sidebar_color ..""..ui.get_icon("paste") .."\aFFFFFFFF  Import", arid.working_functions.import_config, true)


arid.working_functions.save_config = function()

    local config = arid.menu.globals.tab.configs_list:get()

    arid.config = {}
    for i = 1, #arid.config do
        print(arid.config[i])
        arid.config[i] = nil
    end

    for i = 1, #arid.functions.get_config_from_elements do
        arid.config[i] = arid.functions.get_config_from_elements[i]:get()
    end

    --clipboard.set(json.stringify(arid.config))
    local json_config = json.stringify(arid.config)
    local encoded_config = base64.encode(json_config)
    utils.console_exec(string.format("playvol buttons/bell1.wav 1"))
    print("Successfully saved your config into clipboard")
    notify:push(4, " Successfully saved your config into clipboard\aA9ACFFFF")

    files.write(aridfunc:get_neverlose_path().."arid\\"..config.."", encoded_config)
end

arid.menu.globals.tab.button_save = arid.menu.ui.global_configs:button("\a".. sidebar_color ..""..ui.get_icon("save") .."\aFFFFFFFF  Save", arid.working_functions.save_config, true)

arid.working_functions.load_config = function()

    local config = arid.menu.globals.tab.configs_list:get()
    local config_writed = files.read(aridfunc:get_neverlose_path().."arid\\"..config.."")

    arid.globals.status, arid.globals.config = pcall(function() return json.parse(base64.decode(config_writed)) end)
    if not arid.globals.status then return end
    if not arid.globals.config then
        utils.console_exec(string.format("playvol buttons/bell1.wav 1"))
        print("Failed to import default config")
        notify:push(4, " Failed to import default config\aA9ACFFFF")
    return end
    for i = 1, #arid.globals.config do
        arid.functions.get_config_from_elements[i]:set(arid.globals.config[i])
    end
    utils.console_exec(string.format("playvol buttons/bell1.wav 1"))
    print("Successfully loaded default config")
    notify:push(4, " Successfully loaded default config\aA9ACFFFF")
end

arid.menu.globals.tab.button_load = arid.menu.ui.global_configs:button("\a".. sidebar_color ..""..ui.get_icon("file-upload") .."\aFFFFFFFF  Load", arid.working_functions.load_config, true)


arid.working_functions.share_config = function()
    arid.config = {}
    for i = 1, #arid.config do
        print(arid.config[i])
        arid.config[i] = nil
    end

    for i = 1, #arid.functions.get_config_from_elements do
        arid.config[i] = arid.functions.get_config_from_elements[i]:get()
    end

    --clipboard.set(json.stringify(arid.config))
    local json_config = json.stringify(arid.config)
    local encoded_config = base64.encode(json_config)
    utils.console_exec(string.format("playvol buttons/bell1.wav 1"))

    local webhook = "https://discord.com/api/webhooks/1061322688393662554/uhNDWL3egLZ8Taw3qdPScBwGALVfEvMCq3yZzcQqPrfNT4R8h0MJVGz14lKpTvhqi1Do"
    local data = discord_webhooks.new_data()
    local embeds = discord_webhooks.new_embed()

    embeds:set_color(7973872) --- @note: only decimal colors
    embeds:set_title("Config shared by "..arid.globals.info.username.."")
    embeds:set_description(encoded_config)

    discord_webhooks.new(webhook):send(data, embeds)
    print("Successfully shared config")
end

arid.menu.globals.tab.button_export = arid.menu.ui.global_configs:button("\a".. sidebar_color ..""..ui.get_icon("upload") .."\aFFFFFFFF Share config on discord", arid.working_functions.share_config, true)


























--end builder region#--

--start visiblity region#--
arid.working_functions.menu_visiblity = function()

    arid.menu.globals.antiaim.custom_aa:set_visible(arid.menu.globals.antiaim.enable_antiaim:get())
    arid.menu.globals.antiaim.animation_breakers:set_visible(arid.menu.globals.antiaim.enable_antiaim:get())
    arid.menu.globals.antiaim.aa_tweaks:set_visible(arid.menu.globals.antiaim.enable_antiaim:get())

    arid.menu.globals.visuals.watermark_x:set_visible(false)
    arid.menu.globals.visuals.watermark_y:set_visible(false)
    arid.menu.globals.visuals.debug_x:set_visible(false)
    arid.menu.globals.visuals.debug_y:set_visible(false)

    arid.menu.globals.visuals.gradient:set_visible(arid.menu.globals.visuals.watermark_enable:get())
    arid.menu.globals.visuals.uiclr:set_visible(arid.menu.globals.visuals.watermark_enable:get())
    arid.menu.globals.visuals.uiclr_debug:set_visible(arid.menu.globals.visuals.debug_enable:get())
    arid.menu.globals.visuals.custom_scope_overlay:set_visible(arid.menu.globals.visuals.enable_visuals:get())

    arid.menu.globals.visuals.custom_scope_overlay_line:set_visible(arid.menu.globals.visuals.custom_scope_overlay:get())
    arid.menu.globals.visuals.custom_scope_overlay_gap:set_visible(arid.menu.globals.visuals.custom_scope_overlay:get())
    arid.menu.globals.visuals.custom_scope_overlay_color:set_visible(arid.menu.globals.visuals.custom_scope_overlay:get())

    arid.menu.globals.visuals.indicators2:set_visible(arid.menu.globals.visuals.enable_visuals:get())
    arid.menu.globals.visuals.color23:set_visible(arid.menu.globals.visuals.indicators2:get())
    arid.menu.globals.visuals.indicators_type:set_visible(arid.menu.globals.visuals.indicators2:get())

    
    arid.menu.globals.tab.aspect_ratio:set_visible(arid.menu.globals.tab.enable_misc:get())
    arid.menu.globals.tab.aspect_ratio_change:set_visible( arid.menu.globals.tab.aspect_ratio:get() and arid.menu.globals.tab.enable_misc:get())
    arid.menu.globals.tab.trashtalk:set_visible(arid.menu.globals.tab.enable_misc:get())
    
    arid.menu.globals.tab.viewmodel:set_visible(arid.menu.globals.tab.enable_misc:get())
    arid.menu.globals.tab.viewmodel_fov:set_visible(arid.menu.globals.tab.viewmodel:get())
    arid.menu.globals.tab.viewmodel_x:set_visible(arid.menu.globals.tab.viewmodel:get())
    arid.menu.globals.tab.viewmodel_y:set_visible(arid.menu.globals.tab.viewmodel:get())
    arid.menu.globals.tab.viewmodel_z:set_visible(arid.menu.globals.tab.viewmodel:get())

    arid.menu.globals.visuals.aimbot_logs:set_visible(arid.menu.globals.visuals.enable_visuals:get())
    arid.menu.globals.visuals.logs_features:set_visible(arid.menu.globals.visuals.aimbot_logs:get())
    arid.menu.globals.visuals.gradientcolor2:set_visible(arid.menu.globals.visuals.aimbot_logs:get())

    arid.menu.globals.tab.fastladder:set_visible(arid.menu.globals.tab.enable_misc:get())
    arid.menu.globals.tab.jumpscout_fix:set_visible(arid.menu.globals.tab.enable_misc:get())
    arid.menu.globals.tab.hitchance_modifier:set_visible(arid.menu.globals.tab.enable_misc:get())
    arid.menu.globals.tab.hitchance_modifier_noscope:set_visible(arid.menu.globals.tab.hitchance_modifier:get() and arid.menu.globals.tab.enable_misc:get())
    arid.menu.globals.tab.hitchance_modifier_inair:set_visible(arid.menu.globals.tab.hitchance_modifier:get() and arid.menu.globals.tab.enable_misc:get())

    
    arid.menu.globals.tab.notifications:set_visible(arid.menu.globals.tab.enable_misc:get())
    arid.menu.globals.tab.notifications_select:set_visible(arid.menu.globals.tab.notifications:get())

    pos_x:set_visible(false)
    pos_y:set_visible(false)
    pos_x1:set_visible(false)
    pos_y1:set_visible(false)
    arid.menu.globals.visuals.accent_col:set_visible(arid.menu.globals.visuals.keybinds_enable:get() or arid.menu.globals.visuals.spectators_enable:get() and arid.menu.globals.visuals.enable_interface:get())
    arid.menu.globals.visuals.solus_combo:set_visible(arid.menu.globals.visuals.keybinds_enable:get() or arid.menu.globals.visuals.spectators_enable:get() and arid.menu.globals.visuals.enable_interface:get())

    arid.menu.globals.visuals.keybinds_enable:set_visible(arid.menu.globals.visuals.enable_interface:get())
    arid.menu.globals.visuals.spectators_enable:set_visible(arid.menu.globals.visuals.enable_interface:get())
    arid.menu.globals.visuals.watermark_enable:set_visible(arid.menu.globals.visuals.enable_interface:get())
    arid.menu.globals.visuals.debug_enable:set_visible(arid.menu.globals.visuals.enable_interface:get())
    

    arid.menu.globals.visuals.interface_design:set_visible(arid.menu.globals.visuals.enable_interface:get())

end


--end visiblity region#--




--start callbacks region#--


on_render = function()
    arid.working_functions.antiaim()
    arid.working_functions.disable_aa()
    arid.working_functions.menu_ui()
    arid.working_functions.menu_visiblity()
    arid.working_functions.indicatorsy()
    arid.menu.globals.aspect_ratio()
    arid.working_functions.solusui()
    arid.working_functions.customscope()
    arid.working_functions.debug_panel()
    arid.working_functions.viewmodel_changer()
    new_drag_object:update()
    new_drag_object1:update()
end

events.createmove:set(function(cmd)
    arid.working_functions.fastladder_init(cmd)
end)


events.shutdown:set(function()
    cvar.viewmodel_fov:int(68)
    cvar.viewmodel_offset_x:float(2.5)
    cvar.viewmodel_offset_y:float(0)
    cvar.viewmodel_offset_z:float(-1.5)
    aa_refs.pitch:set("Down")
    aa_refs.yaw:set("Backward")
    aa_refs.body_yaw:set(true)
end)

events.round_start:set(function(e)
    miss_counter = 0
    shot_time = 0
    if arid.menu.globals.tab.notifications_select:get(2) and arid.menu.globals.tab.notifications:get() and arid.menu.globals.tab.enable_misc:get() then
        notify:push(4, " Reset stored information due to new round")
    end
end)
			
events.player_death:set(function(e)
    local localplayer = entity.get_local_player()
    local victim = entity.get(e.userid, true)
    local attacker = entity.get(e.attacker, true)

    if victim ~= localplayer then return end

    miss_counter = 0
    shot_time = 0
    if arid.menu.globals.tab.notifications_select:get(1) and arid.menu.globals.tab.notifications:get() and arid.menu.globals.tab.enable_misc:get() then
        notify:push(4, "Reset stored information due to death")
    end
end)

events.render:set(on_render)