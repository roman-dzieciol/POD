// ============================================================================
//  PODEngineerToolGun.uc ::
// ============================================================================
class PODEngineerToolGun extends PODToolboxGun;

function bool CanAttackTarget(Actor Other)
{
    if( Super.CanAttackTarget(Other) )
        return true;

    if( PODBuildspot(Other) != None
    &&  PODBuildspot(Other).BetterObjectiveThan(PODBuildspot(Other),Instigator.GetTeamNum(),0) )
        return true;
    return false;
}

function NewTarget( Actor Other )
{
    local int b1,b2,v;
    Super.NewTarget(Other);

    if( PODBuildSpot(Other) != None )
    {
        if( PODBuildSpot(Other).DefenderTeamIndex == Instigator.GetTeamNum() )
        {
            b1 = GetBlueprintIndex();
            b2 = GetNextBlueprintIndex();
            if( PODBuildSpot(Other).IsBlueprintValid(GetBlueprint()) )
            {
                v = class'PODUtil'.static.PackInt4(2,b1,1,b2);
                Instigator.ReceiveLocalizedMessage( MessageClass, v );
            }
            else
            {
                v = class'PODUtil'.static.PackInt4(4,b1,1,b2);
                Instigator.ReceiveLocalizedMessage( MessageClass, v );
            }
        }
    }
}


DefaultProperties
{
    FireModeClass(0)                = Class'POD.PODEngineerToolFire'

    ItemName                        = "Engineer Tool"
    Description                     = "Engineer Tool"
}
