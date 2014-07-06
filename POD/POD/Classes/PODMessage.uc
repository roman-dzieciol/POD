// ============================================================================
//  PODMessage.uc ::
// ============================================================================
class PODMessage extends LocalMessage;

var localized string UnknownObjectName;

static function string GetOptionalObjectName(
    optional int Switch,
    optional PlayerReplicationInfo PRI1,
    optional PlayerReplicationInfo PRI2,
    optional Object O
    )
{
    local string ObjName;

    if( O == None )
        ObjName = default.UnknownObjectName;
    else if( Actor(O) != None )
        ObjName = Actor(O).GetHumanReadableName();
    else if( class<PODBlueprint>(O) != None )
        ObjName = class<PODBlueprint>(O).default.ItemName;
    else if( class<Actor>(O) != None )
        ObjName = class<Actor>(O).static.GetLocalString(Switch,PRI1,PRI2);

    if( ObjName == "" )
        ObjName = default.UnknownObjectName;

    return ObjName;
}

DefaultProperties
{

    UnknownObjectName       = "unknown object"

}
