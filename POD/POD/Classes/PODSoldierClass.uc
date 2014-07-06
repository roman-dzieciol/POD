// ============================================================================
//  PODSoldierClass.uc ::
// ============================================================================
class PODSoldierClass extends PODPlayerClass;



DefaultProperties
{
    ClassName           = "Soldier"
    ClassTeamName       = "Soldier"

    Shield             = 2.0
    ShieldMax          = 2.0
    ShieldRegen        = 0.0

    Health              = 2.0
    HealthMax           = 2.0
    HealthRegen         = 0.0

    Energy              = 1.0
    EnergyMax           = 1.0
    EnergyRegen         = 0.5

    PawnClass           = class'PODPawnSoldier'

    LinearSpeed         = 1.0
    AngularSpeed        = 1.0

    LinearAccel         = 1.0
    AngularAccel        = 1.0

    Equipment(0)        = "POD.PODSoldierToolGun"
    Equipment(1)        = "POD.PODNeedlerGun"
    Equipment(2)        = "POD.PODAntiBioGun"
}
