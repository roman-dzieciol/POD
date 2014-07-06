// ============================================================================
//  PODBot.uc ::
// ============================================================================
class PODBot extends xBot;


function class<PODBlueprint> ChooseBlueprint( PODBuildSpot S )
{
    return class'PODBPTurret';
}

// ============================================================================
//  PlayerClass
// ============================================================================
function ChoosePlayerClass()
{
    local PODPRI PRI;

    PRI = PODPRI(PlayerReplicationInfo);
    if( PRI != None )
    {
        if( FRand() < 0.66 )
        {
            // Engineer
            PRI.PlayerClassByte = 0;
        }
        else
        {
            if( FRand() < 0.5 )
            {
                // Medic
                PRI.PlayerClassByte = 1;
            }
            else
            {
                // Soldier
                PRI.PlayerClassByte = 2;
            }
        }
    }

}

simulated function class<PODPlayerClass> GetPlayerClass()
{
    local PODPRI PRI;

    PRI = PODPRI(PlayerReplicationInfo);
    if( PRI != None )
        return PRI.GetPlayerClass();

    return None;
}

// ============================================================================
//  Pawn
// ============================================================================
function Possess(Pawn Other)
{
    Super.Possess(Other);
    if( PODKVehicle(Other) != None )
        PODKVehicle(Other).SetupPlayerClass();

    if( GetOrders() == 'Attack' && Squad != None && Squad.SquadLeader == self )
    {
        Squad.SetObjective( PODTeamAI(UnrealTeamInfo(PlayerReplicationInfo.Team).AI).GetClosestObjective(self), True );
        WhatToDoNext(1);
    }
}

function SetPawnClass(string inClass, string inCharacter)
{
}


// ============================================================================
//  States
// ============================================================================

// ----------------------------------------------------------------------------
//  RangedAttack
// ----------------------------------------------------------------------------
state RangedAttack
{
ignores SeePlayer, HearNoise, Bump;

    function bool Stopped()
    {
        return true;
    }

    function bool IsShootingObjective()
    {
        return (Target != None && (Target == Squad.SquadObjective || Target.Owner == Squad.SquadObjective));
    }

    function CancelCampFor(Controller C)
    {
        DoTacticalMove();
    }

    function StopFiring()
    {
        if ( (Pawn != None) && Pawn.RecommendLongRangedAttack() && Pawn.IsFiring() )
            return;
        Global.StopFiring();
        if ( bHasFired )
        {
            if ( IsSniping() )
                Pawn.bWantsToCrouch = (Skill > 2);
            else
            {
                bHasFired = false;
                WhatToDoNext(32);
            }
        }
    }

    function EnemyNotVisible()
    {
        //let attack animation complete
        if ( (Target == Enemy) && !Pawn.RecommendLongRangedAttack() )
            WhatToDoNext(33);
    }

    function Timer()
    {
        if ( (Pawn.Weapon != None) && Pawn.Weapon.bMeleeWeapon )
        {
            SetCombatTimer();
            StopFiring();
            WhatToDoNext(34);
        }
        else if ( Target == Enemy )
            TimedFireWeaponAtEnemy();
        else
            FireWeaponAt(Target);
    }

    function DoRangedAttackOn(Actor A)
    {
        if ( (Pawn.Weapon != None) && Pawn.Weapon.FocusOnLeader(false) )
            Target = Focus;
        else
            Target = A;
        GotoState('RangedAttack');
    }

    function BeginState()
    {
        StopStartTime = Level.TimeSeconds;
        bHasFired = false;
        if ( (Pawn.Physics != PHYS_Flying) || (Pawn.MinFlySpeed == 0) )
        {
            Pawn.Acceleration = vect(0,0,0); //stop
            MoveTimer = -1.0;
        }
        if ( Vehicle(Pawn) != None )
        {
            Vehicle(Pawn).Steering = 0;
            Vehicle(Pawn).Throttle = 0;
            Vehicle(Pawn).Rise = 0;
        }
        if ( (Pawn.Weapon != None) && Pawn.Weapon.FocusOnLeader(false) )
            Target = Focus;
        else if ( Target == None )
            Target = Enemy;
        if ( Target == None )
            log(GetHumanReadableName()$" no target in ranged attack");
    }

Begin:
    bHasFired = false;
    if ( (Pawn.Weapon != None) && Pawn.Weapon.bMeleeWeapon )
        SwitchToBestWeapon();
    GoalString = GoalString@"Ranged attack";
    Focus = Target;
    Sleep(0.0);
    if ( Target == None )
        WhatToDoNext(335);

    if ( Enemy != None )
        CheckIfShouldCrouch(Pawn.Location,Enemy.Location, 1);
    if ( NeedToTurn(Target.Location) )
    {
        Focus = Target;
        FinishRotation();
    }
    bHasFired = true;
    if ( Target == Enemy )
        TimedFireWeaponAtEnemy();
    else
        FireWeaponAt(Target);
    Sleep(0.1);
    if ( ((Pawn.Weapon != None) && Pawn.Weapon.bMeleeWeapon) || (Target == None) || ((Target != Enemy) && (GameObjective(Target) == None) && (Enemy != None) && EnemyVisible()) )
        WhatToDoNext(35);
    if ( Enemy != None )
        CheckIfShouldCrouch(Pawn.Location,Enemy.Location, 1);
    Focus = Target;
    Sleep(FMax(Pawn.RangedAttackTime(),0.2 + (0.5 + 0.5 * FRand()) * 0.4 * (7 - Skill)));
    WhatToDoNext(36);
    if ( bSoaking )
        SoakStop("STUCK IN RANGEDATTACK!");
}


