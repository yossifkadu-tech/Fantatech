import '../models/app_state.dart';

class S {
  // Navigation
  final String navHome;
  final String navCameras;
  final String navSecurity;
  final String navProfile;

  // Dashboard
  final String greetingPrefix;
  final String homeSecured;
  final String homeNotSecured;
  final String allSystemsActive;
  final String tapToActivate;
  final String alarmTitle;
  final String alarmSecured;
  final String alarmOff;
  final String roomManagement;
  final String roomsUnit;
  final String camerasTitle;
  final String lightsOn;
  final String lightingTitle;
  final String tempTitle;
  final String tempComfy;
  final String aiSubtitle;
  final String quickActions;
  final String leaveHome;
  final String turnOffAll;
  final String goodNight;
  final String movieMode;
  final String mediaTitle;
  final String mediaSpeakers;
  final String mediaScan;
  final String mediaNoDevices;
  final String bioTitle;
  final String bioPrompt;
  final String bioEnable;
  final String bioSkip;
  final String bioReason;
  final String onbNext;
  final String onbStart;
  final String onbSkip;
  final String onbAllow;
  final String onbLater;
  final String onb1Title;
  final String onb1Body;
  final String onb2Title;
  final String onb2Body;
  final String onb3Title;
  final String onb3Body;
  final String onbPermTitle;
  final String onbPermBody;
  final String secSection;
  final String bioLoginLabel;
  final String bioLoginSub;
  final String legalSection;
  final String termsLabel;
  final String privacyLabel;
  final String sceneCreate;
  final String sceneNew;
  final String sceneName;
  final String sceneActions;
  final String actPlugs;
  final String valKeep;
  final String valOn;
  final String valOff;
  final String authEmailHint;
  final String authPassHint;
  final String loginGreeting;
  final String loginSubtitle;
  final String loginForgot;
  final String loginButton;
  final String authOr;
  final String loginNoAccount;
  final String registerNow;
  final String registerTitle;
  final String registerSubtitle;
  final String confirmPassHint;
  final String registerButton;
  final String haveAccount;
  final String loginHousehold;
  final String errEnterName;
  final String errEnterEmail;
  final String errPassShort;
  final String errPassMismatch;
  final String acMode;
  final String acFanSpeed;
  final String acSwing;
  final String acMethod;
  final String modeCool;
  final String modeHeat;
  final String modeFan;
  final String modeDry;
  final String modeAuto;
  final String fanLow;
  final String fanMed;
  final String fanHigh;
  final String mediaMaster;
  final String mediaParty;
  final String mediaStopAll;
  final String tvRemote;
  final String tvSource;
  final String tvChannel;
  final String tvMute;
  final String energyTitle;
  final String automationsTitle;
  final String activeAutomations;

  // Profile
  final String myProfile;
  final String myHome;
  final String usersTitle;
  final String subscriptionTitle;
  final String settingsTitle;
  final String helpTitle;
  final String signOut;
  final String languageLabel;
  final String themeLabel;
  final String darkMode;
  final String lightMode;
  final String saveChanges;
  final String editProfile;
  final String fullName;
  final String emailLabel;
  final String profileUpdated;
  final String signOutConfirm;
  final String signOutQuestion;
  final String confirmSignOut;

  // Security
  final String securityTitle;
  final String armedMode;
  final String disarmedMode;
  final String doorSensor;
  final String windowsSensor;
  final String motionSensors;
  final String smokeDetector;
  final String securedStatus;
  final String openStatus;
  final String activeStatus;
  final String normalStatus;
  final String panicButton;
  final String panicActivate;
  final String panicWarning;

  // Cameras
  final String allCameras;
  final String liveLabel;
  final String offlineLabel;
  final String addDeviceBtn;
  final String notificationsTitle;

  // Automations
  final String automationsAll;
  final String automationsRec;
  final String addAutomation;
  final String autoName;
  final String autoCondition;
  final String autoAction;
  // Recommended automations
  final String recPeakName;
  final String recPeakDesc;
  final String recTravelName;
  final String recTravelDesc;
  final String recTempName;
  final String recTempDesc;

  // Energy
  final String monthlyConsumption;
  final String activeDevices;
  final String fullReport;
  final String fromLastMonth;

  // Notifications
  final String allNotif;
  final String alertsNotif;
  final String camerasNotif;
  final String markAllRead;

  // Devices screen
  final String devicesTitle;
  final String allDevices;
  final String devicesOn;
  final String lightsCategory;
  final String blindsCategory;
  final String acCategory;
  final String plugsCategory;
  final String switchesCategory;
  final String sensorsCategory;
  final String deviceTemp;
  final String deviceBrightness;
  final String devicePosition;

  // Settings
  final String notifSettings;
  final String aboutApp;

  // AI screen
  final String aiInputHint;
  final String aiSug1;
  final String aiSug2;
  final String aiSug3;
  final String aiSug4;
  final String aiReply1;
  final String aiReply2;
  final String aiReply3;
  final String aiReply4;
  final String aiReplyDefault;

  // Add device
  final String addDeviceTitle;
  final String autoScan;
  final String deviceCatalog;
  final String searchHint;
  final String searching;
  final String devicesFound;
  final String noResults;

  // Devices nav
  final String navDevices;

  // Subscription sheet
  final String subscriptionPro;
  final String subscriptionValid;
  final String subscriptionRenew;
  final String subscriptionFeat1;
  final String subscriptionFeat2;
  final String subscriptionFeat3;
  final String subscriptionFeat4;

  // Add device catalog sections & scan
  final String catalogLights;
  final String catalogSwitches;
  final String catalogSensors;
  final String catalogCameras;
  final String catalogAC;
  final String catalogBlinds;
  final String catalogNetwork;
  final String scanPairingHint;
  final String acRemoteName;
  final String acRemoteCategory;
  final String acWifiName;
  final String acWifiCategory;

  // Catalog device names
  final String devBulb;
  final String devStrip;
  final String devSwitch;
  final String devDimmer;
  final String devPlug;
  final String devMotionSensor;
  final String devDoorSensor;
  final String devWindowSensor;
  final String devSmokeDetector;
  final String devIndoorCam;
  final String devOutdoorCam;
  final String devSmartAC;
  final String devWaterHeater;
  final String devThermostat;
  final String devSmartBlind;
  final String devSmartGate;
  final String devRouterWifi;
  final String devGwZigbee;
  final String devGwWifi;
  final String devGwMatter;

  // Catalog category labels
  final String catLight;
  final String catSwitch;
  final String catPlug;
  final String catSensor;
  final String catCamera;
  final String catClimate;
  final String catBlind;
  final String catGate;
  final String catRouter;
  final String catGateway;

  // Scan & devices UI
  final String networkLabel;
  final String wifiNotConnected;
  final String connectWifiHint;
  final String scanComplete;
  final String scanError;
  final String rescan;
  final String noDevicesOnNetwork;
  final String sameWifiHint;
  final String connectedStatus;
  final String noDevicesConnected;
  final String scanToDiscover;
  final String scanFindDevices;
  final String remove;
  final String deviceWillBeRemoved;
  final String ipAddressLabel;
  final String displayLabel;
  final String discoverDevices;
  final String scanViaGateway;

  // Discovery / scan progress messages
  final String scanStarting;
  final String scanWifiLog;
  final String scanWifiDoneFmt;    // '{n}' replaced with host count
  final String scanBleLog;
  final String scanBleDone;
  final String scanMatterLog;
  final String scanMatterDone;
  final String scanGatewayFmt;     // '{n}' replaced with device count
  final String scanGatewayDone;
  final String scanIdentifyingFmt; // '{n}' replaced with device count
  final String scanIdentifyingProgress;
  final String scanFinishedFmt;    // '{n}' replaced with found count
  final String scanFoundFmt;       // '{n}' replaced with found count
  final String scanNoDevicesFound;
  final String scanCancelledProgress;
  final String scanCancelledLog;

  // Profile photo
  final String fromGallery;
  final String fromCamera;
  final String removePhoto;

  // Camera labels
  final String cameraRoomIndoor;
  final String cameraRoomOutdoor;
  final String micLabel;
  final String speakLabel;
  final String screenshotLabel;
  final String recordLabel;

  // Connect flow
  final String deviceFound;
  final String linkDevice;
  final String deviceNotFound;
  final String retrySearch;

  // Cyber security screen
  final String cyberTitle;
  final String cyberScore;
  final String cyberNetProtected;
  final String cyberNeedsImprovement;
  final String cyberNoThreats;
  final String cyberActiveThreats;
  final String cyberLastScan;
  final String cyberDevicesMetric;
  final String cyberConnected;
  final String cyberThreats;
  final String cyberNoThreatsSub;
  final String cyberNeedsTreatment;
  final String cyberEncryption;
  final String cyberNetProtection;
  final String cyberFirewallTitle;
  final String cyberFirewallSub;
  final String cyberVpnSub;
  final String cyberDnsTitle;
  final String cyberDnsSub;
  final String cyberIotTitle;
  final String cyberIotSub;
  final String cyberDeviceAudit;
  final String cyberFirmware;
  final String cyberFirmwareUpToDate;
  final String cyberDefaultPassTitle;
  final String cyberDefaultPassSub;
  final String cyberSecurityProto;
  final String cyberRemoteAccess;
  final String cyberRemoteAccessSub;
  final String cyberStatusActive;
  final String cyberStatusOff;
  final String cyberStatusWarning;
  final String cyberBadgeOk;
  final String cyberBadgeRecommended;
  final String cyberBadgeCheck;
  final String cyberRecentEvents;
  final String cyberEvent1Time;
  final String cyberEvent1Text;
  final String cyberEvent2Time;
  final String cyberEvent2Text;
  final String cyberEvent3Time;
  final String cyberEvent3Text;
  final String cyberEvent4Time;
  final String cyberEvent4Text;
  final String cyberNavLabel;
  // Store screen
  final String storeTitle;
  final String storeNavLabel;
  final String storeFeatured;
  final String storeNewArrivals;
  final String storeAddToCart;
  final String storeComingSoon;
  final String storeSearchHint;
  final String storeNoResultsFor;
  final String storeSearchSite;
  final String storeViewAll;
  final String storeNotifyMe;
  final String storeNotifyDesc;
  final String storeYourEmail;
  final String storeHubProTagline;
  final String storeBrowserError;
  final String storeNotifySuccess;
  // Product names
  final String prodMotionSensor;
  final String prodBlindMotor;
  final String prodSmartPlug;
  final String prodLedStrip;

  // Common
  final String cancel;
  final String save;
  final String add;
  final String added;
  final String edit;
  final String delete;
  final String close;
  final String noNotifications;

  // Panic / emergency
  final String panicLabel;
  final String emergencyActivated;

  // Help & support
  final String helpFaq;
  final String helpContact;
  final String helpRegisterTitle;
  final String helpNameHint;
  final String helpEmailHint;
  final String helpMsgHint;
  final String helpSendBtn;
  final String helpSentSuccess;

  // Store
  final String visitWebsite;

  // Rooms management
  final String addRoom;
  final String editRoom;
  final String deleteRoom;
  final String roomNameHint;
  final String roomAdded;
  final String roomDeleted;
  final String roomEdited;
  final String roomIconLabel;

  // Default room names (used as translated keys for built-in rooms)
  final String roomNameLiving;
  final String roomNameBedroom;
  final String roomNameKitchen;
  final String roomNameKids;
  final String roomNameBalcony;

  /// Translates a room key (e.g. '__living__') to the current locale's name.
  /// Falls back to the raw string for user-created rooms.
  String translateRoomKey(String name) {
    switch (name) {
      case '__living__':  return roomNameLiving;
      case '__bedroom__': return roomNameBedroom;
      case '__kitchen__': return roomNameKitchen;
      case '__kids__':    return roomNameKids;
      case '__balcony__': return roomNameBalcony;
      default:            return name;
    }
  }

  // Solar system
  final String solarTitle;
  final String solarProduction;
  final String solarConsumption;
  final String solarBattery;
  final String solarGrid;
  final String solarFeedIn;
  final String solarToday;
  final String solarConnect;
  final String solarSaving;
  final String solarKw;
  final String solarStatus;

  // Energy graph tabs
  final String energyDay;
  final String energyWeek;
  final String energyMonth;
  final String energyPeak;

  // Circuit breakers
  final String breakersTitle;
  final String breakerMain;
  final String breakerOn;
  final String breakerOff;
  final String breakerTripped;
  final String breakerConnect;
  final String breakerAmps;
  final String breakerPanel;
  final String breakerWifi;
  final String breakerZigbee;

  // Calendar
  final String calendarTitle;
  final String calendarHebrew;
  final String calendarGregorian;
  final String calendarToday;
  final String calendarHoliday;
  final String hebrewYear;
  // Hebrew month names
  final String hMonthTishrei;
  final String hMonthCheshvan;
  final String hMonthKislev;
  final String hMonthTevet;
  final String hMonthShvat;
  final String hMonthAdar;
  final String hMonthNissan;
  final String hMonthIyar;
  final String hMonthSivan;
  final String hMonthTamuz;
  final String hMonthAv;
  final String hMonthElul;
  // Jewish holidays
  final String holidayRoshHashana;
  final String holidayYomKippur;
  final String holidaySukkot;
  final String holidaySheminiAtzeret;
  final String holidayHanukkah;
  final String holidayTuBishvat;
  final String holidayPurim;
  final String holidayPesach;
  final String holidayYomHaatzmaut;
  final String holidayLagBaomer;
  final String holidayShavuot;
  final String holidayTishaBeav;

  // Boiler / water heater switches
  final String boilerTitle;
  final String boilerOn;
  final String boilerOff;
  final String boilerSchedule;
  final String boilerTempLabel;
  final String boilerTimer;
  final String boilerMode;
  final String boilerModeEco;
  final String boilerModeFull;
  final String boilerConnect;
  final String boilerWifi;
  final String boilerZigbee;
  final String boilerAddDevice;
  final String boilerStatus;

  // Device name editing
  final String deviceEditName;
  final String deviceRename;
  final String deviceRenamed;

  // Boiler gateway / driver discovery
  final String boilerNotResponding;
  final String boilerFindGateway;
  final String boilerScanning;
  final String boilerGatewayFound;
  final String boilerGatewayNone;
  final String boilerDownloadDriver;
  final String boilerDriverDownloading;
  final String boilerDriverReady;
  final String boilerReconnect;
  final String boilerSelectGateway;

  // Smart sockets (energy)
  final String socketsTitle;
  final String socketRegister;
  final String socketRegistered;
  final String socketPower;
  final String socketAddNew;
  final String socketName;
  final String socketRoom;
  final String socketProtocol;

  // Home management & users
  final String homeManagerLabel;
  final String memberLabel;
  final String noHomeUsers;
  final String registerAsManager;
  final String addMember;
  final String memberName;
  final String setPinCode;
  final String pinCodeLabel;
  final String pinSaved;
  final String pinRemoved;
  // Rooms
  final String devicesInRoom;
  final String noDevicesInRoom;
  // Shabbat
  final String shabbatCandles;
  final String shabbatHavdalah;

  // AC carousel
  final String acConnected;
  final String acNoUnits;

  // Store ad banner (translated)
  final String adStoreLabel;
  final String adTrackTitle;
  final String adTrackSub;
  final String adFeaturedLabel;
  final String adFeaturedSub;
  final String adNewLabel;
  final String adNewSub;
  final String adAllLabel;
  final String adAllSub;
  final String adNoneLabel;
  final String adNoneSub;

  // Subscription plans
  final String planFree;
  final String planBasic;
  final String planAdvanced;
  final String planAdvancedPlus;
  final String planUnlimited;
  final String planCurrentBadge;
  final String planUpgradeNow;
  final String planSelected;
  final String planDevicesLabel;
  final String planRoomsLabel;
  final String planAutoLabel;
  final String planUnlimitedLabel;
  final String planAiLabel;
  final String planIntercomLabel;
  final String planCamerasLabel;
  final String planSupportLabel;
  final String planReadOnly;
  final String planViewOnly;
  final String planMonthly;
  final String planFreePrice;
  final String planBasicPrice;
  final String planAdvancedPrice;
  final String planAdvancedPlusPrice;
  final String planUnlimitedPrice;

