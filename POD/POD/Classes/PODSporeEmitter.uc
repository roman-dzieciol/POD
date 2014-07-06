// ============================================================================
//  PODSporeEmitter.uc ::
// ============================================================================
class PODSporeEmitter extends PODConstructingEmitter;

var bool bLastState;

simulated function Timer()
{
    local bool b;

    if( DestroyableObjective(Owner) != None )
    {
        b = DestroyableObjective(Owner).bIsUnderAttack;
        if( b != bLastState )
        {
            if( b )
                SetBlueprint( class'PODBPSporeFX' );
            else
                SetBlueprint( None );
            bLastState = b;
        }
    }
}

DefaultProperties
{

}
