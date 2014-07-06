// ============================================================================
//  PODSprayFire.uc ::
// ============================================================================
class PODSprayFire extends PODProjectileFire;



#exec OBJ LOAD FILE=..\Sounds\NewWeaponSounds.uax



simulated function bool AllowFire()
{
    if (PODSprayGun(Weapon).CurrentGrenades >= PODSprayGun(Weapon).MaxGrenades)
        return false;

    return Super.AllowFire();
}

function Projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local PODSprayProjectile g;
    local float f;

    g = PODSprayProjectile(Weapon.Spawn(ProjectileClass, instigator,, Start, Dir));
    if (g != None)
    {
        f = Lerp(HoldTime/MaxHoldTime,ProjectileClass.default.Speed,ProjectileClass.default.MaxSpeed,True);
        g.Speed = f;
        g.Velocity = g.Speed * Vector(Dir);
        g.Damage *= DamageAtten;
        G.SetOwner(Weapon);
        PODSprayGun(Weapon).Grenades[PODSprayGun(Weapon).Grenades.length] = G;
        PODSprayGun(Weapon).CurrentGrenades++;
    }
    return g;
}


defaultproperties
{
    ProjPerFire = 1;

    AmmoClass=class'PODSprayAmmo'
    AmmoPerFire=1

    FireAnim=Fire
    FireAnimRate=0.5
    FireEndAnim=None
    FireLoopAnim=None

    FlashEmitterClass=class'XEffects.AssaultMuzFlash1st'

    ProjectileClass=class'POD.PODSprayProjectile'

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
