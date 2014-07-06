// ============================================================================
//  PODRazorGun.uc ::
// ============================================================================
class PODRazorGun extends PODWeapon;


function float GetAIRating()
{
    local Bot B;
    local float ZDiff, dist, Result;

    B = Bot(Instigator.Controller);
    if ( B == None )
        return AIRating;
    if ( B.IsShootingObjective() )
        return AIRating - 0.15;
    if ( B.Enemy == None )
    {
        if ( (B.Target != None) && VSize(B.Target.Location - B.Pawn.Location) > 8000 )
            return 0.95;
        return AIRating;
    }

    if ( B.Stopped() )
        result = AIRating + 0.1;
    else
        result = AIRating - 0.1;
    ZDiff = Instigator.Location.Z - B.Enemy.Location.Z;
    if ( ZDiff < -200 )
        result += 0.1;
    dist = VSize(B.Enemy.Location - Instigator.Location);
    if ( dist > 2000 )
    {
        if ( !B.EnemyVisible() )
            result = result - 0.15;
        return ( FMin(2.0,result + (dist - 2000) * 0.0002) );
    }
    if ( !B.EnemyVisible() )
        return AIRating - 0.1;

    return result;
}

function float SuggestAttackStyle()
{
    return -0.4;
}

function float SuggestDefenseStyle()
{
    return 0.2;
}

simulated function float ChargeBar()
{
    return FMin(1,FireMode[0].HoldTime/PODRazorFire(FireMode[0]).FullyChargedTime);
}

defaultproperties
{
    ItemName                        = "Razor"
    Description                     = ""

    FireModeClass(0)                = class'PODRazorFire'
    FireModeClass(1)                = class'PODRazorFire'

    InventoryGroup                  = 9
    Priority                        = 11

    SelectSound                     = Sound'WeaponSounds.LightningGun.SwitchToLightningGun'
    SelectForce                     = "SwitchToLightningGun"

    bSniping                        = true

    AIRating                        = 0.69
    CurrentRating                   = 0.69

    HudColor                        = (r=185,g=170,b=255,a=255)

    CustomCrosshair                 = 0
    CustomCrosshairTextureName      = "Crosshairs.Hud.Crosshair_Cross1"
    CustomCrosshairColor            = (r=185,g=170,b=255,a=255)

}
