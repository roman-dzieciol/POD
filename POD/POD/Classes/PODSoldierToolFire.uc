// ============================================================================
//  PODSoldierToolFire.uc ::
// ============================================================================
class PODSoldierToolFire extends PODToolboxFire;

var() float SporeMult;


function bool HandleTarget( Actor Other, vector HitLocation, vector HitNormal )
{
    if( PODSpore(Other) != None )
    {
        Other.TakeDamage(Damage*SporeMult, Instigator, HitLocation, HitNormal, DamageType);
        return true;
    }
}

DefaultProperties
{
    SporeMult = 1.5

}
