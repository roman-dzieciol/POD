// ============================================================================
//  PODSprayFireAlt.uc ::
// ============================================================================
class PODSprayFireAlt extends PODNoFire;


function PostBeginPlay()
{
    Super.PostBeginPlay();

}

simulated function bool AllowFire()
{
    return (PODSprayGun(Weapon).CurrentGrenades > 0);
}

function DoFireEffect()
{
    local int x;
    local PODSprayGun Gun;

    Gun = PODSprayGun(Weapon);

    for (x = 0; x < Gun.Grenades.Length; x++)
        if (Gun.Grenades[x] != None)
            Gun.Grenades[x].Explode(Gun.Grenades[x].Location, vect(0,0,1));

    Gun.Grenades.length = 0;
    Gun.CurrentGrenades = 0;
}

DefaultProperties
{

    FireRate=1.0
    BotRefireRate=0
}
