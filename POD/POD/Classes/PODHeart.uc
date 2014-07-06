class PODHeart extends Decoration
      placeable;

function TakeDamage( int NDamage, Pawn instigatedBy, Vector hitlocation,
                    Vector momentum, class<DamageType> damageType)
{

      // Make the heart immune to strikes from NanoBot's.
      if( instigatedBy.PlayerReplicationInfo.Team.TeamIndex != 0 ) {

          super.TakeDamage( NDamage, instigatedBy, hitlocation, momentum, damageType);
          PODGame(Level.Game).CheckScore(instigatedBy.PlayerReplicationInfo);

      }

}

defaultproperties
{
     Health=100
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'PODSM_Bio.Heart'
     DrawScale=6.0
     bStatic=True
     bAlwaysRelevant=True
     bCollideActors=True
     bBlockActors=True
     bProjTarget=True
     bBlockKarma=True
     bNetNotify=True
     CollisionRadius=400.000000
     CollisionHeight=400.000000
     bPathColliding=True
     bDynamicLight=True
     bDamageable=True
     NetUpdateFrequency=1.0
}
