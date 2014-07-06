// ============================================================================
//  PODTeamAI.uc ::
// ============================================================================
class PODTeamAI extends TeamAI;

function SetBotOrders(Bot NewBot, RosterEntry R)
{
    local SquadAI HumanSquad;
    local name NewOrders;

    //xLog( "SetBotOrders" #GON(NewBot) #GON(R) );

    if( Objectives == None )
        SetObjectiveLists();

    if ( R==None || R.NoRecommendation() )
    {
        // pick orders
        if ( Team.Size == 0 )
            OrderOffset = 0;
        NewOrders = OrderList[OrderOffset % 8];
        OrderOffset++;
    }

    if ( NewOrders == 'FOLLOW' )
    {
        // Follow any human player
        HumanSquad = AddHumanSquad();
        if ( HumanSquad != None )
        {
            HumanSquad.AddBot(NewBot);
            return;
        }
    }
    PutOnOffense(NewBot);
}

// ============================================================================
//  Lifespan
// ============================================================================

function Timer()
{
    ReAssessStrategy();
}


// ============================================================================
//  What next
// ============================================================================

function ReAssessStrategy()
{
    local GameObjective O;

    if( FreelanceSquad == None )
        return;

    // Freelancers always attack
    FreelanceSquad.bFreelanceAttack = true;
    FreelanceSquad.bFreelanceDefend = false;
    O = GetClosestObjective(FreelanceSquad.SquadLeader);

    if( O != None && O != FreelanceSquad.SquadObjective )
        FreelanceSquad.SetObjective(O,true);
}

function FindNewObjectives(GameObjective DisabledObjective)
{
    local SquadAI S;

    if( PickedObjective != None && PickedObjective == DisabledObjective )
        PickedObjective = None;

    for( S=Squads; S!=None; S=S.NextSquad )
        if( S.SquadObjective == DisabledObjective )
            FindNewObjectiveFor(S,true);
}

function FindNewObjectiveFor(SquadAI S, bool bForceUpdate)
{
    local GameObjective O;

    //xLog( "FindNewObjectiveFor" #GON(S) #bForceUpdate );

    if( PlayerController(S.SquadLeader) != None )
        return;

    if( PODSpore(S.SquadObjective) != None )
    {
        // if just captured node, build defenses
        O = PODSpore(S.SquadObjective).GetSubObjective(Team.TeamIndex);
        if( O != None )
        {
            //xLog( "FindNewObjectiveFor #1" #GON(O) );
            S.SetObjective(O, bForceUpdate);
            return;
        }
    }
    else if( PODBuildSpot(S.SquadObjective) != None )
    {
        // if just built something, try again
        O = PODBuildSpot(S.SquadObjective).Spore.GetSubObjective(Team.TeamIndex);
        if( O != None )
        {
            //xLog( "FindNewObjectiveFor #2" #GON(O) );
            S.SetObjective(O, bForceUpdate);
            return;
        }
    }

    // kill'em all
    O = GetClosestObjective(S.SquadLeader);
    if( O != None )
    {
        //xLog( "FindNewObjectiveFor #3" #GON(O) );
        S.SetObjective(O, bForceUpdate);
        return;
    }

    S.SetObjective(None, bForceUpdate);
}


// ============================================================================
//  Assignment
// ============================================================================
function bool PutOnDefense(Bot B)
{
    PutOnOffense(B);
    return false;
}

function PutOnOffense(Bot B)
{
    //xLog( "PutOnOffense" #GON(B) #B.Pawn #B.StartSpot );
    if( AttackSquad == None || AttackSquad.Size >= AttackSquad.MaxSquadSize )
        AttackSquad = AddSquadWithLeader(B, GetClosestObjective(B));
    else
        AttackSquad.AddBot(B);
}

function PutOnFreelance(Bot B)
{
    PutOnOffense(B);
}


// ============================================================================
//  Acquisition
// ============================================================================

function GameObjective TryNearbyObjective( Bot B, optional bool bOnlyNearby )
{
    local GameObjective O;
    local array<GameObjective> Visible, Any;
    local int i;

    // Try nearby objectives
    for( O=Objectives; O!=None; O=O.NextObjective )
    {
        if( O.BotNearObjective(B) )
        {
            if( ProbeObjectiveFor(O,B) )
                return O;
        }
        else if( B.LineOfSightTo(O)  )
        {
            Visible[Visible.Length] = O;
        }
        else
        {
            Any[Any.Length] = O;
        }
    }

    // Try visible objectives
    for( i=0; i!=Visible.Length; ++i )
    {
        if( ProbeObjectiveFor(Visible[i],B) )
            return Visible[i];
    }

    if( bOnlyNearby )
        return None;

    // Try any other objectives
    for( i=0; i!=Any.Length; ++i )
    {
        if( ProbeObjectiveFor(Any[i],B) )
            return Any[i];
    }

    return None;
}

function bool ProbeObjectiveFor( GameObjective O, Bot B )
{
    if( O.DefenderTeamIndex == Team.TeamIndex )
    {
        if( DestroyableObjective(O) != None && DestroyableObjective(O).TellBotHowToHeal(B) )
            return true;
    }
    else if( O.TellBotHowToDisable(B) )
        return true;
    return false;
}

function GameObjective GetBestObjective()
{
    local byte TeamNum;
    local GameObjective O,Best;

    //xLog( "GetBestObjective" /*#GON(Best)*/ );

    TeamNum = Team.TeamIndex;
    for( O=Objectives; O!=None; O=O.NextObjective )
    {
        if( O.BetterObjectiveThan(Best,TeamNum,TeamNum) )
        {
            Best = O;
        }
    }
    return Best;
}

function GameObjective GetClosestObjective( Actor S )
{
    local byte TeamNum;
    local GameObjective O,Best;
    local vector Loc;
    local float Distance, BestDistance;

    if( Controller(S) != None )
    {
        if( Controller(S).Pawn != None )
            S = Controller(S).Pawn;
        //if( Bot(S).StartSpot != None )
        //    S = Bot(S).StartSpot;
    }

    //xLog( "GetClosestObjective" #GON(S) );

    if( S == None )
        return GetBestObjective();

    Loc = S.Location;
    TeamNum = Team.TeamIndex;
    BestDistance = 0x7FFFFFFF;

    for( O=Objectives; O!=None; O=O.NextObjective )
    {
        if( O.BetterObjectiveThan(None,TeamNum,TeamNum) )
        {
            Distance = VSize(Loc - O.Location);
            if( Distance < BestDistance )
            {
                BestDistance = Distance;
                Best = O;
            }
        }
    }
    return Best;
}


function GameObjective GetPriorityAttackObjectiveFor(SquadAI AttackSquad)
{
    return GetBestObjective();
}

function GameObjective GetPriorityAttackObjective()
{
    return GetBestObjective();
}

function GameObjective GetPriorityFreelanceObjective()
{
    return GetBestObjective();
}

function GameObjective GetLeastDefendedObjective()
{
    return GetBestObjective();
}

function GameObjective GetMostDefendedObjective()
{
    return GetBestObjective();
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
    SquadType           = Class'POD.PODSquadAI'

    OrderList(0)        = "Follow"
    OrderList(1)        = "Attack"
    OrderList(2)        = "Attack"
    OrderList(3)        = "Attack"
    OrderList(4)        = "Follow"
    OrderList(5)        = "Attack"
    OrderList(6)        = "Attack"
    OrderList(7)        = "Attack"
}
