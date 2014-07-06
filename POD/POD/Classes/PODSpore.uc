// ============================================================================
//  PODSpore.uc ::
// ============================================================================
class PODSpore extends PODDestroyableObjective
    placeable;



var() Sound ControlSound;       // sound played when this control point changes hands

var() array<GameObjective>      SubObjectives;
var   float BasePriority;

var PODConstructingEmitter ConEmitter;
var Controller Constructor;


// ============================================================================
//  Replication
// ============================================================================

simulated function PostNetBeginPlay()
{
    Super.PostNetBeginPlay();

    if( Level.NetMode != NM_DedicatedServer )
    {
        ConEmitter = Spawn(class'PODSporeEmitter',self,,Location,Rotation);
    }
}

// ============================================================================
//  Lifespan
// ============================================================================
simulated function PostBeginPlay()
{
    AIShootOffset = default.AIShootOffset >> Rotation;

    Super.PostBeginPlay();

    //xLog( "PostBeginPlay" );

    if( Role == Role_Authority )
    {
        BasePriority = DefensePriority;
    }
}

function MatchStarting()
{
    local PODGame G;
    local PODBuildSpot S;
    local int i;

    // Find SubObjectives
    G = PODGame(Level.Game);
    if( G != None )
    {
        SubObjectives.Length = 0;
        for( i=0; i!=G.Objectives.Length; ++i )
        {
            S = PODBuildSpot(G.Objectives[i]);
            if( S != None && S.Tag == PhysicalObjectiveActorsTag )
            {
                SubObjectives[SubObjectives.Length] = S;
                S.Spore = Self;
            }
        }
    }

    UpdateSubObjectives();
}

// ============================================================================
//  GameObjective
// ============================================================================
function SetActive( bool bActiveStatus )
{
    Super.SetActive(bActiveStatus);
    UpdateSubObjectives();
}

function DisableObjective(Pawn Instigator)
{
    local PlayerReplicationInfo PRI;

    if( !IsActive() || !UnrealMPGameInfo(Level.Game).CanDisableObjective( Self ) )
        return;

    Instigator.DesiredSpeed = Instigator.MaxDesiredSpeed;

    bIsUnderAttack  = false;
    Health = DamageCapacity;

    if( UnderAttackTimer != None )
    {
        UnderAttackTimer.Destroy();
        UnderAttackTimer = None;
    }

    NetUpdateTime = Level.TimeSeconds - 1;

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


    if ( bTeamControlled )
    {
        if (PRI != None)
            DefenderTeamIndex = PRI.Team.TeamIndex;
    }
    else
    {
        bDisabled   = true;
        SetActive( false );
    }


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

    UpdateSubObjectives();
    UnrealMPGameInfo(Level.Game).FindNewObjectives( Self );

    BroadcastCapture();
}


// ============================================================================
//  SubObjectives
// ============================================================================
function UpdateSubObjectives()
{
    local int i;
    local PODBuildSpot S;

    //xLog( "UpdateSubObjectives" );

    DefensePriority = BasePriority;

    for( i=0; i!=SubObjectives.Length; ++i )
    {
        S = PODBuildSpot(SubObjectives[i]);
        if( S != None )
        {
            S.Spore = self;
            S.SetActive(bActive);
            S.SetTeam(DefenderTeamIndex);
            if( S.Structure == None )
                DefensePriority += 1;
        }
    }
}
function GameObjective GetSubObjective( byte TeamNum )
{
    local int i;
    local GameObjective S;

    for( i=0; i!=SubObjectives.Length; ++i )
    {
        S = SubObjectives[i];
        if( S != None && S.BetterObjectiveThan(None,TeamNum,0) )
        {
            return S;
        }
    }
    return None;
}

// ============================================================================
//  Feedback
// ============================================================================

function BroadcastCapture()
{
    local Controller C;

    for ( C=Level.ControllerList; C!=None; C=C.NextController )
    {
         if( C.GetTeamNum() != 255 && PlayerController(C) != None )
         {
             if( DefenderTeamIndex == 255 )
             {
                 if( Instigator.GetTeamNum() == 0 )
                 {
                     Level.Game.BroadCastHandler.BroadcastLocalized( self, PlayerController(C), class'PODSporeMessage', 5);
                 } else {
                     Level.Game.BroadCastHandler.BroadcastLocalized( self, PlayerController(C), class'PODSporeMessage', 4);
                 }
             }
             else if( DefenderTeamIndex == 0 )
             {
                 Level.Game.BroadCastHandler.BroadcastLocalized( self, PlayerController(C), class'PODSporeMessage', 3);
             }
             else if( DefenderTeamIndex == 1 )
             {
                 Level.Game.BroadCastHandler.BroadcastLocalized( self, PlayerController(C), class'PODSporeMessage', 2);
             }
         }
    }
}


