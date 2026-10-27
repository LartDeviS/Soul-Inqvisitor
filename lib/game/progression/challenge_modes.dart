enum ChallengeModifier { limitedHealing, empoweredBosses, warpCorruption, noDash, eliteSwarm }
class ChallengeMode { final String id,name,description; final Set<ChallengeModifier> modifiers; final double rewardMultiplier; const ChallengeMode({required this.id,required this.name,required this.description,required this.modifiers,this.rewardMultiplier=1}); }
class ChallengeModeCatalog { static const modes=<ChallengeMode>[
 ChallengeMode(id:'iron_oath',name:'Железная клятва',description:'Лечение ограничено, награды увеличены.',modifiers:{ChallengeModifier.limitedHealing},rewardMultiplier:1.25),
 ChallengeMode(id:'warp_storm',name:'Варп-шторм',description:'Порча растёт быстрее, элитные враги опаснее.',modifiers:{ChallengeModifier.warpCorruption,ChallengeModifier.eliteSwarm},rewardMultiplier:1.4),
 ChallengeMode(id:'execution',name:'Казнь',description:'Боссы усилены, рывок недоступен.',modifiers:{ChallengeModifier.empoweredBosses,ChallengeModifier.noDash},rewardMultiplier:1.5),
 ]; static ChallengeMode? byId(String id){for(final mode in modes){if(mode.id==id)return mode;}return null;} }
