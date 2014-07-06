// ============================================================================
//  PODToolboxFireAlt.uc ::
// ============================================================================
class PODToolboxFireAlt extends PODWeaponFire;

function DoFireEffect()
{
    PODToolboxGun(Weapon).ChangeMode();
}



DefaultProperties
{
    FireRate            = 0.02
    bWaitForRelease     = True
    AmmoPerFire         = 0
}
