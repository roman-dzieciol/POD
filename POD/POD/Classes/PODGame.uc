// ============================================================================
//  PODGame.uc ::
// ============================================================================
class PODGame extends xTeamGame;


// - PlayerStart Ratings ------------------------------------------------------
const PSR_Invalid   =-0x7FFFFFFF;
const PSR_Max       = 0x7FFFFFFF;

// - Objectives ---------------------------------------------------------------
var array<GameObjective> Objectives;
var PODHeart Heart;


// ============================================================================
//  Lifespan
// ============================================================================
event InitGame( string Options, out string Error )
{
    local NavigationPoint N;

    Super.InitGame(Options, Error);

    // TeamGame.InitGame() removes those
    if( RedTeamName == "" )
        RedTeamName = default.RedTeamName;
    if( BlueTeamName == "" )
        BlueTeamName = default.BlueTeamName;

    // Register all the objectives
    for( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
    {
        if( GameObjective(N) != None )
        {
            Objectives[Objectives.Length] = GameObjective(N);
        }
    }

//    foreach DynamicActors(Class'PODHeart', Heart)
//            break;
//
//    if( Heart != none )
//    {
//        Heart.Health = 1000;
//    }

}


state MatchInProgress
{
    function Timer()
    {
        Super.Timer();

//        if ( Heart == none )
//        {
//            foreach AllActors(class'PODHeart',Heart)
//                break;
//        }
//
//        if ( Heart != none ) {
//            PODGRI(GameReplicationInfo).HeartPos = Heart.Location;
//            PODGRI(GameReplicationInfo).HeartTHealth = Heart.Health;
//        }

        //UpdatePlayerEnergy();

        if ( RemainingTime <= 0 )
        {

             EndGame(none,"OutOfTime");

        }

    }
}

// ============================================================================
//  Player Class
// ============================================================================

function bool ChangeClass(Controller Other, byte b)
{
    local PODPRI PRI;

    PRI = PODPRI(Other.PlayerReplicationInfo);
    if( PRI == None )
        return false;

    PRI.PlayerClassByte = b;
    Other.StartSpot = None;

    //BroadcastLocalizedMessage( GameMessageClass, 3, Other.PlayerReplicationInfo, None, NewTeam );
    if( PlayerController(Other) != None )
        GameEvent("ClassChange",string(b),Other.PlayerReplicationInfo);

    return true;
}


// ============================================================================
//  AI
// ============================================================================

function Bot SpawnBot(optional string botName)
{
    local Bot NewBot;
    local RosterEntry Chosen;
    local UnrealTeamInfo BotTeam;

    BotTeam = GetBotTeam();
    Chosen = BotTeam.ChooseBotClass(botName);

    if( Chosen != None && Chosen.PawnClass == None )
        Chosen.Init();

    NewBot = Spawn(class'PODBot');
    if( NewBot != None )
        InitializeBot(NewBot,BotTeam,Chosen);

    return NewBot;
}


function InitializeBot(Bot NewBot, UnrealTeamInfo BotTeam, RosterEntry Chosen)
{
    NewBot.InitializeSkill(AdjustedDifficulty);
    BotTeam.AddToTeam(NewBot);

    if( PODTeamInfo(BotTeam) != None )
        ChangeName(NewBot, PODTeamInfo(BotTeam).GetBotName(), false);
    else
        ChangeName(NewBot, DefaultPlayerName, false);

    BotTeam.SetBotOrders(NewBot,Chosen);
}

function float SpawnWait(AIController B)
{
    if( B.PlayerReplicationInfo.bOutOfLives )
        return 999;

    if( Level.NetMode == NM_Standalone )
    {
        if( NumBots > 3 )
            return ( 0.5 * FMax(2,NumBots-4) * FRand() );
    }

    return FRand();
}



// ============================================================================
//  Player
// ============================================================================
function class<Pawn> GetDefaultPlayerClass(Controller C)
{
    local PODPRI PRI;

    PRI = PODPRI(C.PlayerReplicationInfo);
    if( PRI != None )
        return PRI.GetPawnClass();
}

function Logout(Controller Exiting)
{
    Super.Logout(Exiting);
    CheckScore(None);
}


// ============================================================================
//  Controller
// ============================================================================
function RestartPlayer( Controller C )
{
//    xLog( "RestartPlayer"
//    #GON(C)
//    #GON(FindSpore(C.GetTeamNum()))
//    #GON(GetDefaultPlayerClass(C)) );

    if( FindSpore(C.GetTeamNum()) == None )
        return;

    if( PODBot(C) != None )
        PODBot(C).ChoosePlayerClass();

    C.PawnClass = GetDefaultPlayerClass(C);

    Super.RestartPlayer(C);
}

function Controller FindLivingPlayer( int TeamNum )
{
    local Controller C;

    for( C=Level.ControllerList; C!=None; C=C.NextController )
    {
        if( C.PlayerReplicationInfo != None
        &&  C.bIsPlayer
        &&  C.Pawn != None
        &&  C.Pawn.Health > 0
        &&  C.GetTeamNum() == TeamNum )
        {
            return C;
        }
    }

    return None;
}


// ============================================================================
//  Scoring
// ============================================================================
function EndGame( PlayerReplicationInfo Winner, string Reason )
{
//    if ( Reason ~= "HeartDestroyed" )
//    {
//
//        if ( !CheckEndGame(Winner, Reason) )
//        {
//             bOverTime = true;
//             return;
//        }
//
//        bGameEnded = true;
//        TriggerEvent('EndGame', self, None);
//        EndLogging(Reason);
//
//    }

    if ( Reason ~= "OutOfTime" )
    {

        GameReplicationInfo.Winner = Teams[0];

        EndTime = Level.TimeSeconds + EndTimeDelay;
        SetEndGameFocus(Winner);

        bGameEnded = true;
        TriggerEvent('EndGame', self, None);
        EndLogging(Reason);

    }

    if ( (Reason ~= "EveryoneIsDead") || (Reason ~= "VirusDead") || (Reason ~= "NanoDead") )
    {

        if( Reason ~= "EveryoneIsDead" ) GameReplicationInfo.Winner = none;

        if( Reason ~= "VirusDead" ) {
            GameReplicationInfo.Winner = Teams[0];
        } else if( Reason ~= "NanoDead") {
            GameReplicationInfo.Winner = Teams[1];
        }

        EndTime = Level.TimeSeconds + EndTimeDelay;
        SetEndGameFocus(Winner);

        bGameEnded = true;
        TriggerEvent('EndGame', self, None);
        EndLogging(Reason);

    }

    if ( bGameEnded ) {

        GotoState('MatchOver');

    }



}

function CheckScore( PlayerReplicationInfo Scorer )
{
    local NavigationPoint N, Spores[2];
    local byte Team;

//    if( Heart.Health <= 0 )
//    {
//        EndGame(Scorer,"HeartDestroyed");
//    }

    for( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
    {
        if( PODSpore(N) != none
        &&  PODSpore(N).bActive )
        {
            Team = PODSpore(N).DefenderTeamIndex;
            if( Team == 0 || Team == 1 )
                Spores[Team] = N;
            if( Spores[0] != None && Spores[1] != None )
                break;
        }
    }

    if( Spores[0] == none && FindLivingPlayer(0) == none )
    {
        EndGame(Scorer, "NanoDead");
    }
    else if( Spores[1] == None && FindLivingPlayer(1) == None )
    {
        EndGame(Scorer, "VirusDead");
    }

}


function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
//    if( Reason ~= "HeartDestroyed" )
//    {
//         if ( Heart.Health <= 0 )
//         {
//              GameReplicationInfo.Winner = Teams[1];
//         }
//    }
//
//    if( Reason ~= "OutOfTime" )
//    {
//         if( RemainingTime <= 0 )
//         {
//             if ( Heart.Health <= 0 )
//                  GameReplicationInfo.Winner = Teams[1];
//             else if( Heart.Health > 0 )
//                  GameReplicationInfo.Winner = Teams[0];
//             else
//                  GameReplicationInfo.Winner = none;
//         }
//    }

    EndTime = Level.TimeSeconds + EndTimeDelay;
    SetEndGameFocus(Winner);
    return true;
}


function SetEndGameFocus(PlayerReplicationInfo Winner)
{
    local Controller C, NextC;
    local PlayerController PC;

    //xLog( "SetEndGameFocus" #GON(Winner) );

    if( Winner != None )
        EndGameFocus = Controller(Winner.Owner).Pawn;

    if( EndGameFocus != None )
        EndGameFocus.bAlwaysRelevant = true;


    // Reset ALL controllers first
    C = Level.ControllerList;
    while( C != None )
    {
        NextC = C.NextController;

        PC = PlayerController(C);
        if( PC != None )
        {
            if(!PC.PlayerReplicationInfo.bOnlySpectator )
                PlayWinMessage(PC, (PC.PlayerReplicationInfo.Team == GameReplicationInfo.Winner));

            PC.ClientSetBehindView(true);
            if( EndGameFocus != None )
            {
                PC.ClientSetViewTarget(EndGameFocus);
                PC.SetViewTarget(EndGameFocus);
            }

            if( CurrentGameProfile != None )
                CurrentGameProfile.bWonMatch = (PC.PlayerReplicationInfo.Team == GameReplicationInfo.Winner);

            PC.ClientGameEnded();
        }
        else
        {
            C.GameHasEnded(); // C is now None!
        }

        C = NextC;
    }
}


// ============================================================================
//  Navigation Network
// ============================================================================

function NavigationPoint FindPlayerStart( Controller Player, optional byte InTeam, optional string incomingName )
{
    local NavigationPoint N, BestStart;
    local Teleporter Tel;
    local float BestRating, NewRating;
    local byte Team;

    //xLog( "FindPlayerStart" #InTeam #GON(Player) #incomingName );

    if( Player != None && Player.StartSpot != None )
        LastPlayerStartSpot = Player.StartSpot;

    // always pick StartSpot at start of match
    if( Player != None && Player.StartSpot != None && Level.NetMode == NM_Standalone
    && (bWaitingToStartMatch || (Player.PlayerReplicationInfo != None && Player.PlayerReplicationInfo.bWaitingPlayer))  )
    {
        return Player.StartSpot;
    }

    if( GameRulesModifiers != None )
    {
        N = GameRulesModifiers.FindPlayerStart(Player,InTeam,incomingName);
        if( N != None )
            return N;
    }

    // if incoming start is specified, then just use it
    if( incomingName!="" )
        foreach AllActors( class 'Teleporter', Tel )
            if( string(Tel.Tag)~=incomingName )
                return Tel;

    // use InTeam if player doesn't have a team yet
    if( Player != None && Player.PlayerReplicationInfo != None )
    {
        if( Player.PlayerReplicationInfo.Team != None )
            Team = Player.PlayerReplicationInfo.Team.TeamIndex;
        else
            Team = InTeam;
    }
    else
        Team = InTeam;

    BestRating = PSR_Invalid;
    for( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
    {
        NewRating = RatePlayerStart(N,Team,Player);
        //xLog( "RatePlayerStart" #GON(N) #Team #GON(Player) #NewRating );
        if( NewRating > BestRating && NewRating != PSR_Invalid )
        {
            BestRating = NewRating;
            BestStart = N;
        }
    }

    if( BestStart == None )
    {
        BestRating = PSR_Invalid;
        ForEach AllActors( class 'NavigationPoint', N )
        {
            NewRating = RatePlayerStart(N,Team,Player);
            //xLog( "RatePlayerStart" #GON(N) #Team #GON(Player) #NewRating );
            if( NewRating > BestRating && NewRating != PSR_Invalid )
            {
                BestRating = NewRating;
                BestStart = N;
            }
        }
    }

    if( BestStart != None )
        LastStartSpot = BestStart;

    return BestStart;
}


function float RatePlayerStart( NavigationPoint N, byte Team, Controller Player )
{
    local PODSpore S;
    local float Score;

    S = PODSpore(N);
    if( S == None
    || !S.bActive
    ||  S.DefenderTeamIndex != Team )
        return PSR_Invalid;

    Score -= FRand();
    if( Player != None )
        Score -= VSize(S.Location - Player.Location);

    return Score;
}


function NavigationPoint FindSpore( byte TeamNum )
{
    local NavigationPoint N;

    for( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
    {
        if( PODSpore(N) != None
        &&  PODSpore(N).bActive
        &&  PODSpore(N).DefenderTeamIndex == TeamNum )
        {
            return N;
        }
    }

    return None;
}


// ============================================================================
//  Messages
// ============================================================================

event BroadcastLocalizedTeam( Controller Sender, class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
    local Controller C;
    local PlayerController P;

    if( BroadCastHandler.bPartitionSpectators
    && !bGameEnded
    &&  Sender != None
    && !Sender.PlayerReplicationInfo.bAdmin
    && (Sender.PlayerReplicationInfo.bOnlySpectator || Sender.PlayerReplicationInfo.bOutOfLives) )
    {
        For( C=Level.ControllerList; C!=None; C=C.NextController )
        {
            P = PlayerController(C);
            if( P != None
            &&  P.PlayerReplicationInfo.Team == Sender.PlayerReplicationInfo.Team
            && (P.PlayerReplicationInfo.bOnlySpectator || P.PlayerReplicationInfo.bOutOfLives) )
                BroadCastHandler.BroadcastLocalized(Sender, P, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
        }
    }
    else
    {
        For( C=Level.ControllerList; C!=None; C=C.NextController )
        {
            P = PlayerController(C);
            if( P != None
            &&  P.PlayerReplicationInfo.Team == Sender.PlayerReplicationInfo.Team )
                BroadCastHandler.BroadcastLocalized(Sender, P, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
        }
    }
}


// ============================================================================
//  Inventory
// ============================================================================
function AddGameSpecificInventory(Pawn p)
{
    local Inventory Inv;

    Super.AddGameSpecificInventory(p);

    For ( Inv=P.Inventory; Inv!=None; Inv=Inv.Inventory )
    {
        if( Weapon(Inv) != None )
            Weapon(Inv).MaxOutAmmo();
    }
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

final static function nLog ( coerce string s )
{
    Log( s, default.name );
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

    GameName                        = "POD"

    SpawnProtectionTime             = 7.500000

    bAllowVehicles                  = True
    bLiberalVehiclePaths            = True
    bAlwaysShowLoginMenu            = True

    HUDType                         = "POD.PODHud"
    DefaultPlayerClassName          = "POD.PODKVehicle"
    ScoreboardType                  = "POD.PODScoreboard"
    PlayerControllerClassName       = "POD.PODPlayer"
    MapListType                     = "POD.PODMapList"
    RedTeamName                     = "POD.PODTeamInfoNano"
    BlueTeamName                    = "POD.PODTeamInfoVirus"
    LoginMenuClass                  = "POD.PODLoginMenu"
    GameUMenuType                   = "POD.PODLoginMenu"

    GameReplicationInfoClass        = Class'POD.PODGRI'
    TeamAIType(0)                   = class'POD.PODTeamAI'
    TeamAIType(1)                   = class'POD.PODTeamAI'
}
