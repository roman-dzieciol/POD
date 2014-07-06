// ============================================================================
//  PODProjectileFire.uc ::
// ============================================================================
class PODProjectileFire extends PODWeaponFire;


var() int ProjPerFire;
var() Vector ProjSpawnOffset; // +x forward, +y right, +z up


function float MaxRange()
{
    return 8192;
}


function DoFireEffect()
{
    local Vector StartProj, StartTrace, X,Y,Z;
    local Rotator R, Aim;
    local int i;
    local int SpawnCount;
    local float theta;
    local vector GunOffset;
    //local Vector HitLocation, HitNormal;
    //local Actor Other;

    Instigator.MakeNoise(1.0);
    Weapon.GetViewAxes(X,Y,Z);


    StartTrace = Instigator.Location;

    SpawnCount = Max(1, ProjPerFire * int(Load));

    for( i=0; i!=SpawnCount; ++i )
    {

        GunOffset = PODKVehicle(Instigator).GetGunOffset(i%2);
        StartProj = StartTrace + X*GunOffset.X + Y*GunOffset.Y + Z*GunOffset.Z;
    //    Weapon.DrawStayingDebugLine(StartProj,StartProj+X*1024,0,255,0);
    //    if( !Instigator.TraceThisActor(HitLocation, HitNormal, Instigator.Location, StartProj+X*1024,vect(1,1,1)*128) )
    //    {
    //        StartProj = HitLocation + X * 128;
    //        Weapon.DrawStayingDebugLine(StartProj,StartProj+X*1024,0,255,255);
    //    }

        // check if projectile would spawn through a wall and adjust start location accordingly
    //    Other = Weapon.Trace(HitLocation, HitNormal, StartProj, StartTrace, false);
    //    if (Other != None)
    //    {
    //        StartProj = HitLocation;
    //    }

        //Extent = CollisionRadius * vect(1,1,0);
        //Extent.Z = CollisionHeight;


        Aim = AdjustAim(StartProj, AimError);

        switch (SpreadStyle)
        {
        case SS_Random:
            X = Vector(Aim);
            R.Yaw = Spread * (FRand()-0.5);
            R.Pitch = Spread * (FRand()-0.5);
            R.Roll = Spread * (FRand()-0.5);
            SpawnProjectile(StartProj, Rotator(X >> R));
            break;
        case SS_Line:
            theta = Spread*PI/32768*(i - float(SpawnCount-1)/2.0);
            X.X = Cos(theta);
            X.Y = Sin(theta);
            X.Z = 0.0;
            SpawnProjectile(StartProj, Rotator(X >> Aim));
            break;
        default:
            SpawnProjectile(StartProj, Aim);
        }

    }
}

function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local Projectile p;

    if( ProjectileClass != None )
        p = Weapon.Spawn(ProjectileClass,,, Start, Dir);

    if( p == None )
        return None;

    p.Damage *= DamageAtten;
    return p;
}

simulated function vector GetFireStart(vector X, vector Y, vector Z)
{
    return Instigator.Location + X*ProjSpawnOffset.X + Y*ProjSpawnOffset.Y + Z*ProjSpawnOffset.Z;
}

DefaultProperties
{
    ProjPerFire=2
    ProjSpawnOffset=(X=128.000000)
    bInstantHit=False
    NoAmmoSound=ProceduralSound'WeaponSounds.PReload5.P1Reload5'
    WarnTargetPct=0.500000
    bModeExclusive=true
}
