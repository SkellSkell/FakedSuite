//==================
//Faked Suite v1.0
//Builds off of Project One's code base to focus on faked players.
//==================
class FSMut extends KFMutator
	config(FakedSuite);

/* Faked player settings */
var config bool bFakedPlayers;
var config bool bFakedPlayersGiveHealth;
var config int FakedPlayerCount;

/* Max zed settings */
var config bool bChangeMaxMonsters;
var config int CustomMaxMonsters;

/* Base trader time settings */
var config bool bModifyBaseTraderTime;
var config int BaseTraderTime;

/* How much faster should spawns be? */
var config float SpawnRateModifier;

/* Should all zed teleporting be disabled? */
var config bool bDisableTeleport;

/* Should all special zeds be disabled? */
var config bool bDisableAlbino;

/* Deregulate spawning system? */
var config bool bNoSpawningCooldown;

/* Should changes done via chat commands save? */
var config bool bSaveCommandChanges;

/* Should Scrakes and Fleshpounds be pushed off until their appropriate waves? */
var config bool bEnforceFairSpawns;

/* Should zeds be allowed to randomly evade/block? */
var config bool bDisableEvadingAndBlocking;

struct MonsterDifficultyInfoData
{
	var class<Pawn> MC;
	var class<KFMonsterDifficultyInfo> DI;
};

var array<MonsterDifficultyInfoData> SwapList;

//For servers using commandline changes.
var config bool bSaveCommandLineChanges;

//Initialization var.
var config bool bConfigReady;

//Cached reference to FSGameInfo.
var FSGameInfo FSGI;

function PostBeginPlay()
{
	Super.PostBeginPlay();

	if(WorldInfo.Game.BaseMutator == None)
		WorldInfo.Game.BaseMutator = Self;
	else
		WorldInfo.Game.BaseMutator.AddMutator(Self);

	if(bDeleteMe)
		return;

	//If we can, set outselves to the gamemode.
	if(FSGameInfo(WorldInfo.Game) != None)
	{
		FSGI = FSGameInfo(WorldInfo.Game);
		FSGI.FSMut = Self;

		SetTimer(0.100000, false, 'InitGM');
		SetTimer(0.200000, false, 'SetupBroadcast');
	}
}

function AddMutator(Mutator M)
{
	if(M != Self)
	{
		if(M.Class==Class)
			M.Destroy();
		else
			Super.AddMutator(M);
	}
}

function bool CheckReplacement(Actor Other)
{
	if(bDisableTeleport && KFAIController(Other) != None)
		KFAIController(Other).bCanTeleportCloser = false;
	else if(KFPawn_Monster(Other) != None)
		ProcessMonster(KFPawn_Monster(Other));

	return true;
}

function ProcessMonster(KFPawn_Monster Monster)
{
	if(bDisableAlbino && static.DisableAlbino(Monster, bDisableEvadingAndBlocking))
		return;

	if(bDisableEvadingAndBlocking)
		static.DisableEvadeAndBlock(Monster);
}

//Returns true if a Monster Difficulty Info was changed.
static function bool DisableAlbino(KFPawn_Monster Monster, bool bDisableBlock)
{
	local bool bChangedMDI;

	bChangedMDI = false;

	if(bDisableBlock)
	{
		switch (Monster.Class)
		{
			case class'KFPawn_ZedCrawler':
				Monster.DifficultySettings = class'FSMDI_Crawler_NoVSBlock';
				bChangedMDI = true;
				break;
			case class'KFPawn_ZedClot_Alpha':
				Monster.DifficultySettings = class'FSMDI_ClotAlpha_NoVSBlock';
				bChangedMDI = true;
				break;
		}		
	}
	else
	{
		switch (Monster.Class)
		{
			case class'KFPawn_ZedCrawler':
				Monster.DifficultySettings = class'FSMDI_Crawler_NoVS';
				bChangedMDI = true;
				break;
			case class'KFPawn_ZedClot_Alpha':
				Monster.DifficultySettings = class'FSMDI_ClotAlpha_NoVS';
				bChangedMDI = true;
				break;
		}			
	}

	return bChangedMDI;
}

