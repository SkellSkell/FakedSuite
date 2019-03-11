class FSBroadcastHandler extends BroadcastHandler;

var BroadcastHandler NextBroadcaster;
var FSMut MutRef;

function Broadcast( Actor Sender, coerce string Msg, optional name Type )
{
	local string CommandResponse;

	if((Type=='Say' || Type=='TeamSay') && Left(Msg,1)=="!" && KFPlayerController(Sender)!=None)
	{
		if(MutRef.ProcessCommand(Mid(Msg,1),KFPlayerController(Sender), CommandResponse))
		{
			KFPlayerController(Sender).ClientMessage(CommandResponse);
			return;
		}
	}

	NextBroadcaster.Broadcast(Sender,Msg,Type);
}

function BroadcastTeam( Controller Sender, coerce string Msg, optional name Type )
{
	local string CommandResponse;

	if( (Type=='Say' || Type=='TeamSay') && Left(Msg,1)=="!" && KFPlayerController(Sender)!=None )
	{
		if(MutRef.ProcessCommand(Mid(Msg,1),KFPlayerController(Sender), CommandResponse))
		{
			KFPlayerController(Sender).ClientMessage(CommandResponse);
			return;
		}
	}

	NextBroadcaster.BroadcastTeam(Sender,Msg,Type);
}

//--------
//Delegate everything else to regular broadcaster.
//--------

function UpdateSentText()
{
	NextBroadcaster.UpdateSentText();
}

function bool AllowsBroadcast( actor broadcaster, int InLen )
{
	return NextBroadcaster.AllowsBroadcast(Broadcaster, InLen);
}

function BroadcastText( PlayerReplicationInfo SenderPRI, PlayerController Receiver, coerce string Msg, optional name Type )
{
	NextBroadcaster.BroadcastText(SenderPRI, Receiver, Msg, Type);
}

function BroadcastLocalized( Actor Sender, PlayerController Receiver, class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	NextBroadcaster.BroadcastLocalized(Sender, Receiver, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}

function AllowBroadcastLocalized( actor Sender, class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	NextBroadcaster.AllowBroadcastLocalized(Sender,Message,Switch,RelatedPRI_1,RelatedPRI_2,OptionalObject);
}

event AllowBroadcastLocalizedTeam( int TeamIndex, actor Sender, class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	NextBroadcaster.AllowBroadcastLocalizedTeam(TeamIndex,Sender,Message,Switch,RelatedPRI_1,RelatedPRI_2,OptionalObject);
}

defaultproperties
{
}