  const S({
    required this.navHome,
    required this.navCameras,
    required this.navSecurity,
    required this.navProfile,
    required this.greetingPrefix,
    required this.homeSecured,
    required this.homeNotSecured,
    required this.allSystemsActive,
    required this.tapToActivate,
    required this.alarmTitle,
    required this.alarmSecured,
    required this.alarmOff,
    required this.roomManagement,
    required this.roomsUnit,
    required this.camerasTitle,
    required this.lightsOn,
    required this.lightingTitle,
    required this.tempTitle,
    required this.tempComfy,
    required this.aiSubtitle,
    required this.quickActions,
    required this.leaveHome,
    required this.turnOffAll,
    required this.goodNight,
    required this.movieMode,
    required this.mediaTitle,
    required this.mediaSpeakers,
    required this.mediaScan,
    required this.mediaNoDevices,
    required this.bioTitle,
    required this.bioPrompt,
    required this.bioEnable,
    required this.bioSkip,
    required this.bioReason,
    required this.onbNext,
    required this.onbStart,
    required this.onbSkip,
    required this.onbAllow,
    required this.onbLater,
    required this.onb1Title,
    required this.onb1Body,
    required this.onb2Title,
    required this.onb2Body,
    required this.onb3Title,
    required this.onb3Body,
    required this.onbPermTitle,
    required this.onbPermBody,
    required this.secSection,
    required this.bioLoginLabel,
    required this.bioLoginSub,
    required this.legalSection,
    required this.termsLabel,
    required this.privacyLabel,
    required this.sceneCreate,
    required this.sceneNew,
    required this.sceneName,
    required this.sceneActions,
    required this.actPlugs,
    required this.valKeep,
    required this.valOn,
    required this.valOff,
    required this.authEmailHint,
    required this.authPassHint,
    required this.loginGreeting,
    required this.loginSubtitle,
    required this.loginForgot,
    required this.loginButton,
    required this.authOr,
    required this.loginNoAccount,
    required this.registerNow,
    required this.registerTitle,
    required this.registerSubtitle,
    required this.confirmPassHint,
    required this.registerButton,
    required this.haveAccount,
    required this.loginHousehold,
    required this.errEnterName,
    required this.errEnterEmail,
    required this.errPassShort,
    required this.errPassMismatch,
    required this.acMode,
    required this.acFanSpeed,
    required this.acSwing,
    required this.acMethod,
    required this.modeCool,
    required this.modeHeat,
    required this.modeFan,
    required this.modeDry,
    required this.modeAuto,
    required this.fanLow,
    required this.fanMed,
    required this.fanHigh,
    required this.mediaMaster,
    required this.mediaParty,
    required this.mediaStopAll,
    required this.tvRemote,
    required this.tvSource,
    required this.tvChannel,
    required this.tvMute,
    required this.energyTitle,
    required this.automationsTitle,
    required this.activeAutomations,
    required this.myProfile,
    required this.myHome,
    required this.usersTitle,
    required this.subscriptionTitle,
    required this.settingsTitle,
    required this.helpTitle,
    required this.signOut,
    required this.languageLabel,
    required this.themeLabel,
    required this.darkMode,
    required this.lightMode,
    required this.saveChanges,
    required this.editProfile,
    required this.fullName,
    required this.emailLabel,
    required this.profileUpdated,
    required this.signOutConfirm,
    required this.signOutQuestion,
    required this.confirmSignOut,
    required this.securityTitle,
    required this.armedMode,
    required this.disarmedMode,
    required this.doorSensor,
    required this.windowsSensor,
    required this.motionSensors,
    required this.smokeDetector,
    required this.securedStatus,
    required this.openStatus,
    required this.activeStatus,
    required this.normalStatus,
    required this.panicButton,
    required this.panicActivate,
    required this.panicWarning,
    required this.allCameras,
    required this.liveLabel,
    required this.offlineLabel,
    required this.addDeviceBtn,
    required this.notificationsTitle,
    required this.automationsAll,
    required this.automationsRec,
    required this.addAutomation,
    required this.autoName,
    required this.autoCondition,
    required this.autoAction,
    required this.recPeakName,
    required this.recPeakDesc,
    required this.recTravelName,
    required this.recTravelDesc,
    required this.recTempName,
    required this.recTempDesc,
    required this.monthlyConsumption,
    required this.activeDevices,
    required this.fullReport,
    required this.fromLastMonth,
    required this.allNotif,
    required this.alertsNotif,
    required this.camerasNotif,
    required this.markAllRead,
    required this.devicesTitle,
    required this.allDevices,
    required this.devicesOn,
    required this.lightsCategory,
    required this.blindsCategory,
    required this.acCategory,
    required this.plugsCategory,
    required this.switchesCategory,
    required this.sensorsCategory,
    required this.deviceTemp,
    required this.deviceBrightness,
    required this.devicePosition,
    required this.notifSettings,
    required this.aboutApp,
    required this.aiInputHint,
    required this.aiSug1,
    required this.aiSug2,
    required this.aiSug3,
    required this.aiSug4,
    required this.aiReply1,
    required this.aiReply2,
    required this.aiReply3,
    required this.aiReply4,
    required this.aiReplyDefault,
    required this.addDeviceTitle,
    required this.autoScan,
    required this.deviceCatalog,
    required this.searchHint,
    required this.searching,
    required this.devicesFound,
    required this.noResults,
    required this.navDevices,
    required this.subscriptionPro,
    required this.subscriptionValid,
    required this.subscriptionRenew,
    required this.subscriptionFeat1,
    required this.subscriptionFeat2,
    required this.subscriptionFeat3,
    required this.subscriptionFeat4,
    required this.catalogLights,
    required this.catalogSwitches,
    required this.catalogSensors,
    required this.catalogCameras,
    required this.catalogAC,
    required this.catalogBlinds,
    required this.catalogNetwork,
    required this.scanPairingHint,
    required this.acRemoteName,
    required this.acRemoteCategory,
    required this.acWifiName,
    required this.acWifiCategory,
    required this.devBulb,
    required this.devStrip,
    required this.devSwitch,
    required this.devDimmer,
    required this.devPlug,
    required this.devMotionSensor,
    required this.devDoorSensor,
    required this.devWindowSensor,
    required this.devSmokeDetector,
    required this.devIndoorCam,
    required this.devOutdoorCam,
    required this.devSmartAC,
    required this.devWaterHeater,
    required this.devThermostat,
    required this.devSmartBlind,
    required this.devSmartGate,
    required this.devRouterWifi,
    required this.devGwZigbee,
    required this.devGwWifi,
    required this.devGwMatter,
    required this.catLight,
    required this.catSwitch,
    required this.catPlug,
    required this.catSensor,
    required this.catCamera,
    required this.catClimate,
    required this.catBlind,
    required this.catGate,
    required this.catRouter,
    required this.catGateway,
    required this.networkLabel,
    required this.wifiNotConnected,
    required this.connectWifiHint,
    required this.scanComplete,
    required this.scanError,
    required this.rescan,
    required this.noDevicesOnNetwork,
    required this.sameWifiHint,
    required this.connectedStatus,
    required this.noDevicesConnected,
    required this.scanToDiscover,
    required this.scanFindDevices,
    required this.remove,
    required this.deviceWillBeRemoved,
    required this.ipAddressLabel,
    required this.displayLabel,
    required this.discoverDevices,
    required this.scanViaGateway,
    required this.scanStarting,
    required this.scanWifiLog,
    required this.scanWifiDoneFmt,
    required this.scanBleLog,
    required this.scanBleDone,
    required this.scanMatterLog,
    required this.scanMatterDone,
    required this.scanGatewayFmt,
    required this.scanGatewayDone,
    required this.scanIdentifyingFmt,
    required this.scanIdentifyingProgress,
    required this.scanFinishedFmt,
    required this.scanFoundFmt,
    required this.scanNoDevicesFound,
    required this.scanCancelledProgress,
    required this.scanCancelledLog,
    required this.fromGallery,
    required this.fromCamera,
    required this.removePhoto,
    required this.cameraRoomIndoor,
    required this.cameraRoomOutdoor,
    required this.micLabel,
    required this.speakLabel,
    required this.screenshotLabel,
    required this.recordLabel,
    required this.deviceFound,
    required this.linkDevice,
    required this.deviceNotFound,
    required this.retrySearch,
    required this.cyberTitle, required this.cyberScore,
    required this.cyberNetProtected, required this.cyberNeedsImprovement,
    required this.cyberNoThreats, required this.cyberActiveThreats,
    required this.cyberLastScan, required this.cyberDevicesMetric,
    required this.cyberConnected, required this.cyberThreats,
    required this.cyberNoThreatsSub, required this.cyberNeedsTreatment,
    required this.cyberEncryption, required this.cyberNetProtection,
    required this.cyberFirewallTitle, required this.cyberFirewallSub,
    required this.cyberVpnSub, required this.cyberDnsTitle,
    required this.cyberDnsSub, required this.cyberIotTitle,
    required this.cyberIotSub, required this.cyberDeviceAudit,
    required this.cyberFirmware, required this.cyberFirmwareUpToDate,
    required this.cyberDefaultPassTitle, required this.cyberDefaultPassSub,
    required this.cyberSecurityProto, required this.cyberRemoteAccess,
    required this.cyberRemoteAccessSub, required this.cyberStatusActive,
    required this.cyberStatusOff, required this.cyberStatusWarning,
    required this.cyberBadgeOk, required this.cyberBadgeRecommended,
    required this.cyberBadgeCheck, required this.cyberRecentEvents,
    required this.cyberEvent1Time, required this.cyberEvent1Text,
    required this.cyberEvent2Time, required this.cyberEvent2Text,
    required this.cyberEvent3Time, required this.cyberEvent3Text,
    required this.cyberEvent4Time, required this.cyberEvent4Text,
    required this.cyberNavLabel,
    required this.storeTitle, required this.storeNavLabel,
    required this.storeFeatured, required this.storeNewArrivals,
    required this.storeAddToCart, required this.storeComingSoon,
    required this.storeSearchHint, required this.storeNoResultsFor,
    required this.storeSearchSite, required this.storeViewAll,
    required this.storeNotifyMe, required this.storeNotifyDesc,
    required this.storeYourEmail, required this.storeHubProTagline,
    required this.storeBrowserError, required this.storeNotifySuccess,
    required this.prodMotionSensor, required this.prodBlindMotor,
    required this.prodSmartPlug, required this.prodLedStrip,
    required this.cancel,
    required this.save,
    required this.add,
    required this.added,
    required this.edit,
    required this.delete,
    required this.close,
    required this.noNotifications,
    required this.panicLabel,
    required this.emergencyActivated,
    required this.helpFaq,
    required this.helpContact,
    required this.helpRegisterTitle,
    required this.helpNameHint,
    required this.helpEmailHint,
    required this.helpMsgHint,
    required this.helpSendBtn,
    required this.helpSentSuccess,
    required this.visitWebsite,
    required this.addRoom,
    required this.editRoom,
    required this.deleteRoom,
    required this.roomNameHint,
    required this.roomAdded,
    required this.roomDeleted,
    required this.roomEdited,
    required this.roomIconLabel,
    required this.roomNameLiving,
    required this.roomNameBedroom,
    required this.roomNameKitchen,
    required this.roomNameKids,
    required this.roomNameBalcony,
    required this.solarTitle, required this.solarProduction,
    required this.solarConsumption, required this.solarBattery,
    required this.solarGrid, required this.solarFeedIn,
    required this.solarToday, required this.solarConnect,
    required this.solarSaving, required this.solarKw, required this.solarStatus,
    required this.energyDay, required this.energyWeek,
    required this.energyMonth, required this.energyPeak,
    required this.breakersTitle, required this.breakerMain,
    required this.breakerOn, required this.breakerOff,
    required this.breakerTripped, required this.breakerConnect,
    required this.breakerAmps, required this.breakerPanel,
    required this.breakerWifi, required this.breakerZigbee,
    required this.calendarTitle, required this.calendarHebrew,
    required this.calendarGregorian, required this.calendarToday,
    required this.calendarHoliday, required this.hebrewYear,
    required this.hMonthTishrei, required this.hMonthCheshvan,
    required this.hMonthKislev, required this.hMonthTevet,
    required this.hMonthShvat, required this.hMonthAdar,
    required this.hMonthNissan, required this.hMonthIyar,
    required this.hMonthSivan, required this.hMonthTamuz,
    required this.hMonthAv, required this.hMonthElul,
    required this.holidayRoshHashana, required this.holidayYomKippur,
    required this.holidaySukkot, required this.holidaySheminiAtzeret,
    required this.holidayHanukkah, required this.holidayTuBishvat,
    required this.holidayPurim, required this.holidayPesach,
    required this.holidayYomHaatzmaut, required this.holidayLagBaomer,
    required this.holidayShavuot, required this.holidayTishaBeav,
    // Boiler
    required this.boilerTitle, required this.boilerOn, required this.boilerOff,
    required this.boilerSchedule, required this.boilerTempLabel,
    required this.boilerTimer, required this.boilerMode,
    required this.boilerModeEco, required this.boilerModeFull,
    required this.boilerConnect, required this.boilerWifi,
    required this.boilerZigbee, required this.boilerAddDevice,
    required this.boilerStatus,
    // Boiler gateway
    required this.boilerNotResponding, required this.boilerFindGateway,
    required this.boilerScanning, required this.boilerGatewayFound,
    required this.boilerGatewayNone, required this.boilerDownloadDriver,
    required this.boilerDriverDownloading, required this.boilerDriverReady,
    required this.boilerReconnect, required this.boilerSelectGateway,
    // Smart sockets
    required this.socketsTitle, required this.socketRegister,
    required this.socketRegistered, required this.socketPower,
    required this.socketAddNew, required this.socketName,
    required this.socketRoom, required this.socketProtocol,
    // Device editing
    required this.deviceEditName, required this.deviceRename,
    required this.deviceRenamed,
    // Plans
    required this.planFree, required this.planBasic,
    required this.planAdvanced, required this.planAdvancedPlus,
    required this.planUnlimited,
    required this.planCurrentBadge, required this.planUpgradeNow,
    required this.planSelected, required this.planDevicesLabel,
    required this.planRoomsLabel, required this.planAutoLabel,
    required this.planUnlimitedLabel, required this.planAiLabel,
    required this.planIntercomLabel,
    required this.planCamerasLabel, required this.planSupportLabel,
    required this.planReadOnly, required this.planViewOnly,
    required this.planMonthly,
    required this.planFreePrice, required this.planBasicPrice,
    required this.planAdvancedPrice, required this.planAdvancedPlusPrice,
    required this.planUnlimitedPrice,
    // Home management
    required this.homeManagerLabel, required this.memberLabel,
    required this.noHomeUsers, required this.registerAsManager,
    required this.addMember, required this.memberName,
    required this.setPinCode, required this.pinCodeLabel,
    required this.pinSaved, required this.pinRemoved,
    required this.devicesInRoom, required this.noDevicesInRoom,
    required this.shabbatCandles, required this.shabbatHavdalah,
    required this.acConnected, required this.acNoUnits,
    required this.adStoreLabel, required this.adTrackTitle, required this.adTrackSub,
    required this.adFeaturedLabel, required this.adFeaturedSub,
    required this.adNewLabel, required this.adNewSub,
    required this.adAllLabel, required this.adAllSub,
    required this.adNoneLabel, required this.adNoneSub,
  });

  factory S.of(AppLocale locale) {
    switch (locale) {
      case AppLocale.english:
        return _en;
      case AppLocale.arabic:
        return _ar;
      case AppLocale.amharic:
        return _am;
      case AppLocale.spanish:
        return _es;
      case AppLocale.russian:
        return _ru;
      case AppLocale.hebrew:
        return _he;
    }
  }

  // ── Hebrew ────────────────────────────────────────────────────
  static const S _he = S(
    navHome: 'בית', navCameras: 'מצלמות', navSecurity: 'אבטחה', navProfile: 'פרופיל',
    greetingPrefix: 'שלום', homeSecured: 'הבית שלך מוגן', homeNotSecured: 'הבית לא מוגן',
    allSystemsActive: 'כל המערכות פעילות', tapToActivate: 'לחץ להפעיל מערכת אבטחה',
    alarmTitle: 'אזעקה', alarmSecured: 'מוגן', alarmOff: 'כבויה', roomManagement: 'ניהול בית', roomsUnit: 'חדרים',
    camerasTitle: 'מצלמות', lightsOn: 'אורות דלוקים', lightingTitle: 'תאורה',
    tempTitle: 'טמפרטורה', tempComfy: 'נעים', aiSubtitle: 'איך אפשר לעזור לך?',
    quickActions: 'פעולות מהירות', leaveHome: 'יציאה מהבית', turnOffAll: 'כיבוי כל הבית', goodNight: 'לילה טוב', movieMode: 'מצב סרט',
    mediaTitle: 'מדיה', mediaSpeakers: 'רמקולים', mediaScan: 'סרוק מכשירים', mediaNoDevices: 'לא נמצאו רמקולים. לחץ סרוק.',
    bioTitle: 'כניסה מהירה', bioPrompt: 'להפעיל כניסה עם טביעת אצבע בפעמים הבאות?', bioEnable: 'הפעל', bioSkip: 'לא תודה', bioReason: 'אמת את זהותך כדי להיכנס',
    onbNext: 'הבא', onbStart: 'בוא נתחיל', onbSkip: 'דלג', onbAllow: 'אפשר', onbLater: 'אחר כך', onb1Title: 'ברוך הבא ל-FantaTech', onb1Body: 'הבית החכם שלך — תאורה, אבטחה, אקלים ואנרגיה, הכל במקום אחד.', onb2Title: 'שליטה מלאה', onb2Body: 'נהל מצלמות, חיישנים, מפסקים וגלאים מכל מקום, בכל שפה.', onb3Title: 'אוטומציות חכמות', onb3Body: 'צור סצנות, חסוך אנרגיה, וקבל התראות בזמן אמת.', onbPermTitle: 'הרשאות לגילוי מכשירים', onbPermBody: 'כדי לגלות מכשירים ברשת נדרשות הרשאות מיקום ו-Bluetooth. המידע נשאר במכשיר שלך בלבד.',
    secSection: 'אבטחה', bioLoginLabel: 'כניסה עם טביעת אצבע', bioLoginSub: 'היכנס במהירות עם ביומטריה', legalSection: 'משפטי ופרטיות', termsLabel: 'תנאי שימוש', privacyLabel: 'מדיניות פרטיות',
    sceneCreate: 'צור סצנה', sceneNew: 'סצנה חדשה', sceneName: 'שם הסצנה', sceneActions: 'פעולות', actPlugs: 'שקעים', valKeep: 'ללא שינוי', valOn: 'הדלק', valOff: 'כבה',
    authEmailHint: 'אימייל או טלפון', authPassHint: 'סיסמה', loginGreeting: 'שלום לך!', loginSubtitle: 'היכנס לחשבון שלך', loginForgot: 'שכחת סיסמה?', loginButton: 'התחבר', authOr: 'או', loginNoAccount: 'אין לך חשבון?', registerNow: 'הרשם עכשיו', registerTitle: 'יצירת חשבון', registerSubtitle: 'הצטרף לבית החכם של FantaTech', confirmPassHint: 'אימות סיסמה', registerButton: 'הרשם', haveAccount: 'כבר יש לך חשבון?', loginHousehold: 'כניסה כחבר בית',
    errEnterName: 'נא להזין שם מלא', errEnterEmail: 'נא להזין אימייל או טלפון', errPassShort: 'הסיסמה חייבת להכיל לפחות 6 תווים', errPassMismatch: 'הסיסמאות אינן תואמות',
    acMode: 'מצב', acFanSpeed: 'מהירות מאוורר', acSwing: 'סוויינג', acMethod: 'שיטת בקרה', modeCool: 'קירור', modeHeat: 'חימום', modeFan: 'מאוורר', modeDry: 'ייבוש', modeAuto: 'אוטו', fanLow: 'נמוך', fanMed: 'בינוני', fanHigh: 'גבוה',
    mediaMaster: 'עוצמה כללית', mediaParty: 'נגן בכל הרמקולים', mediaStopAll: 'עצור הכל',
    tvRemote: 'שלט טלוויזיה', tvSource: 'מקור', tvChannel: 'ערוץ', tvMute: 'השתק',
    energyTitle: 'צריכת אנרגיה', automationsTitle: 'אוטומציות', activeAutomations: 'אוטומציות פעילות',
    myProfile: 'הפרופיל שלי', myHome: 'הבית שלי', usersTitle: 'משתמשים',
    subscriptionTitle: 'מנוי וחיוב', settingsTitle: 'הגדרות', helpTitle: 'עזרה ותמיכה',
    signOut: 'יציאה מחשבון', languageLabel: 'שפה', themeLabel: 'מצב תצוגה',
    darkMode: 'כהה', lightMode: 'בהיר', saveChanges: 'שמור שינויים',
    editProfile: 'עריכת פרופיל', fullName: 'שם מלא', emailLabel: 'אימייל',
    profileUpdated: 'הפרופיל עודכן בהצלחה', signOutConfirm: 'יציאה מחשבון', signOutQuestion: 'האם לצאת מהחשבון?', confirmSignOut: 'יציאה',
    securityTitle: 'אבטחה', armedMode: 'מצב מוגן', disarmedMode: 'לא מוגן',
    doorSensor: 'דלת כניסה', windowsSensor: 'חלונות', motionSensors: 'חיישני תנועה', smokeDetector: 'גלאי עשן',
    securedStatus: 'מאובטח', openStatus: 'פתוח', activeStatus: 'פעיל', normalStatus: 'תקין',
    panicButton: 'כפתור חירום', panicActivate: 'הפעל!', panicWarning: 'פעולה זו תשלח התראת חירום',
    allCameras: 'כל המצלמות', liveLabel: 'LIVE', offlineLabel: 'לא מחובר',
    addDeviceBtn: 'הוסף מכשיר', notificationsTitle: 'התראות',
    automationsAll: 'כל האוטומציות', automationsRec: 'המלצות', addAutomation: 'הוסף אוטומציה',
    autoName: 'שם האוטומציה', autoCondition: 'תנאי (אם...)', autoAction: 'פעולה (אז...)',
    recPeakName: 'חיסכון בשעות שיא', recPeakDesc: 'כיבוי מכשירים לא חיוניים בין 17:00-20:00',
    recTravelName: 'מצב נסיעה', recTravelDesc: 'הפעלת אבטחה מלאה כשאתה מחוץ לעיר',
    recTempName: 'ניהול טמפרטורה', recTempDesc: 'שמור על 22° כשיש מישהו בבית',
    monthlyConsumption: 'צריכה חודשית', activeDevices: 'מכשירים פעילים', fullReport: 'צפה בדוח מלא', fromLastMonth: 'ממחודש הקודם',
    allNotif: 'הכל', alertsNotif: 'התראות', camerasNotif: 'מצלמות', markAllRead: 'סמן הכל כנקרא',
    devicesTitle: 'מכשירים', allDevices: 'הכל', devicesOn: 'מכשירים דלוקים',
    lightsCategory: 'אורות', blindsCategory: 'תריסים', acCategory: 'מזגנים',
    plugsCategory: 'שקעים', switchesCategory: 'מפסקים', sensorsCategory: 'חיישנים',
    deviceTemp: 'טמפרטורה', deviceBrightness: 'עוצמה', devicePosition: 'מיקום',
    notifSettings: 'הגדרות התראות', aboutApp: 'אודות האפליקציה',
    aiInputHint: 'הקש או דבר אליי',
    aiSug1: 'כבה את כל האורות',
    aiSug2: 'מה מצב הבית עכשיו?',
    aiSug3: 'הפעל מצב לילה',
    aiSug4: 'האם יש התראות פעילות?',
    aiReply1: 'כיבוי כל האורות... ✅\n8 אורות כובו בהצלחה.',
    aiReply2: 'הבית במצב תקין 🏠\n• אבטחה: מוגן ✅\n• אורות: 3 דלוקים\n• טמפרטורה: 24°C',
    aiReply3: 'מצב לילה הופעל 🌙\nכל האורות כובו, התריסים נסגרו.',
    aiReply4: 'בדיקת מערכת האבטחה... 🔍\nאין התראות פעילות. כל החיישנים תקינים.',
    aiReplyDefault: 'הבנתי! אני מטפל בזה עכשיו... 🤖\nנשלח עדכון בקרוב.',
    addDeviceTitle: 'הוסף מכשיר', autoScan: 'סריקה אוטומטית', deviceCatalog: 'קטלוג מכשירים',
    searchHint: 'חפש מכשיר או מפסק...', searching: 'מחפש מכשירים...', devicesFound: 'מכשירים שנמצאו', noResults: 'לא נמצאו תוצאות',
    navDevices: 'מכשירים',
    subscriptionPro: 'מנוי Pro', subscriptionValid: 'פעיל עד 31/12/2025', subscriptionRenew: 'חדש מנוי',
    subscriptionFeat1: 'מצלמות ללא הגבלה', subscriptionFeat2: 'אחסון ענן 30 יום', subscriptionFeat3: 'AI חכם', subscriptionFeat4: 'תמיכה 24/7',
    catalogLights: 'תאורה', catalogSwitches: 'מפסקים ושקעים', catalogSensors: 'חיישנים', catalogCameras: 'מצלמות', catalogAC: 'מיזוג ואקלים', catalogBlinds: 'תריסים ושערים', catalogNetwork: 'ראוטרים וגייטוויי',
    scanPairingHint: "ודא שהמכשיר במצב צ'יווד ושמחובר לחשמל",
    acRemoteName: 'שלט IR למזגן', acRemoteCategory: 'שלט חכם',
    acWifiName: 'מזגן WiFi חכם', acWifiCategory: 'מזגן WiFi',
    devBulb: 'נורה חכמה', devStrip: 'רצועת LED', devSwitch: 'מפסק חכם', devDimmer: 'עמעם חכם', devPlug: 'שקע חכם',
    devMotionSensor: 'חיישן תנועה', devDoorSensor: 'חיישן דלת', devWindowSensor: 'חיישן חלון', devSmokeDetector: 'גלאי עשן',
    devIndoorCam: 'מצלמה פנימית', devOutdoorCam: 'מצלמה חיצונית',
    devSmartAC: 'מזגן חכם', devWaterHeater: 'דוד מים', devThermostat: 'תרמוסטט',
    devSmartBlind: 'תריס חכם', devSmartGate: 'שער חכם',
    devRouterWifi: 'ראוטר WiFi', devGwZigbee: 'גייטוויי Zigbee', devGwWifi: 'גייטוויי WiFi', devGwMatter: 'גייטוויי Matter',
    catLight: 'תאורה', catSwitch: 'מפסק', catPlug: 'שקע', catSensor: 'חיישן', catCamera: 'מצלמה',
    catClimate: 'מיזוג', catBlind: 'תריס', catGate: 'שער', catRouter: 'ראוטר', catGateway: 'גייטוויי',
    networkLabel: 'רשת', wifiNotConnected: 'לא מחובר לרשת WiFi',
    connectWifiHint: 'התחבר לרשת WiFi ביתית ונסה שוב',
    scanComplete: 'סריקה הושלמה', scanError: 'שגיאה בסריקה', rescan: 'סרוק מחדש',
    noDevicesOnNetwork: 'לא נמצאו מכשירים ברשת',
    sameWifiHint: 'ודא שהמכשירים מחוברים לאותה רשת WiFi',
    connectedStatus: 'מחובר', noDevicesConnected: 'אין מכשירים מחוברים',
    scanToDiscover: 'סרוק את הרשת שלך כדי לגלות ולהוסיף מכשירים חכמים',
    scanFindDevices: 'סרוק ומצא מכשירים', remove: 'הסר',
    deviceWillBeRemoved: 'המכשיר יוסר מהרשימה', ipAddressLabel: 'כתובת IP',
    displayLabel: 'תצוגה', discoverDevices: 'גלה מכשירים', scanViaGateway: 'סורק דרך',
    scanStarting: 'מתחיל סריקה…',
    scanWifiLog: 'WiFiScanner: מתחיל סריקת LAN',
    scanWifiDoneFmt: 'WiFiScanner: סיים ({n} מארחים)',
    scanBleLog: 'BLEScanner: מתחיל סריקת BLE',
    scanBleDone: 'BLEScanner: סיים',
    scanMatterLog: 'MatterDiscovery: מחפש ב-mDNS',
    scanMatterDone: 'MatterDiscovery: סיים',
    scanGatewayFmt: 'בודק {n} מכשירים לזיהוי מעמיק',
    scanGatewayDone: 'זיהוי מעמיק: סיים',
    scanIdentifyingFmt: 'מזהה {n} מכשירים…',
    scanIdentifyingProgress: 'מזהה מכשירים…',
    scanFinishedFmt: 'סריקה הסתיימה — נמצאו {n} מכשירים',
    scanFoundFmt: 'נמצאו {n} מכשירים',
    scanNoDevicesFound: 'לא נמצאו מכשירים',
    scanCancelledProgress: 'הסריקה הופסקה',
    scanCancelledLog: 'הסריקה הופסקה על ידי המשתמש',
    fromGallery: 'בחר מהגלריה', fromCamera: 'צלם תמונה', removePhoto: 'הסר תמונה',
    cameraRoomIndoor: 'פנים', cameraRoomOutdoor: 'חוץ',
    micLabel: 'מיקרופון', speakLabel: 'דיבור', screenshotLabel: 'צילום', recordLabel: 'הקלטה',
    deviceFound: 'המכשיר נמצא!', linkDevice: 'קשר מכשיר',
    deviceNotFound: 'המכשיר לא נמצא', retrySearch: 'נסה שוב',
    cyberTitle: 'אבטחת סייבר', cyberScore: 'ציון', cyberNetProtected: 'הרשת מוגנת', cyberNeedsImprovement: 'דורש שיפור',
    cyberNoThreats: 'לא נמצאו איומים פעילים', cyberActiveThreats: 'איומים פעילים', cyberLastScan: 'עדכון אחרון: לפני 2 שעות',
    cyberDevicesMetric: 'מכשירים', cyberConnected: 'מחוברים', cyberThreats: 'איומים', cyberNoThreatsSub: 'ללא איומים',
    cyberNeedsTreatment: 'דורש טיפול', cyberEncryption: 'הצפנה', cyberNetProtection: 'הגנת רשת',
    cyberFirewallTitle: 'חומת אש (Firewall)', cyberFirewallSub: 'מגן על הרשת הביתית',
    cyberVpnSub: 'הצפנת תעבורת הרשת', cyberDnsTitle: 'חסימת DNS זדוני', cyberDnsSub: 'מסנן אתרים מסוכנים',
    cyberIotTitle: 'בידוד מכשירי IoT', cyberIotSub: 'רשת נפרדת למכשירים חכמים',
    cyberDeviceAudit: 'סקירת מכשירים', cyberFirmware: 'עדכוני קושחה', cyberFirmwareUpToDate: 'מכשירים עדכניים',
    cyberDefaultPassTitle: 'סיסמאות ברירת מחדל', cyberDefaultPassSub: 'לא נמצאו סיסמאות ברירת מחדל',
    cyberSecurityProto: 'פרוטוקול אבטחה', cyberRemoteAccess: 'גישה מרחוק', cyberRemoteAccessSub: 'מוגבלת למשתמשים מורשים',
    cyberStatusActive: 'פעיל', cyberStatusOff: 'כבוי', cyberStatusWarning: 'אזהרה',
    cyberBadgeOk: 'תקין', cyberBadgeRecommended: 'מומלץ', cyberBadgeCheck: 'בדוק',
    cyberRecentEvents: 'אירועים אחרונים',
    cyberEvent1Time: 'לפני 2 שעות', cyberEvent1Text: 'סריקת רשת הושלמה בהצלחה',
    cyberEvent2Time: 'לפני 6 שעות', cyberEvent2Text: 'מכשיר חדש התחבר לרשת',
    cyberEvent3Time: 'אתמול 22:14', cyberEvent3Text: 'ניסיון גישה לא מורשה נחסם',
    cyberEvent4Time: 'לפני 3 ימים', cyberEvent4Text: 'עדכון הגנה הותקן אוטומטית',
    cyberNavLabel: 'סייבר',
    storeTitle: 'החנות שלי', storeNavLabel: 'חנות', storeFeatured: 'מוצרים מומלצים',
    storeNewArrivals: 'חדש בחנות', storeAddToCart: 'הוסף לסל', storeComingSoon: 'בקרוב',
    storeSearchHint: 'חפש מוצרים…', storeNoResultsFor: 'לא נמצאו תוצאות עבור',
    storeSearchSite: 'חפש באתר FantaTech', storeViewAll: 'הצג הכל',
    storeNotifyMe: 'הודע לי', storeNotifyDesc: 'הכנס אימייל ונודיע לך כשה-Hub Pro 2.0 יהיה זמין:',
    storeYourEmail: 'האימייל שלך', storeHubProTagline: 'הדור הבא של מרכז הבית החכם.',
    storeBrowserError: 'לא ניתן לפתוח את הדפדפן',
    storeNotifySuccess: '✓ נרשמת בהצלחה! נעדכן אותך.',
    prodMotionSensor: 'חיישן תנועה Shelly', prodBlindMotor: 'מנוע תריס חכם',
    prodSmartPlug: 'שקע חכם 16A', prodLedStrip: 'רצועת LED 5מ',
    cancel: 'ביטול', save: 'שמור', add: 'הוסף', added: 'נוסף ✓', edit: 'ערוך', delete: 'מחיקה', close: 'סגור',
    noNotifications: 'אין התראות',
    panicLabel: 'חירום', emergencyActivated: '🚨 מצב חירום הופעל! הגורמים הרלוונטיים עודכנו.',
    helpFaq: 'שאלות נפוצות', helpContact: 'צור קשר',
    helpRegisterTitle: 'השאר פרטים', helpNameHint: 'שם מלא', helpEmailHint: 'כתובת אימייל',
    helpMsgHint: 'הודעה (אופציונלי)', helpSendBtn: 'שלח', helpSentSuccess: 'פרטיך נשמרו! נחזור אליך בקרוב.',
    visitWebsite: 'בקר באתר',
    addRoom: 'הוסף חדר', editRoom: 'ערוך חדר', deleteRoom: 'מחק חדר',
    roomNameHint: 'שם החדר', roomAdded: 'החדר נוסף', roomDeleted: 'החדר נמחק', roomEdited: 'החדר עודכן',
    roomIconLabel: 'אייקון',
    roomNameLiving: 'סלון', roomNameBedroom: 'חדר שינה', roomNameKitchen: 'מטבח',
    roomNameKids: 'חדר ילדים', roomNameBalcony: 'מרפסת',
    solarTitle: 'מערכת סולארית', solarProduction: 'ייצור', solarConsumption: 'צריכה',
    solarBattery: 'סוללה', solarGrid: 'רשת', solarFeedIn: 'הזנה לרשת',
    solarToday: 'היום', solarConnect: 'חבר מערכת', solarSaving: 'חיסכון',
    solarKw: 'קוט"ש', solarStatus: 'מצב מערכת',
    energyDay: 'יום', energyWeek: 'שבוע', energyMonth: 'חודש', energyPeak: 'שיא',
    breakersTitle: 'מפסקים חכמים', breakerMain: 'מפסק ראשי',
    breakerOn: 'פועל', breakerOff: 'כבוי', breakerTripped: 'נפל',
    breakerConnect: 'חבר מפסק', breakerAmps: 'אמפר',
    breakerPanel: 'לוח חשמל', breakerWifi: 'WiFi', breakerZigbee: 'Zigbee',
    calendarTitle: 'לוח שנה', calendarHebrew: 'לוח עברי', calendarGregorian: 'לוח גרגוריאני',
    calendarToday: 'היום', calendarHoliday: 'חג', hebrewYear: 'שנת',
    hMonthTishrei: 'תשרי', hMonthCheshvan: 'חשוון', hMonthKislev: 'כסלו',
    hMonthTevet: 'טבת', hMonthShvat: 'שבט', hMonthAdar: 'אדר',
    hMonthNissan: 'ניסן', hMonthIyar: 'אייר', hMonthSivan: 'סיוון',
    hMonthTamuz: 'תמוז', hMonthAv: 'אב', hMonthElul: 'אלול',
    holidayRoshHashana: 'ראש השנה', holidayYomKippur: 'יום כיפור',
    holidaySukkot: 'סוכות', holidaySheminiAtzeret: 'שמיני עצרת',
    holidayHanukkah: 'חנוכה', holidayTuBishvat: 'ט"ו בשבט',
    holidayPurim: 'פורים', holidayPesach: 'פסח',
    holidayYomHaatzmaut: 'יום העצמאות', holidayLagBaomer: 'ל"ג בעומר',
    holidayShavuot: 'שבועות', holidayTishaBeav: 'תשעה באב',
    // Boiler
    boilerTitle: 'דוד חכם', boilerOn: 'דלוק', boilerOff: 'כבוי',
    boilerSchedule: 'תזמון', boilerTempLabel: 'טמפרטורה',
    boilerTimer: 'טיימר', boilerMode: 'מצב',
    boilerModeEco: 'חיסכון', boilerModeFull: 'מלא',
    boilerConnect: 'חבר מכשיר', boilerWifi: 'WiFi',
    boilerZigbee: 'Zigbee', boilerAddDevice: 'הוסף דוד',
    boilerStatus: 'סטטוס',
    boilerNotResponding: 'לא מגיב', boilerFindGateway: 'חפש Gateway',
    boilerScanning: 'סורק רשת...', boilerGatewayFound: 'Gateway נמצא',
    boilerGatewayNone: 'לא נמצא Gateway', boilerDownloadDriver: 'הורד דרייבר',
    boilerDriverDownloading: 'מוריד...', boilerDriverReady: 'דרייבר מוכן ✓',
    boilerReconnect: 'התחבר מחדש', boilerSelectGateway: 'בחר Gateway',
    socketsTitle: 'שקעים חכמים', socketRegister: 'רשום שקע',
    socketRegistered: 'שקע נרשם', socketPower: 'צריכה',
    socketAddNew: 'הוסף שקע', socketName: 'שם השקע',
    socketRoom: 'חדר', socketProtocol: 'פרוטוקול',
    // Device editing
    deviceEditName: 'ערוך שם', deviceRename: 'שם חדש',
    deviceRenamed: 'השם עודכן',
    // Plans
    planFree: 'חינמי', planBasic: 'בסיסי',
    planAdvanced: 'מתקדם', planAdvancedPlus: 'מתקדם פלוס',
    planUnlimited: 'ללא הגבלה',
    planCurrentBadge: 'פעיל', planUpgradeNow: 'שדרג עכשיו',
    planSelected: 'נבחר', planDevicesLabel: 'מכשירים',
    planRoomsLabel: 'מכשירים', planAutoLabel: 'אוטומציות',
    planUnlimitedLabel: 'ללא הגבלה', planAiLabel: 'AI מוקפץ',
    planIntercomLabel: 'אינטרקום',
    planCamerasLabel: 'מצלמות', planSupportLabel: 'תמיכה',
    planReadOnly: 'צפייה בלבד', planViewOnly: 'שליטה: צפייה בלבד',
    planMonthly: '/ חודש',
    planFreePrice: '₪0', planBasicPrice: '₪19',
    planAdvancedPrice: '₪39', planAdvancedPlusPrice: '₪69',
    planUnlimitedPrice: '₪150',
    homeManagerLabel: 'מנהל בית', memberLabel: 'חבר משק בית',
    noHomeUsers: 'אין משתמשים רשומים', registerAsManager: 'הירשם כמנהל בית',
    addMember: 'הוסף חבר בית', memberName: 'שם החבר',
    setPinCode: 'הגדר קוד PIN', pinCodeLabel: 'קוד PIN (4 ספרות)',
    pinSaved: 'קוד PIN נשמר', pinRemoved: 'קוד PIN הוסר',
    devicesInRoom: 'מכשירים בחדר', noDevicesInRoom: 'אין מכשירים בחדר',
    shabbatCandles: 'הדלקת נרות', shabbatHavdalah: 'הבדלה',
    acConnected: 'מזגנים מחוברים', acNoUnits: 'אין מזגנים מחוברים',
    adStoreLabel: 'חנות FantaTech', adTrackTitle: 'מסלול פרסום',
    adTrackSub: 'בחר אילו מוצרים יוצגו בבאנר הדשבורד',
    adFeaturedLabel: 'מוצרים מובחרים', adFeaturedSub: 'Hub Pro, Camera 4K, Smart Bulb, חיישן',
    adNewLabel: 'חדש בחנות', adNewSub: 'תריס חכם, שקע 16A, Gateway, LED Strip',
    adAllLabel: 'כל המוצרים', adAllSub: 'רוטציה מלאה של כל הקטלוג',
    adNoneLabel: 'ללא פרסומות', adNoneSub: 'הסתר את הבאנר לחלוטין',
  );

