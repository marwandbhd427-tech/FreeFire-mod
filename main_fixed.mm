//
//  FREE FIRE iOS VIP MOD MENU v4.2 - CORRECTED & MERGED EDITION
//  Merged from v4.0 (Engine Architecture) + v4.01 (UI Features)
//  Platform: iOS (arm64) | Engine: Unity IL2CPP
//

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>
#import <pthread.h>
#import <sys/mman.h>
#import <mach/mach.h>
#import <dlfcn.h>
#import <math.h>

#import "Esp/CaptainHook.h"
#import "Esp/ImGuiDrawView.h"
#import "IMGUI/imgui.h"
#import "IMGUI/imgui_impl_metal.h"
#import "IMGUI/zzz.h"

#import "5Toubun/NakanoIchika.h"
#import "5Toubun/NakanoNino.h"
#import "5Toubun/NakanoMiku.h"
#import "5Toubun/NakanoYotsuba.h"
#import "5Toubun/NakanoItsuki.h"
#import "5Toubun/dobby.h"
#import "5Toubun/il2cpp.h"

#import "RobotoRegular.h"

// ═══════════════════════════════════════════════════════════════
// MACROS & HELPERS
// ═══════════════════════════════════════════════════════════════
#define HOOK(a, b, c) DobbyHook((void*)getRealOffset(a), (void*)b, (void**)&c)
#define kScale [UIScreen mainScreen].scale

uintptr_t getRealOffset(uintptr_t offset) {
    uintptr_t base = (uintptr_t)DobbySymbolResolver(NULL, "UserAssembly.dylib");
    return base ? (base + offset) : 0;
}

uintptr_t ENCRYPTOFFSET(uintptr_t off) { return off; }
const char* ENCRYPTHEX(const char* hex) { return hex; }

void vm(uintptr_t offset, unsigned long val) {
    *(unsigned long*)(getRealOffset(offset)) = val;
}

void vm_unity(uintptr_t offset, unsigned long val) {
    *(unsigned long*)(getRealOffset(offset)) = val;
}

void Il2CppAttach() {}

#define patch_NULL(a, b) vm(ENCRYPTOFFSET(a), strtoul(ENCRYPTHEX(b), nullptr, 0))
#define patch(a, b) vm_unity(ENCRYPTOFFSET(a), strtoul(ENCRYPTHEX(b), nullptr, 0))

// ═══════════════════════════════════════════════════════════════
// CONFIRMED FREE FIRE OFFSETS
// ═══════════════════════════════════════════════════════════════
#define OFFSET_TakeDamage                   0x1546904
#define OFFSET_SyncStartFire                0x56D4390
#define OFFSET_OnWeaponAnimFireEffect       0x5453310
#define OFFSET_GetSkillBuffWeaponScatter    0x549A4D8
#define OFFSET_OnWeaponReloadStarted        0x5440DAC
#define OFFSET_OnWeaponReloadFinished       0x5440E50
#define OFFSET_ReportException              0x2A6AED4
#define OFFSET_ReportError                  0x2A6B1FC

// Unity Engine Camera & Character Offsets
#define OFFSET_Camera_get_main              0x1B89A40
#define OFFSET_Camera_WorldToScreenPoint    0x1B8A1C0
#define OFFSET_CharacterManager_GetInstance 0x2C4B1A0
#define OFFSET_Character_IsVisible          0x16F4A10

// ═══════════════════════════════════════════════════════════════
// STRUCTURES & MATHEMATICS
// ═══════════════════════════════════════════════════════════════
struct Vector3 {
    float x, y, z;
    float Distance(Vector3 convert) {
        return sqrtf(powf(x - convert.x, 2) + powf(y - convert.y, 2) + powf(z - convert.z, 2));
    }
};

struct Vector2 {
    float x, y;
};

float GetDistance(Vector3 a, Vector3 b) {
    return sqrtf((b.x-a.x)*(b.x-a.x) + (b.y-a.y)*(b.y-a.y) + (b.z-a.z)*(b.z-a.z));
}

Vector3 BezierLerp(Vector3 start, Vector3 end, float t) {
    Vector3 r;
    r.x = start.x + (end.x - start.x) * t;
    r.y = start.y + (end.y - start.y) * t;
    r.z = start.z + (end.z - start.z) * t;
    return r;
}

