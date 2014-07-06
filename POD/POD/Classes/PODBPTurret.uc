// ============================================================================
//  PODBPTurret.uc ::
// ============================================================================
class PODBPTurret extends PODBlueprint;



DefaultProperties
{
    ItemName="Turret"
    ItemClass=class'POD.PODSentinel'
    EmitterMesh=StaticMesh'AS_Weapons_SM.Turret.FloorTurretStaticEditor'
    EmitterScale=0.5
    EmitterOffset=(Z=-144)
    ItemOffset=(Z=-64)
}