static function DisableEvadeAndBlock(KFPawn_Monster Monster)
{
	local int Index;

	Index = default.SwapList.Find('MC', Monster.Class);

	if(Index != INDEX_NONE)
		Monster.DifficultySettings = default.SwapList[Index].DI;
}

static final function FSMut GetMutRef(WorldInfo ThisWorldInfo)
{
	local Mutator M;
	local FSMut FSMut;

    if(ThisWorldInfo.Game != None)
    {
        for(M = ThisWorldInfo.Game.BaseMutator; M != None; M = M.NextMutator) 
        {
            FSMut = FSMut(M);

            if(FSMut != None)
                return FSMut;
        }
    }
   
    return None;
}

function SetupBroadcast()
{
	local FSBroadcastHandler B;
	B = Spawn(class'FSBroadcastHandler');
	B.MutRef = Self;
	B.NextBroadcaster = WorldInfo.Game.BroadcastHandler;
	WorldInfo.Game.BroadcastHandler = B;
}

//Returns true if a command was valid.
function bool ProcessCommand(string Command, KFPlayerController KFPC, out string CommandResponse)
{
	local bool bCommandSuccess;
	local array<string> CommandBreakdown;

	bCommandSuccess = false;
	CommandResponse = "Command processed...";

	ParseStringIntoArray(Command, CommandBreakdown, " ", true);

	if(KFPC == None || FSGI == None || CommandBreakdown.Length == 0
		|| (WorldInfo.NetMode != NM_Standalone && !KFPC.PlayerReplicationInfo.bAdmin))
		return false;

	if(CommandBreakdown[0] ~= "SetFakedPlayers")
	{
		bCommandSuccess = true;

		if(CommandBreakdown.Length > 1)
			SetFakedPlayers(true, int(CommandBreakdown[1]));
		else 
			SetFakedPlayers(false, 0);

		CommandResponse = "Faked player count has been changed to "$FSGI.FakedPlayerCount$"!";
	}
	else if(CommandBreakdown[0] ~= "SetFakedChangeHealth")
	{
		bCommandSuccess = true;
		CommandResponse = "!SetFakedChangeHealth inputs are only false/true or 0/1!";

		if(CommandBreakdown.Length == 1 || CommandBreakdown[1] ~= "false" || CommandBreakdown[1] ~= "0")
		{
			SetFakedPlayerHealth(false);
			CommandResponse = "Faked players no longer modify health!";
		}
		else if(CommandBreakdown[1] ~= "true" || CommandBreakdown[1] ~= "1")
		{
			SetFakedPlayerHealth(true);
			CommandResponse = "Faked players now modify health!";
		}
	}
	else if(CommandBreakdown[0] ~= "SetSpawnRateMod")
	{
		bCommandSuccess = true;

		if(CommandBreakdown.Length > 1)
			SetSpawnRateMod(float(CommandBreakdown[1]));
		else 
			SetSpawnRateMod(1.000000);

		CommandResponse = "Spawn rate modifier has been changed to "$FSGI.ZedSpawnRateModifier$"!";		
	}
	else if(CommandBreakdown[0] ~= "SetTraderTimeLeft")
	{
		bCommandSuccess = true;

		//Go straight to the function call in the GameInfo.
		if(CommandBreakdown.Length > 1)
			FSGI.ModifyTraderTime(int(CommandBreakdown[1]));
		else 
			FSGI.ModifyTraderTime(1);

		CommandResponse = "Current trader time set to "$FSGI.MyKFGRI.RemainingTime$"!";
	}
	else if(CommandBreakdown[0] ~= "SetBaseTraderTime")
	{
		bCommandSuccess = true;

		if(CommandBreakdown.Length > 1)
		{
			SetBaseTraderTime(true, int(CommandBreakdown[1]));
			FSGI.ClampDownTraderTime(int(CommandBreakdown[1]));
		}
		else
			SetBaseTraderTime(false);

		CommandResponse = "Base trader time set to "$FSGI.TimeBetweenWaves$"!";
	}
	else if(CommandBreakdown[0] ~= "EndTrader")
	{
		bCommandSuccess = true;

		FSGI.ClampDownTraderTime(1);

		CommandResponse = "Ending trader wave!";
	}
	else if(CommandBreakdown[0] ~= "SetMaxMonsters")
	{
		bCommandSuccess = true;

		if(CommandBreakdown.Length > 1)
		{
			SetMaxMonsters(true, int(CommandBreakdown[1]));
			CommandResponse = "Setting maximum alive zeds to "$FSGI.CustomMaxMonsters$"!";
		}
		else
		{
			SetMaxMonsters(false);
			CommandResponse = "Turning off custom maximum alive zeds!";
		}
	}
	else if(CommandBreakdown[0] ~= "SetFairSpawns")
	{
		bCommandSuccess = true;
		CommandResponse = "!SetFairSpawns inputs are only false/true or 0/1!";

		if(CommandBreakdown.Length == 1 || CommandBreakdown[1] ~= "false" || CommandBreakdown[1] ~= "0")
		{
			SetEnforceFairSpawns(false);
			CommandResponse = "Fair spawns are no longer enforced!";
		}
		else if(CommandBreakdown[1] ~= "true" || CommandBreakdown[1] ~= "1")
		{
			SetEnforceFairSpawns(true);
			CommandResponse = "Fair spawns are now enforced!";
		}
	}
	else if(CommandBreakdown[0] ~= "SetDisableVersusZeds")
	{
		bCommandSuccess = true;
		CommandResponse = "!SetDisableVersusZeds inputs are only false/true or 0/1!";

		if(CommandBreakdown.Length ~= 1 || CommandBreakdown[1] ~= "false" || CommandBreakdown[1] ~= "0")
		{
			SetDisableVersusZeds(false);
			CommandResponse = "Versus zeds are no longer disabled!";
		}
		else if(CommandBreakdown[1] ~= "true" || CommandBreakdown[1] ~= "1")
		{
			SetDisableVersusZeds(true);
			CommandResponse = "Versus zeds are now disabled!";
		}
	}
	else if(CommandBreakdown[0] ~= "SetEvadeAndBlock")
	{
		bCommandSuccess = true;
		CommandResponse = "!SetEvadeAndBlock inputs are only false/true or 0/1!";

		if(CommandBreakdown.Length == 1 || CommandBreakdown[1] ~= "false" || CommandBreakdown[1] ~= "0")
		{
			SetDisableEvadeAndBlock(true);
			CommandResponse = "Evading and blocking are now disabled!";
		}
		else if(CommandBreakdown[1] ~= "true" || CommandBreakdown[1] ~= "1")
		{
			SetDisableEvadeAndBlock(false);
			CommandResponse = "Evading and blocking are no longer disabled!";
		}
	}
	else if(CommandBreakdown[0] ~= "SetDisableTeleport")
	{
		bCommandSuccess = true;
		CommandResponse = "!SetDisableTeleport inputs are only false/true or 0/1!";

		if(CommandBreakdown.Length == 1 || CommandBreakdown[1] ~= "true" || CommandBreakdown[1] ~= "1")
		{
			SetDisableTeleport(true);
			CommandResponse = "Teleporting is now disabled!";
		}
		else if(CommandBreakdown[1] ~= "false" || CommandBreakdown[1] ~= "0")
		{
			SetDisableTeleport(false);
			CommandResponse = "Teleporting is no longer disabled!";
		}
	}
	else if(CommandBreakdown[0] ~= "ShowConfig")
	{
		bCommandSuccess = true;
		CommandResponse = "Dumped config to console!";

		if(LocalPlayer(KFPC.Player) != None)
			LocalPlayer(KFPC.Player).ViewportClient.ViewportConsole.OutputText( GetConfigDump() );
	}

	return bCommandSuccess;
}

