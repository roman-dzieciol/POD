// ============================================================================
//  PODShieldGun.uc ::
// ============================================================================
class PODShieldGun extends PODWeapon;


#EXEC OBJ LOAD FILE=InterfaceContent.utx

var Sound       ShieldHitSound;
var String      ShieldHitForce;

replication
{
    reliable if (Role == ROLE_Authority)
        ClientTakeHit;
}


simulated function vector CenteredEffectStart()
{
    local Vector X,Y,Z;

    GetViewAxes(X, Y, Z);
    return (Instigator.Location +
        Instigator.CalcDrawOffset(self) +
        EffectOffset.X * X +
        EffectOffset.Z * Z);
}

simulated event RenderOverlays( Canvas Canvas )
{
    local int m;

    if ((Hand < -1.0) || (Hand > 1.0))
    {
        for (m = 0; m < NUM_FIRE_MODES; m++)
        {
            if (FireMode[m] != None)
            {
                FireMode[m].DrawMuzzleFlash(Canvas);
            }
        }
    }
    Super.RenderOverlays(Canvas);
}

// AI Interface
function GiveTo(Pawn Other, optional Pickup Pickup)
{
    Super.GiveTo(Other, Pickup);
}

function bool CanAttack(Actor Other)
{
    return true;
}

simulated function BringUp(optional Weapon PrevWeapon)
{
    Super.Bringup(PrevWeapon);
    if ( !AmmoMaxed(1) )
    {
        while ( (FireMode[1].NextTimerPop < Level.TimeSeconds) && (FireMode[1].TimerInterval > 0.f) )
        {
            FireMode[1].Timer();
            if ( FireMode[1].bTimerLoop )
                FireMode[1].NextTimerPop = FireMode[1].NextTimerPop + FireMode[1].TimerInterval;
            else
                FireMode[1].TimerInterval = 0.f;
        }
    }
}

simulated function Timer()
{
    Super.Timer();
}


/* BestMode()
choose between regular or alt-fire
*/
function byte BestMode()
{
    local float EnemyDist;
    local bot B;

    B = Bot(Instigator.Controller);
    if ( (B == None) || (B.Enemy == None) )
        return 1;

    if ( B.bShieldSelf && B.ShouldKeepShielding() )
        return 1;

    EnemyDist = VSize(B.Enemy.Location - Instigator.Location);
    if ( EnemyDist > 4 * Instigator.GroundSpeed )
        return 1;
    if ( (B.MoveTarget != B.Enemy) && (B.IsRetreating() || (EnemyDist > 2 * Instigator.GroundSpeed)) )
        return 1;
    return 0;
}

// super desireable for bot waiting to impact jump
function float GetAIRating()
{
    local Bot B;
    local float EnemyDist;

    B = Bot(Instigator.Controller);
    if ( B == None )
        return AIRating;

    if ( B.bShieldSelf && B.ShouldKeepShielding() )
        return 9;

    if ( B.bPreparingMove && (B.ImpactTarget != None) )
        return 9;

    if ( B.PlayerReplicationInfo.HasFlag != None )
    {
        if ( Instigator.Health < 50 )
            return AIRating + 0.35;
        return AIRating + 0.25;
    }

    if ( B.Enemy == None )
        return AIRating;

    EnemyDist = VSize(B.Enemy.Location - Instigator.Location);
    if ( B.Stopped() && (EnemyDist > 100) )
        return 0.1;

    if ( (EnemyDist < 750) && (B.Skill <= 2) && !B.Enemy.IsA('Bot') && (PODShieldGun(B.Enemy.Weapon) != None) )
        return FClamp(300/(EnemyDist + 1), 0.6, 0.75);

    if ( EnemyDist > 400 )
        return 0.1;
    if ( (Instigator.Weapon != self) && (EnemyDist < 120) )
        return 0.25;

    return ( FMin(0.6, 90/(EnemyDist + 1)) );
}

// End AI interface

function AdjustPlayerDamage( out int Damage, Pawn InstigatedBy, Vector HitLocation,
                                 out Vector Momentum, class<DamageType> DamageType)
{
    local int Drain;
    local vector Reflect;
    local vector HitNormal;
    local float DamageMax;

    DamageMax = 100.0;
    if ( DamageType == class'Fell' )
        DamageMax = 20.0;
    else if( !DamageType.default.bArmorStops || !DamageType.default.bLocationalHit || (DamageType == class'DamTypeShieldImpact' && InstigatedBy == Instigator) )
        return;

    if ( CheckReflect(HitLocation, HitNormal, 0) )
    {
        Drain = Min( AmmoAmount(1)*2, Damage );
        Drain = Min(Drain,DamageMax);
        Reflect = MirrorVectorByNormal( Normal(Location - HitLocation), Vector(Instigator.Rotation) );
        Damage -= Drain;
        Momentum *= 1.25;
        if ( (Instigator != None) && (Instigator.PlayerReplicationInfo != None) && (Instigator.PlayerReplicationInfo.HasFlag != None) )
        {
            Drain = Min(AmmoAmount(1), Drain);
            ConsumeAmmo(1,Drain);
            DoReflectEffect(Drain);
        }
        else
        {
            ConsumeAmmo(1,Drain/2);
            DoReflectEffect(Drain/2);
        }
    }
}

