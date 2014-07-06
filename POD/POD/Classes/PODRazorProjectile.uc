// ============================================================================
//  PODRazorProjectile.uc ::
// ============================================================================
class PODRazorProjectile extends PODProjectile;

var ShockBall ShockBallEffect;

simulated event PreBeginPlay()
{
    Super.PreBeginPlay();

    if( Pawn(Owner) != None )
        Instigator = Pawn( Owner );
}

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    if( Level.NetMode != NM_DedicatedServer )
    {
        ShockBallEffect = Spawn(class'ShockBall', self);
        ShockBallEffect.SetBase(self);
    }

    Velocity = Speed * Vector(Rotation);
    SetTimer(0.1, true);
}

simulated function PostNetBeginPlay()
{
    local PlayerController PC;

    Super.PostNetBeginPlay();

    if( Level.NetMode == NM_DedicatedServer )
        return;

    PC = Level.GetLocalPlayerController();
    if( (Instigator != None) && (PC == Instigator.Controller) )
        return;
    if ( Level.bDropDetail || (Level.DetailMode == DM_Low) )
    {
        bDynamicLight = false;
        LightType = LT_None;
    }
    else if ( (PC == None) || (PC.ViewTarget == None) || (VSize(PC.ViewTarget.Location - Location) > 3000) )
    {
        bDynamicLight = false;
        LightType = LT_None;
    }
}

function Timer()
{
    local float f;

    f = Smerp(lifespan / default.lifespan,0,1);
    SetDrawScale(Default.DrawScale*f);
}

simulated function Destroyed()
{
    if( ShockBallEffect != None )
    {
        if( bNoFX )
            ShockBallEffect.Destroy();
        else
            ShockBallEffect.Kill();
    }

    Super.Destroyed();
}


simulated function DestroyEffects()
{
    Super.DestroyEffects();

    if( ShockBallEffect != None )
        ShockBallEffect.Destroy();
}

simulated function HitWall( vector HitNormal, actor Other )
{
    if( Reflect(Other) )
        return;

    Super.HitWall(HitNormal,Other);
}

simulated function ProcessTouch ( Actor Other, vector HitLocation )
{
    local Vector V;

    if( Other == Instigator ) return;
    if( Other == Owner ) return;
    if( Other != None && Other.Class == Class )
        return;

    if( Reflect(Other) )
        return;

    if( !Other.IsA('Projectile') || Other.bProjTarget )
    {
        xLog( "Explode" @Other );

        if( Role == ROLE_Authority )
        {
            V = GetStartPos();
            if( V != vect(0,0,0) )
            {
                Other.TakeDamage(Damage,Instigator,HitLocation,MomentumTransfer * Normal(Velocity),MyDamageType);
            }
        }
        Explode(HitLocation, Normal(HitLocation-Other.Location));
    }
}

simulated function Explode(vector HitLocation,vector HitNormal)
{
    local xEmitter hitEmitter;
    local vector V;

    PlaySound(ImpactSound, SLOT_Misc);
    if( EffectIsRelevant(Location,false) )
    {
        hitEmitter = Spawn(class'XEffects.ChildLightningBolt',,, Location);
        if ( hitEmitter != None )
            hitEmitter.mSpawnVecA = Location;

        V = GetStartPos();

        if( V != vect(0,0,0) )
        {
            hitEmitter = Spawn(class'XWeapons.NewLightningBolt',,, V);
            if( hitEmitter != None )
                hitEmitter.mSpawnVecA = Location;
        }

        Spawn(class'ShockExplosionCore',,, Location);
        if( !Level.bDropDetail && (Level.DetailMode != DM_Low) )
            Spawn(class'ShockExplosion',,, Location);
    }
    SetCollisionSize(0.0, 0.0);
    Destroy();
}

simulated function vector GetStartPos()
{
    local vector a,b,x,y,z;

    if( PODKVehicle(Instigator) != None )
    {
        GetAxes(Instigator.Rotation,X,Y,Z);

        a = PODKVehicle(Instigator).GetGunOffset(0);
        b = PODKVehicle(Instigator).GetGunOffset(1);

        a = instigator.Location + X*a.X + Y*a.Y + Z*a.Z;
        b = instigator.Location + X*b.X + Y*b.Y + Z*b.Z;

        if( FastTrace(a,Location) && VSize(a-Location) < VSize(b-Location) )
            return a;
        else if( FastTrace(b,Location) )
            return b;
    }

    if( FastTrace(Instigator.Location,Location) )
        return Instigator.Location;
    else
        return vect(0,0,0);
}


defaultproperties
{
    LifeSpan                            = 0.5

    Speed                               = 16000.000000
    MaxSpeed                            = 16000.000000

    Damage                              = 100.000000
    DamageRadius                        = 0.000000
    MomentumTransfer                    = 70000.000000
    MyDamageType                        = Class'XWeapons.DamTypeShockBall'

    ForceType                           = FT_Constant
    ForceRadius                         = 40.000000
    ForceScale                          = 5.000000
    FluidSurfaceShootStrengthMod        = 8.000000

    CollisionRadius                     = 10.000000
    CollisionHeight                     = 10.000000
    bSwitchToZeroCollision              = True
    bProjTarget                         = True
    bUseCollisionStaticMesh             = True

    bNetTemporary                       = False
    bOnlyDirtyReplication               = True

    bDynamicLight                       = True
    LightType                           = LT_Steady
    LightEffect                         = LE_QuadraticNonIncidence
    LightHue                            = 195
    LightSaturation                     = 85
    LightBrightness                     = 255.000000
    LightRadius                         = 4.000000

    DrawType                            = DT_Sprite
    DrawScale                           = 0.700000
    Texture                             = Texture'XEffectMat.Shock.shock_core_low'
    Skins(0)                            = Texture'XEffectMat.Shock.shock_core_low'
    Style                               = STY_Translucent
    CullDistance                        = 4000.000000
    bAlwaysFaceCamera                   = True
    ExplosionDecal                      = Class'XEffects.ShockImpactScorch'
    MaxEffectDistance                   = 7000.000000

    SoundVolume                         = 50
    SoundRadius                         = 100.000000
    AmbientSound                        = Sound'WeaponSounds.ShockRifle.ShockRifleProjectile'
    ImpactSound                         = Sound'WeaponSounds.ShockRifle.ShockRifleExplosion'
}
