class PODEnergyPickup extends MiniHealthPack;

var int EnergyAmount;

//auto state Pickup
//{
//    function Touch( actor Other )
//    {
//        local PODKVehicle P;
//
//        if ( ValidTouch(Other) )
//        {
//            P = PODKVehicle(Other);
//            if ( P.GiveEnergy(self.EnergyAmount) )
//            {
//                AnnouncePickup(P);
//                self.Destroy();
//            }
//
//        }
//    }
//}

static function string GetLocalString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2
    )
{
    return Default.PickupMessage;
}

defaultproperties
{
     EnergyAmount=0
     PickupMessage="Energy Gain"
}