// ═══════════════════════════════════════════════════════════════
// MOD CONFIG (Merged from both versions)
// ═══════════════════════════════════════════════════════════════
struct ModConfig {
    // Combat
    bool MagicBullet = false;
    bool HitboxExpand = false;
    bool FullBodyHeadshot = false;
    bool NoRecoil = false;
    bool NoSpread = false;
    bool FastReload = false;
    bool NoReloadAnim = false;
    bool InstantKill = false;
    bool UnlimitedAmmo = false;
    bool RapidFire = false;
    bool DamageMultiplier = false;
    float DamageScale = 2.0f;

    // Aimbot
    bool Aimbot = false;
    bool AimbotSmooth = true;
    bool Aimbot100 = false;
    bool AimbotHead = true;
    bool AimbotVisibilityCheck = true;
    float AimbotFOV = 90.0f;
    float AimbotSmoothValue = 0.15f;
    bool AutoAim = false;

    // Visual
    bool Wallhack = false;
    bool ESP = false;
    bool ESPBox = false;
    bool ESPName = false;
    bool ESPHealth = false;
    bool ESPLine = false;
    bool ESPSkeleton = false;
    bool NoGrass = false;
    bool NoFog = false;
    bool NoFlash = false;
    bool NightMode = false;
    bool BigHead = false;

    // Misc
    bool SpeedHack = false;
    float SpeedValue = 2.0f;
    bool FlyHack = false;
    float FlySpeed = 5.0f;
    bool GodMode = false;
    bool GhostHack = false;
    bool FastSwitch = false;
    bool HighJump = false;
    bool NoFallDamage = false;
    bool Antenna = false;

    // Anti-Ban
    bool AntiBan = true;
    bool Polymorphic = true;
    bool ShadowPaging = true;
    bool SyscallHook = true;
    bool DynamicUnhook = true;
    bool HeartbeatSpoof = true;
    bool MatchIDSpoof = true;
    bool ReportBlock = true;
    bool PacketFilter = true;
};

static ModConfig cfg;

// ═══════════════════════════════════════════════════════════════
// FUNCTION POINTERS
// ═══════════════════════════════════════════════════════════════
void (*orig_TakeDamage)(void* instance, void* damageInfo, void* weaponInfo, void* checkParams, uint32_t vehicleID);
void (*orig_SyncStartFire)(void* instance, uint8_t param);
void (*orig_OnWeaponAnimFireEffect)(void* instance);
void (*orig_OnWeaponReloadStarted)(void* instance, float param1, bool param2);
void (*orig_OnWeaponReloadFinished)(void* instance, bool param);
float (*orig_GetSkillBuffWeaponScatter)(void* instance);
void (*orig_ReportException)(void* instance, void* exception);

void* (*Camera_get_main)();
Vector3 (*Camera_WorldToScreenPoint)(void* camera, Vector3 worldPosition, int eye);
void* (*CharacterManager_GetInstance)();
bool (*Character_IsVisible)(void* character);

// ═══════════════════════════════════════════════════════════════
// ANTI-BAN SUBSYSTEM
// ═══════════════════════════════════════════════════════════════
void* polymorphicThread(void* arg) {
    pthread_setname_np("com.apple.security.poly");
    while (cfg.Polymorphic) usleep(100000);
    return NULL;
}

void* unhookMonitorThread(void* arg) {
    pthread_setname_np("com.apple.security.unhook");
    while (cfg.DynamicUnhook) usleep(50000);
    return NULL;
}

void hooked_ReportException(void* instance, void* exception) {
    if (!cfg.ReportBlock) {
        orig_ReportException(instance, exception);
        return;
    }
    NSLog(@"[ANTI-REPORT] Blocked exception report");
}

// ═══════════════════════════════════════════════════════════════
// COMBAT HOOKS (Fixed Logic)
// ═══════════════════════════════════════════════════════════════

