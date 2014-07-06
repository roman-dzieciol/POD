// ============================================================================
//  PODNeedlerGun.uc ::
// ============================================================================
class PODNeedlerGun extends PODWeapon;

var float BarrelRotation;
var float FinalRotation;
var bool bRotateBarrel;

var Pawn SeekTarget;
var float LockTime, UnLockTime, SeekCheckTime;
var bool bLockedOn, bBreakLock;
var bool bTightSpread;
var() float SeekCheckFreq, SeekRange;
var() float LockRequiredTime, UnLockRequiredTime;
var() float LockAim;

replication
{
    reliable if (Role == ROLE_Authority && bNetOwner)
        bLockedOn;

}

function Tick(float dt)
{
    local Pawn Other;
    local Vector StartTrace;
    local Rotator Aim;
    local float BestDist, BestAim;

    if (Instigator == None || Instigator.Weapon != self)
        return;

    if ( Role < ROLE_Authority )
        return;

    if ( !Instigator.IsHumanControlled() )
        return;

    if (Level.TimeSeconds > SeekCheckTime)
    {
        if (bBreakLock)
        {
            bBreakLock = false;
            bLockedOn = false;
            SeekTarget = None;
        }

        StartTrace = Instigator.Location;
        Aim = Instigator.GetViewRotation();

        BestAim = LockAim;
        Other = Instigator.Controller.PickTarget(BestAim, BestDist, Vector(Aim), StartTrace, SeekRange);

        if ( CanLockOnTo(Other) )
        {
            if (Other == SeekTarget)
            {
                LockTime += SeekCheckFreq;
                if (!bLockedOn && LockTime >= LockRequiredTime)
                {
                    bLockedOn = true;
                    PlayerController(Instigator.Controller).ClientPlaySound(Sound'WeaponSounds.LockOn');
                 }
            }
            else
            {
                SeekTarget = Other;
                LockTime = 0.0;
            }
            UnLockTime = 0.0;
        }
        else
        {
            if (SeekTarget != None)
            {
                UnLockTime += SeekCheckFreq;
                if (UnLockTime >= UnLockRequiredTime)
                {
                    SeekTarget = None;
                    if (bLockedOn)
                    {
                        bLockedOn = false;
                        PlayerController(Instigator.Controller).ClientPlaySound(Sound'WeaponSounds.SeekLost');
                    }
                }
            }
            else
                 bLockedOn = false;
         }

        SeekCheckTime = Level.TimeSeconds + SeekCheckFreq;
    }
}

function bool CanLockOnTo(Actor Other)
{
    local Pawn P;

    P = Pawn(Other);

    if (P == None || P == Instigator || !P.bProjTarget)
        return false;

    if (!Level.Game.bTeamGame)
        return true;

    if ( (Instigator.Controller != None) && Instigator.Controller.SameTeamAs(P.Controller) )
        return false;

    return ( (P.PlayerReplicationInfo == None) || (P.PlayerReplicationInfo.Team != Instigator.PlayerReplicationInfo.Team) );
}

function Projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local PODNeedlerProjectile Rocket;
    local bot B;

    // decide if bot should be locked on
    B = Bot(Instigator.Controller);
    if ( (B != None) && (B.Skill > 2 + 5 * FRand()) && (FRand() < 0.6) && (B.Target != None)
        && (B.Target == B.Enemy) && (VSize(B.Enemy.Location - B.Pawn.Location) > 2000 + 2000 * FRand())
        && (Level.TimeSeconds - B.LastSeenTime < 0.4) && (Level.TimeSeconds - B.AcquireTime > 1.5) )
    {
        bLockedOn = true;
        SeekTarget = B.Enemy;
    }

    if (bLockedOn && SeekTarget != None)
    {
        Rocket = Spawn(class'PODNeedlerProjectile',,, Start, Dir);
        Rocket.Seeking = SeekTarget;
        return Rocket;
    }
    else
    {
        Rocket = Spawn(class'PODNeedlerProjectile',,, Start, Dir);
        return Rocket;
    }
}


function float GetAIRating()
{
    local Bot B;

    B = Bot(Instigator.Controller);
    if ( B == None )
        return AIRating;

    if ( B.Enemy == None )
    {
        if ( (B.Target != None) && VSize(B.Target.Location - B.Pawn.Location) > 8000 )
            return 0.5;
        return AIRating;
    }

    if ( !B.EnemyVisible() )
        return AIRating - 0.15;

    return AIRating * FMin(Pawn(Owner).DamageScaling, 1.5);
}

function byte BestMode()
{
    return 0;
}

DefaultProperties
{
    ItemName                        = "Needler"
    Description                     = "Similar to a machine gun that shoots small piercing darts."

    FireModeClass(0)                = class'PODNeedlerFire'
    FireModeClass(1)                = class'PODNeedlerFire'

    InventoryGroup                  = 7

    SelectSound                     = Sound'WeaponSounds.Minigun.SwitchToMiniGun'
    SelectForce                     = "SwitchToMiniGun"

    HudColor                        = (B=255)

    CustomCrosshair                 = 12
    CustomCrossHairTextureName      = "Crosshairs.Hud.Crosshair_Circle1"
    CustomCrosshairColor            = (r=255,g=255,b=255,a=255)

    AIRating=+0.69
    CurrentRating=+0.69

    SeekCheckFreq=0.1
    SeekRange=8000
    LockRequiredTime=0.3
    UnLockRequiredTime=0.5
    LockAim=0.965 // 15 deg
}