function string GetConfigDump()
{
	local string DumpString;

	if(!bConfigReady)
		return "|FS| FAILED ON CONFIG READY CHECK.";

	DumpString = "|FS| CONFIG DUMP:";

	//Faked Players
	DumpString = DumpString$"|FS| Faked Players is"@(FSGI.bFakedPlayers ? "enabled" : "disabled")$".";

	if(bFakedPlayers)
	{
		DumpString = DumpString$"\n|FS| Faked Players Give Health is"@(FSGI.bFakedHealthModifier ? "enabled" : "disabled")$".";
		DumpString = DumpString$"\n|FS| Faked Players Count is set to"@string(FSGI.FakedPlayerCount)$".";		
	}

	//Max Monsters
	DumpString = "\n|FS| Custom Max Monsters is"@(FSGI.bCustomMaxMonsters ? "enabled" : "disabled")$".";

	if(FSGI.bCustomMaxMonsters)
		DumpString = DumpString$"\n|FS| Custom Max Monsters is set to"@string(FSGI.CustomMaxMonsters)$".";
	
	//Trader
	DumpString = DumpString$"\n|FS| Custom Trader Duration is"@(FSGI.DifficultyInfo.GetTraderTimeByDifficulty() != FSGI.TimeBetweenWaves ? "enabled" : "disabled")$".";

	if(FSGI.DifficultyInfo.GetTraderTimeByDifficulty() != FSGI.TimeBetweenWaves)
		DumpString = DumpString$"\n|FS| Custom Trader Duration is set to"@string(FSGI.TimeBetweenWaves)$".";

	//Spawn Rate
	DumpString = DumpString$"\n|FS| Spawn Rate Modifier is set to"@string(FSGI.ZedSpawnRateModifier)$".";

	//Teleporting
	DumpString = DumpString$"\n|FS| Disable Teleport is set to"@(bDisableTeleport ? "enabled" : "disabled")$".";

	//Disable Albino
	DumpString = DumpString$"\n|FS| Disable Albino is set to"@(bDisableAlbino ? "enabled" : "disabled")$".";

	//No Spawning Cooldown
	DumpString = DumpString$"\n|FS| No Spawning Cooldown is set to"@(FSGI.bNoSpawningCooldown ? "enabled" : "disabled")$".";

	//Enforce Fair Spawns
	DumpString = DumpString$"\n|FS| Enforce Fair Spawns is set to"@(FSGI.bEnforceFairSpawns ? "enabled" : "disabled")$".";

	//Disable Evading And Blocking
	DumpString = DumpString$"\n|FS| Disable Evading And Blocking is set to"@(bDisableEvadingAndBlocking ? "enabled" : "disabled")$".";

	return DumpString;
}

