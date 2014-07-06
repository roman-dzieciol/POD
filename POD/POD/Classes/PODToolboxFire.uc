// ============================================================================
//  PODToolboxFire.uc ::
// ============================================================================
class PODToolboxFire extends PODWeaponFire;

var() float TraceRange;
var() vector TraceExtent;
var   float UpTime;
var   bool bDoHit;

var() class<DamageType> DamageType;
var() int Damage;
var() class<Emitter> BeamClass;
var   Emitter Beam;



simulated function InitEffects()
{
    if( BeamClass != None )
        Beam = Weapon.Spawn(BeamClass);
    Super.InitEffects();
}

simulated function DestroyEffects()
{
    if( Beam != None )
        Beam.Destroy();

    Super.DestroyEffects();
}

function vector GetFireStart(vector X, vector Y, vector Z)
{
    return Instigator.Location;
}

function float MaxRange()
{
    return TraceRange;
}


function DoFireEffect()
{
    bDoHit = true;
    UpTime = FireRate+0.1;
}

function StopFiring()
{
    //xLog( "StopFiring" );
    //PODToolboxGun(Weapon).TargetActor = None;
}

event ModeDoFire()
{
    // don't use ammo here - it will be consumed in ModeTick() where it's sync'ed with damage dealing
    Load = 0;
    Super.ModeDoFire();
}

simulated event ModeTick(float DT)
{
    local PODToolboxGun Gun;
    local vector StartTrace, EndTrace, X, Y, Z;
    local vector HitLocation, HitNormal, TargetLocation;
    local Actor Other, A;
    local Actor Target, BotTarget;
    local Bot B;
    local rotator Aim;
    local float angle, bestangle;


    if( Instigator.Controller != None )
        B = Bot(Instigator.Controller);
    if( B != None )
        BotTarget = B.Target;

    Gun = PODToolboxGun(Weapon);
    Gun.GetViewAxes(X,Y,Z);

    Aim = AdjustAim(StartTrace, AimError);
    StartTrace = GetFireStart(X,Y,Z);

    if( BotTarget != None )
    {
        EndTrace = StartTrace + Normal(BotTarget.Location-Instigator.Location)*TraceRange;
    }
    else
    {
        EndTrace = StartTrace + vector(Aim) * TraceRange;
    }

    // Try trace
    Other = Instigator.Trace(HitLocation, HitNormal, EndTrace, StartTrace, True, TraceExtent);
    Target = GetValidTarget(Other);

    // Try iterator
    if( Target == None )
    {
        bestangle = 0.71;
        foreach Instigator.VisibleCollidingActors(class'Actor',A,TraceRange,StartTrace,false)
        {
            Other = GetValidTarget(A);
            if( Other != None )
            {
                angle = Normal(Other.Location - StartTrace) dot Normal(EndTrace - StartTrace);
                if( angle > bestangle )
                {
                    Target = Other;
                    bestangle = angle;
                }
            }
        }
    }

    if( Target != None )
        TargetLocation = Target.Location;

    Gun.SetTarget( Target, TargetLocation );

    if( UpTime > 0.0 || Instigator.Role < ROLE_Authority )
    {
        UpTime -= DT;
        //Gun.DrawDebugSphere( HitLocation, 16, 8, 255, 0, 0 );

        if( Target != None )
        {
            if( bDoHit )
            {
                Instigator.MakeNoise(1.0);
                if( HandleTarget(Target,HitLocation,HitNormal) )
                    Weapon.ConsumeAmmo( ThisModeNum, AmmoPerFire );
            }
        }
    }
    else
    {
        StopFiring();
    }

    //xLog( "ModeTick" #DT #bDoHit #GON(Other) #GON(PODToolboxGun(Weapon).TargetActor) );

    bDoHit = false;
}

function Actor GetValidTarget( Actor Other )
{
    if( Other == None
    ||  Other == Instigator
    ||  Other.bWorldGeometry )
        return None;

    if( DestroyableObjective(Other) == None
    &&  DestroyableObjective(Other.Owner) != None )
        Other = Other.Owner;

    if( Weapon.CanAttack(Other) || Weapon.CanHeal(Other) )
        return Other;

    return None;
}

function bool HandleTarget( Actor Other, vector HitLocation, vector HitNormal )
{
    if( PODSpore(Other) != None )
    {
        Other.TakeDamage(Damage, Instigator, HitLocation, HitNormal, DamageType);
        return true;
    }
}


// ============================================================================
//  DefaultProperties
// ============================================================================
DefaultProperties
{
    BeamClass           = class'POD.PODToolboxBeam'

    TraceRange          = 384
    TraceExtent         = (X=4,Y=4,Z=4)

    Damage              = 1
    DamageType          = class'POD.PODToolboxDamage'

    FireRate            = 0.1
    AmmoClass           = class'POD.PODAmmo'
    AmmoPerFire         = 1

    BotRefireRate       = 1.0

}
