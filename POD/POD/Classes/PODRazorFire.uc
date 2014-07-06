// ============================================================================
//  PODRazorFire.uc ::
// ============================================================================
class PODRazorFire extends PODProjectileFire;

var float MinHoldTime;                  // held for this time or less will do minimum damage/force. held for MaxHoldTime will do max
var float FullyChargedTime;

function float MaxRange()
{
    return ProjectileClass.default.MaxSpeed * ProjectileClass.default.LifeSpan;
}

function DoFireEffect()
{
    local float f;
    f = (FClamp(HoldTime, MinHoldTime, MaxHoldTime) - MinHoldTime) / (MaxHoldTime - MinHoldTime); // result 0 to 1
    DamageAtten = Lerp(f,0.25,1.0);
    Super.DoFireEffect();
}


DefaultProperties
{
    AmmoClass                   = class'PODRazorAmmo'
    AmmoPerFire                 = 1

    FireSound                   = Sound'WeaponSounds.BLightningGunFire'
    FireForce                   = "LightningGunFire"
    FireRate                    = 0.6
    bFireOnRelease              = True
    bInstantHit                 = True
    MaxHoldTime                 = 1.5
    MinHoldtime                 = 0.5
    TransientSoundVolume        = +1.0

    BotRefireRate               = 1.0
    WarnTargetPct               = +0.1

    AimError                    = 850
    Spread                      = 400
    SpreadStyle                 = SS_Random

    ProjectileClass             = class'POD.PODRazorProjectile'
}
