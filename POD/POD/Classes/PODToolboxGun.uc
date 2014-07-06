// ============================================================================
//  PODToolboxGun.uc ::
// ============================================================================
class PODToolboxGun extends PODWeapon
    abstract
    HideDropDown
    CacheExempt;

var Actor TargetActor;
var vector TargetHitLocation;

var() int SelectedBlueprint;
var() array< class<PODBlueprint> > Blueprints;

// ============================================================================
//  Replication
// ============================================================================
replication
{
    reliable if ( bNetDirty && Role == ROLE_Authority )
        TargetActor, TargetHitLocation;
}

function AttachToPawn(Pawn P)
{
    Instigator = P;

    if( AttachmentClass != None )
        Super.AttachToPawn(P);
}

function SetTarget( Actor T, optional vector L )
{
    if( T != TargetActor )
    {
        NewTarget(T);
    }
    TargetActor = T;
    TargetHitLocation = L;
}


function NewTarget( Actor Other )
{
    if( Other == None )
        return;

    if( PODSpore(Other) != None )
    {
        if( PODSpore(Other).DefenderTeamIndex != Instigator.GetTeamNum() )
            Instigator.ReceiveLocalizedMessage( MessageClass, class'PODUtil'.static.PackInt2(1,0),,,Other);
    }
}

function ChangeMode()
{
    if( PODBuildSpot(TargetActor) != None )
    {
        if( ++SelectedBlueprint >= Blueprints.Length )
            SelectedBlueprint = 0;
    }

    NewTarget(TargetActor);
}

function class<PODBlueprint> GetBlueprint()
{
    return Blueprints[SelectedBlueprint];
}

function class<PODBlueprint> GetNextBlueprint()
{
    if( SelectedBlueprint != Blueprints.Length - 1 )
        return Blueprints[SelectedBlueprint+1];
    return Blueprints[0];
}

function byte GetBlueprintIndex()
{
    return class'PODBlueprintList'.static.GetIndex(GetBlueprint());
}

function byte GetNextBlueprintIndex()
{
    return class'PODBlueprintList'.static.GetIndex(GetNextBlueprint());
}




// return false if out of range, can't see target, etc.
function bool CanAttack(Actor Other)
{
    local float Dist;

    if( Instigator == None || Instigator.Controller == None )
        return false;

    // do actor-specific checks
    if( !CanAttackTarget(Other) )
        return false;

    // check that target is within range
    Dist = VSize(Instigator.Location - Other.Location);
    if( Dist > FireMode[0].MaxRange() )
        return false;

    // check that can see target
    if( !Instigator.Controller.LineOfSightTo(Other) )
        return false;

    return true;
}

function bool CanHeal(Actor Other)
{
    local float Dist;

    if( Instigator == None || Instigator.Controller == None )
        return false;

    // do actor-specific checks
    if( !CanHealTarget(Other) )
        return false;

    // check that target is within range
    Dist = VSize(Instigator.Location - Other.Location);
    if( Dist > FireMode[0].MaxRange() )
        return false;

    // check that can see target
    if( !Instigator.Controller.LineOfSightTo(Other) )
        return false;

    return true;
}


function bool CanAttackTarget(Actor Other)
{
    if( PODSpore(Other) != None
    &&  PODSpore(Other).BetterObjectiveThan(None,Instigator.GetTeamNum(),0) )
        return true;
    return false;
}

function bool CanHealTarget(Actor Other)
{
    return false;
}

function float GetAIRating()
{
    local PODBot B;
    local Actor O;

    B = PODBot(Instigator.Controller);
    if( B != None )
    {
        O = B.Squad.SquadObjective;
        if( O == None )
            O = B.Target;

        //xLog( "GetAIRating" #GON(O) );
        if( O != None
        &&  VSize(B.Pawn.Location - O.Location) < FireMode[0].MaxRange()
        &&  PODToolboxFire(FireMode[0]).GetValidTarget(O) != None  )
        {
            return 100000;
        }
    }

    return AIRating * FMin(Pawn(Owner).DamageScaling, 1.5);
}

function bool BotFire(bool bFinished, optional name FiringMode)
{
    //xLog("BotFire" #bFinished #FiringMode);
    return Super.BotFire(bFinished,FiringMode);
}



simulated function float ChargeBar()
{
    if( GameObjective(TargetActor) != None )
        return GameObjective(TargetActor).GetObjectiveProgress();
    return 0;
}


// ============================================================================
//  AI
// ============================================================================

// tells bot whether to charge or back off while using this weapon
function float SuggestAttackStyle()
{
    return 10.0;
}

// tells bot whether to charge or back off while defending against this weapon
function float SuggestDefenseStyle()
{
    return 10.0;
}

function byte BestMode()
{
    return 0;
}

simulated function bool StartFire(int Mode)
{
    //xLog( "StartFire" );
    return Super.StartFire(Mode);
}


// ============================================================================
//  Energy
// ============================================================================
simulated function class<Ammunition> GetAmmoClass(int mode)
{
    return AmmoClass[mode];
}