// ----------------------------------------------------------------------------
//  VehicleCharging
// ----------------------------------------------------------------------------
state VehicleCharging
{
    ignores SeePlayer, HearNoise;

    function Timer()
    {
        Target = Enemy;
        TimedFireWeaponAtEnemy();
    }

    function FindDestination()
    {
        // SW: Charge MoveTarget

        if ( MoveTarget == None )
        {
            Destination = Pawn.Location;
            return;
        }

        Destination = MoveTarget.Location - Normal(MoveTarget.Location-Pawn.Location)*128;
    }

    function EnemyNotVisible()
    {
        WhatToDoNext(15);
    }

Begin:
    if ( Enemy == None )
        WhatToDoNext(16);

    // SW: unreachable code removed

    if ( VSize(Enemy.Location - Pawn.Location) < 1200 )
    {
        FindDestination();
        MoveTo(Destination, None, false);
        if ( Enemy == None )
            WhatToDoNext(91);
    }
    MoveTarget = Enemy;

Moving:
    FireWeaponAt(Enemy);
    MoveToward(MoveTarget,FaceActor(1),,ShouldStrafeTo(MoveTarget));
    WhatToDoNext(17);
    if( bSoaking )
        SoakStop("STUCK IN VEHICLECHARGING!");
}




// ============================================================================
//  Debug
// ============================================================================
final simulated function xLog ( coerce string s )
{
    Log
    (   "[" $Left("00",2-Len(Level.Second)) $Level.Second $":"
            $Left("000",3-Len(Level.Millisecond)) $Level.Millisecond $"]"
    @   "[" $StrShort(GetStateName()) $"]"
    @   s
    ,   name );
}

final static function string StrShort( coerce string s )
{
    local string r,c;
    local int i,n;

    c = Caps(s);
    n = Len(s);

    for( i=0; i!=n; ++i )
        if( Mid(s,i,1) == Mid(c,i,1) )
            r $= Mid(s,i,1);

    return r;
}

final static operator(112) string # ( coerce string A, coerce string B )
{
    return A @"[" $B $"]";
}

final static function name GON( Object O )
{
    if( O != None ) return O.Name;
    else            return 'None';
}

final simulated function string GPT( string S )
{
    return GetPropertyText(S);
}

// ============================================================================
//  DefaultProperties
// ============================================================================
DefaultProperties
{
    PawnClass                       = class'PODKVehicle'
    PlayerReplicationInfoClass      = Class'PODPRI'
}
