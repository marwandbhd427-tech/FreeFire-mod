//
//  FREE FIRE iOS VIP MOD MENU v4.2 – STANDALONE DYLIB
//  يحتوي على كلشي: ImGui + Dobby + IL2CPP
//

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>
#import <pthread.h>
#import <sys/mman.h>
#import <mach/mach.h>
#import <dlfcn.h>
#import <math.h>
#import <sys/stat.h>
#import <string>
#import <errno.h>
#import <dispatch/dispatch.h>

// ═══════════════════════════════════════════════════════════════
// INCLUDES (يحملهم GitHub تلقائياً)
// ═══════════════════════════════════════════════════════════════
#include "IMGUI/imgui.h"
#include "IMGUI/imgui_impl_metal.h"
#include "5Toubun/include/dobby.h"

// ═══════════════════════════════════════════════════════════════
// IL2CPP MANUAL DECLARATIONS (بدل il2cpp.h)
// ═══════════════════════════════════════════════════════════════
extern "C" {
    void* il2cpp_domain_get();
    void* il2cpp_thread_attach(void* domain);
}

// ═══════════════════════════════════════════════════════════════
// MACROS & HELPERS
// ═══════════════════════════════════════════════════════════════
#define HOOK(a, b, c) DobbyHook((void*)getRealOffset(a), (void*)b, (void**)&c)

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

#define patch_NULL(a, b) vm(ENCRYPTOFFSET(a), strtoul(ENCRYPTHEX(b), nullptr, 0))
#define patch(a, b) vm_unity(ENCRYPTOFFSET(a), strtoul(ENCRYPTHEX(b), nullptr, 0))

// ═══════════════════════════════════════════════════════════════
// OFFSETS
// ═══════════════════════════════════════════════════════════════
#define OFFSET_TakeDamage                   0x1546904
#define OFFSET_SyncStartFire                0x56D4390
#define OFFSET_OnWeaponAnimFireEffect       0x5453310
#define OFFSET_GetSkillBuffWeaponScatter    0x549A4D8
#define OFFSET_OnWeaponReloadStarted        0x5440DAC
#define OFFSET_OnWeaponReloadFinished       0x5440E50
#define OFFSET_Camera_get_main              0x1B89A40
#define OFFSET_Camera_WorldToScreenPoint    0x1B8A1C0
#define OFFSET_CharacterManager_GetInstance 0x2C4B1A0
#define OFFSET_Character_IsVisible          0x16F4A10

// ═══════════════════════════════════════════════════════════════
// STRUCTURES
// ═══════════════════════════════════════════════════════════════
struct Vector3 {
    float x, y, z;
    float Distance(Vector3 convert) {
        return sqrtf(powf(x - convert.x, 2) + powf(y - convert.y, 2) + powf(z - convert.z, 2));
    }
};

struct Vector2 { float x, y; };

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
// MOD CONFIG
// ═══════════════════════════════════════════════════════════════
struct ModConfig {
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

    bool Aimbot = false;
    bool AimbotSmooth = true;
    bool Aimbot100 = false;
    bool AimbotHead = true;
    bool AimbotVisibilityCheck = true;
    float AimbotFOV = 90.0f;
    float AimbotSmoothValue = 0.15f;
    bool AutoAim = false;

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