  // ── English ───────────────────────────────────────────────────
  static const S _en = S(
    navHome: 'Home', navCameras: 'Cameras', navSecurity: 'Security', navProfile: 'Profile',
    greetingPrefix: 'Hello', homeSecured: 'Your home is secured', homeNotSecured: 'Home is not secured',
    allSystemsActive: 'All systems active', tapToActivate: 'Tap to activate security',
    alarmTitle: 'Alarm', alarmSecured: 'Secured', alarmOff: 'Off', roomManagement: 'Home Management', roomsUnit: 'rooms',
    camerasTitle: 'Cameras', lightsOn: 'lights on', lightingTitle: 'Lighting',
    tempTitle: 'Temperature', tempComfy: 'Comfortable', aiSubtitle: 'How can I help you?',
    quickActions: 'Quick Actions', leaveHome: 'Leave Home', turnOffAll: 'Turn Off All', goodNight: 'Good Night', movieMode: 'Movie Mode',
    mediaTitle: 'Media', mediaSpeakers: 'Speakers', mediaScan: 'Scan devices', mediaNoDevices: 'No speakers found. Tap scan.',
    bioTitle: 'Quick Sign-In', bioPrompt: 'Enable fingerprint login for next time?', bioEnable: 'Enable', bioSkip: 'Not now', bioReason: 'Authenticate to sign in',
    onbNext: 'Next', onbStart: 'Get Started', onbSkip: 'Skip', onbAllow: 'Allow', onbLater: 'Later', onb1Title: 'Welcome to FantaTech', onb1Body: 'Your smart home — lighting, security, climate and energy, all in one place.', onb2Title: 'Full Control', onb2Body: 'Manage cameras, sensors, switches and detectors from anywhere, in any language.', onb3Title: 'Smart Automations', onb3Body: 'Create scenes, save energy, and get real-time alerts.', onbPermTitle: 'Permissions for Device Discovery', onbPermBody: 'To find devices on your network we need Location and Bluetooth access. Your data stays on your device only.',
    secSection: 'Security', bioLoginLabel: 'Fingerprint Login', bioLoginSub: 'Sign in quickly with biometrics', legalSection: 'Legal & Privacy', termsLabel: 'Terms of Service', privacyLabel: 'Privacy Policy',
    sceneCreate: 'Create Scene', sceneNew: 'New Scene', sceneName: 'Scene name', sceneActions: 'Actions', actPlugs: 'Plugs', valKeep: 'No change', valOn: 'On', valOff: 'Off',
    authEmailHint: 'Email or phone', authPassHint: 'Password', loginGreeting: 'Hello!', loginSubtitle: 'Sign in to your account', loginForgot: 'Forgot password?', loginButton: 'Sign In', authOr: 'or', loginNoAccount: "Don't have an account?", registerNow: 'Register now', registerTitle: 'Create Account', registerSubtitle: 'Join the FantaTech smart home', confirmPassHint: 'Confirm password', registerButton: 'Register', haveAccount: 'Already have an account?', loginHousehold: 'Household Member',
    errEnterName: 'Please enter your full name', errEnterEmail: 'Please enter email or phone', errPassShort: 'Password must be at least 6 characters', errPassMismatch: 'Passwords do not match',
    acMode: 'Mode', acFanSpeed: 'Fan Speed', acSwing: 'Swing', acMethod: 'Control', modeCool: 'Cool', modeHeat: 'Heat', modeFan: 'Fan', modeDry: 'Dry', modeAuto: 'Auto', fanLow: 'Low', fanMed: 'Med', fanHigh: 'High',
    mediaMaster: 'Master Volume', mediaParty: 'Play on all', mediaStopAll: 'Stop all',
    tvRemote: 'TV Remote', tvSource: 'Source', tvChannel: 'Channel', tvMute: 'Mute',
    energyTitle: 'Energy Usage', automationsTitle: 'Automations', activeAutomations: 'active automations',
    myProfile: 'My Profile', myHome: 'My Home', usersTitle: 'Users',
    subscriptionTitle: 'Subscription', settingsTitle: 'Settings', helpTitle: 'Help & Support',
    signOut: 'Sign Out', languageLabel: 'Language', themeLabel: 'Theme',
    darkMode: 'Dark', lightMode: 'Light', saveChanges: 'Save Changes',
    editProfile: 'Edit Profile', fullName: 'Full Name', emailLabel: 'Email',
    profileUpdated: 'Profile updated successfully', signOutConfirm: 'Sign Out', signOutQuestion: 'Are you sure you want to sign out?', confirmSignOut: 'Sign Out',
    securityTitle: 'Security', armedMode: 'Armed', disarmedMode: 'Disarmed',
    doorSensor: 'Front Door', windowsSensor: 'Windows', motionSensors: 'Motion Sensors', smokeDetector: 'Smoke Detector',
    securedStatus: 'Secured', openStatus: 'Open', activeStatus: 'Active', normalStatus: 'Normal',
    panicButton: 'Panic Button', panicActivate: 'Activate!', panicWarning: 'This will send an emergency alert',
    allCameras: 'All Cameras', liveLabel: 'LIVE', offlineLabel: 'Offline',
    addDeviceBtn: 'Add Device', notificationsTitle: 'Notifications',
    automationsAll: 'All Automations', automationsRec: 'Suggestions', addAutomation: 'Add Automation',
    autoName: 'Automation Name', autoCondition: 'Condition (If...)', autoAction: 'Action (Then...)',
    recPeakName: 'Peak Hours Saving', recPeakDesc: 'Turn off non-essential devices between 17:00-20:00',
    recTravelName: 'Travel Mode', recTravelDesc: 'Full security when you are out of town',
    recTempName: 'Temperature Control', recTempDesc: 'Keep 22° when someone is home',
    monthlyConsumption: 'Monthly Usage', activeDevices: 'Active Devices', fullReport: 'View Full Report', fromLastMonth: 'from last month',
    allNotif: 'All', alertsNotif: 'Alerts', camerasNotif: 'Cameras', markAllRead: 'Mark all as read',
    devicesTitle: 'Devices', allDevices: 'All', devicesOn: 'devices on',
    lightsCategory: 'Lights', blindsCategory: 'Blinds', acCategory: 'AC',
    plugsCategory: 'Plugs', switchesCategory: 'Switches', sensorsCategory: 'Sensors',
    deviceTemp: 'Temperature', deviceBrightness: 'Brightness', devicePosition: 'Position',
    notifSettings: 'Notification Settings', aboutApp: 'About App',
    aiInputHint: 'Type or speak to me',
    aiSug1: 'Turn off all lights',
    aiSug2: "What's the home status?",
    aiSug3: 'Activate night mode',
    aiSug4: 'Are there active alerts?',
    aiReply1: 'Turning off all lights... ✅\n8 lights turned off successfully.',
    aiReply2: 'Home is in good condition 🏠\n• Security: Armed ✅\n• Lights: 3 on\n• Temperature: 24°C',
    aiReply3: 'Night mode activated 🌙\nAll lights off, blinds closed.',
    aiReply4: 'Checking security system... 🔍\nNo active alerts. All sensors normal.',
    aiReplyDefault: 'Got it! Working on that now... 🤖\nUpdate coming soon.',
    addDeviceTitle: 'Add Device', autoScan: 'Auto Scan', deviceCatalog: 'Device Catalog',
    searchHint: 'Search device or switch...', searching: 'Searching devices...', devicesFound: 'Devices Found', noResults: 'No results found',
    navDevices: 'Devices',
    subscriptionPro: 'Pro Subscription', subscriptionValid: 'Active until 31/12/2025', subscriptionRenew: 'Renew Subscription',
    subscriptionFeat1: 'Unlimited Cameras', subscriptionFeat2: '30-day Cloud Storage', subscriptionFeat3: 'Smart AI', subscriptionFeat4: '24/7 Support',
    catalogLights: 'Lighting', catalogSwitches: 'Switches & Plugs', catalogSensors: 'Sensors', catalogCameras: 'Cameras', catalogAC: 'AC & Climate', catalogBlinds: 'Blinds & Gates', catalogNetwork: 'Routers & Gateways',
    scanPairingHint: 'Make sure the device is in pairing mode and powered on',
    acRemoteName: 'AC IR Remote', acRemoteCategory: 'IR Remote',
    acWifiName: 'WiFi Air Conditioner', acWifiCategory: 'WiFi AC',
    devBulb: 'Smart Bulb', devStrip: 'LED Strip', devSwitch: 'Smart Switch', devDimmer: 'Smart Dimmer', devPlug: 'Smart Plug',
    devMotionSensor: 'Motion Sensor', devDoorSensor: 'Door Sensor', devWindowSensor: 'Window Sensor', devSmokeDetector: 'Smoke Detector',
    devIndoorCam: 'Indoor Camera', devOutdoorCam: 'Outdoor Camera',
    devSmartAC: 'Smart AC', devWaterHeater: 'Water Heater', devThermostat: 'Thermostat',
    devSmartBlind: 'Smart Blind', devSmartGate: 'Smart Gate',
    devRouterWifi: 'Router WiFi', devGwZigbee: 'Gateway Zigbee', devGwWifi: 'Gateway WiFi', devGwMatter: 'Matter Gateway',
    catLight: 'Light', catSwitch: 'Switch', catPlug: 'Plug', catSensor: 'Sensor', catCamera: 'Camera',
    catClimate: 'Climate', catBlind: 'Blind', catGate: 'Gate', catRouter: 'Router', catGateway: 'Gateway',
    networkLabel: 'Network', wifiNotConnected: 'Not connected to WiFi',
    connectWifiHint: 'Connect to your home WiFi and try again',
    scanComplete: 'Scan complete', scanError: 'Scan error', rescan: 'Scan again',
    noDevicesOnNetwork: 'No devices found on network',
    sameWifiHint: 'Make sure devices are connected to the same WiFi',
    connectedStatus: 'Connected', noDevicesConnected: 'No devices connected',
    scanToDiscover: 'Scan your network to discover and add smart devices',
    scanFindDevices: 'Scan & Find Devices', remove: 'Remove',
    deviceWillBeRemoved: 'The device will be removed from the list', ipAddressLabel: 'IP Address',
    displayLabel: 'Display', discoverDevices: 'Discover Devices', scanViaGateway: 'Scanning via',
    scanStarting: 'Starting scan…',
    scanWifiLog: 'WiFiScanner: starting LAN scan',
    scanWifiDoneFmt: 'WiFiScanner: done ({n} hosts)',
    scanBleLog: 'BLEScanner: starting BLE scan',
    scanBleDone: 'BLEScanner: done',
    scanMatterLog: 'MatterDiscovery: searching mDNS',
    scanMatterDone: 'MatterDiscovery: done',
    scanGatewayFmt: 'Deep-probing {n} devices',
    scanGatewayDone: 'Deep probe: done',
    scanIdentifyingFmt: 'Identifying {n} devices…',
    scanIdentifyingProgress: 'Identifying devices…',
    scanFinishedFmt: 'Scan complete — {n} devices found',
    scanFoundFmt: '{n} devices found',
    scanNoDevicesFound: 'No devices found',
    scanCancelledProgress: 'Scan cancelled',
    scanCancelledLog: 'Scan cancelled by user',
    fromGallery: 'Choose from Gallery', fromCamera: 'Take Photo', removePhoto: 'Remove Photo',
    cameraRoomIndoor: 'Indoor', cameraRoomOutdoor: 'Outdoor',
    micLabel: 'Mic', speakLabel: 'Talk', screenshotLabel: 'Capture', recordLabel: 'Record',
    deviceFound: 'Device Found!', linkDevice: 'Link Device',
    deviceNotFound: 'Device not found', retrySearch: 'Try Again',
    cyberTitle: 'Cyber Security', cyberScore: 'Score', cyberNetProtected: 'Network Protected', cyberNeedsImprovement: 'Needs Improvement',
    cyberNoThreats: 'No active threats found', cyberActiveThreats: 'active threats', cyberLastScan: 'Last update: 2 hours ago',
    cyberDevicesMetric: 'Devices', cyberConnected: 'Connected', cyberThreats: 'Threats', cyberNoThreatsSub: 'No threats',
    cyberNeedsTreatment: 'Needs attention', cyberEncryption: 'Encryption', cyberNetProtection: 'Network Protection',
    cyberFirewallTitle: 'Firewall', cyberFirewallSub: 'Protects home network',
    cyberVpnSub: 'Encrypts network traffic', cyberDnsTitle: 'Malicious DNS Blocking', cyberDnsSub: 'Filters dangerous sites',
    cyberIotTitle: 'IoT Device Isolation', cyberIotSub: 'Separate network for smart devices',
    cyberDeviceAudit: 'Device Audit', cyberFirmware: 'Firmware Updates', cyberFirmwareUpToDate: 'devices up to date',
    cyberDefaultPassTitle: 'Default Passwords', cyberDefaultPassSub: 'No default passwords found',
    cyberSecurityProto: 'Security Protocol', cyberRemoteAccess: 'Remote Access', cyberRemoteAccessSub: 'Limited to authorized users',
    cyberStatusActive: 'Active', cyberStatusOff: 'Off', cyberStatusWarning: 'Warning',
    cyberBadgeOk: 'OK', cyberBadgeRecommended: 'Recommended', cyberBadgeCheck: 'Check',
    cyberRecentEvents: 'Recent Events',
    cyberEvent1Time: '2 hours ago', cyberEvent1Text: 'Network scan completed successfully',
    cyberEvent2Time: '6 hours ago', cyberEvent2Text: 'New device connected to network',
    cyberEvent3Time: 'Yesterday 22:14', cyberEvent3Text: 'Unauthorized access attempt blocked',
    cyberEvent4Time: '3 days ago', cyberEvent4Text: 'Security update installed automatically',
    cyberNavLabel: 'Cyber',
    storeTitle: 'My Store', storeNavLabel: 'Store', storeFeatured: 'Featured Products',
    storeNewArrivals: 'New Arrivals', storeAddToCart: 'Add to Cart', storeComingSoon: 'Coming Soon',
    storeSearchHint: 'Search products…', storeNoResultsFor: 'No results for',
    storeSearchSite: 'Search on FantaTech', storeViewAll: 'View All',
    storeNotifyMe: 'Notify Me', storeNotifyDesc: 'Enter your email and we\'ll notify you when Hub Pro 2.0 is available:',
    storeYourEmail: 'Your email', storeHubProTagline: 'The next generation smart home hub.',
    storeBrowserError: 'Could not open the browser',
    storeNotifySuccess: '✓ Subscribed successfully! We\'ll keep you posted.',
    prodMotionSensor: 'Shelly Motion Sensor', prodBlindMotor: 'Smart Blind Motor',
    prodSmartPlug: 'Smart Plug 16A', prodLedStrip: 'LED Strip 5m',
    cancel: 'Cancel', save: 'Save', add: 'Add', added: 'Added ✓', edit: 'Edit', delete: 'Delete', close: 'Close',
    noNotifications: 'No notifications',
    panicLabel: 'PANIC', emergencyActivated: '🚨 Emergency mode activated! Authorities have been notified.',
    helpFaq: 'FAQ', helpContact: 'Contact Us',
    helpRegisterTitle: 'Register for Support', helpNameHint: 'Full Name', helpEmailHint: 'Email Address',
    helpMsgHint: 'Message (optional)', helpSendBtn: 'Send', helpSentSuccess: 'Details saved! We will get back to you soon.',
    visitWebsite: 'Visit Website',
    addRoom: 'Add Room', editRoom: 'Edit Room', deleteRoom: 'Delete Room',
    roomNameHint: 'Room name', roomAdded: 'Room added', roomDeleted: 'Room deleted', roomEdited: 'Room updated',
    roomIconLabel: 'Icon',
    roomNameLiving: 'Living Room', roomNameBedroom: 'Bedroom', roomNameKitchen: 'Kitchen',
    roomNameKids: 'Kids Room', roomNameBalcony: 'Balcony',
    solarTitle: 'Solar System', solarProduction: 'Production', solarConsumption: 'Consumption',
    solarBattery: 'Battery', solarGrid: 'Grid', solarFeedIn: 'Feed to Grid',
    solarToday: 'Today', solarConnect: 'Connect System', solarSaving: 'Savings',
    solarKw: 'kWh', solarStatus: 'System Status',
    energyDay: 'Day', energyWeek: 'Week', energyMonth: 'Month', energyPeak: 'Peak',
    breakersTitle: 'Smart Breakers', breakerMain: 'Main Breaker',
    breakerOn: 'On', breakerOff: 'Off', breakerTripped: 'Tripped',
    breakerConnect: 'Connect Breaker', breakerAmps: 'Amps',
    breakerPanel: 'Electrical Panel', breakerWifi: 'WiFi', breakerZigbee: 'Zigbee',
    calendarTitle: 'Calendar', calendarHebrew: 'Hebrew Calendar', calendarGregorian: 'Gregorian',
    calendarToday: 'Today', calendarHoliday: 'Holiday', hebrewYear: 'Year',
    hMonthTishrei: 'Tishrei', hMonthCheshvan: 'Cheshvan', hMonthKislev: 'Kislev',
    hMonthTevet: 'Tevet', hMonthShvat: 'Shvat', hMonthAdar: 'Adar',
    hMonthNissan: 'Nissan', hMonthIyar: 'Iyar', hMonthSivan: 'Sivan',
    hMonthTamuz: 'Tamuz', hMonthAv: 'Av', hMonthElul: 'Elul',
    holidayRoshHashana: 'Rosh Hashana', holidayYomKippur: 'Yom Kippur',
    holidaySukkot: 'Sukkot', holidaySheminiAtzeret: 'Shemini Atzeret',
    holidayHanukkah: 'Hanukkah', holidayTuBishvat: 'Tu Bishvat',
    holidayPurim: 'Purim', holidayPesach: 'Passover',
    holidayYomHaatzmaut: 'Yom Haatzmaut', holidayLagBaomer: "Lag B'Omer",
    holidayShavuot: 'Shavuot', holidayTishaBeav: "Tisha B'Av",
    boilerTitle: 'Smart Boiler', boilerOn: 'On', boilerOff: 'Off',
    boilerSchedule: 'Schedule', boilerTempLabel: 'Temperature',
    boilerTimer: 'Timer', boilerMode: 'Mode',
    boilerModeEco: 'Eco', boilerModeFull: 'Full',
    boilerConnect: 'Connect device', boilerWifi: 'WiFi',
    boilerZigbee: 'Zigbee', boilerAddDevice: 'Add Boiler',
    boilerStatus: 'Status',
    boilerNotResponding: 'Not responding', boilerFindGateway: 'Find Gateway',
    boilerScanning: 'Scanning network...', boilerGatewayFound: 'Gateway found',
    boilerGatewayNone: 'No gateway found', boilerDownloadDriver: 'Download driver',
    boilerDriverDownloading: 'Downloading...', boilerDriverReady: 'Driver ready ✓',
    boilerReconnect: 'Reconnect', boilerSelectGateway: 'Select Gateway',
    socketsTitle: 'Smart Sockets', socketRegister: 'Register socket',
    socketRegistered: 'Socket registered', socketPower: 'Power',
    socketAddNew: 'Add socket', socketName: 'Socket name',
    socketRoom: 'Room', socketProtocol: 'Protocol',
    deviceEditName: 'Edit Name', deviceRename: 'New name',
    deviceRenamed: 'Name updated',
    planFree: 'Free', planBasic: 'Basic',
    planAdvanced: 'Advanced', planAdvancedPlus: 'Advanced Plus',
    planUnlimited: 'Unlimited',
    planCurrentBadge: 'Active', planUpgradeNow: 'Upgrade Now',
    planSelected: 'Selected', planDevicesLabel: 'Devices',
    planRoomsLabel: 'Devices', planAutoLabel: 'Automations',
    planUnlimitedLabel: 'Unlimited', planAiLabel: 'AI Pop-up',
    planIntercomLabel: 'Intercom',
    planCamerasLabel: 'Cameras', planSupportLabel: 'Support',
    planReadOnly: 'View only', planViewOnly: 'Control: View only',
    planMonthly: '/ month',
    planFreePrice: '\$0', planBasicPrice: '\$19',
    planAdvancedPrice: '\$39', planAdvancedPlusPrice: '\$69',
    planUnlimitedPrice: '\$100',
    homeManagerLabel: 'Home Manager', memberLabel: 'Household Member',
    noHomeUsers: 'No registered users', registerAsManager: 'Register as Home Manager',
    addMember: 'Add Member', memberName: 'Member Name',
    setPinCode: 'Set PIN Code', pinCodeLabel: 'PIN Code (4 digits)',
    pinSaved: 'PIN saved', pinRemoved: 'PIN removed',
    devicesInRoom: 'Devices in Room', noDevicesInRoom: 'No devices in this room',
    shabbatCandles: 'Candle Lighting', shabbatHavdalah: 'Havdalah',
    acConnected: 'AC units connected', acNoUnits: 'No AC connected',
    adStoreLabel: 'FantaTech Store', adTrackTitle: 'Ad Settings',
    adTrackSub: 'Choose which products appear in the dashboard banner',
    adFeaturedLabel: 'Featured Products', adFeaturedSub: 'Hub Pro, Camera 4K, Smart Bulb, Sensor',
    adNewLabel: 'New in Store', adNewSub: 'Smart Blind, Smart Plug 16A, Gateway, LED Strip',
    adAllLabel: 'All Products', adAllSub: 'Full rotation of all catalog',
    adNoneLabel: 'No Ads', adNoneSub: 'Hide the banner completely',
  );