function BroadcastAlert()
{
    local Controller C;

    for ( C=Level.ControllerList; C!=None; C=C.NextController )
    {
        if( PlayerController(C) != None
        &&  C.GetTeamNum() != DefenderTeamIndex
        &&  C.GetTeamNum() != 255 )
        {
            if( C.GetTeamNum() == 0 )
            {
                Level.Game.BroadCastHandler.BroadcastLocalized( self, PlayerController(C), class'PODSporeMessage', 0);
            }
            else
            {
                Level.Game.BroadCastHandler.BroadcastLocalized( self, PlayerController(C), class'PODSporeMessage', 1);
            }
        }
    }
}


// ============================================================================
//  Damage
// ============================================================================

function TakeDamage( int Damage, Pawn InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType )
{
    local bool bWasUnderAttack;

    if( class<PODToolboxDamage>(DamageType) == None )
        return;

    bWasUnderAttack = bIsUnderAttack;

    //xLog( "TakeDamage" #Damage #GON(InstigatedBy) /*#HitLocation, #Momentum*/ #GON(DamageType) );

    if( InstigatedBy != None )
        Constructor = InstigatedBy.Controller;

    GotoState('Regenerating');

    Super.TakeDamage( Damage, InstigatedBy, HitLocation, Momentum, DamageType );

    if( bIsUnderAttack && !bWasUnderAttack )
        BroadcastAlert();
}

function bool HealDamage(int Amount, Controller Healer, class<DamageType> DamageType)
{
    //xLog( "HealDamage" #Amount #GON(Healer) #GON(DamageType) );
    return false;
}


// ============================================================================
//  AI
// ============================================================================

function bool BetterObjectiveThan( GameObjective Best, byte DesiredTeamNum, byte RequesterTeamNum )
{
    if( !IsActive() || DefenderTeamIndex == DesiredTeamNum )
        return false;

    if( Best == None || Best.DefensePriority < DefensePriority )
        return true;

    return false;
}

function bool TellBotHowToDisable( Bot B )
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

    //xLog( "TellBotHowToDisable" #B.Pawn.ReachedDestination(self) );

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
        //B.MoveTimer = -1;
        //B.MoveTarget = GetShootTarget();
        B.Pawn.DesiredSpeed = 0;

        return true;
    }
    //xLog( "TellBotHowToDisable" #B.Pawn.ReachedDestination(self) );

    return B.Squad.FindPathToObjective(B,self);
}

function bool TellBotHowToHeal(Bot B)
{
    return false;
}


// ============================================================================
//  States
// ============================================================================

// ----------------------------------------------------------------------------
//  Regenerating
// ----------------------------------------------------------------------------
state Regenerating
{
Begin:
    //xLog( "Regenerating" #Health );
    if( Health < DamageCapacity )
    {
        Sleep(0.25);
        Constructor = None;
        Health = FMin( Health+0.25*DamageCapacity, DamageCapacity );
        Goto('Begin');
    }
    Constructor = None;
    GotoState('');
}


// ============================================================================
//  DefaultProperties
// ============================================================================
DefaultProperties
{
    LinkHealMult                    = 1
    ConstraintPawnClass             = Class'POD.PODKVehicle'

    AIShootOffset=(Z=-128.000000)


    ControlSound                    = sound'GameSounds.DDAlarm'
    SoundRadius                     = 255
    SoundVolume                     = 255

    bCanBeDamaged                   = False
    //AIUseOffset                     = (Z=-127)

    bTeamControlled                 = True
    bReplicateObjective             = True
    bPlayCriticalAssaultAlarm       = True

    BaseExitTime                    = 0.25
    BaseRadius                      = 128

    ObjectiveName                   = "Spawning Spore"
    DestructionMessage              = "Spore-Point Captured!"
    ObjectiveDescription            = "Reach Objective and hold use key to capture it."
    Objective_Info_Attacker         = "Capture Objective"
    Objective_Info_Defender         = "Defend Objective"

    ObjectiveTypeIcon               = FinalBlend'AS_FX_TX.Icons.OBJ_Proximity_FB'
    Announcer_DisabledObjective     = Sound'AnnouncerAssault.Generic.Objective_accomplished'

    bNotBased                       = True
    bDestinationOnly                = True
    //    bFlyingPreferred          = True
    //    bOptionalJumpDest         = False
    //    bForceDoubleJump          = False
    //    bSpecialForced            = False

    bHidden                         = False
    DrawType                        = DT_StaticMesh
    StaticMesh                      = StaticMesh'2k4ChargerMeshes.ChargerMeshes.HealthChargerMESH-DS'
    Prepivot                        = (Z=128)

    CollisionHeight                 = 128
    CollisionRadius                 = 128
    bCollideActors                  = True
    bBlockActors                    = True
    bProjTarget                     = True
    bBlockKarma                     = False
    bIgnoreEncroachers              = True
    bCollideWhenPlacing             = False

    bStatic                         = False
    //bOnlyAffectPawns                = True
    bAlwaysRelevant                 = True
}
