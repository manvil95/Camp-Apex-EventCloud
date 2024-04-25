public with sharing class TRG_CAMPX_SponsorHandler extends TriggerHandler {

    private List<CAMPX__Sponsor__c>     listNew;
    private List<CAMPX__Sponsor__c>     listOld;
    private Map<Id, CAMPX__Sponsor__c>  mapNew;
    private Map<Id, CAMPX__Sponsor__c>  mapOld;
    private String                      objectHandler;

    public TRG_CAMPX_SponsorHandler ()  {
        this.listNew        = Trigger.new;
        this.listOld        = Trigger.old;
        this.mapOld         = (Map<Id, CAMPX__Sponsor__c>) Trigger.oldMap;
        this.mapNew         = (Map<Id, CAMPX__Sponsor__c>) Trigger.newMap;
        this.objectHandler  = 'CAMPX__Sponsor__c';
    }

    public override void afterUpdate() {
        // Cuando un registro CAMPX__Sponsor__c se actualiza para tener un CAMPX__Status__c "Aceptado", el sistema debe contabilizar el CAMPX__ContributedAmount__c del patrocinador en el campo CAMPX__GrossRevenue__c de CAMPX__Event__c.
        Set<Id> sponsorIds = new Set<Id>();
        List<CAMPX__Event__c> updatableList = new List<CAMPX__Event__c>();

        for (CAMPX__Sponsor__c currentSponsor : this.listNew) {
            sponsorIds.add(currentSponsor.Id);
        }

        List<CAMPX__Event__c> eventList = [SELECT Id, CAMPX__GrossRevenue__c FROM CAMPX__Event__c WHERE Id IN :sponsorIds WITH USER_MODE];

        Map<Id, CAMPX__Event__c> mapEvents = new Map<Id,CAMPX__Event__c>();
        for (CAMPX__Event__c currentEvent : eventList) {
            mapEvents.put(currentEvent.Id, currentEvent);
        }
        

        for (CAMPX__Sponsor__c currentSponsor : this.listNew) {
            if (currentSponsor.CAMPX__Status__c == 'Accepted' && this.mapOld.get(currentSponsor.Id).CAMPX__Status__c != 'Accepted') {
                CAMPX__Event__c event = mapEvents.get((Id) currentSponsor.CAMPX__Event__c);
                event.CAMPX__GrossRevenue__c = event.CAMPX__GrossRevenue__c + currentSponsor.CAMPX__ContributionAmount__c;
                updatableList.add(event);
            }
        }
        try {
            update updatableList;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
}