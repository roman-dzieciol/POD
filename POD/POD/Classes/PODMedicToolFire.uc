// ============================================================================
//  PODMedicToolFire.uc ::
// ============================================================================
class PODMedicToolFire extends PODToolboxFire;

var() float SporeMult;
var() float HealMult;


function bool HandleTarget( Actor Other, vector HitLocation, vector HitNormal )
{
    if( PODSpore(Other) != None )
    {
        Other.TakeDamage(Damage*SporeMult, Instigator, HitLocation, HitNormal, DamageType);
        return true;
    }
    else if( PODKVehicle(Other) != None )
    {
        return Other.HealDamage(Damage*HealMult, Instigator.Controller, DamageType);
    }
}

DefaultProperties
{
    SporeMult=1.5
    HealMult=2

}
