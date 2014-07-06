// ============================================================================
//  PODRestingFormation.uc ::
// ============================================================================
class PODRestingFormation extends RestingFormation;

function vector GetLocationFor(int Pos, Bot B)
{
    local Actor Center;

    Center = SquadAI(Owner).FormationCenter();
    if( Center == None )
        return B.Pawn.Location;

    return Center.Location - Normal(Center.Location-B.Pawn.Location)*FormationSize;
}

DefaultProperties
{
     FormationSize=750.000000
}
