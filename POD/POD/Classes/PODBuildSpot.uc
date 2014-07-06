// ============================================================================
//  PODBuildSpot.uc ::
// ============================================================================
class PODBuildSpot extends PODDestroyableObjective;

var Actor Structure;
var class<PODBlueprint> Blueprint;
var PODSpore Spore;
var PODConstructingEmitter ConEmitter;
var VolumeTimer WrenchTimer;
var rotator BaseRotation;
var Controller Constructor;
var() array< class<PODBlueprint> > Prohibited;


// ============================================================================
//  Replication
// ============================================================================
replication
{
    reliable if ( bNetInitial && Role == ROLE_Authority )
        BaseRotation;

    reliable if ( bNetDirty && Role == ROLE_Authority )
        Structure, Blueprint;
}

simulated function PostNetBeginPlay()
{
    Super.PostNetBeginPlay();

    if( Level.NetMode != NM_DedicatedServer )
    {
        ConEmitter = Spawn(class'PODConstructingEmitter',self,,Location,BaseRotation);
        WrenchTimer = Spawn(class'VolumeTimer',self);
    }
}


// ============================================================================
//  Lifespan
// ============================================================================
simulated function PostBeginPlay()
{
    //local vector X,Y,Z;

    if( Role == ROLE_Authority )
    {
        BaseRotation = Rotation;
    }

    //GetAxes(default.RotationRate,X,Y,Z);
    //RotationRate = OrthoRotation(X>>Rotation,Y>>Rotation,Z>>Rotation);
    AIShootOffset = default.AIShootOffset >> Rotation;

    Super.PostBeginPlay();
}

simulated function TimerPop(VolumeTimer T)
{
    if( T == UnderAttackTimer )
    {
        Super.TimerPop(T);
    }
    else if( T == WrenchTimer )
    {
        UpdateWrench();
    }
}

function Reset()
{
    Super(GameObjective).Reset();

    Health = 0;
    AccumulatedDamage = 0;
    UpdateWrench();

    if( UnderAttackTimer != None )
    {
        UnderAttackTimer.Destroy();
        UnderAttackTimer = None;
    }
}


// ============================================================================
//  BuildSpot
// ============================================================================

simulated function UpdateWrench()
{
    local PODPlayer PC;
    local byte TeamNum;

    PC = PODPlayer(Level.GetLocalPlayerController());
    if( PC != None )
    {
        // TODO: Spectator support
        //if( Pawn(PC.ViewTarget) != None )
        //    TeamNum = Pawn(PC.ViewTarget).GetTeamNum();
        //else
            TeamNum = PC.GetTeamNum();

        if( TeamNum != 255
        &&  TeamNum == DefenderTeamIndex
        &&  Health >= 0
        &&  IsStructureDestroyed()
        &&  class<PODEngineerClass>(PC.GetPlayerClass()) != None )
        {
            SetDrawType(default.DrawType);
            return;
        }
    }
    SetDrawType(DT_None);
}


simulated function bool IsStructureDestroyed()
{
    return Structure == None
        || Structure.bDeleteMe
        || Structure.bHidden
        ||(Pawn(Structure) != None && Pawn(Structure).Health <= 0);
}

function SetBlueprint( class<PODBlueprint> B )
{
    Blueprint = B;
}

simulated function bool IsValidTarget( Pawn P )
{
    if(!bActive
    ||  bDisabled
    ||  Health < 0
    ||  DefenderTeamIndex != P.GetTeamNum() )
        return false;

    if( PODKVehicle(P) != None
    &&  class<PODEngineerClass>(PODKVehicle(P).GetPlayerClass()) == None )
        return false;

    return true;
}

function SetTeam( byte TeamIndex )
{
    if( TeamIndex != DefenderTeamIndex )
        DestroyStructure();

    DefenderTeamIndex = TeamIndex;
}

function DestroyStructure()
{
    if( Structure != None )
    {
        if( Pawn(Structure) != None )
            Pawn(Structure).KilledBy(None);
        else if( Structure.bCanBeDamaged )
            Structure.TakeDamage( 1000000, None, Structure.Location, vector(Rotation), class'DamageType' );
        else
            Structure.Destroy();
        Structure = None;
    }
}

