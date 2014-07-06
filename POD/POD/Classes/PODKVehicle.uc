// ============================================================================
//  PODSVehicle.uc ::
// ============================================================================
//  TORQUE: +X=RollLeft +Y=PitchDown +Z=YawRight
// ============================================================================
class PODKVehicle extends SVehicle
    abstract;


// - Camera -------------------------------------------------------------------

var() vector TPCamExtent;


// - Stats --------------------------------------------------------------------

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

var() float RegenTimerFreq;
var   VolumeTimer RegenTimer;


// - Physics ------------------------------------------------------------------

var() float MaxThrustForce;
var() float MaxStrafeForce;
var() float MaxRiseForce;

var() float ThrustDamping;
var() float StrafeDamping;
var() float RiseDamping;

var() float LinearSpeed;
var() float AngularSpeed;

var   float OutputThrust;
var   float OutputStrafe;
var   float OutputRise;

var   vector LocalForce;
var   vector LocalTorque;
var   quat LocalQuat;


// - Safetime -----------------------------------------------------------------

var   bool bInitSafetime;
var   vector LastSafeLocation;
var   quat LastSafeQuat;


// - Physics replication ------------------------------------------------------

struct SVehicleState
{
    var KRBVec      Position;
    var Quat        Quaternion;
    var KRBVec      LinVel;
    var KRBVec      AngVel;

    var float       OutputThrust;
    var float       OutputStrafe;
    var float       OutputRise;

//    var int         ServerViewPitch;
//    var int         ServerViewYaw;
//    var int         ServerViewRoll;
};

var  SVehicleState NewVehicleState;
var  SVehicleState OldVehicleState;
var  bool bVehicleState;

// - Inventory ----------------------------------------------------------------

var vector GunOffset;


// ============================================================================
//  Replication
// ============================================================================
replication
{
    reliable if ( Role == ROLE_Authority )
        NewVehicleState;

    reliable if ( bNetDirty && Role == ROLE_Authority )
        Energy, Shield;

    reliable if ( bNetDirty && Role == ROLE_Authority )
        EnergyMax, ShieldMax;
}

simulated event PostNetReceive()
{
    local class<PODPlayerClass> C;

    C = GetPlayerClass();
    if( C != None )
    {
        SetupPlayerClass(C);
        bNetNotify = false;
    }
}

simulated event VehicleStateReceived()
{
    if( OldVehicleState == NewVehicleState )
        return;

    OldVehicleState = NewVehicleState;
    bVehicleState = true;
}


// ============================================================================
//  Lifespan
// ============================================================================
simulated event PostBeginPlay()
{
    // Update pawn props
    //SetupPlayerClass(default.ConfigClass);

    Super.PostBeginPlay();

    PODInitCollision();

    if( Role == ROLE_Authority )
    {
        RegenTimer = Spawn(class'VolumeTimer',self);
        RegenTimer.TimerFrequency = RegenTimerFreq;
    }
    else
    {
        //bSmoothKarmaStateUpdates = True;
    }
}

simulated event Destroyed()
{
    if( RegenTimer != None )
        RegenTimer.Destroy();

    Super.Destroyed();
}