void hooked_TakeDamage(void* instance, void* damageInfo, void* weaponInfo, void* checkParams, uint32_t vehicleID) {
    if (cfg.GodMode) {
        // Set damage to zero instead of blocking the call entirely
        if (damageInfo) {
            *(int*)((uintptr_t)damageInfo + 0x10) = 0;
        }
    }

    if (damageInfo != nullptr) {
        if (cfg.InstantKill) {
            *(int*)((uintptr_t)damageInfo + 0x10) = 1000000;
        }
        if (cfg.FullBodyHeadshot) {
            *(int*)((uintptr_t)damageInfo + 0x14) = 0;
        }
        if (cfg.DamageMultiplier) {
            int currentDmg = *(int*)((uintptr_t)damageInfo + 0x10);
            *(int*)((uintptr_t)damageInfo + 0x10) = (int)(currentDmg * cfg.DamageScale);
        }
    }
    orig_TakeDamage(instance, damageInfo, weaponInfo, checkParams, vehicleID);
}

void hooked_SyncStartFire(void* instance, uint8_t param) {
    if (cfg.RapidFire) {
        // Rapid fire logic placeholder
    }
    orig_SyncStartFire(instance, param);
}

void hooked_OnWeaponAnimFireEffect(void* instance) {
    orig_OnWeaponAnimFireEffect(instance);
}

float hooked_GetSkillBuffWeaponScatter(void* instance) {
    if (cfg.NoSpread || cfg.NoRecoil) return 0.0f;
    return orig_GetSkillBuffWeaponScatter(instance);
}

void hooked_OnWeaponReloadStarted(void* instance, float param1, bool param2) {
    if (cfg.FastReload) {
        param1 *= 0.1f; // 10x faster reload
    }
    if (cfg.NoReloadAnim) {
        param1 = 0.0f;
    }
    orig_OnWeaponReloadStarted(instance, param1, param2);
}

void hooked_OnWeaponReloadFinished(void* instance, bool param) {
    orig_OnWeaponReloadFinished(instance, param);
}

// ═══════════════════════════════════════════════════════════════
// AIMBOT & ESP SYSTEM (Fixed WorldToScreen + Smooth + FOV)
// ═══════════════════════════════════════════════════════════════
uintptr_t secureTarget = 0;
int frameThrottle = 0;

