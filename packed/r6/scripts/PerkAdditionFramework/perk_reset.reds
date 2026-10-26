//the following was provided freely by Nexus user rmk1234, thank you friend!

// Vanilla ResetNewPerks only loops over the original enum range (< Count), so perks appended
// to gamedataNewPerkType by PerkAdditionFramework are never sold or locked on attribute reset.
// This sells and locks every perk with an enum value past the vanilla Invalid entry.
@wrapMethod(PlayerDevelopmentData)
public final func ResetNewPerks() -> Void {
  wrappedMethod();

  for perkType in this.GetAddedNewPerkTypes() {
    this.ResetAddedNewPerk(perkType);
  }
}

// Repairs saves where an attribute reset happened before the fix above. Added perks left
// unlocked without their attribute requirement or required perks are sold and locked.
// Loops until stable so perks depending on a repaired perk are also repaired.
@wrapMethod(PlayerDevelopmentData)
public final func OnRestored(gameInstance: GameInstance) -> Void {
  wrappedMethod(gameInstance);

  if !IsDefined(this.m_owner as PlayerPuppet) {
    return;
  }

  let addedPerkTypes: array<gamedataNewPerkType> = this.GetAddedNewPerkTypes();
  let changed: Bool = true;
  while changed {
    changed = false;
    for perkType in addedPerkTypes {
      if this.IsNewPerkUnlocked(perkType) && !this.AreAddedNewPerkRequirementsMet(perkType) {
        // LogChannel(n"DEBUG", s"Repairing stuck added perk: \(perkType)");
        this.ResetAddedNewPerk(perkType);
        changed = true;
      }
    }
  }
}

// Helpers

@addMethod(PlayerDevelopmentData)
private final func GetAddedNewPerkTypes() -> array<gamedataNewPerkType> {
  let perkTypes: array<gamedataNewPerkType>;
  let perkEnum: ref<ReflectionEnum> = Reflection.GetEnum(n"gamedataNewPerkType");
  if !IsDefined(perkEnum) {
    return perkTypes;
  }

  let vanillaMax: Int64 = Cast<Int64>(EnumInt(gamedataNewPerkType.Invalid));
  for constant in perkEnum.GetConstants() {
    if constant.GetValue() > vanillaMax {
      ArrayPush(perkTypes, IntEnum<gamedataNewPerkType>(constant.GetValue()));
    }
  }
  return perkTypes;
}

// Mirrors the vanilla unlock conditions in UnlockFreeNewPerks / GetUnlockedPerkList
@addMethod(PlayerDevelopmentData)
private final func AreAddedNewPerkRequirementsMet(perkType: gamedataNewPerkType) -> Bool {
  if !this.HasEnoughtAttributePoints(perkType) {
    return false;
  }

  let requiredPerks: array<wref<NewPerk_Record>>;
  RPGManager.GetNewPerkRecord(perkType).RequiresPerks(requiredPerks);
  for requiredPerk in requiredPerks {
    // GetNewPerkMaxLevel returns 0 for locked perks, so use the record's level count instead
    if this.IsNewPerkBought(requiredPerk.Type()) < requiredPerk.GetLevelsCount() {
      return false;
    }
  }
  return true;
}

@addMethod(PlayerDevelopmentData)
private final func ResetAddedNewPerk(perkType: gamedataNewPerkType) -> Void {
  let perkLevelSold: Int32;
  while this.ForceSellNewPerk(perkType, perkLevelSold) {
    let newPerkSoldEvent: ref<NewPerkSoldEvent> = new NewPerkSoldEvent();
    newPerkSoldEvent.perkType = perkType;
    newPerkSoldEvent.perkLevelSold = perkLevelSold;
    GameInstance.GetUISystem(this.m_owner.GetGame()).QueueEvent(newPerkSoldEvent);
    this.m_owner.QueueEvent(newPerkSoldEvent);
  }
  this.LockNewPerk(perkType);
  let newPerkLockedEvent: ref<NewPerkLockedEvent> = new NewPerkLockedEvent();
  newPerkLockedEvent.perkType = perkType;
  GameInstance.GetUISystem(this.m_owner.GetGame()).QueueEvent(newPerkLockedEvent);
}