function TimerPop( VolumeTimer T )
{
    if( T == RegenTimer )
    {
        if( EnergyRegen > 0 )
        {
            if( Energy < EnergyMax && EnergyRegenTime < Level.TimeSeconds )
            {
                EnergyAccum += float(EnergyRegen) * RegenTimerFreq;
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
                HealthAccum += float(HealthRegen) * RegenTimerFreq;
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
                ShieldAccum += float(ShieldRegen) * RegenTimerFreq;
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

//event Tick( float DeltaTime )
//{
//    Super.Tick(DeltaTime);
//    xLog( "Tick" #KIsAwake() );
//}


// ============================================================================
//  Physics
// ============================================================================

simulated event SVehicleUpdateParams()
{
    local KarmaParamsRBFull KP;

    Super.SVehicleUpdateParams();

    KP = KarmaParamsRBFull(KParams);
    KP.KMaxSpeed = LinearSpeed;
}

simulated event bool KUpdateState(out KRigidBodyState RBState)
{
    // todo: remove strafing while rolling

    if( Role == ROLE_Authority )
    {
        if( Controller != None )
        {
            OutputThrust = Throttle;
            OutputStrafe = Steering;
            OutputRise = Rise;
            KWake();
        }

        PODPackState();

        KGetRigidBodyState(RBState);
        PODSafetime(RBState);
        RBState.Quaternion = LocalQuat;
        RBState.AngVel = KRBVecFromVector(vect(0,0,0));

        return true;
    }
    else
    {
        return PODUpdateClient(RBState);
    }

    return False;
}

function PODPackState()
{
    local KRigidBodyState RBState;
    local SVehicleState LocalState;

    KGetRigidBodyState(RBState);

    LocalState.Position = RBState.Position;
    LocalState.Quaternion = RBState.Quaternion;
    LocalState.LinVel = RBState.LinVel;
    LocalState.AngVel = RBState.AngVel;

    LocalState.OutputThrust = OutputThrust;
    LocalState.OutputStrafe = OutputStrafe;
    LocalState.OutputRise   = OutputRise;

    NewVehicleState = LocalState;
}

simulated function bool PODUpdateClient( out KRigidBodyState RBState )
{
    local KRigidBodyState LocalState;

    if( bVehicleState )
    {
        LocalState.Position = NewVehicleState.Position;
        LocalState.Quaternion = NewVehicleState.Quaternion;
        LocalState.LinVel = NewVehicleState.LinVel;
        LocalState.AngVel = NewVehicleState.AngVel;

        bVehicleState = false;
        RBState = LocalState;
    }
    else
    {
        KGetRigidBodyState(RBState);
        PODSafetime(RBState);
    }

    return true;

//    local vector dpos, dlin;
//    local float dposa, dlina;
//    local KRigidBodyState LocalState;
//
//    KGetRigidBodyState(newState);
//    PODUpdateVehicle(newState);
//
//    if( bVehicleState )
//    {
//        //xLog( "KUpdateState" #bVehicleState );
//
//        //VehicleStateReceived(newState);
//
//
//        LocalState.Position = NewVehicleState.Position;
//        LocalState.Quaternion = NewVehicleState.Quaternion;
//        LocalState.LinVel = NewVehicleState.LinVel;
//        LocalState.AngVel = NewVehicleState.AngVel;
//
//        OutputThrust = NewVehicleState.OutputThrust;
//        OutputStrafe = NewVehicleState.OutputStrafe;
//        OutputRise = NewVehicleState.OutputRise;
//
//        //LocalState.Position = KRBVecFromVector(NewVehicleState.Position);
//        //LocalState.LinVel = KRBVecFromVector(0.1f * NewVehicleState.LinVel);
//        //LocalState.AngVel = KRBVectFromVector(0.001f * NewVehicleState.AngVel);
//
//        //dpos = KRBVecToVector(newState.Position) - KRBVecToVector(LocalState.Position);
//        //dlin = KRBVecToVector(newState.LinVel) - KRBVecToVector(LocalState.LinVel);
//
//        //dposa = KRBVecToVector(newState.Position) dot KRBVecToVector(LocalState.Position);
//        //dlina = KRBVecToVector(newState.LinVel) dot KRBVecToVector(LocalState.LinVel);
//
//        newState = LocalState;
//        //newState.AngVel = KRBVecFromVector(vect(0,0,0));
//
//        //xLog( "KUpdateState" #VSize(dpos) #VSize(dlin) );
//
//        bVehicleState = false;
//        return true;
//    }
}

simulated event UpdateVehicle(float dt )
{
    local KRigidBodyState RBState;

    //xLog("UpdateVehicle");

    KGetRigidBodyState(RBState);

    PODUpdateForces( dt, LocalForce, LocalTorque );
    LocalQuat = PODRotateVehicle(dt, RBState.Quaternion);
}

simulated final function PODUpdateForces( float DeltaTime, out vector Force, out vector Torque )
{
    local vector VehX, VehY, VehZ;
    local float VelXMag, VelYMag, VelZMag;

    Force = vect(0,0,0);

    if( Controller == None )
        return;

    GetAxes(Rotation,VehX,VehY,VehZ);

    VelXMag = Velocity dot VehX;
    VelYMag = Velocity dot VehY;
    VelZMag = Velocity dot VehZ;

    // Thrust
    Force += (OutputThrust * MaxThrustForce * VehX);
    //Force -= ( (1.0f - Abs(OutputThrust)) * ThrustDamping * VelXMag * VehX);

    // Rise
    Force += (OutputRise * MaxRiseForce * VehZ);
    //Force -= ( (1.0f - Abs(OutputRise)) * RiseDamping * VelZMag * VehZ);

    // Strafe
    if( !bIsWalking )
    {
        Force += (-OutputStrafe * MaxStrafeForce * VehY);
        //Force -= ( (1.0f - Abs(OutputStrafe)) * StrafeDamping * VelYMag * VehY);
    }
}

simulated final function quat PODRotateVehicle( float DeltaTime, quat qveh )
{
    local quat qcon;
    local float ades, amax, alpha;

    // rotate vehicle to controller rotation using constant speed

    if( Controller == None )
        return qveh;

    // get controller rotation
    if( Bot(Controller) != None )
    {
        qcon = QuatFromRotator(Normalize(DesiredRotation));
        //  FRotator ViewRot = (Controller->FocalPoint - Location).Rotation();
    }
    else
    {
        qcon = QuatFromRotator(Normalize(Controller.Rotation));
    }

    qcon = QuatInvert(qcon);        // ...
    AlignQuatWith(qveh,qcon);       // align quats
    ades = QuatError(qveh,qcon);    // get angle between quats

    // calc alpha value for slerp
    amax = AngularSpeed * DeltaTime;
    if( ades > amax )
    {
        alpha = amax / ades;
    }
    else
    {
        alpha = 1;
    }

    return QuatSlerp(qveh,qcon,alpha);
}

simulated final function PODSafetime( out KRigidBodyState rbstate )
{
    local vector vcur;
    local quat qcur;

    // undo any movement through world geometry

    vcur = KRBVecToVector(rbstate.Position);
    qcur = rbstate.Quaternion;

    if( bInitSafetime )
    {
        // do a simple trace on world geometry only
        // partial submerging in world geometry is ok, karma will push us away natively
        if( !FastTrace( vcur, LastSafeLocation ) )
        {
            rbstate.Position = KRBVecFromVector(LastSafeLocation);
            rbstate.Quaternion = LastSafeQuat;
            vcur = LastSafeLocation;
            qcur = LastSafeQuat;
        }
    }
    else
    {
        // do nothing the 1st time
        bInitSafetime = True;
    }

    LastSafeLocation = vcur;
    LastSafeQuat = qcur;
}

simulated final function PODUpdateSimParams()
{
//    local KSimParams p;
//
//    KGetSimParams(p);
//
//    p.GammaPerSec       = 6.0;  // default = 6.0
//    p.PenetrationScale  = 1.0;  // default = 1.0
//    p.MaxPenetration    = 0.13; // default = 0.13
//    p.MaxTimestep       = 0.04; // default = 0.04
//
//    KSetSimParams(p);
}

simulated final function PODInitCollision()
{
    // Hack to instance correctly the skeletal collision boxes
    GetBoneCoords('');
    SetCollision(false, false);
    SetCollision(true, true);
}

simulated event KApplyForce( out vector Force, out vector Torque )
{
    //if( Force != vect(0,0,0) || Torque != vect(0,0,0) )
    //    xLog("KApplyForce" #Force #Torque );

    Force += LocalForce;
    Torque += LocalTorque;
    LocalForce = vect(0,0,0);
    LocalTorque = vect(0,0,0);
    KWake();
}

event FellOutOfWorld(eKillZType KillType)
{
    xLog( "FellOutOfWorld" );
}

/*
event SetWalking( bool bNewIsWalking )
{
    //xLog( "SetWalking" #bNewIsWalking #bIsWalking );
    if ( bNewIsWalking != bIsWalking )
    {
        bIsWalking = bNewIsWalking;
        //ChangeAnimation();
    }
}*/

simulated function TouchedDarkMatter( PODSprayEmitter E )
{
    if( PlayerController(Controller) != None )
    {
        PlayerController(Controller).ClientFlash(1.0,vect(0,0,0));
    }
}

simulated function UnTouchedDarkMatter( PODSprayEmitter E )
{
    if( PlayerController(Controller) != None )
    {
        PlayerController(Controller).ClientFlash(1.0,vect(1000,1000,1000));
    }
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

simulated function SetupPlayerClass( optional class<PODPlayerClass> C )
{
    if( C == None )
        C = GetPlayerClass();

    if( C == None )
        return;

    //xLog( "SetupPlayerClass()" #GON(C) );

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

        Energy = C.default.Energy * default.Energy;
        EnergyMax = C.default.EnergyMax * default.EnergyMax;
        EnergyRegen = C.default.EnergyRegen * default.EnergyRegen;
    }

    LinearSpeed = C.default.LinearSpeed * default.LinearSpeed;
    AngularSpeed = C.default.AngularSpeed * default.AngularSpeed;

    MaxThrustForce = C.default.LinearAccel * default.MaxThrustForce;
    MaxStrafeForce = C.default.LinearAccel * default.MaxStrafeForce;
    MaxRiseForce = C.default.LinearAccel * default.MaxRiseForce;

    SVehicleUpdateParams();
}

// ============================================================================
//  Team
// ============================================================================

simulated function NotifyTeamChanged()
{
    // my PRI now has a new team
    PostNetReceive();
}


// ============================================================================
//  Inventory
// ============================================================================

simulated function vector GetGunOffset( optional int pos )
{
    if( pos == 0 )
        return GunOffset;
    else
        return GunOffset * vect(1,-1,1);
}

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
//  Stats
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


function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    local PlayerController PC;
    local Controller C;

    if ( bDeleteMe || Level.bLevelChange || bVehicleDestroyed)
        return; // already destroyed, or level is being cleaned up

    bVehicleDestroyed = True;

    if ( Physics != PHYS_Karma )
    {
        super.Died(Killer, damageType, HitLocation);
        return;
    }

    if ( Level.Game.PreventDeath(self, Killer, damageType, HitLocation) )
    {
        Health = max(Health, 1); //mutator should set this higher
        return;
    }
    Health = Min(0, Health);

    if ( Controller != None )
    {
        C = Controller;
        C.WasKilledBy(Killer);
        Level.Game.Killed(Killer, C, self, damageType);
        if( C.bIsPlayer )
        {
            PC = PlayerController(C);
            if ( PC != None )
                ClientKDriverLeave(PC); // Just to reset HUD etc.
            else
                ClientClearController();

            C.PawnDied(self);
        }
        else
            C.Destroy();

        bDriving = False;
    }
    else
        Level.Game.Killed(Killer, Controller(Owner), self, damageType);

    if ( Killer != None )
    {
        TriggerEvent(Event, self, Killer.Pawn);
        Instigator = Killer.Pawn; //so if the dead vehicle crushes somebody the vehicle's killer gets the credit
    }
    else
        TriggerEvent(Event, self, None);

    //RanOverDamageType = DestroyedRoadKillDamageType;
    //CrushedDamageType = DestroyedRoadKillDamageType;

    if ( IsHumanControlled() )
        PlayerController(Controller).ForceDeathUpdate();


    if (ParentFactory != None)
    {
        ParentFactory.VehicleDestroyed(self);
        ParentFactory = None;
    }

    GotoState('VehicleDestroyed');
}

// ============================================================================
//  Camera
// ============================================================================

simulated function SpecialCalcFirstPersonView(PlayerController PC, out actor ViewActor, out vector CameraLocation, out rotator CameraRotation )
{
    ViewActor = self;
    CameraLocation = Location;
    CameraRotation = PC.Rotation;
}


simulated function SpecialCalcBehindView(PlayerController PC, out actor ViewActor, out vector CameraLocation, out rotator CameraRotation )
{
    local vector x, y, z;

    GetAxes(PC.Rotation, x, y, z);
    ViewActor = self;
    CameraLocation = Location - X * 256;
    CameraRotation = PC.Rotation;
}

// ============================================================================
//  Controller
// ============================================================================

function PossessedBy(Controller C)
{
    //xLog( "PossessedBy" #GON(C) );

    Level.Game.DiscardInventory( Self );

    Super.PossessedBy( C );

    // KDriverEnter
    bDriving = True;
    StuckCount = 0;

    NetUpdateTime = Level.TimeSeconds - 1;
    bStasis = false;
    C.Pawn  = Self;
    AddDefaultInventory();
    if ( Weapon != None )
    {
        Weapon.NetUpdateTime = Level.TimeSeconds - 1;
        Weapon.Instigator = Self;
        PendingWeapon = None;
        Weapon.BringUp();
    }
}


// ============================================================================
//  Vehicle
// ============================================================================

event bool IsVehicleEmpty()
{
    if( Controller != None )
        return false;

    return true;
}

simulated function int NumPassengers()
{
    local int num;

    if ( Controller != None )
        num = 1;

    return num;
}


// ============================================================================
//  STATES
// ============================================================================
state VehicleDestroyed
{
ignores Tick;

    function CallDestroy()
    {
        Destroy();
    }

    function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
    {
    }

Begin:
    // Become the dead vehicle mesh
    //SetPhysics(PHYS_None);
    //KSetBlockKarma(False);
    //SetDrawType(DT_StaticMesh);
    //SetStaticMesh(DestroyedVehicleMesh);
    //KSetBlockKarma(True);
    //SetPhysics(PHYS_Karma);
    //Skins.length = 0;
    NetPriority = 2;

    //VehicleExplosion(vect(0,0,1), 1.0);
    sleep(9.0);
    CallDestroy();
}


// ============================================================================
//  Quaternion
// ============================================================================

// Ensure quat1 points to same side of the hypersphere as quat2
simulated final function AlignQuatWith( Quat quat2, out Quat quat1 )
{
    local float Minus, Plus;

    Minus  = Square(quat1.X-quat2.X) + Square(quat1.Y-quat2.Y) + Square(quat1.Z-quat2.Z) + Square(quat1.W-quat2.W);
    Plus   = Square(quat1.X+quat2.X) + Square(quat1.Y+quat2.Y) + Square(quat1.Z+quat2.Z) + Square(quat1.W+quat2.W);

    if( Minus > Plus )
    {
        quat1.X = - quat1.X;
        quat1.Y = - quat1.Y;
        quat1.Z = - quat1.Z;
        quat1.W = - quat1.W;
    }
}

// Error measure (angle) between two quaternions, ranged [0..1]
simulated final function float QuatError(Quat Q1,Quat Q2)
{
    local float cosom;

    cosom = Q1.X*Q2.X + Q1.Y*Q2.Y + Q1.Z*Q2.Z + Q1.W*Q2.W;
    if( Abs(cosom) < 0.9999999f )
       return acos(cosom)*(1.f/PI);
    return 0;
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

final static operator(112) string # ( coerce string A, rotator B )
{
    return A @"[" $B.Pitch$"," $B.Yaw$"," $B.Roll $"]";
}

final static operator(112) string # ( coerce string A, quat B )
{
    return A @"[" $B.W$"," $B.X$"," $B.Y$"," $B.Z $"]";
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

simulated function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
    Super.DisplayDebug(Canvas, YL, YPos);

    Canvas.SetDrawColor(255,0,0);
    //Canvas.DrawText("Awake:" #bIsAwake #bHasBeenAwake );
    YPos += YL;

    Canvas.SetDrawColor(255,0,0);
    Canvas.DrawText("Forces:" #VSize(LocalForce) #VSize(LocalTorque) );
    YPos += YL;

    /*KParams.CalcContactRegion();
    if( KParams.bContactingLevel )
    {
        Canvas.SetDrawColor(0,128,255);
        Canvas.DrawText("Contact:" #KParams.ContactRegionRadius #KParams.ContactRegionNormalForce #KParams.ContactRegionCenter #KParams.ContactRegionNormal );
        YPos += YL;
    }*/

}


// ============================================================================
//  Debug Draw
// ============================================================================
simulated final function DrawAxesRot( vector Loc, rotator Rot, float Length )
{
    local vector X,Y,Z;
    GetAxes( Rot, X, Y, Z );
    Level.DrawDebugLine(Loc,Loc+X*Length,255,0,0);
    Level.DrawDebugLine(Loc,Loc+Y*Length,0,255,0);
    Level.DrawDebugLine(Loc,Loc+Z*Length,0,0,255);
}

simulated final function DrawAxesXYZ( vector Loc, vector X, vector Y, vector Z, float Length )
{
    Level.DrawDebugLine(Loc,Loc+X*Length,255,0,0);
    Level.DrawDebugLine(Loc,Loc+Y*Length,0,255,0);
    Level.DrawDebugLine(Loc,Loc+Z*Length,0,0,255);
}

DefaultProperties
{
    //bServerMoveSetPawnRot         = false


    // - PODSVehicle ----------------------------------------------------------

    MaxThrustForce                  = 66
    MaxStrafeForce                  = 33
    MaxRiseForce                    = 33

    ThrustDamping                   = 0.0
    StrafeDamping                   = 0.0
    RiseDamping                     = 0.0

    LinearSpeed                     = 400
    AngularSpeed                    = 0.33

    RegenTimerFreq                  = 0.25

    Energy                          = 100
    EnergyMax                       = 100
    EnergyRegen                     = 10
    EnergyRegenTime                 = 1

    Shield                          = 100
    ShieldMax                       = 100
    ShieldRegen                     = 1
    ShieldRegenTime                 = 1

    HealthRegen                     = 1
    HealthRegenTime                 = 1


    // - Vehicle --------------------------------------------------------------

    bDrawDriverInTP                 = False
    bDrawMeshInFP                   = False
    bDrawVehicleShadow              = False
    bAdjustDriversHead              = False

    FPCamPos                        = (X=0,Y=0,Z=0)

    TPCamExtent                     = (X=4,Y=4,Z=4)
    TPCamDistance                   = 256
    TPCamLookat                     = (X=0,Y=0,Z=96)
    TPCamDistRange                  = (Min=256,Max=768)
    TPCamWorldOffset                = (X=0,Y=0,Z=0)


    bZeroPCRotOnEntry               = True
    bPCRelativeFPRotation           = False

    bFollowLookDir                  = True
    bTurnInPlace                    = True

    VehiclePositionString           = "VehiclePositionString"
    VehicleNameString               = "VehicleNameString"

    //VehicleMass                   = 1

    MinRunOverSpeed                 = 50


    // - Pawn -----------------------------------------------------------------

    Health                          = 100
    HealthMax                       = 100

    MaxViewYaw                      = 0
    MaxViewPitch                    = 0

    BaseEyeHeight                   = 0.0
    EyeHeight                       = 0.0

    GroundSpeed                     = 768
    WaterSpeed                      = 768
    AirSpeed                        = 768
    LadderSpeed                     = 768
    AccelRate                       = 768
    JumpZ                           = 0
    AirControl                      = 1
    WalkingPct                      = 1
    CrouchedPct                     = 1
    MaxFallSpeed                    = 1280

    MinFlySpeed                     = 0
    MaxRotation                     = 0

    DesiredSpeed                    = 1
    MaxDesiredSpeed                 = 1

    LandMovementState               = "PODPlayerDriving"

    bFlyingKarma                    = False
    bSimulateGravity                = False
    bCanBeBaseForPawns              = False

     bSpecialCalcView=True

    bJumpCapable                    = False
    bCanHover                       = False
    bCanFly                         = True
    bCanStrafe                      = True
    bCanJump                        = False
    bCanWalk                        = False
    bCanDoubleJump                  = False
    bCanClimbLadders                = false
    bCanPickupInventory             = false
    bCanTeleport                    = false
    bCanUse                         = False


    // - Actor ----------------------------------------------------------------

    DrawScale                       = 1.0
    Mesh                            = Mesh'PODAN_DronesNano.soldier'
    DrawType                        = DT_Mesh
    AmbientGlow                     = 96
    bUnlit                          = false
    bDramaticLighting               = False

    AmbientSound                    = Sound'AssaultSounds.HnSpaceShipEng01'
    SoundRadius                     = 100
    SoundVolume                     = 255
    TransientSoundVolume            = 1.0
    TransientSoundRadius            = 784.0

    bNetNotify                      = True
    bStasis                         = False
    bAlwaysTick                     = True
    bNetInitialRotation             = True

    Physics                         = PHYS_Karma
    CollisionHeight                 = 80
    CollisionRadius                 = 80
    bSmoothKarmaStateUpdates        = False
    bCollideWorld                   = False
    bBlockKarma                     = True
    bUseCollisionStaticMesh         = True


    // - SubObjects -----------------------------------------------------------

    Begin Object Class=KarmaParamsRBFull Name=KParams0
        KInertiaTensor(0)=10.0
        KInertiaTensor(1)=0.0
        KInertiaTensor(2)=0.0
        KInertiaTensor(3)=10.0
        KInertiaTensor(4)=0.0
        KInertiaTensor(5)=10.0
        KStartEnabled=True
        KFriction=0.1
        KLinearDamping=2.0
        KAngularDamping=1.0
        KRestitution=0.5
        bKNonSphericalInertia=False
        bHighDetailOnly=False
        bClientOnly=False
        KActorGravScale=0.0
        KMaxAngularSpeed=0.1
        KImpactThreshold=1000
        bDestroyOnWorldPenetrate=True
        bKDoubleTickRate=False
        bDoSafetime=False
        Name="KParams0"
    End Object
    KParams=KarmaParams'KParams0'

}
