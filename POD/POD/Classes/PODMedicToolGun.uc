// ============================================================================
//  PODMedicToolGun.uc ::
// ============================================================================
class PODMedicToolGun extends PODToolboxGun;


function bool CanHealTarget(Actor Other)
{
    if( PODKVehicle(Other) != None
    &&  PODKVehicle(Other).GetTeamNum() == Instigator.GetTeamNum() )
        return true;
    return false;
}

function NewTarget( Actor Other )
{
    Super.NewTarget(Other);

    if( PODKVehicle(Other) != None )
    {
        if( PODKVehicle(Other).GetTeamNum() == Instigator.GetTeamNum() )
            Instigator.ReceiveLocalizedMessage( MessageClass, class'PODUtil'.static.PackInt2(3,0),,,Other);
    }
}


DefaultProperties
{
    FireModeClass(0)                = Class'POD.PODMedicToolFire'

    ItemName                        = "Medic Tool"
    Description                     = "Medic Tool"

}
