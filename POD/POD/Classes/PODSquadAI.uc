// ============================================================================
//  PODSquadAI.uc ::
// ============================================================================
class PODSquadAI extends SquadAI;


function bool OverrideFollowPlayer(Bot B)
{
    if( PODTeamAI(Team.AI).TryNearbyObjective(B,True) != None )
        return true;

    return false;
}

function RemovePlayer(PlayerController P)
{
    local GameObjective NewObjective;
    if ( SquadLeader != P )
        return;
    if ( SquadMembers == None )
    {
        destroy();
        return;
    }

    PickNewLeader();
    NewObjective = PODTeamAI(Team.AI).GetClosestObjective(SquadLeader);
    if( NewObjective != SquadObjective )
    {
        SquadObjective = NewObjective;
        NetUpdateTime = Level.Timeseconds - 1;
    }
}

function name GetOrders()
{
    local name NewOrders;

    if( PlayerController(SquadLeader) != None )
        NewOrders = 'Human';
    else
        NewOrders = 'Attack';

    if( NewOrders != CurrentOrders )
    {
        //xLog( "GetOrders" #CurrentOrders #NewOrders );
        NetUpdateTime = Level.Timeseconds - 1;
        CurrentOrders = NewOrders;
    }

    return CurrentOrders;
}

// Never ever defend!
function SetObjective(GameObjective O, bool bForceUpdate)
{
    local bot M;

    //Log(SquadLeader.PlayerReplicationInfo.PlayerName$" SET OBJECTIVE"@O@"Forced update"@bForceUpdate);
    if( SquadObjective == O )
    {
        if( SquadObjective == None )
            return;
        if( !bForceUpdate )
            return;
    }
    else
    {
        NetUpdateTime = Level.Timeseconds - 1;
        SquadObjective = O;
        if( SquadObjective != None )
        {
            SetAlternatePath(true);
        }
    }
    for ( M=SquadMembers; M!=None; M=M.NextSquadMember )
        if ( M.Pawn != None )
            Retask(M);
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
    MaxSquadSize        = 2
     RestingFormationClass=Class'POD.PODRestingFormation'
}
