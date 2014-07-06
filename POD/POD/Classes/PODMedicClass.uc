// ============================================================================
//  PODMedicClass.uc ::
// ============================================================================
class PODMedicClass extends PODPlayerClass;



DefaultProperties
{
    ClassName           = "Medic"
    ClassTeamName       = "Medic"

    Shield             = 1.0
    ShieldMax          = 1.0
    ShieldRegen        = 1.0

    Health              = 1.0
    HealthMax           = 1.0
    HealthRegen         = 1.0

    Energy              = 1.5
    EnergyMax           = 1.5
    EnergyRegen         = 0.75

    PawnClass           = class'PODPawnMedic'

    LinearSpeed         = 1.75
    AngularSpeed        = 1.75

    LinearAccel         = 1.75
    AngularAccel        = 1.75

    Equipment(0)        = "POD.PODMedicToolGun"
    Equipment(1)        = "POD.PODInjectGun"
    Equipment(2)        = "POD.PODSprayGun"
}
