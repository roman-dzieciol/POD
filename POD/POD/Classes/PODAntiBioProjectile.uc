// ============================================================================
//  PODAntiBioProjectile.uc ::
// ============================================================================
class PODAntiBioProjectile extends PODHomingProjectile;

var xEmitter SmokeTrail;
var Effects Corona;


simulated function DestroyEffects()
{
    Super.DestroyEffects();

    if ( SmokeTrail != None )
        SmokeTrail.mRegen = False;
    if ( Corona != None )
        Corona.Destroy();
}

simulated function PostBeginPlay()
{
    if ( Level.NetMode != NM_DedicatedServer)
    {
        SmokeTrail = Spawn(class'RocketTrailSmoke',self);
        Corona = Spawn(class'RocketCorona',self);
    }

    Velocity = speed * vector(Rotation);

    Super.PostBeginPlay();
}

simulated function PostNetBeginPlay()
{
    local PlayerController PC;

    Super.PostNetBeginPlay();

    if ( Level.NetMode == NM_DedicatedServer )
        return;
    if ( Level.bDropDetail || (Level.DetailMode == DM_Low) )
    {
        bDynamicLight = false;
        LightType = LT_None;
    }
    else
    {
        PC = Level.GetLocalPlayerController();
        if ( (Instigator != None) && (PC == Instigator.Controller) )
            return;
        if ( (PC == None) || (PC.ViewTarget == None) || (VSize(PC.ViewTarget.Location - Location) > 3000) )
        {
            bDynamicLight = false;
            LightType = LT_None;
        }
    }
}


simulated function HitWall( vector HitNormal, actor Other )
{
    if( Reflect(Other) )
        return;

    if ( Other != instigator )
        Super.HitWall(HitNormal, Other);
}

simulated function ProcessTouch (Actor Other, Vector HitLocation)
{
    if( Reflect(Other) )
        return;

    if ( (Other != instigator) && (!Other.IsA('Projectile') || Other.bProjTarget) )
        Explode(HitLocation, vector(rotation)*-1 );
}

function BlowUp(vector HitLocation)
{
    HurtRadius(Damage, DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
    MakeNoise(1.0);
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
    local PlayerController PC;

    PlaySound(sound'WeaponSounds.BExplosion3',,2.5*TransientSoundVolume);
    if ( EffectIsRelevant(Location,false) )
    {
        Spawn(class'NewExplosionA',,,HitLocation + HitNormal*20,rotator(HitNormal));
        PC = Level.GetLocalPlayerController();
        if ( (PC.ViewTarget != None) && VSize(PC.ViewTarget.Location - Location) < 5000 )
            Spawn(class'ExplosionCrap',,, HitLocation + HitNormal*20, rotator(HitNormal));
//      if ( (ExplosionDecal != None) && (Level.NetMode != NM_DedicatedServer) )
//          Spawn(ExplosionDecal,self,,Location, rotator(-HitNormal));
    }

    BlowUp(HitLocation);
    Destroy();
}


defaultproperties
{
    Speed                               = 1350.0
    MaxSpeed                            = 1350.0
    Damage                              = 90.0
    DamageRadius                        = 220.0
    MomentumTransfer                    = 50000

    MyDamageType                        = class'DamTypeRocketHoming'
    ExplosionDecal                      = class'RocketMark'

    RemoteRole                          = ROLE_SimulatedProxy
    LifeSpan                            = 8.0

    AmbientSound                        = Sound'WeaponSounds.RocketLauncher.RocketLauncherProjectile'
    SoundVolume                         = 255
    SoundRadius                         = 100

    DrawType                            = DT_StaticMesh
    StaticMesh                          = StaticMesh'WeaponStaticMesh.RocketProj'
    DrawScale                           = 1.0

    AmbientGlow                         = 96
    bUnlit                              = True
    LightType                           = LT_Steady
    LightEffect                         = LE_QuadraticNonIncidence
    LightBrightness                     = 255
    LightHue                            = 28
    LightRadius                         = 5
    bDynamicLight                       = true

    bCollideWorld                       = true
    bFixedRotationDir                   = True
    RotationRate                        = (Roll=50000)
    DesiredRotation                     = (Roll=30000)

    ForceType                           = FT_Constant
    ForceScale                          = 5.0
    ForceRadius                         = 100.0
    FluidSurfaceShootStrengthMod        = 10.0


}