  // ── Arabic ────────────────────────────────────────────────────
  static const S _ar = S(
    navHome: 'الرئيسية', navCameras: 'كاميرات', navSecurity: 'أمان', navProfile: 'الملف',
    greetingPrefix: 'مرحباً', homeSecured: 'منزلك محمي', homeNotSecured: 'المنزل غير محمي',
    allSystemsActive: 'جميع الأنظمة نشطة', tapToActivate: 'اضغط لتفعيل الأمان',
    alarmTitle: 'إنذار', alarmSecured: 'محمي', alarmOff: 'معطل', roomManagement: 'إدارة المنزل', roomsUnit: 'غرف',
    camerasTitle: 'كاميرات', lightsOn: 'أضواء مضاءة', lightingTitle: 'إضاءة',
    tempTitle: 'الحرارة', tempComfy: 'مريح', aiSubtitle: 'كيف يمكنني مساعدتك؟',
    quickActions: 'إجراءات سريعة', leaveHome: 'مغادرة المنزل', turnOffAll: 'إيقاف الكل', goodNight: 'تصبح على خير', movieMode: 'وضع الفيلم',
    mediaTitle: 'الوسائط', mediaSpeakers: 'مكبرات الصوت', mediaScan: 'مسح الأجهزة', mediaNoDevices: 'لا توجد مكبرات. اضغط مسح.',
    bioTitle: 'دخول سريع', bioPrompt: 'تفعيل الدخول ببصمة الإصبع في المرة القادمة؟', bioEnable: 'تفعيل', bioSkip: 'ليس الآن', bioReason: 'وثّق هويتك لتسجيل الدخول',
    onbNext: 'التالي', onbStart: 'لنبدأ', onbSkip: 'تخطٍ', onbAllow: 'السماح', onbLater: 'لاحقاً', onb1Title: 'مرحباً بك في FantaTech', onb1Body: 'منزلك الذكي — الإضاءة والأمان والمناخ والطاقة في مكان واحد.', onb2Title: 'تحكم كامل', onb2Body: 'أدر الكاميرات والحساسات والمفاتيح والكواشف من أي مكان وبأي لغة.', onb3Title: 'أتمتة ذكية', onb3Body: 'أنشئ مشاهد ووفّر الطاقة واحصل على تنبيهات فورية.', onbPermTitle: 'أذونات اكتشاف الأجهزة', onbPermBody: 'لاكتشاف الأجهزة على شبكتك نحتاج إلى إذن الموقع والبلوتوث. تبقى بياناتك على جهازك فقط.',
    secSection: 'الأمان', bioLoginLabel: 'الدخول ببصمة الإصبع', bioLoginSub: 'سجّل الدخول بسرعة بالبصمة', legalSection: 'القانونية والخصوصية', termsLabel: 'شروط الخدمة', privacyLabel: 'سياسة الخصوصية',
    sceneCreate: 'إنشاء مشهد', sceneNew: 'مشهد جديد', sceneName: 'اسم المشهد', sceneActions: 'الإجراءات', actPlugs: 'المقابس', valKeep: 'بدون تغيير', valOn: 'تشغيل', valOff: 'إيقاف',
    authEmailHint: 'البريد أو الهاتف', authPassHint: 'كلمة المرور', loginGreeting: 'مرحباً!', loginSubtitle: 'سجّل الدخول إلى حسابك', loginForgot: 'نسيت كلمة المرور؟', loginButton: 'تسجيل الدخول', authOr: 'أو', loginNoAccount: 'ليس لديك حساب؟', registerNow: 'سجّل الآن', registerTitle: 'إنشاء حساب', registerSubtitle: 'انضم إلى منزل FantaTech الذكي', confirmPassHint: 'تأكيد كلمة المرور', registerButton: 'تسجيل', haveAccount: 'لديك حساب بالفعل؟', loginHousehold: 'فرد من المنزل',
    errEnterName: 'يرجى إدخال الاسم الكامل', errEnterEmail: 'يرجى إدخال البريد أو الهاتف', errPassShort: 'يجب أن تكون كلمة المرور 6 أحرف على الأقل', errPassMismatch: 'كلمتا المرور غير متطابقتين',
    acMode: 'الوضع', acFanSpeed: 'سرعة المروحة', acSwing: 'تأرجح', acMethod: 'التحكم', modeCool: 'تبريد', modeHeat: 'تدفئة', modeFan: 'مروحة', modeDry: 'تجفيف', modeAuto: 'تلقائي', fanLow: 'منخفض', fanMed: 'متوسط', fanHigh: 'مرتفع',
    mediaMaster: 'مستوى الصوت العام', mediaParty: 'تشغيل على الكل', mediaStopAll: 'إيقاف الكل',
    tvRemote: 'جهاز التحكم', tvSource: 'المصدر', tvChannel: 'القناة', tvMute: 'كتم',
    energyTitle: 'استهلاك الطاقة', automationsTitle: 'الأتمتة', activeAutomations: 'أتمتة نشطة',
    myProfile: 'ملفي الشخصي', myHome: 'منزلي', usersTitle: 'المستخدمون',
    subscriptionTitle: 'الاشتراك', settingsTitle: 'الإعدادات', helpTitle: 'المساعدة',
    signOut: 'تسجيل خروج', languageLabel: 'اللغة', themeLabel: 'المظهر',
    darkMode: 'داكن', lightMode: 'فاتح', saveChanges: 'حفظ التغييرات',
    editProfile: 'تعديل الملف', fullName: 'الاسم الكامل', emailLabel: 'البريد الإلكتروني',
    profileUpdated: 'تم تحديث الملف بنجاح', signOutConfirm: 'تسجيل خروج', signOutQuestion: 'هل تريد تسجيل الخروج؟', confirmSignOut: 'خروج',
    securityTitle: 'الأمان', armedMode: 'مفعّل', disarmedMode: 'معطل',
    doorSensor: 'باب الدخول', windowsSensor: 'النوافذ', motionSensors: 'كاشف الحركة', smokeDetector: 'كاشف الدخان',
    securedStatus: 'مؤمّن', openStatus: 'مفتوح', activeStatus: 'نشط', normalStatus: 'طبيعي',
    panicButton: 'زر الطوارئ', panicActivate: 'تفعيل!', panicWarning: 'سيتم إرسال تنبيه طوارئ',
    allCameras: 'كل الكاميرات', liveLabel: 'مباشر', offlineLabel: 'غير متصل',
    addDeviceBtn: 'إضافة جهاز', notificationsTitle: 'الإشعارات',
    automationsAll: 'كل الأتمتة', automationsRec: 'اقتراحات', addAutomation: 'إضافة أتمتة',
    autoName: 'اسم الأتمتة', autoCondition: 'الشرط (إذا...)', autoAction: 'الإجراء (إذاً...)',
    recPeakName: 'توفير ساعات الذروة', recPeakDesc: 'إطفاء الأجهزة غير الضرورية بين 17:00-20:00',
    recTravelName: 'وضع السفر', recTravelDesc: 'أمان كامل عندما تكون خارج المدينة',
    recTempName: 'التحكم بالحرارة', recTempDesc: 'حافظ على 22° عند وجود أحد في المنزل',
    monthlyConsumption: 'الاستهلاك الشهري', activeDevices: 'الأجهزة النشطة', fullReport: 'عرض التقرير الكامل', fromLastMonth: 'من الشهر الماضي',
    allNotif: 'الكل', alertsNotif: 'تنبيهات', camerasNotif: 'كاميرات', markAllRead: 'وضع علامة مقروء',
    devicesTitle: 'الأجهزة', allDevices: 'الكل', devicesOn: 'أجهزة نشطة',
    lightsCategory: 'إضاءة', blindsCategory: 'ستائر', acCategory: 'تكييف',
    plugsCategory: 'مقابس', switchesCategory: 'مفاتيح', sensorsCategory: 'حساسات',
    deviceTemp: 'الحرارة', deviceBrightness: 'السطوع', devicePosition: 'الموضع',
    notifSettings: 'إعدادات الإشعارات', aboutApp: 'حول التطبيق',
    aiInputHint: 'اكتب أو تحدث إليّ',
    aiSug1: 'أطفئ كل الأضواء',
    aiSug2: 'ما حالة المنزل الآن؟',
    aiSug3: 'تفعيل وضع الليل',
    aiSug4: 'هل هناك تنبيهات نشطة؟',
    aiReply1: 'إطفاء كل الأضواء... ✅\nتم إطفاء 8 أضواء بنجاح.',
    aiReply2: 'المنزل في حالة جيدة 🏠\n• الأمان: مفعّل ✅\n• الأضواء: 3 مضاءة\n• الحرارة: 24°C',
    aiReply3: 'وضع الليل مفعّل 🌙\nتم إطفاء الأضواء وإغلاق الستائر.',
    aiReply4: 'فحص نظام الأمان... 🔍\nلا تنبيهات نشطة حالياً. كل الحساسات سليمة.',
    aiReplyDefault: 'فهمت! أعمل على ذلك الآن... 🤖\nسيصلك تحديث قريباً.',
    addDeviceTitle: 'إضافة جهاز', autoScan: 'مسح تلقائي', deviceCatalog: 'كتالوج الأجهزة',
    searchHint: 'ابحث عن جهاز...', searching: 'جارٍ البحث...', devicesFound: 'الأجهزة المكتشفة', noResults: 'لا توجد نتائج',
    navDevices: 'الأجهزة',
    subscriptionPro: 'اشتراك Pro', subscriptionValid: 'نشط حتى 31/12/2025', subscriptionRenew: 'تجديد الاشتراك',
    subscriptionFeat1: 'كاميرات غير محدودة', subscriptionFeat2: 'تخزين سحابي 30 يوماً', subscriptionFeat3: 'ذكاء اصطناعي', subscriptionFeat4: 'دعم 24/7',
    catalogLights: 'إضاءة', catalogSwitches: 'مفاتيح ومقابس', catalogSensors: 'حساسات', catalogCameras: 'كاميرات', catalogAC: 'تكييف وأجواء', catalogBlinds: 'ستائر وبوابات', catalogNetwork: 'راوترات وبوابات',
    scanPairingHint: 'تأكد أن الجهاز في وضع الإقران ومتصل بالكهرباء',
    acRemoteName: 'ريموت IR للتكييف', acRemoteCategory: 'ريموت ذكي',
    acWifiName: 'مكيف WiFi ذكي', acWifiCategory: 'مكيف WiFi',
    devBulb: 'مصباح ذكي', devStrip: 'شريط LED', devSwitch: 'مفتاح ذكي', devDimmer: 'معتم ذكي', devPlug: 'قابس ذكي',
    devMotionSensor: 'كاشف حركة', devDoorSensor: 'كاشف الباب', devWindowSensor: 'كاشف النافذة', devSmokeDetector: 'كاشف الدخان',
    devIndoorCam: 'كاميرا داخلية', devOutdoorCam: 'كاميرا خارجية',
    devSmartAC: 'مكيف ذكي', devWaterHeater: 'سخان مياه', devThermostat: 'ثرموستات',
    devSmartBlind: 'ستارة ذكية', devSmartGate: 'بوابة ذكية',
    devRouterWifi: 'راوتر WiFi', devGwZigbee: 'بوابة Zigbee', devGwWifi: 'بوابة WiFi', devGwMatter: 'بوابة Matter',
    catLight: 'إضاءة', catSwitch: 'مفتاح', catPlug: 'قابس', catSensor: 'حساس', catCamera: 'كاميرا',
    catClimate: 'مناخ', catBlind: 'ستارة', catGate: 'بوابة', catRouter: 'راوتر', catGateway: 'بوابة',
    networkLabel: 'شبكة', wifiNotConnected: 'غير متصل بشبكة WiFi',
    connectWifiHint: 'اتصل بشبكة WiFi المنزلية وحاول مرة أخرى',
    scanComplete: 'اكتمل الفحص', scanError: 'خطأ في الفحص', rescan: 'فحص مجدداً',
    noDevicesOnNetwork: 'لم يتم العثور على أجهزة في الشبكة',
    sameWifiHint: 'تأكد أن الأجهزة متصلة بنفس شبكة WiFi',
    connectedStatus: 'متصل', noDevicesConnected: 'لا توجد أجهزة متصلة',
    scanToDiscover: 'افحص شبكتك لاكتشاف الأجهزة الذكية وإضافتها',
    scanFindDevices: 'فحص وإيجاد الأجهزة', remove: 'إزالة',
    deviceWillBeRemoved: 'سيتم إزالة الجهاز من القائمة', ipAddressLabel: 'عنوان IP',
    displayLabel: 'العرض', discoverDevices: 'اكتشاف الأجهزة', scanViaGateway: 'الفحص عبر',
    scanStarting: 'جارٍ بدء الفحص…',
    scanWifiLog: 'WiFiScanner: بدء فحص الشبكة',
    scanWifiDoneFmt: 'WiFiScanner: اكتمل ({n} مضيفاً)',
    scanBleLog: 'BLEScanner: بدء فحص البلوتوث',
    scanBleDone: 'BLEScanner: اكتمل',
    scanMatterLog: 'MatterDiscovery: البحث عبر mDNS',
    scanMatterDone: 'MatterDiscovery: اكتمل',
    scanGatewayFmt: 'فحص عميق لـ {n} جهاز',
    scanGatewayDone: 'الفحص العميق: اكتمل',
    scanIdentifyingFmt: 'تعريف {n} أجهزة…',
    scanIdentifyingProgress: 'جارٍ التعريف…',
    scanFinishedFmt: 'اكتمل الفحص — {n} أجهزة',
    scanFoundFmt: 'تم العثور على {n} جهاز',
    scanNoDevicesFound: 'لم يتم العثور على أجهزة',
    scanCancelledProgress: 'تم إلغاء الفحص',
    scanCancelledLog: 'ألغى المستخدم الفحص',
    fromGallery: 'اختر من المعرض', fromCamera: 'التقط صورة', removePhoto: 'إزالة الصورة',
    cameraRoomIndoor: 'داخلي', cameraRoomOutdoor: 'خارجي',
    micLabel: 'ميكروفون', speakLabel: 'تحدث', screenshotLabel: 'تصوير', recordLabel: 'تسجيل',
    deviceFound: 'تم العثور على الجهاز!', linkDevice: 'ربط الجهاز',
    deviceNotFound: 'الجهاز غير موجود', retrySearch: 'حاول مرة أخرى',
    cyberTitle: 'أمن إلكتروني', cyberScore: 'النتيجة', cyberNetProtected: 'الشبكة محمية', cyberNeedsImprovement: 'يحتاج تحسين',
    cyberNoThreats: 'لم تُعثر على تهديدات نشطة', cyberActiveThreats: 'تهديدات نشطة', cyberLastScan: 'آخر تحديث: قبل ساعتين',
    cyberDevicesMetric: 'الأجهزة', cyberConnected: 'متصلة', cyberThreats: 'التهديدات', cyberNoThreatsSub: 'لا تهديدات',
    cyberNeedsTreatment: 'يحتاج معالجة', cyberEncryption: 'التشفير', cyberNetProtection: 'حماية الشبكة',
    cyberFirewallTitle: 'جدار الحماية (Firewall)', cyberFirewallSub: 'يحمي الشبكة المنزلية',
    cyberVpnSub: 'تشفير حركة الشبكة', cyberDnsTitle: 'حجب DNS الضار', cyberDnsSub: 'يصفي المواقع الخطرة',
    cyberIotTitle: 'عزل أجهزة IoT', cyberIotSub: 'شبكة منفصلة للأجهزة الذكية',
    cyberDeviceAudit: 'مراجعة الأجهزة', cyberFirmware: 'تحديثات البرامج الثابتة', cyberFirmwareUpToDate: 'أجهزة محدّثة',
    cyberDefaultPassTitle: 'كلمات المرور الافتراضية', cyberDefaultPassSub: 'لم تُعثر على كلمات مرور افتراضية',
    cyberSecurityProto: 'بروتوكول الأمان', cyberRemoteAccess: 'الوصول عن بُعد', cyberRemoteAccessSub: 'مقيد للمستخدمين المصرح لهم',
    cyberStatusActive: 'نشط', cyberStatusOff: 'معطل', cyberStatusWarning: 'تحذير',
    cyberBadgeOk: 'جيد', cyberBadgeRecommended: 'موصى به', cyberBadgeCheck: 'تحقق',
    cyberRecentEvents: 'الأحداث الأخيرة',
    cyberEvent1Time: 'قبل ساعتين', cyberEvent1Text: 'اكتمل فحص الشبكة بنجاح',
    cyberEvent2Time: 'قبل 6 ساعات', cyberEvent2Text: 'جهاز جديد اتصل بالشبكة',
    cyberEvent3Time: 'أمس 22:14', cyberEvent3Text: 'تم حجب محاولة وصول غير مصرح بها',
    cyberEvent4Time: 'قبل 3 أيام', cyberEvent4Text: 'تم تثبيت تحديث أمان تلقائياً',
    cyberNavLabel: 'سيبر',
    storeTitle: 'متجري', storeNavLabel: 'متجر', storeFeatured: 'منتجات مميزة',
    storeNewArrivals: 'جديد في المتجر', storeAddToCart: 'أضف إلى السلة', storeComingSoon: 'قريباً',
    storeSearchHint: 'ابحث عن منتجات…', storeNoResultsFor: 'لا توجد نتائج لـ',
    storeSearchSite: 'ابحث في موقع FantaTech', storeViewAll: 'عرض الكل',
    storeNotifyMe: 'أبلغني', storeNotifyDesc: 'أدخل بريدك الإلكتروني وسنبلغك عند توفر Hub Pro 2.0:',
    storeYourEmail: 'بريدك الإلكتروني', storeHubProTagline: 'الجيل القادم من مركز المنزل الذكي.',
    storeBrowserError: 'تعذّر فتح المتصفح',
    storeNotifySuccess: '✓ تم الاشتراك بنجاح! سنبقيك على اطلاع.',
    prodMotionSensor: 'حساس حركة Shelly', prodBlindMotor: 'محرك ستائر ذكي',
    prodSmartPlug: 'مقبس ذكي 16A', prodLedStrip: 'شريط LED 5م',
    cancel: 'إلغاء', save: 'حفظ', add: 'إضافة', added: 'تمت الإضافة ✓', edit: 'تعديل', delete: 'حذف', close: 'إغلاق',
    noNotifications: 'لا توجد إشعارات',
    panicLabel: 'طوارئ', emergencyActivated: '🚨 تم تفعيل وضع الطوارئ! تم إخطار الجهات المختصة.',
    helpFaq: 'الأسئلة الشائعة', helpContact: 'اتصل بنا',
    helpRegisterTitle: 'سجّل للدعم', helpNameHint: 'الاسم الكامل', helpEmailHint: 'البريد الإلكتروني',
    helpMsgHint: 'رسالة (اختياري)', helpSendBtn: 'إرسال', helpSentSuccess: 'تم حفظ تفاصيلك! سنعود إليك قريباً.',
    visitWebsite: 'زيارة الموقع',
    addRoom: 'إضافة غرفة', editRoom: 'تعديل الغرفة', deleteRoom: 'حذف الغرفة',
    roomNameHint: 'اسم الغرفة', roomAdded: 'تمت إضافة الغرفة', roomDeleted: 'تم حذف الغرفة', roomEdited: 'تم تحديث الغرفة',
    roomIconLabel: 'أيقونة',
    roomNameLiving: 'غرفة المعيشة', roomNameBedroom: 'غرفة النوم', roomNameKitchen: 'المطبخ',
    roomNameKids: 'غرفة الأطفال', roomNameBalcony: 'الشرفة',
    solarTitle: 'نظام الطاقة الشمسية', solarProduction: 'الإنتاج', solarConsumption: 'الاستهلاك',
    solarBattery: 'البطارية', solarGrid: 'الشبكة', solarFeedIn: 'تغذية الشبكة',
    solarToday: 'اليوم', solarConnect: 'توصيل النظام', solarSaving: 'الوفورات',
    solarKw: 'كيلوواط', solarStatus: 'حالة النظام',
    energyDay: 'يوم', energyWeek: 'أسبوع', energyMonth: 'شهر', energyPeak: 'ذروة',
    breakersTitle: 'قواطع ذكية', breakerMain: 'القاطع الرئيسي',
    breakerOn: 'تشغيل', breakerOff: 'إيقاف', breakerTripped: 'انقطع',
    breakerConnect: 'توصيل القاطع', breakerAmps: 'أمبير',
    breakerPanel: 'لوحة الكهرباء', breakerWifi: 'WiFi', breakerZigbee: 'Zigbee',
    calendarTitle: 'التقويم', calendarHebrew: 'التقويم العبري', calendarGregorian: 'التقويم الميلادي',
    calendarToday: 'اليوم', calendarHoliday: 'عطلة', hebrewYear: 'السنة',
    hMonthTishrei: 'تشري', hMonthCheshvan: 'حشوان', hMonthKislev: 'كسلو',
    hMonthTevet: 'طيبت', hMonthShvat: 'شباط', hMonthAdar: 'آذار',
    hMonthNissan: 'نيسان', hMonthIyar: 'إيار', hMonthSivan: 'سيوان',
    hMonthTamuz: 'تموز', hMonthAv: 'آب', hMonthElul: 'إيلول',
    holidayRoshHashana: 'رأس السنة العبرية', holidayYomKippur: 'يوم الغفران',
    holidaySukkot: 'عيد العرش', holidaySheminiAtzeret: 'شميني عتسيرت',
    holidayHanukkah: 'حانوكا', holidayTuBishvat: 'تو بشفات',
    holidayPurim: 'بوريم', holidayPesach: 'الفصح',
    holidayYomHaatzmaut: 'يوم الاستقلال', holidayLagBaomer: 'لاج بعومر',
    holidayShavuot: 'شافوعوت', holidayTishaBeav: 'تاسع آب',
    boilerTitle: 'سخان ذكي', boilerOn: 'تشغيل', boilerOff: 'إيقاف',
    boilerSchedule: 'جدولة', boilerTempLabel: 'درجة الحرارة',
    boilerTimer: 'مؤقت', boilerMode: 'وضع',
    boilerModeEco: 'اقتصادي', boilerModeFull: 'كامل',
    boilerConnect: 'توصيل جهاز', boilerWifi: 'WiFi',
    boilerZigbee: 'Zigbee', boilerAddDevice: 'إضافة سخان',
    boilerStatus: 'الحالة',
    boilerNotResponding: 'لا يستجيب', boilerFindGateway: 'البحث عن Gateway',
    boilerScanning: 'جارٍ المسح...', boilerGatewayFound: 'تم العثور على Gateway',
    boilerGatewayNone: 'لم يُعثر على Gateway', boilerDownloadDriver: 'تحميل برنامج التشغيل',
    boilerDriverDownloading: 'جارٍ التحميل...', boilerDriverReady: 'جاهز ✓',
    boilerReconnect: 'إعادة الاتصال', boilerSelectGateway: 'اختر Gateway',
    socketsTitle: 'مآخذ ذكية', socketRegister: 'تسجيل مأخذ',
    socketRegistered: 'تم التسجيل', socketPower: 'استهلاك',
    socketAddNew: 'إضافة مأخذ', socketName: 'اسم المأخذ',
    socketRoom: 'غرفة', socketProtocol: 'بروتوكول',
    deviceEditName: 'تعديل الاسم', deviceRename: 'اسم جديد',
    deviceRenamed: 'تم تحديث الاسم',
    planFree: 'مجاني', planBasic: 'أساسي',
    planAdvanced: 'متقدم', planAdvancedPlus: 'متقدم بلس',
    planUnlimited: 'غير محدود',
    planCurrentBadge: 'نشط', planUpgradeNow: 'ترقية الآن',
    planSelected: 'مختار', planDevicesLabel: 'أجهزة',
    planRoomsLabel: 'أجهزة', planAutoLabel: 'أتمتة',
    planUnlimitedLabel: 'غير محدود', planAiLabel: 'AI منبثق',
    planIntercomLabel: 'إنترفون',
    planCamerasLabel: 'كاميرات', planSupportLabel: 'دعم',
    planReadOnly: 'عرض فقط', planViewOnly: 'تحكم: عرض فقط',
    planMonthly: '/ شهر',
    planFreePrice: '\$0', planBasicPrice: '\$19',
    planAdvancedPrice: '\$39', planAdvancedPlusPrice: '\$69',
    planUnlimitedPrice: '\$100',
    homeManagerLabel: 'مدير المنزل', memberLabel: 'فرد من الأسرة',
    noHomeUsers: 'لا يوجد مستخدمون مسجلون', registerAsManager: 'سجّل كمدير منزل',
    addMember: 'أضف فرداً', memberName: 'اسم الفرد',
    setPinCode: 'تعيين رمز PIN', pinCodeLabel: 'رمز PIN (4 أرقام)',
    pinSaved: 'تم حفظ PIN', pinRemoved: 'تم حذف PIN',
    devicesInRoom: 'الأجهزة في الغرفة', noDevicesInRoom: 'لا توجد أجهزة في هذه الغرفة',
    shabbatCandles: 'إضاءة الشموع', shabbatHavdalah: 'هافدالاه',
    acConnected: 'مكيفات متصلة', acNoUnits: 'لا توجد مكيفات متصلة',
    adStoreLabel: 'متجر FantaTech', adTrackTitle: 'إعدادات الإعلانات',
    adTrackSub: 'اختر المنتجات التي تظهر في البانر',
    adFeaturedLabel: 'منتجات مميزة', adFeaturedSub: 'Hub Pro, Camera 4K, Smart Bulb, Sensor',
    adNewLabel: 'الجديد في المتجر', adNewSub: 'Smart Blind, Smart Plug 16A, Gateway, LED Strip',
    adAllLabel: 'كل المنتجات', adAllSub: 'تناوب كامل لكل الكتالوج',
    adNoneLabel: 'بدون إعلانات', adNoneSub: 'إخفاء البانر بالكامل',
  );

