// ============================================================================
//  PODMineGun.uc ::
// ============================================================================
class PODMineGun extends PODWeapon;

var array<PODMineProjectile> Grenades;
var int CurrentGrenades; //should be sync'ed with Grenades.length
var int MaxGrenades;

replication
{
    reliable if (bNetOwner && bNetDirty && ROLE == ROLE_Authority)
        CurrentGrenades;
}

simulated function bool HasAmmo()
{
    if (CurrentGrenades > 0)
        return true;

    return Super.HasAmmo();
}

simulated function OutOfAmmo()
{
}
simulated singular function ClientStopFire(int Mode)
{
    if (Mode == 1 && !HasAmmo())
        DoAutoSwitch();

    Super.ClientStopFire(Mode);
}

simulated function Destroyed()
{
    local int x;

    if (Role == ROLE_Authority)
    {
        for (x = 0; x < Grenades.Length; x++)
            if (Grenades[x] != None)
                Grenades[x].Explode(Grenades[x].Location, vect(0,0,1));
        Grenades.Length = 0;
    }

    Super.Destroyed();
}

// AI Interface
function float GetAIRating()
{
    local Bot B;
    local float EnemyDist;
    local vector EnemyDir;

    B = Bot(Instigator.Controller);
    if ( B == None )
        return AIRating;
    if ( B.Enemy == None )
    {
        if ( (B.Target != None) && VSize(B.Target.Location - B.Pawn.Location) > 1000 )
            return 0.2;
        return AIRating;
    }

    // if retreating, favor this weapon
    EnemyDir = B.Enemy.Location - Instigator.Location;
    EnemyDist = VSize(EnemyDir);
    if ( EnemyDist > 1500 )
        return 0.1;
    if ( B.IsRetreating() )
        return (AIRating + 0.4);
    if ( -1 * EnemyDir.Z > EnemyDist )
        return AIRating + 0.1;
    if ( (B.Enemy.Weapon != None) && B.Enemy.Weapon.bMeleeWeapon )
        return (AIRating + 0.3);
    if ( EnemyDist > 1000 )
        return 0.35;
    return AIRating;
}

/* BestMode()
choose between regular or alt-fire
*/
function byte BestMode()
{
    local int x;

    if (CurrentGrenades >= MaxGrenades || (AmmoAmount(0) <= 0 && FireMode[0].NextFireTime <= Level.TimeSeconds))
        return 1;

    for (x = 0; x < Grenades.length; x++)
        if (Grenades[x] != None && Pawn(Grenades[x].Base) != None)
            return 1;

    return 0;
}

function float SuggestAttackStyle()
{
    local Bot B;
    local float EnemyDist;

    B = Bot(Instigator.Controller);
    if ( (B == None) || (B.Enemy == None) )
        return 0.4;

    EnemyDist = VSize(B.Enemy.Location - Instigator.Location);
    if ( EnemyDist > 1500 )
        return 1.0;
    if ( EnemyDist > 1000 )
        return 0.4;
    return -0.4;
}

function float SuggestDefenseStyle()
{
    local Bot B;

    B = Bot(Instigator.Controller);
    if ( (B == None) || (B.Enemy == None) )
        return 0;

    if ( VSize(B.Enemy.Location - Instigator.Location) < 1600 )
        return -0.6;
    return 0;
}


// End AI Interface

defaultproperties
{
    ItemName="Mine"
    Description="Trident Defensive Technologies Series 7 Flechette Cannon has been taken to the next step in evolution with the production of the Mk3 \"Negotiator\". The ionized flechettes are capable of delivering second and third-degree burns to organic tissue, cauterizing the wound instantly.||Payload delivery is achieved via one of two methods: ionized flechettes launched in a spread pattern directly from the barrel; or via fragmentation grenades that explode on impact, radiating flechettes in all directions."
    IconMaterial=Material'HudContent.Generic.HUD'
    IconCoords=(X1=169,Y1=172,X2=245,Y2=208)

    FireModeClass(0)=PODMineFire
    FireModeClass(1)=PODMineFireAlt
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

    AIRating=+0.0
    CurrentRating=+0.0

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

    MaxGrenades=8
}