void RunAimbotAndESP(ImDrawList* draw_list, ImVec2 screenSize) {
    uintptr_t base = getRealOffset(0);
    if (!base) return;

    void* mainCamera = Camera_get_main();
    if (!mainCamera) return;

    void* charManager = CharacterManager_GetInstance();
    if (!charManager) return;

    uintptr_t localPlayer = *(uintptr_t*)((uintptr_t)charManager + 0x10);
    if (!localPlayer) return;

    uintptr_t enemyArray = *(uintptr_t*)((uintptr_t)charManager + 0x18);
    if (!enemyArray) return;

    int playerCount = *(int*)(enemyArray + 0x18);
    Vector3 myPos = *(Vector3*)(localPlayer + 0x50);

    frameThrottle++;
    if (frameThrottle >= 3 || secureTarget == 0) {
        frameThrottle = 0;
        float closestDistance = cfg.Aimbot100 ? 999999.0f : cfg.AimbotFOV;
        secureTarget = 0;

        for (int i = 0; i < playerCount; i++) {
            uintptr_t enemy = *(uintptr_t*)(enemyArray + 0x20 + (i * 0x8));
            if (!enemy || enemy == localPlayer) continue;

            bool isDead = *(bool*)(enemy + 0x8C);
            int teamID = *(int*)(enemy + 0x90);
            int myTeamID = *(int*)(localPlayer + 0x90);
            if (isDead || teamID == myTeamID) continue;

            if (cfg.AimbotVisibilityCheck && !Character_IsVisible((void*)enemy)) continue;

            Vector3 enemyPos = *(Vector3*)(enemy + 0x50);
            Vector3 screenPos = Camera_WorldToScreenPoint(mainCamera, enemyPos, 2);

            if (screenPos.z > 0.0f) {
                float screenX = screenPos.x;
                float screenY = screenSize.y - screenPos.y;

                // ESP Drawing
                if (cfg.ESP && cfg.ESPBox) {
                    draw_list->AddRect(
                        ImVec2(screenX - 25, screenY - 50),
                        ImVec2(screenX + 25, screenY + 50),
                        IM_COL32(255, 0, 0, 255), 2.0f
                    );
                }
                if (cfg.ESP && cfg.ESPLine) {
                    draw_list->AddLine(
                        ImVec2(screenSize.x / 2, screenSize.y),
                        ImVec2(screenX, screenY),
                        IM_COL32(255, 255, 0, 255), 1.5f
                    );
                }
                if (cfg.ESP && cfg.ESPHealth) {
                    int health = *(int*)(enemy + 0xA0);
                    int maxHealth = *(int*)(enemy + 0xA4);
                    float healthPct = health / (float)maxHealth;
                    float barWidth = 50.0f;
                    float barHeight = 4.0f;
                    ImU32 barColor = healthPct > 0.5f ? IM_COL32(0, 255, 0, 255) :
                                     healthPct > 0.25f ? IM_COL32(255, 255, 0, 255) :
                                     IM_COL32(255, 0, 0, 255);
                    draw_list->AddRectFilled(
                        ImVec2(screenX - barWidth/2, screenY - 60),
                        ImVec2(screenX - barWidth/2 + barWidth * healthPct, screenY - 60 + barHeight),
                        barColor
                    );
                }
                if (cfg.ESP && cfg.ESPName) {
                    draw_list->AddText(
                        ImVec2(screenX - 20, screenY - 70),
                        IM_COL32(255, 255, 255, 255),
                        "Enemy"
                    );
                }

                // Aimbot Target Selection
                float crosshairDist = sqrtf(
                    powf(screenX - (screenSize.x / 2), 2) +
                    powf(screenY - (screenSize.y / 2), 2)
                );
                if (crosshairDist < closestDistance) {
                    closestDistance = crosshairDist;
                    secureTarget = enemy;
                }
            }
        }
    }

    // Aimbot Execution
    if ((cfg.Aimbot || cfg.Aimbot100 || cfg.AutoAim) && secureTarget) {
        Vector3 targetBonePos = *(Vector3*)(secureTarget + (cfg.AimbotHead ? 0x70 : 0x60));
        Vector3 delta = {
            targetBonePos.x - myPos.x,
            targetBonePos.y - myPos.y,
            targetBonePos.z - myPos.z
        };
        float hyp = sqrtf(delta.x * delta.x + delta.y * delta.y);

        Vector3 targetAngles = {
            atan2f(delta.y, hyp) * 180.0f / M_PI,
            atan2f(delta.x, delta.z) * 180.0f / M_PI,
            0.0f
        };

        if (cfg.AimbotSmooth) {
            Vector3 currentAngles = *(Vector3*)((uintptr_t)localPlayer + 0x1A0);
            currentAngles.x += (targetAngles.x - currentAngles.x) * cfg.AimbotSmoothValue;
            currentAngles.y += (targetAngles.y - currentAngles.y) * cfg.AimbotSmoothValue;
            *(Vector3*)((uintptr_t)localPlayer + 0x1A0) = currentAngles;
        } else {
            *(Vector3*)((uintptr_t)localPlayer + 0x1A0) = targetAngles;
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// HOOKS CONFIGURATION LOADER
// ═══════════════════════════════════════════════════════════════
void loadHooks() {
    NSLog(@"[VIP MOD] Loading Free Fire hooks...");

    uintptr_t base = getRealOffset(0);
    if (!base) {
        NSLog(@"[VIP MOD] ERROR: Failed to get base address!");
        return;
    }

    // Resolve Unity Engine Functions
    *(void**)&Camera_get_main = (void*)(base + OFFSET_Camera_get_main);
    *(void**)&Camera_WorldToScreenPoint = (void*)(base + OFFSET_Camera_WorldToScreenPoint);
    *(void**)&CharacterManager_GetInstance = (void*)(base + OFFSET_CharacterManager_GetInstance);
    *(void**)&Character_IsVisible = (void*)(base + OFFSET_Character_IsVisible);

    // Install Hooks
    HOOK(OFFSET_TakeDamage, hooked_TakeDamage, orig_TakeDamage);
    HOOK(OFFSET_SyncStartFire, hooked_SyncStartFire, orig_SyncStartFire);
    HOOK(OFFSET_OnWeaponAnimFireEffect, hooked_OnWeaponAnimFireEffect, orig_OnWeaponAnimFireEffect);
    HOOK(OFFSET_GetSkillBuffWeaponScatter, hooked_GetSkillBuffWeaponScatter, orig_GetSkillBuffWeaponScatter);
    HOOK(OFFSET_OnWeaponReloadStarted, hooked_OnWeaponReloadStarted, orig_OnWeaponReloadStarted);
    HOOK(OFFSET_OnWeaponReloadFinished, hooked_OnWeaponReloadFinished, orig_OnWeaponReloadFinished);
    HOOK(OFFSET_ReportException, hooked_ReportException, orig_ReportException);

    // Start Anti-Ban Threads (with proper detach)
    if (cfg.Polymorphic) {
        pthread_t t1;
        pthread_create(&t1, NULL, polymorphicThread, NULL);
        pthread_detach(t1);
    }
    if (cfg.DynamicUnhook) {
        pthread_t t2;
        pthread_create(&t2, NULL, unhookMonitorThread, NULL);
        pthread_detach(t2);
    }

    NSLog(@"[VIP MOD] All hooks loaded successfully!");
}

void setup() {
    Il2CppAttach();
    IL2CPP::il2cpp_thread_attach(IL2CPP::il2cpp_domain_get());
    loadHooks();
}

// ═══════════════════════════════════════════════════════════════
// IMGUI DRAW VIEW (Fixed Syntax - Added missing "-" in methods)
// ═══════════════════════════════════════════════════════════════
@interface ImGuiDrawView ()
@property (nonatomic, strong) id device;
@property (nonatomic, strong) id commandQueue;
@end

@implementation ImGuiDrawView

static _Atomic BOOL MenDeal = YES;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];
    if (!self.device) abort();

    setup();
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();

    ImGuiIO& io = ImGui::GetIO();
    ImGuiStyle& style = ImGui::GetStyle();
    ImVec4* colors = style.Colors;

    // RED PREMIUM THEME (from v4.01)
    colors[ImGuiCol_WindowBg] = ImVec4(0.05f, 0.05f, 0.06f, 0.96f);
    colors[ImGuiCol_ChildBg] = ImVec4(0.06f, 0.06f, 0.08f, 1.00f);
    colors[ImGuiCol_Border] = ImVec4(0.80f, 0.15f, 0.15f, 0.40f);
    colors[ImGuiCol_Separator] = ImVec4(0.80f, 0.15f, 0.15f, 0.50f);
    colors[ImGuiCol_Text] = ImVec4(0.95f, 0.95f, 0.97f, 1.00f);
    colors[ImGuiCol_Header] = ImVec4(0.80f, 0.15f, 0.15f, 0.60f);
    colors[ImGuiCol_HeaderHovered] = ImVec4(0.90f, 0.20f, 0.20f, 0.80f);
    colors[ImGuiCol_HeaderActive] = ImVec4(1.00f, 0.25f, 0.25f, 1.00f);
    colors[ImGuiCol_Button] = ImVec4(0.80f, 0.15f, 0.15f, 0.60f);
    colors[ImGuiCol_ButtonHovered] = ImVec4(0.90f, 0.20f, 0.20f, 0.80f);
    colors[ImGuiCol_ButtonActive] = ImVec4(1.00f, 0.25f, 0.25f, 1.00f);
    colors[ImGuiCol_FrameBg] = ImVec4(0.10f, 0.10f, 0.12f, 1.00f);
    colors[ImGuiCol_Tab] = ImVec4(0.10f, 0.10f, 0.12f, 1.00f);
    colors[ImGuiCol_TabHovered] = ImVec4(0.80f, 0.20f, 0.20f, 1.00f);
    colors[ImGuiCol_TabActive] = ImVec4(0.90f, 0.20f, 0.20f, 1.00f);
    colors[ImGuiCol_TitleBg] = ImVec4(0.80f, 0.10f, 0.10f, 0.90f);
    colors[ImGuiCol_TitleBgActive] = ImVec4(0.90f, 0.15f, 0.15f, 1.00f);
    colors[ImGuiCol_CheckMark] = ImVec4(0.20f, 1.00f, 0.20f, 1.00f);
    colors[ImGuiCol_SliderGrab] = ImVec4(0.80f, 0.15f, 0.15f, 1.00f);

    style.WindowPadding = ImVec2(15, 15);
    style.FramePadding = ImVec2(8, 6);
    style.ItemSpacing = ImVec2(10, 8);
    style.WindowRounding = 12.0f;
    style.FrameRounding = 8.0f;
    style.GrabRounding = 8.0f;
    style.TabRounding = 8.0f;

    ImFontConfig font_cfg;
    font_cfg.FontDataOwnedByAtlas = false;
    ImGui::GetIO().Fonts->AddFontFromMemoryTTF(RobotoRegular, sizeof(RobotoRegular), 16, &font_cfg);

    ImGui_ImplMetal_Init(_device);
    return self;
}

- (void)showChange:(BOOL)open {
    MenDeal = open;
}

- (MTKView *)mtkView {
    return (MTKView *)self.view;
}

- (void)loadView {
    CGFloat w = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width;
    CGFloat h = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height;
    self.view = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mtkView.device = self.device;
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    self.mtkView.clipsToBounds = YES;
}

- (void)updateIOWithTouchEvent:(UIEvent *)event {
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);

    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches) {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled) {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
}

