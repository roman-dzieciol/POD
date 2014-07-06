// ============================================================================
//  PODBlueprint.uc ::
// ============================================================================
class PODBlueprint extends PODObject
    abstract;

var() localized string ItemName;
var() class<Actor> ItemClass;
var() StaticMesh EmitterMesh;
var() float EmitterScale;
var() vector EmitterOffset;
var() vector ItemOffset;
var   byte Index;

DefaultProperties
{
    EmitterScale=1.0
    Index=0
}
