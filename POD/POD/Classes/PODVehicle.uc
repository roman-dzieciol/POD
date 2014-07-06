// ============================================================================
//  PODVehicle.uc ::
// ============================================================================
class PODVehicle extends ASVehicle_SpaceFighter;

var   VolumeTimer PawnTimer;
var() float PawnTimerFreq;

var() vector TPCamExtent;

var() byte Energy;
var() byte EnergyMax;
var() byte EnergyRegen;
var   float EnergyRegenTime;
var   float EnergyAccum;

var() byte HealthRegen;
var   float HealthRegenTime;
var   float HealthAccum;

var() byte Shield;
var() byte ShieldMax;
var() byte ShieldRegen;
var   float ShieldRegenTime;
var   float ShieldAccum;

var class<PODPlayerClass> PlayerClass;


// ============================================================================
//  Replication
// ============================================================================
replication
{
    reliable if ( bNetDirty && Role==ROLE_Authority )
        Energy, Shield;

    reliable if ( bNetDirty && Role==ROLE_Authority )
        EnergyMax, ShieldMax;
}

simulated event PostNetReceive()
{
    if( GetPlayerClass() != None  )
    {
        SetupPlayerClass();
        bNetNotify = false;
    }
}

simulated function NotifyTeamChanged()
{
    // my PRI now has a new team
    PostNetReceive();
}


// ============================================================================
//  Lifespan
// ============================================================================
simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    if( Level.bStartup )
        AddDefaultInventory();

    if( Role == ROLE_Authority )
    {
        PawnTimer = Spawn(class'VolumeTimer',self);
        PawnTimer.TimerFrequency = PawnTimerFreq;
    }
}

simulated event Destroyed()
{
    if( PawnTimer != None )
        PawnTimer.Destroy();

    Super.Destroyed();
}

function TimerPop( VolumeTimer T )
{
    if( T == PawnTimer )
    {
        if( EnergyRegen > 0 )
        {
            if( Energy < EnergyMax && EnergyRegenTime < Level.TimeSeconds )
            {
                EnergyAccum += float(EnergyRegen) * PawnTimerFreq;
                if( EnergyAccum > 1 )
                {
                    Energy = Min( Energy + int(EnergyAccum), EnergyMax );
                    EnergyAccum -= int(EnergyAccum);
                }
            }
            else
                EnergyAccum = 0;
        }

        if( HealthRegen > 0 )
        {
            if( Health < HealthMax && HealthRegenTime < Level.TimeSeconds )
            {
                HealthAccum += float(HealthRegen) * PawnTimerFreq;
                if( HealthAccum > 1 )
                {
                    Health = Min( Health + int(HealthAccum), HealthMax );
                    HealthAccum -= int(HealthAccum);
                }
            }
            else
                HealthAccum = 0;
        }

        if( ShieldRegen > 0 )
        {
            if( Shield < ShieldMax && ShieldRegenTime < Level.TimeSeconds )
            {
                ShieldAccum += float(ShieldRegen) * PawnTimerFreq;
                if( ShieldAccum > 1 )
                {
                    Shield = Min( Shield + int(ShieldAccum), ShieldMax );
                    ShieldAccum -= int(ShieldAccum);
                }
            }
            else
                ShieldAccum = 0;
        }
    }
}

// ============================================================================
//  Energy
// ============================================================================
function ConsumeEnergy( int Amount )
{
    if( Amount < Energy )
        Energy -= Amount;
    else
        Energy = 0;

    if( EnergyRegen > 0 )
        EnergyRegenTime = Level.TimeSeconds + default.EnergyRegenTime;
}


// ============================================================================
//  Controller
// ============================================================================
function PossessedBy(Controller C)
{
    Super(Vehicle).PossessedBy( C );

    NetUpdateTime = Level.TimeSeconds - 1;
    bStasis = false;
    C.Pawn  = Self;
    AddDefaultInventory();

    // Don't start at full speed
    Velocity = EngineMinVelocity * Vector(Rotation);
    Acceleration = Velocity;
}

