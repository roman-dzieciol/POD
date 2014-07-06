// ============================================================================
//  PODNeedlerProjectile.uc ::
// ============================================================================
class PODNeedlerProjectile extends PODHomingProjectile;

#exec OBJ LOAD FILE=..\Sounds\MenuSounds.uax

var bool bCanHitOwner;
var xEmitter Trail;
var class<xEmitter> HitEffectClass;
var float LastSparkTime;
var Actor IgnoreActor; //don't stick to this actor
var byte Team;
var Emitter Beacon;


replication
{
    reliable if (bNetDirty && Role == ROLE_Authority)
        IgnoreActor, Team;
}



simulated function BlowUp(vector HitLocation)
{
    Super.BlowUp(HitLocation);

    //explosion
    if( !bNoFX )
    {
        if( EffectIsRelevant(Location,false) )
        {
            Spawn(class'ONSGrenadeExplosionEffect',,, Location, rotator(vect(0,0,1)));
            Spawn(ExplosionDecal,self,, Location, rotator(vect(0,0,-1)));
        }
        PlaySound(sound'WeaponSounds.BExplosion3',,TransientSoundVolume);
    }
}



simulated function DestroyEffects()
{
    Super.DestroyEffects();

    if( Trail != None )
        Trail.mRegen = false;

    if( Beacon != None )
        Beacon.Destroy();
}

simulated function PostBeginPlay()
{
    local PlayerController PC;

    Super.PostBeginPlay();

    if ( Level.NetMode != NM_DedicatedServer)
    {
        PC = Level.GetLocalPlayerController();
        if ( (PC.ViewTarget != None) && VSize(PC.ViewTarget.Location - Location) < 5500 )
            Trail = Spawn(class'GrenadeSmokeTrail', self,, Location, Rotation);
    }

    Velocity = Speed * Vector(Rotation);
    if (PhysicsVolume.bWaterVolume)
        Velocity = 0.6*Velocity;

    if (Role == ROLE_Authority && Instigator != None)
        Team = Instigator.GetTeamNum();

}

simulated function PostNetBeginPlay()
{
    if ( Level.NetMode != NM_DedicatedServer )
    {
        if (Team == 1)
            Beacon = spawn(class'ONSGrenadeBeaconBlue', self);
        else
            Beacon = spawn(class'ONSGrenadeBeaconRed', self);

        if (Beacon != None)
            Beacon.SetBase(self);
    }
    Super.PostNetBeginPlay();
}


simulated function ProcessTouch( actor Other, vector HitLocation )
{
    if( Reflect(Other) )
        return;

    if (!bPendingDelete && Base == None && Other != IgnoreActor && ( Other.Class != Class && (Other != Instigator || bCanHitOwner)))
        Stick(Other, HitLocation);
}

simulated function HitWall( vector HitNormal, actor Other )
{
    if( Reflect(Other) )
        return;

    if (!bPendingDelete && Base == None && Other != IgnoreActor && ( Other.Class != Class && (Other != Instigator || bCanHitOwner)))
        Stick(Other, Location);
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
    LastTouched = Base;
    BlowUp(HitLocation);
    Destroy();
}

simulated function TakeDamage(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
    if( Damage > 0 )
    {
        Explode(Location, vect(0,0,1));
    }
}

simulated function Stick(actor Other, vector HitLocation)
{
    local vector HitNormal;

    HitNormal = Normal(Other.Location - Location);
    LastTouched = Other;

    if( Trail != None )
        Trail.mRegen = false; // stop the emitter from regenerating

    bBounce = False;
    SetPhysics(PHYS_None);
    SetBase(Other);
    if (Base == None)
    {
        UnStick();
        return;
    }
    bCollideWorld = False;
    bProjTarget = true;

    PlaySound(Sound'MenuSounds.Select3',,2.5*TransientSoundVolume);

    GotoState('Explosion');
}

simulated function UnStick()
{
    Explode(Location, vect(0,0,1));
}

simulated function BaseChange()
{
    if (!bPendingDelete && Physics == PHYS_None && Base == None)
        UnStick();
}

simulated function PawnBaseDied()
{
    Explode(Location, vect(0,0,1));
}

state Explosion
{
Begin:
    SetTimer(0, false);
    Sleep(2);
    Explode(Location, vect(0,0,1));
}


DefaultProperties
{
    Speed                       = 10000
    MaxSpeed                    = 10000

    Damage                      = 20
    DamageRadius                = 192.0
    MomentumTransfer            = 50000
    MyDamageType                = class'DamTypeONSGrenade'

    CollisionRadius             = 1
    CollisionHeight             = 1

    HitEffectClass              = class'XEffects.WallSparks'
    ExplosionDecal              = class'ONSRocketScorch'
    ImpactSound                 = Sound'WeaponSounds.P1GrenFloor1'

    DrawType                    = DT_StaticMesh
    StaticMesh                  = StaticMesh'WeaponStaticMesh.GrenadeMesh'
    DrawScale                   = 3.0
    AmbientGlow                 = 100

    bHardAttach                 = True
    bSwitchToZeroCollision      = True

    bFixedRotationDir           = True
    RotationRate                = (Roll=50000)
    DesiredRotation             = (Roll=30000)

}