function DoReflectEffect(int Drain)
{
    PlaySound(ShieldHitSound, SLOT_None);
    PODShieldFire(FireMode[1]).TakeHit(Drain);
    ClientTakeHit(Drain);
}

simulated function ClientTakeHit(int Drain)
{
    ClientPlayForceFeedback(ShieldHitForce);
    PODShieldFire(FireMode[1]).TakeHit(Drain);
}

simulated function float AmmoStatus(optional int Mode) // returns float value for ammo amount
{
    if ( Instigator == None || Instigator.Weapon != self )
    {
        if ( (FireMode[1].TimerInterval != 0.f) && (FireMode[1].NextTimerPop < Level.TimeSeconds) )
        {
            FireMode[1].Timer();
            if ( FireMode[1].bTimerLoop )
                FireMode[1].NextTimerPop = FireMode[1].NextTimerPop + FireMode[1].TimerInterval;
            else
                FireMode[1].TimerInterval = 0.f;
        }
    }
    return Super.AmmoStatus(Mode);
}


function bool CheckReflect( Vector HitLocation, out Vector RefNormal, int AmmoDrain )
{
    local Vector HitDir;
    local Vector FaceDir;

    if (!IsFiring() || AmmoAmount(0) == 0)
        return false;

    FaceDir = Vector(Instigator.Rotation);
    HitDir = Normal(Instigator.Location - HitLocation + Vect(0,0,8));
    //Log(self@"HitDir"@(FaceDir dot HitDir));

    RefNormal = FaceDir;

    //Log( "CheckReflect" @(FaceDir dot HitDir) );

    if ( FaceDir dot HitDir < -0.37 ) // 68 degree protection arc
    {
        if (AmmoDrain > 0)
            ConsumeAmmo(0,AmmoDrain);
        return true;
    }
    return false;
}

function float SuggestAttackStyle()
{
    return 0.8;
}

function float SuggestDefenseStyle()
{
    return -0.8;
}



DefaultProperties
{
    InventoryGroup=2

    HighDetailOverlay=Material'UT2004Weapons.WeaponSpecMap2'
    ItemName="Shield"
    Description="The Kemphler DD280 Riot Control Device has the ability to resist and reflect incoming projectiles and energy beams. The plasma wave inflicts massive damage, rupturing tissue, pulverizing organs, and flooding the bloodstream with dangerous gas bubbles.||This weapon may be intended for combat at close range, but when wielded properly should be considered as dangerous as any other armament in your arsenal."
    IconMaterial=Material'HudContent.Generic.HUD'
    IconCoords=(X1=169,Y1=39,X2=241,Y2=77)

    FireModeClass(0)=PODShieldFire
    FireModeClass(1)=PODShieldFire

    Mesh=mesh'Weapons.ShieldGun_1st'
    BobDamping=2.2
    PickupClass=class'ShieldGunPickup'
    EffectOffset=(X=15.0,Y=5.5,Z=2)
    bMeleeWeapon=true
    ShieldHitSound=Sound'WeaponSounds.ShieldGun.ShieldReflection'
    DrawScale=0.4
    PutDownAnim=PutDown
    DisplayFOV=60
    PlayerViewOffset=(X=2,Y=-0.7,Z=-2.7)
    SmallViewOffset=(X=10,Y=3.3,Z=-6.7)
    PlayerViewPivot=(Pitch=500,Roll=0,Yaw=500)

    SelectSound=Sound'WeaponSounds.ShieldGun_change'
    SelectForce="ShieldGun_change"
    ShieldHitForce="ShieldReflection"

    AIRating=0.35
    CurrentRating=0.35
    HudColor=(r=255,g=188,b=121,a=255)

    Priority=2
    CustomCrosshair=6
    CustomCrosshairTextureName="Crosshairs.Hud.Crosshair_Pointer"
    CustomCrosshairColor=(r=255,g=188,b=121,a=255)
    CustomCrosshairScale=1.0

    CenteredOffsetY=-9.0
    CenteredRoll=1000

}
