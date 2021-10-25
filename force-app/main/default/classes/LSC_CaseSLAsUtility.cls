public without sharing class LSC_CaseSLAsUtility {
    public static void manageSLAs (Map<Id, Case> newItems, Map<Id, Case> oldItems) {
        List<BusinessHours> bhs = [SELECT Id FROM BusinessHours WHERE IsDefault = true];
        if(bhs != null && bhs.size() > 0) {
            Id businessHoursId  = bhs[0].Id;
            for(Case c : newItems.values()) {
                if(c.Status != oldItems.get(c.Id).Status) {
                    Case cOld = oldItems.get(c.Id);

                    //Handling Time In Queue
                    if(cOld.Status == 'New' && c.Status != 'New') {
                        c.LSC_TimeInQueue__c = Math.round(BusinessHours.diff(businessHoursId, c.CreatedDate, System.now())/60000);
                    }

                    //Handling Closure 
                    if((c.Status == 'Closed' || c.Status == 'Closed Approved' || c.Status == 'Closed Rejected') && cOld.IsClosed == false) {
                        c.LSC_TotalLifecycle__c = Math.round(BusinessHours.diff(businessHoursId, c.CreatedDate, System.now())/60000);
                    }

                    //Handling Pending Approval
                    if(c.Status == 'Pending Approval' && c.Status != cOld.Status) {
                        c.LSC_ApprovalStart__c = System.now();
                    }
                    if(cOld.Status == 'Pending Approval' && c.Status != cOld.Status) {
                        if(c.LSC_ApprovalTime__c == null) {
                            c.LSC_ApprovalTime__c = 0;
                        }
                        c.LSC_ApprovalTime__c += Math.round(BusinessHours.diff(businessHoursId, c.LSC_ApprovalStart__c, System.now())/60000);
                        c.LSC_ApprovalStart__c = null;
                    }                    
                    
                    //Handling In Progress And Escalated
                    if((c.Status == 'In Progress' || c.Status == 'Escalated') && c.Status != cOld.Status) {
                        if(cOld.Status != 'In Progress' && cOld.Status != 'Escalated') {
                            c.LSC_InProgressStart__c = System.now();
                        }
                    }
                    if((cOld.Status == 'In Progress' || cOld.Status == 'Escalated') && c.Status != 'In Progress' && c.Status != 'Escalated') {
                        if(c.LSC_ProcessingTime__c == null) {
                            c.LSC_ProcessingTime__c = 0;
                        }
                        c.LSC_ProcessingTime__c += Math.round(BusinessHours.diff(businessHoursId, c.LSC_InProgressStart__c, System.now())/60000);
                        c.LSC_InProgressStart__c = null;
                    }                    

                    //Handling On Hold
                    if(c.Status == 'On Hold' && c.Status != cOld.Status) {
                        c.LSC_OnHoldStart__c = System.now();
                    }
                    if(cOld.Status == 'On Hold' && c.Status != cOld.Status) {
                        if(c.LSC_OnHoldTime__c == null) {
                            c.LSC_OnHoldTime__c = 0;
                        }
                        c.LSC_OnHoldTime__c += Math.round(BusinessHours.diff(businessHoursId, c.LSC_OnHoldStart__c, System.now())/60000);
                        c.LSC_OnHoldStart__c = null;
                    }

                }
            }
        }
    }

    @AuraEnabled(cacheable=true)
    public static SLAWrapper getData(String recordId) {
        SLAWrapper result = new SLAWrapper();
        if(recordId != null) {
            List<Case> cases = [SELECT Id, RecordType.Name, Status, LSC_InProgressStart__c, LSC_TimeInQueue__c, LSC_TotalLifecycle__c, LSC_ProcessingTime__c, LSC_ApprovalStart__c, LSC_ApprovalTime__c, LSC_OnHoldStart__c, LSC_OnHoldTime__c, CreatedDate FROM Case WHERE Id = :recordId];            
            if(cases == null || cases.size() == 0) {
                return result;  
            }
            Case c = cases[0];
            List<BusinessHours> bhs = [SELECT Id FROM BusinessHours WHERE IsDefault = true];
            if(bhs == null || bhs.size() == 0) {
                return result;  
            }            
            Id businessHoursId = bhs[0].Id;
            LSC_SLATerms__mdt sla = LSC_SLATerms__mdt.getInstance(c.RecordType.Name);
            if(sla == null) {
                return result;  
            }                     
            result.status = c.Status;
            if(c.Status == 'New') {
                result.totalTime = Math.round(BusinessHours.diff(businessHoursId, c.CreatedDate, System.now())/60000);
                result.timeInQueue = Math.round(BusinessHours.diff(businessHoursId, c.CreatedDate, System.now())/60000);              
            }
            else if(c.Status == 'In Progress' || c.Status == 'Escalated' || c.Status == 'On Hold') {
                result.totalTime = Math.round(BusinessHours.diff(businessHoursId, c.CreatedDate, System.now())/60000);
                result.timeInQueue = c.LSC_TimeInQueue__c;
                if(c.Status == 'In Progress' || c.Status == 'Escalated') {
                    result.onHoldTime = c.LSC_OnHoldTime__c;
                    result.processingTime = c.LSC_ProcessingTime__c != null ? c.LSC_ProcessingTime__c : 0;
                    result.processingTime += Math.round(BusinessHours.diff(businessHoursId, c.LSC_InProgressStart__c, System.now())/60000);
                }
                if(c.Status == 'On Hold') {
                    result.processingTime = c.LSC_ProcessingTime__c;
                    result.onHoldTime = c.LSC_OnHoldTime__c != null ? c.LSC_OnHoldTime__c : 0;
                    result.onHoldTime += Math.round(BusinessHours.diff(businessHoursId, c.LSC_OnHoldStart__c, System.now())/60000);
                }     
            }
            else if(c.Status == 'Pending Approval') {
                result.totalTime = Math.round(BusinessHours.diff(businessHoursId, c.CreatedDate, System.now())/60000);
                result.timeInQueue = c.LSC_TimeInQueue__c;
                result.processingTime = c.LSC_ProcessingTime__c;
                result.onHoldTime = c.LSC_OnHoldTime__c;
                result.approvalTime =  Math.round(BusinessHours.diff(businessHoursId, c.LSC_ApprovalStart__c, System.now())/60000);
            }
            else if(c.Status == 'Closed' || c.Status == 'Closed Approved' || c.Status == 'Closed Rejected') {
                result.totalTime = c.LSC_TotalLifecycle__c;
                result.timeInQueue = c.LSC_TimeInQueue__c;
                result.processingTime = c.LSC_ProcessingTime__c;
                result.onHoldTime = c.LSC_OnHoldTime__c;
                result.approvalTime =  c.LSC_ApprovalTime__c;
            }

            if(result.timeInQueue != null && sla.LSC_TimeInQueueOrange__c != null && result.timeInQueue > sla.LSC_TimeInQueueOrange__c) {
                if(result.timeInQueue > sla.LSC_TimeInQueueRed__c) {
                    result.timeInQueueType = 'expired';
                }
                else {
                    result.timeInQueueType = 'warning';
                }
            }
            else {
                result.timeInQueueType = 'base';
            }   
            if(result.timeInQueue != null && sla.LSC_TimeInQueueRed__c != null) {
                result.timeInQueueP = Math.round(100*result.timeInQueue/sla.LSC_TimeInQueueRed__c);
                if(result.timeInQueueP > 100) {
                    result.timeInQueueP = 100;
                }
            }            

            if(result.totalTime != null && sla.LSC_TOtalTimeOrange__c != null && result.totalTime > sla.LSC_TOtalTimeOrange__c) {
                if(result.totalTime > sla.LSC_TotalTimeRed__c) {
                    result.totalTimeType = 'expired';
                }
                else { 
                    result.totalTimeType = 'warning';
                }
            }
            else {
                result.totalTimeType = 'base';
            } 
            if(result.totalTime != null && sla.LSC_TotalTimeRed__c != null) {
                result.totalTimeP = Math.round(100*result.totalTime/sla.LSC_TotalTimeRed__c);
                if(result.totalTimeP > 100) {
                    result.totalTimeP = 100;
                }
            }                  

            if(result.processingTime != null && sla.LSC_ProcessingTimeOrange__c != null && result.processingTime > sla.LSC_ProcessingTimeOrange__c) {
                if(result.processingTime > sla.LSC_ProcessingTimeRed__c) {
                    result.processingTimeType = 'expired';
                }
                else {
                    result.processingTimeType = 'warning';
                }
            }
            else {
                result.processingTimeType = 'base';
            }  
            if(result.processingTime != null && sla.LSC_ProcessingTimeRed__c != null) {
                result.processingTimeP = Math.round(100*result.processingTime/sla.LSC_ProcessingTimeRed__c);
                if(result.processingTimeP > 100) {
                    result.processingTimeP = 100;
                }
            }                   

            if(result.onHoldTime != null && sla.LSC_OnHoldTimeOrange__c != null && result.onHoldTime > sla.LSC_OnHoldTimeOrange__c) {
                if(result.onHoldTime > sla.LSC_OnHoldTimeRed__c) {
                    result.onHoldTimeType = 'expired';
                }
                else {
                    result.onHoldTimeType = 'warning';
                }
            }
            else {
                result.onHoldTimeType = 'base';
            }  
            if(result.onHoldTime != null && sla.LSC_OnHoldTimeRed__c != null) {
                result.onHoldTimeP = Math.round(100*result.onHoldTime/sla.LSC_OnHoldTimeRed__c);
                if(result.onHoldTimeP > 100) {
                    result.onHoldTimeP = 100;
                }
            }               

            if(result.approvalTime != null && sla.LSC_ApprovalTimeOrange__c != null && result.approvalTime > sla.LSC_ApprovalTimeOrange__c) {
                if(result.approvalTime > sla.LSC_ApprovalTimeRed__c) {
                    result.approvalType = 'expired';
                }
                else {
                    result.approvalType = 'warning';
                }
            }
            else {
                result.approvalType = 'base';
            } 
            if(result.approvalTime != null && sla.LSC_ApprovalTimeRed__c != null) {
                result.approvalTimeP = Math.round(100*result.approvalTime/sla.LSC_ApprovalTimeRed__c);
                if(result.approvalTimeP > 100) {
                    result.approvalTimeP = 100;
                }
            }                 

        }
        return result;        
    }    

    public class SLAWrapper {
        @AuraEnabled
        public String status {get; set;}

        @AuraEnabled
        public Double totalTime {get; set;}

        @AuraEnabled
        public Integer totalTimeP {get; set;}        

        @AuraEnabled
        public String totalTimeType {get; set;}

        @AuraEnabled
        public Double timeInQueue {get; set;}

        @AuraEnabled
        public Integer timeInQueueP {get; set;}        

        @AuraEnabled
        public String timeInQueueType {get; set;}

        @AuraEnabled
        public Double processingTime {get; set;}

        @AuraEnabled
        public String processingTimeType {get; set;}

        @AuraEnabled
        public Integer processingTimeP {get; set;}        

        @AuraEnabled
        public Double onHoldTime {get; set;}

        @AuraEnabled
        public String onHoldTimeType {get; set;}     
        
        @AuraEnabled
        public Integer onHoldTimeP {get; set;}        

        @AuraEnabled
        public Double approvalTime {get; set;}

        @AuraEnabled
        public String approvalType {get; set;}     
        
        @AuraEnabled
        public Integer approvalTimeP {get; set;}        

        public SLAWrapper() {
            totalTimeP = 100;
            timeInQueueP = 100;
            processingTimeP = 100;
            onHoldTimeP = 100;
            approvalTimeP = 100;
        }
    }    
}