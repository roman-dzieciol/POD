// ============================================================================
//  PODTeamInfo.uc ::
// ============================================================================
class PODTeamInfo extends UnrealTeamInfo;


var() array< class<PODPlayerClass> > ClassList;

var array<int> NameUsage;

function PostBeginPlay()
{
    NameUsage.Length = RosterNames.Length;
    Super.PostBeginPlay();
}

simulated function class<PODPlayerClass> GetPlayerClass( byte Type )
{
    Type = Min( Type, ClassList.Length-1 );
    return ClassList[Type];
}

function string GetBotName()
{
    local int i;

    // Try random
    i = Rand(NameUsage.Length);
    if( NameUsage[i] == 0 )
    {
        ++NameUsage[i];
        return RosterNames[i];
    }

    // Try first unused
    for( i=0; i!=NameUsage.Length; ++i)
    {
        if( NameUsage[i] == 0 )
        {
            ++NameUsage[i];
            return RosterNames[i];
        }
    }

    // Use random with postfix
    i = Rand(NameUsage.Length);
    return RosterNames[i]$(++NameUsage[i]);
}

function AddRandomPlayer()
{
}

function AddNamedBot(string BotName)
{
}

function RosterEntry GetNextBot()
{
    return None;
}

function RosterEntry GetNamedBot(string botName)
{
    return None;
}


DefaultProperties
{

}