// ============================================================================
//  Damage
// ============================================================================
function bool HealDamage(int Amount, Controller Healer, class<DamageType> DamageType)
{
    //xLog( "HealDamage" );
    if( Health <= 0 || Health >= HealthMax || Amount <= 0 || Healer == None || GetTeamNum() != Healer.GetTeamNum() )
        return false;

    Health = Min(Health + Amount, HealthMax);
    NetUpdateTime = Level.TimeSeconds - 1;
    return true;
}

function int ShieldAbsorb( int damage )
{
    if( Shield > 0 )
    {
        //SetOverlayMaterial( ShieldHitMat, ShieldHitMatTime, false );
        //PlaySound(sound'WeaponSounds.ArmorHit', SLOT_Pain,2*TransientSoundVolume,,400);
    }

    if( damage > Shield )
    {
        damage -= Shield;
        Shield = 0;
    }
    else
    {
        Shield -= damage;
        damage = 0;
    }

    if( ShieldRegen > 0 )
        ShieldRegenTime = Level.TimeSeconds + default.ShieldRegenTime;

    return damage;
}


// ============================================================================
//  Collision
// ============================================================================
simulated function VehicleCollision(Vector HitNormal, Actor Other)
{
    //Log(Other);
    if( Vehicle(Other) != None )
    {
        //Velocity += Other.Velocity * 1.1;
        //Other.Velocity += Velocity * 10.0;
        //Velocity = Velocity * -2;
    }
}

function Vehicle GetVehicleBase()
{
    // infinite recursion bug?
    return None;//Vehicle(Base);
}

// ============================================================================
//  Player Class
// ============================================================================
function PlayerChangedClass()
{
    Died( None, class'DamageType', Location );
}

simulated function class<PODPlayerClass> GetPlayerClass()
{
    local PODPRI PRI;

    PRI = PODPRI(PlayerReplicationInfo);
    if( PRI != None )
        return PRI.GetPlayerClass();

    return None;
}

simulated function SetupPlayerClass()
{
    local class<PODPlayerClass> C;

    C = GetPlayerClass();

    //xLog( "SetupPlayerClass()" #GON(C) );
    if( C != None )
    {
        PlayerClass = C;

        if( Role == ROLE_Authority )
        {
            Health = C.default.Health * default.Health;
            HealthMax = C.default.HealthMax * default.HealthMax;
            HealthRegen = C.default.HealthRegen * default.HealthRegen;

            Shield = C.default.Shield * default.Shield;
            ShieldMax = C.default.ShieldMax * default.ShieldMax;
            ShieldRegen = C.default.ShieldRegen * default.ShieldRegen;

            Energy = C.default.Energy * default.Energy;
            EnergyMax = C.default.EnergyMax * default.EnergyMax;
            EnergyRegen = C.default.EnergyRegen * default.EnergyRegen;
        }
    }
}


// ============================================================================
//  Inventory
// ============================================================================

function bool TooCloseToAttack(Actor Other)
{
    if( Other == None )
        return false;

    return VSize(Other.Location-Location) < 1024;
}

function name GetWeaponBoneFor(Inventory I)
{
    // Hide 3rd person attachments
    if( I.ThirdPersonActor != None )
    {
        I.ThirdPersonActor.bHidden = True;
    }
    return '';
}

simulated function NextWeapon()
{
    Super(Pawn).NextWeapon();
}

simulated function PrevWeapon()
{
    Super(Pawn).PrevWeapon();
}

function AddDefaultInventory()
{
    local class<PODPlayerClass> PC;
    local array<string> Equipment;
    local int i;

    PC = GetPlayerClass();
    if( PC != None )
    {
        Equipment = PC.default.Equipment;
        for( i=0; i!=Equipment.Length; ++i )
        {
            CreateInventory(Equipment[i]);
        }
    }

    Level.Game.AddGameSpecificInventory(self);

    Controller.ClientSwitchToBestWeapon();
}

