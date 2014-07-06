class PODGRI extends GameReplicationInfo
      config(PODData);

var vector HeartPos;
var int HeartTHealth;
var PODHeart Heart;

replication
{
  reliable if( bNetDirty && (Role == Role_Authority))
    HeartTHealth;
  reliable if( Role == Role_Authority)
    HeartPos;
}

defaultproperties {
}
