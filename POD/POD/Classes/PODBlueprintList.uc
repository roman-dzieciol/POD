// ============================================================================
//  PODBlueprintList.uc ::
// ============================================================================
class PODBlueprintList extends PODObject;

var bool bInit;
var array< class<PODBlueprint> > BP; // 255 max, 0 is reserved


static function class<PODBlueprint> GetClass( byte i )
{
    return default.BP[i];
}

static function byte GetIndex( class<PODBlueprint> c )
{
    if( !default.bInit )
        InitClasses();

    if( c != None )
        return c.default.Index;

    return 0;
}

static function InitClasses()
{
    local int i;

    for( i=1; i!=default.BP.Length; ++i )
    {
        default.BP[i].default.Index = i;
    }

    default.bInit = True;
}

DefaultProperties
{
    BP(0)=None
    BP(1)=class'PODBPTurret'
    BP(2)=class'PODBPAttractor'
}
