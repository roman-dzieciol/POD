// ============================================================================
//  PODPawnSoldier.uc ::
// ============================================================================
class PODPawnSoldier extends PODKVehicle;


// offset: x=80, y=40

DefaultProperties
{
    CollisionHeight     = 80
    CollisionRadius     = 80
    Mesh              = Mesh'PODAN_DronesNano.soldier'
    AmbientSound        = Sound'AssaultSounds.SkShipEng01''

    TPCamDistance       = 256
    TPCamDistRange      = (Min=256,Max=768)

    Skins(0) = Texture'Engine.TerrainBad'

    GunOffset=(X=80,Y=40,Z=0)
}
