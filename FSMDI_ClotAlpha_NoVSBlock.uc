class FSMDI_ClotAlpha_NoVSBlock extends KFDifficulty_ClotAlpha
	abstract;

defaultproperties
{
	Normal={(
		EvadeOnDamageSettings={(Chance=-1.0, DamagedHealthPctToTrigger=1.1)},
		BlockSettings={(Chance=-1.0, DamagedHealthPctToTrigger=1.1)}
	)}	

	Hard={(
		EvadeOnDamageSettings={(Chance=-1.0, DamagedHealthPctToTrigger=1.1)},
		BlockSettings={(Chance=-1.0, DamagedHealthPctToTrigger=1.1)}
	)}
	
	Suicidal={(
		EvadeOnDamageSettings={(Chance=-1.0, DamagedHealthPctToTrigger=1.1)},
		BlockSettings={(Chance=-1.0, DamagedHealthPctToTrigger=1.1)}
	)}
	
	HellOnEarth={(
		EvadeOnDamageSettings={(Chance=-1.0, DamagedHealthPctToTrigger=1.1)},
		BlockSettings={(Chance=-1.0, DamagedHealthPctToTrigger=1.1)}
	)}
	
	RallyTriggerSettings(0)={(SpawnChance=-1.f, RallyChance=-1.f)}
	RallyTriggerSettings(1)={(SpawnChance=-1.f, RallyChance=-1.f)}
	RallyTriggerSettings(2)={(SpawnChance=-1.f, RallyChance=-1.f)}
	RallyTriggerSettings(3)={(SpawnChance=-1.f, RallyChance=-1.f)}
}