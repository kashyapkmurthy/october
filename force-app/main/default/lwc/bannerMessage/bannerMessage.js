import { LightningElement, wire, track } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import momentJs from "@salesforce/resourceUrl/momentjs_2_29_1";
import getBannerMessage from "@salesforce/apex/LSC_BannerMessageController.getBannerMessage";
import { replaceStringWithPlaceholder } from "c/utils";

export default class BannerMessage extends LightningElement {
  wiredBannerMessageResult;
  @track
  bannerMessage = {};
  messageBodyFromBackend = "";
  scriptLoaded = false;
  isShow = false;
  isCritical = false;

  connectedCallback() {
    Promise.all([loadScript(this, momentJs)])
      .then(() => {
        this.scriptLoaded = true;
        this.isShow = this.checkIfShowBanner();
      })
      .catch((error) => {
        this.scriptLoaded = false;
        this.isShow = false;
      });
  }

  @wire(getBannerMessage)
  wiredBannerMessage(result) {
    this.wiredBannerMessageResult = result;
    if (result.data) {
      this.bannerMessage = result.data;
      this.messageBodyFromBackend = result.data.Message_Body__c;
      this.isShow = this.checkIfShowBanner();
      this.isCritical = result.data.Is_Critical__c;
    } else if (result.error) {
      this.bannerMessage = {};
      this.isShow = false;
      this.isCritical = false;
    }
  }

  get messageTitle() {
    return this.bannerMessage?.Message_Title__c;
  }

  get messageContainerClassName() {
    let className = "slds-notify slds-notify_alert messageContainer";
    className = this.isCritical ? className + " criticalMessage" : className;
    return className;
  }

  get messageBody() {
    let messageBody = this.messageBodyFromBackend;
    if (
      this.messageBodyFromBackend &&
      this.messageBodyFromBackend.indexOf("{") > -1 &&
      this.scriptLoaded
    ) {
      const formattedStartTime = moment(
        this.bannerMessage.Start_Time__c
      ).format("h:mma dddd DD MMMM YYYY");
      const formattedEndTime = moment(this.bannerMessage.End_Time__c).format(
        "h:mma dddd DD MMMM YYYY"
      );
      const replaceHander = {
        Start_Time__c: formattedStartTime,
        End_Time__c: formattedEndTime
      };
      messageBody = replaceStringWithPlaceholder(
        this.messageBodyFromBackend,
        replaceHander
      );
    }
    return messageBody;
  }

  checkIfShowBanner() {
    let isShow = false;
    if (
      this.bannerMessage.Start_Time__c &&
      this.bannerMessage.End_Time__c &&
      this.scriptLoaded
    ) {
      const startTimeMoment = moment(this.bannerMessage.Start_Time__c);
      const endTimeMoment = moment(this.bannerMessage.End_Time__c);
      isShow =
        this.bannerMessage.Is_Active__c &&
        moment().isSameOrAfter(startTimeMoment) &&
        moment().isSameOrBefore(endTimeMoment);
    }
    return isShow;
  }

  handleClose() {
    this.isShow = false;
  }
}