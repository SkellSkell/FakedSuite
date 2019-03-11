class FSGameInfo extends KFGameInfo_Survival;

var FSMut FSMut;

var bool bFakedHealthModifier;
var bool bFakedPlayers;
var int FakedPlayerCount;

var float ZedSpawnRateModifier;

var bool bCustomMaxMonsters;
var int CustomMaxMonsters;

var bool bEnforceFairSpawns;

var bool bNoSpawningCooldown;

var array< EAIType > ReplacementOption;

var string InitData;

event InitGame( string Options, out string ErrorMessage )
{
   Super.InitGame( Options, ErrorMessage );

   InitData = Options;
}

function DoInitDataParse(FSMut FSM)
{
   if(HasOption(InitData, "SpawnRate"))
      FSM.SpawnRateModifier = GetFloatOption(InitData, "SpawnRate", 1.f);

   if(HasOption(InitData, "MaxMonsters"))
   {
      FSM.CustomMaxMonsters = GetIntOption(InitData, "MaxMonsters", INDEX_NONE);
      FSM.bChangeMaxMonsters = FSM.CustomMaxMonsters != INDEX_NONE;
   }

   if(HasOption(InitData, "FakedPlayers"))
   {
      FSM.FakedPlayerCount = GetIntOption(InitData, "FakedPlayers", INDEX_NONE);
      FSM.bFakedPlayers = FSM.FakedPlayerCount != INDEX_NONE;
   }

   if(HasOption(InitData, "TraderTime"))
   {
      FSM.BaseTraderTime = GetIntOption(InitData, "TraderTime", INDEX_NONE);
      FSM.bModifyBaseTraderTime = FSM.BaseTraderTime != INDEX_NONE;
   }

   if(HasOption(InitData, "FakedHealth"))
      FSM.bFakedPlayersGiveHealth = ParseOption(InitData, "FakedHealth") ~= "true";

   if(HasOption(InitData, "DisableAlbino"))
      FSM.bDisableAlbino = ParseOption(InitData, "DisableAlbino") ~= "true";

   if(HasOption(InitData, "FairSpawns"))
      FSM.bEnforceFairSpawns = ParseOption(InitData, "FairSpawns") ~= "true";

   if(HasOption(InitData, "NoBlockEvade"))
      FSM.bDisableEvadingAndBlocking = ParseOption(InitData, "NoBlockEvade")  ~= "true";

   if(HasOption(InitData, "NoTeleport"))
      FSM.bDisableTeleport = ParseOption(InitData, "NoTeleport")  ~= "true";
}

function InitGameConductor()
{
   GameConductor = new(self) GameConductorClass;
   GameConductor.Initialize();
   GameConductor.bBypassGameConductor = true;
}

event Timer()
{
   Super(KFGameInfo).Timer();

   if( SpawnManager != none )
   {
      SpawnManager.Update();
   }
}

/** Adjusts AI pawn default settings by game difficulty and player count */
function SetMonsterDefaults( KFPawn_Monster P )
{
	local float HealthMod;
	local float HeadHealthMod;
	local float TotalSpeedMod, StartingSpeedMod;
	local float DamageMod;
	local int LivingPlayerCount;

	LivingPlayerCount = GetLivingPlayerCount();

	if(FSMut == None)
		AttemptMutatorRefresh();

	if(bFakedHealthModifier)
	{
		LivingPlayerCount += FakedPlayerCount;
	}

	DamageMod = 1.0;
	HealthMod = 1.0;
	HeadHealthMod = 1.0;    

	// Scale health and damage by game conductor values for versus zeds
	DifficultyInfo.GetAIHealthModifier(P, GameDifficulty, LivingPlayerCount, HealthMod, HeadHealthMod);
	DamageMod = DifficultyInfo.GetAIDamageModifier(P, GameDifficulty,bOnePlayerAtStart);

	// Scale damage
	P.DifficultyDamageMod = DamageMod;

	StartingSpeedMod = DifficultyInfo.GetAISpeedMod(P, GameDifficulty);
	TotalSpeedMod = StartingSpeedMod;

	// Scale movement speed
	P.GroundSpeed = P.default.GroundSpeed * TotalSpeedMod;
	P.SprintSpeed = P.default.SprintSpeed * TotalSpeedMod;

	// Store the difficulty adjusted ground speed to restore if we change it elsewhere
	P.NormalGroundSpeed = P.GroundSpeed;
	P.NormalSprintSpeed = P.SprintSpeed;
	P.InitialGroundSpeedModifier = StartingSpeedMod;

	// Scale health by difficulty
	P.Health = P.default.Health * HealthMod;
	if( P.default.HealthMax == 0 )
	{
		P.HealthMax = P.default.Health * HealthMod;
	}
	else
	{
		P.HealthMax = P.default.HealthMax * HealthMod;
	}

	P.ApplySpecialZoneHealthMod(HeadHealthMod);
	P.GameResistancePct = DifficultyInfo.GetDamageResistanceModifier(LivingPlayerCount);
}