function InitGM()
{
	if(!bConfigReady)
	{
		SpawnRateModifier=1.f;
		bConfigReady = true;
		SaveConfig();
	}

	FSGI.DoInitDataParse(self);

	if(bSaveCommandLineChanges)
		SaveConfig();

	FSGI.bFakedPlayers = bFakedPlayers;
	FSGI.FakedPlayerCount = FakedPlayerCount;

	FSGI.bFakedHealthModifier = bFakedPlayersGiveHealth;

	FSGI.ZedSpawnRateModifier = SpawnRateModifier;

	FSGI.bCustomMaxMonsters = bChangeMaxMonsters;
	FSGI.CustomMaxMonsters = CustomMaxMonsters;

	if(bModifyBaseTraderTime)
		FSGI.TimeBetweenWaves = BaseTraderTime;

	FSGI.bEnforceFairSpawns = bEnforceFairSpawns;

	FSGI.bNoSpawningCooldown = bNoSpawningCooldown;
}

function SetFakedPlayers(bool bNewFakedPlayers, int NewFakedPlayersCount)
{
	FSGI.bFakedPlayers = bNewFakedPlayers;
	FSGI.FakedPlayerCount = NewFakedPlayersCount;

	if(bSaveCommandChanges)
	{
		LogInternal("Faked Players changed with bSaveCommandChanges set to true. Saving...", 'FakedSuite');
		bFakedPlayers = bNewFakedPlayers;
		FakedPlayerCount = NewFakedPlayersCount;
		SaveConfig();
	}
}

function SetFakedPlayerHealth(bool NewGivesHealth)
{
	FSGI.bFakedHealthModifier = NewGivesHealth;

	if(bSaveCommandChanges)
	{
		LogInternal("Faked Players Give Health changed with bSaveCommandChanges set to true. Saving...", 'FakedSuite');
		bFakedPlayersGiveHealth = NewGivesHealth;
		SaveConfig();
	}
}

function SetSpawnRateMod(float NewSpawnRateMod)
{
	FSGI.ZedSpawnRateModifier = NewSpawnRateMod;

	if(bSaveCommandChanges)
	{
		LogInternal("Spawn Rate changed with bSaveCommandChanges set to true. Saving...", 'FakedSuite');
		SpawnRateModifier = NewSpawnRateMod;
		SaveConfig();
	}	
}

