public with sharing class TRG_CAMPX_SponsorHelper {
    
    private static final String STATUS_ACCEPTED = 'Accepted';
    

    public static void validateStatusChangeToAccepted(List<CAMPX__Sponsor__c> newCampxSponsors, Map<Id,CAMPX__Sponsor__c> oldMapSponsors) {
        for (CAMPX__Sponsor__c sponsor : newCampxSponsors) {
            if (
                    (   oldMapSponsors == null 
                        || sponsor.CAMPX__Status__c  != oldMapSponsors.get(sponsor.Id).CAMPX__Status__c
                    ) 
                    && sponsor.CAMPX__Status__c == STATUS_ACCEPTED 
                    && String.isBlank(sponsor.CAMPX__Event__c)
            ) { 
                sponsor.addError('A Sponsor must be associated with an event before being Accepted.');
            }
        }
    }
    
    public static void updatingSponsorTierBasedOnContributionAmount(List<CAMPX__Sponsor__c> newCampxSponsors, Map<Id,CAMPX__Sponsor__c> oldMapSponsors) {
        for (CAMPX__Sponsor__c sponsor : newCampxSponsors) {
            if (    
                    oldMapSponsors == null 
                    || sponsor.CAMPX__ContributionAmount__c != oldMapSponsors.get(sponsor.Id).CAMPX__ContributionAmount__c
            ) { 
                if (sponsor.CAMPX__ContributionAmount__c >= 5000) {
                    sponsor.CAMPX__Tier__c = 'Gold';
                } else if (sponsor.CAMPX__ContributionAmount__c >= 1000) {
                    sponsor.CAMPX__Tier__c = 'Silver';
                } else if (sponsor.CAMPX__ContributionAmount__c > 0) {
                    sponsor.CAMPX__Tier__c = 'Bronze';
                } else {
                    sponsor.CAMPX__Tier__c = '';
                }
            }
        }
    }

    // Cuando un registro CAMPX__Sponsor__c se actualiza para tener un CAMPX__Status__c "Aceptado", 
    // el sistema debe contabilizar el CAMPX__ContributedAmount__c del patrocinador en el campo 
    // CAMPX__GrossRevenue__c de CAMPX__Event__c.
    public static void updatingEventGrossRevenueUponSponsorAcceptance(List<CAMPX__Sponsor__c> newRecords, Map<Id,CAMPX__Sponsor__c> oldRecordsMap) {
        Set<Id> eventIds = new Set<Id>();
        
        for (CAMPX__Sponsor__c sponsor : newRecords) {
            if (hasToRecalculateEventsGrossRevenue(sponsor, oldRecordsMap)) {
                eventIds.add(sponsor.CAMPX__Event__c);
            }
            
            if (isEventCancelled(sponsor, oldRecordsMap)) {
                eventIds.add(oldRecordsMap.get(sponsor.Id).CAMPX__Event__c);
            }
        }
        
        if (eventIds.size() > 0) {
            calculateEventGrossRevenue(eventIds);
        }
    }
    
    private static Boolean isEventCancelled(CAMPX__Sponsor__c sponsor, Map<Id,CAMPX__Sponsor__c> oldRecordsMap) {
        return oldRecordsMap != null && sponsor.CAMPX__Event__c == null && oldRecordsMap.get(sponsor.Id).CAMPX__Event__c != null;
    }
    
    private static Boolean hasToRecalculateEventsGrossRevenue(CAMPX__Sponsor__c sponsor, Map<Id,CAMPX__Sponsor__c> oldRecordsMap) {
        return (    (   oldRecordsMap == null 
                        || sponsor.CAMPX__Status__c  != oldRecordsMap.get(sponsor.Id).CAMPX__Status__c
                        || sponsor.CAMPX__ContributionAmount__c  != oldRecordsMap.get(sponsor.Id).CAMPX__ContributionAmount__c
                    ) 
                    && sponsor.CAMPX__Status__c == STATUS_ACCEPTED
                )
                || (    oldRecordsMap != null 
                        && sponsor.CAMPX__Status__c  != oldRecordsMap.get(sponsor.Id).CAMPX__Status__c
                        && oldRecordsMap.get(sponsor.Id).CAMPX__Status__c == STATUS_ACCEPTED
                )
                || (
                    oldRecordsMap != null 
                    && sponsor.CAMPX__Event__c != null
                    && sponsor.CAMPX__Event__c != oldRecordsMap.get(sponsor.Id).CAMPX__Event__c
                );
    }
    
    private static void calculateEventGrossRevenue(Set<Id> eventIds) {
        MAp<Id, CAMPX__Event__c> eventsToUpdateMap = new Map<Id,CAMPX__Event__c>();

        for (Id eventId : eventIds) {
            eventsToUpdateMap.put(eventId, new CAMPX__Event__c(Id=eventId, CAMPX__GrossRevenue__c=0));
        }
        
        List<AggregateResult> results = [   SELECT SUM(CAMPX__ContributionAmount__c) Amount, 
                                                CAMPX__Event__c Event, 
                                                CAMPX__Status__c Status 
                                            FROM CAMPX__Sponsor__c 
                                            WHERE CAMPX__Event__c IN :eventIds 
                                                AND CAMPX__Status__c =: STATUS_ACCEPTED
                                            WITH USER_MODE
                                            GROUP BY CAMPX__Event__c, CAMPX__Status__c];
        
        for (AggregateResult result : results) {
            Decimal amount  = (Decimal) result.get('Amount');
            Id      eventId = (Id) result.get('Event');
            
            if (eventId != null) {
                eventsToUpdateMap.put(eventId, new CAMPX__Event__c(Id=eventId, CAMPX__GrossRevenue__c=amount));
            }
        }
        
        update eventsToUpdateMap.values();
        
    }
}