simulated function bool IsBlueprintValid( class<PODBlueprint> B )
{
    local int i;

    if( B == None )
        return false;

    for( i=0; i!=Prohibited.Length; ++i )
    {
        if( Prohibited[i] == B )
            return false;
    }

    return true;
}

// ============================================================================
//  Damage
// ============================================================================


function bool IsOccupied()
{
    if( Health >= DamageCapacity
    ||  Health < 0
    || !IsStructureDestroyed() )
        return True;
    return False;
}


function TakeDamage( int Damage, Pawn InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType )
{
}

function bool HealDamage(int Amount, Controller Healer, class<DamageType> DamageType)
{
    //xLog( "HealDamage" #Amount #GON(Healer) #GON(DamageType) );

    if( class<PODToolboxDamage>(DamageType) == None )
        return false;

    if(!bActive
    ||  bDisabled
    ||  Health < 0
    ||  Health >= DamageCapacity
    ||  Amount <= 0
    ||  Healer == None
    ||  DefenderTeamIndex != Healer.GetTeamNum()
    || (Constructor != None && Constructor != Healer) )
        return false;

    // bot hack
    if( PODBot(Healer) != None )
        SetBlueprint(PODBot(Healer).ChooseBlueprint(self));

    if( Blueprint == None )
        return false;

    Constructor = Healer;
    Health = Min(Health + (Amount * LinkHealMult), DamageCapacity);
    NetUpdateTime = Level.TimeSeconds - 1;

    //if( ConEmitter != None )
    //    ConEmitter.SetBlueprint( Blueprint );

    if( Health == DamageCapacity )
    {
        DisableObjective(Healer.Pawn);
    }
    else
    {
        GotoState('Degrading');
    }

    return true;
}

function DisableObjective(Pawn Instigator)
{
    local PlayerReplicationInfo PRI;

    if ( !IsActive() || !UnrealMPGameInfo(Level.Game).CanDisableObjective( Self ) )
        return;

    NetUpdateTime = Level.TimeSeconds - 1;

    bIsUnderAttack  = false;
    //Health = DamageCapacity;
    Constructor = None;

    if( UnderAttackTimer != None )
    {
        UnderAttackTimer.Destroy();
        UnderAttackTimer = None;
    }

    if ( bClearInstigator )
    {
        Instigator = None;
    }
    else
    {
        if ( Instigator != None )
        {
            if ( Instigator.PlayerReplicationInfo != None )
                PRI = Instigator.PlayerReplicationInfo;
            else if ( Instigator.Controller != None && Instigator.Controller.PlayerReplicationInfo != None )
                PRI = Instigator.Controller.PlayerReplicationInfo;
        }

        if ( DelayedDamageInstigatorController != None )
        {
            if ( Instigator == None )
                Instigator = DelayedDamageInstigatorController.Pawn;

            if ( PRI == None && DelayedDamageInstigatorController.PlayerReplicationInfo != None )
                PRI = DelayedDamageInstigatorController.PlayerReplicationInfo;
        }

        if ( !bBotOnlyObjective && DestructionMessage != "" )
            PlayDestructionMessage();
    }


    Health = -1; // Disable building
    GotoState('Construction');


    SetCriticalStatus( false );
    DisabledBy  = PRI;
    if ( MyBaseVolume != None && MyBaseVolume.IsA('ASCriticalObjectiveVolume') )
        MyBaseVolume.GotoState('ObjectiveDisabled');

    if ( bAccruePoints )
        Level.Game.ScoreObjective( PRI, 0 );
    else
        Level.Game.ScoreObjective( PRI, Score );

    if ( !bBotOnlyObjective )
        UnrealMPGameInfo(Level.Game).ObjectiveDisabled( Self );

    TriggerEvent(Event, self, Instigator);

    UnrealMPGameInfo(Level.Game).FindNewObjectives( Self );
}


// ============================================================================
//  AI
// ============================================================================

