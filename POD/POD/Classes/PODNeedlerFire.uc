// ============================================================================
//  PODNeedlerFire.uc ::
// ============================================================================
class PODNeedlerFire extends PODProjectileFire;


function Projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local Projectile p;

    p = PODNeedlerGun(Weapon).SpawnProjectile(Start, Dir);
    if ( p != None )
        p.Damage *= DamageAtten;
    return p;
}

DefaultProperties
{

    AmmoClass=class'PODNeedlerAmmo'
    AmmoPerFire=1

    ProjectileClass=class'POD.PODNeedlerProjectile'

    AimError                    = 850
    Spread                      = 400
    SpreadStyle                 = SS_Random

    FireSound=Sound'WeaponSounds.FlakCannon.FlakCannonFire'
    FireForce="FlakCannonFire"  // jdf

    FireRate=0.25

    BotRefireRate=0.7

    ShakeOffsetMag=(X=-20.0,Y=0.00,Z=0.00)
    ShakeOffsetRate=(X=-1000.0,Y=0.0,Z=0.0)
    ShakeOffsetTime=2
    ShakeRotMag=(X=0.0,Y=0.0,Z=0.0)
    ShakeRotRate=(X=0.0,Y=0.0,Z=0.0)
    ShakeRotTime=2
}
