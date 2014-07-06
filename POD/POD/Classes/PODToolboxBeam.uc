// ============================================================================
//  PODToolboxBeam.uc ::
// ============================================================================
class PODToolboxBeam extends PODEmitter;


var bool bCancel;
var vector EffectOffset;
var vector EndEffect;

replication
{
    reliable if (bNetDirty && Role == ROLE_Authority)
        bCancel, EndEffect;
}

function SetInitialState()
{
    Super.SetInitialState();


    if (Level.NetMode == NM_DedicatedServer)
        disable('Tick');
}



simulated function Tick(float deltaTime)
{
    local vector StartTrace, X, Y, Z;
    local float Dist;
    local PODToolboxGun Gun;

    if( bCancel )
    {
        bCancel = False;
        BeamEmitter(Emitters[0]).FadeOut = true;
        BeamEmitter(Emitters[0]).LifeTimeRange.Min = 1.25;
        BeamEmitter(Emitters[0]).LifeTimeRange.Max = 1.25;
        BeamEmitter(Emitters[0]).RespawnDeadParticles = False;
        return;
    }

    if( Instigator == None )
    {
        bCancel = True;
        return;
    }

    Gun = PODToolboxGun(Instigator.Weapon);
    if( Gun == None || Gun.TargetActor == None )
    {
        bCancel = True;
        return;
    }

    EndEffect = Gun.TargetHitLocation;

    if( BeamEmitter(Emitters[0]).RespawnDeadParticles == False )
    {
        bHidden = False;
        BeamEmitter(Emitters[0]).FadeOut = False;
        BeamEmitter(Emitters[0]).LifeTimeRange.Min = 0.02;
        BeamEmitter(Emitters[0]).LifeTimeRange.Max = 0.02;
        BeamEmitter(Emitters[0]).RespawnDeadParticles = True;
        BeamEmitter(Emitters[0]).AllParticlesDead = False;
        BeamEmitter(Emitters[0]).Reset();
    }

    if( Gun.GetFireMode(0).bIsFiring )
    {
        Emitters[0].Opacity = 0.8;
    }
    else
    {
        Emitters[0].Opacity = 0.2;
    }

    if (Instigator.IsFirstPerson())
    {
        Instigator.Weapon.GetViewAxes(X, Y, Z);
        if (Instigator.Weapon.WeaponCentered())
            StartTrace = Instigator.Location;
        else
            StartTrace = Instigator.Location + Instigator.CalcDrawOffset(Instigator.Weapon) + EffectOffset.X * X + Instigator.Weapon.Hand * EffectOffset.Y * Y + EffectOffset.Z * Z;
    }
    //else if (xPawn(Instigator) != None && xPawn(Instigator).WeaponAttachment != None)
    //    StartTrace = xPawn(Instigator).WeaponAttachment.GetTipLocation();
    else
        StartTrace = Instigator.Location;

    SetLocation(StartTrace);
    SetRotation(rotator(EndEffect - StartTrace));
    Dist = VSize(EndEffect - StartTrace);
    BeamEmitter(Emitters[0]).BeamDistanceRange.Min = Dist;
    BeamEmitter(Emitters[0]).BeamDistanceRange.Max = Dist;
}

DefaultProperties
{
    Begin Object Class=BeamEmitter Name=BeamEmitter0
        BeamDistanceRange=(Min=10000.000000,Max=10000.000000)
        DetermineEndPointBy=PTEP_Distance
        BeamTextureUScale=16.000000
        RotatingSheets=3
        LowFrequencyPoints=2
        HighFrequencyPoints=2
        AutomaticInitialSpawning=False
        ColorScale(0)=(Color=(R=192))
        ColorScale(1)=(RelativeTime=0.500000,Color=(B=64,G=64,R=255))
        ColorScale(2)=(RelativeTime=1.000000,Color=(R=192))
        ColorMultiplierRange=(X=(Min=0.500000,Max=0.500000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
        MaxParticles=1
        UseRotationFrom=PTRS_Actor
        StartSizeRange=(X=(Min=10.000000,Max=10.000000),Y=(Min=10.000000,Max=10.000000))
        InitialParticlesPerSecond=5000.000000
        Texture=Texture'AW-2004Particles.Weapons.BeamFragment'
        LifetimeRange=(Min=0.020000,Max=0.020000)
        StartVelocityRange=(X=(Min=1.000000,Max=1.000000))
    End Object
    Emitters(0)=BeamEmitter'BeamEmitter0'

    bHidden = True
    bNetInitialRotation=true
    bNoDelete=false
    AutoDestroy=False
    RemoteRole=ROLE_SimulatedProxy
    bUpdateSimulatedPosition=true
    bReplicateInstigator=true

    EffectOffset=(X=0,Y=0,Z=0)
}