function ModifyAIDoshValueForPlayerCount( out float ModifiedValue )
{
	local float DoshMod;

    DoshMod = GetFakedNumPlayers() /  DifficultyInfo.GetPlayerNumMaxAIModifier(GetFakedNumPlayers());

	ModifiedValue *= DoshMod;
}

/* Try to hook all gameplay-relevant functions to this one. GetNumPlayers() is used by server for other things. */
function int GetFakedNumPlayers()
{
   local int BaseNumPlayers;

   BaseNumPlayers = Super.GetNumPlayers();

   if(FSMut == None && !AttemptMutatorRefresh())
      return BaseNumPlayers;

   if(!bFakedPlayers || BaseNumPlayers == 0)
      return BaseNumPlayers;
   return BaseNumPlayers + FakedPlayerCount;
}

function int GetNumHumanTeamPlayers()
{
   local int BaseNumPlayers;

   BaseNumPlayers = Super.GetNumHumanTeamPlayers();

   if(FSMut == None && !AttemptMutatorRefresh())
      return BaseNumPlayers;

   if(!bFakedPlayers || BaseNumPlayers == 0)
      return BaseNumPlayers;
   return BaseNumPlayers + FakedPlayerCount;
}

function ModifyTraderTime(int NewTime)
{
   NewTime = FMax(NewTime, 1);

   //Update GRI counter.
   MyKFGRI.RemainingTime = NewTime;
   MyKFGRI.RemainingMinute = NewTime;

   //Clear and set trader timer.
   ClearTimer(nameof(CloseTraderTimer));
   SetTimer(NewTime, False, nameof(CloseTraderTimer));
}

function ClampDownTraderTime(int NewBaseTime)
{
   if(MyKFGRI.RemainingTime > NewBaseTime)
   {
      //Update GRI counter.
      MyKFGRI.RemainingTime = NewBaseTime;
      MyKFGRI.RemainingMinute = NewBaseTime;

      //Clear and set trader timer.
      ClearTimer(nameof(CloseTraderTimer));
      SetTimer(NewBaseTime, False, nameof(CloseTraderTimer));     
   }
}

function bool AttemptMutatorRefresh()
{
   FSMut = class'FSMut'.static.GetMutRef(WorldInfo);

   if(FSMut != None)
   {
      FSMut.FSGI = self;
      FSMut.InitGM();
   }
   else
      LogInternal("Missing mutator reference after attempt to grab it from WorldInfo.", 'FakedSuite');

   return FSMut != None;
}

static function bool ShouldBlockScrakeSpawn(byte GL, int WN)
{
   switch( GL )
   {
   case GL_Short:
      return WN < 3;
   case GL_Normal:
      return WN < 4;
   case GL_Long:
      return WN < 5;
   }

   return true;
}

static function bool ShouldBlockFleshpoundSpawn(byte GL, int WN)
{
   switch( GL )
   {
   case GL_Short:
      return WN < 3;
   case GL_Normal:
      return WN < 5;
   case GL_Long:
      return WN < 6;
   }

   return true;
}

static function GetCorrectedSquad(byte GL, int WN, out array< class<KFPawn_Monster> >  AISpawnList)
{
   local int i;

   if(static.ShouldBlockScrakeSpawn(GL, WN))
   {
      for ( i = 0; i < AISpawnList.Length; i++ )
      {
         if ( AISpawnList[i] == default.AIClassList[AT_Scrake] )
            AISpawnList[i] = default.AIClassList[ default.ReplacementOption[Rand(default.ReplacementOption.Length)] ];
      } 
   }

   if(static.ShouldBlockFleshpoundSpawn(GL, WN))
   {
      for ( i = 0; i < AISpawnList.Length; i++ )
      {
         if ( AISpawnList[i] == default.AIClassList[AT_FleshPound] )
            AISpawnList[i] = default.AIClassList[ default.ReplacementOption[Rand(default.ReplacementOption.Length)] ];
      }       
   }
}

defaultproperties
{
   ReplacementOption.Add(AT_Bloat)
   ReplacementOption.Add(AT_Siren)
   ReplacementOption.Add(AT_Husk)

   bFakedPlayers=False
   bFakedHealthModifier=False
   FakedPlayerCount=0

   bCustomMaxMonsters=False
   CustomMaxMonsters=0

   ZedSpawnRateModifier=1.000000

   bNoSpawningCooldown=False

   SpawnManagerClasses(0)=class'FSAISM_Short'
   SpawnManagerClasses(1)=class'FSAISM_Normal'
   SpawnManagerClasses(2)=class'FSAISM_Long'

   GameConductorClass=class'FSGameConductor'
}