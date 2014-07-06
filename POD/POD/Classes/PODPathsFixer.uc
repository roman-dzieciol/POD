// ============================================================================
//  PODPathsFixer.uc ::
// ============================================================================
class PODPathsFixer extends BrushBuilder;

event bool Build()
{
    local ReachSpec R;
    local int i;

    foreach AllObjects(class'ReachSpec',R)
    {
        R.reachFlags = (R.reachFlags & 0xFFFFFFF0) + 0x2;
        ++i;
    }

    Log("UPDATED" @i @"REACHSPECS", class.name);
    return BadParameters("UPDATED" @i @"REACHSPECS");
}


DefaultProperties
{
     BitmapFilename="BBGeneric"
     ToolTip="POD Paths Fixer"

}
