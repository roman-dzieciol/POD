// ============================================================================
//  PODHomingProjectile.uc ::
// ============================================================================
class PODHomingProjectile extends PODProjectile;

var Actor Seeking;
var vector InitialDir;

replication
{
    reliable if( bNetInitial && Role == ROLE_Authority )
        Seeking, InitialDir;
}

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    SetTimer(0.05, true);
}

simulated function Timer()
{
    local vector ForceDir;
    local float VelMag;

    Acceleration = vect(0,0,0);

    if( InitialDir == vect(0,0,0) )
        InitialDir = Normal(Velocity);

    Super.Timer();

    if( Seeking != None && Seeking != Instigator )
    {
        // Do normal guidance to target.
        ForceDir = Normal(Seeking.Location - Location);

        if( (ForceDir Dot InitialDir) > 0 )
        {
            VelMag = VSize(Velocity);
            ForceDir = Normal(ForceDir * 0.8 * VelMag + Velocity);
            Velocity =  VelMag * ForceDir;
            Acceleration += 50 * ForceDir;
        }
        // Update projectile so it faces in the direction its going.
        SetRotation(rotator(Velocity));
    }
}



DefaultProperties
{

    bNetTemporary               = false
    bOnlyDirtyReplication       = true
    RemoteRole                  = ROLE_SimulatedProxy
    Physics                     = PHYS_Falling
}
