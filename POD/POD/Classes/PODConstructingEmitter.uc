// ============================================================================
//  PODConstructingEmitter.uc ::
// ============================================================================
class PODConstructingEmitter extends PODEmitter;

var class<PODBlueprint> LastBlueprint;

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();
    SetTimer(0.2,True);
}

simulated function Timer()
{
    if( PODBuildSpot(Owner) != None )
    {
        if( PODBuildSpot(Owner).Blueprint != LastBlueprint )
        {
            SetRotation( PODBuildSpot(Owner).BaseRotation );
            SetBlueprint( PODBuildSpot(Owner).Blueprint );
        }
    }
}

simulated function SetBlueprint( class<PODBlueprint> B )
{
    Log( "SetBlueprint" @B );

    if( B == None )
    {
        StopFX();
    }
    else
    {
        StartFX(B);
    }

    LastBlueprint = B;
}

simulated final function StartFX( class<PODBlueprint> B )
{
    Emitters[0].StartLocationOffset = B.default.EmitterOffset;
    Emitters[0].MeshScaleRange.X.Min = B.default.EmitterScale;
    Emitters[0].MeshScaleRange.X.Max = B.default.EmitterScale;
    Emitters[0].MeshScaleRange.Y.Min = B.default.EmitterScale;
    Emitters[0].MeshScaleRange.Y.Max = B.default.EmitterScale;
    Emitters[0].MeshScaleRange.Z.Min = B.default.EmitterScale;
    Emitters[0].MeshScaleRange.Z.Max = B.default.EmitterScale;
    Emitters[0].MeshSpawningStaticMesh = B.default.EmitterMesh;
    Emitters[0].RespawnDeadParticles = True;
    Emitters[0].AllParticlesDead = False;
    Emitters[0].Reset();
}

simulated final function StopFX()
{
    Emitters[0].RespawnDeadParticles = False;
}

DefaultProperties
{
    Begin Object Class=SpriteEmitter Name=SpriteEmitter0
        FadeOut=True
        FadeIn=True
        VelocityFromMesh=True
        UseRevolution=True
        UniformSize=True
        ScaleSizeXByVelocity=True
        AutomaticInitialSpawning=False
        RespawnDeadParticles=False
        AllParticlesDead=True
        UseVelocityScale=True
        FadeOutStartTime=0.500000
        FadeInEndTime=0.100000
        CoordinateSystem=PTCS_Relative
        MaxParticles=200
        MeshSpawningStaticMesh=None
        MeshSpawning=PTMS_Random
        VelocityScaleRange=(X=(Min=-10.000000,Max=5.000000),Y=(Min=-10.000000,Max=5.000000),Z=(Min=-10.000000,Max=5.000000))
        RevolutionsPerSecondRange=(X=(Min=-0.020000,Max=0.020000),Y=(Min=-0.020000,Max=0.020000),Z=(Min=-0.020000,Max=0.020000))
        StartSizeRange=(X=(Min=10.000000,Max=10.000000),Y=(Min=10.000000,Max=10.000000))
        ScaleSizeByVelocityMultiplier=(X=0.050000,Y=0.050000,Z=0.050000)
        ScaleSizeByVelocityMax=1.000000
        InitialParticlesPerSecond=200.000000
        Texture=Texture'EmitterTextures.Flares.EFlareR'
        LifetimeRange=(Min=1.000000,Max=1.000000)
        StartVelocityRadialRange=(Min=-10.000000)
        GetVelocityDirectionFrom=PTVD_AddRadial
        VelocityScale(0)=(RelativeVelocity=(X=1.000000,Y=1.000000,Z=1.000000))
        VelocityScale(1)=(RelativeTime=1.000000,RelativeVelocity=(X=3.000000,Y=3.000000,Z=3.000000))
    End Object
    Emitters(0)=SpriteEmitter'SpriteEmitter0'


    bNoDelete=false
    AutoDestroy=False
    RemoteRole=ROLE_None
    LastBlueprint=None



}