  // ── Amharic ───────────────────────────────────────────────────
  static const S _am = S(
    navHome: 'ቤት', navCameras: 'ካሜራ', navSecurity: 'ደህንነት', navProfile: 'መገለጫ',
    greetingPrefix: 'ሰላም', homeSecured: 'ቤትህ ተጠብቋል', homeNotSecured: 'ቤትህ አልተጠበቀም',
    allSystemsActive: 'ሁሉም ስርዓቶች ንቁ', tapToActivate: 'ደህንነትን ለማንቃት ጫን',
    alarmTitle: 'ማንቂያ', alarmSecured: 'ጠብቋቷ', alarmOff: 'ጠፍቷ', roomManagement: 'የቤት አስተዳደር', roomsUnit: 'ክፍሎች',
    camerasTitle: 'ካሜራዎች', lightsOn: 'መብራቶች 켜져', lightingTitle: 'መብራት',
    tempTitle: 'ሙቀት', tempComfy: 'ምቹ', aiSubtitle: 'እንዴት ልረዳህ?',
    quickActions: 'ፈጣን ድርጊቶች', leaveHome: 'ቤት ውጣ', turnOffAll: 'ሁሉ አጥፋ', goodNight: 'መልካም ሌሊት', movieMode: 'የፊልም ሁነታ',
    mediaTitle: 'ሚዲያ', mediaSpeakers: 'ድምጽ ማጉያዎች', mediaScan: 'መሣሪያዎችን ቃኝ', mediaNoDevices: 'ድምጽ ማጉያ አልተገኘም። ቃኝን ይጫኑ።',
    bioTitle: 'ፈጣን መግቢያ', bioPrompt: 'በሚቀጥለው ጊዜ በጣት አሻራ መግባት ይነቃ?', bioEnable: 'አንቃ', bioSkip: 'አሁን አይደለም', bioReason: 'ለመግባት ማንነትዎን ያረጋግጡ',
    onbNext: 'ቀጣይ', onbStart: 'እንጀምር', onbSkip: 'ዝለል', onbAllow: 'ፍቀድ', onbLater: 'በኋላ', onb1Title: 'እንኳን ወደ FantaTech በደህና መጡ', onb1Body: 'ብልህ ቤትዎ — መብራት፣ ደህንነት፣ የአየር ሁኔታ እና ኢነርጂ በአንድ ቦታ።', onb2Title: 'ሙሉ ቁጥጥር', onb2Body: 'ካሜራዎችን፣ ዳሳሾችን፣ መቀየሪያዎችን ከየትኛውም ቦታ ያቀናብሩ።', onb3Title: 'ብልህ አውቶሜሽን', onb3Body: 'ትዕይንቶችን ይፍጠሩ፣ ኢነርጂ ይቆጥቡ፣ ወቅታዊ ማንቂያዎችን ያግኙ።', onbPermTitle: 'የመሣሪያ ፍለጋ ፍቃዶች', onbPermBody: 'በአውታረ መረብዎ ላይ መሣሪያዎችን ለማግኘት የአካባቢ እና የብሉቱዝ ፍቃድ ያስፈልጋል። ውሂብዎ በመሣሪያዎ ብቻ ይቆያል።',
    secSection: 'ደህንነት', bioLoginLabel: 'በጣት አሻራ መግባት', bioLoginSub: 'በባዮሜትሪክ በፍጥነት ይግቡ', legalSection: 'ህጋዊ እና ግላዊነት', termsLabel: 'የአገልግሎት ውሎች', privacyLabel: 'የግላዊነት ፖሊሲ',
    sceneCreate: 'ትዕይንት ፍጠር', sceneNew: 'አዲስ ትዕይንት', sceneName: 'የትዕይንት ስም', sceneActions: 'ድርጊቶች', actPlugs: 'ሶኬቶች', valKeep: 'ሳይቀየር', valOn: 'አብራ', valOff: 'አጥፋ',
    authEmailHint: 'ኢሜል ወይም ስልክ', authPassHint: 'የይለፍ ቃል', loginGreeting: 'ሰላም!', loginSubtitle: 'ወደ መለያዎ ይግቡ', loginForgot: 'የይለፍ ቃል ረሱ?', loginButton: 'ግባ', authOr: 'ወይም', loginNoAccount: 'መለያ የለዎትም?', registerNow: 'አሁን ይመዝገቡ', registerTitle: 'መለያ ይፍጠሩ', registerSubtitle: 'ወደ FantaTech ስማርት ቤት ይቀላቀሉ', confirmPassHint: 'የይለፍ ቃል ያረጋግጡ', registerButton: 'ይመዝገቡ', haveAccount: 'አስቀድሞ መለያ አለዎት?', loginHousehold: 'የቤተሰብ አባል',
    errEnterName: 'እባክዎ ሙሉ ስም ያስገቡ', errEnterEmail: 'እባክዎ ኢሜል ወይም ስልክ ያስገቡ', errPassShort: 'የይለፍ ቃል ቢያንስ 6 ቁምፊዎች መሆን አለበት', errPassMismatch: 'የይለፍ ቃላት አይዛመዱም',
    acMode: 'ሁነታ', acFanSpeed: 'የአየር ፍጥነት', acSwing: 'ማወዛወዝ', acMethod: 'መቆጣጠሪያ', modeCool: 'ማቀዝቀዝ', modeHeat: 'ማሞቅ', modeFan: 'ማራገቢያ', modeDry: 'ማድረቅ', modeAuto: 'ራስ-ሰር', fanLow: 'ዝቅተኛ', fanMed: 'መካከለኛ', fanHigh: 'ከፍተኛ',
    mediaMaster: 'አጠቃላይ ድምጽ', mediaParty: 'በሁሉም ላይ አጫውት', mediaStopAll: 'ሁሉንም አቁም',
    tvRemote: 'የቲቪ መቆጣጠሪያ', tvSource: 'ምንጭ', tvChannel: 'ጣቢያ', tvMute: 'ድምጽ አጥፋ',
    energyTitle: 'ኃይል ፍጆታ', automationsTitle: 'አውቶሜሽን', activeAutomations: 'ንቁ አውቶሜሽን',
    myProfile: 'የኔ መገለጫ', myHome: 'የኔ ቤት', usersTitle: 'ተጠቃሚዎች',
    subscriptionTitle: 'ምዝገባ', settingsTitle: 'ቅንብሮች', helpTitle: 'እርዳታ',
    signOut: 'ውጣ', languageLabel: 'ቋንቋ', themeLabel: 'ቅርጸ-ቀለም',
    darkMode: 'ጨለማ', lightMode: 'ብርሃን', saveChanges: 'ለውጦችን አስቀምጥ',
    editProfile: 'መገለጫ አርትዕ', fullName: 'ሙሉ ስም', emailLabel: 'ኢሜይል',
    profileUpdated: 'መገለጫ ተዘምኗ', signOutConfirm: 'ውጣ', signOutQuestion: 'ለመውጣት እርግጠኛ ነህ?', confirmSignOut: 'ውጣ',
    securityTitle: 'ደህንነት', armedMode: 'ታጥቋ', disarmedMode: ' አልታጠቀም',
    doorSensor: 'የፊት ደጃፍ', windowsSensor: 'መስኮቶች', motionSensors: 'እንቅስቃሴ ዳሳሽ', smokeDetector: 'ጭስ ዳሳሽ',
    securedStatus: 'ተጠብቋ', openStatus: 'ክፍት', activeStatus: 'ንቁ', normalStatus: 'መደበኛ',
    panicButton: 'አደጋ ቁልፍ', panicActivate: 'አንቃ!', panicWarning: 'የአደጋ ማንቂያ ይላካል',
    allCameras: 'ሁሉም ካሜራዎች', liveLabel: 'ቀጥታ', offlineLabel: 'ከስርዓት ውጭ',
    addDeviceBtn: 'መሳሪያ ጨምር', notificationsTitle: 'ማሳወቂያዎች',
    automationsAll: 'ሁሉም አውቶሜሽን', automationsRec: 'ምክሮች', addAutomation: 'አውቶሜሽን ጨምር',
    autoName: 'የአውቶሜሽን ስም', autoCondition: 'ሁኔታ (ከሆነ...)', autoAction: 'ድርጊት (ያኔ...)',
    recPeakName: 'የጫፍ ሰዓት ቁጠባ', recPeakDesc: 'አስፈላጊ ያልሆኑ መሣሪያዎችን ከ17:00-20:00 ማጥፋት',
    recTravelName: 'የጉዞ ሁነታ', recTravelDesc: 'ከከተማ ውጭ ሲሆኑ ሙሉ ደህንነት',
    recTempName: 'የሙቀት ቁጥጥር', recTempDesc: 'አንድ ሰው ቤት ሲኖር 22° ይጠብቁ',
    monthlyConsumption: 'ወርሃዊ ፍጆታ', activeDevices: 'ንቁ መሳሪያዎች', fullReport: 'ሙሉ ሪፖርት ይመልከቱ', fromLastMonth: 'ካለፈው ወር',
    allNotif: 'ሁሉም', alertsNotif: 'ማንቂያዎች', camerasNotif: 'ካሜራዎች', markAllRead: 'ሁሉ ታይቷ ምልክት',
    devicesTitle: 'መሳሪያዎች', allDevices: 'ሁሉም', devicesOn: 'መሳሪያዎች ንቁ',
    lightsCategory: 'መብራቶች', blindsCategory: 'መጋረጃዎች', acCategory: 'ማቀዝቀዣ',
    plugsCategory: 'ሶኬቶች', switchesCategory: 'ማብሪያዎች', sensorsCategory: 'ሴንሰሮች',
    deviceTemp: 'ሙቀት', deviceBrightness: 'ብሩህነት', devicePosition: 'ቦታ',
    notifSettings: 'የማሳወቂያ ቅንብሮች', aboutApp: 'ስለ መተግበሪያ',
    aiInputHint: 'ተፃፍ ወይም ተናገር',
    aiSug1: 'ሁሉም መብራቶች አጥፋ',
    aiSug2: 'የቤቱ ሁኔታ ምንድን ነው?',
    aiSug3: 'የሌሊት ሁነታ አንቃ',
    aiSug4: 'ንቁ ማስጠንቀቂያዎች አሉ?',
    aiReply1: 'ሁሉም መብራቶች ጠፍተዋል... ✅\n8 መብራቶች ጠፍተዋል።',
    aiReply2: 'ቤቱ ጥሩ ሁኔታ ላይ ነው 🏠\n• ደህንነት: ንቁ ✅\n• መብራቶች: 3 ኦን\n• ሙቀት: 24°C',
    aiReply3: 'የሌሊት ሁነታ ተነቃ 🌙\nሁሉም መብራቶች ጠፍቷ፣ ቅጠሎች ተዘጉ።',
    aiReply4: 'የደህንነት ስርዓት እየተፈተሸ... 🔍\nምንም ንቁ ማስጠንቀቂያ የለም። ሁሉም ሴንሰሮች ይሰራሉ።',
    aiReplyDefault: 'ገባኝ! አሁን እየሰራሁ ነው... 🤖\nሪፖርት ይደርሳል።',
    addDeviceTitle: 'መሳሪያ ጨምር', autoScan: 'አውቶ ቅኝት', deviceCatalog: 'የመሳሪያ ዝርዝር',
    searchHint: 'መሳሪያ ፈልግ...', searching: 'መሳሪያዎች እየተፈለጉ...', devicesFound: 'የተገኙ መሳሪያዎች', noResults: 'ምንም አልተገኘም',
    navDevices: 'መሳሪያዎች',
    subscriptionPro: 'Pro ምዝገባ', subscriptionValid: 'እስከ 31/12/2025', subscriptionRenew: 'ምዝገባ አድስ',
    subscriptionFeat1: 'ያልተገደበ ካሜራ', subscriptionFeat2: '30 ቀን ክላውድ', subscriptionFeat3: 'ብልህ AI', subscriptionFeat4: '24/7 ድጋፍ',
    catalogLights: 'መብራቶች', catalogSwitches: 'ማብሪያዎች', catalogSensors: 'ሴንሰሮች', catalogCameras: 'ካሜራዎች', catalogAC: 'ማቀዝቀዣ', catalogBlinds: 'መጋረጃዎች', catalogNetwork: 'ራውተሮች',
    scanPairingHint: 'መሣሪያው የጥናት ሁነታ ላይ መሆኑን አረጋግጥ',
    acRemoteName: 'የAC IR ሪሞት', acRemoteCategory: 'IR ሪሞት',
    acWifiName: 'WiFi ማቀዝቀዣ', acWifiCategory: 'WiFi AC',
    devBulb: 'ስማርት አምፑል', devStrip: 'LED ሪቦን', devSwitch: 'ስማርት ማብሪያ', devDimmer: 'ዲመር', devPlug: 'ስማርት ሶኬት',
    devMotionSensor: 'እንቅስቃሴ ሴንሰር', devDoorSensor: 'ደጃፍ ሴንሰር', devWindowSensor: 'መስኮት ሴንሰር', devSmokeDetector: 'ጭስ ዳሳሽ',
    devIndoorCam: 'ውስጣዊ ካሜራ', devOutdoorCam: 'ውጫዊ ካሜራ',
    devSmartAC: 'ስማርት AC', devWaterHeater: 'የውሃ ማሞቂያ', devThermostat: 'ቴርሞስታት',
    devSmartBlind: 'ስማርት ቅጠል', devSmartGate: 'ስማርት በር',
    devRouterWifi: 'WiFi ራውተር', devGwZigbee: 'Zigbee ጌትዌይ', devGwWifi: 'WiFi ጌትዌይ', devGwMatter: 'Matter ጌትዌይ',
    catLight: 'ብርሃን', catSwitch: 'ማብሪያ', catPlug: 'ሶኬት', catSensor: 'ሴንሰር', catCamera: 'ካሜራ',
    catClimate: 'ማቀዝቀዣ', catBlind: 'ቅጠል', catGate: 'በር', catRouter: 'ራውተር', catGateway: 'ጌትዌይ',
    networkLabel: 'ኔትወርክ', wifiNotConnected: 'ወደ WiFi አልተገናኘም',
    connectWifiHint: 'ወደ ቤት WiFi ይገናኙ እና እንደገና ይሞክሩ',
    scanComplete: 'ቅኝት ተጠናቅቋ', scanError: 'የቅኝት ስህተት', rescan: 'እንደገና ቅኝ',
    noDevicesOnNetwork: 'በኔትወርክ ላይ ምንም መሣሪያ አልተገኘም',
    sameWifiHint: 'መሣሪያዎቹ ወደ ተመሳሳይ WiFi መገናኘታቸውን ያረጋግጡ',
    connectedStatus: 'ተገናኝቷ', noDevicesConnected: 'ምንም መሳሪያ አልተገናኘም',
    scanToDiscover: 'ስማርት መሳሪያዎችን ለማግኘት ኔትወርክዎን ይቃኙ',
    scanFindDevices: 'ቅኝ እና ፈልግ', remove: 'አስወግድ',
    deviceWillBeRemoved: 'መሣሪያው ከዝርዝሩ ይወገዳል', ipAddressLabel: 'IP አድራሻ',
    displayLabel: 'ማሳያ', discoverDevices: 'መሳሪያዎችን ፈልግ', scanViaGateway: 'ቅኝት ያደርጋል',
    scanStarting: 'ፍተሻ እየጀመረ…',
    scanWifiLog: 'WiFiScanner: LAN ፍተሻ እየጀመረ',
    scanWifiDoneFmt: 'WiFiScanner: ተጠናቀቀ ({n} አስተናጋጆች)',
    scanBleLog: 'BLEScanner: BLE ፍተሻ እየጀመረ',
    scanBleDone: 'BLEScanner: ተጠናቀቀ',
    scanMatterLog: 'MatterDiscovery: mDNS እየፈለገ',
    scanMatterDone: 'MatterDiscovery: ተጠናቀቀ',
    scanGatewayFmt: '{n} መሳሪያዎችን ጥልቅ ፍተሻ',
    scanGatewayDone: 'ጥልቅ ፍተሻ: ተጠናቀቀ',
    scanIdentifyingFmt: '{n} መሳሪያዎችን እየለየ…',
    scanIdentifyingProgress: 'መሳሪያዎችን እየለየ…',
    scanFinishedFmt: 'ፍተሻ ተጠናቀቀ — {n} መሳሪያዎች',
    scanFoundFmt: '{n} መሳሪያዎች ተገኙ',
    scanNoDevicesFound: 'ምንም መሳሪያ አልተገኘም',
    scanCancelledProgress: 'ፍተሻ ተሰርዟል',
    scanCancelledLog: 'ፍተሻው በተጠቃሚ ተሰርዟል',
    fromGallery: 'ከጋለሪ ምረጥ', fromCamera: 'ፎቶ ቅረጽ', removePhoto: 'ፎቶ አስወግድ',
    cameraRoomIndoor: 'ውስጥ', cameraRoomOutdoor: 'ውጭ',
    micLabel: 'ማይክ', speakLabel: 'ተናገር', screenshotLabel: 'ቀረጻ', recordLabel: 'ቅረጽ',
    deviceFound: 'መሣሪያ ተገኝቷል!', linkDevice: 'መሣሪያ አስተሳስር',
    deviceNotFound: 'መሣሪያ አልተገኘም', retrySearch: 'እንደገና ሞክር',
    cyberTitle: 'የሳይበር ደህንነት', cyberScore: 'ውጤት', cyberNetProtected: 'ኔትወርክ ተጠብቋል', cyberNeedsImprovement: 'መሻሻል ያስፈልጋል',
    cyberNoThreats: 'ንቁ ስጋቶች አልተገኙም', cyberActiveThreats: 'ንቁ ስጋቶች', cyberLastScan: 'የመጨረሻ ዝማኔ: ከ2 ሰዓት በፊት',
    cyberDevicesMetric: 'መሳሪያዎች', cyberConnected: 'ተያይዘዋል', cyberThreats: 'ስጋቶች', cyberNoThreatsSub: 'ስጋት የለም',
    cyberNeedsTreatment: 'ጥንቃቄ ያስፈልጋል', cyberEncryption: 'ምስጠራ', cyberNetProtection: 'የኔትወርክ ጥበቃ',
    cyberFirewallTitle: 'ፋየርዎል', cyberFirewallSub: 'የቤት ኔትወርክን ይጠብቃል',
    cyberVpnSub: 'የኔትወርክ ትራፊክን ያመሰጥራል', cyberDnsTitle: 'ጎጂ DNS አጥር', cyberDnsSub: 'አደገኛ ጣቢያዎችን ያጣራል',
    cyberIotTitle: 'IoT መሳሪያ መነጠል', cyberIotSub: 'ለስማርት መሳሪያዎች የሚሆን ኔትወርክ',
    cyberDeviceAudit: 'የመሳሪያ ምርመራ', cyberFirmware: 'የፈርምዌር ዝማኔዎች', cyberFirmwareUpToDate: 'መሳሪያዎች ዘምነዋል',
    cyberDefaultPassTitle: 'ነባሪ የይለፍ ቃሎች', cyberDefaultPassSub: 'ነባሪ የይለፍ ቃሎች አልተገኙም',
    cyberSecurityProto: 'የደህንነት ፕሮቶኮል', cyberRemoteAccess: 'ርቀት ተደራሽነት', cyberRemoteAccessSub: 'ለፈቃደኛ ተጠቃሚዎች ብቻ',
    cyberStatusActive: 'ንቁ', cyberStatusOff: 'ጠፍቷ', cyberStatusWarning: 'ማስጠንቀቂያ',
    cyberBadgeOk: 'ጥሩ', cyberBadgeRecommended: 'ይመከራል', cyberBadgeCheck: 'ፈትሽ',
    cyberRecentEvents: 'የቅርብ ጊዜ ክስተቶች',
    cyberEvent1Time: 'ከ2 ሰዓት በፊት', cyberEvent1Text: 'የኔትወርክ ቅኝት በተሳካ ሁኔታ ተጠናቀቀ',
    cyberEvent2Time: 'ከ6 ሰዓት በፊት', cyberEvent2Text: 'አዲስ መሳሪያ ወደ ኔትወርክ ተያይዟል',
    cyberEvent3Time: 'ትናንት 22:14', cyberEvent3Text: 'ያልተፈቀደ ተደራሽነት ሙከራ ታግዷል',
    cyberEvent4Time: 'ከ3 ቀናት በፊት', cyberEvent4Text: 'የደህንነት ዝማኔ ተጭኗል',
    cyberNavLabel: 'ሳይበር',
    storeTitle: 'ሱቄ', storeNavLabel: 'ሱቅ', storeFeatured: 'ምርጥ ምርቶች',
    storeNewArrivals: 'አዲስ ዕቃዎች', storeAddToCart: 'ወደ ጋሪ ጨምር', storeComingSoon: 'በቅርቡ',
    storeSearchHint: 'ምርቶችን ፈልግ…', storeNoResultsFor: 'ምንም ውጤት የለም ለ',
    storeSearchSite: 'በ FantaTech ድህረ ገጽ ፈልግ', storeViewAll: 'ሁሉንም አሳይ',
    storeNotifyMe: 'አሳውቀኝ', storeNotifyDesc: 'ኢሜልዎን ያስገቡ፣ Hub Pro 2.0 ሲገኝ እናሳውቅዎታለን፦',
    storeYourEmail: 'ኢሜልዎ', storeHubProTagline: 'የሚቀጥለው ትውልድ የስማርት ቤት ማዕከል።',
    storeBrowserError: 'አሳሹን መክፈት አልተቻለም',
    storeNotifySuccess: '✓ በተሳካ ሁኔታ ተመዝግበዋል! እናሳውቅዎታለን።',
    prodMotionSensor: 'የ Shelly እንቅስቃሴ ዳሳሽ', prodBlindMotor: 'ስማርት የመጋረጃ ሞተር',
    prodSmartPlug: 'ስማርት ሶኬት 16A', prodLedStrip: 'የ LED ገመድ 5ሜ',
    cancel: 'ሰርዝ', save: 'አስቀምጥ', add: 'ጨምር', added: 'ታክሏ ✓', edit: 'አርትዕ', delete: 'ሰርዝ', close: 'ዝጋ',
    noNotifications: 'ምንም ማሳወቂያ የለም',
    panicLabel: 'አደጋ', emergencyActivated: '🚨 የአደጋ ሁኔታ ተቃጥቷል! ባለስልጣናት ተነጉሯቸዋል።',
    helpFaq: 'ተደጋጋሚ ጥያቄዎች', helpContact: 'ያነጋግሩን',
    helpRegisterTitle: 'ለድጋፍ ይመዝገቡ', helpNameHint: 'ሙሉ ስም', helpEmailHint: 'ኢሜይል አድራሻ',
    helpMsgHint: 'መልዕክት (ፈቃደኛ)', helpSendBtn: 'ላክ', helpSentSuccess: 'ዝርዝሮቹ ተቀምጠዋል! በቅርቡ እናናግርዎታለን።',
    visitWebsite: 'ድረ-ገጽ ይጎብኙ',
    addRoom: 'ክፍል ጨምር', editRoom: 'ክፍል ያርትዑ', deleteRoom: 'ክፍል ሰርዝ',
    roomNameHint: 'የክፍል ስም', roomAdded: 'ክፍሉ ታክሏ', roomDeleted: 'ክፍሉ ተሰርዟል', roomEdited: 'ክፍሉ ታድሷል',
    roomIconLabel: 'አዶ',
    roomNameLiving: 'መኖሪያ ክፍል', roomNameBedroom: 'መኝታ ክፍል', roomNameKitchen: 'ወጥ ቤት',
    roomNameKids: 'የልጆች ክፍል', roomNameBalcony: 'መረፈቻ',
    solarTitle: 'የፀሐይ ስርዓት', solarProduction: 'ምርት', solarConsumption: 'ፍጆታ',
    solarBattery: 'ባትሪ', solarGrid: 'ኔትወርክ', solarFeedIn: 'ወደ ኔትወርክ',
    solarToday: 'ዛሬ', solarConnect: 'ስርዓት ያገናኙ', solarSaving: 'ቁጠባ',
    solarKw: 'kWh', solarStatus: 'የስርዓት ሁኔታ',
    energyDay: 'ቀን', energyWeek: 'ሳምንት', energyMonth: 'ወር', energyPeak: 'ከፍተኛ',
    breakersTitle: 'ብልህ ማቋረጫዎች', breakerMain: 'ዋና ማቋረጫ',
    breakerOn: 'ክፈት', breakerOff: 'ዝጋ', breakerTripped: 'ወደቀ',
    breakerConnect: 'ማቋረጫ ያገናኙ', breakerAmps: 'አምፔር',
    breakerPanel: 'የኤሌክትሪክ ፓነል', breakerWifi: 'WiFi', breakerZigbee: 'Zigbee',
    calendarTitle: 'ቀን መቁጠሪያ', calendarHebrew: 'የዕብራይስጥ ቀን', calendarGregorian: 'ግሪጎሪያን',
    calendarToday: 'ዛሬ', calendarHoliday: 'በዓል', hebrewYear: 'ዓ.ም',
    hMonthTishrei: 'ቲሽሬ', hMonthCheshvan: 'ቼሽቫን', hMonthKislev: 'ኪስሌቭ',
    hMonthTevet: 'ቴቬት', hMonthShvat: 'ሽቫት', hMonthAdar: 'አዳር',
    hMonthNissan: 'ኒሳን', hMonthIyar: 'ኢያር', hMonthSivan: 'ሲቫን',
    hMonthTamuz: 'ታሙዝ', hMonthAv: 'አቭ', hMonthElul: 'ኤሉል',
    holidayRoshHashana: 'ሮሽ ሃሻና', holidayYomKippur: 'ዮም ኪፑር',
    holidaySukkot: 'ሱኮት', holidaySheminiAtzeret: 'ሸሚኒ አጸሬት',
    holidayHanukkah: 'ሃኑካ', holidayTuBishvat: 'ቱ ቢሽቫት',
    holidayPurim: 'ፑሪም', holidayPesach: 'ፓሳሃ',
    holidayYomHaatzmaut: 'ዮም ሃአጽማዑት', holidayLagBaomer: 'ላግ ባዖምር',
    holidayShavuot: 'ሻቩኦት', holidayTishaBeav: 'ቲሻ ቢ-አቭ',
    boilerTitle: 'ብልህ ቦይለር', boilerOn: 'ኦን', boilerOff: 'ኦፍ',
    boilerSchedule: 'መርሃ ግብር', boilerTempLabel: 'ሙቀት',
    boilerTimer: 'ታይመር', boilerMode: 'ሁነታ',
    boilerModeEco: 'ቆጣቢ', boilerModeFull: 'ሙሉ',
    boilerConnect: 'መሳሪያ አገናኝ', boilerWifi: 'WiFi',
    boilerZigbee: 'Zigbee', boilerAddDevice: 'ቦይለር ጨምር',
    boilerStatus: 'ሁኔታ',
    boilerNotResponding: 'ምላሽ የለም', boilerFindGateway: 'Gateway ፈልግ',
    boilerScanning: 'በማስስ...', boilerGatewayFound: 'Gateway ተገኘ',
    boilerGatewayNone: 'Gateway አልተገኘም', boilerDownloadDriver: 'ድራይቨር አውርድ',
    boilerDriverDownloading: 'በማውረድ...', boilerDriverReady: 'ድራይቨር ዝግጁ ✓',
    boilerReconnect: 'እንደገና አገናኝ', boilerSelectGateway: 'Gateway ምረጥ',
    socketsTitle: 'ብልህ ሶኬቶች', socketRegister: 'ሶኬት ተመዝግብ',
    socketRegistered: 'ሶኬት ተመዘገበ', socketPower: 'ፍጆታ',
    socketAddNew: 'ሶኬት ጨምር', socketName: 'የሶኬት ስም',
    socketRoom: 'ክፍል', socketProtocol: 'ፕሮቶኮል',
    deviceEditName: 'ስም ያርትዑ', deviceRename: 'አዲስ ስም',
    deviceRenamed: 'ስም ተዘምኗል',
    planFree: 'ነፃ', planBasic: 'መሰረታዊ',
    planAdvanced: 'የተሻሻለ', planAdvancedPlus: 'የተሻሻለ ፕላስ',
    planUnlimited: 'ያልተገደበ',
    planCurrentBadge: 'ንቁ', planUpgradeNow: 'አሁን አሻሽል',
    planSelected: 'የተመረጠ', planDevicesLabel: 'መሳሪያዎች',
    planRoomsLabel: 'ክፍሎች', planAutoLabel: 'አውቶሜሽን',
    planUnlimitedLabel: 'ያልተገደበ', planAiLabel: 'AI ረዳት',
    planIntercomLabel: 'ኢንተርኮም',
    planCamerasLabel: 'ካሜራዎች', planSupportLabel: 'ድጋፍ',
    planReadOnly: 'ለማየት ብቻ', planViewOnly: 'ቁጥጥር: ለማየት ብቻ',
    planMonthly: '/ ወር',
    planFreePrice: '₪0', planBasicPrice: '₪19',
    planAdvancedPrice: '₪39', planAdvancedPlusPrice: '₪69',
    planUnlimitedPrice: '₪150',
    homeManagerLabel: 'አስተዳዳሪ', memberLabel: 'የቤተሰብ አባል',
    noHomeUsers: 'የተመዘገቡ ተጠቃሚዎች የሉም', registerAsManager: 'እንደ አስተዳዳሪ ተመዝገብ',
    addMember: 'አባል ጨምር', memberName: 'የአባሉ ስም',
    setPinCode: 'PIN ኮድ አዘጋጅ', pinCodeLabel: 'PIN ኮድ (4 ቁጥሮች)',
    pinSaved: 'PIN ተቀምጧ', pinRemoved: 'PIN ተወግዷ',
    devicesInRoom: 'በክፍሉ ያሉ መሳሪያዎች', noDevicesInRoom: 'በዚህ ክፍል ምንም መሳሪያ የለም',
    shabbatCandles: 'ሻባት ሻማ', shabbatHavdalah: 'ሃቭዳላ',
    acConnected: 'ማቀዝቀዣዎች ተገናኝተዋል', acNoUnits: 'ምንም ማቀዝቀዣ አልተገናኘም',
    adStoreLabel: 'FantaTech ሱቅ', adTrackTitle: 'የማስታወቂያ ቅንብሮች',
    adTrackSub: 'ምን ምርቶች በባነር ላይ ይታዩ',
    adFeaturedLabel: 'ምርጥ ምርቶች', adFeaturedSub: 'Hub Pro, Camera 4K, Smart Bulb, Sensor',
    adNewLabel: 'አዲስ ምርቶች', adNewSub: 'Smart Blind, Smart Plug 16A, Gateway, LED Strip',
    adAllLabel: 'ሁሉም ምርቶች', adAllSub: 'ሙሉ ዝርዝር',
    adNoneLabel: 'ማስታወቂያ የለም', adNoneSub: 'ባነሩን ደብቅ',
  );

