// ============================================================================
//  PODPlayerClass.uc ::
// ============================================================================
class PODPlayerClass extends PODObject;

var() localized string ClassName;
var() localized string ClassTeamName;
var() localized string Description;

var() class<PODTeamInfo> TeamClass;
var() array<string> Equipment;

var() float Shield;
var() float ShieldMax;
var() float ShieldRegen;

var() float Health;
var() float HealthMax;
var() float HealthRegen;

var() float Energy;
var() float EnergyMax;
var() float EnergyRegen;

var() float LinearSpeed;
var() float AngularSpeed;

var() float LinearAccel;
var() float AngularAccel;

var() class<Pawn> PawnClass;


// ============================================================================
//  DefaultProperties
// ============================================================================
DefaultProperties
{
    Shield              = 1.0
    ShieldMax           = 1.0
    ShieldRegen         = 1.0

    Health              = 1.0
    HealthMax           = 1.0
    HealthRegen         = 1.0

    Energy              = 1.0
    EnergyMax           = 1.0
    EnergyRegen         = 1.0

    LinearSpeed         = 1.0
    AngularSpeed        = 1.0

    LinearAccel         = 1.0
    AngularAccel        = 1.0


//    Equipment(1)        = "POD.PODAntiBioGun"
//    Equipment(2)        = "POD.PODShieldGun"
//    Equipment(3)        = "POD.PODNeedlerGun"
//    Equipment(4)        = "POD.PODRazorGun"
//    Equipment(5)        = "POD.PODSprayGun"
//    Equipment(6)        = "POD.PODMineGun"
//    Equipment(7)        = "POD.PODInjectGun"
}
