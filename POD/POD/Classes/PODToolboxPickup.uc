// ============================================================================
//  PODToolboxPickup.uc ::
// ============================================================================
class PODToolboxPickup extends PODWeaponPickup;

DefaultProperties
{
    InventoryType=class'Translauncher'

    PickupMessage="You got the Toolbox."
    PickupSound=Sound'PickupSounds.SniperRiflePickup'
    PickupForce="SniperRiflePickup"  // jdf

    StaticMesh=StaticMesh'newweaponpickups.translocatorcenter'
    DrawType=DT_StaticMesh
    DrawScale=0.2
}