function CreateInventory(string InventoryClassName)
{
    local Inventory Inv;
    local class<Inventory> InventoryClass;

    InventoryClass = Level.Game.BaseMutator.GetInventoryClass(InventoryClassName);
    if( (InventoryClass!=None) && (FindInventoryType(InventoryClass)==None) )
    {
        Inv = Spawn(InventoryClass);
        if( Inv != None )
        {
            Inv.GiveTo(self);
            if ( Inv != None )
                Inv.PickupFunction(self);
        }
    }
}

// ============================================================================
//  Camera
// ============================================================================

simulated function rotator GetViewRotation()
{
    if ( IsLocallyControlled() && IsHumanControlled() && Health > 0 )
        return QuatToRotator(SpaceFighterRotation); // true rotation
    else
        return Rotation;
}

simulated function bool SpecialCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation )
{
    return Super(Vehicle).SpecialCalcView(ViewActor, CameraLocation, CameraRotation );
}

function bool SpectatorSpecialCalcView(PlayerController Viewer, out Actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
    return Super(Vehicle).SpectatorSpecialCalcView(Viewer, ViewActor, CameraLocation, CameraRotation );
}

simulated function SpecialCalcFirstPersonView(PlayerController PC, out actor ViewActor, out vector CameraLocation, out rotator CameraRotation )
{
    local vector    x, y, z;
    local rotator   R;

    CameraLocation = Location;
    ViewActor   = Self;
    R           = GetViewRotation();
    GetAxes(R, x, y, z);

    // First-person view.
    CameraRotation = Normalize(R + PC.ShakeRot); // amb
    CameraLocation = CameraLocation +
                     PC.ShakeOffset.X * x +
                     PC.ShakeOffset.Y * y +
                     PC.ShakeOffset.Z * z;

    // Camera position is locked to vehicle
    CameraLocation = CameraLocation + (FPCamPos >> GetViewRotation());
}

// Vehicle.SpecialCalcBehindView() with variable Extent and Pawn's rotation
simulated function SpecialCalcBehindView(PlayerController PC, out actor ViewActor, out vector CameraLocation, out rotator CameraRotation )
{
    local vector CamLookAt, HitLocation, HitNormal, OffsetVector;
    local Actor HitActor;
    local vector x, y, z;

    //xLog("SpecialCalcBehindView");

    if (DesiredTPCamDistance < TPCamDistance)
        TPCamDistance = FMax(DesiredTPCamDistance, TPCamDistance - CameraSpeed * (Level.TimeSeconds - LastCameraCalcTime));
    else if (DesiredTPCamDistance > TPCamDistance)
        TPCamDistance = FMin(DesiredTPCamDistance, TPCamDistance + CameraSpeed * (Level.TimeSeconds - LastCameraCalcTime));

    GetAxes(PC.Rotation, x, y, z);
    ViewActor = self;
    CamLookAt = GetCameraLocationStart() + (TPCamLookat >> Rotation) + TPCamWorldOffset;

    OffsetVector = vect(0, 0, 0);
    OffsetVector.X = -1.0 * TPCamDistance;

    CameraLocation = CamLookAt + (OffsetVector >> /*PC.*/Rotation);

    HitActor = Trace(HitLocation, HitNormal, CameraLocation, CamLookAt, true, TPCamExtent);
    if ( HitActor != None
         && (HitActor.bWorldGeometry || HitActor == GetVehicleBase() || Trace(HitLocation, HitNormal, CameraLocation, CamLookAt, false, TPCamExtent) != None) )
            CameraLocation = HitLocation;

    CameraRotation = Normalize(/*PC.*/Rotation + PC.ShakeRot);
    CameraLocation = CameraLocation + PC.ShakeOffset.X * x + PC.ShakeOffset.Y * y + PC.ShakeOffset.Z * z;
}


// ============================================================================
//  AI
// ============================================================================
//function bool NeedToTurn(vector targ)
//{
//    return false;
//}

// ============================================================================
//  Movement
// ============================================================================
function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
{
    if ( Role == Role_Authority )
    {
        if ( !bPostNetCalled )
            return;

        UpdateAutoTargetting();
    }
}

