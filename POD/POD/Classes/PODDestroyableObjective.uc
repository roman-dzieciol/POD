// ============================================================================
//  PODDestroyableObjective.uc ::
// ============================================================================
class PODDestroyableObjective extends DestroyableObjective;


function bool BetterObjectiveThan( GameObjective Best, byte DesiredTeamNum, byte RequesterTeamNum )
{
    if( !IsActive() || DefenderTeamIndex != DesiredTeamNum )
        return false;

    if( Best == None || Best.DefensePriority < DefensePriority )
        return true;

    return false;
}

simulated function bool IsValidTarget( Pawn P )
{
    return false;
}

function bool TellBotHowToHeal(Bot B)
{
    return B.Squad.FindPathToObjective(B,self);
}

function bool TellBotHowToDisable(Bot B)
{
    return B.Squad.FindPathToObjective(B,self);
}

simulated function PlayDestructionMessage()
{
    local PlayerController  PC;

    if ( DestructionMessage == default.DestructionMessage && DefenderTeamIndex < ArrayCount(Level.GRI.Teams) )
        DestructionMessage = Level.GRI.Teams[DefenderTeamIndex].TeamName@DestructionMessage;

    if( !bReplicateObjective )
    {
        Level.Game.Broadcast(Self, DestructionMessage, 'CriticalEvent');
        return;
    }

    PC = Level.GetLocalPlayerController();
    if( PC != None )
        PC.TeamMessage(PC.PlayerReplicationInfo, DestructionMessage, 'CriticalEvent');
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
    @   "#" $DefenderTeamindex
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
     bVehicleDestination=True
     bFlyingPreferred=True
}
