// ============================================================================
//  PODInjectGun.uc ::
// ============================================================================
class PODInjectGun extends PODWeapon;


function float SuggestAttackStyle()
{
    return 0.9;
}

function float SuggestDefenseStyle()
{
    return 0.9;
}

DefaultProperties
{

    HighDetailOverlay=Material'UT2004Weapons.WeaponSpecMap2'
    ItemName="Flak Cannon"
    Description="Trident Defensive Technologies Series 7 Flechette Cannon has been taken to the next step in evolution with the production of the Mk3 \"Negotiator\". The ionized flechettes are capable of delivering second and third-degree burns to organic tissue, cauterizing the wound instantly.||Payload delivery is achieved via one of two methods: ionized flechettes launched in a spread pattern directly from the barrel; or via fragmentation grenades that explode on impact, radiating flechettes in all directions."
    IconMaterial=Material'HudContent.Generic.HUD'
    IconCoords=(X1=169,Y1=172,X2=245,Y2=208)

    FireModeClass(0)=PODInjectFire
    FireModeClass(1)=PODInjectFire
    InventoryGroup=7
    BobDamping=1.4
    EffectOffset=(X=200.0,Y=32.0,Z=-25.0)
    PutDownAnim=PutDown

    DisplayFOV=60
    DrawScale=1.0
    PlayerViewOffset=(X=-7,Y=8,Z=0)
    SmallViewOffset=(X=5,Y=14,Z=-6)
    PlayerViewPivot=(Pitch=0,Roll=200,Yaw=16884)
    SelectSound=Sound'WeaponSounds.FlakCannon.SwitchToFlakCannon'
    SelectAnim=Pickup
    SelectForce="SwitchToFlakCannon"
    bMeleeWeapon=true

    AIRating=+0.75
    CurrentRating=+0.75

    bDynamicLight=false
    LightType=LT_Steady
    LightEffect=LE_NonIncidence
    LightBrightness=255
    LightHue=30
    LightSaturation=150
    LightRadius=4.0

    HudColor=(r=255,g=128,b=0,a=255)
    Priority=13
    CustomCrosshair=9
    CustomCrosshairTextureName="Crosshairs.Hud.Crosshair_Triad3"
    CustomCrosshairColor=(r=255,g=128,b=0,a=255)

    CenteredOffsetY=-4.0
    CenteredYaw=-500
    CenteredRoll=3000
}