simulated function UpdateRocketAcceleration(float DeltaTime, float YawChange, float PitchChange)
{
    local vector    X,Y,Z;
    local float     RotationSmoothFactor;
    local float     RollChange;
    local Rotator   NewRotation;

    //xLog( "UpdateRocketAcceleration" );

    if ( !bPostNetCalled || Controller == None )
        return;

    if ( !bInitialized  )
    {
        // Laurent -- Velocity Override
        // When Player Spawns with the spaceship as Pawn, velocity is reset at start match
        // since Rotation is overwritten later by Rotator(Velocity), it gets reset to Rotation(0,0,0)
        // And therefore not using the one set in PlayerStart.Rotation
        Acceleration = EngineMinVelocity * Vector(Rotation);
        SpaceFighterRotation = QuatFromRotator( Rotation );
        bInitialized = true;
    }

    DesiredVelocity = FClamp( DesiredVelocity+PlayerController(Controller).aForward*DeltaTime/15.f, EngineMinVelocity, AirSpeed);

    //CurrentSpeed    = FClamp( (Velocity Dot Vector(Rotation)) * 1000.f / AirSpeed, 0.f, 1000.f);
    //EngineAccel     = (DesiredVelocity - CurrentSpeed) * 100.f;

    RotationSmoothFactor = FClamp(1.f - RotationInertia * DeltaTime, 0.f, 1.f);

    if ( PlayerController(Controller).bDuck > 0 && Abs(Rotation.Roll) > 500 )
    {
        // Auto Correct Roll
        if ( Rotation.Roll < 0 )
            RollChange = RollAutoCorrectSpeed;
        else
            RollChange = -RollAutoCorrectSpeed;
    }
    else if ( PlayerController(Controller).aUp > 0 ) // Rolling
        RollChange = PlayerController(Controller).aStrafe * 0.66;

    // Rotation Acceleration
    YawAccel    = RotationSmoothFactor*YawAccel   + DeltaTime*VehicleRotationSpeed*YawChange;
    PitchAccel  = RotationSmoothFactor*PitchAccel + DeltaTime*VehicleRotationSpeed*PitchChange;
    RollAccel   = RotationSmoothFactor*RollAccel  + DeltaTime*VehicleRotationSpeed*RollChange;

    YawAccel    = FClamp( YawAccel, -AirSpeed, AirSpeed );
    PitchAccel  = FClamp( PitchAccel, -AirSpeed, AirSpeed );
    RollAccel   = FClamp( RollAccel, -AirSpeed, AirSpeed );

    // Perform new rotation
    GetAxes( QuatToRotator(SpaceFighterRotation), X, Y, Z );
    SpaceFighterRotation = QuatProduct(SpaceFighterRotation,
                                QuatProduct(QuatFromAxisAndAngle(Y, DeltaTime*PitchAccel),
                                QuatProduct(QuatFromAxisAndAngle(Z, -1.0 * DeltaTime * YawAccel),
                                QuatFromAxisAndAngle(X, DeltaTime * RollAccel))));

    NewRotation = QuatToRotator( SpaceFighterRotation );

    // If autoadjusting roll, clamp to 0
    if ( PlayerController(Controller).bDuck > 0 && ((NewRotation.Roll < 0 && Rotation.Roll > 0) || (NewRotation.Roll > 0 && Rotation.Roll < 0)) )
    {
        NewRotation.Roll = 0;
        RollAccel = 0;
    }

    Acceleration = Vector(NewRotation) * DesiredVelocity;

    // strafing
    StrafeAccel = RotationSmoothFactor*StrafeAccel;
    if ( PlayerController(Controller).aUp == 0 )
        StrafeAccel += DeltaTime*StrafeAccelRate*PlayerController(Controller).aStrafe;
    StrafeAccel = FClamp( StrafeAccel, -MaxStrafe, MaxStrafe);
    GetAxes( NewRotation, X, Y, Z );
    Acceleration += StrafeAccel * Y;

    // Adjust Rolling based on Stafing
    NewRotation.Roll += StrafeAccel * 15;
    DelayedDebugString = "NewRotation.Roll:" @ NewRotation.Roll @ "StrafeAccel:" @ StrafeAccel;

    // Take complete control on Rotation
    bRotateToDesired    = true;
    bRollToDesired      = true;
    DesiredRotation     = NewRotation;
    SetRotation( NewRotation );
}

