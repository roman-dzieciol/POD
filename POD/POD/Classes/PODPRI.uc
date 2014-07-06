class PODPRI extends PlayerReplicationInfo
    config;


var byte PlayerClassByte;

// ============================================================================
//  Replication
// ============================================================================
replication
{
    // Variables server should send to client
    reliable if ( bNetDirty && Role == ROLE_Authority )
        PlayerClassByte;
}


// ============================================================================
//  PlayerClass
// ============================================================================

simulated function class<PODPlayerClass> GetPlayerClass()
{
    local PODTeamInfo T;

    T = PODTeamInfo(Team);
    if( T != None )
        return T.GetPlayerClass(PlayerClassByte);

    return None;
}

function class<Pawn> GetPawnClass()
{
    local class<PODPlayerClass> PC;

    PC = GetPlayerClass();
    if( PC != None )
        return PC.default.PawnClass;

    return None;
}


// ============================================================================
//  DefaultProperties
// ============================================================================
DefaultProperties
{
}