function SetMaxMonsters(bool NewChangeMaxMonsters, optional int NewMaxMonsters = 1)
{
	FMax(NewMaxMonsters, 1);

	FSGI.bCustomMaxMonsters = NewChangeMaxMonsters;
	FSGI.CustomMaxMonsters = NewMaxMonsters;

	if(bSaveCommandChanges)
	{
		LogInternal("Max Monsters changed with bSaveCommandChanges set to true. Saving...", 'FakedSuite');
		bChangeMaxMonsters = NewChangeMaxMonsters;
		CustomMaxMonsters = NewMaxMonsters;
		SaveConfig();
	}
}

function SetBaseTraderTime(bool bNewModifyTime, optional int NewTime = 1)
{
	NewTime = FMax(NewTime, 1);

	if(!bNewModifyTime)
		NewTime = FSGI.DifficultyInfo.GetTraderTimeByDifficulty();
	FSGI.TimeBetweenWaves = NewTime;

	if(bSaveCommandChanges)
	{
		LogInternal("Base Trader Time changed with bSaveCommandChanges set to true. Saving...", 'FakedSuite');
		bModifyBaseTraderTime = bNewModifyTime;
		BaseTraderTime = NewTime;
		SaveConfig();
	}
}

function SetEnforceFairSpawns(bool bNewEnforceFairSpawns)
{
	FSGI.bEnforceFairSpawns = bNewEnforceFairSpawns;

	if(bSaveCommandChanges)
	{
		LogInternal("Enforce Fair Spawns changed with bSaveCommandChanges set to true. Saving...", 'FakedSuite');
		bEnforceFairSpawns = bNewEnforceFairSpawns;
		SaveConfig();
	}
}

function SetDisableVersusZeds(bool bNewDisableAlbino)
{
	bDisableAlbino = bNewDisableAlbino;

	if(bSaveCommandChanges)
	{
		LogInternal("Disable Albino changed with bSaveCommandChanges set to true. Saving...", 'FakedSuite');
		SaveConfig();
	}
}

function SetDisableEvadeAndBlock(bool bNewDisableEvadeAndBlock)
{
	bDisableEvadingAndBlocking = bNewDisableEvadeAndBlock;

	if(bSaveCommandChanges)
	{
		LogInternal("Disable Evanding And Blocking changed with bSaveCommandChanges set to true. Saving...", 'FakedSuite');
		SaveConfig();
	}
}

function SetDisableTeleport(bool bNewDisableTeleport)
{
	bDisableTeleport = bNewDisableTeleport;

	if(bSaveCommandChanges)
	{
		LogInternal("Disable Evanding And Blocking changed with bSaveCommandChanges set to true. Saving...", 'FakedSuite');
		SaveConfig();
	}
}

defaultproperties
{
	SwapList.Add((MC=class'KFPawn_ZedClot_Cyst',DI=class'FSMDI_ClotCyst'))
	SwapList.Add((MC=class'KFPawn_ZedClot_Alpha',DI=class'FSMDI_ClotAlpha_NoBlock'))
	SwapList.Add((MC=class'KFPawn_ZedClot_Slasher',DI=class'FSMDI_ClotSlasher'))
	SwapList.Add((MC=class'KFPawn_ZedCrawler',DI=class'FSMDI_Crawler_NoBlock'))
	SwapList.Add((MC=class'KFPawn_ZedGorefast',DI=class'FSMDI_Gorefast'))
	SwapList.Add((MC=class'KFPawn_ZedStalker',DI=class'FSMDI_Stalker'))
	SwapList.Add((MC=class'KFPawn_ZedScrake',DI=class'FSMDI_Scrake'))
	SwapList.Add((MC=class'KFPawn_ZedFleshpound',DI=class'FSMDI_Fleshpound'))
	SwapList.Add((MC=class'KFPawn_ZedBloat',DI=class'FSMDI_Bloat'))
	SwapList.Add((MC=class'KFPawn_ZedSiren',DI=class'FSMDI_Siren'))
	SwapList.Add((MC=class'KFPawn_ZedHusk',DI=class'FSMDI_Husk'))
}