simulated function MaxOutAmmo()
{
}

simulated function SuperMaxOutAmmo()
{
}

simulated function int MaxAmmo(int mode)
{
    if( PODKVehicle(Instigator) != None )
        return PODKVehicle(Instigator).EnergyMax;

    return 0;
}

simulated function FillToInitialAmmo()
{
}

simulated function int AmmoAmount(int mode)
{
    if( PODKVehicle(Instigator) != None )
        return PODKVehicle(Instigator).Energy;

    return 0;
}

simulated function class<Pickup> AmmoPickupClass(int mode)
{
    if ( AmmoClass[mode] != None )
        return FireMode[mode].AmmoClass.Default.PickupClass;

    return None;
}

simulated function bool AmmoMaxed(int mode)
{
    if( PODKVehicle(Instigator) != None )
        return PODKVehicle(Instigator).Energy == PODKVehicle(Instigator).EnergyMax;
    return false;
}

simulated function GetAmmoCount(out float MaxAmmoPrimary, out float CurAmmoPrimary)
{
    if( PODKVehicle(Instigator) != None )
    {
        MaxAmmoPrimary = PODKVehicle(Instigator).EnergyMax;
        CurAmmoPrimary = PODKVehicle(Instigator).Energy;
    }
}

simulated function float AmmoStatus(optional int Mode) // returns float value for ammo amount
{
    if( PODKVehicle(Instigator) != None )
        return PODKVehicle(Instigator).Energy / PODKVehicle(Instigator).EnergyMax;

    return 0;
}

simulated function bool ConsumeAmmo(int Mode, float load, optional bool bAmountNeededIsMax)
{
    if( PODKVehicle(Instigator) != None )
    {
        if( bAmountNeededIsMax )
        {
            PODKVehicle(Instigator).ConsumeEnergy(PODKVehicle(Instigator).EnergyMax);
        }
        else
        {
            if( load > PODKVehicle(Instigator).Energy )
                return false;
            PODKVehicle(Instigator).ConsumeEnergy(load);
        }
    }
    return true;
}

function bool AddAmmo(int AmmoToAdd, int Mode)
{
    if( PODKVehicle(Instigator) != None )
    {
        PODKVehicle(Instigator).Energy = Min(PODKVehicle(Instigator).Energy+AmmoToAdd,PODKVehicle(Instigator).EnergyMax);
    }
    return true;
}

simulated function bool HasAmmo()
{
    if( PODKVehicle(Instigator) != None )
        return PODKVehicle(Instigator).Energy > FireMode[0].AmmoPerFire;
    return false;
}

// for AI
simulated function bool NeedAmmo(int mode)
{
    return false;
}

simulated function float DesireAmmo(class<Inventory> NewAmmoClass, bool bDetour)
{
    return 0;
}

simulated function CheckOutOfAmmo()
{
}

simulated function PostNetReceive()
{
    CheckOutOfAmmo();
}

// ============================================================================
//  DefaultProperties
// ============================================================================
DefaultProperties
{
    MessageClass                    = class'POD.PODToolPackedMessage'
    Blueprints(0)                   = class'POD.PODBPTurret'
    Blueprints(1)                   = class'POD.PODBPAttractor'

    bCanThrow                       = False

    IconMaterial                    = Material'HudContent.Generic.HUD'
    IconCoords                      = (X1=0,Y1=0,X2=2,Y2=2)
    HudColor                        = (B=128,R=128)

    CustomCrosshair                 = 2
    CustomCrosshairTextureName      = "Crosshairs.Hud.Crosshair_Cross3"
    CustomCrosshairColor            = (r=0,g=0,b=255,a=255)
    CustomCrosshairScale            = 1.0

    AIRating                        = -1.0
    CurrentRating                   = -1.0

    Priority                        = -2
    InventoryGroup                  = 1

    DrawScale                       = 0.8
    PlayerViewOffset                = (X=28.5,Y=12,Z=-12)
    SmallViewOffset                 = (X=38,Y=16,Z=-16)
    PlayerViewPivot                 = (Pitch=1000,Roll=0,Yaw=400)
    CenteredOffsetY                 = 0
    CenteredRoll                    = 0

    DisplayFOV                      = 60.0
    BobDamping                      = 1.8

    EffectOffset                    = (X=100.0,Y=30.0,Z=-19.0)

    SelectSound                     = Sound'WeaponSounds.Translocator_change'
    SelectForce                     = "Translocator_change"

    IdleAnimRate                    = 0.25
    PutDownAnim                     = PutDown
    SelectAnim                      = Select

    Mesh                            = Mesh'NewWeapons2004.NewTransLauncher_1st'
    FireModeClass(0)                = Class'POD.PODToolboxFire'
    FireModeClass(1)                = Class'POD.PODToolboxFireAlt'
    PickupClass                     = Class'POD.PODToolboxPickup'
    AttachmentClass                 = None

    ItemName                        = "Toolbox"
    Description                     = "Toolbox"
}