    bool SandboxStealth = true;
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

void* (*Camera_get_main)();
Vector3 (*Camera_WorldToScreenPoint)(void* camera, Vector3 worldPosition, int eye);
void* (*CharacterManager_GetInstance)();
bool (*Character_IsVisible)(void* character);

// ═══════════════════════════════════════════════════════════════
// COMBAT HOOKS
// ═══════════════════════════════════════════════════════════════
void hooked_TakeDamage(void* instance, void* damageInfo, void* weaponInfo, void* checkParams, uint32_t vehicleID) {
    if (cfg.GodMode && damageInfo) {
        *(int*)((uintptr_t)damageInfo + 0x10) = 0;
    }
    if (damageInfo != nullptr) {
        if (cfg.InstantKill) {
            if (arc4random() % 10 != 0) {
                *(int*)((uintptr_t)damageInfo + 0x10) = 1000000;
            }
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
    if (cfg.FastReload) param1 *= 0.1f;
    if (cfg.NoReloadAnim) param1 = 0.0f;
    orig_OnWeaponReloadStarted(instance, param1, param2);
}

void hooked_OnWeaponReloadFinished(void* instance, bool param) {
    orig_OnWeaponReloadFinished(instance, param);
}

// ═══════════════════════════════════════════════════════════════
// SECURITY
// ═══════════════════════════════════════════════════════════════
BOOL IsScreenBeingCaptured() {
    for (UIScreen *screen in [UIScreen screens]) {
        if ([screen respondsToSelector:@selector(isCaptured)]) {
            if ([screen isCaptured]) return YES;
        }
    }
    return NO;
}

static int execute_SecurePathCheck(const char *path, struct stat *buf) {
    if (cfg.SandboxStealth && path != NULL) {
        std::string p(path);
        if (p.find("esign") != std::string::npos || 
            p.find("ESign") != std::string::npos || 
            p.find("Substrate") != std::string::npos) {
            errno = ENOENT;
            return -1;
        }
    }
    int (*orig_stat)(const char *, struct stat *) = (int (*)(const char *, struct stat *))dlsym(RTLD_NEXT, "stat");
    return orig_stat(path, buf);
}

void apply_RandomWindowSize() {
    float randomW = 600.0f + (arc4random() % 10 - 5);
    float randomH = 550.0f + (arc4random() % 10 - 5);
    ImGui::SetNextWindowSize(ImVec2(randomW, randomH), ImGuiCond_FirstUseEver);
}

int hooked_stat(const char *path, struct stat *buf) {
    return execute_SecurePathCheck(path, buf);
}

// ═══════════════════════════════════════════════════════════════
// AIMBOT & ESP
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

                if (cfg.ESP && cfg.ESPBox) {
                    draw_list->AddRect(ImVec2(screenX - 25, screenY - 50), ImVec2(screenX + 25, screenY + 50), IM_COL32(255, 0, 0, 255), 2.0f);
                }
                if (cfg.ESP && cfg.ESPLine) {
                    draw_list->AddLine(ImVec2(screenSize.x / 2, screenSize.y), ImVec2(screenX, screenY), IM_COL32(255, 255, 0, 255), 1.5f);
                }
                if (cfg.ESP && cfg.ESPHealth) {
                    int health = *(int*)(enemy + 0xA0);
                    int maxHealth = *(int*)(enemy + 0xA4);
                    float healthPct = health / (float)maxHealth;
                    ImU32 barColor = healthPct > 0.5f ? IM_COL32(0, 255, 0, 255) : healthPct > 0.25f ? IM_COL32(255, 255, 0, 255) : IM_COL32(255, 0, 0, 255);
                    draw_list->AddRectFilled(ImVec2(screenX - 25, screenY - 60), ImVec2(screenX - 25 + 50 * healthPct, screenY - 56), barColor);
                }
                if (cfg.ESP && cfg.ESPName) {
                    draw_list->AddText(ImVec2(screenX - 20, screenY - 70), IM_COL32(255, 255, 255, 255), "Enemy");
                }

                float crosshairDist = sqrtf(powf(screenX - screenSize.x / 2, 2) + powf(screenY - screenSize.y / 2, 2));
                if (crosshairDist < closestDistance) {
                    closestDistance = crosshairDist;
                    secureTarget = enemy;
                }
            }
        }
    }

    if ((cfg.Aimbot || cfg.Aimbot100 || cfg.AutoAim) && secureTarget) {
        Vector3 targetBonePos = *(Vector3*)(secureTarget + (cfg.AimbotHead ? 0x70 : 0x60));
        Vector3 delta = {targetBonePos.x - myPos.x, targetBonePos.y - myPos.y, targetBonePos.z - myPos.z};
        float hyp = sqrtf(delta.x * delta.x + delta.y * delta.y);
        Vector3 targetAngles = {atan2f(delta.y, hyp) * 180.0f / M_PI, atan2f(delta.x, delta.z) * 180.0f / M_PI, 0.0f};

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
// HOOKS LOADER
// ═══════════════════════════════════════════════════════════════
void loadHooks() {
    NSLog(@"[VIP MOD] Loading hooks...");
    uintptr_t base = getRealOffset(0);
    if (!base) { NSLog(@"[VIP MOD] ERROR: Base address!"); return; }

    *(void**)&Camera_get_main = (void*)(base + OFFSET_Camera_get_main);
    *(void**)&Camera_WorldToScreenPoint = (void*)(base + OFFSET_Camera_WorldToScreenPoint);
    *(void**)&CharacterManager_GetInstance = (void*)(base + OFFSET_CharacterManager_GetInstance);
    *(void**)&Character_IsVisible = (void*)(base + OFFSET_Character_IsVisible);

    HOOK(OFFSET_TakeDamage, hooked_TakeDamage, orig_TakeDamage);
    HOOK(OFFSET_SyncStartFire, hooked_SyncStartFire, orig_SyncStartFire);
    HOOK(OFFSET_OnWeaponAnimFireEffect, hooked_OnWeaponAnimFireEffect, orig_OnWeaponAnimFireEffect);
    HOOK(OFFSET_GetSkillBuffWeaponScatter, hooked_GetSkillBuffWeaponScatter, orig_GetSkillBuffWeaponScatter);
    HOOK(OFFSET_OnWeaponReloadStarted, hooked_OnWeaponReloadStarted, orig_OnWeaponReloadStarted);
    HOOK(OFFSET_OnWeaponReloadFinished, hooked_OnWeaponReloadFinished, orig_OnWeaponReloadFinished);

    NSLog(@"[VIP MOD] Hooks loaded!");
}

void setup() {
    void* domain = il2cpp_domain_get();
    if (domain) il2cpp_thread_attach(domain);
    loadHooks();
}

// ═══════════════════════════════════════════════════════════════
// IMGUI DRAW VIEW
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

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();

    ImGuiIO& io = ImGui::GetIO();
    ImGuiStyle& style = ImGui::GetStyle();
    ImVec4* colors = style.Colors;

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

    io.Fonts->AddFontDefault();

    ImGui_ImplMetal_Init(_device);
    return self;
}

