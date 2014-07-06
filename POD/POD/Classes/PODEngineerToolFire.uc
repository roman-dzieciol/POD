// ============================================================================
//  PODEngineerToolFire.uc ::
// ============================================================================
class PODEngineerToolFire extends PODToolboxFire;

var() float SporeMult;
var() float BuildMult;

function bool HandleTarget( Actor Other, vector HitLocation, vector HitNormal )
{
    if( PODSpore(Other) != None )
    {
        Other.TakeDamage(Damage*SporeMult, Instigator, HitLocation, HitNormal, DamageType);
        return true;
    }
    else if( PODBuildSpot(Other) != None )
    {
        if( PODBuildSPot(Other).IsBlueprintValid( PODToolboxGun(Weapon).GetBlueprint()) )
        {
            PODBuildSPot(Other).SetBlueprint( PODToolboxGun(Weapon).GetBlueprint() );
            return Other.HealDamage(Damage*BuildMult, Instigator.Controller, DamageType);
        }
        else
        {
        }
    }
}

DefaultProperties
{
    SporeMult=2
    BuildMult=2
}
