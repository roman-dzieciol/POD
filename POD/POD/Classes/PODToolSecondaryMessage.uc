// ============================================================================
//  PODToolSecondaryMessage.uc ::
// ============================================================================
class PODToolSecondaryMessage extends PODToolboxMessage;

var localized string Modes[8];


static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo PRI1,
    optional PlayerReplicationInfo PRI2,
    optional Object O
    )
{
    local string ObjName;
    local int a,b,n;

    class'PODUtil'.static.UnPackInt4(Switch,a,b,n,n);

    switch( a )
    {
        case 0:
            return "";

        case 1:
            ObjName = GetOptionalObjectName(Switch,PRI1,PRI2,class'PODBlueprintList'.static.GetClass(b));
            break;

        default:
            ObjName = GetOptionalObjectName(Switch,PRI1,PRI2,O);
            break;
    }

    return Repl(default.Modes[a],"%o",ObjName,true);
}

DefaultProperties
{
    Modes(0)        = "INVALID"
    Modes(1)        = "Press [ALT-FIRE] to select %o"
}
