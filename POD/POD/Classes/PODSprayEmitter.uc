// ============================================================================
//  PODSprayEmitter.uc ::
// ============================================================================
class PODSprayEmitter extends PODEmitter;

var byte Team;


replication
{
    reliable if (bNetInitial && Role == ROLE_Authority)
        Team;
}

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    SetTimer(30,False);
}

simulated function Timer()
{
    Kill();
}

auto simulated state DarkMatter
{
    simulated event Touch( Actor Other )
    {
        if( PODKVehicle(Other) != None )
        {
            PODKVehicle(Other).TouchedDarkMatter(self);
        }
    }

    simulated event UnTouch( Actor Other )
    {
        if( PODKVehicle(Other) != None )
        {
            PODKVehicle(Other).UnTouchedDarkMatter(self);
        }
    }

    simulated function BeginState()
    {
        local Actor A;

        ForEach TouchingActors(class'Actor', A)
            Touch(A);
    }
}

DefaultProperties
{
    bNoDelete           = False
    RemoteRole          = ROLE_SimulatedProxy
    bAlwaysRelevant     = True
    CollisionRadius     = 512
    CollisionHeight     = 512
    bCollideActors      = True
    bNotOnDedServer     = False


    Begin Object Class=SpriteEmitter Name=SpriteEmitter0
        UseDirectionAs=PTDU_Scale
        UseCollision=True
        UseMaxCollisions=True
        UseColorScale=True
        SpinParticles=True
        UseSizeScale=True
        UseRegularSizeScale=False
        UniformSize=True
        AutomaticInitialSpawning=False
        UseRandomSubdivision=True
        ExtentMultiplier=(X=0.100000,Y=0.100000,Z=0.100000)
        DampingFactorRange=(X=(Min=0.100000,Max=0.100000),Y=(Min=0.100000,Max=0.100000),Z=(Min=0.100000,Max=0.100000))
        MaxCollisions=(Min=3.000000,Max=3.000000)
        ColorScale(1)=(RelativeTime=0.100000,Color=(A=255))
        ColorScale(2)=(RelativeTime=0.800000,Color=(A=255))
        ColorScale(3)=(RelativeTime=1.000000)
        ColorMultiplierRange=(X=(Min=0.000000,Max=0.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
        MaxParticles=12
        StartLocationShape=PTLS_Sphere
        SphereRadiusRange=(Min=512.000000,Max=512.000000)
        SizeScale(0)=(RelativeSize=8.000000)
        SizeScale(1)=(RelativeTime=1.000000,RelativeSize=12.000000)
        ParticlesPerSecond=12.000000
        InitialParticlesPerSecond=12.000000
        DrawStyle=PTDS_AlphaBlend
        Texture=Texture'AW-2004Particles.Fire.MuchSmoke1'
        TextureUSubdivisions=4
        TextureVSubdivisions=4
        LifetimeRange=(Min=1.000000,Max=1.000000)
        StartVelocityRadialRange=(Min=-100.000000,Max=-100.000000)
        GetVelocityDirectionFrom=PTVD_AddRadial
    End Object
    Emitters(0)=SpriteEmitter'SpriteEmitter0'

}
