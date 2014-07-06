// ============================================================================
//  PODEngineerClass.uc ::
// ============================================================================
class PODEngineerClass extends PODPlayerClass;



DefaultProperties
{
    ClassName           = "Engineer"
    ClassTeamName       = "Engineer"

    Shield             = 1.5
    ShieldMax          = 1.5
    ShieldRegen        = 1.0

    Health              = 1.0
    HealthMax           = 1.0
    HealthRegen         = 0.0

    Energy              = 2.0
    EnergyMax           = 2.0
    EnergyRegen         = 1.0

    PawnClass           = class'PODPawnEngineer'

    LinearSpeed         = 1.5
    AngularSpeed        = 1.5

    LinearAccel         = 1.5
    AngularAccel        = 1.5

    Equipment(0)        = "POD.PODEngineerToolGun"
    Equipment(1)        = "POD.PODNeedlerGun"
    Equipment(2)        = "POD.PODShieldGun"
    Equipment(3)        = "POD.PODRazorGun"
}
