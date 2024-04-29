public with sharing class TRG_CAMPX_SponsorHelper {
    
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

    public static void updatingEventGrossRevenueUponSponsorAcceptance(List<CAMPX__Sponsor__c> newCampxSponsors, Map<Id, CAMPX__Sponsor__c> oldMapSponsors) {
        // Cuando un registro CAMPX__Sponsor__c se actualiza para tener un CAMPX__Status__c "Aceptado", el sistema debe contabilizar el CAMPX__ContributedAmount__c del patrocinador en el campo CAMPX__GrossRevenue__c de CAMPX__Event__c.
        Set<Id> sponsorIds = new Set<Id>();
        List<CAMPX__Event__c> updatableList = new List<CAMPX__Event__c>();

        for (CAMPX__Sponsor__c currentSponsor : newCampxSponsors) {
            sponsorIds.add(currentSponsor.Id);
        }

        List<CAMPX__Event__c> eventList = [SELECT Id, CAMPX__GrossRevenue__c FROM CAMPX__Event__c WHERE Id IN :sponsorIds WITH USER_MODE];

        Map<Id, CAMPX__Event__c> mapEvents = new Map<Id,CAMPX__Event__c>();
        for (CAMPX__Event__c currentEvent : eventList) {
            mapEvents.put(currentEvent.Id, currentEvent);
        }
        

        for (CAMPX__Sponsor__c currentSponsor : newCampxSponsors) {
            if (currentSponsor.CAMPX__Status__c == 'Accepted' && oldMapSponsors.get(currentSponsor.Id).CAMPX__Status__c != 'Accepted') {
                CAMPX__Event__c event = mapEvents.get((Id) currentSponsor.CAMPX__Event__c);
                event.CAMPX__GrossRevenue__c = event.CAMPX__GrossRevenue__c + currentSponsor.CAMPX__ContributionAmount__c;
                updatableList.add(event);
            }
        }
        try {
            update updatableList;
            System.debug('manvil: ' + updatableList);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
}