public class LSC_ProcessCaseCommentBeforeInsert {
    public LSC_ProcessCaseCommentBeforeInsert() {

    }
    
    public static void processBeforeInsert (List<CaseComment> newItems) {
        for(CaseComment comment : newItems) {
            comment.IsPublished = true;
        }
    }
}