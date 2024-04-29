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

    public override void beforeInsert() {
        TRG_CAMPX_SponsorHelper.updatingSponsorTierBasedOnContributionAmount(this.listNew, null);
    }
    public override void afterInsert() {
    }

    public override void beforeUpdate() {
        TRG_CAMPX_SponsorHelper.updatingSponsorTierBasedOnContributionAmount(this.listNew, this.mapOld);

    }
    public override void afterUpdate() {
        TRG_CAMPX_SponsorHelper.updatingEventGrossRevenueUponSponsorAcceptance(this.listNew, this.mapOld);
    }
}