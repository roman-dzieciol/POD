// ============================================================================
//  PODToolPackedMessage.uc ::
// ============================================================================
class PODToolPackedMessage extends PODMessage;

var class<LocalMessage> PrimaryMessage;
var class<LocalMessage> SecondaryMessage;

static function ClientReceive(
    PlayerController P,
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    local int a,b;

    class'PODUtil'.static.UnPackInt2(Switch,a,b);

    default.PrimaryMessage.Static.ClientReceive( P, a, RelatedPRI_1, RelatedPRI_2, OptionalObject );
    default.SecondaryMessage.Static.ClientReceive( P, b, RelatedPRI_1, RelatedPRI_2, OptionalObject );
}

DefaultProperties
{
    PrimaryMessage          = class'PODToolPrimaryMessage'
    SecondaryMessage        = class'PODToolSecondaryMessage'
    bIsConsoleMessage       = False
}
