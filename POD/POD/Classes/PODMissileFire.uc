// ============================================================================
//  PODMissileFire.uc ::
// ============================================================================
class PODMissileFire extends ONSAVRiLFire;


function Projectile SpawnProjectile(vector Start, rotator Dir)
{
    local Projectile P;
    local vector X,Y,Z;

    Weapon.GetViewAxes(X,Y,Z);

    P = Super.SpawnProjectile(Start + Y * 32, Dir);
    if (P != None)
        P.SetOwner(Weapon);

    P = Super.SpawnProjectile(Start - Y * 32, Dir);
    if (P != None)
        P.SetOwner(Weapon);

    return P;
}

DefaultProperties
{
    ProjectileClass=class'POD.PODMissileProjectile'

}