// ============================================================================
//  FX
// ============================================================================

simulated function SetTrailFX()
{
    // Trail FX
    if ( TrailEmitter==None && Health>0 && Team != 255  )
    {
        TrailEmitter = Spawn(class'FX_SpaceFighter_Trail_Red', Self,, Location - Vector(Rotation)*TrailOffset, Rotation);

        if ( TrailEmitter != None )
        {
            if ( Team == 1 )    // Blue version
                FX_SpaceFighter_Trail_Red(TrailEmitter).SetBlueColor();

            TrailEmitter.SetBase( Self );
        }
    }
}

simulated function AdjustFX()
{
    local float         NewSpeed, VehicleSpeed, SpeedPct;
    local int           i, averageOver;

    // Check that Trail is here
    SetTrailFX();

    // Smooth filter on velocity, which is very instable especially on Jerky frame rate.
    NewSpeed = Max(Velocity Dot Vector(Rotation), EngineMinVelocity);
    SpeedFilter[NextSpeedFilterSlot] = NewSpeed;
    NextSpeedFilterSlot++;

    if ( bSpeedFilterWarmup )
        averageOver = NextSpeedFilterSlot;
    else
        averageOver = SpeedFilterFrames;

    for (i=0; i<averageOver; i++)
        VehicleSpeed += SpeedFilter[i];

    VehicleSpeed /= float(averageOver);

    if ( NextSpeedFilterSlot == SpeedFilterFrames )
    {
        NextSpeedFilterSlot = 0;
        bSpeedFilterWarmup  = false;
    }

    SmoothedSpeedRatio = VehicleSpeed / AirSpeed;
    SpeedPct = VehicleSpeed - EngineMinVelocity*AirSpeed/1000.f;
    SpeedPct = FClamp( SpeedPct / (AirSpeed*( (1000.f-EngineMinVelocity)/1000.f )), 0.f, 1.f );

    // Adjust Engine FX depending on velocity
    if ( TrailEmitter != None )
        AdjustEngineFX( SpeedPct );

    // Animate SpaceFighter depending on velocity
    //if ( bGearUp )
    //    AnimateSkelMesh( SpeedPct );

    UpdateEngineSound( SpeedPct );

    // Adjust FOV depending on speed
    if ( PlayerController(Controller) != None && IsLocallyControlled() )
        PlayerController(Controller).SetFOV( PlayerController(Controller).DefaultFOV + SpeedPct*SpeedPct*15  );
}

simulated function UpdateEngineSound( float SpeedPct )
{
    // Adjust Engine volume
    SoundVolume = 160 +  32 * SpeedPct;
    SoundPitch  =  64 +  16 * SpeedPct;
}

simulated function AdjustEngineFX( float SpeedPct )
{
    local SpriteEmitter E1, E2;

    E1 = SpriteEmitter(TrailEmitter.Emitters[1]);
    E2 = SpriteEmitter(TrailEmitter.Emitters[2]);

    // Thruster
    E1.SizeScale[1].RelativeSize = 2.00 + 1.0*SpeedPct;
    E1.SizeScale[2].RelativeSize = 2.00 + 1.5*SpeedPct;
    E1.SizeScale[3].RelativeSize = 2.00 + 1.0*SpeedPct;
    E1.Opacity = 1 - SpeedPct * 0.5;

    E2.Opacity = 0.5 + SpeedPct * 0.25;
    E2.StartSizeRange.X.Min = 40 + 10 * SpeedPct;
    E2.StartSizeRange.X.Max = 50 + 25 * SpeedPct;
}

// ============================================================================
//  STATES
// ============================================================================
state Dying
{
ignores Trigger, Bump, HitWall, HeadVolumeChange, PhysicsVolumeChange, Falling, BreathTimer;
    function TimerPop( VolumeTimer T ){}
}



