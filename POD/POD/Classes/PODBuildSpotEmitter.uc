// ============================================================================
//  PODBuildSpotEmitter.uc ::
// ============================================================================
class PODBuildSpotEmitter extends PODEmitter;


simulated function Reset();

defaultproperties
{
     Begin Object Class=MeshEmitter Name=MeshEmitter0
         StaticMesh=StaticMesh'AS_Decos.HellBenderEngine'
         SpinParticles=True
         UniformSize=True
         AutomaticInitialSpawning=True
         TriggerDisabled=False
         MaxParticles=1
         StartLocationOffset=(X=0.000000)
         StartSpinRange=(Z=(Min=0.250000,Max=0.250000))
         StartSizeRange=(X=(Min=1.0,Max=1.0),Y=(Min=1.0,Max=1.0),Z=(Min=1.0,Max=1.0))
         InitialParticlesPerSecond=50000.000000
         CoordinateSystem=PTCS_Relative
     End Object
     Emitters(0)=MeshEmitter'MeshEmitter0'

     CullDistance=2000
     bNoDelete=False
     bDeferRendering=False
     bUnlit=False
}