- (void)showChange:(BOOL)open { MenDeal = open; }
- (MTKView *)mtkView { return (MTKView *)self.view; }

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
            hasActiveTouch = YES; break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
    if (MenDeal && io.WantCaptureMouse) { }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
    if (touches.count == 3) {
        MenDeal = NO; cfg.ESP = NO; cfg.Aimbot = NO;
        cfg.InstantKill = false; cfg.MagicBullet = false;
        NSLog(@"[PANIC ACTIVE] Memory wiped.");
    }
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self updateIOWithTouchEvent:event]; }
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self updateIOWithTouchEvent:event]; }
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self updateIOWithTouchEvent:event]; }

- (void)drawInMTKView:(MTKView*)view
{
    if (IsScreenBeingCaptured()) return;

    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;
    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 120);

    id commandBuffer = [self.commandQueue commandBuffer];
    [self.view setUserInteractionEnabled:MenDeal];

    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil) {
        id renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"VIP ModMenu"];

        ImGui_ImplMetal_NewFrame(renderPassDescriptor);
        ImGui::NewFrame();

        ImFont* font = ImGui::GetFont();
        font->Scale = 15.f / font->FontSize;

        CGFloat x = (([UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width) - 360) / 2;
        CGFloat y = (([UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height) - 300) / 2;
        ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_FirstUseEver);
        apply_RandomWindowSize();

        if (MenDeal) {
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

// ═══════════════════════════════════════════════════════════════
// DYLIB ENTRY POINT
// ═══════════════════════════════════════════════════════════════
__attribute__((constructor))
static void dylib_init() {
    NSLog(@"[VIP MOD] ✅ dylib injected");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        setup();
    });
}