// ============================================================================
//  Debug
// ============================================================================
final simulated function xLog ( coerce string s )
{
    Log
    (   "[" $Left("00",2-Len(Level.Second)) $Level.Second $":"
            $Left("000",3-Len(Level.Millisecond)) $Level.Millisecond $"]"
    @   "[" $StrShort(GetStateName()) $"]"
    @   s
    ,   name );
}

final static function string StrShort( coerce string s )
{
    local string r,c;
    local int i,n;

    c = Caps(s);
    n = Len(s);

    for( i=0; i!=n; ++i )
        if( Mid(s,i,1) == Mid(c,i,1) )
            r $= Mid(s,i,1);

    return r;
}

final static operator(112) string # ( coerce string A, coerce string B )
{
    return A @"[" $B $"]";
}

final static function name GON( Object O )
{
    if( O != None ) return O.Name;
    else            return 'None';
}

final simulated function string GPT( string S )
{
    return GetPropertyText(S);
}


// ============================================================================
//  DefaultProperties
// ============================================================================
DefaultProperties
{
    PawnTimerFreq               = 0.25

    Energy                      = 100
    EnergyMax                   = 100
    EnergyRegen                 = 10
    EnergyRegenTime             = 1

    Shield                      = 100
    ShieldMax                   = 100
    ShieldRegen                 = 1
    ShieldRegenTime             = 1

    HealthRegen                 = 1
    HealthRegenTime             = 1

    bFlyingKarma                = False
    bCanFly                     = True
    bCanStrafe                  = True
    bTurnInPlace                = True
    bCanHover                   = True

    bFollowLookDir              = False

    bJumpCapable                = False
    bCanJump                    = False
    bCanWalk                    = False
    bCanDoubleJump              = False
    bSimulateGravity            = False
    bCanUse                     = False

    bSpecialHUD                 = False
    bSpecialCrosshair           = False

    bNetNotify                  = True

    Health                      = 100
    HealthMax                   = 100

    RotationInertia             = 10.0
    EngineMinVelocity           = -768
    bGearUp                     = true

    DesiredSpeed                = 1
    MaxDesiredSpeed             = 1

    HearingThreshold            = 2800.000000
    SightRadius                 = 5000.000000

    GroundSpeed                 = 768
    WaterSpeed                  = 768
    AirSpeed                    = 768
    LadderSpeed                 = 768
    AccelRate                   = 768
    JumpZ                       = 0
    AirControl                  = 1
    WalkingPct                  = 1
    CrouchedPct                 = 1
    MaxFallSpeed                = 1280
    MinFlySpeed                 = 0

    MinRunOverSpeed             = 50
    MaxRotation                 = 0

    bCustomHealthDisplay        = False
    DefaultWeaponClassName      = "POD.PODToolboxGun"

    AmbientSound                = Sound'AssaultSounds.HnSpaceShipEng01'
    SoundRadius                 = 100
    SoundVolume                 = 255

    TransientSoundVolume        = 1.0
    TransientSoundRadius        = 784.0
    VehiclePositionString       = "in a drone"
    VehicleNameString           = "Drone"

    DrawType                    = DT_Mesh
    DrawScale                   = 1.0
    AmbientGlow                 = 96
    bUnlit                      = false

    FPCamPos                    = (X=0,Y=0,Z=0)

    TPCamExtent                 = (X=4,Y=4,Z=4)
    TPCamDistance               = 192
    TPCamLookat                 = (X=0,Y=0,Z=96)
    TPCamDistRange              = (Min=192,Max=768)
    TPCamWorldOffset            = (X=0,Y=0,Z=0)

    RocketOffset                = (X=0,Y=0,Z=-20)
    TrailOffset                 = 67.0
    GenericShieldEffect[0]      = class'UT2K4AssaultFull.FX_SpaceFighter_Shield_Red'
    GenericShieldEffect[1]      = class'UT2K4AssaultFull.FX_SpaceFighter_Shield'

    VehicleProjSpawnOffset      = (X=35,Y=0,Z=-8)

}
