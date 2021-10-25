trigger LSC_CaseCommentTrigger on CaseComment (before insert) {
    LSC_TriggerDispatcher.Run(new LSC_CaseCommentTriggerHandler());
}