  // ── Spanish ───────────────────────────────────────────────────
  static const S _es = S(
    navHome: 'Inicio', navCameras: 'Cámaras', navSecurity: 'Seguridad', navProfile: 'Perfil',
    greetingPrefix: 'Hola', homeSecured: 'Tu casa está protegida', homeNotSecured: 'Casa no protegida',
    allSystemsActive: 'Todos los sistemas activos', tapToActivate: 'Toca para activar seguridad',
    alarmTitle: 'Alarma', alarmSecured: 'Protegida', alarmOff: 'Apagada', roomManagement: 'Gestión del Hogar', roomsUnit: 'habitaciones',
    camerasTitle: 'Cámaras', lightsOn: 'luces encendidas', lightingTitle: 'Iluminación',
    tempTitle: 'Temperatura', tempComfy: 'Confortable', aiSubtitle: '¿En qué puedo ayudarte?',
    quickActions: 'Acciones Rápidas', leaveHome: 'Salir de casa', turnOffAll: 'Apagar todo', goodNight: 'Buenas noches', movieMode: 'Modo Película',
    mediaTitle: 'Media', mediaSpeakers: 'Altavoces', mediaScan: 'Buscar dispositivos', mediaNoDevices: 'Sin altavoces. Toca buscar.',
    bioTitle: 'Acceso rápido', bioPrompt: '¿Activar inicio con huella para la próxima vez?', bioEnable: 'Activar', bioSkip: 'Ahora no', bioReason: 'Autentícate para iniciar sesión',
    onbNext: 'Siguiente', onbStart: 'Comenzar', onbSkip: 'Omitir', onbAllow: 'Permitir', onbLater: 'Más tarde', onb1Title: 'Bienvenido a FantaTech', onb1Body: 'Tu hogar inteligente — iluminación, seguridad, clima y energía en un solo lugar.', onb2Title: 'Control total', onb2Body: 'Gestiona cámaras, sensores, interruptores y detectores desde cualquier lugar.', onb3Title: 'Automatizaciones', onb3Body: 'Crea escenas, ahorra energía y recibe alertas en tiempo real.', onbPermTitle: 'Permisos para descubrir dispositivos', onbPermBody: 'Para encontrar dispositivos en tu red necesitamos Ubicación y Bluetooth. Tus datos permanecen solo en tu dispositivo.',
    secSection: 'Seguridad', bioLoginLabel: 'Inicio con huella', bioLoginSub: 'Inicia sesión rápido con biometría', legalSection: 'Legal y Privacidad', termsLabel: 'Términos de servicio', privacyLabel: 'Política de privacidad',
    sceneCreate: 'Crear escena', sceneNew: 'Nueva escena', sceneName: 'Nombre de escena', sceneActions: 'Acciones', actPlugs: 'Enchufes', valKeep: 'Sin cambio', valOn: 'Encender', valOff: 'Apagar',
    authEmailHint: 'Correo o teléfono', authPassHint: 'Contraseña', loginGreeting: '¡Hola!', loginSubtitle: 'Inicia sesión en tu cuenta', loginForgot: '¿Olvidaste la contraseña?', loginButton: 'Iniciar sesión', authOr: 'o', loginNoAccount: '¿No tienes cuenta?', registerNow: 'Regístrate', registerTitle: 'Crear cuenta', registerSubtitle: 'Únete al hogar inteligente FantaTech', confirmPassHint: 'Confirmar contraseña', registerButton: 'Registrarse', haveAccount: '¿Ya tienes cuenta?', loginHousehold: 'Miembro del hogar',
    errEnterName: 'Ingresa tu nombre completo', errEnterEmail: 'Ingresa correo o teléfono', errPassShort: 'La contraseña debe tener al menos 6 caracteres', errPassMismatch: 'Las contraseñas no coinciden',
    acMode: 'Modo', acFanSpeed: 'Ventilador', acSwing: 'Oscilación', acMethod: 'Control', modeCool: 'Frío', modeHeat: 'Calor', modeFan: 'Ventilador', modeDry: 'Seco', modeAuto: 'Auto', fanLow: 'Bajo', fanMed: 'Medio', fanHigh: 'Alto',
    mediaMaster: 'Volumen general', mediaParty: 'Reproducir en todos', mediaStopAll: 'Detener todo',
    tvRemote: 'Control TV', tvSource: 'Fuente', tvChannel: 'Canal', tvMute: 'Silenciar',
    energyTitle: 'Consumo de energía', automationsTitle: 'Automatizaciones', activeAutomations: 'automatizaciones activas',
    myProfile: 'Mi Perfil', myHome: 'Mi Casa', usersTitle: 'Usuarios',
    subscriptionTitle: 'Suscripción', settingsTitle: 'Configuración', helpTitle: 'Ayuda',
    signOut: 'Cerrar sesión', languageLabel: 'Idioma', themeLabel: 'Tema',
    darkMode: 'Oscuro', lightMode: 'Claro', saveChanges: 'Guardar cambios',
    editProfile: 'Editar perfil', fullName: 'Nombre completo', emailLabel: 'Correo electrónico',
    profileUpdated: 'Perfil actualizado', signOutConfirm: 'Cerrar sesión', signOutQuestion: '¿Cerrar sesión?', confirmSignOut: 'Salir',
    securityTitle: 'Seguridad', armedMode: 'Armado', disarmedMode: 'Desarmado',
    doorSensor: 'Puerta principal', windowsSensor: 'Ventanas', motionSensors: 'Sensores de movimiento', smokeDetector: 'Detector de humo',
    securedStatus: 'Protegido', openStatus: 'Abierto', activeStatus: 'Activo', normalStatus: 'Normal',
    panicButton: 'Botón de pánico', panicActivate: '¡Activar!', panicWarning: 'Esto enviará una alerta de emergencia',
    allCameras: 'Todas las cámaras', liveLabel: 'EN VIVO', offlineLabel: 'Sin conexión',
    addDeviceBtn: 'Agregar dispositivo', notificationsTitle: 'Notificaciones',
    automationsAll: 'Todas las automatizaciones', automationsRec: 'Sugerencias', addAutomation: 'Agregar automatización',
    autoName: 'Nombre', autoCondition: 'Condición (Si...)', autoAction: 'Acción (Entonces...)',
    recPeakName: 'Ahorro en horas pico', recPeakDesc: 'Apagar dispositivos no esenciales entre 17:00-20:00',
    recTravelName: 'Modo viaje', recTravelDesc: 'Seguridad total cuando estás fuera de la ciudad',
    recTempName: 'Control de temperatura', recTempDesc: 'Mantener 22° cuando alguien está en casa',
    monthlyConsumption: 'Consumo mensual', activeDevices: 'Dispositivos activos', fullReport: 'Ver informe completo', fromLastMonth: 'del mes pasado',
    allNotif: 'Todos', alertsNotif: 'Alertas', camerasNotif: 'Cámaras', markAllRead: 'Marcar todo leído',
    devicesTitle: 'Dispositivos', allDevices: 'Todos', devicesOn: 'dispositivos activos',
    lightsCategory: 'Luces', blindsCategory: 'Persianas', acCategory: 'Clima',
    plugsCategory: 'Enchufes', switchesCategory: 'Interruptores', sensorsCategory: 'Sensores',
    deviceTemp: 'Temperatura', deviceBrightness: 'Brillo', devicePosition: 'Posición',
    notifSettings: 'Configurar notificaciones', aboutApp: 'Acerca de',
    aiInputHint: 'Escribe o háblame',
    aiSug1: 'Apagar todas las luces',
    aiSug2: '¿Estado del hogar ahora?',
    aiSug3: 'Activar modo noche',
    aiSug4: '¿Hay alertas activas?',
    aiReply1: 'Apagando todas las luces... ✅\n8 luces apagadas con éxito.',
    aiReply2: 'El hogar está bien 🏠\n• Seguridad: Armado ✅\n• Luces: 3 encendidas\n• Temperatura: 24°C',
    aiReply3: 'Modo noche activado 🌙\nLuces apagadas, persianas cerradas.',
    aiReply4: 'Revisando seguridad... 🔍\nSin alertas activas. Todo normal.',
    aiReplyDefault: '¡Entendido! Trabajando en eso... 🤖\nActualización próxima.',
    addDeviceTitle: 'Agregar dispositivo', autoScan: 'Escaneo auto', deviceCatalog: 'Catálogo',
    searchHint: 'Buscar dispositivo...', searching: 'Buscando dispositivos...', devicesFound: 'Dispositivos encontrados', noResults: 'Sin resultados',
    navDevices: 'Dispositivos',
    subscriptionPro: 'Suscripción Pro', subscriptionValid: 'Activa hasta 31/12/2025', subscriptionRenew: 'Renovar suscripción',
    subscriptionFeat1: 'Cámaras ilimitadas', subscriptionFeat2: 'Almacenamiento 30 días', subscriptionFeat3: 'IA inteligente', subscriptionFeat4: 'Soporte 24/7',
    catalogLights: 'Iluminación', catalogSwitches: 'Interruptores', catalogSensors: 'Sensores', catalogCameras: 'Cámaras', catalogAC: 'Clima y AC', catalogBlinds: 'Persianas', catalogNetwork: 'Routers y pasarelas',
    scanPairingHint: 'Asegúrate de que el dispositivo esté en modo de emparejamiento',
    acRemoteName: 'Control IR para AC', acRemoteCategory: 'Mando IR',
    acWifiName: 'Aire Acondicionado WiFi', acWifiCategory: 'AC WiFi',
    devBulb: 'Bombilla inteligente', devStrip: 'Tira LED', devSwitch: 'Interruptor inteligente', devDimmer: 'Regulador inteligente', devPlug: 'Enchufe inteligente',
    devMotionSensor: 'Sensor de movimiento', devDoorSensor: 'Sensor de puerta', devWindowSensor: 'Sensor de ventana', devSmokeDetector: 'Detector de humo',
    devIndoorCam: 'Cámara interior', devOutdoorCam: 'Cámara exterior',
    devSmartAC: 'Aire acondicionado', devWaterHeater: 'Calentador de agua', devThermostat: 'Termostato',
    devSmartBlind: 'Persiana inteligente', devSmartGate: 'Portón inteligente',
    devRouterWifi: 'Router WiFi', devGwZigbee: 'Pasarela Zigbee', devGwWifi: 'Pasarela WiFi', devGwMatter: 'Pasarela Matter',
    catLight: 'Luz', catSwitch: 'Interruptor', catPlug: 'Enchufe', catSensor: 'Sensor', catCamera: 'Cámara',
    catClimate: 'Clima', catBlind: 'Persiana', catGate: 'Portón', catRouter: 'Router', catGateway: 'Pasarela',
    networkLabel: 'Red', wifiNotConnected: 'Sin conexión WiFi',
    connectWifiHint: 'Conéctate a tu WiFi doméstica e inténtalo de nuevo',
    scanComplete: 'Escaneo completo', scanError: 'Error de escaneo', rescan: 'Escanear de nuevo',
    noDevicesOnNetwork: 'No se encontraron dispositivos en la red',
    sameWifiHint: 'Asegúrate de que los dispositivos estén en la misma red WiFi',
    connectedStatus: 'Conectado', noDevicesConnected: 'Sin dispositivos conectados',
    scanToDiscover: 'Escanea tu red para descubrir y agregar dispositivos inteligentes',
    scanFindDevices: 'Escanear y encontrar', remove: 'Eliminar',
    deviceWillBeRemoved: 'El dispositivo será eliminado de la lista', ipAddressLabel: 'Dirección IP',
    displayLabel: 'Pantalla', discoverDevices: 'Descubrir Dispositivos', scanViaGateway: 'Escaneando vía',
    scanStarting: 'Iniciando escaneo…',
    scanWifiLog: 'WiFiScanner: iniciando escaneo LAN',
    scanWifiDoneFmt: 'WiFiScanner: completado ({n} hosts)',
    scanBleLog: 'BLEScanner: iniciando escaneo BLE',
    scanBleDone: 'BLEScanner: completado',
    scanMatterLog: 'MatterDiscovery: buscando en mDNS',
    scanMatterDone: 'MatterDiscovery: completado',
    scanGatewayFmt: 'Sondeo profundo de {n} dispositivos',
    scanGatewayDone: 'Sondeo profundo: completado',
    scanIdentifyingFmt: 'Identificando {n} dispositivos…',
    scanIdentifyingProgress: 'Identificando dispositivos…',
    scanFinishedFmt: 'Escaneo completo — {n} dispositivos',
    scanFoundFmt: '{n} dispositivos encontrados',
    scanNoDevicesFound: 'No se encontraron dispositivos',
    scanCancelledProgress: 'Escaneo cancelado',
    scanCancelledLog: 'Escaneo cancelado por el usuario',
    fromGallery: 'Elegir de Galería', fromCamera: 'Tomar Foto', removePhoto: 'Eliminar Foto',
    cameraRoomIndoor: 'Interior', cameraRoomOutdoor: 'Exterior',
    micLabel: 'Micrófono', speakLabel: 'Hablar', screenshotLabel: 'Captura', recordLabel: 'Grabar',
    deviceFound: '¡Dispositivo encontrado!', linkDevice: 'Vincular Dispositivo',
    deviceNotFound: 'Dispositivo no encontrado', retrySearch: 'Intentar de nuevo',
    cyberTitle: 'Seguridad Cibernética', cyberScore: 'Puntuación', cyberNetProtected: 'Red Protegida', cyberNeedsImprovement: 'Necesita Mejora',
    cyberNoThreats: 'No se encontraron amenazas activas', cyberActiveThreats: 'amenazas activas', cyberLastScan: 'Última actualización: hace 2 horas',
    cyberDevicesMetric: 'Dispositivos', cyberConnected: 'Conectados', cyberThreats: 'Amenazas', cyberNoThreatsSub: 'Sin amenazas',
    cyberNeedsTreatment: 'Requiere atención', cyberEncryption: 'Cifrado', cyberNetProtection: 'Protección de Red',
    cyberFirewallTitle: 'Cortafuegos (Firewall)', cyberFirewallSub: 'Protege la red del hogar',
    cyberVpnSub: 'Cifra el tráfico de red', cyberDnsTitle: 'Bloqueo DNS malicioso', cyberDnsSub: 'Filtra sitios peligrosos',
    cyberIotTitle: 'Aislamiento de IoT', cyberIotSub: 'Red separada para dispositivos inteligentes',
    cyberDeviceAudit: 'Auditoría de Dispositivos', cyberFirmware: 'Actualizaciones de Firmware', cyberFirmwareUpToDate: 'dispositivos actualizados',
    cyberDefaultPassTitle: 'Contraseñas predeterminadas', cyberDefaultPassSub: 'No se encontraron contraseñas predeterminadas',
    cyberSecurityProto: 'Protocolo de Seguridad', cyberRemoteAccess: 'Acceso Remoto', cyberRemoteAccessSub: 'Limitado a usuarios autorizados',
    cyberStatusActive: 'Activo', cyberStatusOff: 'Apagado', cyberStatusWarning: 'Advertencia',
    cyberBadgeOk: 'OK', cyberBadgeRecommended: 'Recomendado', cyberBadgeCheck: 'Verificar',
    cyberRecentEvents: 'Eventos Recientes',
    cyberEvent1Time: 'Hace 2 horas', cyberEvent1Text: 'Escaneo de red completado con éxito',
    cyberEvent2Time: 'Hace 6 horas', cyberEvent2Text: 'Nuevo dispositivo conectado a la red',
    cyberEvent3Time: 'Ayer 22:14', cyberEvent3Text: 'Intento de acceso no autorizado bloqueado',
    cyberEvent4Time: 'Hace 3 días', cyberEvent4Text: 'Actualización de seguridad instalada automáticamente',
    cyberNavLabel: 'Ciber',
    storeTitle: 'Mi Tienda', storeNavLabel: 'Tienda', storeFeatured: 'Productos Destacados',
    storeNewArrivals: 'Novedades', storeAddToCart: 'Añadir al Carrito', storeComingSoon: 'Próximamente',
    storeSearchHint: 'Buscar productos…', storeNoResultsFor: 'Sin resultados para',
    storeSearchSite: 'Buscar en FantaTech', storeViewAll: 'Ver todo',
    storeNotifyMe: 'Avísame', storeNotifyDesc: 'Ingresa tu correo y te avisaremos cuando Hub Pro 2.0 esté disponible:',
    storeYourEmail: 'Tu correo', storeHubProTagline: 'El centro de hogar inteligente de nueva generación.',
    storeBrowserError: 'No se pudo abrir el navegador',
    storeNotifySuccess: '✓ ¡Suscrito con éxito! Te mantendremos informado.',
    prodMotionSensor: 'Sensor de movimiento Shelly', prodBlindMotor: 'Motor de persiana inteligente',
    prodSmartPlug: 'Enchufe inteligente 16A', prodLedStrip: 'Tira LED 5m',
    cancel: 'Cancelar', save: 'Guardar', add: 'Agregar', added: 'Agregado ✓', edit: 'Editar', delete: 'Eliminar', close: 'Cerrar',
    noNotifications: 'Sin notificaciones',
    panicLabel: 'PÁNICO', emergencyActivated: '🚨 ¡Modo de emergencia activado! Las autoridades han sido notificadas.',
    helpFaq: 'Preguntas frecuentes', helpContact: 'Contáctanos',
    helpRegisterTitle: 'Registrarse para soporte', helpNameHint: 'Nombre completo', helpEmailHint: 'Correo electrónico',
    helpMsgHint: 'Mensaje (opcional)', helpSendBtn: 'Enviar', helpSentSuccess: '¡Datos guardados! Nos pondremos en contacto pronto.',
    visitWebsite: 'Visitar sitio web',
    addRoom: 'Agregar habitación', editRoom: 'Editar habitación', deleteRoom: 'Eliminar habitación',
    roomNameHint: 'Nombre de la habitación', roomAdded: 'Habitación agregada', roomDeleted: 'Habitación eliminada', roomEdited: 'Habitación actualizada',
    roomIconLabel: 'Ícono',
    roomNameLiving: 'Sala', roomNameBedroom: 'Dormitorio', roomNameKitchen: 'Cocina',
    roomNameKids: 'Cuarto de niños', roomNameBalcony: 'Balcón',
    solarTitle: 'Sistema Solar', solarProduction: 'Producción', solarConsumption: 'Consumo',
    solarBattery: 'Batería', solarGrid: 'Red', solarFeedIn: 'Exportar a red',
    solarToday: 'Hoy', solarConnect: 'Conectar sistema', solarSaving: 'Ahorro',
    solarKw: 'kWh', solarStatus: 'Estado del sistema',
    energyDay: 'Día', energyWeek: 'Semana', energyMonth: 'Mes', energyPeak: 'Pico',
    breakersTitle: 'Disyuntores inteligentes', breakerMain: 'Disyuntor principal',
    breakerOn: 'Encendido', breakerOff: 'Apagado', breakerTripped: 'Disparado',
    breakerConnect: 'Conectar disyuntor', breakerAmps: 'Amperios',
    breakerPanel: 'Panel eléctrico', breakerWifi: 'WiFi', breakerZigbee: 'Zigbee',
    calendarTitle: 'Calendario', calendarHebrew: 'Calendario hebreo', calendarGregorian: 'Gregoriano',
    calendarToday: 'Hoy', calendarHoliday: 'Festivo', hebrewYear: 'Año',
    hMonthTishrei: 'Tishrei', hMonthCheshvan: 'Cheshvan', hMonthKislev: 'Kislev',
    hMonthTevet: 'Tevet', hMonthShvat: 'Shvat', hMonthAdar: 'Adar',
    hMonthNissan: 'Nissan', hMonthIyar: 'Iyar', hMonthSivan: 'Sivan',
    hMonthTamuz: 'Tamuz', hMonthAv: 'Av', hMonthElul: 'Elul',
    holidayRoshHashana: 'Rosh Hashaná', holidayYomKippur: 'Yom Kipur',
    holidaySukkot: 'Sucot', holidaySheminiAtzeret: 'Shemini Atzeret',
    holidayHanukkah: 'Janucá', holidayTuBishvat: 'Tu Bishvat',
    holidayPurim: 'Purim', holidayPesach: 'Pésaj',
    holidayYomHaatzmaut: 'Yom Haatzmaut', holidayLagBaomer: "Lag Baómer",
    holidayShavuot: 'Shavuot', holidayTishaBeav: 'Tishá Beav',
    boilerTitle: 'Calentador inteligente', boilerOn: 'Encendido', boilerOff: 'Apagado',
    boilerSchedule: 'Programar', boilerTempLabel: 'Temperatura',
    boilerTimer: 'Temporizador', boilerMode: 'Modo',
    boilerModeEco: 'Eco', boilerModeFull: 'Completo',
    boilerConnect: 'Conectar dispositivo', boilerWifi: 'WiFi',
    boilerZigbee: 'Zigbee', boilerAddDevice: 'Agregar calentador',
    boilerStatus: 'Estado',
    boilerNotResponding: 'Sin respuesta', boilerFindGateway: 'Buscar Gateway',
    boilerScanning: 'Escaneando red...', boilerGatewayFound: 'Gateway encontrado',
    boilerGatewayNone: 'Sin Gateway', boilerDownloadDriver: 'Descargar driver',
    boilerDriverDownloading: 'Descargando...', boilerDriverReady: 'Driver listo ✓',
    boilerReconnect: 'Reconectar', boilerSelectGateway: 'Seleccionar Gateway',
    socketsTitle: 'Enchufes inteligentes', socketRegister: 'Registrar enchufe',
    socketRegistered: 'Enchufe registrado', socketPower: 'Consumo',
    socketAddNew: 'Agregar enchufe', socketName: 'Nombre del enchufe',
    socketRoom: 'Habitación', socketProtocol: 'Protocolo',
    deviceEditName: 'Editar nombre', deviceRename: 'Nuevo nombre',
    deviceRenamed: 'Nombre actualizado',
    planFree: 'Gratis', planBasic: 'Básico',
    planAdvanced: 'Avanzado', planAdvancedPlus: 'Avanzado Plus',
    planUnlimited: 'Ilimitado',
    planCurrentBadge: 'Activo', planUpgradeNow: 'Actualizar ahora',
    planSelected: 'Seleccionado', planDevicesLabel: 'Dispositivos',
    planRoomsLabel: 'Habitaciones', planAutoLabel: 'Automatizaciones',
    planUnlimitedLabel: 'Ilimitado', planAiLabel: 'Asistente AI',
    planIntercomLabel: 'Intercomunicador',
    planCamerasLabel: 'Cámaras', planSupportLabel: 'Soporte',
    planReadOnly: 'Solo lectura', planViewOnly: 'Control: solo lectura',
    planMonthly: '/ mes',
    planFreePrice: '₪0', planBasicPrice: '₪19',
    planAdvancedPrice: '₪39', planAdvancedPlusPrice: '₪69',
    planUnlimitedPrice: '₪150',
    homeManagerLabel: 'Administrador', memberLabel: 'Miembro del hogar',
    noHomeUsers: 'Sin usuarios registrados', registerAsManager: 'Registrarse como administrador',
    addMember: 'Agregar miembro', memberName: 'Nombre del miembro',
    setPinCode: 'Establecer PIN', pinCodeLabel: 'Código PIN (4 dígitos)',
    pinSaved: 'PIN guardado', pinRemoved: 'PIN eliminado',
    devicesInRoom: 'Dispositivos en habitación', noDevicesInRoom: 'Sin dispositivos en esta habitación',
    shabbatCandles: 'Encendido de velas', shabbatHavdalah: 'Havdalá',
    acConnected: 'unidades de A/C conectadas', acNoUnits: 'Sin A/C conectado',
    adStoreLabel: 'Tienda FantaTech', adTrackTitle: 'Config. de Anuncios',
    adTrackSub: 'Elige los productos que aparecen en el banner',
    adFeaturedLabel: 'Productos Destacados', adFeaturedSub: 'Hub Pro, Camera 4K, Smart Bulb, Sensor',
    adNewLabel: 'Novedad en Tienda', adNewSub: 'Smart Blind, Smart Plug 16A, Gateway, LED Strip',
    adAllLabel: 'Todos los Productos', adAllSub: 'Rotación completa del catálogo',
    adNoneLabel: 'Sin Anuncios', adNoneSub: 'Ocultar el banner completamente',
  );

