import PerkAdditionFramework.Logging.*

public class PerkAdditionFramework extends ScriptableService 
{
    let perkEnum : ref<ReflectionEnum>;
    let allNewPerk_Records : array<ref<NewPerk_Record>>;
    let enumName : CName = n"gamedataNewPerkType";

    private cb func OnInitialize()
    {
        // LogToConsole(s"Initializing");
        this.allNewPerk_Records = this.GetPerkRecords();
        this.perkEnum = Reflection.GetEnum(this.enumName);


        this.CheckForDuplicateEnumAssignment(this.allNewPerk_Records);
        this.CheckForDuplicateSlotAssignment();
        this.ExpandPerkEnum(this.allNewPerk_Records);
        // LogToConsole(s"Initialized");
    }

    public static func GetInstance() -> ref<PerkAdditionFramework>
    {
        return GameInstance.GetScriptableServiceContainer().GetService(n"PerkAdditionFramework") as PerkAdditionFramework;
    }

    private func ExpandPerkEnum(perk_Records : array<ref<NewPerk_Record>>)
    {
        let members : array<ref<ReflectionConst>> = this.perkEnum.GetConstants(); //can't get ArraySize without declaring this individually :(
        let n : Int64 = Cast<Int64>( ArraySize(members) ); //current highest index
        let enumName : CName;
        for perk_Record in perk_Records
        {
            enumName = perk_Record.EnumName();
            if !( this.EnumContains(this.perkEnum, enumName) )
            {
                n += 1l;
                this.perkEnum.AddConstant( enumName, n );
                TweakDBManager.UpdateRecord(TDBID.Create("NewPerks."+ToString(enumName))); //apparently the data from the record is accessed via enum. Has to be reloaded after the enum is created.
            }
        }
    }


    private func EnumContains(targetEnum : ref<ReflectionEnum>, memberName : CName) -> Bool
    {
        let constants : array<ref<ReflectionConst>> = targetEnum.GetConstants();
        for constant in constants
        {
            if ( Equals( constant.GetName(), memberName) )
            {
                return true;
            }
        }
        return false;
    }

    private func CheckForDuplicateEnumAssignment(perkRecords : array<ref<NewPerk_Record>>) -> Bool
    {
        let usedEnumNames : array<CName>;
        for perkRecord in perkRecords 
        {
            let enumNameToTest : CName = perkRecord.EnumName();
            if !ArrayContains(usedEnumNames, enumNameToTest)
            {
                ArrayPush(usedEnumNames, enumNameToTest);
            } 
            else
            {
                PAFLogWarning(s"Slot \(enumNameToTest) was assigned multiple times.");
            }
        }
    }   

    private func CheckForDuplicateSlotAssignment() -> Bool
    {
        let attributes : array<ref<AttributeData_Record>> = this.GetAttributeRecords();
        for attribute in attributes
        {
            let perkRecords : array<wref<NewPerk_Record>>;
            attribute.Perks(perkRecords); //is an out var apparently
            let usedSlots : array<ref<NewPerkSlot_Record>>;
            for perkRecord in perkRecords 
            {
                let slotToTest : wref<NewPerkSlot_Record> = perkRecord.Slot();
                if !ArrayContains(usedSlots, slotToTest)
                {
                    ArrayPush(usedSlots, slotToTest);
                } 
                else
                {
                    PAFLogWarning(s"Slot \(slotToTest) in \(attribute.EnumName()) was assigned multiple times.");
                }
            }
        }
    }   

    // fetchers
    
    private func GetPerkRecords() -> array<ref<NewPerk_Record>>
    {
        let records : array<ref<TweakDBRecord>> = TweakDBInterface.GetRecords(n"NewPerk_Record");
        let recordsOut : array<ref<NewPerk_Record>>;
        for records in records
        {
            ArrayPush(recordsOut, ( records as NewPerk_Record) );
        }
        return recordsOut;
    }

    private func GetAttributeRecords() -> array<ref<AttributeData_Record>>
    {
        let records : array<ref<TweakDBRecord>> = TweakDBInterface.GetRecords(n"AttributeData_Record");
        let recordsOut : array<ref<AttributeData_Record>>;
        for records in records
        {
            ArrayPush(recordsOut, ( records as AttributeData_Record) );
        }
        return recordsOut;
    }
    
}