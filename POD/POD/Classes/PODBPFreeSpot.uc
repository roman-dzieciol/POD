// ============================================================================
//  PODBPFreeSpot.uc ::
// ============================================================================
class PODBPFreeSpot extends PODBlueprint
    HideDropDown;



DefaultProperties
{
    ItemName="Free Spot"
    ItemClass=class'PODBuildSpotEmitter'
    EmitterMesh=StaticMesh'AS_Decos.HellBenderEngine'
    EmitterOffset=(Z=-64)
    ItemOffset=(Z=-64)

}
