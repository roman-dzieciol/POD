// ============================================================================
//  PODPawnMedic.uc ::
// ============================================================================
class PODPawnMedic extends PODKVehicle;


// offset: x=80, y=16

DefaultProperties
{
    CollisionHeight     = 70
    CollisionRadius     = 70
    Mesh              = Mesh'PODAN_DronesNano.medic'

    TPCamDistance       = 160
    TPCamDistRange      = (Min=160,Max=768)

    Skins(0) = Texture'Engine.DefaultTexture'

    GunOffset=(X=80,Y=16,Z=12)
}
