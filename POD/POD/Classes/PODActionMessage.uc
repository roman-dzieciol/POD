class PODActionMessage extends PODMessage;

var(Message) localized string NoEnergyString;
var(Message) color YellowColor, RedColor;

static function color GetColor(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2
	)
{
	if (Switch == 0)
		return Default.YellowColor;
	else
		return Default.RedColor;
}

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	return Default.NoEnergyString;
}


defaultproperties
{
     NoEnergyString="You do not have enough energy!"
     RedColor=(R=255,A=255)
     YellowColor=(G=255,R=255,A=255)
     bIsPartiallyUnique=True
     bIsConsoleMessage=False
     bFadeMessage=True
     Lifetime=3
     DrawColor=(G=160,R=0)
     StackMode=SM_Down
     PosY=0.200000
     FontSize=1
}