  // ── Russian ───────────────────────────────────────────────────
  static const S _ru = S(
    navHome: 'Главная', navCameras: 'Камеры', navSecurity: 'Охрана', navProfile: 'Профиль',
    greetingPrefix: 'Привет', homeSecured: 'Дом под защитой', homeNotSecured: 'Дом не защищён',
    allSystemsActive: 'Все системы активны', tapToActivate: 'Нажмите для активации',
    alarmTitle: 'Охрана', alarmSecured: 'Защищён', alarmOff: 'Выключена', roomManagement: 'Управление домом', roomsUnit: 'комнат',
    camerasTitle: 'Камеры', lightsOn: 'света включены', lightingTitle: 'Освещение',
    tempTitle: 'Температура', tempComfy: 'Комфортно', aiSubtitle: 'Как я могу вам помочь?',
    quickActions: 'Быстрые действия', leaveHome: 'Уйти из дома', turnOffAll: 'Выключить всё', goodNight: 'Спокойной ночи', movieMode: 'Режим фильма',
    mediaTitle: 'Медиа', mediaSpeakers: 'Колонки', mediaScan: 'Поиск устройств', mediaNoDevices: 'Колонки не найдены. Нажмите поиск.',
    bioTitle: 'Быстрый вход', bioPrompt: 'Включить вход по отпечатку в следующий раз?', bioEnable: 'Включить', bioSkip: 'Не сейчас', bioReason: 'Подтвердите личность для входа',
    onbNext: 'Далее', onbStart: 'Начать', onbSkip: 'Пропустить', onbAllow: 'Разрешить', onbLater: 'Позже', onb1Title: 'Добро пожаловать в FantaTech', onb1Body: 'Ваш умный дом — свет, безопасность, климат и энергия в одном месте.', onb2Title: 'Полный контроль', onb2Body: 'Управляйте камерами, датчиками, выключателями откуда угодно.', onb3Title: 'Умные сценарии', onb3Body: 'Создавайте сцены, экономьте энергию и получайте уведомления.', onbPermTitle: 'Разрешения для поиска устройств', onbPermBody: 'Чтобы найти устройства в сети, нужны Геолокация и Bluetooth. Данные остаются только на вашем устройстве.',
    secSection: 'Безопасность', bioLoginLabel: 'Вход по отпечатку', bioLoginSub: 'Быстрый вход по биометрии', legalSection: 'Правовая информация', termsLabel: 'Условия использования', privacyLabel: 'Политика конфиденциальности',
    sceneCreate: 'Создать сцену', sceneNew: 'Новая сцена', sceneName: 'Название сцены', sceneActions: 'Действия', actPlugs: 'Розетки', valKeep: 'Без изменений', valOn: 'Вкл', valOff: 'Выкл',
    authEmailHint: 'Email или телефон', authPassHint: 'Пароль', loginGreeting: 'Здравствуйте!', loginSubtitle: 'Войдите в свой аккаунт', loginForgot: 'Забыли пароль?', loginButton: 'Войти', authOr: 'или', loginNoAccount: 'Нет аккаунта?', registerNow: 'Зарегистрироваться', registerTitle: 'Создать аккаунт', registerSubtitle: 'Присоединяйтесь к умному дому FantaTech', confirmPassHint: 'Подтвердите пароль', registerButton: 'Регистрация', haveAccount: 'Уже есть аккаунт?', loginHousehold: 'Член семьи',
    errEnterName: 'Введите полное имя', errEnterEmail: 'Введите email или телефон', errPassShort: 'Пароль должен быть не менее 6 символов', errPassMismatch: 'Пароли не совпадают',
    acMode: 'Режим', acFanSpeed: 'Вентилятор', acSwing: 'Качание', acMethod: 'Управление', modeCool: 'Охлаждение', modeHeat: 'Обогрев', modeFan: 'Вентилятор', modeDry: 'Осушение', modeAuto: 'Авто', fanLow: 'Низкий', fanMed: 'Средний', fanHigh: 'Высокий',
    mediaMaster: 'Общая громкость', mediaParty: 'Играть на всех', mediaStopAll: 'Остановить все',
    tvRemote: 'Пульт ТВ', tvSource: 'Источник', tvChannel: 'Канал', tvMute: 'Без звука',
    energyTitle: 'Потребление энергии', automationsTitle: 'Автоматизация', activeAutomations: 'активных сценариев',
    myProfile: 'Мой профиль', myHome: 'Мой дом', usersTitle: 'Пользователи',
    subscriptionTitle: 'Подписка', settingsTitle: 'Настройки', helpTitle: 'Помощь',
    signOut: 'Выйти', languageLabel: 'Язык', themeLabel: 'Тема',
    darkMode: 'Тёмная', lightMode: 'Светлая', saveChanges: 'Сохранить',
    editProfile: 'Редактировать', fullName: 'Полное имя', emailLabel: 'Эл. почта',
    profileUpdated: 'Профиль обновлён', signOutConfirm: 'Выйти', signOutQuestion: 'Вы уверены, что хотите выйти?', confirmSignOut: 'Выйти',
    securityTitle: 'Безопасность', armedMode: 'Вооружён', disarmedMode: 'Разоружён',
    doorSensor: 'Входная дверь', windowsSensor: 'Окна', motionSensors: 'Датчики движения', smokeDetector: 'Датчик дыма',
    securedStatus: 'Защищён', openStatus: 'Открыт', activeStatus: 'Активен', normalStatus: 'Норма',
    panicButton: 'Тревога', panicActivate: 'Активировать!', panicWarning: 'Будет отправлен сигнал SOS',
    allCameras: 'Все камеры', liveLabel: 'ПРЯМОЙ ЭФИР', offlineLabel: 'Не в сети',
    addDeviceBtn: 'Добавить устройство', notificationsTitle: 'Уведомления',
    automationsAll: 'Все сценарии', automationsRec: 'Рекомендации', addAutomation: 'Добавить сценарий',
    autoName: 'Название', autoCondition: 'Условие (Если...)', autoAction: 'Действие (Тогда...)',
    recPeakName: 'Экономия в часы пик', recPeakDesc: 'Отключение второстепенных устройств с 17:00 до 20:00',
    recTravelName: 'Режим поездки', recTravelDesc: 'Полная охрана, когда вы за городом',
    recTempName: 'Контроль температуры', recTempDesc: 'Поддерживать 22°, когда кто-то дома',
    monthlyConsumption: 'Месячное потребление', activeDevices: 'Активные устройства', fullReport: 'Полный отчёт', fromLastMonth: 'с прошлого месяца',
    allNotif: 'Все', alertsNotif: 'Оповещения', camerasNotif: 'Камеры', markAllRead: 'Отметить все прочитанными',
    devicesTitle: 'Устройства', allDevices: 'Все', devicesOn: 'устройств включено',
    lightsCategory: 'Освещение', blindsCategory: 'Жалюзи', acCategory: 'Климат',
    plugsCategory: 'Розетки', switchesCategory: 'Выключатели', sensorsCategory: 'Датчики',
    deviceTemp: 'Температура', deviceBrightness: 'Яркость', devicePosition: 'Позиция',
    notifSettings: 'Настройки уведомлений', aboutApp: 'О приложении',
    aiInputHint: 'Введите или говорите со мной',
    aiSug1: 'Выключить весь свет',
    aiSug2: 'Статус дома сейчас?',
    aiSug3: 'Активировать ночной режим',
    aiSug4: 'Есть активные оповещения?',
    aiReply1: 'Выключаю весь свет... ✅\n8 источников света выключены.',
    aiReply2: 'Дом в порядке 🏠\n• Охрана: Активна ✅\n• Свет: 3 включены\n• Температура: 24°C',
    aiReply3: 'Ночной режим активирован 🌙\nСвет выключен, шторы закрыты.',
    aiReply4: 'Проверка системы охраны... 🔍\nАктивных оповещений нет. Все датчики в норме.',
    aiReplyDefault: 'Понял! Работаю над этим... 🤖\nОбновление придёт скоро.',
    addDeviceTitle: 'Добавить устройство', autoScan: 'Авто поиск', deviceCatalog: 'Каталог устройств',
    searchHint: 'Поиск устройства...', searching: 'Поиск устройств...', devicesFound: 'Найденные устройства', noResults: 'Ничего не найдено',
    navDevices: 'Устройства',
    subscriptionPro: 'Pro Подписка', subscriptionValid: 'Активна до 31/12/2025', subscriptionRenew: 'Продлить подписку',
    subscriptionFeat1: 'Неограниченные камеры', subscriptionFeat2: 'Облако 30 дней', subscriptionFeat3: 'Умный ИИ', subscriptionFeat4: 'Поддержка 24/7',
    catalogLights: 'Освещение', catalogSwitches: 'Выключатели', catalogSensors: 'Датчики', catalogCameras: 'Камеры', catalogAC: 'Климат', catalogBlinds: 'Жалюзи и ворота', catalogNetwork: 'Роутеры и шлюзы',
    scanPairingHint: 'Убедитесь, что устройство в режиме сопряжения и включено',
    acRemoteName: 'ИК-пульт для кондиционера', acRemoteCategory: 'ИК-пульт',
    acWifiName: 'Кондиционер WiFi', acWifiCategory: 'WiFi AC',
    devBulb: 'Умная лампа', devStrip: 'LED-лента', devSwitch: 'Умный выключатель', devDimmer: 'Умный диммер', devPlug: 'Умная розетка',
    devMotionSensor: 'Датчик движения', devDoorSensor: 'Датчик двери', devWindowSensor: 'Датчик окна', devSmokeDetector: 'Датчик дыма',
    devIndoorCam: 'Внутренняя камера', devOutdoorCam: 'Внешняя камера',
    devSmartAC: 'Умный кондиционер', devWaterHeater: 'Водонагреватель', devThermostat: 'Термостат',
    devSmartBlind: 'Умные жалюзи', devSmartGate: 'Умные ворота',
    devRouterWifi: 'Роутер WiFi', devGwZigbee: 'Шлюз Zigbee', devGwWifi: 'Шлюз WiFi', devGwMatter: 'Шлюз Matter',
    catLight: 'Свет', catSwitch: 'Выключатель', catPlug: 'Розетка', catSensor: 'Датчик', catCamera: 'Камера',
    catClimate: 'Климат', catBlind: 'Жалюзи', catGate: 'Ворота', catRouter: 'Роутер', catGateway: 'Шлюз',
    networkLabel: 'Сеть', wifiNotConnected: 'Нет подключения к WiFi',
    connectWifiHint: 'Подключитесь к домашней WiFi и попробуйте снова',
    scanComplete: 'Сканирование завершено', scanError: 'Ошибка сканирования', rescan: 'Сканировать снова',
    noDevicesOnNetwork: 'Устройства в сети не найдены',
    sameWifiHint: 'Убедитесь, что устройства подключены к той же WiFi',
    connectedStatus: 'Подключено', noDevicesConnected: 'Нет подключённых устройств',
    scanToDiscover: 'Сканируйте сеть для обнаружения и добавления умных устройств',
    scanFindDevices: 'Сканировать и найти', remove: 'Удалить',
    deviceWillBeRemoved: 'Устройство будет удалено из списка', ipAddressLabel: 'IP-адрес',
    displayLabel: 'Экран', discoverDevices: 'Найти Устройства', scanViaGateway: 'Сканирование через',
    scanStarting: 'Начало сканирования…',
    scanWifiLog: 'WiFiScanner: начало сканирования LAN',
    scanWifiDoneFmt: 'WiFiScanner: завершено ({n} узлов)',
    scanBleLog: 'BLEScanner: начало сканирования BLE',
    scanBleDone: 'BLEScanner: завершено',
    scanMatterLog: 'MatterDiscovery: поиск в mDNS',
    scanMatterDone: 'MatterDiscovery: завершено',
    scanGatewayFmt: 'Глубокое зондирование {n} устройств',
    scanGatewayDone: 'Глубокое зондирование: завершено',
    scanIdentifyingFmt: 'Идентификация {n} устройств…',
    scanIdentifyingProgress: 'Идентификация устройств…',
    scanFinishedFmt: 'Сканирование завершено — {n} устройств',
    scanFoundFmt: 'Найдено {n} устройств',
    scanNoDevicesFound: 'Устройства не найдены',
    scanCancelledProgress: 'Сканирование отменено',
    scanCancelledLog: 'Сканирование отменено пользователем',
    fromGallery: 'Выбрать из Галереи', fromCamera: 'Сделать Фото', removePhoto: 'Удалить Фото',
    cameraRoomIndoor: 'Внутри', cameraRoomOutdoor: 'Снаружи',
    micLabel: 'Микрофон', speakLabel: 'Говорить', screenshotLabel: 'Снимок', recordLabel: 'Запись',
    deviceFound: 'Устройство найдено!', linkDevice: 'Подключить',
    deviceNotFound: 'Устройство не найдено', retrySearch: 'Попробовать снова',
    cyberTitle: 'Кибербезопасность', cyberScore: 'Оценка', cyberNetProtected: 'Сеть защищена', cyberNeedsImprovement: 'Требует улучшения',
    cyberNoThreats: 'Активных угроз не обнаружено', cyberActiveThreats: 'активных угроз', cyberLastScan: 'Последнее обновление: 2 часа назад',
    cyberDevicesMetric: 'Устройства', cyberConnected: 'Подключено', cyberThreats: 'Угрозы', cyberNoThreatsSub: 'Нет угроз',
    cyberNeedsTreatment: 'Требует внимания', cyberEncryption: 'Шифрование', cyberNetProtection: 'Защита сети',
    cyberFirewallTitle: 'Брандмауэр (Firewall)', cyberFirewallSub: 'Защищает домашнюю сеть',
    cyberVpnSub: 'Шифрует сетевой трафик', cyberDnsTitle: 'Блокировка вредоносного DNS', cyberDnsSub: 'Фильтрует опасные сайты',
    cyberIotTitle: 'Изоляция IoT устройств', cyberIotSub: 'Отдельная сеть для умных устройств',
    cyberDeviceAudit: 'Аудит устройств', cyberFirmware: 'Обновления прошивки', cyberFirmwareUpToDate: 'устройств обновлено',
    cyberDefaultPassTitle: 'Стандартные пароли', cyberDefaultPassSub: 'Стандартных паролей не обнаружено',
    cyberSecurityProto: 'Протокол безопасности', cyberRemoteAccess: 'Удалённый доступ', cyberRemoteAccessSub: 'Ограничен авторизованными пользователями',
    cyberStatusActive: 'Активен', cyberStatusOff: 'Выключен', cyberStatusWarning: 'Предупреждение',
    cyberBadgeOk: 'ОК', cyberBadgeRecommended: 'Рекомендуется', cyberBadgeCheck: 'Проверить',
    cyberRecentEvents: 'Последние события',
    cyberEvent1Time: '2 часа назад', cyberEvent1Text: 'Сканирование сети завершено успешно',
    cyberEvent2Time: '6 часов назад', cyberEvent2Text: 'Новое устройство подключилось к сети',
    cyberEvent3Time: 'Вчера 22:14', cyberEvent3Text: 'Попытка несанкционированного доступа заблокирована',
    cyberEvent4Time: '3 дня назад', cyberEvent4Text: 'Обновление безопасности установлено автоматически',
    cyberNavLabel: 'Кибер',
    storeTitle: 'Мой магазин', storeNavLabel: 'Магазин', storeFeatured: 'Рекомендуемые товары',
    storeNewArrivals: 'Новинки', storeAddToCart: 'В корзину', storeComingSoon: 'Скоро',
    storeSearchHint: 'Поиск товаров…', storeNoResultsFor: 'Нет результатов для',
    storeSearchSite: 'Искать на сайте FantaTech', storeViewAll: 'Показать все',
    storeNotifyMe: 'Сообщить мне', storeNotifyDesc: 'Введите эл. почту, и мы сообщим, когда Hub Pro 2.0 появится:',
    storeYourEmail: 'Ваша эл. почта', storeHubProTagline: 'Центр умного дома нового поколения.',
    storeBrowserError: 'Не удалось открыть браузер',
    storeNotifySuccess: '✓ Вы успешно подписаны! Мы сообщим вам.',
    prodMotionSensor: 'Датчик движения Shelly', prodBlindMotor: 'Умный мотор для штор',
    prodSmartPlug: 'Умная розетка 16A', prodLedStrip: 'LED-лента 5м',
    cancel: 'Отмена', save: 'Сохранить', add: 'Добавить', added: 'Добавлено ✓', edit: 'Изменить', delete: 'Удалить', close: 'Закрыть',
    noNotifications: 'Нет уведомлений',
    panicLabel: 'ПАНИКА', emergencyActivated: '🚨 Экстренный режим активирован! Власти уведомлены.',
    helpFaq: 'Часто задаваемые вопросы', helpContact: 'Связаться с нами',
    helpRegisterTitle: 'Регистрация поддержки', helpNameHint: 'Полное имя', helpEmailHint: 'Электронная почта',
    helpMsgHint: 'Сообщение (необязательно)', helpSendBtn: 'Отправить', helpSentSuccess: 'Данные сохранены! Мы свяжемся с вами.',
    visitWebsite: 'Посетить сайт',
    addRoom: 'Добавить комнату', editRoom: 'Изменить комнату', deleteRoom: 'Удалить комнату',
    roomNameHint: 'Название комнаты', roomAdded: 'Комната добавлена', roomDeleted: 'Комната удалена', roomEdited: 'Комната обновлена',
    roomIconLabel: 'Иконка',
    roomNameLiving: 'Гостиная', roomNameBedroom: 'Спальня', roomNameKitchen: 'Кухня',
    roomNameKids: 'Детская', roomNameBalcony: 'Балкон',
    solarTitle: 'Солнечная система', solarProduction: 'Выработка', solarConsumption: 'Потребление',
    solarBattery: 'Аккумулятор', solarGrid: 'Сеть', solarFeedIn: 'Отдача в сеть',
    solarToday: 'Сегодня', solarConnect: 'Подключить систему', solarSaving: 'Экономия',
    solarKw: 'кВт·ч', solarStatus: 'Статус системы',
    energyDay: 'День', energyWeek: 'Неделя', energyMonth: 'Месяц', energyPeak: 'Пик',
    breakersTitle: 'Умные автоматы', breakerMain: 'Главный автомат',
    breakerOn: 'Вкл', breakerOff: 'Выкл', breakerTripped: 'Сработал',
    breakerConnect: 'Подключить автомат', breakerAmps: 'Ампер',
    breakerPanel: 'Электрощит', breakerWifi: 'WiFi', breakerZigbee: 'Zigbee',
    calendarTitle: 'Календарь', calendarHebrew: 'Еврейский календарь', calendarGregorian: 'Григорианский',
    calendarToday: 'Сегодня', calendarHoliday: 'Праздник', hebrewYear: 'Год',
    hMonthTishrei: 'Тишрей', hMonthCheshvan: 'Хешван', hMonthKislev: 'Кислев',
    hMonthTevet: 'Тевет', hMonthShvat: 'Шват', hMonthAdar: 'Адар',
    hMonthNissan: 'Нисан', hMonthIyar: 'Ияр', hMonthSivan: 'Сиван',
    hMonthTamuz: 'Тамуз', hMonthAv: 'Ав', hMonthElul: 'Элул',
    holidayRoshHashana: 'Рош-а-Шана', holidayYomKippur: 'Йом-Кипур',
    holidaySukkot: 'Суккот', holidaySheminiAtzeret: 'Шмини Ацерет',
    holidayHanukkah: 'Ханука', holidayTuBishvat: 'Ту би-Шват',
    holidayPurim: 'Пурим', holidayPesach: 'Пасха',
    holidayYomHaatzmaut: 'День независимости', holidayLagBaomer: 'Лаг ба-Омер',
    holidayShavuot: 'Шавуот', holidayTishaBeav: 'Тиша бе-Ав',
    boilerTitle: 'Умный бойлер', boilerOn: 'Вкл', boilerOff: 'Выкл',
    boilerSchedule: 'Расписание', boilerTempLabel: 'Температура',
    boilerTimer: 'Таймер', boilerMode: 'Режим',
    boilerModeEco: 'Эко', boilerModeFull: 'Полный',
    boilerConnect: 'Подключить', boilerWifi: 'WiFi',
    boilerZigbee: 'Zigbee', boilerAddDevice: 'Добавить бойлер',
    boilerStatus: 'Статус',
    boilerNotResponding: 'Не отвечает', boilerFindGateway: 'Найти Gateway',
    boilerScanning: 'Сканирование...', boilerGatewayFound: 'Gateway найден',
    boilerGatewayNone: 'Gateway не найден', boilerDownloadDriver: 'Скачать драйвер',
    boilerDriverDownloading: 'Скачивание...', boilerDriverReady: 'Драйвер готов ✓',
    boilerReconnect: 'Переподключить', boilerSelectGateway: 'Выбрать Gateway',
    socketsTitle: 'Умные розетки', socketRegister: 'Зарегистрировать',
    socketRegistered: 'Розетка добавлена', socketPower: 'Мощность',
    socketAddNew: 'Добавить розетку', socketName: 'Название розетки',
    socketRoom: 'Комната', socketProtocol: 'Протокол',
    deviceEditName: 'Изменить имя', deviceRename: 'Новое имя',
    deviceRenamed: 'Имя обновлено',
    planFree: 'Бесплатно', planBasic: 'Базовый',
    planAdvanced: 'Продвинутый', planAdvancedPlus: 'Продвинутый Плюс',
    planUnlimited: 'Безлимитный',
    planCurrentBadge: 'Активен', planUpgradeNow: 'Обновить',
    planSelected: 'Выбран', planDevicesLabel: 'Устройства',
    planRoomsLabel: 'Комнаты', planAutoLabel: 'Автоматизации',
    planUnlimitedLabel: 'Без ограничений', planAiLabel: 'AI ассистент',
    planIntercomLabel: 'Домофон',
    planCamerasLabel: 'Камеры', planSupportLabel: 'Поддержка',
    planReadOnly: 'Только просмотр', planViewOnly: 'Управление: только просмотр',
    planMonthly: '/ мес',
    planFreePrice: '₪0', planBasicPrice: '₪19',
    planAdvancedPrice: '₪39', planAdvancedPlusPrice: '₪69',
    planUnlimitedPrice: '₪150',
    homeManagerLabel: 'Администратор', memberLabel: 'Член семьи',
    noHomeUsers: 'Нет зарегистрированных пользователей', registerAsManager: 'Зарегистрироваться как администратор',
    addMember: 'Добавить члена', memberName: 'Имя члена',
    setPinCode: 'Установить PIN', pinCodeLabel: 'PIN-код (4 цифры)',
    pinSaved: 'PIN сохранён', pinRemoved: 'PIN удалён',
    devicesInRoom: 'Устройства в комнате', noDevicesInRoom: 'В этой комнате нет устройств',
    shabbatCandles: 'Зажигание свечей', shabbatHavdalah: 'Гавдала',
    acConnected: 'кондиционеров подключено', acNoUnits: 'Нет кондиционеров',
    adStoreLabel: 'Магазин FantaTech', adTrackTitle: 'Настройки рекламы',
    adTrackSub: 'Выберите товары для отображения в баннере',
    adFeaturedLabel: 'Рекомендуемые', adFeaturedSub: 'Hub Pro, Camera 4K, Smart Bulb, Sensor',
    adNewLabel: 'Новинки магазина', adNewSub: 'Smart Blind, Smart Plug 16A, Gateway, LED Strip',
    adAllLabel: 'Все товары', adAllSub: 'Полная ротация каталога',
    adNoneLabel: 'Без рекламы', adNoneSub: 'Полностью скрыть баннер',
  );
}
