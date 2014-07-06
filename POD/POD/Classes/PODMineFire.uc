// ============================================================================
//  PODMineFire.uc ::
// ============================================================================
class PODMineFire extends PODProjectileFire;



simulated function bool AllowFire()
{
    if (PODMineGun(Weapon).CurrentGrenades >= PODMineGun(Weapon).MaxGrenades)
        return false;

    return Super.AllowFire();
}

function Projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local PODMineProjectile G;

    G = PODMineProjectile(Super.SpawnProjectile(Start, Dir));
    if (G != None && PODMineGun(Weapon) != None)
    {
        G.SetOwner(Weapon);
        PODMineGun(Weapon).Grenades[PODMineGun(Weapon).Grenades.length] = G;
        PODMineGun(Weapon).CurrentGrenades++;
    }

    return G;
}

defaultproperties
{


    AmmoClass=class'PODMineAmmo'
    AmmoPerFire=1

    FireAnim=Fire
    FireAnimRate=0.5
    FireEndAnim=None
    FireLoopAnim=None

    FlashEmitterClass=class'XEffects.AssaultMuzFlash1st'

    ProjectileClass=class'POD.PODMineProjectile'


    FireSound=Sound'NewWeaponSounds.NewGrenadeShoot'
    ReloadSound=Sound'WeaponSounds.BReload9'
    FireForce="AssaultRifleAltFire"
    ReloadForce="BReload9"

    PreFireTime=0.0
    FireRate=1.0
    MaxHoldTime=1
    bModeExclusive=true
    bFireOnRelease=true

    bSplashDamage=true
    bRecommendSplashDamage=true
    BotRefireRate=0.25
    bTossed=true

    ShakeOffsetMag=(X=-20.0,Y=0.00,Z=0.00)
    ShakeOffsetRate=(X=-1000.0,Y=0.0,Z=0.0)
    ShakeOffsetTime=2
    ShakeRotMag=(X=0.0,Y=0.0,Z=0.0)
    ShakeRotRate=(X=0.0,Y=0.0,Z=0.0)
    ShakeRotTime=2
}