function bool BetterObjectiveThan( GameObjective Best, byte DesiredTeamNum, byte RequesterTeamNum )
{
    if( !IsActive() || DefenderTeamIndex != DesiredTeamNum )
        return false;

    if( Best == self )
        return true;

    if( IsOccupied() )
        return false;

    if( Best == None || Best.DefensePriority < DefensePriority )
        return true;

    return false;
}

function bool TellBotHowToHeal( Bot B )
{
    local PODBot PB;

    PB = PODBot(B);
    if( PB == None )
        return false;

    if( !BetterObjectiveThan(None,B.GetTeamNum(),0) )
        return false;

    // if someone's already constructing, dont interrupt
    if( class<PODEngineerClass>(PB.GetPlayerClass()) == None
    || (Constructor != None && Constructor != B) )
    {
        // wander around
        B.GoalString = "Move away from "$self;
        B.RouteGoal = B.FindRandomDest();
        B.MoveTarget = B.RouteCache[0];
        B.SetAttractionState();
        return True;
    }

    //xLog( "TellBotHowToHeal" #B.Pawn.ReachedDestination(self) );

    if( B.Pawn.ReachedDestination(self) )
    {
        if( B.Squad.SquadObjective == None )
        {
            //hack - if bot has no squadobjective, need this for SwitchToBestWeapon() so bot's weapons' GetAIRating()
            //has some way of figuring out bot is trying to heal me
            B.DoRangedAttackOn(self);
            B.SwitchToBestWeapon();
        }

        B.Focus = GetShootTarget();
        B.DoRangedAttackOn(GetShootTarget());
        B.Pawn.DesiredSpeed = 0;

        return true;
    }

    return B.Squad.FindPathToObjective(B,self);
}

//function bool IsRelevant( Pawn P, bool bAliveCheck )
//{
//    local byte PawnTeam;
//
//    if( P == None
//    || !ClassIsChildOf(P.Class, ConstraintPawnClass)
//    || !IsActive()
//    || !UnrealMPGameInfo(Level.Game).CanDisableObjective( Self )
//    ){
//        return false;
//    }
//
//    //PawnTeam = P.GetTeamNum();
//
//    if( bAliveCheck )
//    {
//        if( P.Health < 1 || P.bDeleteMe || !P.IsPlayerPawn() )
//            return false;
//    }
//
//    if( bBotOnlyObjective && (PlayerController(P.Controller) != None) )
//        return false;
//
//    return true;
//}

//
//function bool TellBotHowToDisable(Bot B)
//{
//    //xLog( "TellBotHowToDisable" #GON(B) );
//    return B.Squad.FindPathToObjective(B,self);
//}
//
//function bool TellBotHowToHeal(Bot B)
//{
//    //xLog( "TellBotHowToHeal" #GON(B) );
//    return Super.TellBotHowToHeal(B);
//    //return B.Squad.FindPathToObjective(B,self);
//}


//simulated function float GetPriority( byte TeamNum )
//{
//    if( !IsActive() )
//        return -1;
//
//    xLog( "GetPriority" #TeamNum );
//
//    if( TeamNum == DefenderTeamIndex )
//    {
//        if( Structure != None )
//            return -1;
//        else
//            return 2;
//    }
//    else if( TeamNum == 255 )
//    {
//        return -1;
//    }
//    else
//    {
//        if( Structure != None )
//            return 2;
//        else
//            return -1;
//    }
//}




// ============================================================================
//  States
// ============================================================================

// ----------------------------------------------------------------------------
//  Degrading
// ----------------------------------------------------------------------------
state Degrading
{
Begin:
    //xLog( "Degrading" #Health );
    if( Health > 0 )
    {
        Sleep(0.25);
        Health = FMax( Health-0.25*DamageCapacity, 0 );
        Goto('Begin');
    }
    SetBlueprint(None);
    //if( ConEmitter != None )
    //    ConEmitter.SetBlueprint( None );
    GotoState('');
}

// ----------------------------------------------------------------------------
//  Regenerating
// ----------------------------------------------------------------------------
//state Regenerating
//{
//Begin:
//    //xLog( "Regenerating" #Health );
//    if( Health < DamageCapacity )
//    {
//        Sleep(0.25);
//        Health = FMin( Health+0.25*DamageCapacity, DamageCapacity );
//        Goto('Begin');
//    }
//    GotoState('');
//}

