// ============================================================================
//  PODToolPrimaryMessage.uc ::
// ============================================================================
class PODToolPrimaryMessage extends PODToolboxMessage;

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

        case 2:
        case 4:
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
    Modes(1)        = "Hold [FIRE] to capture %o"
    Modes(2)        = "Hold [FIRE] to build %o"
    Modes(3)        = "Hold [FIRE] to heal %o"
    Modes(4)        = "%o can't be built at this spot."
}
