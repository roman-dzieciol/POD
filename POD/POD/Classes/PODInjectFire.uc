// ============================================================================
//  PODInjectFire.uc ::
// ============================================================================
class PODInjectFire extends PODWeaponFire;


var class<DamageType> DamageType;
var int DamageMin, DamageMax;
var float TraceRange;
var float Momentum;

function float MaxRange()
{
    if (Instigator.Region.Zone.bDistanceFog)
        TraceRange = FClamp(Instigator.Region.Zone.DistanceFogEnd, 8000, default.TraceRange);
    else
        TraceRange = default.TraceRange;

    return TraceRange;
}


function DoTrace(Vector Start, Rotator Dir)
{
    local Vector X, End, HitLocation, HitNormal;
    local Actor Other;
    local int Damage;

    MaxRange();

    X = Vector(Dir);
    End = Start + TraceRange * X;

    Other = Instigator.Trace(HitLocation, HitNormal, End, Start, true);
    log(Other);

    if ( Other != None && Other != Instigator )
    {
        if ( !Other.bWorldGeometry )
        {
            Damage = DamageMin;
            if ( (DamageMin != DamageMax) && (FRand() > 0.5) )
                Damage += Rand(1 + DamageMax - DamageMin);
            Damage = Damage * DamageAtten;

            Other.TakeDamage(Damage, Instigator, HitLocation, Momentum*X, DamageType);
        }
    }
}


DefaultProperties
{
     TraceRange=256

     Momentum=1.000000
     NoAmmoSound=ProceduralSound'WeaponSounds.PReload5.P1Reload5'

    AmmoClass=class'PODInjectAmmo'
    AmmoPerFire=0


    DamageType=class'DamTypeShieldImpact'
    DamageMin=200.0
    DamageMax=200.0

    FireSound=Sound'WeaponSounds.P1ShieldGunFire'
    // jdf ---
    FireForce="ShieldGunFire"
    // --- jdf
    FireRate=0.6
    bModeExclusive=true
    FlashEmitterClass=class'xEffects.ForceRingA'
    TransientSoundVolume=+1.0

    BotRefireRate=1.0
    WarnTargetPct=+0.1

    ShakeOffsetMag=(X=-20.0,Y=0.00,Z=0.00)
    ShakeOffsetRate=(X=-1000.0,Y=0.0,Z=0.0)
    ShakeOffsetTime=2
    ShakeRotMag=(X=0.0,Y=0.0,Z=0.0)
    ShakeRotRate=(X=0.0,Y=0.0,Z=0.0)
    ShakeRotTime=2
}