// ----------------------------------------------------------------------------
//  Construction
// ----------------------------------------------------------------------------
state Construction
{
//    simulated function float GetPriority( byte TeamNum )
//    {
//        if( !bActive || bDisabled )
//            return -1;
//
//        if( TeamNum != DefenderTeamIndex )
//            return 1;
//
//        return -1;
//    }

    event BeginState()
    {
    }

    event EndState()
    {
        Constructor = None;
    }

    function SetBlueprint( class<PODBlueprint> B )
    {
    }

    function TimerPop(VolumeTimer T)
    {
        if( T == WrenchTimer )
            return;
        Super.TimerPop(T);
    }

    function bool SpawnStructure()
    {
        local vector L;

        if( Structure == None )
        {
            //SetCollision(False,False);

            L = Location + (Blueprint.default.ItemOffset>>BaseRotation);
            if( Blueprint != None )
                Structure = Spawn(Blueprint.default.ItemClass,,,L,BaseRotation);

            //SetCollision(True,True);
        }

        if( Vehicle(Structure) != None )
        {
            Vehicle(Structure).SetTeamNum( DefenderTeamIndex );
        }

        return Structure != None;
    }

Begin:
    DestroyStructure();
    Sleep(2.0);

Spawning:
    if( !SpawnStructure() )
    {
        Sleep(1.0);
        Goto('Spawning');
    }

    Blueprint = None;
    Health = 0; // Enable building
    NetUpdateTime = Level.TimeSeconds - 1;
    GotoState('');
}


// ============================================================================
//  DefaultProperties
// ============================================================================
DefaultProperties
{
    LinkHealMult                    = 1

    //ControlSound                  = sound'GameSounds.DDAlarm'
    //AIUseOffset                   = (Z=-127)
    //AIShootOffset                 = (Z=-128.000000)


    Blueprint                       = None

    Prohibited(0)                   = class'PODBPAttractor'

    // - Objective ------------------------------------------------------------

    bInitiallyActive                = True

    bCanBeDamaged                   = True

    bTeamControlled                 = True
    bReplicateObjective             = True
    bPlayCriticalAssaultAlarm       = True

    //BaseExitTime                  = 0.25
    //BaseRadius                    = 128

    //DefensePriority               = 100

    ObjectiveName                   = "Build Spot"
    DestructionMessage              = "Structure Built!"
    ObjectiveDescription            = "Engineer can build structures here."
    Objective_Info_Attacker         = "Destroy Structure"
    Objective_Info_Defender         = "Defend Structure"

    ObjectiveTypeIcon               = FinalBlend'AS_FX_TX.Icons.OBJ_Proximity_FB'
    Announcer_DisabledObjective     = Sound'AnnouncerAssault.Generic.Objective_accomplished'


    // - NavigationPoint ------------------------------------------------------

    bNotBased                       = True
    bDestinationOnly                = True
    //    bFlyingPreferred          = True
    //    bOptionalJumpDest         = False
    //    bForceDoubleJump          = False
    //    bSpecialForced            = False


    // - Actor ----------------------------------------------------------------

    bHidden                         = False
    DrawType                        = DT_StaticMesh
    StaticMesh                      = StaticMesh'PODSM_Objectives.rwrench'
    //Prepivot                      = (Z=128)

    bFixedRotationDir               = True
    RotationRate                    = (Yaw=32768)
    DrawScale                       = 10
    bUnlit                          = True
    Physics                         = PHYS_Rotating

    CollisionHeight                 = 64
    CollisionRadius                 = 64
    bCollideActors                  = True
    bBlockActors                    = False
    bProjTarget                     = False
    bBlockKarma                     = False
    bIgnoreEncroachers              = True
    bCollideWhenPlacing             = False
    bUseCylinderCollision           = True

    bStatic                         = False
    //bOnlyAffectPawns              = True
    bAlwaysRelevant                 = True

    //SoundRadius                   = 255
    //SoundVolume                   = 255
}