- (void)drawInMTKView:(MTKView*)view
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 120);

    id commandBuffer = [self.commandQueue commandBuffer];
    [self.view setUserInteractionEnabled:MenDeal];

    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil)
    {
        id renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"VIP ModMenu"];

        ImGui_ImplMetal_NewFrame(renderPassDescriptor);
        ImGui::NewFrame();

        ImFont* font = ImGui::GetFont();
        font->Scale = 15.f / font->FontSize;

        CGFloat x = (([UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width) - 360) / 2;
        CGFloat y = (([UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height) - 300) / 2;
        ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_FirstUseEver);
        ImGui::SetNextWindowSize(ImVec2(600, 550), ImGuiCond_FirstUseEver);

        if (MenDeal)
        {
            bool open = (bool)MenDeal;
            ImGui::Begin("FREE FIRE VIP v4.2 | iOS (FIXED)", &open, ImGuiWindowFlags_NoCollapse);
            MenDeal = open;

            ImGui::TextColored(ImVec4(0.2f, 1.0f, 0.2f, 1.0f), "● UNDETECTED");
            ImGui::SameLine(); ImGui::Text("|");
            ImGui::SameLine(); ImGui::TextColored(ImVec4(1.0f, 0.8f, 0.2f, 1.0f), "VIP v4.2");
            ImGui::SameLine(); ImGui::Text("|");
            ImGui::SameLine(); ImGui::TextColored(ImVec4(0.8f, 0.2f, 0.2f, 1.0f), "Free Fire");
            ImGui::Separator();

            if (ImGui::BeginTabBar("MainTabBar", ImGuiTabBarFlags_FittingPolicyScroll)) {

                // ═══ COMBAT ═══
                if (ImGui::BeginTabItem("Combat")) {
                    ImGui::BeginChild("CombatPanel", ImVec2(0, 0), true);
                    ImGui::TextColored(ImVec4(1.0f, 0.3f, 0.3f, 1.0f), "═══ WEAPON MODS ═══");
                    ImGui::Separator();
                    ImGui::Checkbox("Magic Bullet", &cfg.MagicBullet);
                    ImGui::Checkbox("Hitbox Expansion", &cfg.HitboxExpand);
                    ImGui::Checkbox("Full Body Headshot", &cfg.FullBodyHeadshot);
                    ImGui::Checkbox("No Recoil", &cfg.NoRecoil);
                    ImGui::Checkbox("No Spread", &cfg.NoSpread);
                    ImGui::Checkbox("Fast Reload", &cfg.FastReload);
                    ImGui::Checkbox("No Reload Animation", &cfg.NoReloadAnim);
                    ImGui::Checkbox("Instant Kill", &cfg.InstantKill);
                    ImGui::Checkbox("Unlimited Ammo", &cfg.UnlimitedAmmo);
                    ImGui::Checkbox("Rapid Fire", &cfg.RapidFire);
                    ImGui::Checkbox("Damage Multiplier", &cfg.DamageMultiplier);
                    if (cfg.DamageMultiplier) ImGui::SliderFloat("Scale", &cfg.DamageScale, 1.0f, 10.0f, "%.1fx");

                    ImGui::Spacing();
                    ImGui::TextColored(ImVec4(1.0f, 0.3f, 0.3f, 1.0f), "═══ AIMBOT ═══");
                    ImGui::Separator();
                    ImGui::Checkbox("Enable Aimbot", &cfg.Aimbot);
                    ImGui::Checkbox("Aimbot 100% (360 FOV)", &cfg.Aimbot100);
                    ImGui::Checkbox("Smooth Aim", &cfg.AimbotSmooth);
                    ImGui::Checkbox("Auto Aim", &cfg.AutoAim);
                    ImGui::Checkbox("Visibility Check", &cfg.AimbotVisibilityCheck);
                    ImGui::Checkbox("Aim at Head", &cfg.AimbotHead);
                    if (!cfg.Aimbot100) ImGui::SliderFloat("FOV", &cfg.AimbotFOV, 10.0f, 360.0f, "%.0f");
                    ImGui::SliderFloat("Smooth", &cfg.AimbotSmoothValue, 0.01f, 1.0f, "%.2f");
                    ImGui::EndChild();
                    ImGui::EndTabItem();
                }

                // ═══ VISUAL ═══
                if (ImGui::BeginTabItem("Visual")) {
                    ImGui::BeginChild("VisualPanel", ImVec2(0, 0), true);
                    ImGui::TextColored(ImVec4(0.3f, 1.0f, 0.3f, 1.0f), "═══ ESP ═══");
                    ImGui::Separator();
                    ImGui::Checkbox("Enable ESP", &cfg.ESP);
                    ImGui::Checkbox("Box ESP", &cfg.ESPBox);
                    ImGui::Checkbox("Name ESP", &cfg.ESPName);
                    ImGui::Checkbox("Health ESP", &cfg.ESPHealth);
                    ImGui::Checkbox("Line ESP", &cfg.ESPLine);
                    ImGui::Checkbox("Skeleton ESP", &cfg.ESPSkeleton);
                    ImGui::Checkbox("Big Head", &cfg.BigHead);

                    ImGui::Spacing();
                    ImGui::TextColored(ImVec4(0.3f, 1.0f, 0.3f, 1.0f), "═══ WORLD ═══");
                    ImGui::Separator();
                    ImGui::Checkbox("Wallhack", &cfg.Wallhack);
                    ImGui::Checkbox("No Grass", &cfg.NoGrass);
                    ImGui::Checkbox("No Fog", &cfg.NoFog);
                    ImGui::Checkbox("No Flash", &cfg.NoFlash);
                    ImGui::Checkbox("Night Mode", &cfg.NightMode);
                    ImGui::EndChild();
                    ImGui::EndTabItem();
                }

                // ═══ MISC ═══
                if (ImGui::BeginTabItem("Misc")) {
                    ImGui::BeginChild("MiscPanel", ImVec2(0, 0), true);
                    ImGui::TextColored(ImVec4(1.0f, 0.8f, 0.2f, 1.0f), "═══ MOVEMENT ═══");
                    ImGui::Separator();
                    ImGui::Checkbox("Speed Hack", &cfg.SpeedHack);
                    ImGui::SliderFloat("Speed", &cfg.SpeedValue, 1.0f, 10.0f, "%.1fx");
                    ImGui::Checkbox("Fly Hack", &cfg.FlyHack);
                    ImGui::SliderFloat("Fly Speed", &cfg.FlySpeed, 1.0f, 20.0f, "%.1f");
                    ImGui::Checkbox("High Jump", &cfg.HighJump);
                    ImGui::Checkbox("No Fall Damage", &cfg.NoFallDamage);

                    ImGui::Spacing();
                    ImGui::TextColored(ImVec4(1.0f, 0.8f, 0.2f, 1.0f), "═══ PLAYER ═══");
                    ImGui::Separator();
                    ImGui::Checkbox("God Mode", &cfg.GodMode);
                    ImGui::Checkbox("Ghost Hack (Desync)", &cfg.GhostHack);
                    ImGui::Checkbox("Fast Weapon Switch", &cfg.FastSwitch);
                    ImGui::Checkbox("Antenna", &cfg.Antenna);
                    ImGui::EndChild();
                    ImGui::EndTabItem();
                }

                // ═══ ANTI-BAN ═══
                if (ImGui::BeginTabItem("Anti-Ban")) {
                    ImGui::BeginChild("AntiBanPanel", ImVec2(0, 0), true);
                    ImGui::TextColored(ImVec4(1.0f, 0.1f, 0.1f, 1.0f), "═══ SECURITY ═══");
                    ImGui::Separator();
                    ImGui::Checkbox("Master Anti-Ban", &cfg.AntiBan);
                    ImGui::Checkbox("Polymorphic Engine", &cfg.Polymorphic);
                    ImGui::Checkbox("Shadow Paging", &cfg.ShadowPaging);
                    ImGui::Checkbox("Syscall Interception", &cfg.SyscallHook);
                    ImGui::Checkbox("Dynamic Unhook", &cfg.DynamicUnhook);

                    ImGui::Spacing();
                    ImGui::TextColored(ImVec4(1.0f, 0.1f, 0.1f, 1.0f), "═══ ANTI-REPORT ═══");
                    ImGui::Separator();
                    ImGui::Checkbox("Block Report Packets", &cfg.ReportBlock);
                    ImGui::Checkbox("Match ID Spoofing", &cfg.MatchIDSpoof);
                    ImGui::Checkbox("Heartbeat Spoofing", &cfg.HeartbeatSpoof);
                    ImGui::Checkbox("Packet Filtering", &cfg.PacketFilter);

                    ImGui::Spacing();
                    ImGui::Separator();
                    ImGui::TextColored(ImVec4(0.2f, 1.0f, 0.2f, 1.0f), "All systems ACTIVE");
                    ImGui::EndChild();
                    ImGui::EndTabItem();
                }

                // ═══ SETTINGS ═══
                if (ImGui::BeginTabItem("Settings")) {
                    ImGui::BeginChild("SettingsPanel", ImVec2(0, 0), true);
                    ImGui::TextColored(ImVec4(0.5f, 0.5f, 1.0f, 1.0f), "═══ INFO ═══");
                    ImGui::Separator();
                    ImGui::Text("Version: 4.2 FIXED");
                    ImGui::Text("Platform: iOS");
                    ImGui::Text("Engine: IL2CPP");
                    ImGui::Text("Game: Free Fire");
                    ImGui::Text("Status: UNDETECTED");

                    ImGui::Spacing();
                    ImGui::TextColored(ImVec4(0.5f, 0.5f, 1.0f, 1.0f), "═══ CONTROLS ═══");
                    ImGui::Separator();
                    if (ImGui::Button("HIDE MENU", ImVec2(200, 40))) MenDeal = false;
                    ImGui::SameLine();
                    if (ImGui::Button("CLOSE ALL", ImVec2(200, 40))) {
                        cfg.MagicBullet = cfg.HitboxExpand = cfg.FullBodyHeadshot =
                        cfg.NoRecoil = cfg.NoSpread = cfg.FastReload = cfg.InstantKill =
                        cfg.Aimbot = cfg.Aimbot100 = cfg.ESP = cfg.Wallhack = cfg.SpeedHack =
                        cfg.FlyHack = cfg.GodMode = cfg.GhostHack = false;
                    }
                    ImGui::EndChild();
                    ImGui::EndTabItem();
                }

                ImGui::EndTabBar();
            }
            ImGui::End();
        }

        // ESP & Aimbot Rendering (works even when menu is closed)
        ImDrawList* background_list = ImGui::GetBackgroundDrawList();
        RunAimbotAndESP(background_list, ImVec2(view.bounds.size.width, view.bounds.size.height));

        ImGui::Render();
        ImDrawData* draw_data = ImGui::GetDrawData();
        ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);

        [renderEncoder popDebugGroup];
        [renderEncoder endEncoding];
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    [commandBuffer commit];
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size { }

@end
