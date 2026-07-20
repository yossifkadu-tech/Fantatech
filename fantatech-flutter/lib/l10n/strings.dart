import '../models/app_state.dart';

class S {
  // Navigation
  final String navHome;
  final String navCameras;
  final String navSecurity;
  final String navProfile;
  final String navAutomations;

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
  final String aiTopSubtitle;
  final String aiClearChat;
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
  final String bioUnavailable;
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
  final String resetEmailHint;
  final String resetEmailSent;
  final String okButton;
  final String cancelButton;
  final String sendButton;
  final String loginButton;
  final String authOr;
  final String loginNoAccount;
  final String registerNow;
  final String continueAsGuest;
  final String loginWith;
  final String appTagline;
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
  final String acPreset;
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
  final String faq1Q; final String faq1A;
  final String faq2Q; final String faq2A;
  final String faq3Q; final String faq3A;
  final String faq4Q; final String faq4A;
  final String energyTitle;
  final String automationsTitle;
  final String activeAutomations;
  final String climateEnergyTitle;
  final String homeManagementTitle;

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
  final String appearanceTitle;
  final String themeFont;
  final String themeAccent;
  final String themeBg;
  final String themeRadius;
  final String themeBgDarkBlue;
  final String themeBgAmoled;
  final String themeBgDarkGray;
  final String themeBgLightGray;
  final String themeBgLightWhite;
  final String themeRadiusSharp;
  final String themeRadiusNormal;
  final String themeRadiusRound;
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
  final String waterLeakSensor;
  final String securedStatus;
  final String openStatus;
  final String activeStatus;
  final String normalStatus;
  final String panicButton;
  final String panicActivate;
  final String panicWarning;

  // Welcome Guest mode
  final String welcomeGuestBtn;
  final String welcomeGuestActive;
  final String welcomeGuestTimer;
  final String welcomeGuestCancel;
  final String welcomeGuestHint;
  final String welcomeGuestChoose;
  final String guestOptShort;
  final String guestOptMedium;
  final String guestOptLong;
  final String guestMinutes;

  // Sensor brand picker
  final String chooseBrand;
  final String pairingSteps;

  // Cameras
  final String allCameras;
  final String liveLabel;
  final String offlineLabel;
  final String deviceOn;
  final String deviceOff;
  final String addDeviceBtn;
  final String deleteAll;
  final String deleteAllConfirm;
  final String notificationsTitle;
  final String timeNow;
  final String timeMinAgo;       // uses {n}
  final String timeHrAgo;        // uses {n}
  final String timeDayAgo;       // uses {n}
  final String deviceConnectedFmt; // uses {name}

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
  final String aiMicUnavailable;
  final String aiSug1;
  final String aiSug2;
  final String aiSug3;
  final String aiSug4;
  final String aiSugDesc1;
  final String aiSugDesc2;
  final String aiSugDesc3;
  final String aiSugDesc4;
  final String aiPrivacyNote;
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
  final String haRemoveDeviceFailed;
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
  final String scanBarcode;
  final String searchScanProducts;
  final String editUserName;

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
  final String roomNameKitchen;
  final String roomNameBedroom;
  final String roomNameKids;
  final String roomNameGarden;
  final String roomNameBathroom;
  final String roomNameStorage;
  final String roomNameAc;

  // Common camera location names (seed/discovered cameras come in English).
  final String camFrontDoor;
  final String camBackDoor;
  final String camGarage;
  final String camBackyard;
  final String camEntrance;
  final String camDriveway;
  final String camBalcony;

  // Seed-automation names / conditions / actions (mock data ships mixed-language).
  final String autoMotionNight;
  final String autoArrive;
  final String autoMorning;
  final String autoEnergySave;
  final String condMotionNight;
  final String condNobodyHome;
  final String condArrive;
  final String condTime2300;
  final String condMorningWeekday;
  final String condNoMotion30;
  final String actAllLightsOn;
  final String actAlarmOffAll;
  final String actLightsAlarmOff;
  final String actOffLock;
  final String actBlindsCoffee;
  final String actOffLightsAc;
  // Device categories + imperative on/off buttons.
  final String catSmoke;
  final String catEnergy;
  final String actionTurnOn;
  final String actionTurnOff;
  // Cyber screen
  final String cyberNoEvents;
  final String cyberNetworkMap;
  final String cyberNetworkTopology;
  final String cyberPhones;
  final String cyberOnlineFmt;   // {on} {total}
  // Home-style picker (profile)
  final List<String> homeTypeLabels;   // 10 ordered house types
  final List<String> homeColorLabels;  // 10 ordered palette colors
  final String homeTypeTitle;
  final String homeColorTitle;
  final String colorMix;
  final String pickLabel;
  // Profile — invite / manager / photo
  final String profilePhotoFmt;   // {name}
  final String inviteSubject;
  final String inviteBodyFmt;      // {code}
  final String noEmailApp;
  final String regManagerMsg;
  final String nameFieldFmt;       // {name}
  final String homeJoinTitle;
  final String shareCodeHint;
  final String gotIt;
  final String homeStyleTitle;
  final String registerAsFmt;      // {name}
  final String newCodeFmt;         // {code}
  final String joinCodeInline;
  final String inviteByEmail;
  final String inviteByEmailSub;
  final String tailscaleWhat;
  final String tailscaleDesc;
  final String tailscaleStep1;
  final String tailscaleStep2;
  final String tailscaleStep3;
  final String tailscaleOpen;
  // Cameras screen
  final String camScanNetwork;
  final String camScanning;
  final String camAddManual;
  final String camFieldName;
  final String camPort;
  final String camUser;
  final String camRtspPath;
  final String camStreamPath;
  final String camRtspHint;
  final String camPtzTitle;
  final String camPtzSub;
  final String camTestConn;
  final String camAddBtn;
  final String camFoundFmt;        // {info} {ports}
  final String camConnectFailFmt;  // {addr}

  /// Translates a known seed-automation string (name / condition / action) to
  /// the current locale. Falls back to the raw text for user-created automations.
  String translateAutomation(String raw) {
    switch (raw.trim()) {
      // names — Hebrew keys
      case 'עזיבת הבית':                    return leaveHome;
      case 'כניסה לבית':                    return autoArrive;
      case 'לילה טוב':                      return goodNight;
      case 'בוקר טוב':                      return autoMorning;
      case 'חיסכון בחשמל':                  return autoEnergySave;
      // names — English keys (mock data stored in English)
      case 'Motion Night Lights':           return autoMotionNight;
      case 'Leaving Home':                  return leaveHome;
      case 'Arriving Home':                 return autoArrive;
      case 'Good Night':                    return goodNight;
      case 'Good Morning':                  return autoMorning;
      case 'Energy Saving':                 return autoEnergySave;
      // names — Arabic
      case 'إضاءة ليلية بالحركة':          return autoMotionNight;
      case 'مغادرة المنزل':                return leaveHome;
      case 'الوصول إلى المنزل':            return autoArrive;
      case 'تصبح على خير':                 return goodNight;
      case 'صباح الخير':                   return autoMorning;
      case 'توفير الطاقة':                 return autoEnergySave;
      // names — Amharic
      case 'በእንቅስቃሴ የሌሊት መብራት':          return autoMotionNight;
      case 'ቤት ውጣ':                        return leaveHome;
      case 'ወደ ቤት መድረስ':                  return autoArrive;
      case 'መልካም ሌሊት':                    return goodNight;
      case 'እንደምን አደሩ':                   return autoMorning;
      case 'ኢነርጂ ቁጠባ':                    return autoEnergySave;
      // names — Spanish
      case 'Luz nocturna por movimiento':   return autoMotionNight;
      case 'Salir de casa':                 return leaveHome;
      case 'Llegada a casa':                return autoArrive;
      case 'Buenas noches':                 return goodNight;
      case 'Buenos días':                   return autoMorning;
      case 'Ahorro de energía':             return autoEnergySave;
      // names — Russian
      case 'Ночной свет по движению':       return autoMotionNight;
      case 'Уйти из дома':                  return leaveHome;
      case 'Прибытие домой':                return autoArrive;
      case 'Спокойной ночи':                return goodNight;
      case 'Доброе утро':                   return autoMorning;
      case 'Экономия энергии':              return autoEnergySave;
      // names — French
      case 'Éclairage nocturne par mouvement': return autoMotionNight;
      case 'Quitter la maison':             return leaveHome;
      case 'Arrivée à la maison':           return autoArrive;
      case 'Bonne nuit':                    return goodNight;
      case 'Bonjour':                       return autoMorning;
      case "Économie d'énergie":            return autoEnergySave;
      // recommendation names — Hebrew
      case 'חיסכון בשעות שיא':             return recPeakName;
      case 'מצב נסיעה':                    return recTravelName;
      case 'ניהול טמפרטורה':               return recTempName;
      // recommendation names — English
      case 'Peak Hours Saving':             return recPeakName;
      case 'Travel Mode':                   return recTravelName;
      case 'Temperature Control':           return recTempName;
      // recommendation names — Arabic
      case 'توفير ساعات الذروة':           return recPeakName;
      case 'وضع السفر':                    return recTravelName;
      case 'التحكم بالحرارة':              return recTempName;
      // recommendation names — Amharic
      case 'የጫፍ ሰዓት ቁጠባ':                return recPeakName;
      case 'የጉዞ ሁነታ':                     return recTravelName;
      case 'የሙቀት ቁጥጥር':                  return recTempName;
      // recommendation names — Spanish
      case 'Ahorro en horas pico':          return recPeakName;
      case 'Modo viaje':                    return recTravelName;
      case 'Control de temperatura':        return recTempName;
      // recommendation names — Russian
      case 'Экономия в часы пик':           return recPeakName;
      case 'Режим поездки':                 return recTravelName;
      case 'Контроль температуры':          return recTempName;
      // recommendation names — French
      case 'Économie aux heures de pointe': return recPeakName;
      case 'Mode voyage':                   return recTravelName;
      case 'Contrôle de la température':   return recTempName;
      // conditions — Hebrew keys
      case 'אם אין אף אחד בבית':            return condNobodyHome;
      case 'אם נכנסים לבית':                return condArrive;
      case 'שעה 23:00':                     return condTime2300;
      case 'שעה 07:00 בימי חול':            return condMorningWeekday;
      case 'אם אין תנועה 30 דקות':          return condNoMotion30;
      // conditions — English keys (mock data)
      case 'Motion detected AND Night (21:00–06:00)': return condMotionNight;
      case 'If nobody is home':             return condNobodyHome;
      case 'If someone enters the home':    return condArrive;
      case 'At 23:00':                      return condTime2300;
      case 'At 07:00 on weekdays':          return condMorningWeekday;
      case 'If no motion for 30 minutes':   return condNoMotion30;
      // actions — Hebrew keys
      case 'הפעל אזעקה + כבה הכל':          return actAlarmOffAll;
      case 'הדלק אורות + כבה אזעקה':        return actLightsAlarmOff;
      case 'כבה הכל + נעל דלתות':           return actOffLock;
      case 'פתח תריסים + הדלק קפה':         return actBlindsCoffee;
      case 'כבה אורות ומזגנים':             return actOffLightsAc;
      // actions — English keys (mock data)
      case 'Turn on all lights':            return actAllLightsOn;
      case 'Activate alarm + turn off everything': return actAlarmOffAll;
      case 'Turn on lights + deactivate alarm':    return actLightsAlarmOff;
      case 'Turn off everything + lock doors':     return actOffLock;
      case 'Open blinds + start coffee':           return actBlindsCoffee;
      case 'Turn off lights and AC':               return actOffLightsAc;
      default:                              return raw;
    }
  }

  /// Translates a known camera location name (e.g. 'Front Door') to the current
  /// locale. Falls back to the raw name for custom/user-renamed cameras.
  String translateCameraName(String name) {
    switch (name.trim().toLowerCase()) {
      case 'front door':  return camFrontDoor;
      case 'back door':   return camBackDoor;
      case 'garage':      return camGarage;
      case 'backyard':
      case 'back yard':   return camBackyard;
      case 'entrance':    return camEntrance;
      case 'driveway':    return camDriveway;
      case 'balcony':     return camBalcony;
      case 'living room': return roomNameLiving;
      case 'garden':      return roomNameGarden;
      case 'kitchen':     return roomNameKitchen;
      case 'bedroom':     return roomNameBedroom;
      case 'bathroom':    return roomNameBathroom;
      default:            return name;
    }
  }

  /// Translates a room key (e.g. '__living__') to the current locale's name.
  /// Falls back to the raw string for user-created rooms.
  String translateRoomKey(String name) {
    switch (name) {
      case '__living__':  return roomNameLiving;
      case '__kitchen__': return roomNameKitchen;
      case '__bedroom__': return roomNameBedroom;
      case '__kids__':    return roomNameKids;
      case '__media__':   return roomNameMedia;
      case '__bathroom__':return roomNameBathroom;
      case '__garden__':  return roomNameGarden;
      case '__main__':    return breakerMain;
      case '__storage__': return roomNameStorage;
      case '__ac__':      return roomNameAc;
      default:            return name;
    }
  }

  // Login screen
  final String rememberMe;

  // Solar system
  final String notConnectedLabel;
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
  final String assignRoom;
  final String noRoom;
  final String newRoom;

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
  final String keepShabbatLabel;
  final String shabbatSection;
  final String shabbatCandlesDesc;
  final String shabbatHavdalahDesc;

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

  // ── Home screen (redesigned) ─────────────────────────────────
  final String homeGreetingSub;
  final String energyToday;
  final String vsYesterday;
  final String energyAnalytics;
  final String securitySystemLabel;
  final String secArmedShort;
  final String secDisarmedShort;
  final String allOkLabel;
  final String emergencyBtn;
  final String showAll;
  final String roomsHeader;
  final String statHomesLabel;
  final String devicesUnit;
  final String qaLock;
  final String qaLights;
  final String qaAc;
  final String qaCameras;
  final String qaAlerts;
  final String qaPlugs;
  final String qaWaterHeater;
  final String qaBreakers;
  final String qaNoDevices;
  final String qaNoAlerts;
  final String qaResetAll;
  final String qaScanDevice;
  final String adAddLink;
  final String adCustomLink;
  final String systemStatus;
  final String statusInternet;
  final String statusSensors;
  final String connectedLabel;
  final String camMotion;
  final String camOnline;
  final String camOffline;
  final String locationUnavailable;
  final String gatewaysManage;
  final String gatewaysTitle;
  final String statusOffline;
  final String secArmStayBtn;
  final String secDisarmBtn;
  final String roomNameMedia;
  final String mediaRoomTitle;
  final String roomOccupantLabel;
  final String occupantNone;
  final String occupantKids;
  final String occupantAdults;

  // Settings — previously hardcoded in Hebrew
  final String autoThemeLabel;
  final String autoThemeDesc;
  final String autoThemeActive;
  final String autoThemeWaiting;
  final String homeLayoutLabel;
  final String signOutAppTitle;
  final String signOutChoose;
  final String signOutToLogin;
  final String signOutToLoginSub;
  final String signOutFull;
  final String signOutFullSub;
  // Switch account (Settings → Account)
  final String accountSection;
  final String switchAccountTitle;
  final String switchAccountSub;
  final String switchAccountConfirmTitle;
  final String switchAccountConfirmBody;
  final String switchAccountConfirmBtn;
  final String switchAccountPasswordPrompt;
  final String switchAccountWrongPassword;
  // Installer mode (Profile hero badge)
  final String installerBadge;
  final String installerCodeTitle;
  final String installerCodeHint;
  final String installerCodeWrong;
  final String installerModeOnMsg;
  final String installerModeOffMsg;
  final String installerExitConfirm;
  // Offline-device toggle hint (shown when tapping a locked switch)
  final String deviceOfflineHint;
  // AI Agent
  final String aiBackendNotConfigured;
  final String aiRequestFailed;
  final String aiEmptyReply;
  final String aiTooManySteps;
  // Smart Mirror
  final String mirrorScreenTitle;
  // Ad banner
  final String adBannerShop;

  // Login additional
  final String loginBiometric;
  final String errInvalidEmail;
  final String loginGoogleEmailPrompt;

  // Store
  final String storeBuyAt;

  // Date / calendar pickers
  final String confirm;
  final String pickDay;
  final String pickMonth;
  final String pickHebrewDate;
  final String hebrewDateFmt;    // {date}
  final String hebrewCalendarChip;

  // Scan discovery screen
  final String scanNetworkTitle;
  final String scanSelectDevice;
  final String stop;
  final String scanSensorsShutters;

  // Sensor hub screen
  final String sensorHubTitle;
  final String sensorHubFoundFmt;   // {sensors}/{covers}
  final String sensorsTab;
  final String shuttersTab;
  final String noSensorsFound;
  final String noCoversFound;
  final String coverOpen;
  final String coverStop;
  final String coverClose;

  // Smart switch hub screen
  final String switchScanningAll;
  final String switchAddedFmt;        // {name}
  final String keyStoredLocal;
  final String saveAndControl;
  final String tapoLogin;
  final String tapoCredHint;
  final String connectAndControl;
  final String errControlFmt;         // {name}
  final String switchSearchingAll;
  final String switchNoFound;
  final String switchHint;

  // Camera player screen
  final String camFrameCaptureError;
  final String camNoFaces;
  final String camFacesFoundFmt;    // {count}/{known}
  final String camFacesOnlyFmt;     // {count}
  final String camAnalysisErrorFmt; // {error}
  final String camCaptureError;
  final String camSnapshotSavedFmt; // {ts}
  final String camSaveSnapshotError;
  final String camConnectingFmt;    // {name}
  final String camIdentifyingFaces;
  final String camDetectingFaces;
  final String camFaceLabelFmt;     // {n}
  final String camStreamConnFailed;

  // Add device screen
  final String addWizBulb;
  final String addWizBulbSub;
  final String deviceNotFoundStatus;
  final String manualAddStatus;
  final String connecting;
  final String deviceNotFoundHint;
  final String manualAddLabel;
  final String deviceNameLabel;
  final String deviceDeleteConfirm;
  final String ipAddressOptional;
  final String back;

  // Face enrollment screen
  final String faceConfigured;
  final String faceIdTitle;
  final String faceIdSubtitle;
  final String faceTraining;
  final String faceTrainModelFmt;    // {enrolled}/{total}
  final String facePrepGroup;
  final String faceTrainStartFailed;
  final String faceTrainingProgress;
  final String faceTrainSuccess;
  final String faceTrainFailed;
  final String faceSetAzureKeyFirst;
  final String faceAddingPhoto;
  final String faceCreateRecordError;
  final String faceFaceNotDetected;
  final String facePhotoAddedFmt;    // {name}
  final String faceNotConfiguredTap;
  final String faceCheckConnection;
  final String faceGetFreeApiKey;
  final String faceSaveSettingsFirst;
  final String faceAzureConnOk;
  final String faceAzureConnFailed;
  final String faceEnrolledAzure;
  final String faceNotEnrolled;
  final String faceAddPerson;
  final String faceFullNameHint;
  final String faceEnterName;
  final String faceCreatingRecord;
  final String faceNoPeople;
  final String faceNoPeopleHint;

  // Room setup screen
  final String roomSettings;
  final String capComingSoonFmt; // {cap}

  // Household login screen
  final String householdNoAdmin;
  final String householdMemberNote;
  final String backToLogin;
  final String householdAdmin;
  final String selectProfile;
  final String noMembersYet;
  final String addMembersHint;

  // Smart switch scan sheet
  final String switchScanProgressFmt; // {n}
  final String switchNoDevicesHint;
  final String scanDoneFmt;           // {n}
  final String scanWifi;

  // Face analysis screen
  final String faceAnalysisTitle;
  final String faceAnalysisSubtitle;
  final String clear;
  final String clearHistory;
  final String clearHistoryConfirm;
  final String statScans;
  final String statFacesDetected;
  final String statAlerts;
  final String faces;
  final String smiling;
  final String eyesClosed;
  final String noFacesInFrame;
  final String noAnalysesYet;
  final String faceAnalysisHint;

  // Smarthome screen
  final String smartHomeTitle;
  final String temperatureFmt;   // {n}
  final String brightnessFmt;    // {n}
  final String positionFmt;      // {n}

  // WiZ setup screen
  final String wizIdentifyingWifi;
  final String wizNoWifi;
  final String wizBroadcastingFmt;   // {prefix}
  final String wizNoFound;
  final String wizFoundFmt;          // {n}
  final String wizScanFailed;
  final String wizBlinkingFmt;       // {ip}
  final String wizBlinkSentFmt;      // {ip}
  final String wizNoResponseFmt;     // {ip}
  final String wizDeviceAddedFmt;    // {name}
  final String wizManualAdd;
  final String wizTest;

  // Gateway hub screen
  final String gatewayHubTitle;
  final String gatewayHubSubtitle;
  final String connected;
  final String addGateway;
  final String gatewayTypesFmt;       // {n}
  final String devicesImportedFmt;    // {n}, {name}
  final String allDevicesExist;
  final String diagnosisTitle;
  final String disconnectConfirmFmt;  // {name}
  final String importedDevicesNote;
  final String disconnect;
  final String deviceCountFmt;        // {n}
  final String importDevices;

  // Gateway connect sheet
  final String connect;
  final String connectAfterButton;
  final String connectedSuccess;
  final String secondsRemainingFmt; // {n}
  final String cloud;
  final String cloudConnectionNote;
  final String setupStepsHintFmt;   // {n}
  final String tokenPortalFmt;      // {name}
  final String optional;

  // Z2M connect sheet
  final String z2mEnterIp;
  final String z2mUnreachableFmt;   // {ip}, {port}
  final String z2mUnknownError;
  final String z2mSubtitle;
  final String z2mIpLabel;
  final String z2mIpHint;
  final String z2mPortLabel;
  final String z2mTokenLabel;
  final String z2mTokenHint;
  final String z2mFoundFmt;         // {n}
  final String z2mConnectImport;
  final String z2mFrontendHelp;

  // Discovery sheet
  final String discoveryTitle;
  final String scan;
  final String matterDeviceTitle;
  final String matterDeviceHelp;
  final String understood;
  final String devicesAddedFmt;   // {n}
  final String haFound;
  final String haConnectedFmt;    // {n}
  final String haConnect;
  final String haReconnectSync;
  final String haTokenHint;
  final String importFromHa;
  final String scanningDevices;
  final String scanHint;
  final String addAllFmt;         // {n}

  // Matter commissioning screen
  final String matterCommTitle;
  final String matterCommSubtitle;
  final String matterCommScanBtn;
  final String matterCommManualBtn;
  final String matterCommManualHint;
  final String matterCommissioning;
  final String matterCommSuccess;
  final String matterCommFailed;
  final String matterCommNoHa;
  final String matterCommRetry;
  final String matterCommCodeHint;

  // Blinds hub screen
  final String blindsHubTitle;
  final String openAll;
  final String closeAll;
  final String noBlindsFound;
  final String blindsHint;

  // Smart locks hub screen
  final String smartLocksTitle;
  final String lockedStatus;
  final String unlockedStatus;
  final String lockAll;
  final String unlockAll;
  final String noLocksFound;
  final String lockHint;

  // Lights hub screen
  final String lightsHubTitle;
  final String lightsAllOn;
  final String lightsAllOff;
  final String noLightsFound;
  final String lightsHint;

  // Plugs hub screen
  final String plugsHubTitle;
  final String plugsAllOn;
  final String plugsAllOff;
  final String noPlugsFound;
  final String plugsHint;

  // AC hub screen
  final String acHubTitle;

  // Intercom hub screen
  final String intercomTitle;
  final String intercomNoDevices;
  final String intercomHint;
  final String intercomRing;
  final String intercomAnswer;
  final String intercomDecline;
  final String intercomCategory;
  final String intercomRinging;
  final String intercomUnlockDoor;

  // Robot vacuum
  final String vacuumCategory;
  final String vacuumNoDevices;
  final String vacuumHint;
  final String vacuumStart;
  final String vacuumPause;
  final String vacuumDock;
  final String vacuumCleaning;
  final String vacuumDocked;

  // Energy rate
  final String energyRateLabel;
  final String energyRateEdit;
  final String energyRateUnit;
  final String energyRateSaved;

  // Backup / Export
  final String backupTitle;
  final String backupExport;
  final String backupImport;
  final String backupExportDone;
  final String backupImportDone;
  final String backupImportError;
  final String backupSection;

  // Biometric splash & permission strings
  final String biometricSplashLabel;
  final String camLocationPermission;
  final String camNoWifiIp;
  final String camScanNoneFound;

  // Security screen (layout management)
  final String showHideSections;
  final String restoreDefaults;
  final String restoreDefaultsConfirm;
  final String restore;
  final String systemTest;

  const S({
    this.intercomTitle      = 'Intercom',
    this.intercomNoDevices  = 'No intercom devices found',
    this.intercomHint       = 'Add an intercom device via the catalog or gateway import',
    this.intercomRing       = 'Ring',
    this.intercomAnswer     = 'Answer',
    this.intercomDecline    = 'Decline',
    this.intercomCategory   = 'Video Doorbell',
    this.intercomRinging    = 'Someone at the door…',
    this.intercomUnlockDoor = 'Unlock door',
    this.vacuumCategory  = 'Robot Vacuum',
    this.vacuumNoDevices = 'No robot vacuums found',
    this.vacuumHint      = 'Connect your robot vacuum through Home Assistant to see it here',
    this.vacuumStart     = 'Start',
    this.vacuumPause     = 'Pause',
    this.vacuumDock      = 'Return to dock',
    this.vacuumCleaning  = 'Cleaning',
    this.vacuumDocked    = 'Docked',
    this.energyRateLabel    = 'Electricity rate',
    this.energyRateEdit     = 'Edit rate',
    this.energyRateUnit     = '₪/kWh',
    this.energyRateSaved    = 'Rate saved',
    this.backupTitle        = 'Backup & Restore',
    this.backupExport       = 'Export settings',
    this.backupImport       = 'Import settings',
    this.backupExportDone   = 'Settings exported to Downloads',
    this.backupImportDone   = 'Settings restored successfully',
    this.backupImportError  = 'Failed to import — invalid file',
    this.backupSection      = 'Data & Backup',
    this.biometricSplashLabel   = 'Authenticate',
    this.camLocationPermission  = 'Location permission required to scan the network',
    this.camNoWifiIp = "Couldn't detect your WiFi network — connect to WiFi and try again, or add the camera manually",
    this.camScanNoneFound = "No cameras found on the network. If yours isn't ONVIF-compatible, add it manually with its IP address instead.",
    // Home screen (redesigned) — English defaults; locales override below.
    this.homeGreetingSub     = 'Your home, safe & smart.',
    this.aiSugDesc1   = 'I can turn off all the lights in the house',
    this.aiSugDesc2   = 'Get a full summary of the home and its systems',
    this.aiSugDesc3   = 'I\'ll turn on all the night mode settings',
    this.aiSugDesc4   = 'Check for alerts and unusual conditions',
    this.aiPrivacyNote = 'Your information is private and protected',
    this.aiTopSubtitle = 'Your smart home\'s helper',
    this.aiClearChat = 'Clear conversation',
    this.climateEnergyTitle  = 'Climate & Energy',
    this.homeManagementTitle = 'Home Management',
    this.energyToday         = 'Energy today',
    this.vsYesterday         = 'vs yesterday',
    this.energyAnalytics     = 'Energy Analytics',
    this.securitySystemLabel = 'Security System',
    this.secArmedShort       = 'Armed',
    this.secDisarmedShort    = 'Disarmed',
    this.allOkLabel          = 'All systems OK',
    this.emergencyBtn        = 'Emergency',
    this.showAll             = 'Show all',
    this.roomsHeader         = 'Rooms',
    this.statHomesLabel      = 'Homes',
    this.devicesUnit         = 'devices',
    this.qaLock              = 'Lock',
    this.qaLights            = 'Lights',
    this.qaAc                = 'AC',
    this.qaCameras           = 'Cameras',
    this.qaAlerts            = 'Alerts',
    this.qaPlugs             = 'Plugs',
    this.qaWaterHeater       = 'Heater',
    this.qaBreakers          = 'Panel',
    this.qaNoDevices         = 'No devices connected',
    this.qaNoAlerts          = 'No alerts',
    this.qaResetAll          = 'Reset All',
    this.qaScanDevice        = 'Scan for Device',
    this.adAddLink           = 'Add Link',
    this.adCustomLink        = 'Custom Link',
    this.systemStatus        = 'System status',
    this.statusInternet      = 'Internet',
    this.statusSensors       = 'Sensors',
    this.connectedLabel      = 'Connected',
    this.camMotion           = 'Motion detected',
    this.camOnline           = 'Online',
    this.camOffline          = 'Offline',
    this.locationUnavailable = 'Location unavailable',
    this.gatewaysManage      = 'Manage',
    this.gatewaysTitle       = 'Gateways',
    this.statusOffline       = 'Offline',
    this.secArmStayBtn       = 'Arm (Stay)',
    this.secDisarmBtn        = 'Disarm',
    this.roomNameMedia       = 'Media',
    this.roomNameBathroom    = 'Bathroom',
    this.roomNameStorage     = 'Storage',
    this.roomNameAc          = 'AC',
    this.mediaRoomTitle      = 'Media',
    this.roomOccupantLabel   = 'Who uses this room?',
    this.occupantNone        = 'None',
    this.occupantKids        = 'Kids',
    this.occupantAdults      = 'Adults',
    this.autoThemeLabel      = 'Auto Theme',
    this.autoThemeDesc       = 'Adapts theme to ambient light',
    this.autoThemeActive     = 'Active',
    this.autoThemeWaiting    = 'Waiting for sensor…',
    this.homeLayoutLabel     = 'Home Layout',
    this.signOutAppTitle     = 'Exit App',
    this.signOutChoose       = 'Choose how to exit',
    this.signOutToLogin      = 'Sign out & return to login',
    this.signOutToLoginSub   = 'Disconnects account — login required',
    this.signOutFull         = 'Full Exit',
    this.signOutFullSub      = 'Signs out & closes the app',
    this.accountSection             = 'Account',
    this.switchAccountTitle         = 'Switch Account',
    this.switchAccountSub           = 'Sign out and sign in with a different account',
    this.switchAccountConfirmTitle  = 'Switch account?',
    this.switchAccountConfirmBody   = "You'll be signed out and returned to the login screen.",
    this.switchAccountConfirmBtn    = 'Switch Account',
    this.switchAccountPasswordPrompt = 'Enter your password to confirm',
    this.switchAccountWrongPassword  = 'Incorrect password',
    this.installerBadge        = 'INSTALLER',
    this.installerCodeTitle    = 'Installer Mode',
    this.installerCodeHint     = 'Enter installer code',
    this.installerCodeWrong    = 'Incorrect installer code',
    this.installerModeOnMsg    = 'Installer Mode activated',
    this.installerModeOffMsg   = 'Installer Mode exited',
    this.installerExitConfirm  = 'Exit Installer Mode?',
    this.deviceOfflineHint = 'Device offline — check its connection',
    this.aiBackendNotConfigured = 'AI assistant is not set up yet',
    this.aiRequestFailed = "Sorry, I couldn't reach the assistant right now",
    this.aiEmptyReply = "Done.",
    this.aiTooManySteps = 'That request needs too many steps — try something simpler',
    this.mirrorScreenTitle   = 'Smart Mirror',
    this.adBannerShop        = 'Shop',
    this.loginBiometric      = 'Sign in with fingerprint / face',
    this.errInvalidEmail     = 'Invalid email address',
    this.loginGoogleEmailPrompt = 'Enter your Gmail address to continue',
    this.scanNetworkTitle    = 'Network Scan',
    this.scanSelectDevice    = 'Select device to add',
    this.stop                = 'Stop',
    this.scanSensorsShutters = 'Sensors · Shutters',
    this.storeBuyAt          = 'Buy at',
    this.confirm             = 'OK',
    this.pickDay             = 'Day',
    this.pickMonth           = 'Month',
    this.pickHebrewDate      = 'Choose Hebrew date',
    this.hebrewDateFmt       = 'Hebrew date: {date}',
    this.hebrewCalendarChip  = 'Hebrew date…',
    this.sensorHubTitle       = 'Sensors & Shutters',
    this.sensorHubFoundFmt    = '{sensors} sensors · {covers} shutters',
    this.sensorsTab           = 'Sensors',
    this.shuttersTab          = 'Shutters',
    this.noSensorsFound       = 'No sensors found',
    this.noCoversFound        = 'No shutters found',
    this.coverOpen            = '▲  Open',
    this.coverStop            = '■  Stop',
    this.coverClose           = '▼  Close',
    this.switchScanningAll    = 'Scanning all protocols…',
    this.switchAddedFmt       = '✓ {name} added to home',
    this.keyStoredLocal       = 'Key is stored on your device only.',
    this.saveAndControl       = 'Save & Control',
    this.tapoLogin            = 'Tapo — Sign In',
    this.tapoCredHint         = 'Same credentials as the TP-Link Tapo app.',
    this.connectAndControl    = 'Connect & Control',
    this.errControlFmt        = 'Control error for {name}',
    this.switchSearchingAll   = 'Searching for smart switches on all protocols…',
    this.switchNoFound        = 'No smart switches found',
    this.switchHint           = 'Make sure switches are on the same WiFi network.\nShelly/ESPHome — in STA mode\nSonoff — in DIY mode (firmware 3.6+)\nHome Assistant / Zigbee2MQTT — connect in Settings',
    this.camFrameCaptureError = 'Error capturing frame',
    this.camNoFaces           = 'No faces detected',
    this.camFacesFoundFmt     = 'Detected {count} faces — {known} identified 🎯',
    this.camFacesOnlyFmt      = 'Detected {count} faces 🎯',
    this.camAnalysisErrorFmt  = 'Analysis error: {error}',
    this.camCaptureError      = 'Capture error',
    this.camSnapshotSavedFmt  = '📸 Saved: snapshot_{ts}.png',
    this.camSaveSnapshotError = 'Error saving snapshot',
    this.camConnectingFmt     = 'Connecting to {name}…',
    this.camIdentifyingFaces  = 'Identifying faces and identity…',
    this.camDetectingFaces    = 'Detecting faces…',
    this.camFaceLabelFmt      = 'Face {n}',
    this.camStreamConnFailed  = 'Cannot connect to stream',
    this.addWizBulb           = 'Add real WiZ bulb',
    this.addWizBulbSub        = 'True LAN control · no cloud',
    this.deviceNotFoundStatus = 'Device not found',
    this.manualAddStatus      = 'Manual add',
    this.connecting           = 'Connecting…',
    this.deviceNotFoundHint   = 'Make sure the device is powered and on WiFi,\nor that Bluetooth is on and enabled.',
    this.manualAddLabel       = 'Add manually',
    this.deviceNameLabel      = 'Device name',
    this.deviceDeleteConfirm  = 'Remove this device from the app? You can add it back later by scanning again.',
    this.ipAddressOptional    = 'IP address (optional)',
    this.back                 = 'Back',
    this.faceConfigured       = '✓ Configured',
    this.faceIdTitle          = 'Face ID',
    this.faceIdSubtitle       = 'Enroll known people for automatic recognition',
    this.faceTraining         = 'Training model…',
    this.faceTrainModelFmt    = 'Train model ({enrolled}/{total} enrolled)',
    this.facePrepGroup        = 'Preparing group…',
    this.faceTrainStartFailed = '❌ Could not start training',
    this.faceTrainingProgress = 'Training… (may take up to 60 s)',
    this.faceTrainSuccess     = '✅ Model trained successfully! Recognition active.',
    this.faceTrainFailed      = '❌ Training failed. Try again.',
    this.faceSetAzureKeyFirst = 'Set Azure API Key first',
    this.faceAddingPhoto      = 'Adding photo to Azure…',
    this.faceCreateRecordError= '❌ Error creating record in Azure',
    this.faceFaceNotDetected  = '❌ No face detected in this photo',
    this.facePhotoAddedFmt    = '✅ Photo added to {name}. Train the model.',
    this.faceNotConfiguredTap = 'Not configured — tap to set up',
    this.faceCheckConnection  = 'Test connection',
    this.faceGetFreeApiKey    = 'Get a free API Key at portal.azure.com → Cognitive Services',
    this.faceSaveSettingsFirst= '⚠️ Save settings first',
    this.faceAzureConnOk      = '✅ Azure connection successful!',
    this.faceAzureConnFailed  = '❌ Cannot connect. Check Endpoint + Key',
    this.faceEnrolledAzure    = '✓ Enrolled in Azure',
    this.faceNotEnrolled      = '⚠ Not enrolled — add a photo',
    this.faceAddPerson        = 'Add person',
    this.faceFullNameHint     = 'Full name',
    this.faceEnterName        = 'Enter a name',
    this.faceCreatingRecord   = 'Creating record…',
    this.faceNoPeople         = 'No people enrolled',
    this.faceNoPeopleHint     = 'Add people so cameras can identify them by name',
    this.roomSettings         = 'Room settings',
    this.capComingSoonFmt     = '{cap} — coming soon',
    this.householdNoAdmin     = 'No household admin yet',
    this.householdMemberNote  = 'Member login is available after the household admin\nregisters with Google or Apple.',
    this.backToLogin          = 'Back to login screen',
    this.householdAdmin       = 'Household admin',
    this.selectProfile        = 'Select profile',
    this.noMembersYet         = 'No household members yet',
    this.addMembersHint       = 'The household admin can add members\nin the Profile area ← Household management.',
    this.switchScanProgressFmt = 'Scanning… {n} / 254',
    this.switchNoDevicesHint   = 'No devices found. Make sure devices are on the same WiFi network',
    this.scanDoneFmt           = 'Scan complete — {n} devices',
    this.scanWifi              = 'Scan WiFi network',
    this.faceAnalysisTitle    = 'Face Detection Analysis',
    this.faceAnalysisSubtitle = 'Camera scan history',
    this.clear                = 'Clear',
    this.clearHistory         = 'Clear history',
    this.clearHistoryConfirm  = 'Delete all analysis results?',
    this.delete               = 'Delete',
    this.statScans            = 'Scans',
    this.statFacesDetected    = 'Faces detected',
    this.statAlerts           = 'Alerts',
    this.faces                = 'Faces',
    this.smiling              = 'Smiling',
    this.eyesClosed           = 'Eyes closed',
    this.noFacesInFrame       = 'No faces detected in this frame',
    this.noAnalysesYet        = 'No analyses yet',
    this.faceAnalysisHint     = 'Open a camera and tap the "Analyze" button\nto enable face detection',
    this.smartHomeTitle       = 'Smart Home',
    this.temperatureFmt       = 'Temperature: {n}°C',
    this.brightnessFmt        = 'Brightness: {n}%',
    this.positionFmt          = 'Position: {n}%',
    this.wizIdentifyingWifi   = 'Identifying WiFi network…',
    this.wizNoWifi            = 'Not connected to WiFi — enter IP manually',
    this.wizBroadcastingFmt   = 'Broadcasting WiZ discovery at {prefix}.x…',
    this.wizNoFound           = 'No WiZ bulbs found — try manually',
    this.wizFoundFmt          = 'Found {n} bulbs',
    this.wizScanFailed        = 'Scan failed — try manually',
    this.wizBlinkingFmt       = 'Blinking {ip}…',
    this.wizBlinkSentFmt      = 'Blink command sent to {ip} ✓',
    this.wizNoResponseFmt     = 'No response from {ip} — check bulb is on network',
    this.wizDeviceAddedFmt    = '{name} added — real control active',
    this.wizManualAdd         = 'Manual add by IP address',
    this.wizTest              = 'Test',
    this.gatewayHubTitle      = 'Gateways & Control Hubs',
    this.gatewayHubSubtitle   = 'Connect Zigbee, Z-Wave, WiFi & cloud hubs',
    this.connected            = 'Connected',
    this.addGateway           = 'Add gateway',
    this.gatewayTypesFmt      = '{n} types',
    this.devicesImportedFmt   = 'Added {n} devices from {name}',
    this.allDevicesExist      = 'All devices already exist',
    this.diagnosisTitle       = 'Devices the hub reports',
    this.disconnectConfirmFmt = 'Disconnect "{name}"?',
    this.importedDevicesNote  = 'Imported devices will remain, but no more can be imported.',
    this.disconnect           = 'Disconnect',
    this.deviceCountFmt       = '{n} devices',
    this.importDevices        = 'Import devices',
    this.connect              = 'Connect',
    this.connectAfterButton   = 'Connect (after button press)',
    this.connectedSuccess     = 'Connected successfully!',
    this.secondsRemainingFmt  = '{n} seconds remaining',
    this.cloud                = 'Cloud',
    this.cloudConnectionNote  = 'Cloud connection — data passes through manufacturer servers',
    this.setupStepsHintFmt    = 'How to get the credentials? ({n} steps)',
    this.tokenPortalFmt       = 'Token created in {name} portal',
    this.optional             = 'Optional',
    this.z2mEnterIp           = 'Enter the Zigbee2MQTT IP address',
    this.z2mUnreachableFmt    = 'Cannot reach Zigbee2MQTT at {ip}:{port}\nCheck frontend is running and IP is correct',
    this.z2mUnknownError      = 'Unknown error',
    this.z2mSubtitle          = 'Connect to Zigbee gateway — automatic device import',
    this.z2mIpLabel           = 'Z2M IP address',
    this.z2mIpHint            = 'E.g.: 192.168.1.50',
    this.z2mPortLabel         = 'Port',
    this.z2mTokenLabel        = 'API Token (optional)',
    this.z2mTokenHint         = 'If configured',
    this.z2mFoundFmt          = 'Found {n} Zigbee devices!',
    this.z2mConnectImport     = 'Connect & import devices',
    this.z2mFrontendHelp      = 'Enable frontend in Z2M config:\n  frontend:\n    port: 8080',
    this.discoveryTitle       = 'Search Devices',
    this.scan                 = 'Scan',
    this.matterDeviceTitle    = 'Matter Device',
    this.matterDeviceHelp     = 'Matter devices (like IKEA bulbs) are paired via a Matter hub — not directly from the app.\n\nSimple way:\n1. Pair the bulb to DIRIGERA via the IKEA Home smart app.\n2. Here: Gateways → DIRIGERA → "Import devices".\nThe bulb will appear with full control.',
    this.understood           = 'Understood',
    this.devicesAddedFmt      = 'Added {n} devices',
    this.haFound              = 'Home Assistant found',
    this.haConnectedFmt       = 'Connected — {n} devices imported',
    this.haConnect            = 'Connect',
    this.haReconnectSync      = 'Reconnect & Sync',
    this.ipAddressLabel       = 'IP address',
    this.haTokenHint          = 'Create Token at: Profile → Long-Lived Access Tokens',
    this.importFromHa         = 'Import devices from Home Assistant',
    this.scanningDevices      = 'Searching for devices…',
    this.scanHint             = 'Press "Scan" to find devices on the network',
    this.addAllFmt            = 'Add all ({n} devices)',
    this.matterCommTitle      = 'Commission Matter Device',
    this.matterCommSubtitle   = 'Scan the QR code on the device label',
    this.matterCommScanBtn    = 'Scan QR Code',
    this.matterCommManualBtn  = 'Enter Code Manually',
    this.matterCommManualHint = '11-digit code (e.g. 12345-67890)',
    this.matterCommissioning  = 'Commissioning via Home Assistant…',
    this.matterCommSuccess    = 'Device commissioned successfully!',
    this.matterCommFailed     = 'Commissioning failed. Check HA Matter integration.',
    this.matterCommNoHa       = 'Home Assistant not connected. Connect HA first.',
    this.matterCommRetry      = 'Try Again',
    this.matterCommCodeHint   = 'MT:… or 11-digit pairing code',
    this.blindsHubTitle       = 'Blinds & Shutters',
    this.openAll              = 'Open All',
    this.closeAll             = 'Close All',
    this.noBlindsFound        = 'No blinds connected',
    this.blindsHint           = 'Add blinds via Home Assistant',
    this.smartLocksTitle      = 'Smart Locks',
    this.lockedStatus         = 'Locked',
    this.unlockedStatus       = 'Unlocked',
    this.lockAll              = 'Lock All',
    this.unlockAll            = 'Unlock All',
    this.noLocksFound         = 'No locks connected',
    this.lockHint             = 'Add a smart lock via Home Assistant',
    this.lightsHubTitle       = 'Lights',
    this.lightsAllOn          = 'All On',
    this.lightsAllOff         = 'All Off',
    this.noLightsFound        = 'No lights connected',
    this.lightsHint           = 'Add lights via Home Assistant',
    this.plugsHubTitle        = 'Smart Plugs',
    this.plugsAllOn           = 'All On',
    this.plugsAllOff          = 'All Off',
    this.noPlugsFound         = 'No smart plugs connected',
    this.plugsHint            = 'Add plugs via WiFi scan or Home Assistant',
    this.acHubTitle           = 'Air Conditioning',
    required this.navHome,
    required this.navCameras,
    required this.navSecurity,
    required this.navProfile,
    this.navAutomations = 'Automations',
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
    required this.bioUnavailable,
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
    required this.resetEmailHint,
    required this.resetEmailSent,
    required this.okButton,
    required this.cancelButton,
    required this.sendButton,
    required this.loginButton,
    required this.authOr,
    required this.loginNoAccount,
    required this.registerNow,
    required this.continueAsGuest,
    required this.loginWith,
    required this.appTagline,
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
    this.acPreset = 'Preset',
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
    required this.faq1Q, required this.faq1A,
    required this.faq2Q, required this.faq2A,
    required this.faq3Q, required this.faq3A,
    required this.faq4Q, required this.faq4A,
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
    required this.appearanceTitle,
    required this.themeFont,
    required this.themeAccent,
    required this.themeBg,
    required this.themeRadius,
    required this.themeBgDarkBlue,
    required this.themeBgAmoled,
    required this.themeBgDarkGray,
    required this.themeBgLightGray,
    required this.themeBgLightWhite,
    required this.themeRadiusSharp,
    required this.themeRadiusNormal,
    required this.themeRadiusRound,
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
    required this.waterLeakSensor,
    required this.securedStatus,
    required this.openStatus,
    required this.activeStatus,
    required this.normalStatus,
    required this.panicButton,
    required this.panicActivate,
    required this.panicWarning,
    required this.welcomeGuestBtn,
    required this.welcomeGuestActive,
    required this.welcomeGuestTimer,
    required this.welcomeGuestCancel,
    required this.welcomeGuestHint,
    required this.welcomeGuestChoose,
    required this.guestOptShort,
    required this.guestOptMedium,
    required this.guestOptLong,
    required this.guestMinutes,
    required this.chooseBrand,
    required this.pairingSteps,
    required this.allCameras,
    required this.liveLabel,
    required this.offlineLabel,
    this.deviceOn  = 'On',
    this.deviceOff = 'Off',
    required this.addDeviceBtn,
    this.deleteAll        = 'Delete all',
    this.deleteAllConfirm = 'Remove all devices from the list?',
    required this.notificationsTitle,
    required this.timeNow,
    required this.timeMinAgo,
    required this.timeHrAgo,
    required this.timeDayAgo,
    required this.deviceConnectedFmt,
    required this.camFrontDoor,
    required this.camBackDoor,
    required this.camGarage,
    required this.camBackyard,
    required this.camEntrance,
    required this.camDriveway,
    required this.camBalcony,
    required this.autoMotionNight,
    required this.autoArrive,
    required this.autoMorning,
    required this.autoEnergySave,
    required this.condMotionNight,
    required this.condNobodyHome,
    required this.condArrive,
    required this.condTime2300,
    required this.condMorningWeekday,
    required this.condNoMotion30,
    required this.actAllLightsOn,
    required this.actAlarmOffAll,
    required this.actLightsAlarmOff,
    required this.actOffLock,
    required this.actBlindsCoffee,
    required this.actOffLightsAc,
    required this.catSmoke,
    required this.catEnergy,
    required this.actionTurnOn,
    required this.actionTurnOff,
    required this.cyberNoEvents,
    required this.cyberNetworkMap,
    required this.cyberNetworkTopology,
    required this.cyberPhones,
    required this.cyberOnlineFmt,
    required this.homeTypeLabels,
    required this.homeColorLabels,
    required this.homeTypeTitle,
    required this.homeColorTitle,
    required this.colorMix,
    required this.pickLabel,
    required this.profilePhotoFmt,
    required this.inviteSubject,
    required this.inviteBodyFmt,
    required this.noEmailApp,
    required this.regManagerMsg,
    required this.nameFieldFmt,
    required this.homeJoinTitle,
    required this.shareCodeHint,
    required this.gotIt,
    required this.homeStyleTitle,
    required this.registerAsFmt,
    required this.newCodeFmt,
    required this.joinCodeInline,
    required this.inviteByEmail,
    required this.inviteByEmailSub,
    required this.tailscaleWhat,
    required this.tailscaleDesc,
    required this.tailscaleStep1,
    required this.tailscaleStep2,
    required this.tailscaleStep3,
    required this.tailscaleOpen,
    required this.camScanNetwork,
    required this.camScanning,
    required this.camAddManual,
    required this.camFieldName,
    required this.camPort,
    required this.camUser,
    required this.camRtspPath,
    required this.camStreamPath,
    required this.camRtspHint,
    required this.camPtzTitle,
    required this.camPtzSub,
    required this.camTestConn,
    required this.camAddBtn,
    required this.camFoundFmt,
    required this.camConnectFailFmt,
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
    required this.aiMicUnavailable,
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
    required this.haRemoveDeviceFailed,
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
    required this.scanBarcode,
    required this.searchScanProducts,
    required this.editUserName,
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
    required this.roomNameKitchen,
    required this.roomNameBedroom,
    required this.roomNameKids,
    required this.roomNameGarden,
    this.rememberMe = 'Remember me',
    this.notConnectedLabel = 'Not connected',
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
    this.assignRoom = 'Assign Room',
    this.noRoom = 'No room',
    this.newRoom = 'New room…',
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
    required this.keepShabbatLabel, required this.shabbatSection,
    required this.shabbatCandlesDesc, required this.shabbatHavdalahDesc,
    required this.acConnected, required this.acNoUnits,
    required this.adStoreLabel, required this.adTrackTitle, required this.adTrackSub,
    required this.adFeaturedLabel, required this.adFeaturedSub,
    required this.adNewLabel, required this.adNewSub,
    required this.adAllLabel, required this.adAllSub,
    required this.adNoneLabel, required this.adNoneSub,
    required this.showHideSections,
    required this.restoreDefaults,
    required this.restoreDefaultsConfirm,
    required this.restore,
    required this.systemTest,
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
      case AppLocale.french:
        return _fr;
      case AppLocale.hebrew:
        return _he;
    }
  }

  // ── Hebrew ────────────────────────────────────────────────────
  static const S _he = S(
    homeGreetingSub: 'הבית שלך, בטוח וחכם.', energyToday: 'צריכת אנרגיה היום', vsYesterday: 'מהאתמול',
    climateEnergyTitle: 'אקלים ואנרגיה', homeManagementTitle: 'ניהול הבית',
    energyAnalytics: 'ניתוח אנרגיה',
    securitySystemLabel: 'מערכת אבטחה', secArmedShort: 'מופעלת', secDisarmedShort: 'מנוטרל', allOkLabel: 'הכל תקין', emergencyBtn: 'לחצן חירום',
    showAll: 'הצג הכל', roomsHeader: 'חדרים', statHomesLabel: 'בתים', devicesUnit: 'מכשירים',
    qaLock: 'נעילה', qaLights: 'אורות', qaAc: 'מזגן', qaCameras: 'מצלמות', qaAlerts: 'התראות',
    qaPlugs: 'שקעים', qaWaterHeater: 'דוד חכם', qaBreakers: 'לוח חשמל',
    qaNoDevices: 'אין מכשירים מחוברים', qaNoAlerts: 'אין התראות', qaResetAll: 'אפס הכל', qaScanDevice: 'חפש מכשיר',
    adAddLink: 'הוסף קישור', adCustomLink: 'קישור מותאם',
    systemStatus: 'סטטוס מערכת', statusInternet: 'אינטרנט', statusSensors: 'חיישנים', connectedLabel: 'מחובר',
    camMotion: 'תנועה מזוהה', camOnline: 'מקוון', camOffline: 'לא מקוון', locationUnavailable: 'מיקום לא זמין', gatewaysManage: 'נהל', gatewaysTitle: 'גשרים', statusOffline: 'לא מקוון',
    secArmStayBtn: 'הפעל בבית', secDisarmBtn: 'נטרל', roomNameMedia: 'מדיה', mediaRoomTitle: 'מדיה',
    roomOccupantLabel: 'מי משתמש בחדר?', occupantNone: 'ללא', occupantKids: 'ילדים', occupantAdults: 'מבוגרים',
    navHome: 'חדרים', navCameras: 'מצלמות', navSecurity: 'אבטחה', navProfile: 'פרופיל', navAutomations: 'אוטומציות',
    greetingPrefix: 'שלום', homeSecured: 'הבית שלך מוגן', homeNotSecured: 'הבית לא מוגן',
    allSystemsActive: 'כל המערכות פעילות', tapToActivate: 'לחץ להפעיל מערכת אבטחה',
    alarmTitle: 'אזעקה', alarmSecured: 'מוגן', alarmOff: 'כבויה', roomManagement: 'ניהול בית', roomsUnit: 'חדרים',
    camerasTitle: 'מצלמות', lightsOn: 'אורות דלוקים', lightingTitle: 'תאורה',
    tempTitle: 'טמפרטורה', tempComfy: 'נעים', aiSubtitle: 'איך אפשר לעזור לך?', aiTopSubtitle: 'העוזר החכם של הבית שלך',
    quickActions: 'פעולות מהירות', leaveHome: 'יציאה מהבית', turnOffAll: 'כיבוי כל הבית', goodNight: 'לילה טוב', movieMode: 'מצב סרט',
    mediaTitle: 'מדיה', mediaSpeakers: 'רמקולים', mediaScan: 'סרוק מכשירים', mediaNoDevices: 'לא נמצאו רמקולים. לחץ סרוק.',
    bioTitle: 'כניסה מהירה', bioPrompt: 'להפעיל כניסה עם טביעת אצבע בפעמים הבאות?', bioEnable: 'הפעל', bioSkip: 'לא תודה', bioReason: 'אמת את זהותך כדי להיכנס',
    onbNext: 'הבא', onbStart: 'בוא נתחיל', onbSkip: 'דלג', onbAllow: 'אפשר', onbLater: 'אחר כך', onb1Title: 'ברוך הבא ל-FantaTech', onb1Body: 'הבית החכם שלך — תאורה, אבטחה, אקלים ואנרגיה, הכל במקום אחד.', onb2Title: 'שליטה מלאה', onb2Body: 'נהל מצלמות, חיישנים, מפסקים וגלאים מכל מקום, בכל שפה.', onb3Title: 'אוטומציות חכמות', onb3Body: 'צור סצנות, חסוך אנרגיה, וקבל התראות בזמן אמת.', onbPermTitle: 'הרשאות לגילוי מכשירים', onbPermBody: 'כדי לגלות מכשירים ברשת נדרשות הרשאות מיקום ו-Bluetooth. המידע נשאר במכשיר שלך בלבד.',
    secSection: 'אבטחה', bioLoginLabel: 'כניסה עם טביעת אצבע', bioLoginSub: 'היכנס במהירות עם ביומטריה', bioUnavailable: 'המכשיר אינו תומך בביומטריה', legalSection: 'משפטי ופרטיות', termsLabel: 'תנאי שימוש', privacyLabel: 'מדיניות פרטיות',
    sceneCreate: 'צור סצנה', sceneNew: 'סצנה חדשה', sceneName: 'שם הסצנה', sceneActions: 'פעולות', actPlugs: 'שקעים', valKeep: 'ללא שינוי', valOn: 'הדלק', valOff: 'כבה',
    authEmailHint: 'אימייל או טלפון', authPassHint: 'סיסמה', loginGreeting: 'שלום לך!', loginSubtitle: 'היכנס לחשבון שלך', loginForgot: 'שכחת סיסמה?', resetEmailHint: 'הזן את כתובת האימייל שלך ונשלח לך קישור לאיפוס סיסמה.', resetEmailSent: 'קישור לאיפוס נשלח! בדוק את תיבת הדואר שלך.', okButton: 'אישור', cancelButton: 'ביטול', sendButton: 'שלח', loginButton: 'התחבר', authOr: 'או', loginNoAccount: 'אין לך חשבון?', registerNow: 'הרשם עכשיו', continueAsGuest: 'המשך כאורח', loginWith: 'כניסה עם', appTagline: 'פתרונות בית חכם ואבטחה', registerTitle: 'יצירת חשבון', registerSubtitle: 'הצטרף לבית החכם של FantaTech', confirmPassHint: 'אימות סיסמה', registerButton: 'הרשם', haveAccount: 'כבר יש לך חשבון?', loginHousehold: 'כניסה כחבר בית',
    errEnterName: 'נא להזין שם מלא', errEnterEmail: 'נא להזין אימייל או טלפון', errPassShort: 'הסיסמה חייבת להכיל לפחות 6 תווים', errPassMismatch: 'הסיסמאות אינן תואמות',
    acMode: 'מצב', acFanSpeed: 'מהירות מאוורר', acSwing: 'סוויינג', acPreset: 'מצב מובנה', acMethod: 'שיטת בקרה', modeCool: 'קירור', modeHeat: 'חימום', modeFan: 'מאוורר', modeDry: 'ייבוש', modeAuto: 'אוטו', fanLow: 'נמוך', fanMed: 'בינוני', fanHigh: 'גבוה',
    mediaMaster: 'עוצמה כללית', mediaParty: 'נגן בכל הרמקולים', mediaStopAll: 'עצור הכל',
    tvRemote: 'שלט טלוויזיה', tvSource: 'מקור', tvChannel: 'ערוץ', tvMute: 'השתק',
    faq1Q: 'כיצד מוסיפים מכשיר?', faq1A: 'לחץ על + בלוח הראשי ובחר את המכשיר מהקטלוג.', faq2Q: 'כיצד משנים שפה?', faq2A: 'פרופיל ← הגדרות ← שפה.', faq3Q: 'האם האפליקציה עובדת ללא אינטרנט?', faq3A: 'פקודות מקומיות עובדות. ענן דורש אינטרנט.', faq4Q: 'כיצד מגדירים אוטומציה?', faq4A: 'לחץ על "אוטומציות" בתפריט התחתון ← הוסף.',
    energyTitle: 'צריכת אנרגיה', automationsTitle: 'אוטומציות', activeAutomations: 'אוטומציות פעילות',
    myProfile: 'הפרופיל שלי', myHome: 'הבית שלי', usersTitle: 'משתמשים',
    subscriptionTitle: 'מנוי וחיוב', settingsTitle: 'הגדרות', helpTitle: 'עזרה ותמיכה',
    signOut: 'יציאה מחשבון', languageLabel: 'שפה', themeLabel: 'מצב תצוגה',
    darkMode: 'כהה', lightMode: 'בהיר', appearanceTitle: 'מראה', themeFont: 'פונט', themeAccent: 'צבע ראשי', themeBg: 'רקע', themeRadius: 'עיגול', themeBgDarkBlue: 'כחול כהה', themeBgAmoled: 'שחור AMOLED', themeBgDarkGray: 'אפור כהה', themeBgLightGray: 'בהיר כחלחל', themeBgLightWhite: 'לבן נקי', themeRadiusSharp: 'חד', themeRadiusNormal: 'רגיל', themeRadiusRound: 'מעוגל', saveChanges: 'שמור שינויים',
    editProfile: 'עריכת פרופיל', fullName: 'שם מלא', emailLabel: 'אימייל',
    profileUpdated: 'הפרופיל עודכן בהצלחה', signOutConfirm: 'יציאה מחשבון', signOutQuestion: 'האם לצאת מהחשבון?', confirmSignOut: 'יציאה',
    securityTitle: 'אבטחה', armedMode: 'מצב מוגן', disarmedMode: 'לא מוגן',
    doorSensor: 'דלת כניסה', windowsSensor: 'חלונות', motionSensors: 'חיישני תנועה', smokeDetector: 'גלאי עשן', waterLeakSensor: 'גלאי נזילה',
    securedStatus: 'מאובטח', openStatus: 'פתוח', activeStatus: 'פעיל', normalStatus: 'תקין',
    panicButton: 'כפתור חירום', panicActivate: 'הפעל!', panicWarning: 'פעולה זו תשלח התראת חירום',
    welcomeGuestBtn: 'שלום אורח', welcomeGuestActive: 'מצב אורח פעיל', welcomeGuestTimer: 'נשאר {n} דקות', welcomeGuestCancel: 'בטל מצב אורח', welcomeGuestHint: 'מנטרל אבטחה לאורח · מתאזן מחדש אוטומטית',
    welcomeGuestChoose: 'בחר משך ביקור', guestOptShort: 'ביקור קצר', guestOptMedium: 'ביקור רגיל', guestOptLong: 'ביקור ממושך', guestMinutes: 'דקות',
    chooseBrand: 'בחר יצרן', pairingSteps: 'שלבי חיבור',
    allCameras: 'כל המצלמות', liveLabel: 'LIVE', offlineLabel: 'לא מחובר', deviceOn: 'פועל', deviceOff: 'כבוי', deleteAll: 'מחק הכל', deleteAllConfirm: 'להסיר את כל המכשירים מהרשימה?',
    addDeviceBtn: 'הוסף מכשיר', notificationsTitle: 'התראות',
    timeNow: 'עכשיו', timeMinAgo: 'לפני {n} דקות', timeHrAgo: 'לפני {n} שעות', timeDayAgo: 'לפני {n} ימים', deviceConnectedFmt: 'מכשיר חובר: {name}',
    camFrontDoor: 'דלת קדמית', camBackDoor: 'דלת אחורית', camGarage: 'מוסך', camBackyard: 'חצר אחורית', camEntrance: 'כניסה', camDriveway: 'שביל גישה', camBalcony: 'מרפסת',
    autoMotionNight: 'תאורת לילה בתנועה', autoArrive: 'הגעה הביתה', autoMorning: 'בוקר טוב', autoEnergySave: 'חיסכון בחשמל',
    condMotionNight: 'תנועה בלילה (21:00–06:00)', condNobodyHome: 'אם אין אף אחד בבית', condArrive: 'בכניסה לבית', condTime2300: 'בשעה 23:00', condMorningWeekday: 'בשעה 07:00 בימי חול', condNoMotion30: 'אם אין תנועה 30 דקות',
    actAllLightsOn: 'הדלקת כל האורות', actAlarmOffAll: 'הפעל אזעקה + כבה הכל', actLightsAlarmOff: 'הדלק אורות + כבה אזעקה', actOffLock: 'כבה הכל + נעל דלתות', actBlindsCoffee: 'פתח תריסים + הדלק קפה', actOffLightsAc: 'כבה אורות ומזגנים',
    catSmoke: 'עשן', catEnergy: 'אנרגיה', actionTurnOn: 'הדלק', actionTurnOff: 'כבה',
    cyberNoEvents: 'אין אירועים אחרונים', cyberNetworkMap: 'מפת רשת', cyberNetworkTopology: 'טופולוגיית רשת', cyberPhones: 'טלפונים', cyberOnlineFmt: '{on} / {total} מחוברים',
    homeTypeLabels: const ['בית','דירה','וילה','קוטג׳','קאבין','מגדל','פנטהאוס','חווה','משק','יאכטה'],
    homeColorLabels: const ['כחול','סגול','ירוק','כתום','זהב','אדום','טורקיז','ורוד','חום','אפור'],
    homeTypeTitle: 'סוג הבית', homeColorTitle: 'צבע', colorMix: 'ערבוב צבע', pickLabel: 'בחר',
    profilePhotoFmt: 'תמונת פרופיל — {name}', inviteSubject: 'הזמנה להצטרף לבית החכם שלי', inviteBodyFmt: 'שלום,\n\nאני מזמין אותך להצטרף לבית החכם שלי דרך אפליקציית FantaTech.\n\nקוד הצטרפות: {code}\n\nהורד את האפליקציה והכנס את הקוד כדי להצטרף.', noEmailApp: 'לא נמצאה אפליקציית דוא"ל במכשיר', regManagerMsg: 'נרשמת כמנהל הבית!', nameFieldFmt: 'שם: {name}', homeJoinTitle: 'קוד הצטרפות לבית', shareCodeHint: 'שתף את הקוד עם חברי הבית\nכדי שיוכלו להצטרף', gotIt: 'הבנתי', homeStyleTitle: 'סגנון הבית', registerAsFmt: 'תירשם כ: {name}', newCodeFmt: 'קוד חדש נוצר: {code}', joinCodeInline: 'קוד הצטרפות לבית:  ', inviteByEmail: 'הזמן חבר בית במייל', inviteByEmailSub: 'שלח קוד הצטרפות ישירות למייל',
    tailscaleWhat: 'מה זה Tailscale?', tailscaleDesc: 'VPN חינמי המיועד לגישה מרחוק לרשת הביתית שלך.\nמחבר את הטלפון לרשת הבית בצורה מוצפנת, גם כשאתה בחוץ.', tailscaleStep1: 'הורד Tailscale לטלפון ול-Raspberry Pi / HA Green', tailscaleStep2: 'היכנס עם אותו חשבון (Google / Apple / Email)', tailscaleStep3: 'הפעל את הטוגל — האפליקציה תפתח את Tailscale', tailscaleOpen: 'פתח / הורד Tailscale',
    camScanNetwork: 'סרוק רשת', camScanning: 'סורק...', camAddManual: 'הוסף מצלמה ידנית', camFieldName: 'שם', camPort: 'פורט', camUser: 'משתמש', camRtspPath: 'נתיב RTSP', camStreamPath: 'נתיב stream', camRtspHint: '/  או  /cam/realmonitor?channel=1', camPtzTitle: 'מצלמת PTZ', camPtzSub: 'הפעל שליטת Pan / Tilt / Zoom', camTestConn: 'בדוק חיבור', camAddBtn: 'הוסף מצלמה', camFoundFmt: '✓ נמצאה מצלמה! {info} — פורטים פתוחים: {ports}', camConnectFailFmt: '✗ לא ניתן להתחבר ל-{addr}',
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
    aiInputHint: 'הקש או דבר אליי', aiMicUnavailable: 'המיקרופון לא זמין במכשיר',
    aiSug1: 'כבה את כל האורות',
    aiSug2: 'מה מצב הבית עכשיו?',
    aiSug3: 'הפעל מצב לילה',
    aiSug4: 'האם יש התראות פעילות?',
    aiSugDesc1: 'אני יכול לכבות את כל האורות בבית',
    aiSugDesc2: 'קבל סיכום מלא של מצב הבית והמערכות',
    aiSugDesc3: 'אני מפעיל את כל ההגדרות למצב לילה',
    aiSugDesc4: 'בדוק עבור התראות ומצבים חריגים',
    aiPrivacyNote: 'המידע שלך פרטי ומאובטח', aiClearChat: 'נקה שיחה',
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
    deviceWillBeRemoved: 'המכשיר יוסר מהרשימה', haRemoveDeviceFailed: 'הוסר מהרשימה, אך לא נמחק מ-Home Assistant', ipAddressLabel: 'כתובת IP',
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
    scanBarcode: 'סרוק ברקוד / QR', editUserName: 'ערוך שם משתמש', searchScanProducts: 'סריקת מוצרים ברשת',
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
    roomNameLiving: 'סלון', roomNameKitchen: 'מטבח', roomNameBedroom: 'חדרי שינה',
    roomNameKids: 'חדר ילדים', roomNameGarden: 'גינה', roomNameBathroom: 'שירותים',
    roomNameStorage: 'מחסן', roomNameAc: 'מזגן',
    rememberMe: 'זכור אותי',
    notConnectedLabel: 'לא מחובר', solarTitle: 'מערכת סולארית', solarProduction: 'ייצור', solarConsumption: 'צריכה',
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
    assignRoom: 'שייך לחדר', noRoom: 'ללא חדר', newRoom: 'חדר חדש…',
    // Plans
    planFree: 'חינמי', planBasic: 'בסיסי',
    planAdvanced: 'מתקדם', planAdvancedPlus: 'מתקדם פלוס',
    planUnlimited: 'ללא הגבלה',
    planCurrentBadge: 'פעיל', planUpgradeNow: 'שדרג עכשיו',
    planSelected: 'נבחר', planDevicesLabel: 'מכשירים',
    planRoomsLabel: 'חדרים', planAutoLabel: 'אוטומציות',
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
    keepShabbatLabel: 'שומר חגי ישראל', shabbatSection: 'שבת',
    shabbatCandlesDesc: 'כיבוי הכל ✡️ ונעילת דלתות לפני כניסת שבת',
    shabbatHavdalahDesc: 'הפעלה חזרה של המכשירים לאחר צאת שבת',
    acConnected: 'מזגנים מחוברים', acNoUnits: 'אין מזגנים מחוברים',
    adStoreLabel: 'חנות FantaTech', adTrackTitle: 'מסלול פרסום',
    adTrackSub: 'בחר אילו מוצרים יוצגו בבאנר הדשבורד',
    adFeaturedLabel: 'מוצרים מובחרים', adFeaturedSub: 'Hub Pro, Camera 4K, Smart Bulb, חיישן',
    adNewLabel: 'חדש בחנות', adNewSub: 'תריס חכם, שקע 16A, Gateway, LED Strip',
    adAllLabel: 'כל המוצרים', adAllSub: 'רוטציה מלאה של כל הקטלוג',
    adNoneLabel: 'ללא פרסומות', adNoneSub: 'הסתר את הבאנר לחלוטין',
    autoThemeLabel: 'ערכת נושא אוטומטית', autoThemeDesc: 'מתאים ערכת נושא לפי תאורת הסביבה',
    autoThemeActive: 'פעיל', autoThemeWaiting: 'ממתין לחיישן…',
    homeLayoutLabel: 'פריסת מסך הבית',
    signOutAppTitle: 'יציאה מהאפליקציה', signOutChoose: 'בחר כיצד ברצונך לצאת',
    signOutToLogin: 'התנתק וחזור למסך הכניסה', signOutToLoginSub: 'מנתק את החשבון — כניסה מחדש תידרש',
    signOutFull: 'יציאה מלאה', signOutFullSub: 'מנתק וסוגר את האפליקציה',
    accountSection: 'חשבון',
    switchAccountTitle: 'החלפת חשבון', switchAccountSub: 'התנתקות והתחברות עם חשבון אחר',
    switchAccountConfirmTitle: 'להחליף חשבון?', switchAccountConfirmBody: 'תנותק ותועבר למסך הכניסה.',
    switchAccountConfirmBtn: 'החלף חשבון', switchAccountPasswordPrompt: 'הזן את הסיסמה שלך לאישור',
    switchAccountWrongPassword: 'סיסמה שגויה',
    installerBadge: 'מתקין', installerCodeTitle: 'מצב מתקין',
    installerCodeHint: 'הזן קוד מתקין', installerCodeWrong: 'קוד מתקין שגוי',
    installerModeOnMsg: 'מצב מתקין הופעל', installerModeOffMsg: 'מצב מתקין הופסק',
    installerExitConfirm: 'לצאת ממצב מתקין?',
    deviceOfflineHint: 'המכשיר לא מקוון — בדוק את החיבור שלו',
    aiBackendNotConfigured: 'עוזר ה-AI עוד לא הוגדר',
    aiRequestFailed: 'סליחה, לא הצלחתי להתחבר לעוזר כרגע',
    aiEmptyReply: 'בוצע.',
    aiTooManySteps: 'הבקשה הזו דורשת יותר מדי שלבים — נסה משהו פשוט יותר',
    mirrorScreenTitle: 'מראה חכמה', adBannerShop: 'לחנות',
    confirm: 'אישור', pickDay: 'יום', pickMonth: 'חודש',
    pickHebrewDate: 'בחר תאריך עברי',
    hebrewDateFmt: 'תאריך עברי: {date}',
    hebrewCalendarChip: 'תאריך עברי…',
    storeBuyAt: 'קנה ב-',
    loginBiometric: 'כניסה עם טביעת אצבע / פנים',
    errInvalidEmail: 'כתובת אימייל לא תקינה',
    loginGoogleEmailPrompt: 'הזן את כתובת ה-Gmail שלך להמשך',
    scanNetworkTitle: 'סריקת רשת',
    scanSelectDevice: 'בחר מכשיר להוספה',
    stop: 'עצור',
    scanSensorsShutters: 'חיישנים · תריסים',
    sensorHubTitle: 'חיישנים ותריסים',
    sensorHubFoundFmt: '{sensors} חיישנים · {covers} תריסים',
    sensorsTab: 'חיישנים',
    shuttersTab: 'תריסים',
    noSensorsFound: 'לא נמצאו חיישנים',
    noCoversFound: 'לא נמצאו תריסים',
    coverOpen: '▲  פתח',
    coverStop: '■  עצור',
    coverClose: '▼  סגור',
    switchScanningAll: 'סורק את כל הפרוטוקולים…',
    switchAddedFmt: '✓ {name} נוסף לבית',
    keyStoredLocal: 'המפתח נשמר רק במכשיר שלך.',
    saveAndControl: 'שמור ושלוט',
    tapoLogin: 'Tapo — כניסה',
    tapoCredHint: 'אותם פרטי חשבון שבאפליקציית TP-Link Tapo.',
    connectAndControl: 'התחבר ושלוט',
    errControlFmt: 'שגיאה בשליטה על {name}',
    switchSearchingAll: 'מחפש מפסקים חכמים בכל הפרוטוקולים…',
    switchNoFound: 'לא נמצאו מפסקים חכמים',
    switchHint: 'ודא שהמפסקים מחוברים לאותה רשת WiFi.\nShelly/ESPHome — ב-STA mode\nSonoff — ב-DIY mode (firmware 3.6+)\nHome Assistant / Zigbee2MQTT — חבר בהגדרות',
    camFrameCaptureError: 'שגיאה בלכידת הפריים',
    camNoFaces: 'לא זוהו פנים',
    camFacesFoundFmt: 'זוהו {count} פנים — {known} מזוהים 🎯',
    camFacesOnlyFmt: 'זוהו {count} פנים 🎯',
    camAnalysisErrorFmt: 'שגיאה בניתוח: {error}',
    camCaptureError: 'שגיאה בצילום',
    camSnapshotSavedFmt: '📸 נשמר: snapshot_{ts}.png',
    camSaveSnapshotError: 'שגיאה בשמירת הצילום',
    camConnectingFmt: 'מתחבר ל-{name}...',
    camIdentifyingFaces: 'מזהה פנים וזהות...',
    camDetectingFaces: 'מזהה פנים...',
    camFaceLabelFmt: 'פנים {n}',
    camStreamConnFailed: 'לא ניתן להתחבר לסטרים',
    addWizBulb: 'הוסף נורת WiZ אמיתית',
    addWizBulbSub: 'שליטה אמיתית ב-LAN · ללא ענן',
    deviceNotFoundStatus: 'לא נמצא מכשיר',
    manualAddStatus: 'הוספה ידנית',
    connecting: 'מתחבר...',
    deviceNotFoundHint: 'ודא שהמכשיר מחובר לחשמל וברשת WiFi,\nאו שה-Bluetooth פועל ומופעל.',
    manualAddLabel: 'הוסף ידנית',
    deviceNameLabel: 'שם המכשיר', deviceDeleteConfirm: 'להסיר את המכשיר הזה מהאפליקציה? תוכל להוסיף אותו שוב מאוחר יותר בסריקה חוזרת.',
    ipAddressOptional: 'כתובת IP (אופציונלי)',
    back: 'חזור',
    faceConfigured: '✓ מוגדר',
    faceIdTitle: 'זיהוי זהות',
    faceIdSubtitle: 'רשום אנשים מוכרים לזיהוי אוטומטי',
    faceTraining: 'מאמן מודל...',
    faceTrainModelFmt: 'אמן מודל זיהוי ({enrolled}/{total} רשומים)',
    facePrepGroup: 'מכין קבוצה...',
    faceTrainStartFailed: '❌ לא ניתן להתחיל אימון',
    faceTrainingProgress: 'מאמן... (עשויה לקחת עד 60 שניות)',
    faceTrainSuccess: '✅ המודל אומן בהצלחה! הזיהוי פעיל.',
    faceTrainFailed: '❌ האימון נכשל. נסה שוב.',
    faceSetAzureKeyFirst: 'הגדר API Key של Azure תחילה',
    faceAddingPhoto: 'מוסיף תמונה ל-Azure...',
    faceCreateRecordError: '❌ שגיאה ביצירת רשומה ב-Azure',
    faceFaceNotDetected: '❌ לא ניתן לזהות פנים בתמונה זו',
    facePhotoAddedFmt: '✅ תמונה נוספה ל-{name}. אמן את המודל.',
    faceNotConfiguredTap: 'לא מוגדר — לחץ להגדרה',
    faceCheckConnection: 'בדוק חיבור',
    faceGetFreeApiKey: 'קבל API Key חינם בـ portal.azure.com → Cognitive Services',
    faceSaveSettingsFirst: '⚠️ שמור את ההגדרות תחילה',
    faceAzureConnOk: '✅ חיבור ל-Azure הצליח!',
    faceAzureConnFailed: '❌ לא ניתן להתחבר. בדוק Endpoint + Key',
    faceEnrolledAzure: '✓ רשום ב-Azure',
    faceNotEnrolled: '⚠ לא רשום — הוסף תמונה',
    faceAddPerson: 'הוסף אדם',
    faceFullNameHint: 'ישראל ישראלי',
    faceEnterName: 'הכנס שם',
    faceCreatingRecord: 'יוצר רשומה...',
    faceNoPeople: 'אין אנשים רשומים',
    faceNoPeopleHint: 'הוסף אנשים כדי שהמצלמות\nיזהו אותם בשם',
    roomSettings: 'הגדרות החדר',
    capComingSoonFmt: '{cap} — בקרוב',
    householdNoAdmin: 'עדיין אין מנהל בית',
    householdMemberNote: 'כניסה כחבר בית זמינה לאחר שמנהל הבית\nנרשם עם Google או Apple.',
    backToLogin: 'חזור למסך הכניסה',
    householdAdmin: 'מנהל הבית',
    selectProfile: 'בחר פרופיל',
    noMembersYet: 'אין חברי בית עדיין',
    addMembersHint: 'מנהל הבית יכול להוסיף חברי בית\nבאזור הפרופיל ← ניהול בית.',
    switchScanProgressFmt: 'סורק... {n} / 254',
    switchNoDevicesHint: 'לא נמצאו מכשירים. ודא שהמכשירים מחוברים לאותה רשת WiFi',
    scanDoneFmt: 'סריקה הסתיימה — {n} מכשירים',
    scanWifi: 'סרוק רשת WiFi',
    faceAnalysisTitle: 'ניתוח זיהוי פנים',
    faceAnalysisSubtitle: 'היסטוריית סריקות מצלמות',
    clear: 'נקה',
    clearHistory: 'נקה היסטוריה',
    clearHistoryConfirm: 'האם למחוק את כל תוצאות הניתוח?',
    statScans: 'סריקות',
    statFacesDetected: 'פנים זוהו',
    statAlerts: 'התראות',
    faces: 'פנים',
    smiling: 'מחייך',
    eyesClosed: 'עיניים סגורות',
    noFacesInFrame: 'לא זוהו פנים בפריים זה',
    noAnalysesYet: 'אין ניתוחים עדיין',
    faceAnalysisHint: 'פתח מצלמה ולחץ על כפתור "נתח"\nכדי להפעיל זיהוי פנים',
    smartHomeTitle: 'בית חכם',
    temperatureFmt: 'טמפרטורה: {n}°C',
    brightnessFmt: 'עוצמה: {n}%',
    positionFmt: 'מיקום: {n}%',
    wizIdentifyingWifi: 'מזהה רשת WiFi…',
    wizNoWifi: 'לא מחובר ל-WiFi — הזן IP ידנית',
    wizBroadcastingFmt: 'משדר גילוי WiZ ב-{prefix}.x …',
    wizNoFound: 'לא נמצאו נורות WiZ — נסה ידנית',
    wizFoundFmt: 'נמצאו {n} נורות',
    wizScanFailed: 'הסריקה נכשלה — נסה ידנית',
    wizBlinkingFmt: 'מהבהב {ip} …',
    wizBlinkSentFmt: 'נשלחה פקודת הבהוב ל-{ip} ✓',
    wizNoResponseFmt: 'אין מענה מ-{ip} - בדוק שהנורה ברשת',
    wizDeviceAddedFmt: '{name} נוספה — שליטה אמיתית פעילה',
    wizManualAdd: 'הוספה ידנית לפי כתובת IP',
    wizTest: 'בדיקה',
    gatewayHubTitle: 'גשרים ומרכזי בקרה',
    gatewayHubSubtitle: 'חבר רכזות Zigbee, Z-Wave, WiFi וענן',
    connected: 'מחובר',
    addGateway: 'הוסף גשר',
    gatewayTypesFmt: '{n} סוגים',
    devicesImportedFmt: 'נוספו {n} מכשירים מ-{name}',
    allDevicesExist: 'כל המכשירים כבר קיימים',
    diagnosisTitle: 'מכשירים שהרכזת מדווחת',
    disconnectConfirmFmt: 'נתק "{name}"?',
    importedDevicesNote: 'המכשירים שיובאו יישארו, אך לא ניתן יהיה לייבא עוד.',
    disconnect: 'נתק',
    deviceCountFmt: '{n} מכשירים',
    importDevices: 'ייבא מכשירים',
    connect: 'חבר',
    connectAfterButton: 'חבר (לאחר לחיצת כפתור)',
    connectedSuccess: 'מחובר בהצלחה!',
    secondsRemainingFmt: '{n} שניות נותרו',
    cloud: 'ענן',
    cloudConnectionNote: 'חיבור ענן — הנתונים עוברים דרך שרתי היצרן',
    setupStepsHintFmt: 'איך משיגים את הפרטים? ({n} צעדים)',
    tokenPortalFmt: 'Token נוצר בפורטל {name}',
    optional: 'אופציונלי',
    z2mEnterIp: 'הכנס כתובת IP של ה-Zigbee2MQTT',
    z2mUnreachableFmt: 'לא ניתן להגיע ל-Zigbee2MQTT ב-{ip}:{port}\nוודא שה-frontend מופעל וה-IP נכון',
    z2mUnknownError: 'שגיאה לא ידועה',
    z2mSubtitle: 'חיבור לגייטוויי Zigbee — ייבוא מכשירים אוטומטי',
    z2mIpLabel: 'כתובת IP של Z2M',
    z2mIpHint: 'למשל: 192.168.1.50',
    z2mPortLabel: 'פורט',
    z2mTokenLabel: 'API Token (אופציונלי)',
    z2mTokenHint: 'אם מוגדר',
    z2mFoundFmt: 'נמצאו {n} מכשירי Zigbee!',
    z2mConnectImport: 'התחבר וייבא מכשירים',
    z2mFrontendHelp: 'הפעל frontend ב-Z2M config:\n  frontend:\n    port: 8080',
    discoveryTitle: 'חיפוש מכשירים',
    scan: 'סרוק',
    matterDeviceTitle: 'מכשיר Matter',
    matterDeviceHelp: 'מכשירי Matter (כמו מנורת IKEA) מצורפים דרך רכזת Matter — לא ישירות מהאפליקציה.\n\nהדרך הפשוטה:\n1. צרף את המנורה ל-DIRIGERA דרך אפליקציית IKEA Home smart.\n2. כאן: גשרים → DIRIGERA → "ייבא מכשירים".\nהמנורה תופיע עם שליטה מלאה.',
    understood: 'הבנתי',
    devicesAddedFmt: 'נוספו {n} מכשירים',
    haFound: 'Home Assistant נמצא',
    haConnectedFmt: 'מחובר — {n} מכשירים יובאו',
    haConnect: 'חבר',
    haReconnectSync: 'התחבר מחדש וסנכרן',
    haTokenHint: 'צור Token ב: Profile → Long-Lived Access Tokens',
    importFromHa: 'ייבא מכשירים מ-Home Assistant',
    scanningDevices: 'מחפש מכשירים…',
    scanHint: 'לחץ "סרוק" כדי לחפש מכשירים ברשת',
    addAllFmt: 'הוסף הכל ({n} מכשירים)',
    matterCommTitle: 'חיבור מכשיר Matter',
    matterCommSubtitle: 'סרוק את קוד ה-QR על המדבקה של המכשיר',
    matterCommScanBtn: 'סרוק QR',
    matterCommManualBtn: 'הזן קוד ידנית',
    matterCommManualHint: 'קוד 11 ספרות (למשל 12345-67890)',
    matterCommissioning: 'מחבר דרך Home Assistant…',
    matterCommSuccess: 'המכשיר חובר בהצלחה!',
    matterCommFailed: 'החיבור נכשל. בדוק שהאינטגרציה של Matter פעילה ב-HA.',
    matterCommNoHa: 'Home Assistant לא מחובר. חבר HA קודם.',
    matterCommRetry: 'נסה שוב',
    matterCommCodeHint: 'MT:… או קוד 11 ספרות',
    blindsHubTitle: 'תריסים וכיסויים',
    openAll: 'פתח הכל',
    closeAll: 'סגור הכל',
    noBlindsFound: 'לא נמצאו תריסים',
    blindsHint: 'הוסף תריסים דרך Home Assistant',
    smartLocksTitle: 'נעילות חכמות',
    lockedStatus: 'נעול',
    unlockedStatus: 'פתוח',
    lockAll: 'נעל הכל',
    unlockAll: 'פתח הכל',
    noLocksFound: 'לא נמצאו נעילות',
    lockHint: 'הוסף נעילה חכמה דרך Home Assistant',
    lightsHubTitle: 'אורות',
    lightsAllOn: 'הדלק הכל',
    lightsAllOff: 'כבה הכל',
    noLightsFound: 'לא נמצאו אורות',
    lightsHint: 'הוסף אורות דרך Home Assistant',
    plugsHubTitle: 'שקעים חכמים',
    plugsAllOn: 'הדלק הכל',
    plugsAllOff: 'כבה הכל',
    noPlugsFound: 'לא נמצאו שקעים',
    plugsHint: 'הוסף שקעים דרך סריקת WiFi',
    acHubTitle: 'מיזוג אוויר',
    intercomTitle: 'אינטרקום', intercomNoDevices: 'לא נמצאו מכשירי אינטרקום',
    intercomHint: 'הוסף אינטרקום דרך הקטלוג או ייבוא גשר',
    intercomRing: 'צלצל', intercomAnswer: 'ענה', intercomDecline: 'דחה',
    intercomCategory: 'פעמון וידאו', intercomRinging: 'מישהו בדלת…',
    vacuumCategory: 'רובוט שואב', vacuumNoDevices: 'לא נמצאו רובוטים שואבים',
    vacuumHint: 'חבר את הרובוט השואב דרך Home Assistant כדי לראות אותו כאן',
    vacuumStart: 'התחל', vacuumPause: 'השהה', vacuumDock: 'חזור לתחנה',
    vacuumCleaning: 'מנקה', vacuumDocked: 'בתחנה',
    intercomUnlockDoor: 'פתח דלת',
    energyRateLabel: 'תעריף חשמל', energyRateEdit: 'ערוך תעריף',
    energyRateUnit: '₪/קוט"ש', energyRateSaved: 'תעריף נשמר',
    backupTitle: 'גיבוי ושחזור', backupExport: 'ייצוא הגדרות',
    backupImport: 'ייבוא הגדרות', backupExportDone: 'ההגדרות יוצאו להורדות',
    backupImportDone: 'ההגדרות שוחזרו בהצלחה', backupImportError: 'ייבוא נכשל — קובץ לא תקין',
    backupSection: 'נתונים וגיבוי',
    biometricSplashLabel: 'אמת זהות',
    camLocationPermission: 'נדרשת הרשאת מיקום לסריקת הרשת',
    camNoWifiIp: 'לא הצלחנו לזהות את רשת ה-WiFi שלך — התחבר ל-WiFi ונסה שוב, או הוסף את המצלמה ידנית',
    camScanNoneFound: 'לא נמצאו מצלמות ברשת. אם המצלמה שלך לא תומכת ב-ONVIF, הוסף אותה ידנית לפי כתובת ה-IP שלה.',
    showHideSections: 'הצג / הסתר אזורים', restoreDefaults: 'שחזור ברירת מחדל?', restoreDefaultsConfirm: 'פעולה זו תאפס את סידור לוח האבטחה. לא ניתן לבטל.', restore: 'שחזר', systemTest: 'בדיקת מערכת',
  );

  // ── English ───────────────────────────────────────────────────
  static const S _en = S(
    navHome: 'Home', navCameras: 'Cameras', navSecurity: 'Security', navProfile: 'Profile', navAutomations: 'Automations',
    greetingPrefix: 'Hello', homeSecured: 'Your home is secured', homeNotSecured: 'Home is not secured',
    allSystemsActive: 'All systems active', tapToActivate: 'Tap to activate security',
    alarmTitle: 'Alarm', alarmSecured: 'Secured', alarmOff: 'Off', roomManagement: 'Home Management', roomsUnit: 'rooms',
    camerasTitle: 'Cameras', lightsOn: 'lights on', lightingTitle: 'Lighting',
    tempTitle: 'Temperature', tempComfy: 'Comfortable', aiSubtitle: 'How can I help you?', aiTopSubtitle: 'Your smart home\'s helper',
    quickActions: 'Quick Actions', leaveHome: 'Leave Home', turnOffAll: 'Turn Off All', goodNight: 'Good Night', movieMode: 'Movie Mode',
    mediaTitle: 'Media', mediaSpeakers: 'Speakers', mediaScan: 'Scan devices', mediaNoDevices: 'No speakers found. Tap scan.',
    bioTitle: 'Quick Sign-In', bioPrompt: 'Enable fingerprint login for next time?', bioEnable: 'Enable', bioSkip: 'Not now', bioReason: 'Authenticate to sign in',
    onbNext: 'Next', onbStart: 'Get Started', onbSkip: 'Skip', onbAllow: 'Allow', onbLater: 'Later', onb1Title: 'Welcome to FantaTech', onb1Body: 'Your smart home — lighting, security, climate and energy, all in one place.', onb2Title: 'Full Control', onb2Body: 'Manage cameras, sensors, switches and detectors from anywhere, in any language.', onb3Title: 'Smart Automations', onb3Body: 'Create scenes, save energy, and get real-time alerts.', onbPermTitle: 'Permissions for Device Discovery', onbPermBody: 'To find devices on your network we need Location and Bluetooth access. Your data stays on your device only.',
    secSection: 'Security', bioLoginLabel: 'Fingerprint Login', bioLoginSub: 'Sign in quickly with biometrics', bioUnavailable: 'Biometrics not supported on this device', legalSection: 'Legal & Privacy', termsLabel: 'Terms of Service', privacyLabel: 'Privacy Policy',
    sceneCreate: 'Create Scene', sceneNew: 'New Scene', sceneName: 'Scene name', sceneActions: 'Actions', actPlugs: 'Plugs', valKeep: 'No change', valOn: 'On', valOff: 'Off',
    authEmailHint: 'Email or phone', authPassHint: 'Password', loginGreeting: 'Hello!', loginSubtitle: 'Sign in to your account', loginForgot: 'Forgot password?', resetEmailHint: 'Enter your email and we\'ll send you a reset link.', resetEmailSent: 'Reset link sent! Check your inbox.', okButton: 'OK', cancelButton: 'Cancel', sendButton: 'Send', loginButton: 'Sign In', authOr: 'or', loginNoAccount: "Don't have an account?", registerNow: 'Register now', continueAsGuest: 'Continue as Guest', loginWith: 'Sign in with', appTagline: 'Smart Home & Security Solutions', registerTitle: 'Create Account', registerSubtitle: 'Join the FantaTech smart home', confirmPassHint: 'Confirm password', registerButton: 'Register', haveAccount: 'Already have an account?', loginHousehold: 'Household Member',
    errEnterName: 'Please enter your full name', errEnterEmail: 'Please enter email or phone', errPassShort: 'Password must be at least 6 characters', errPassMismatch: 'Passwords do not match',
    acMode: 'Mode', acFanSpeed: 'Fan Speed', acSwing: 'Swing', acPreset: 'Preset', acMethod: 'Control', modeCool: 'Cool', modeHeat: 'Heat', modeFan: 'Fan', modeDry: 'Dry', modeAuto: 'Auto', fanLow: 'Low', fanMed: 'Med', fanHigh: 'High',
    mediaMaster: 'Master Volume', mediaParty: 'Play on all', mediaStopAll: 'Stop all',
    tvRemote: 'TV Remote', tvSource: 'Source', tvChannel: 'Channel', tvMute: 'Mute',
    faq1Q: 'How to add a device?', faq1A: 'Tap + on the dashboard and pick the device from the catalog.', faq2Q: 'How to change language?', faq2A: 'Profile → Settings → Language.', faq3Q: 'Does the app work offline?', faq3A: 'Local commands work. Cloud requires internet.', faq4Q: 'How to set an automation?', faq4A: 'Tap "Automations" in the bottom menu → Add.',
    energyTitle: 'Energy Usage', automationsTitle: 'Automations', activeAutomations: 'active automations',
    myProfile: 'My Profile', myHome: 'My Home', usersTitle: 'Users',
    subscriptionTitle: 'Subscription', settingsTitle: 'Settings', helpTitle: 'Help & Support',
    signOut: 'Sign Out', languageLabel: 'Language', themeLabel: 'Theme',
    darkMode: 'Dark', lightMode: 'Light', appearanceTitle: 'Appearance', themeFont: 'Font', themeAccent: 'Accent Color', themeBg: 'Background', themeRadius: 'Roundness', themeBgDarkBlue: 'Dark Blue', themeBgAmoled: 'AMOLED Black', themeBgDarkGray: 'Dark Gray', themeBgLightGray: 'Light Blue', themeBgLightWhite: 'Clean White', themeRadiusSharp: 'Sharp', themeRadiusNormal: 'Normal', themeRadiusRound: 'Round', saveChanges: 'Save Changes',
    editProfile: 'Edit Profile', fullName: 'Full Name', emailLabel: 'Email',
    profileUpdated: 'Profile updated successfully', signOutConfirm: 'Sign Out', signOutQuestion: 'Are you sure you want to sign out?', confirmSignOut: 'Sign Out',
    securityTitle: 'Security', armedMode: 'Armed', disarmedMode: 'Disarmed',
    doorSensor: 'Front Door', windowsSensor: 'Windows', motionSensors: 'Motion Sensors', smokeDetector: 'Smoke Detector', waterLeakSensor: 'Water Leak Sensor',
    securedStatus: 'Secured', openStatus: 'Open', activeStatus: 'Active', normalStatus: 'Normal',
    panicButton: 'Panic Button', panicActivate: 'Activate!', panicWarning: 'This will send an emergency alert',
    welcomeGuestBtn: 'Welcome Guest', welcomeGuestActive: 'Guest Mode Active', welcomeGuestTimer: '{n} min remaining', welcomeGuestCancel: 'Cancel Guest Mode', welcomeGuestHint: 'Disarms security for a guest · auto re-arms',
    welcomeGuestChoose: 'Choose Visit Duration', guestOptShort: 'Short Visit', guestOptMedium: 'Standard Visit', guestOptLong: 'Extended Visit', guestMinutes: 'min',
    chooseBrand: 'Choose Brand', pairingSteps: 'Pairing Steps',
    allCameras: 'All Cameras', liveLabel: 'LIVE', offlineLabel: 'Offline', deviceOn: 'On', deviceOff: 'Off', deleteAll: 'Delete all', deleteAllConfirm: 'Remove all devices from the list?',
    addDeviceBtn: 'Add Device', notificationsTitle: 'Notifications',
    timeNow: 'now', timeMinAgo: '{n} min ago', timeHrAgo: '{n} h ago', timeDayAgo: '{n} d ago', deviceConnectedFmt: 'Device connected: {name}',
    camFrontDoor: 'Front Door', camBackDoor: 'Back Door', camGarage: 'Garage', camBackyard: 'Backyard', camEntrance: 'Entrance', camDriveway: 'Driveway', camBalcony: 'Balcony',
    autoMotionNight: 'Motion Night Lights', autoArrive: 'Arriving Home', autoMorning: 'Good Morning', autoEnergySave: 'Energy Saving',
    condMotionNight: 'Motion at night (21:00–06:00)', condNobodyHome: 'If nobody is home', condArrive: 'On arriving home', condTime2300: 'At 23:00', condMorningWeekday: 'At 07:00 on weekdays', condNoMotion30: 'If no motion for 30 min',
    actAllLightsOn: 'Turn on all lights', actAlarmOffAll: 'Arm alarm + turn off all', actLightsAlarmOff: 'Lights on + disarm', actOffLock: 'Turn off all + lock doors', actBlindsCoffee: 'Open blinds + start coffee', actOffLightsAc: 'Turn off lights & AC',
    catSmoke: 'Smoke', catEnergy: 'Energy', actionTurnOn: 'Turn On', actionTurnOff: 'Turn Off',
    cyberNoEvents: 'No recent events', cyberNetworkMap: 'Network Map', cyberNetworkTopology: 'Network Topology', cyberPhones: 'Phones', cyberOnlineFmt: '{on} / {total} online',
    homeTypeLabels: const ['House','Apartment','Villa','Cottage','Cabin','Tower','Penthouse','Farm','Ranch','Yacht'],
    homeColorLabels: const ['Blue','Purple','Green','Orange','Gold','Red','Turquoise','Pink','Brown','Gray'],
    homeTypeTitle: 'Home Type', homeColorTitle: 'Color', colorMix: 'Color Mix', pickLabel: 'Pick',
    profilePhotoFmt: 'Profile photo — {name}', inviteSubject: 'Invitation to join my smart home', inviteBodyFmt: 'Hello,\n\nI invite you to join my smart home via the FantaTech app.\n\nJoin code: {code}\n\nDownload the app and enter the code to join.', noEmailApp: 'No email app found on the device', regManagerMsg: 'Registered as Home Manager!', nameFieldFmt: 'Name: {name}', homeJoinTitle: 'Home Join Code', shareCodeHint: 'Share the code with household members\nso they can join', gotIt: 'Got it', homeStyleTitle: 'Home Style', registerAsFmt: 'Register as: {name}', newCodeFmt: 'New code generated: {code}', joinCodeInline: 'Home join code:  ', inviteByEmail: 'Invite member by email', inviteByEmailSub: 'Send the join code directly by email',
    tailscaleWhat: 'What is Tailscale?', tailscaleDesc: 'A free VPN for remote access to your home network.\nConnects your phone to the home network securely, even when you are away.', tailscaleStep1: 'Install Tailscale on your phone and Raspberry Pi / HA Green', tailscaleStep2: 'Sign in with the same account (Google / Apple / Email)', tailscaleStep3: 'Enable the toggle — the app will open Tailscale', tailscaleOpen: 'Open / Install Tailscale',
    camScanNetwork: 'Scan Network', camScanning: 'Scanning...', camAddManual: 'Add camera manually', camFieldName: 'Name', camPort: 'Port', camUser: 'User', camRtspPath: 'RTSP path', camStreamPath: 'Stream path', camRtspHint: '/  or  /cam/realmonitor?channel=1', camPtzTitle: 'PTZ Camera', camPtzSub: 'Enable Pan / Tilt / Zoom control', camTestConn: 'Test connection', camAddBtn: 'Add camera', camFoundFmt: '✓ Camera found! {info} — open ports: {ports}', camConnectFailFmt: '✗ Cannot connect to {addr}',
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
    aiInputHint: 'Type or speak to me', aiMicUnavailable: 'Microphone not available',
    aiSug1: 'Turn off all lights',
    aiSug2: "What's the home status?",
    aiSug3: 'Activate night mode',
    aiSug4: 'Are there active alerts?',
    aiSugDesc1: 'I can turn off all the lights in the house',
    aiSugDesc2: 'Get a full summary of the home and its systems',
    aiSugDesc3: 'I\'ll turn on all the night mode settings',
    aiSugDesc4: 'Check for alerts and unusual conditions',
    aiPrivacyNote: 'Your information is private and protected', aiClearChat: 'Clear conversation',
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
    deviceWillBeRemoved: 'The device will be removed from the list', haRemoveDeviceFailed: 'Removed from the list, but could not be deleted from Home Assistant', ipAddressLabel: 'IP Address',
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
    scanBarcode: 'Scan Barcode / QR', editUserName: 'Edit user name', searchScanProducts: 'Scan network for products',
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
    qaNoDevices: 'No devices connected', qaNoAlerts: 'No alerts', qaResetAll: 'Reset All', qaScanDevice: 'Scan for Device',
    adAddLink: 'Add Link', adCustomLink: 'Custom Link',
    panicLabel: 'PANIC', emergencyActivated: '🚨 Emergency mode activated! Authorities have been notified.',
    helpFaq: 'FAQ', helpContact: 'Contact Us',
    helpRegisterTitle: 'Register for Support', helpNameHint: 'Full Name', helpEmailHint: 'Email Address',
    helpMsgHint: 'Message (optional)', helpSendBtn: 'Send', helpSentSuccess: 'Details saved! We will get back to you soon.',
    visitWebsite: 'Visit Website',
    addRoom: 'Add Room', editRoom: 'Edit Room', deleteRoom: 'Delete Room',
    roomNameHint: 'Room name', roomAdded: 'Room added', roomDeleted: 'Room deleted', roomEdited: 'Room updated',
    roomIconLabel: 'Icon',
    roomNameLiving: 'Living Room', roomNameKitchen: 'Kitchen', roomNameBedroom: 'Bedroom',
    roomNameKids: 'Kids Room', roomNameGarden: 'Garden', roomNameBathroom: 'Bathroom',
    roomNameStorage: 'Storage', roomNameAc: 'AC',
    rememberMe: 'Remember me',
    notConnectedLabel: 'Not connected', solarTitle: 'Solar System', solarProduction: 'Production', solarConsumption: 'Consumption',
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
    assignRoom: 'Assign Room', noRoom: 'No room', newRoom: 'New room…',
    planFree: 'Free', planBasic: 'Basic',
    planAdvanced: 'Advanced', planAdvancedPlus: 'Advanced Plus',
    planUnlimited: 'Unlimited',
    planCurrentBadge: 'Active', planUpgradeNow: 'Upgrade Now',
    planSelected: 'Selected', planDevicesLabel: 'Devices',
    planRoomsLabel: 'Rooms', planAutoLabel: 'Automations',
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
    keepShabbatLabel: 'Keep Shabbat', shabbatSection: 'Shabbat',
    shabbatCandlesDesc: 'Turn everything off ✡️ and lock doors before Shabbat',
    shabbatHavdalahDesc: 'Restore devices after Shabbat ends',
    acConnected: 'AC units connected', acNoUnits: 'No AC connected',
    adStoreLabel: 'FantaTech Store', adTrackTitle: 'Ad Settings',
    adTrackSub: 'Choose which products appear in the dashboard banner',
    adFeaturedLabel: 'Featured Products', adFeaturedSub: 'Hub Pro, Camera 4K, Smart Bulb, Sensor',
    adNewLabel: 'New in Store', adNewSub: 'Smart Blind, Smart Plug 16A, Gateway, LED Strip',
    adAllLabel: 'All Products', adAllSub: 'Full rotation of all catalog',
    adNoneLabel: 'No Ads', adNoneSub: 'Hide the banner completely',
    autoThemeLabel: 'Auto Theme', autoThemeDesc: 'Adapts theme to ambient light',
    autoThemeActive: 'Active', autoThemeWaiting: 'Waiting for sensor…',
    homeLayoutLabel: 'Home Layout',
    signOutAppTitle: 'Exit App', signOutChoose: 'Choose how to exit',
    signOutToLogin: 'Sign out & return to login', signOutToLoginSub: 'Disconnects account — login required',
    signOutFull: 'Full Exit', signOutFullSub: 'Signs out & closes the app',
    accountSection: 'Account',
    switchAccountTitle: 'Switch Account', switchAccountSub: 'Sign out and sign in with a different account',
    switchAccountConfirmTitle: 'Switch account?', switchAccountConfirmBody: "You'll be signed out and returned to the login screen.",
    switchAccountConfirmBtn: 'Switch Account', switchAccountPasswordPrompt: 'Enter your password to confirm',
    switchAccountWrongPassword: 'Incorrect password',
    installerBadge: 'INSTALLER', installerCodeTitle: 'Installer Mode',
    installerCodeHint: 'Enter installer code', installerCodeWrong: 'Incorrect installer code',
    installerModeOnMsg: 'Installer Mode activated', installerModeOffMsg: 'Installer Mode exited',
    installerExitConfirm: 'Exit Installer Mode?',
    deviceOfflineHint: 'Device offline — check its connection',
    aiBackendNotConfigured: 'AI assistant is not set up yet',
    aiRequestFailed: "Sorry, I couldn't reach the assistant right now",
    aiEmptyReply: 'Done.',
    aiTooManySteps: 'That request needs too many steps — try something simpler',
    mirrorScreenTitle: 'Smart Mirror', adBannerShop: 'Shop',
    gatewaysTitle: 'Gateways', statusOffline: 'Offline',
    biometricSplashLabel: 'Authenticate',
    camLocationPermission: 'Location permission required to scan the network',
    camNoWifiIp: "Couldn't detect your WiFi network — connect to WiFi and try again, or add the camera manually",
    camScanNoneFound: "No cameras found on the network. If yours isn't ONVIF-compatible, add it manually with its IP address instead.",
    showHideSections: 'Show / Hide Sections', restoreDefaults: 'Restore Defaults?', restoreDefaultsConfirm: 'This will reset the security panel layout. Cannot be undone.', restore: 'Restore', systemTest: 'System Test',
  );

  // ── Arabic ────────────────────────────────────────────────────
  static const S _ar = S(
    homeGreetingSub: 'منزلك، آمن وذكي.', energyToday: 'استهلاك الطاقة اليوم', vsYesterday: 'عن الأمس',
    climateEnergyTitle: 'المناخ والطاقة', homeManagementTitle: 'إدارة المنزل',
    energyAnalytics: 'تحليل الطاقة',
    securitySystemLabel: 'نظام الأمان', secArmedShort: 'مُفعّل', secDisarmedShort: 'مُعطّل', allOkLabel: 'كل شيء على ما يرام', emergencyBtn: 'الطوارئ',
    showAll: 'عرض الكل', roomsHeader: 'الغرف', statHomesLabel: 'المنازل', devicesUnit: 'أجهزة',
    qaLock: 'قفل', qaLights: 'الأضواء', qaAc: 'المكيّف', qaCameras: 'الكاميرات', qaAlerts: 'التنبيهات',
    qaPlugs: 'مقابس', qaWaterHeater: 'سخان', qaBreakers: 'لوحة',
    qaNoDevices: 'لا توجد أجهزة', qaNoAlerts: 'لا توجد تنبيهات', qaResetAll: 'إعادة تعيين', qaScanDevice: 'بحث عن جهاز',
    adAddLink: 'أضف رابط', adCustomLink: 'رابط مخصص',
    systemStatus: 'حالة النظام', statusInternet: 'الإنترنت', statusSensors: 'المستشعرات', connectedLabel: 'متصل',
    camMotion: 'حركة مكتشفة', camOnline: 'متصل', camOffline: 'غير متصل', locationUnavailable: 'الموقع غير متاح', gatewaysManage: 'إدارة', gatewaysTitle: 'بوابات', statusOffline: 'غير متصل',
    secArmStayBtn: 'تفعيل (بالمنزل)', secDisarmBtn: 'تعطيل', roomNameMedia: 'وسائط', mediaRoomTitle: 'وسائط',
    roomOccupantLabel: 'من يستخدم هذه الغرفة؟', occupantNone: 'لا أحد', occupantKids: 'أطفال', occupantAdults: 'بالغون',
    navHome: 'الرئيسية', navCameras: 'كاميرات', navSecurity: 'أمان', navProfile: 'الملف', navAutomations: 'أتمتة',
    greetingPrefix: 'مرحباً', homeSecured: 'منزلك محمي', homeNotSecured: 'المنزل غير محمي',
    allSystemsActive: 'جميع الأنظمة نشطة', tapToActivate: 'اضغط لتفعيل الأمان',
    alarmTitle: 'إنذار', alarmSecured: 'محمي', alarmOff: 'معطل', roomManagement: 'إدارة المنزل', roomsUnit: 'غرف',
    camerasTitle: 'كاميرات', lightsOn: 'أضواء مضاءة', lightingTitle: 'إضاءة',
    tempTitle: 'الحرارة', tempComfy: 'مريح', aiSubtitle: 'كيف يمكنني مساعدتك؟', aiTopSubtitle: 'مساعد منزلك الذكي',
    quickActions: 'إجراءات سريعة', leaveHome: 'مغادرة المنزل', turnOffAll: 'إيقاف الكل', goodNight: 'تصبح على خير', movieMode: 'وضع الفيلم',
    mediaTitle: 'الوسائط', mediaSpeakers: 'مكبرات الصوت', mediaScan: 'مسح الأجهزة', mediaNoDevices: 'لا توجد مكبرات. اضغط مسح.',
    bioTitle: 'دخول سريع', bioPrompt: 'تفعيل الدخول ببصمة الإصبع في المرة القادمة؟', bioEnable: 'تفعيل', bioSkip: 'ليس الآن', bioReason: 'وثّق هويتك لتسجيل الدخول',
    onbNext: 'التالي', onbStart: 'لنبدأ', onbSkip: 'تخطٍ', onbAllow: 'السماح', onbLater: 'لاحقاً', onb1Title: 'مرحباً بك في FantaTech', onb1Body: 'منزلك الذكي — الإضاءة والأمان والمناخ والطاقة في مكان واحد.', onb2Title: 'تحكم كامل', onb2Body: 'أدر الكاميرات والحساسات والمفاتيح والكواشف من أي مكان وبأي لغة.', onb3Title: 'أتمتة ذكية', onb3Body: 'أنشئ مشاهد ووفّر الطاقة واحصل على تنبيهات فورية.', onbPermTitle: 'أذونات اكتشاف الأجهزة', onbPermBody: 'لاكتشاف الأجهزة على شبكتك نحتاج إلى إذن الموقع والبلوتوث. تبقى بياناتك على جهازك فقط.',
    secSection: 'الأمان', bioLoginLabel: 'الدخول ببصمة الإصبع', bioLoginSub: 'سجّل الدخول بسرعة بالبصمة', bioUnavailable: 'الجهاز لا يدعم البيومترية', legalSection: 'القانونية والخصوصية', termsLabel: 'شروط الخدمة', privacyLabel: 'سياسة الخصوصية',
    sceneCreate: 'إنشاء مشهد', sceneNew: 'مشهد جديد', sceneName: 'اسم المشهد', sceneActions: 'الإجراءات', actPlugs: 'المقابس', valKeep: 'بدون تغيير', valOn: 'تشغيل', valOff: 'إيقاف',
    authEmailHint: 'البريد أو الهاتف', authPassHint: 'كلمة المرور', loginGreeting: 'مرحباً!', loginSubtitle: 'سجّل الدخول إلى حسابك', loginForgot: 'نسيت كلمة المرور؟', resetEmailHint: 'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين.', resetEmailSent: 'تم إرسال الرابط! تحقق من بريدك الإلكتروني.', okButton: 'موافق', cancelButton: 'إلغاء', sendButton: 'إرسال', loginButton: 'تسجيل الدخول', authOr: 'أو', loginNoAccount: 'ليس لديك حساب؟', registerNow: 'سجّل الآن', continueAsGuest: 'المتابعة كضيف', loginWith: 'تسجيل الدخول باستخدام', appTagline: 'حلول المنزل الذكي والأمن', registerTitle: 'إنشاء حساب', registerSubtitle: 'انضم إلى منزل FantaTech الذكي', confirmPassHint: 'تأكيد كلمة المرور', registerButton: 'تسجيل', haveAccount: 'لديك حساب بالفعل؟', loginHousehold: 'فرد من المنزل',
    errEnterName: 'يرجى إدخال الاسم الكامل', errEnterEmail: 'يرجى إدخال البريد أو الهاتف', errPassShort: 'يجب أن تكون كلمة المرور 6 أحرف على الأقل', errPassMismatch: 'كلمتا المرور غير متطابقتين',
    acMode: 'الوضع', acFanSpeed: 'سرعة المروحة', acSwing: 'تأرجح', acPreset: 'وضع مسبق', acMethod: 'التحكم', modeCool: 'تبريد', modeHeat: 'تدفئة', modeFan: 'مروحة', modeDry: 'تجفيف', modeAuto: 'تلقائي', fanLow: 'منخفض', fanMed: 'متوسط', fanHigh: 'مرتفع',
    mediaMaster: 'مستوى الصوت العام', mediaParty: 'تشغيل على الكل', mediaStopAll: 'إيقاف الكل',
    tvRemote: 'جهاز التحكم', tvSource: 'المصدر', tvChannel: 'القناة', tvMute: 'كتم',
    faq1Q: 'كيف أضيف جهازاً؟', faq1A: 'اضغط + في اللوحة الرئيسية واختر الجهاز من الكتالوج.', faq2Q: 'كيف أغيّر اللغة؟', faq2A: 'الملف الشخصي ← الإعدادات ← اللغة.', faq3Q: 'هل يعمل التطبيق دون إنترنت؟', faq3A: 'الأوامر المحلية تعمل. السحابة تتطلب إنترنت.', faq4Q: 'كيف أعدّ الأتمتة؟', faq4A: 'اضغط "الأتمتة" في القائمة السفلية ← إضافة.',
    energyTitle: 'استهلاك الطاقة', automationsTitle: 'الأتمتة', activeAutomations: 'أتمتة نشطة',
    myProfile: 'ملفي الشخصي', myHome: 'منزلي', usersTitle: 'المستخدمون',
    subscriptionTitle: 'الاشتراك', settingsTitle: 'الإعدادات', helpTitle: 'المساعدة',
    signOut: 'تسجيل خروج', languageLabel: 'اللغة', themeLabel: 'المظهر',
    darkMode: 'داكن', lightMode: 'فاتح', appearanceTitle: 'المظهر', themeFont: 'الخط', themeAccent: 'اللون الرئيسي', themeBg: 'الخلفية', themeRadius: 'الحواف', themeBgDarkBlue: 'أزرق داكن', themeBgAmoled: 'أسود AMOLED', themeBgDarkGray: 'رمادي داكن', themeBgLightGray: 'فاتح مزرق', themeBgLightWhite: 'أبيض نقي', themeRadiusSharp: 'حاد', themeRadiusNormal: 'عادي', themeRadiusRound: 'مدوّر', saveChanges: 'حفظ التغييرات',
    editProfile: 'تعديل الملف', fullName: 'الاسم الكامل', emailLabel: 'البريد الإلكتروني',
    profileUpdated: 'تم تحديث الملف بنجاح', signOutConfirm: 'تسجيل خروج', signOutQuestion: 'هل تريد تسجيل الخروج؟', confirmSignOut: 'خروج',
    securityTitle: 'الأمان', armedMode: 'مفعّل', disarmedMode: 'معطل',
    doorSensor: 'باب الدخول', windowsSensor: 'النوافذ', motionSensors: 'كاشف الحركة', smokeDetector: 'كاشف الدخان', waterLeakSensor: 'كاشف تسرب الماء',
    securedStatus: 'مؤمّن', openStatus: 'مفتوح', activeStatus: 'نشط', normalStatus: 'طبيعي',
    panicButton: 'زر الطوارئ', panicActivate: 'تفعيل!', panicWarning: 'سيتم إرسال تنبيه طوارئ',
    welcomeGuestBtn: 'مرحباً بالضيف', welcomeGuestActive: 'وضع الضيف نشط', welcomeGuestTimer: 'دقيقة {n} متبقية', welcomeGuestCancel: 'إلغاء وضع الضيف', welcomeGuestHint: 'يوقف الأمان للضيف · يُعاد تلقائياً',
    welcomeGuestChoose: 'اختر مدة الزيارة', guestOptShort: 'زيارة قصيرة', guestOptMedium: 'زيارة عادية', guestOptLong: 'زيارة طويلة', guestMinutes: 'دقيقة',
    chooseBrand: 'اختر العلامة التجارية', pairingSteps: 'خطوات الإقران',
    allCameras: 'كل الكاميرات', liveLabel: 'مباشر', offlineLabel: 'غير متصل', deviceOn: 'تشغيل', deviceOff: 'إيقاف', deleteAll: 'حذف الكل', deleteAllConfirm: 'هل تريد إزالة جميع الأجهزة؟',
    addDeviceBtn: 'إضافة جهاز', notificationsTitle: 'الإشعارات',
    timeNow: 'الآن', timeMinAgo: 'قبل {n} دقيقة', timeHrAgo: 'قبل {n} ساعة', timeDayAgo: 'قبل {n} يوم', deviceConnectedFmt: 'تم توصيل الجهاز: {name}',
    camFrontDoor: 'الباب الأمامي', camBackDoor: 'الباب الخلفي', camGarage: 'الكراج', camBackyard: 'الفناء الخلفي', camEntrance: 'المدخل', camDriveway: 'ممر السيارة', camBalcony: 'الشرفة',
    autoMotionNight: 'إضاءة ليلية بالحركة', autoArrive: 'الوصول إلى المنزل', autoMorning: 'صباح الخير', autoEnergySave: 'توفير الطاقة',
    condMotionNight: 'حركة ليلاً (21:00–06:00)', condNobodyHome: 'إذا لم يكن أحد في المنزل', condArrive: 'عند الوصول إلى المنزل', condTime2300: 'الساعة 23:00', condMorningWeekday: 'الساعة 07:00 في أيام العمل', condNoMotion30: 'إذا لم تكن هناك حركة لمدة 30 دقيقة',
    actAllLightsOn: 'تشغيل كل الأضواء', actAlarmOffAll: 'تفعيل الإنذار + إطفاء الكل', actLightsAlarmOff: 'تشغيل الأضواء + إيقاف الإنذار', actOffLock: 'إطفاء الكل + قفل الأبواب', actBlindsCoffee: 'فتح الستائر + تشغيل القهوة', actOffLightsAc: 'إطفاء الأضواء والمكيّف',
    catSmoke: 'دخان', catEnergy: 'الطاقة', actionTurnOn: 'تشغيل', actionTurnOff: 'إيقاف',
    cyberNoEvents: 'لا توجد أحداث حديثة', cyberNetworkMap: 'خريطة الشبكة', cyberNetworkTopology: 'هيكل الشبكة', cyberPhones: 'هواتف', cyberOnlineFmt: '{on} / {total} متصل',
    homeTypeLabels: const ['منزل','شقة','فيلا','كوخ ريفي','كابينة','برج','بنتهاوس','مزرعة','ضيعة','يخت'],
    homeColorLabels: const ['أزرق','بنفسجي','أخضر','برتقالي','ذهبي','أحمر','فيروزي','وردي','بني','رمادي'],
    homeTypeTitle: 'نوع المنزل', homeColorTitle: 'اللون', colorMix: 'مزج الألوان', pickLabel: 'اختر',
    profilePhotoFmt: 'صورة الملف الشخصي — {name}', inviteSubject: 'دعوة للانضمام إلى منزلي الذكي', inviteBodyFmt: 'مرحباً،\n\nأدعوك للانضمام إلى منزلي الذكي عبر تطبيق FantaTech.\n\nرمز الانضمام: {code}\n\nنزّل التطبيق وأدخل الرمز للانضمام.', noEmailApp: 'لم يتم العثور على تطبيق بريد على الجهاز', regManagerMsg: 'تم تسجيلك كمدير للمنزل!', nameFieldFmt: 'الاسم: {name}', homeJoinTitle: 'رمز الانضمام للمنزل', shareCodeHint: 'شارك الرمز مع أفراد المنزل\nليتمكنوا من الانضمام', gotIt: 'فهمت', homeStyleTitle: 'نمط المنزل', registerAsFmt: 'سجّل كـ: {name}', newCodeFmt: 'تم إنشاء رمز جديد: {code}', joinCodeInline: 'رمز الانضمام للمنزل:  ', inviteByEmail: 'دعوة فرد عبر البريد', inviteByEmailSub: 'أرسل رمز الانضمام مباشرة عبر البريد',
    tailscaleWhat: 'ما هو Tailscale؟', tailscaleDesc: 'شبكة VPN مجانية للوصول عن بُعد إلى شبكة منزلك.\nتربط هاتفك بشبكة المنزل بشكل مشفّر، حتى عندما تكون بالخارج.', tailscaleStep1: 'ثبّت Tailscale على هاتفك وعلى Raspberry Pi / HA Green', tailscaleStep2: 'سجّل الدخول بنفس الحساب (Google / Apple / Email)', tailscaleStep3: 'فعّل المفتاح — سيفتح التطبيق Tailscale', tailscaleOpen: 'افتح / ثبّت Tailscale',
    camScanNetwork: 'فحص الشبكة', camScanning: 'جارٍ الفحص...', camAddManual: 'إضافة كاميرا يدوياً', camFieldName: 'الاسم', camPort: 'المنفذ', camUser: 'المستخدم', camRtspPath: 'مسار RTSP', camStreamPath: 'مسار البث', camRtspHint: '/  أو  /cam/realmonitor?channel=1', camPtzTitle: 'كاميرا PTZ', camPtzSub: 'تفعيل التحكم Pan / Tilt / Zoom', camTestConn: 'اختبار الاتصال', camAddBtn: 'إضافة كاميرا', camFoundFmt: '✓ تم العثور على كاميرا! {info} — المنافذ المفتوحة: {ports}', camConnectFailFmt: '✗ تعذّر الاتصال بـ {addr}',
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
    aiInputHint: 'اكتب أو تحدث إليّ', aiMicUnavailable: 'الميكروفون غير متاح',
    aiSug1: 'أطفئ كل الأضواء',
    aiSug2: 'ما حالة المنزل الآن؟',
    aiSug3: 'تفعيل وضع الليل',
    aiSug4: 'هل هناك تنبيهات نشطة؟',
    aiSugDesc1: 'يمكنني إطفاء جميع الأضواء في المنزل',
    aiSugDesc2: 'احصل على ملخص كامل عن المنزل وأنظمته',
    aiSugDesc3: 'سأقوم بتفعيل جميع إعدادات وضع الليل',
    aiSugDesc4: 'تحقق من وجود تنبيهات أو حالات غير عادية',
    aiPrivacyNote: 'معلوماتك خاصة ومحمية', aiClearChat: 'مسح المحادثة',
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
    deviceWillBeRemoved: 'سيتم إزالة الجهاز من القائمة', haRemoveDeviceFailed: 'تمت إزالته من القائمة، لكن تعذر حذفه من Home Assistant', ipAddressLabel: 'عنوان IP',
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
    scanBarcode: 'مسح الباركود / QR', editUserName: 'تعديل اسم المستخدم', searchScanProducts: 'فحص المنتجات على الشبكة',
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
    roomNameLiving: 'غرفة المعيشة', roomNameKitchen: 'المطبخ', roomNameBedroom: 'غرفة النوم',
    roomNameKids: 'غرفة الأطفال', roomNameGarden: 'الحديقة', roomNameBathroom: 'الحمام',
    roomNameStorage: 'مخزن', roomNameAc: 'مكيف',
    rememberMe: 'تذكرني',
    notConnectedLabel: 'غير متصل', solarTitle: 'نظام الطاقة الشمسية', solarProduction: 'الإنتاج', solarConsumption: 'الاستهلاك',
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
    assignRoom: 'تعيين غرفة', noRoom: 'بدون غرفة', newRoom: 'غرفة جديدة…',
    planFree: 'مجاني', planBasic: 'أساسي',
    planAdvanced: 'متقدم', planAdvancedPlus: 'متقدم بلس',
    planUnlimited: 'غير محدود',
    planCurrentBadge: 'نشط', planUpgradeNow: 'ترقية الآن',
    planSelected: 'مختار', planDevicesLabel: 'أجهزة',
    planRoomsLabel: 'غرف', planAutoLabel: 'أتمتة',
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
    keepShabbatLabel: 'حفظ السبت', shabbatSection: 'السبت',
    shabbatCandlesDesc: 'إطفاء كل شيء ✡️ وقفل الأبواب قبل السبت',
    shabbatHavdalahDesc: 'استعادة الأجهزة بعد انتهاء السبت',
    acConnected: 'مكيفات متصلة', acNoUnits: 'لا توجد مكيفات متصلة',
    adStoreLabel: 'متجر FantaTech', adTrackTitle: 'إعدادات الإعلانات',
    adTrackSub: 'اختر المنتجات التي تظهر في البانر',
    adFeaturedLabel: 'منتجات مميزة', adFeaturedSub: 'Hub Pro, Camera 4K, Smart Bulb, Sensor',
    adNewLabel: 'الجديد في المتجر', adNewSub: 'Smart Blind, Smart Plug 16A, Gateway, LED Strip',
    adAllLabel: 'كل المنتجات', adAllSub: 'تناوب كامل لكل الكتالوج',
    adNoneLabel: 'بدون إعلانات', adNoneSub: 'إخفاء البانر بالكامل',
    autoThemeLabel: 'ثيم تلقائي', autoThemeDesc: 'يتكيف مع ضوء المحيط',
    autoThemeActive: 'نشط', autoThemeWaiting: 'انتظار المستشعر…',
    homeLayoutLabel: 'تخطيط الشاشة الرئيسية',
    signOutAppTitle: 'الخروج من التطبيق', signOutChoose: 'اختر طريقة الخروج',
    signOutToLogin: 'تسجيل خروج والعودة للدخول', signOutToLoginSub: 'يقطع الحساب — تسجيل دخول مطلوب',
    signOutFull: 'خروج كامل', signOutFullSub: 'تسجيل خروج وإغلاق التطبيق',
    accountSection: 'الحساب',
    switchAccountTitle: 'تبديل الحساب', switchAccountSub: 'تسجيل الخروج والدخول بحساب آخر',
    switchAccountConfirmTitle: 'تبديل الحساب؟', switchAccountConfirmBody: 'سيتم تسجيل خروجك والعودة لشاشة الدخول.',
    switchAccountConfirmBtn: 'تبديل الحساب', switchAccountPasswordPrompt: 'أدخل كلمة المرور للتأكيد',
    switchAccountWrongPassword: 'كلمة مرور غير صحيحة',
    installerBadge: 'المثبت', installerCodeTitle: 'وضع المثبت',
    installerCodeHint: 'أدخل رمز المثبت', installerCodeWrong: 'رمز المثبت غير صحيح',
    installerModeOnMsg: 'تم تفعيل وضع المثبت', installerModeOffMsg: 'تم الخروج من وضع المثبت',
    installerExitConfirm: 'الخروج من وضع المثبت؟',
    deviceOfflineHint: 'الجهاز غير متصل — تحقق من الاتصال',
    aiBackendNotConfigured: 'مساعد الذكاء الاصطناعي لم يتم إعداده بعد',
    aiRequestFailed: 'عذرًا، لم أتمكن من الوصول إلى المساعد الآن',
    aiEmptyReply: 'تم.',
    aiTooManySteps: 'هذا الطلب يحتاج خطوات كثيرة جدًا — جرّب شيئًا أبسط',
    mirrorScreenTitle: 'مرآة ذكية', adBannerShop: 'تسوق',
    confirm: 'تأكيد', pickDay: 'يوم', pickMonth: 'شهر',
    pickHebrewDate: 'اختر تاريخاً عبرياً',
    hebrewDateFmt: 'التاريخ العبري: {date}', hebrewCalendarChip: 'التاريخ العبري…',
    storeBuyAt: 'شراء من ',
    loginBiometric: 'الدخول ببصمة / الوجه',
    errInvalidEmail: 'عنوان البريد الإلكتروني غير صحيح',
    loginGoogleEmailPrompt: 'أدخل عنوان Gmail للمتابعة',
    scanNetworkTitle: 'فحص الشبكة', scanSelectDevice: 'اختر جهازاً للإضافة',
    stop: 'إيقاف', scanSensorsShutters: 'حساسات · ستائر',
    sensorHubTitle: 'الحساسات والستائر',
    sensorHubFoundFmt: '{sensors} حساسات · {covers} ستائر',
    sensorsTab: 'حساسات', shuttersTab: 'ستائر',
    noSensorsFound: 'لم يتم العثور على حساسات',
    noCoversFound: 'لم يتم العثور على ستائر',
    coverOpen: '▲  فتح', coverStop: '■  إيقاف', coverClose: '▼  إغلاق',
    switchScanningAll: 'فحص كل البروتوكولات…',
    switchAddedFmt: '✓ {name} تمت إضافته إلى المنزل',
    keyStoredLocal: 'المفتاح محفوظ على جهازك فقط.',
    saveAndControl: 'حفظ والتحكم',
    tapoLogin: 'Tapo — الدخول',
    tapoCredHint: 'نفس بيانات حساب تطبيق TP-Link Tapo.',
    connectAndControl: 'اتصال والتحكم',
    errControlFmt: 'خطأ في التحكم بـ {name}',
    switchSearchingAll: 'البحث عن مفاتيح ذكية في كل البروتوكولات…',
    switchNoFound: 'لم يتم العثور على مفاتيح ذكية',
    switchHint: 'تأكد أن المفاتيح متصلة بنفس شبكة WiFi.\nShelly/ESPHome — في وضع STA\nSonoff — في وضع DIY (firmware 3.6+)\nHome Assistant / Zigbee2MQTT — اتصل في الإعدادات',
    camFrameCaptureError: 'خطأ في التقاط الإطار',
    camNoFaces: 'لم يتم التعرف على أي وجه',
    camFacesFoundFmt: 'تم التعرف على {count} وجه — {known} معروف 🎯',
    camFacesOnlyFmt: 'تم التعرف على {count} وجه 🎯',
    camAnalysisErrorFmt: 'خطأ في التحليل: {error}',
    camCaptureError: 'خطأ في الالتقاط',
    camSnapshotSavedFmt: '📸 تم الحفظ: snapshot_{ts}.png',
    camSaveSnapshotError: 'خطأ في حفظ الصورة',
    camConnectingFmt: 'جارٍ الاتصال بـ {name}...',
    camIdentifyingFaces: 'جارٍ التعرف على الوجوه والهويات...',
    camDetectingFaces: 'جارٍ التعرف على الوجوه...',
    camFaceLabelFmt: 'وجه {n}', camStreamConnFailed: 'تعذّر الاتصال بالبث',
    addWizBulb: 'إضافة مصباح WiZ حقيقي',
    addWizBulbSub: 'تحكم حقيقي عبر LAN · بدون سحابة',
    deviceNotFoundStatus: 'الجهاز غير موجود', manualAddStatus: 'إضافة يدوية',
    connecting: 'جارٍ الاتصال...',
    deviceNotFoundHint: 'تأكد أن الجهاز متصل بالكهرباء وبشبكة WiFi،\nأو أن البلوتوث مفعّل.',
    manualAddLabel: 'إضافة يدوياً', deviceNameLabel: 'اسم الجهاز', deviceDeleteConfirm: 'إزالة هذا الجهاز من التطبيق؟ يمكنك إضافته مرة أخرى لاحقاً عن طريق إعادة المسح.',
    ipAddressOptional: 'عنوان IP (اختياري)', back: 'رجوع',
    faceConfigured: '✓ مُضبوط', faceIdTitle: 'التعرف على الهوية',
    faceIdSubtitle: 'سجّل أشخاصاً للتعرف التلقائي',
    faceTraining: 'تدريب النموذج...',
    faceTrainModelFmt: 'تدريب نموذج التعرف ({enrolled}/{total} مسجلون)',
    facePrepGroup: 'تجهيز المجموعة...',
    faceTrainStartFailed: '❌ تعذّر بدء التدريب',
    faceTrainingProgress: 'جارٍ التدريب... (قد يستغرق حتى 60 ثانية)',
    faceTrainSuccess: '✅ تم تدريب النموذج بنجاح! التعرف نشط.',
    faceTrainFailed: '❌ فشل التدريب. حاول مرة أخرى.',
    faceSetAzureKeyFirst: 'أضف مفتاح Azure API أولاً',
    faceAddingPhoto: 'جارٍ إضافة الصورة إلى Azure...',
    faceCreateRecordError: '❌ خطأ في إنشاء السجل في Azure',
    faceFaceNotDetected: '❌ تعذّر التعرف على وجه في هذه الصورة',
    facePhotoAddedFmt: '✅ تمت إضافة الصورة إلى {name}. درّب النموذج.',
    faceNotConfiguredTap: 'غير مُضبوط — اضغط للضبط',
    faceCheckConnection: 'تحقق من الاتصال',
    faceGetFreeApiKey: 'احصل على مفتاح API مجاني في portal.azure.com → Cognitive Services',
    faceSaveSettingsFirst: '⚠️ احفظ الإعدادات أولاً',
    faceAzureConnOk: '✅ الاتصال بـ Azure نجح!',
    faceAzureConnFailed: '❌ تعذّر الاتصال. تحقق من Endpoint + Key',
    faceEnrolledAzure: '✓ مسجّل في Azure', faceNotEnrolled: '⚠ غير مسجّل — أضف صورة',
    faceAddPerson: 'إضافة شخص', faceFullNameHint: 'الاسم الكامل',
    faceEnterName: 'أدخل اسماً', faceCreatingRecord: 'جارٍ إنشاء السجل...',
    faceNoPeople: 'لا يوجد أشخاص مسجّلون',
    faceNoPeopleHint: 'أضف أشخاصاً لكي تتعرف الكاميرات\nعليهم بالاسم',
    roomSettings: 'إعدادات الغرفة', capComingSoonFmt: '{cap} — قريباً',
    householdNoAdmin: 'لا يوجد مدير منزل بعد',
    householdMemberNote: 'الدخول كفرد متاح بعد تسجيل مدير المنزل\nبـ Google أو Apple.',
    backToLogin: 'العودة لتسجيل الدخول', householdAdmin: 'مدير المنزل',
    selectProfile: 'اختر ملفاً شخصياً', noMembersYet: 'لا يوجد أفراد بعد',
    addMembersHint: 'يمكن لمدير المنزل إضافة أفراد\nمن الملف الشخصي ← إدارة المنزل.',
    switchScanProgressFmt: 'جارٍ الفحص... {n} / 254',
    switchNoDevicesHint: 'لم يتم العثور على أجهزة. تأكد أن الأجهزة متصلة بنفس شبكة WiFi',
    scanDoneFmt: 'اكتمل الفحص — {n} أجهزة', scanWifi: 'فحص شبكة WiFi',
    faceAnalysisTitle: 'تحليل التعرف على الوجه',
    faceAnalysisSubtitle: 'سجل فحوصات الكاميرات',
    clear: 'مسح', clearHistory: 'مسح السجل',
    clearHistoryConfirm: 'هل تريد حذف كل نتائج التحليل؟',
    statScans: 'الفحوصات', statFacesDetected: 'وجوه تم التعرف عليها',
    statAlerts: 'التنبيهات', faces: 'وجوه', smiling: 'مبتسم', eyesClosed: 'عيون مغلقة',
    noFacesInFrame: 'لم يتم التعرف على أي وجه في هذا الإطار',
    noAnalysesYet: 'لا يوجد تحليل بعد',
    faceAnalysisHint: 'افتح الكاميرا واضغط على "تحليل"\nلبدء التعرف على الوجه',
    smartHomeTitle: 'المنزل الذكي',
    temperatureFmt: 'الحرارة: {n}°C', brightnessFmt: 'الإضاءة: {n}%', positionFmt: 'الموضع: {n}%',
    wizIdentifyingWifi: 'جارٍ التعرف على شبكة WiFi…',
    wizNoWifi: 'غير متصل بـ WiFi — أدخل IP يدوياً',
    wizBroadcastingFmt: 'جارٍ البث على {prefix}.x …',
    wizNoFound: 'لم يتم العثور على مصابيح WiZ — جرب يدوياً',
    wizFoundFmt: 'تم العثور على {n} مصباح',
    wizScanFailed: 'فشل الفحص — جرب يدوياً',
    wizBlinkingFmt: 'وميض {ip} …',
    wizBlinkSentFmt: 'تم إرسال أمر الوميض إلى {ip} ✓',
    wizNoResponseFmt: 'لا استجابة من {ip} - تحقق من أن المصباح على الشبكة',
    wizDeviceAddedFmt: '{name} تمت إضافته — التحكم الحقيقي نشط',
    wizManualAdd: 'إضافة يدوية بعنوان IP', wizTest: 'اختبار',
    gatewayHubTitle: 'الجسور ومراكز التحكم',
    gatewayHubSubtitle: 'اتصل بمحاور Zigbee و Z-Wave و WiFi والسحابة',
    connected: 'متصل', addGateway: 'إضافة جسر', gatewayTypesFmt: '{n} أنواع',
    devicesImportedFmt: 'تمت إضافة {n} أجهزة من {name}',
    allDevicesExist: 'جميع الأجهزة موجودة بالفعل',
    diagnosisTitle: 'الأجهزة التي يبلغ عنها المحور',
    disconnectConfirmFmt: 'قطع اتصال "{name}"؟',
    importedDevicesNote: 'الأجهزة المستوردة ستبقى، لكن لن يمكن استيراد المزيد.',
    disconnect: 'قطع الاتصال', deviceCountFmt: '{n} أجهزة',
    importDevices: 'استيراد الأجهزة', connect: 'اتصال',
    connectAfterButton: 'اتصال (بعد ضغط الزر)',
    connectedSuccess: 'تم الاتصال بنجاح!',
    secondsRemainingFmt: '{n} ثواني متبقية', cloud: 'سحابة',
    cloudConnectionNote: 'اتصال سحابي — البيانات تمر عبر خوادم المصنّع',
    setupStepsHintFmt: 'كيف تحصل على التفاصيل؟ ({n} خطوات)',
    tokenPortalFmt: 'Token نُنشئ في بوابة {name}', optional: 'اختياري',
    z2mEnterIp: 'أدخل عنوان IP لـ Zigbee2MQTT',
    z2mUnreachableFmt: 'تعذّر الوصول إلى Zigbee2MQTT عبر {ip}:{port}\nتأكد من تفعيل الواجهة الأمامية وصحة IP',
    z2mUnknownError: 'خطأ غير معروف',
    z2mSubtitle: 'الاتصال ببوابة Zigbee — استيراد تلقائي للأجهزة',
    z2mIpLabel: 'عنوان IP لـ Z2M', z2mIpHint: 'مثال: 192.168.1.50',
    z2mPortLabel: 'المنفذ', z2mTokenLabel: 'رمز API (اختياري)',
    z2mTokenHint: 'إذا تم الضبط', z2mFoundFmt: 'تم العثور على {n} أجهزة Zigbee!',
    z2mConnectImport: 'اتصل واستورد الأجهزة',
    z2mFrontendHelp: 'فعّل الواجهة في إعدادات Z2M:\n  frontend:\n    port: 8080',
    discoveryTitle: 'البحث عن الأجهزة', scan: 'فحص',
    matterDeviceTitle: 'جهاز Matter',
    matterDeviceHelp: 'أجهزة Matter (مثل مصابيح IKEA) تُربط عبر محور Matter — ليس مباشرة من التطبيق.\n\nالطريقة السهلة:\n1. اربط المصباح بـ DIRIGERA عبر تطبيق IKEA Home smart.\n2. هنا: الجسور → DIRIGERA → "استيراد الأجهزة".\nسيظهر المصباح مع التحكم الكامل.',
    understood: 'فهمت', devicesAddedFmt: 'تمت إضافة {n} أجهزة',
    haFound: 'تم العثور على Home Assistant',
    haConnectedFmt: 'متصل — {n} أجهزة تم استيرادها',
    haConnect: 'اتصال',
    haReconnectSync: 'إعادة الاتصال والمزامنة',
    haTokenHint: 'أنشئ Token في: Profile → Long-Lived Access Tokens',
    importFromHa: 'استيراد الأجهزة من Home Assistant',
    scanningDevices: 'جارٍ البحث عن الأجهزة…',
    scanHint: 'اضغط "فحص" للبحث عن الأجهزة في الشبكة',
    addAllFmt: 'إضافة الكل ({n} أجهزة)',
    matterCommTitle: 'ربط جهاز Matter',
    matterCommSubtitle: 'امسح QR على ملصق الجهاز',
    matterCommScanBtn: 'امسح QR', matterCommManualBtn: 'أدخل الرمز يدوياً',
    matterCommManualHint: 'رمز من 11 رقماً (مثال 12345-67890)',
    matterCommissioning: 'جارٍ الربط عبر Home Assistant…',
    matterCommSuccess: 'تم ربط الجهاز بنجاح!',
    matterCommFailed: 'فشل الربط. تأكد من تفعيل تكامل Matter في HA.',
    matterCommNoHa: 'Home Assistant غير متصل. اتصل بـ HA أولاً.',
    matterCommRetry: 'حاول مرة أخرى',
    matterCommCodeHint: 'MT:… أو رمز من 11 رقماً',
    blindsHubTitle: 'الستائر والأغطية', openAll: 'فتح الكل', closeAll: 'إغلاق الكل',
    noBlindsFound: 'لم يتم العثور على ستائر',
    blindsHint: 'أضف الستائر عبر Home Assistant',
    smartLocksTitle: 'الأقفال الذكية', lockedStatus: 'مقفل', unlockedStatus: 'مفتوح',
    lockAll: 'قفل الكل', unlockAll: 'فتح الكل',
    noLocksFound: 'لم يتم العثور على أقفال',
    lockHint: 'أضف قفلاً ذكياً عبر Home Assistant',
    lightsHubTitle: 'الأضواء', lightsAllOn: 'تشغيل الكل', lightsAllOff: 'إيقاف الكل',
    noLightsFound: 'لم يتم العثور على أضواء',
    lightsHint: 'أضف أضواء عبر Home Assistant',
    plugsHubTitle: 'المقابس الذكية', plugsAllOn: 'تشغيل الكل', plugsAllOff: 'إيقاف الكل',
    noPlugsFound: 'لم يتم العثور على مقابس',
    plugsHint: 'أضف مقابس عبر فحص WiFi',
    acHubTitle: 'تكييف الهواء',
    intercomTitle: 'إنترفون', intercomNoDevices: 'لم يتم العثور على أجهزة إنترفون',
    intercomHint: 'أضف إنترفوناً عبر الكتالوج أو استيراد البوابة',
    intercomRing: 'رنّ', intercomAnswer: 'رد', intercomDecline: 'رفض',
    intercomCategory: 'جرس الفيديو', intercomRinging: 'شخص عند الباب…',
    vacuumCategory: 'مكنسة روبوت', vacuumNoDevices: 'لم يتم العثور على مكانس روبوتية',
    vacuumHint: 'قم بتوصيل المكنسة الروبوتية عبر Home Assistant لرؤيتها هنا',
    vacuumStart: 'ابدأ', vacuumPause: 'إيقاف مؤقت', vacuumDock: 'العودة للقاعدة',
    vacuumCleaning: 'تنظيف', vacuumDocked: 'في القاعدة',
    intercomUnlockDoor: 'فتح الباب',
    energyRateLabel: 'تعريفة الكهرباء', energyRateEdit: 'تعديل التعريفة',
    energyRateUnit: '₪/كيلوواط', energyRateSaved: 'تم حفظ التعريفة',
    backupTitle: 'النسخ الاحتياطي والاستعادة', backupExport: 'تصدير الإعدادات',
    backupImport: 'استيراد الإعدادات', backupExportDone: 'تم تصدير الإعدادات',
    backupImportDone: 'تمت الاستعادة بنجاح', backupImportError: 'فشل الاستيراد — ملف غير صالح',
    backupSection: 'البيانات والنسخ الاحتياطي',
    biometricSplashLabel: 'المصادقة',
    camLocationPermission: 'إذن الموقع مطلوب لفحص الشبكة',
    camNoWifiIp: 'تعذر التعرف على شبكة WiFi الخاصة بك — اتصل بشبكة WiFi وحاول مرة أخرى، أو أضف الكاميرا يدويًا',
    camScanNoneFound: 'لم يتم العثور على كاميرات في الشبكة. إذا كانت كاميرتك لا تدعم ONVIF، أضفها يدويًا باستخدام عنوان IP الخاص بها.',
    showHideSections: 'إظهار / إخفاء الأقسام', restoreDefaults: 'استعادة الإعدادات الافتراضية؟', restoreDefaultsConfirm: 'سيؤدي ذلك إلى إعادة تعيين تخطيط لوحة الأمان. لا يمكن التراجع.', restore: 'استعادة', systemTest: 'اختبار النظام',
  );

  // ── Amharic ───────────────────────────────────────────────────
  static const S _am = S(
    homeGreetingSub: 'ቤትዎ፣ ደህንነቱ የተጠበቀ እና ብልጥ።', energyToday: 'የዛሬ ኃይል ፍጆታ', vsYesterday: 'ከትናንት ጋር',
    climateEnergyTitle: 'የአየር ንብረት እና ኃይል', homeManagementTitle: 'የቤት አስተዳደር',
    energyAnalytics: 'የኃይል ትንተና',
    securitySystemLabel: 'የደህንነት ስርዓት', secArmedShort: 'ነቅቷል', secDisarmedShort: 'ጠፍቷል', allOkLabel: 'ሁሉም ደህና ነው', emergencyBtn: 'አደጋ',
    showAll: 'ሁሉንም አሳይ', roomsHeader: 'ክፍሎች', statHomesLabel: 'ቤቶች', devicesUnit: 'መሳሪያዎች',
    qaLock: 'ቁልፍ', qaLights: 'መብራቶች', qaAc: 'አ.ኮንዲሽነር', qaCameras: 'ካሜራዎች', qaAlerts: 'ማንቂያዎች',
    qaPlugs: 'ሶኬቶች', qaWaterHeater: 'ቦይለር', qaBreakers: 'ፓነል',
    qaNoDevices: 'ምንም መሳሪያ የለም', qaNoAlerts: 'ምንም ማሳወቂያ', qaResetAll: 'ሁሉን አስወግድ', qaScanDevice: 'መሳሪያ ፈልግ',
    adAddLink: 'ማገናኛ ጨምር', adCustomLink: 'ብጁ ማገናኛ',
    systemStatus: 'የስርዓት ሁኔታ', statusInternet: 'ኢንተርኔት', statusSensors: 'ዳሳሾች', connectedLabel: 'ተገናኝቷል',
    camMotion: 'እንቅስቃሴ ተገኝቷል', camOnline: 'በመስመር ላይ', camOffline: 'ከመስመር ውጭ', locationUnavailable: 'ቦታ አይገኝም', gatewaysManage: 'አስተዳድር', gatewaysTitle: 'ጌትዌዎች', statusOffline: 'ከመስመር ውጭ',
    secArmStayBtn: 'አንቃ (ቤት)', secDisarmBtn: 'አጥፋ', roomNameMedia: 'ሚዲያ', mediaRoomTitle: 'ሚዲያ',
    roomOccupantLabel: 'ይህን ክፍል ማን ይጠቀማል?', occupantNone: 'ምንም', occupantKids: 'ልጆች', occupantAdults: 'ጎልማሶች',
    navHome: 'ቤት', navCameras: 'ካሜራ', navSecurity: 'ደህንነት', navProfile: 'መገለጫ', navAutomations: 'አዘምኔዎች',
    greetingPrefix: 'ሰላም', homeSecured: 'ቤትህ ተጠብቋል', homeNotSecured: 'ቤትህ አልተጠበቀም',
    allSystemsActive: 'ሁሉም ስርዓቶች ንቁ', tapToActivate: 'ደህንነትን ለማንቃት ጫን',
    alarmTitle: 'ማንቂያ', alarmSecured: 'ጠብቋቷ', alarmOff: 'ጠፍቷ', roomManagement: 'የቤት አስተዳደር', roomsUnit: 'ክፍሎች',
    camerasTitle: 'ካሜራዎች', lightsOn: 'መብራቶች 켜져', lightingTitle: 'መብራት',
    tempTitle: 'ሙቀት', tempComfy: 'ምቹ', aiSubtitle: 'እንዴት ልረዳህ?', aiTopSubtitle: 'የቤትዎ ብልህ ረዳት',
    quickActions: 'ፈጣን ድርጊቶች', leaveHome: 'ቤት ውጣ', turnOffAll: 'ሁሉ አጥፋ', goodNight: 'መልካም ሌሊት', movieMode: 'የፊልም ሁነታ',
    mediaTitle: 'ሚዲያ', mediaSpeakers: 'ድምጽ ማጉያዎች', mediaScan: 'መሣሪያዎችን ቃኝ', mediaNoDevices: 'ድምጽ ማጉያ አልተገኘም። ቃኝን ይጫኑ።',
    bioTitle: 'ፈጣን መግቢያ', bioPrompt: 'በሚቀጥለው ጊዜ በጣት አሻራ መግባት ይነቃ?', bioEnable: 'አንቃ', bioSkip: 'አሁን አይደለም', bioReason: 'ለመግባት ማንነትዎን ያረጋግጡ',
    onbNext: 'ቀጣይ', onbStart: 'እንጀምር', onbSkip: 'ዝለል', onbAllow: 'ፍቀድ', onbLater: 'በኋላ', onb1Title: 'እንኳን ወደ FantaTech በደህና መጡ', onb1Body: 'ብልህ ቤትዎ — መብራት፣ ደህንነት፣ የአየር ሁኔታ እና ኢነርጂ በአንድ ቦታ።', onb2Title: 'ሙሉ ቁጥጥር', onb2Body: 'ካሜራዎችን፣ ዳሳሾችን፣ መቀየሪያዎችን ከየትኛውም ቦታ ያቀናብሩ።', onb3Title: 'ብልህ አውቶሜሽን', onb3Body: 'ትዕይንቶችን ይፍጠሩ፣ ኢነርጂ ይቆጥቡ፣ ወቅታዊ ማንቂያዎችን ያግኙ።', onbPermTitle: 'የመሣሪያ ፍለጋ ፍቃዶች', onbPermBody: 'በአውታረ መረብዎ ላይ መሣሪያዎችን ለማግኘት የአካባቢ እና የብሉቱዝ ፍቃድ ያስፈልጋል። ውሂብዎ በመሣሪያዎ ብቻ ይቆያል።',
    secSection: 'ደህንነት', bioLoginLabel: 'በጣት አሻራ መግባት', bioLoginSub: 'በባዮሜትሪክ በፍጥነት ይግቡ', bioUnavailable: 'መሣሪያው ባዮሜትሪክ አይደግፍም', legalSection: 'ህጋዊ እና ግላዊነት', termsLabel: 'የአገልግሎት ውሎች', privacyLabel: 'የግላዊነት ፖሊሲ',
    sceneCreate: 'ትዕይንት ፍጠር', sceneNew: 'አዲስ ትዕይንት', sceneName: 'የትዕይንት ስም', sceneActions: 'ድርጊቶች', actPlugs: 'ሶኬቶች', valKeep: 'ሳይቀየር', valOn: 'አብራ', valOff: 'አጥፋ',
    authEmailHint: 'ኢሜል ወይም ስልክ', authPassHint: 'የይለፍ ቃል', loginGreeting: 'ሰላም!', loginSubtitle: 'ወደ መለያዎ ይግቡ', loginForgot: 'የይለፍ ቃል ረሱ?', resetEmailHint: 'ኢሜልዎን ያስገቡ፣ ዳግም ማስጀመሪያ ማገናኛ እንልክልዎታለን።', resetEmailSent: 'ማገናኛ ተልኳል! ሳጥንዎን ይፈትሹ።', okButton: 'እሺ', cancelButton: 'ሰርዝ', sendButton: 'ላክ', loginButton: 'ግባ', authOr: 'ወይም', loginNoAccount: 'መለያ የለዎትም?', registerNow: 'አሁን ይመዝገቡ', continueAsGuest: 'እንደ እንግዳ ይቀጥሉ', loginWith: 'በዚህ ግቡ', appTagline: 'ስማርት ቤት እና ደህንነት', registerTitle: 'መለያ ይፍጠሩ', registerSubtitle: 'ወደ FantaTech ስማርት ቤት ይቀላቀሉ', confirmPassHint: 'የይለፍ ቃል ያረጋግጡ', registerButton: 'ይመዝገቡ', haveAccount: 'አስቀድሞ መለያ አለዎት?', loginHousehold: 'የቤተሰብ አባል',
    errEnterName: 'እባክዎ ሙሉ ስም ያስገቡ', errEnterEmail: 'እባክዎ ኢሜል ወይም ስልክ ያስገቡ', errPassShort: 'የይለፍ ቃል ቢያንስ 6 ቁምፊዎች መሆን አለበት', errPassMismatch: 'የይለፍ ቃላት አይዛመዱም',
    acMode: 'ሁነታ', acFanSpeed: 'የአየር ፍጥነት', acSwing: 'ማወዛወዝ', acPreset: 'ቅድመ-ቅንብር', acMethod: 'መቆጣጠሪያ', modeCool: 'ማቀዝቀዝ', modeHeat: 'ማሞቅ', modeFan: 'ማራገቢያ', modeDry: 'ማድረቅ', modeAuto: 'ራስ-ሰር', fanLow: 'ዝቅተኛ', fanMed: 'መካከለኛ', fanHigh: 'ከፍተኛ',
    mediaMaster: 'አጠቃላይ ድምጽ', mediaParty: 'በሁሉም ላይ አጫውት', mediaStopAll: 'ሁሉንም አቁም',
    tvRemote: 'የቲቪ መቆጣጠሪያ', tvSource: 'ምንጭ', tvChannel: 'ጣቢያ', tvMute: 'ድምጽ አጥፋ',
    faq1Q: 'መሣሪያ እንዴት ይታከላል?', faq1A: 'በዋናው ሰሌዳ + ይጫኑ እና ከካታሎጉ መሣሪያ ይምረጡ።', faq2Q: 'ቋንቋ እንዴት ይቀየራል?', faq2A: 'መገለጫ ← ቅንብሮች ← ቋንቋ።', faq3Q: 'መተግበሪያው ያለ ኢንተርኔት ይሰራል?', faq3A: 'የአካባቢ ትዕዛዞች ይሰራሉ። ደመና ኢንተርኔት ይፈልጋል።', faq4Q: 'አውቶሜሽን እንዴት ይዘጋጃል?', faq4A: 'በታችኛው ምናሌ "አውቶሜሽን" ይጫኑ ← ጨምር።',
    energyTitle: 'ኃይል ፍጆታ', automationsTitle: 'አውቶሜሽን', activeAutomations: 'ንቁ አውቶሜሽን',
    myProfile: 'የኔ መገለጫ', myHome: 'የኔ ቤት', usersTitle: 'ተጠቃሚዎች',
    subscriptionTitle: 'ምዝገባ', settingsTitle: 'ቅንብሮች', helpTitle: 'እርዳታ',
    signOut: 'ውጣ', languageLabel: 'ቋንቋ', themeLabel: 'ቅርጸ-ቀለም',
    darkMode: 'ጨለማ', lightMode: 'ብርሃን', appearanceTitle: 'መልክ', themeFont: 'ቅርጸ-ቁምፊ', themeAccent: 'ዋና ቀለም', themeBg: 'ዳራ', themeRadius: 'ጥምዝ', themeBgDarkBlue: 'ጥቁር ሰማያዊ', themeBgAmoled: 'AMOLED ጥቁር', themeBgDarkGray: 'ጥቁር ግራጫ', themeBgLightGray: 'ብርሃን ሰማያዊ', themeBgLightWhite: 'ነጭ', themeRadiusSharp: 'ሹል', themeRadiusNormal: 'መደበኛ', themeRadiusRound: 'ክብ', saveChanges: 'ለውጦችን አስቀምጥ',
    editProfile: 'መገለጫ አርትዕ', fullName: 'ሙሉ ስም', emailLabel: 'ኢሜይል',
    profileUpdated: 'መገለጫ ተዘምኗ', signOutConfirm: 'ውጣ', signOutQuestion: 'ለመውጣት እርግጠኛ ነህ?', confirmSignOut: 'ውጣ',
    securityTitle: 'ደህንነት', armedMode: 'ታጥቋ', disarmedMode: ' አልታጠቀም',
    doorSensor: 'የፊት ደጃፍ', windowsSensor: 'መስኮቶች', motionSensors: 'እንቅስቃሴ ዳሳሽ', smokeDetector: 'ጭስ ዳሳሽ', waterLeakSensor: 'የውሃ መፍሰስ ዳሳሽ',
    securedStatus: 'ተጠብቋ', openStatus: 'ክፍት', activeStatus: 'ንቁ', normalStatus: 'መደበኛ',
    panicButton: 'አደጋ ቁልፍ', panicActivate: 'አንቃ!', panicWarning: 'የአደጋ ማንቂያ ይላካል',
    welcomeGuestBtn: 'እንኳን ደህና መጡ', welcomeGuestActive: 'የእንግዳ ሁናቴ ንቁ ነው', welcomeGuestTimer: '{n} ደቂቃ ቀሪ', welcomeGuestCancel: 'የእንግዳ ሁናቴ ሰርዝ', welcomeGuestHint: 'ለእንግዳ ደህንነትን ያጠፋል · ራሱን ያስቀምጣል',
    welcomeGuestChoose: 'የጉብኝት ጊዜ ይምረጡ', guestOptShort: 'አጭር ጉብኝት', guestOptMedium: 'መደበኛ ጉብኝት', guestOptLong: 'ረጅም ጉብኝት', guestMinutes: 'ደቂቃ',
    chooseBrand: 'ብራንድ ምረጡ', pairingSteps: 'የማጣመር ደረጃዎች',
    allCameras: 'ሁሉም ካሜራዎች', liveLabel: 'ቀጥታ', offlineLabel: 'ከስርዓት ውጭ', deviceOn: 'ኦን', deviceOff: 'ኦፍ', deleteAll: 'ሁሉንም ሰርዝ', deleteAllConfirm: 'ሁሉንም መሳሪያዎች ከዝርዝሩ ማስወገድ?',
    addDeviceBtn: 'መሳሪያ ጨምር', notificationsTitle: 'ማሳወቂያዎች',
    timeNow: 'አሁን', timeMinAgo: 'ከ{n} ደቂቃ በፊት', timeHrAgo: 'ከ{n} ሰዓት በፊት', timeDayAgo: 'ከ{n} ቀን በፊት', deviceConnectedFmt: 'መሣሪያ ተገናኝቷል: {name}',
    camFrontDoor: 'የፊት በር', camBackDoor: 'የኋላ በር', camGarage: 'ጋራዥ', camBackyard: 'የኋላ ግቢ', camEntrance: 'መግቢያ', camDriveway: 'የመኪና መንገድ', camBalcony: 'በረንዳ',
    autoMotionNight: 'በእንቅስቃሴ የሌሊት መብራት', autoArrive: 'ወደ ቤት መድረስ', autoMorning: 'እንደምን አደሩ', autoEnergySave: 'ኢነርጂ ቁጠባ',
    condMotionNight: 'በሌሊት እንቅስቃሴ (21:00–06:00)', condNobodyHome: 'ቤት ውስጥ ማንም ከሌለ', condArrive: 'ወደ ቤት ሲደርሱ', condTime2300: 'በ23:00', condMorningWeekday: 'በ07:00 በስራ ቀናት', condNoMotion30: 'ለ30 ደቂቃ እንቅስቃሴ ከሌለ',
    actAllLightsOn: 'ሁሉንም መብራቶች አብራ', actAlarmOffAll: 'ማንቂያ አስነሳ + ሁሉንም አጥፋ', actLightsAlarmOff: 'መብራቶች አብራ + ማንቂያ አጥፋ', actOffLock: 'ሁሉንም አጥፋ + በሮች ቆልፍ', actBlindsCoffee: 'መጋረጃ ክፈት + ቡና አብራ', actOffLightsAc: 'መብራቶችና ኤሲ አጥፋ',
    catSmoke: 'ጭስ', catEnergy: 'ኢነርጂ', actionTurnOn: 'አብራ', actionTurnOff: 'አጥፋ',
    cyberNoEvents: 'የቅርብ ጊዜ ክስተቶች የሉም', cyberNetworkMap: 'የአውታረ መረብ ካርታ', cyberNetworkTopology: 'የአውታረ መረብ ቶፖሎጂ', cyberPhones: 'ስልኮች', cyberOnlineFmt: '{on} / {total} ተገናኝቷል',
    homeTypeLabels: const ['ቤት','አፓርትመንት','ቪላ','ጎጆ','ካቢን','ግንብ','ፔንትሀውስ','እርሻ','ማሳ','ጀልባ'],
    homeColorLabels: const ['ሰማያዊ','ወይን ጠጅ','አረንጓዴ','ብርቱካን','ወርቃማ','ቀይ','ቱርኳዝ','ሮዝ','ቡናማ','ግራጫ'],
    homeTypeTitle: 'የቤት ዓይነት', homeColorTitle: 'ቀለም', colorMix: 'ቀለም ቅልቅል', pickLabel: 'ምረጥ',
    profilePhotoFmt: 'የመገለጫ ፎቶ — {name}', inviteSubject: 'ወደ ብልህ ቤቴ ለመቀላቀል ግብዣ', inviteBodyFmt: 'ሰላም፣\n\nበFantaTech መተግበሪያ በኩል ወደ ብልህ ቤቴ እንዲቀላቀሉ እጋብዛለሁ።\n\nየመቀላቀያ ኮድ: {code}\n\nመተግበሪያውን አውርደው ኮዱን አስገብተው ይቀላቀሉ።', noEmailApp: 'በመሣሪያው ላይ የኢሜል መተግበሪያ አልተገኘም', regManagerMsg: 'እንደ ቤት አስተዳዳሪ ተመዝግበዋል!', nameFieldFmt: 'ስም: {name}', homeJoinTitle: 'የቤት መቀላቀያ ኮድ', shareCodeHint: 'ኮዱን ከቤተሰብ አባላት ጋር ያጋሩ\nእንዲቀላቀሉ', gotIt: 'ገባኝ', homeStyleTitle: 'የቤት ዘይቤ', registerAsFmt: 'እንደ ይመዝገቡ: {name}', newCodeFmt: 'አዲስ ኮድ ተፈጥሯል: {code}', joinCodeInline: 'የቤት መቀላቀያ ኮድ:  ', inviteByEmail: 'አባል በኢሜል ይጋብዙ', inviteByEmailSub: 'የመቀላቀያ ኮዱን በቀጥታ በኢሜል ይላኩ',
    tailscaleWhat: 'Tailscale ምንድን ነው?', tailscaleDesc: 'ለቤትዎ አውታረ መረብ የርቀት መዳረሻ ነፃ VPN።\nውጭ ሲሆኑም ስልክዎን ከቤት አውታረ መረብ ጋር በተመሰጠረ መንገድ ያገናኛል።', tailscaleStep1: 'Tailscale በስልክዎና በRaspberry Pi / HA Green ላይ ይጫኑ', tailscaleStep2: 'በተመሳሳይ መለያ ይግቡ (Google / Apple / Email)', tailscaleStep3: 'ቶግሉን ያብሩ — መተግበሪያው Tailscale ይከፍታል', tailscaleOpen: 'Tailscale ክፈት / ጫን',
    camScanNetwork: 'አውታረ መረብ ቃኝ', camScanning: 'በመቃኘት ላይ...', camAddManual: 'ካሜራ በእጅ ጨምር', camFieldName: 'ስም', camPort: 'ፖርት', camUser: 'ተጠቃሚ', camRtspPath: 'የRTSP መንገድ', camStreamPath: 'የዥረት መንገድ', camRtspHint: '/  ወይም  /cam/realmonitor?channel=1', camPtzTitle: 'PTZ ካሜራ', camPtzSub: 'Pan / Tilt / Zoom ቁጥጥር አንቃ', camTestConn: 'ግንኙነት ሞክር', camAddBtn: 'ካሜራ ጨምር', camFoundFmt: '✓ ካሜራ ተገኝቷል! {info} — ክፍት ፖርቶች: {ports}', camConnectFailFmt: '✗ ከ{addr} ጋር መገናኘት አልተቻለም',
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
    aiInputHint: 'ተፃፍ ወይም ተናገር', aiMicUnavailable: 'ማይክሮፎን አይገኝም',
    aiSug1: 'ሁሉም መብራቶች አጥፋ',
    aiSug2: 'የቤቱ ሁኔታ ምንድን ነው?',
    aiSug3: 'የሌሊት ሁነታ አንቃ',
    aiSug4: 'ንቁ ማስጠንቀቂያዎች አሉ?',
    aiSugDesc1: 'በቤቱ ውስጥ ያሉትን ሁሉንም መብራቶች ማጥፋት እችላለሁ',
    aiSugDesc2: 'ስለ ቤቱ እና ስርዓቶቹ ሙሉ ማጠቃለያ ያግኙ',
    aiSugDesc3: 'ሁሉንም የሌሊት ሁነታ ቅንብሮች አበራለሁ',
    aiSugDesc4: 'ማስጠንቀቂያዎችን እና ያልተለመዱ ሁኔታዎችን ይፈትሹ',
    aiPrivacyNote: 'መረጃዎ ግላዊ እና የተጠበቀ ነው', aiClearChat: 'ውይይት አጽዳ',
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
    deviceWillBeRemoved: 'መሣሪያው ከዝርዝሩ ይወገዳል', haRemoveDeviceFailed: 'ከዝርዝሩ ተወግዷል፣ ግን ከHome Assistant መሰረዝ አልተቻለም', ipAddressLabel: 'IP አድራሻ',
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
    scanBarcode: 'ባርኮድ / QR ቅኝ', editUserName: 'የተጠቃሚ ስም ያርትዑ', searchScanProducts: 'ምርቶችን በአውታረ መረብ ይቃኙ',
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
    roomNameLiving: 'መኖሪያ ክፍል', roomNameKitchen: 'ወጥ ቤት', roomNameBedroom: 'መኝታ ክፍል',
    roomNameKids: 'የልጆች ክፍል', roomNameGarden: 'ሜዳ', roomNameBathroom: 'መታጠቢያ',
    roomNameStorage: 'ማከማቻ', roomNameAc: 'ኤሲ',
    rememberMe: 'አስታውሰኝ',
    notConnectedLabel: 'አልተገናኘም', solarTitle: 'የፀሐይ ስርዓት', solarProduction: 'ምርት', solarConsumption: 'ፍጆታ',
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
    assignRoom: 'ክፍል ይምደቡ', noRoom: 'ክፍል የለም', newRoom: 'አዲስ ክፍል…',
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
    keepShabbatLabel: 'ሸባትን መጠበቅ', shabbatSection: 'ሸባት',
    shabbatCandlesDesc: 'ሁሉንም ✡️ አጥፋ እና ሸባት በፊት ደጆቹን ቆልፍ',
    shabbatHavdalahDesc: 'ሸባት ካለቀ በኋላ መሳሪያዎቹን መልስ',
    acConnected: 'ማቀዝቀዣዎች ተገናኝተዋል', acNoUnits: 'ምንም ማቀዝቀዣ አልተገናኘም',
    adStoreLabel: 'FantaTech ሱቅ', adTrackTitle: 'የማስታወቂያ ቅንብሮች',
    adTrackSub: 'ምን ምርቶች በባነር ላይ ይታዩ',
    adFeaturedLabel: 'ምርጥ ምርቶች', adFeaturedSub: 'Hub Pro, Camera 4K, Smart Bulb, Sensor',
    adNewLabel: 'አዲስ ምርቶች', adNewSub: 'Smart Blind, Smart Plug 16A, Gateway, LED Strip',
    adAllLabel: 'ሁሉም ምርቶች', adAllSub: 'ሙሉ ዝርዝር',
    adNoneLabel: 'ማስታወቂያ የለም', adNoneSub: 'ባነሩን ደብቅ',
    autoThemeLabel: 'ራስ-ሰር ቅርጸ-ቀለም', autoThemeDesc: 'ለአካባቢ ብርሃን ይስማማል',
    autoThemeActive: 'ንቁ', autoThemeWaiting: 'ሴንሰር ይጠብቃል…',
    homeLayoutLabel: 'የቤት ስክሪን አቀማመጥ',
    signOutAppTitle: 'ከመተግበሪያ ውጡ', signOutChoose: 'እንዴት ለመውጣት ይምረጡ',
    signOutToLogin: 'ወጥቶ ወደ መግቢያ ይመለሱ', signOutToLoginSub: 'መለያ ያቋርጣል — ዳግም መግቢያ ይፈልጋል',
    signOutFull: 'ሙሉ ውጣ', signOutFullSub: 'ወጥቶ ይዘጋል',
    accountSection: 'መለያ',
    switchAccountTitle: 'መለያ ቀይር', switchAccountSub: 'ውጣና በሌላ መለያ ግባ',
    switchAccountConfirmTitle: 'መለያ መቀየር?', switchAccountConfirmBody: 'ትወጣለህ እና ወደ መግቢያ ማያ ትመለሳለህ።',
    switchAccountConfirmBtn: 'መለያ ቀይር', switchAccountPasswordPrompt: 'ለማረጋገጥ የይለፍ ቃልዎን ያስገቡ',
    switchAccountWrongPassword: 'የተሳሳተ የይለፍ ቃል',
    installerBadge: 'ተካይ', installerCodeTitle: 'የተካይ ሁነታ',
    installerCodeHint: 'የተካይ ኮድ ያስገቡ', installerCodeWrong: 'የተሳሳተ የተካይ ኮድ',
    installerModeOnMsg: 'የተካይ ሁነታ ነቅቷል', installerModeOffMsg: 'የተካይ ሁነታ ተዘግቷል',
    installerExitConfirm: 'ከተካይ ሁነታ ይውጡ?',
    deviceOfflineHint: 'መሣሪያው ከመስመር ውጭ ነው — ግንኙነቱን ያረጋግጡ',
    aiBackendNotConfigured: 'የ AI ረዳት ገና አልተዋቀረም',
    aiRequestFailed: 'ይቅርታ፣ አሁን ረዳቱን ማግኘት አልቻልኩም',
    aiEmptyReply: 'ተከናውኗል።',
    aiTooManySteps: 'ይህ ጥያቄ ብዙ ደረጃዎችን ይፈልጋል — ቀላል ነገር ይሞክሩ',
    mirrorScreenTitle: 'ብልህ መስታወት', adBannerShop: 'ሱቅ',
    confirm: 'አረጋግጥ', pickDay: 'ቀን', pickMonth: 'ወር',
    pickHebrewDate: 'የዕብራይስጥ ቀን ምረጥ',
    hebrewDateFmt: 'የዕብራይስጥ: {date}', hebrewCalendarChip: 'የዕብራይስጥ ቀን…',
    storeBuyAt: 'ይግዙ ',
    loginBiometric: 'በጣት አሻራ / ፊት ይግቡ',
    errInvalidEmail: 'ልክ ያልሆነ ኢሜይል',
    loginGoogleEmailPrompt: 'Gmail ያስገቡ ለመቀጠል',
    scanNetworkTitle: 'አውታር ፈልግ', scanSelectDevice: 'ለማስገባት መሳሪያ ምረጥ',
    stop: 'አቁም', scanSensorsShutters: 'ሴንሰሮች · መጋረጃዎች',
    sensorHubTitle: 'ሴንሰሮች እና መጋረጃዎች',
    sensorHubFoundFmt: '{sensors} ሴንሰሮች · {covers} መጋረጃዎች',
    sensorsTab: 'ሴንሰሮች', shuttersTab: 'መጋረጃዎች',
    noSensorsFound: 'ሴንሰሮች አልተገኙም', noCoversFound: 'መጋረጃዎች አልተገኙም',
    coverOpen: '▲  ክፈት', coverStop: '■  አቁም', coverClose: '▼  ዝጋ',
    switchScanningAll: 'ሁሉንም ፕሮቶኮሎች በማስስ…',
    switchAddedFmt: '✓ {name} ወደ ቤት ተጨምሯል',
    keyStoredLocal: 'ቁልፍ በመሳሪያዎ ብቻ ተቀምጧል።',
    saveAndControl: 'ያስቀምጡ እና ይቆጣጠሩ',
    tapoLogin: 'Tapo — ግባ',
    tapoCredHint: 'TP-Link Tapo መተግበሪያ ዳታ ይጠቀሙ።',
    connectAndControl: 'አገናኝ እና ቆጣጠር',
    errControlFmt: '{name} ቁጥጥር ስህተት',
    switchSearchingAll: 'ሁሉንም ፕሮቶኮሎች ማስስ…',
    switchNoFound: 'ብልህ ማብሪያዎች አልተገኙም',
    switchHint: 'ማብሪያዎቹ ከዚሁ WiFi ጋር መገናኘታቸውን ያረጋግጡ።\nShelly/ESPHome — STA ሁነታ\nSonoff — DIY ሁነታ (firmware 3.6+)\nHome Assistant / Zigbee2MQTT — በቅንብሮች ያገናኙ',
    camFrameCaptureError: 'ፍሬም ለማንሳት ስህተት',
    camNoFaces: 'ፊቶች አልተለዩም', camFacesFoundFmt: '{count} ፊቶች ተለዩ — {known} ይታወቃሉ 🎯',
    camFacesOnlyFmt: '{count} ፊቶች ተለዩ 🎯', camAnalysisErrorFmt: 'ትንተና ስህተት: {error}',
    camCaptureError: 'ለማንሳት ስህተት',
    camSnapshotSavedFmt: '📸 ተቀምጧል: snapshot_{ts}.png',
    camSaveSnapshotError: 'ስዕልን ለማስቀመጥ ስህተት',
    camConnectingFmt: '{name} ጋር በማገናኘት...',
    camIdentifyingFaces: 'ፊቶች እና ማንነቶች በመለየት...',
    camDetectingFaces: 'ፊቶች በመለየት...',
    camFaceLabelFmt: 'ፊት {n}', camStreamConnFailed: 'ስትሪም ማገናኘት አልተቻለም',
    addWizBulb: 'WiZ ሊምፕ ጨምር',
    addWizBulbSub: 'LAN ቁጥጥር · ክላውድ የለም',
    deviceNotFoundStatus: 'መሳሪያ አልተገኘም', manualAddStatus: 'ቀጥታ ጨምር',
    connecting: 'በማገናኘት...',
    deviceNotFoundHint: 'መሳሪያው ከኃይል እና WiFi ጋር መገናኘቱን ያረጋግጡ,\nወይም Bluetooth ይክፈቱ።',
    manualAddLabel: 'ቀጥታ ጨምር', deviceNameLabel: 'የመሳሪያ ስም', deviceDeleteConfirm: 'ይህን መሳሪያ ከመተግበሪያው ማስወገድ?',
    ipAddressOptional: 'IP አድራሻ (አማራጭ)', back: 'ተመለስ',
    faceConfigured: '✓ ተዋቅሯል', faceIdTitle: 'የፊት መለያ',
    faceIdSubtitle: 'ለራስ-ሰር ልየታ ሰዎችን ተመዝግቡ',
    faceTraining: 'ሞዴል በማሠልጠን...', faceTrainModelFmt: 'ሞዴል በማሠልጠን ({enrolled}/{total} ተመዝግበዋል)',
    facePrepGroup: 'ቡድን በማዘጋጀት...', faceTrainStartFailed: '❌ ሥልጠና ለመጀምር አልተቻለም',
    faceTrainingProgress: 'በሥልጠና... (እስከ 60 ሰከንድ ሊወስድ ይችላል)',
    faceTrainSuccess: '✅ ሞዴል ሥልጠና ተሳካ! ልየታ ንቁ ነው።',
    faceTrainFailed: '❌ ሥልጠና አልተሳካም። እንደገና ሞክሩ።',
    faceSetAzureKeyFirst: 'Azure API ቁልፍ አስቀድሞ ጨምር',
    faceAddingPhoto: 'ፎቶ ወደ Azure በማስጨመር...',
    faceCreateRecordError: '❌ Azure ላይ መዝገብ ለመፍጠር ስህተት',
    faceFaceNotDetected: '❌ በዚህ ፎቶ ፊት ለመለየት አልተቻለም',
    facePhotoAddedFmt: '✅ ፎቶ ወደ {name} ተጨምሯል። ሞዴሉን ያሠልጥኑ።',
    faceNotConfiguredTap: 'አልተዋቀረም — ለማዋቀር ይንኩ',
    faceCheckConnection: 'ግንኙነት ያረጋግጡ',
    faceGetFreeApiKey: 'portal.azure.com → Cognitive Services ነፃ API ቁልፍ ያግኙ',
    faceSaveSettingsFirst: '⚠️ አስቀድሞ ቅንብሮችን ያስቀምጡ',
    faceAzureConnOk: '✅ Azure ግንኙነት ተሳካ!',
    faceAzureConnFailed: '❌ ለማገናኘት አልተቻለም። Endpoint + Key ያረጋግጡ',
    faceEnrolledAzure: '✓ Azure ላይ ተመዝግቧል', faceNotEnrolled: '⚠ አልተመዘገበም — ፎቶ ጨምር',
    faceAddPerson: 'ሰው ጨምር', faceFullNameHint: 'ሙሉ ስም',
    faceEnterName: 'ስም ያስገቡ', faceCreatingRecord: 'መዝገብ በመፍጠር...',
    faceNoPeople: 'የተመዘገቡ ሰዎች የሉም',
    faceNoPeopleHint: 'ካሜራዎቹ ስማቸውን እንዲያውቁ ሰዎችን ጨምሩ',
    roomSettings: 'የክፍል ቅንብሮች', capComingSoonFmt: '{cap} — ብዙ ሳይቆይ',
    householdNoAdmin: 'አስተዳዳሪ እስካሁን የለም',
    householdMemberNote: 'አስተዳዳሪው Google ወይም Apple ሲጠቀሙ አባልነት ይችላሉ።',
    backToLogin: 'ወደ ግቢ ተመለስ', householdAdmin: 'የቤት አስተዳዳሪ',
    selectProfile: 'መገለጫ ምረጥ', noMembersYet: 'አባሎች እስካሁን የሉም',
    addMembersHint: 'አስተዳዳሪው ከመገለጫ → ቤት አስተዳደር አባሎችን ማስጨመር ይችላሉ።',
    switchScanProgressFmt: 'በማስስ... {n} / 254',
    switchNoDevicesHint: 'መሳሪያዎች አልተገኙም። ከዚሁ WiFi ጋር መገናኘታቸውን ያረጋግጡ',
    scanDoneFmt: 'ፍተሻ ተጠናቋል — {n} መሳሪያዎች', scanWifi: 'WiFi ፈልግ',
    faceAnalysisTitle: 'የፊት ትንተና', faceAnalysisSubtitle: 'የካሜራ ፍተሻ ታሪክ',
    clear: 'አጽዳ', clearHistory: 'ታሪክ አጽዳ',
    clearHistoryConfirm: 'ሁሉንም የትንተና ውጤቶች ይሰርዙ?',
    statScans: 'ፍተሻዎች', statFacesDetected: 'የተለዩ ፊቶች',
    statAlerts: 'ማንቂያዎች', faces: 'ፊቶች', smiling: 'ፈገግ ያሉ', eyesClosed: 'ዝግ ዓይኖች',
    noFacesInFrame: 'በዚህ ፍሬም ፊቶች አልተለዩም', noAnalysesYet: 'ትንተና እስካሁን የለም',
    faceAnalysisHint: 'ካሜራ ከፍቶ "ተንትን" ይንኩ ለፊት ልየታ',
    smartHomeTitle: 'ብልህ ቤት',
    temperatureFmt: 'ሙቀት: {n}°C', brightnessFmt: 'ብርሃን: {n}%', positionFmt: 'ቦታ: {n}%',
    wizIdentifyingWifi: 'WiFi በመለየት…', wizNoWifi: 'WiFi የለም — IP ቀጥታ ያስገቡ',
    wizBroadcastingFmt: '{prefix}.x ላይ በማሰራጨት …',
    wizNoFound: 'WiZ ሊምፖች አልተገኙም — ቀጥታ ሞክሩ',
    wizFoundFmt: '{n} ሊምፖች ተገኙ', wizScanFailed: 'ፍተሻ አልተሳካም — ቀጥታ ሞክሩ',
    wizBlinkingFmt: '{ip} ብልጭ እያለ …', wizBlinkSentFmt: '{ip} ወደ ብልጭ ተልኳል ✓',
    wizNoResponseFmt: '{ip} ምላሽ የለም - ሊምፑ ከአውታር ጋር መገናኘቱን ያረጋግጡ',
    wizDeviceAddedFmt: '{name} ተጨምሯል — ቁጥጥር ንቁ ነው',
    wizManualAdd: 'IP በቀጥታ ጨምር', wizTest: 'ሙከራ',
    gatewayHubTitle: 'ድልድዮች እና ሃቦች',
    gatewayHubSubtitle: 'Zigbee, Z-Wave, WiFi እና ክላውድ ሃቦች ያገናኙ',
    connected: 'ተገናኝቷል', addGateway: 'ድልድይ ጨምር', gatewayTypesFmt: '{n} አይነቶች',
    devicesImportedFmt: '{n} መሳሪያዎች ከ {name} ተጨምረዋል',
    allDevicesExist: 'ሁሉም መሳሪያዎች ቀደም ብለው አሉ',
    diagnosisTitle: 'ሃቡ የሚዘግባቸው መሳሪያዎች',
    disconnectConfirmFmt: '"{name}" ያላቋርጡ?',
    importedDevicesNote: 'ጨምሮ የነበሩት ይቆያሉ፤ ነገር ግን ተጨማሪ ማምጣት አይቻልም።',
    disconnect: 'ያቋርጡ', deviceCountFmt: '{n} መሳሪያዎች',
    importDevices: 'መሳሪያዎች አምጡ', connect: 'አገናኝ',
    connectAfterButton: 'አገናኝ (ቁልፍ ከተጫኑ በኋላ)',
    connectedSuccess: 'በተሳካ ሁኔታ ተገናኝቷል!',
    secondsRemainingFmt: '{n} ሰከንዶች ቀርቷቸዋል', cloud: 'ክላውድ',
    cloudConnectionNote: 'ክላውድ ግንኙነት — ውሂብ በአምራቹ አገልጋዮች ያልፋል',
    setupStepsHintFmt: 'ዝርዝሮቹን እንዴት ማግኘት ይቻላል? ({n} ደረጃዎች)',
    tokenPortalFmt: 'Token በ {name} ፖርታል ተፈጠረ', optional: 'አማራጭ',
    z2mEnterIp: 'Zigbee2MQTT IP ያስገቡ',
    z2mUnreachableFmt: 'Zigbee2MQTT ወደ {ip}:{port} ለመድረስ አልተቻለም\nFrontend ንቁ እና IP ትክክል መሆኑን ያረጋግጡ',
    z2mUnknownError: 'ያልታወቀ ስህተት',
    z2mSubtitle: 'Zigbee ሃብ ያገናኙ — መሳሪያዎችን ያምጡ',
    z2mIpLabel: 'Z2M IP', z2mIpHint: 'ምሳሌ: 192.168.1.50',
    z2mPortLabel: 'ፖርት', z2mTokenLabel: 'API Token (አማራጭ)',
    z2mTokenHint: 'ከተዋቀረ', z2mFoundFmt: '{n} Zigbee መሳሪያዎች ተገኙ!',
    z2mConnectImport: 'አገናኝ እና አምጡ',
    z2mFrontendHelp: 'Z2M ቅንብሮች ውስጥ frontend ያስቃኑ:\n  frontend:\n    port: 8080',
    discoveryTitle: 'መሳሪያዎችን ፈልግ', scan: 'ፍለጋ',
    matterDeviceTitle: 'Matter መሳሪያ',
    matterDeviceHelp: 'Matter መሳሪያዎች (IKEA ሊምፖች) ቀጥታ ሳይሆን Matter ሃብ በኩል ይገናኛሉ።\n\nቀላል መንገድ:\n1. ሊምፑን ከ DIRIGERA IKEA Home smart app ጋር ያዋሃዱ።\n2. እዚህ: ድልድዮች → DIRIGERA → "መሳሪያዎች አምጡ".\nሊምፑ ሙሉ ቁጥጥር ጋር ይታያል።',
    understood: 'ገብቶኛል', devicesAddedFmt: '{n} መሳሪያዎች ተጨምረዋል',
    haFound: 'Home Assistant ተገኘ',
    haConnectedFmt: 'ተገናኝቷል — {n} መሳሪያዎች ተምጥተዋል',
    haConnect: 'አገናኝ',
    haReconnectSync: 'እንደገና አገናኝ እና አሳምን',
    haTokenHint: 'Token ፍጠር: Profile → Long-Lived Access Tokens',
    importFromHa: 'ከ Home Assistant መሳሪያዎች አምጡ',
    scanningDevices: 'መሳሪያዎችን በመፈለግ…',
    scanHint: '"ፍለጋ" ተጫኑ ለአውታሩ ፍተሻ',
    addAllFmt: 'ሁሉ ጨምር ({n} መሳሪያዎች)',
    matterCommTitle: 'Matter ያዋሃዱ', matterCommSubtitle: 'የመሳሪያ QR ያስቃኙ',
    matterCommScanBtn: 'QR ፍለጋ', matterCommManualBtn: 'ኮድ ቀጥታ ያስገቡ',
    matterCommManualHint: '11 ቁጥሮች (ምሳሌ 12345-67890)',
    matterCommissioning: 'Home Assistant ያዋሃዱ…',
    matterCommSuccess: 'መሳሪያ በተሳካ ሁኔታ ተዋሃደ!',
    matterCommFailed: 'ማዋሃድ አልተሳካም። Matter HA ላይ ንቁ መሆኑን ያረጋግጡ።',
    matterCommNoHa: 'Home Assistant አልተገናኘም። HA ያገናኙ።',
    matterCommRetry: 'እንደገና ሞክሩ',
    matterCommCodeHint: 'MT:… ወይም 11 ቁጥሮች',
    blindsHubTitle: 'መጋረጃዎች', openAll: 'ሁሉ ክፈት', closeAll: 'ሁሉ ዝጋ',
    noBlindsFound: 'መጋረጃዎች አልተገኙም',
    blindsHint: 'Home Assistant አማካኝነት መጋረጃዎች ይጨምሩ',
    smartLocksTitle: 'ብልህ መቆለፊያዎች', lockedStatus: 'ተቆልፏል', unlockedStatus: 'ተከፍቷል',
    lockAll: 'ሁሉ ቆልፍ', unlockAll: 'ሁሉ ክፈት',
    noLocksFound: 'መቆለፊያዎች አልተገኙም',
    lockHint: 'Home Assistant አማካኝነት ብልህ መቆለፊያ ይጨምሩ',
    lightsHubTitle: 'ብርሃኖች', lightsAllOn: 'ሁሉ ኦን', lightsAllOff: 'ሁሉ ኦፍ',
    noLightsFound: 'ብርሃኖች አልተገኙም',
    lightsHint: 'Home Assistant አማካኝነት ብርሃኖች ይጨምሩ',
    plugsHubTitle: 'ብልህ ሶኬቶች', plugsAllOn: 'ሁሉ ኦን', plugsAllOff: 'ሁሉ ኦፍ',
    noPlugsFound: 'ሶኬቶች አልተገኙም',
    plugsHint: 'WiFi ፍተሻ አማካኝነት ሶኬቶች ይጨምሩ',
    acHubTitle: 'ማቀዝቀዣ',
    intercomTitle: 'ኢንተርኮም', intercomNoDevices: 'ምንም የኢንተርኮም መሳሪያ አልተገኘም',
    intercomHint: 'በካታሎግ ወይም ጌትዌይ ኢምፖርት ኢንተርኮም ይጨምሩ',
    intercomRing: 'ደውል', intercomAnswer: 'መልስ', intercomDecline: 'አቋርጥ',
    intercomCategory: 'የቪዲዮ ደወል', intercomRinging: 'በሩ ላይ ሰው አለ…',
    vacuumCategory: 'ሮቦት ጠራጊ', vacuumNoDevices: 'ምንም ሮቦት ጠራጊ አልተገኘም',
    vacuumHint: 'ሮቦት ጠራጊዎን በ Home Assistant በኩል ያገናኙ',
    vacuumStart: 'ጀምር', vacuumPause: 'ላፍታ አቁም', vacuumDock: 'ወደ ጣቢያ ተመለስ',
    vacuumCleaning: 'እየጠረገ', vacuumDocked: 'በጣቢያ',
    intercomUnlockDoor: 'በር ክፈት',
    energyRateLabel: 'የኤሌክትሪክ ዋጋ', energyRateEdit: 'ዋጋ አስተካክል',
    energyRateUnit: '₪/kWh', energyRateSaved: 'ዋጋ ተቀምጧል',
    backupTitle: 'ምትኬ እና ማደስ', backupExport: 'ቅንጅቶችን ወደ ውጭ ላክ',
    backupImport: 'ቅንጅቶችን አስገባ', backupExportDone: 'ቅንጅቶች ወደ ውርዶች ተልከዋል',
    backupImportDone: 'ቅንጅቶች በተሳካ ሁኔታ ተመልሰዋል', backupImportError: 'ማስገባት አልተሳካም — ፋይሉ ትክክለኛ አይደለም',
    backupSection: 'ውሂብ እና ምትኬ',
    biometricSplashLabel: 'ያረጋግጡ',
    camLocationPermission: 'አውታረ መረቡን ለመቃኘት የቦታ ፈቃድ ያስፈልጋል',
    camNoWifiIp: 'የ WiFi አውታረ መረብዎን ማወቅ አልቻልንም — ከ WiFi ጋር ይገናኙ እና እንደገና ይሞክሩ፣ ወይም ካሜራውን በእጅ ያክሉ',
    camScanNoneFound: 'በአውታረ መረቡ ላይ ካሜራዎች አልተገኙም። ካሜራዎ ONVIF የማይደግፍ ከሆነ በ IP አድራሻው በእጅ ያክሉት።',
    showHideSections: 'ክፍሎችን አሳይ / ደብቅ', restoreDefaults: 'ነባሪዎችን እንደገና አስጀምር?', restoreDefaultsConfirm: 'ይህ የደህንነት ፓነሉን አቀማመጥ ዳግም ያስጀምራል። ሊቀለበስ አይችልም።', restore: 'እንደገና አስጀምር', systemTest: 'የስርዓት ፈተና',
  );

  // ── Spanish ───────────────────────────────────────────────────
  static const S _es = S(
    homeGreetingSub: 'Tu hogar, seguro e inteligente.', energyToday: 'Energía hoy', vsYesterday: 'vs ayer',
    climateEnergyTitle: 'Clima y energía', homeManagementTitle: 'Gestión del hogar',
    energyAnalytics: 'Análisis de Energía',
    securitySystemLabel: 'Sistema de seguridad', secArmedShort: 'Armado', secDisarmedShort: 'Desarmado', allOkLabel: 'Todo en orden', emergencyBtn: 'Emergencia',
    showAll: 'Ver todo', roomsHeader: 'Habitaciones', statHomesLabel: 'Hogares', devicesUnit: 'dispositivos',
    qaLock: 'Bloquear', qaLights: 'Luces', qaAc: 'Aire', qaCameras: 'Cámaras', qaAlerts: 'Alertas',
    qaPlugs: 'Enchufes', qaWaterHeater: 'Caldera', qaBreakers: 'Panel',
    qaNoDevices: 'Sin dispositivos', qaNoAlerts: 'Sin alertas', qaResetAll: 'Borrar todo', qaScanDevice: 'Buscar dispositivo',
    adAddLink: 'Añadir enlace', adCustomLink: 'Enlace personalizado',
    systemStatus: 'Estado del sistema', statusInternet: 'Internet', statusSensors: 'Sensores', connectedLabel: 'Conectado',
    camMotion: 'Movimiento', camOnline: 'En línea', camOffline: 'Sin conexión', locationUnavailable: 'Ubicación no disponible', gatewaysManage: 'Gestionar', gatewaysTitle: 'Gateways', statusOffline: 'Sin conexión',
    secArmStayBtn: 'Armar (Casa)', secDisarmBtn: 'Desarmar', roomNameMedia: 'Multimedia', mediaRoomTitle: 'Multimedia',
    roomOccupantLabel: '¿Quién usa esta sala?', occupantNone: 'Ninguno', occupantKids: 'Niños', occupantAdults: 'Adultos',
    navHome: 'Inicio', navCameras: 'Cámaras', navSecurity: 'Seguridad', navProfile: 'Perfil', navAutomations: 'Automatizaciones',
    greetingPrefix: 'Hola', homeSecured: 'Tu casa está protegida', homeNotSecured: 'Casa no protegida',
    allSystemsActive: 'Todos los sistemas activos', tapToActivate: 'Toca para activar seguridad',
    alarmTitle: 'Alarma', alarmSecured: 'Protegida', alarmOff: 'Apagada', roomManagement: 'Gestión del Hogar', roomsUnit: 'habitaciones',
    camerasTitle: 'Cámaras', lightsOn: 'luces encendidas', lightingTitle: 'Iluminación',
    tempTitle: 'Temperatura', tempComfy: 'Confortable', aiSubtitle: '¿En qué puedo ayudarte?', aiTopSubtitle: 'El asistente de tu hogar inteligente',
    quickActions: 'Acciones Rápidas', leaveHome: 'Salir de casa', turnOffAll: 'Apagar todo', goodNight: 'Buenas noches', movieMode: 'Modo Película',
    mediaTitle: 'Media', mediaSpeakers: 'Altavoces', mediaScan: 'Buscar dispositivos', mediaNoDevices: 'Sin altavoces. Toca buscar.',
    bioTitle: 'Acceso rápido', bioPrompt: '¿Activar inicio con huella para la próxima vez?', bioEnable: 'Activar', bioSkip: 'Ahora no', bioReason: 'Autentícate para iniciar sesión',
    onbNext: 'Siguiente', onbStart: 'Comenzar', onbSkip: 'Omitir', onbAllow: 'Permitir', onbLater: 'Más tarde', onb1Title: 'Bienvenido a FantaTech', onb1Body: 'Tu hogar inteligente — iluminación, seguridad, clima y energía en un solo lugar.', onb2Title: 'Control total', onb2Body: 'Gestiona cámaras, sensores, interruptores y detectores desde cualquier lugar.', onb3Title: 'Automatizaciones', onb3Body: 'Crea escenas, ahorra energía y recibe alertas en tiempo real.', onbPermTitle: 'Permisos para descubrir dispositivos', onbPermBody: 'Para encontrar dispositivos en tu red necesitamos Ubicación y Bluetooth. Tus datos permanecen solo en tu dispositivo.',
    secSection: 'Seguridad', bioLoginLabel: 'Inicio con huella', bioLoginSub: 'Inicia sesión rápido con biometría', bioUnavailable: 'El dispositivo no admite biometría', legalSection: 'Legal y Privacidad', termsLabel: 'Términos de servicio', privacyLabel: 'Política de privacidad',
    sceneCreate: 'Crear escena', sceneNew: 'Nueva escena', sceneName: 'Nombre de escena', sceneActions: 'Acciones', actPlugs: 'Enchufes', valKeep: 'Sin cambio', valOn: 'Encender', valOff: 'Apagar',
    authEmailHint: 'Correo o teléfono', authPassHint: 'Contraseña', loginGreeting: '¡Hola!', loginSubtitle: 'Inicia sesión en tu cuenta', loginForgot: '¿Olvidaste la contraseña?', resetEmailHint: 'Ingresa tu correo y te enviaremos un enlace para restablecer.', resetEmailSent: '¡Enlace enviado! Revisa tu bandeja de entrada.', okButton: 'Aceptar', cancelButton: 'Cancelar', sendButton: 'Enviar', loginButton: 'Iniciar sesión', authOr: 'o', loginNoAccount: '¿No tienes cuenta?', registerNow: 'Regístrate', continueAsGuest: 'Continuar como invitado', loginWith: 'Iniciar sesión con', appTagline: 'Soluciones de hogar inteligente y seguridad', registerTitle: 'Crear cuenta', registerSubtitle: 'Únete al hogar inteligente FantaTech', confirmPassHint: 'Confirmar contraseña', registerButton: 'Registrarse', haveAccount: '¿Ya tienes cuenta?', loginHousehold: 'Miembro del hogar',
    errEnterName: 'Ingresa tu nombre completo', errEnterEmail: 'Ingresa correo o teléfono', errPassShort: 'La contraseña debe tener al menos 6 caracteres', errPassMismatch: 'Las contraseñas no coinciden',
    acMode: 'Modo', acFanSpeed: 'Ventilador', acSwing: 'Oscilación', acPreset: 'Preajuste', acMethod: 'Control', modeCool: 'Frío', modeHeat: 'Calor', modeFan: 'Ventilador', modeDry: 'Seco', modeAuto: 'Auto', fanLow: 'Bajo', fanMed: 'Medio', fanHigh: 'Alto',
    mediaMaster: 'Volumen general', mediaParty: 'Reproducir en todos', mediaStopAll: 'Detener todo',
    tvRemote: 'Control TV', tvSource: 'Fuente', tvChannel: 'Canal', tvMute: 'Silenciar',
    faq1Q: '¿Cómo añadir un dispositivo?', faq1A: 'Toca + en el panel y elige el dispositivo del catálogo.', faq2Q: '¿Cómo cambiar el idioma?', faq2A: 'Perfil → Ajustes → Idioma.', faq3Q: '¿Funciona sin internet?', faq3A: 'Los comandos locales funcionan. La nube requiere internet.', faq4Q: '¿Cómo crear una automatización?', faq4A: 'Toca "Automatizaciones" en el menú inferior → Añadir.',
    energyTitle: 'Consumo de energía', automationsTitle: 'Automatizaciones', activeAutomations: 'automatizaciones activas',
    myProfile: 'Mi Perfil', myHome: 'Mi Casa', usersTitle: 'Usuarios',
    subscriptionTitle: 'Suscripción', settingsTitle: 'Configuración', helpTitle: 'Ayuda',
    signOut: 'Cerrar sesión', languageLabel: 'Idioma', themeLabel: 'Tema',
    darkMode: 'Oscuro', lightMode: 'Claro', appearanceTitle: 'Apariencia', themeFont: 'Fuente', themeAccent: 'Color principal', themeBg: 'Fondo', themeRadius: 'Bordes', themeBgDarkBlue: 'Azul oscuro', themeBgAmoled: 'Negro AMOLED', themeBgDarkGray: 'Gris oscuro', themeBgLightGray: 'Azul claro', themeBgLightWhite: 'Blanco puro', themeRadiusSharp: 'Recto', themeRadiusNormal: 'Normal', themeRadiusRound: 'Redondeado', saveChanges: 'Guardar cambios',
    editProfile: 'Editar perfil', fullName: 'Nombre completo', emailLabel: 'Correo electrónico',
    profileUpdated: 'Perfil actualizado', signOutConfirm: 'Cerrar sesión', signOutQuestion: '¿Cerrar sesión?', confirmSignOut: 'Salir',
    securityTitle: 'Seguridad', armedMode: 'Armado', disarmedMode: 'Desarmado',
    doorSensor: 'Puerta principal', windowsSensor: 'Ventanas', motionSensors: 'Sensores de movimiento', smokeDetector: 'Detector de humo', waterLeakSensor: 'Sensor de fuga de agua',
    securedStatus: 'Protegido', openStatus: 'Abierto', activeStatus: 'Activo', normalStatus: 'Normal',
    panicButton: 'Botón de pánico', panicActivate: '¡Activar!', panicWarning: 'Esto enviará una alerta de emergencia',
    welcomeGuestBtn: 'Bienvenido Invitado', welcomeGuestActive: 'Modo invitado activo', welcomeGuestTimer: '{n} min restantes', welcomeGuestCancel: 'Cancelar modo invitado', welcomeGuestHint: 'Desactiva la seguridad para invitado · se reactiva solo',
    welcomeGuestChoose: 'Elegir duración de visita', guestOptShort: 'Visita corta', guestOptMedium: 'Visita estándar', guestOptLong: 'Visita larga', guestMinutes: 'min',
    chooseBrand: 'Elegir marca', pairingSteps: 'Pasos de emparejamiento',
    allCameras: 'Todas las cámaras', liveLabel: 'EN VIVO', offlineLabel: 'Sin conexión', deviceOn: 'Encendido', deviceOff: 'Apagado', deleteAll: 'Eliminar todo', deleteAllConfirm: '¿Eliminar todos los dispositivos?',
    addDeviceBtn: 'Agregar dispositivo', notificationsTitle: 'Notificaciones',
    timeNow: 'ahora', timeMinAgo: 'hace {n} min', timeHrAgo: 'hace {n} h', timeDayAgo: 'hace {n} d', deviceConnectedFmt: 'Dispositivo conectado: {name}',
    camFrontDoor: 'Puerta principal', camBackDoor: 'Puerta trasera', camGarage: 'Garaje', camBackyard: 'Patio trasero', camEntrance: 'Entrada', camDriveway: 'Entrada de coches', camBalcony: 'Balcón',
    autoMotionNight: 'Luz nocturna por movimiento', autoArrive: 'Llegada a casa', autoMorning: 'Buenos días', autoEnergySave: 'Ahorro de energía',
    condMotionNight: 'Movimiento de noche (21:00–06:00)', condNobodyHome: 'Si no hay nadie en casa', condArrive: 'Al llegar a casa', condTime2300: 'A las 23:00', condMorningWeekday: 'A las 07:00 entre semana', condNoMotion30: 'Si no hay movimiento durante 30 min',
    actAllLightsOn: 'Encender todas las luces', actAlarmOffAll: 'Armar alarma + apagar todo', actLightsAlarmOff: 'Luces encendidas + desarmar', actOffLock: 'Apagar todo + cerrar puertas', actBlindsCoffee: 'Abrir persianas + preparar café', actOffLightsAc: 'Apagar luces y aire',
    catSmoke: 'Humo', catEnergy: 'Energía', actionTurnOn: 'Encender', actionTurnOff: 'Apagar',
    cyberNoEvents: 'Sin eventos recientes', cyberNetworkMap: 'Mapa de red', cyberNetworkTopology: 'Topología de red', cyberPhones: 'Teléfonos', cyberOnlineFmt: '{on} / {total} en línea',
    homeTypeLabels: const ['Casa','Apartamento','Villa','Cabaña','Cabina','Torre','Ático','Granja','Rancho','Yate'],
    homeColorLabels: const ['Azul','Morado','Verde','Naranja','Dorado','Rojo','Turquesa','Rosa','Marrón','Gris'],
    homeTypeTitle: 'Tipo de hogar', homeColorTitle: 'Color', colorMix: 'Mezcla de color', pickLabel: 'Elegir',
    profilePhotoFmt: 'Foto de perfil — {name}', inviteSubject: 'Invitación a unirse a mi hogar inteligente', inviteBodyFmt: 'Hola,\n\nTe invito a unirte a mi hogar inteligente a través de la app FantaTech.\n\nCódigo de unión: {code}\n\nDescarga la app e introduce el código para unirte.', noEmailApp: 'No se encontró ninguna app de correo en el dispositivo', regManagerMsg: '¡Registrado como administrador del hogar!', nameFieldFmt: 'Nombre: {name}', homeJoinTitle: 'Código de unión al hogar', shareCodeHint: 'Comparte el código con los miembros del hogar\npara que puedan unirse', gotIt: 'Entendido', homeStyleTitle: 'Estilo del hogar', registerAsFmt: 'Registrarse como: {name}', newCodeFmt: 'Nuevo código generado: {code}', joinCodeInline: 'Código de unión al hogar:  ', inviteByEmail: 'Invitar miembro por correo', inviteByEmailSub: 'Envía el código de unión directamente por correo',
    tailscaleWhat: '¿Qué es Tailscale?', tailscaleDesc: 'Una VPN gratuita para acceso remoto a tu red doméstica.\nConecta tu teléfono a la red del hogar de forma cifrada, incluso fuera de casa.', tailscaleStep1: 'Instala Tailscale en tu teléfono y en Raspberry Pi / HA Green', tailscaleStep2: 'Inicia sesión con la misma cuenta (Google / Apple / Email)', tailscaleStep3: 'Activa el interruptor — la app abrirá Tailscale', tailscaleOpen: 'Abrir / Instalar Tailscale',
    camScanNetwork: 'Escanear red', camScanning: 'Escaneando...', camAddManual: 'Agregar cámara manualmente', camFieldName: 'Nombre', camPort: 'Puerto', camUser: 'Usuario', camRtspPath: 'Ruta RTSP', camStreamPath: 'Ruta de stream', camRtspHint: '/  o  /cam/realmonitor?channel=1', camPtzTitle: 'Cámara PTZ', camPtzSub: 'Activar control Pan / Tilt / Zoom', camTestConn: 'Probar conexión', camAddBtn: 'Agregar cámara', camFoundFmt: '✓ ¡Cámara encontrada! {info} — puertos abiertos: {ports}', camConnectFailFmt: '✗ No se puede conectar a {addr}',
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
    aiInputHint: 'Escribe o háblame', aiMicUnavailable: 'Micrófono no disponible',
    aiSug1: 'Apagar todas las luces',
    aiSug2: '¿Estado del hogar ahora?',
    aiSug3: 'Activar modo noche',
    aiSug4: '¿Hay alertas activas?',
    aiSugDesc1: 'Puedo apagar todas las luces de la casa',
    aiSugDesc2: 'Obtén un resumen completo de la casa y sus sistemas',
    aiSugDesc3: 'Activaré todas las configuraciones del modo nocturno',
    aiSugDesc4: 'Comprueba si hay alertas o condiciones inusuales',
    aiPrivacyNote: 'Tu información es privada y está protegida', aiClearChat: 'Borrar conversación',
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
    deviceWillBeRemoved: 'El dispositivo será eliminado de la lista', haRemoveDeviceFailed: 'Eliminado de la lista, pero no se pudo borrar de Home Assistant', ipAddressLabel: 'Dirección IP',
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
    scanBarcode: 'Escanear Código / QR', editUserName: 'Editar nombre de usuario', searchScanProducts: 'Buscar productos en la red',
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
    roomNameLiving: 'Sala', roomNameKitchen: 'Cocina', roomNameBedroom: 'Dormitorio',
    roomNameKids: 'Cuarto de niños', roomNameGarden: 'Jardín', roomNameBathroom: 'Baño',
    roomNameStorage: 'Almacén', roomNameAc: 'Aire Acond.',
    rememberMe: 'Recuérdame',
    notConnectedLabel: 'No conectado', solarTitle: 'Sistema Solar', solarProduction: 'Producción', solarConsumption: 'Consumo',
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
    assignRoom: 'Asignar habitación', noRoom: 'Sin habitación', newRoom: 'Nueva habitación…',
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
    keepShabbatLabel: 'Observar Shabat', shabbatSection: 'Shabat',
    shabbatCandlesDesc: 'Apagar todo ✡️ y cerrar puertas antes del Shabat',
    shabbatHavdalahDesc: 'Restaurar dispositivos tras el final del Shabat',
    acConnected: 'unidades de A/C conectadas', acNoUnits: 'Sin A/C conectado',
    adStoreLabel: 'Tienda FantaTech', adTrackTitle: 'Config. de Anuncios',
    adTrackSub: 'Elige los productos que aparecen en el banner',
    adFeaturedLabel: 'Productos Destacados', adFeaturedSub: 'Hub Pro, Camera 4K, Smart Bulb, Sensor',
    adNewLabel: 'Novedad en Tienda', adNewSub: 'Smart Blind, Smart Plug 16A, Gateway, LED Strip',
    adAllLabel: 'Todos los Productos', adAllSub: 'Rotación completa del catálogo',
    adNoneLabel: 'Sin Anuncios', adNoneSub: 'Ocultar el banner completamente',
    autoThemeLabel: 'Tema Automático', autoThemeDesc: 'Se adapta a la luz ambiental',
    autoThemeActive: 'Activo', autoThemeWaiting: 'Esperando sensor…',
    homeLayoutLabel: 'Diseño de pantalla de inicio',
    signOutAppTitle: 'Salir de la App', signOutChoose: 'Elige cómo salir',
    signOutToLogin: 'Cerrar sesión y volver al inicio', signOutToLoginSub: 'Desconecta la cuenta — requiere inicio de sesión',
    signOutFull: 'Salida Completa', signOutFullSub: 'Cierra sesión y la aplicación',
    accountSection: 'Cuenta',
    switchAccountTitle: 'Cambiar cuenta', switchAccountSub: 'Cerrar sesión e iniciar con otra cuenta',
    switchAccountConfirmTitle: '¿Cambiar de cuenta?', switchAccountConfirmBody: 'Cerrarás sesión y volverás a la pantalla de inicio.',
    switchAccountConfirmBtn: 'Cambiar cuenta', switchAccountPasswordPrompt: 'Ingresa tu contraseña para confirmar',
    switchAccountWrongPassword: 'Contraseña incorrecta',
    installerBadge: 'INSTALADOR', installerCodeTitle: 'Modo Instalador',
    installerCodeHint: 'Ingresa el código de instalador', installerCodeWrong: 'Código de instalador incorrecto',
    installerModeOnMsg: 'Modo Instalador activado', installerModeOffMsg: 'Modo Instalador desactivado',
    installerExitConfirm: '¿Salir del Modo Instalador?',
    deviceOfflineHint: 'Dispositivo desconectado — revisa su conexión',
    aiBackendNotConfigured: 'El asistente de IA aún no está configurado',
    aiRequestFailed: 'Lo siento, no pude conectar con el asistente ahora',
    aiEmptyReply: 'Hecho.',
    aiTooManySteps: 'Esa solicitud necesita demasiados pasos — intenta algo más simple',
    mirrorScreenTitle: 'Espejo Inteligente', adBannerShop: 'Tienda',
    confirm: 'Confirmar', pickDay: 'Día', pickMonth: 'Mes',
    pickHebrewDate: 'Seleccionar fecha hebrea',
    hebrewDateFmt: 'Fecha hebrea: {date}', hebrewCalendarChip: 'Fecha hebrea…',
    storeBuyAt: 'Comprar en ',
    loginBiometric: 'Entrar con huella / rostro',
    errInvalidEmail: 'Correo electrónico no válido',
    loginGoogleEmailPrompt: 'Introduce tu Gmail para continuar',
    scanNetworkTitle: 'Escanear red', scanSelectDevice: 'Selecciona dispositivo para añadir',
    stop: 'Parar', scanSensorsShutters: 'Sensores · Persianas',
    sensorHubTitle: 'Sensores y Persianas',
    sensorHubFoundFmt: '{sensors} sensores · {covers} persianas',
    sensorsTab: 'Sensores', shuttersTab: 'Persianas',
    noSensorsFound: 'No se encontraron sensores', noCoversFound: 'No se encontraron persianas',
    coverOpen: '▲  Abrir', coverStop: '■  Parar', coverClose: '▼  Cerrar',
    switchScanningAll: 'Escaneando todos los protocolos…',
    switchAddedFmt: '✓ {name} añadido al hogar',
    keyStoredLocal: 'La clave se guarda solo en tu dispositivo.',
    saveAndControl: 'Guardar y controlar',
    tapoLogin: 'Tapo — Iniciar sesión',
    tapoCredHint: 'Los mismos datos que la app TP-Link Tapo.',
    connectAndControl: 'Conectar y controlar',
    errControlFmt: 'Error controlando {name}',
    switchSearchingAll: 'Buscando interruptores inteligentes en todos los protocolos…',
    switchNoFound: 'No se encontraron interruptores inteligentes',
    switchHint: 'Asegúrate de que los interruptores están en la misma WiFi.\nShelly/ESPHome — modo STA\nSonoff — modo DIY (firmware 3.6+)\nHome Assistant / Zigbee2MQTT — conecta en ajustes',
    camFrameCaptureError: 'Error capturando fotograma',
    camNoFaces: 'No se reconocieron caras', camFacesFoundFmt: '{count} caras reconocidas — {known} identificadas 🎯',
    camFacesOnlyFmt: '{count} caras reconocidas 🎯', camAnalysisErrorFmt: 'Error de análisis: {error}',
    camCaptureError: 'Error de captura',
    camSnapshotSavedFmt: '📸 Guardado: snapshot_{ts}.png',
    camSaveSnapshotError: 'Error al guardar la imagen',
    camConnectingFmt: 'Conectando a {name}...',
    camIdentifyingFaces: 'Identificando caras y personas...',
    camDetectingFaces: 'Detectando caras...',
    camFaceLabelFmt: 'Cara {n}', camStreamConnFailed: 'No se pudo conectar al stream',
    addWizBulb: 'Añadir bombilla WiZ real',
    addWizBulbSub: 'Control LAN real · sin nube',
    deviceNotFoundStatus: 'Dispositivo no encontrado', manualAddStatus: 'Añadir manualmente',
    connecting: 'Conectando...',
    deviceNotFoundHint: 'Verifica que el dispositivo esté enchufado y en WiFi,\no que el Bluetooth esté activado.',
    manualAddLabel: 'Añadir manualmente', deviceNameLabel: 'Nombre del dispositivo', deviceDeleteConfirm: '¿Eliminar este dispositivo de la app? Puedes volver a añadirlo más tarde escaneando de nuevo.',
    ipAddressOptional: 'Dirección IP (opcional)', back: 'Volver',
    faceConfigured: '✓ Configurado', faceIdTitle: 'Identificación facial',
    faceIdSubtitle: 'Registra personas para identificación automática',
    faceTraining: 'Entrenando modelo...', faceTrainModelFmt: 'Entrenando modelo ({enrolled}/{total} registrados)',
    facePrepGroup: 'Preparando grupo...', faceTrainStartFailed: '❌ No se pudo iniciar el entrenamiento',
    faceTrainingProgress: 'Entrenando... (puede tardar hasta 60 segundos)',
    faceTrainSuccess: '✅ ¡Modelo entrenado con éxito! Identificación activa.',
    faceTrainFailed: '❌ Entrenamiento fallido. Inténtalo de nuevo.',
    faceSetAzureKeyFirst: 'Añade la clave Azure API primero',
    faceAddingPhoto: 'Añadiendo foto a Azure...',
    faceCreateRecordError: '❌ Error creando registro en Azure',
    faceFaceNotDetected: '❌ No se detectó cara en esta foto',
    facePhotoAddedFmt: '✅ Foto añadida a {name}. Entrena el modelo.',
    faceNotConfiguredTap: 'No configurado — toca para configurar',
    faceCheckConnection: 'Verifica la conexión',
    faceGetFreeApiKey: 'Obtén una clave API gratuita en portal.azure.com → Cognitive Services',
    faceSaveSettingsFirst: '⚠️ Guarda los ajustes primero',
    faceAzureConnOk: '✅ ¡Conexión con Azure exitosa!',
    faceAzureConnFailed: '❌ No se pudo conectar. Verifica Endpoint + Key',
    faceEnrolledAzure: '✓ Registrado en Azure', faceNotEnrolled: '⚠ No registrado — añade foto',
    faceAddPerson: 'Añadir persona', faceFullNameHint: 'Nombre completo',
    faceEnterName: 'Introduce un nombre', faceCreatingRecord: 'Creando registro...',
    faceNoPeople: 'No hay personas registradas',
    faceNoPeopleHint: 'Añade personas para que las cámaras\nlas reconozcan por nombre',
    roomSettings: 'Ajustes de habitación', capComingSoonFmt: '{cap} — próximamente',
    householdNoAdmin: 'Aún no hay administrador del hogar',
    householdMemberNote: 'El acceso como miembro estará disponible cuando el administrador se registre con Google o Apple.',
    backToLogin: 'Volver al inicio de sesión', householdAdmin: 'Administrador del hogar',
    selectProfile: 'Seleccionar perfil', noMembersYet: 'Aún no hay miembros',
    addMembersHint: 'El administrador puede añadir miembros\ndesde Perfil → Gestión del hogar.',
    switchScanProgressFmt: 'Escaneando... {n} / 254',
    switchNoDevicesHint: 'No se encontraron dispositivos. Verifica que estén en la misma WiFi',
    scanDoneFmt: 'Escaneo completado — {n} dispositivos', scanWifi: 'Escanear WiFi',
    faceAnalysisTitle: 'Análisis facial', faceAnalysisSubtitle: 'Historial de escaneos de cámaras',
    clear: 'Limpiar', clearHistory: 'Limpiar historial',
    clearHistoryConfirm: '¿Eliminar todos los resultados de análisis?',
    statScans: 'Escaneos', statFacesDetected: 'Caras detectadas',
    statAlerts: 'Alertas', faces: 'Caras', smiling: 'Sonriendo', eyesClosed: 'Ojos cerrados',
    noFacesInFrame: 'No se detectaron caras en este fotograma', noAnalysesYet: 'Aún no hay análisis',
    faceAnalysisHint: 'Abre la cámara y pulsa "Analizar"\npara comenzar el reconocimiento facial',
    smartHomeTitle: 'Casa inteligente',
    temperatureFmt: 'Temp: {n}°C', brightnessFmt: 'Brillo: {n}%', positionFmt: 'Posición: {n}%',
    wizIdentifyingWifi: 'Identificando red WiFi…', wizNoWifi: 'Sin WiFi — introduce IP manualmente',
    wizBroadcastingFmt: 'Transmitiendo en {prefix}.x …',
    wizNoFound: 'No se encontraron bombillas WiZ — prueba manualmente',
    wizFoundFmt: 'Se encontraron {n} bombillas',
    wizScanFailed: 'Escaneo fallido — prueba manualmente',
    wizBlinkingFmt: 'Parpadeando {ip} …', wizBlinkSentFmt: 'Comando de parpadeo enviado a {ip} ✓',
    wizNoResponseFmt: 'Sin respuesta de {ip} - verifica que la bombilla esté en red',
    wizDeviceAddedFmt: '{name} añadido — control activo',
    wizManualAdd: 'Añadir manualmente con IP', wizTest: 'Probar',
    gatewayHubTitle: 'Bridges y Hubs',
    gatewayHubSubtitle: 'Conecta hubs Zigbee, Z-Wave, WiFi y nube',
    connected: 'Conectado', addGateway: 'Añadir bridge', gatewayTypesFmt: '{n} tipos',
    devicesImportedFmt: '{n} dispositivos importados de {name}',
    allDevicesExist: 'Todos los dispositivos ya existen',
    diagnosisTitle: 'Dispositivos reportados por el hub',
    disconnectConfirmFmt: '¿Desconectar "{name}"?',
    importedDevicesNote: 'Los dispositivos importados se mantendrán, pero no se podrán importar más.',
    disconnect: 'Desconectar', deviceCountFmt: '{n} dispositivos',
    importDevices: 'Importar dispositivos', connect: 'Conectar',
    connectAfterButton: 'Conectar (tras pulsar el botón)',
    connectedSuccess: '¡Conectado con éxito!',
    secondsRemainingFmt: '{n} segundos restantes', cloud: 'Nube',
    cloudConnectionNote: 'Conexión en la nube — los datos pasan por los servidores del fabricante',
    setupStepsHintFmt: '¿Cómo obtener los detalles? ({n} pasos)',
    tokenPortalFmt: 'Token creado en el portal de {name}', optional: 'Opcional',
    z2mEnterIp: 'Introduce la IP de Zigbee2MQTT',
    z2mUnreachableFmt: 'No se puede acceder a Zigbee2MQTT en {ip}:{port}\nVerifica que el frontend esté activo y el IP sea correcto',
    z2mUnknownError: 'Error desconocido',
    z2mSubtitle: 'Conecta el hub Zigbee — importa dispositivos automáticamente',
    z2mIpLabel: 'IP de Z2M', z2mIpHint: 'Ej: 192.168.1.50',
    z2mPortLabel: 'Puerto', z2mTokenLabel: 'Token API (opcional)',
    z2mTokenHint: 'Si está configurado', z2mFoundFmt: '¡{n} dispositivos Zigbee encontrados!',
    z2mConnectImport: 'Conectar e importar',
    z2mFrontendHelp: 'Activa el frontend en los ajustes de Z2M:\n  frontend:\n    port: 8080',
    discoveryTitle: 'Descubrir dispositivos', scan: 'Escanear',
    matterDeviceTitle: 'Dispositivo Matter',
    matterDeviceHelp: 'Los dispositivos Matter (ej. bombillas IKEA) se vinculan a través de un hub Matter, no directamente desde la app.\n\nModo fácil:\n1. Vincula la bombilla a DIRIGERA con la app IKEA Home smart.\n2. Aquí: Bridges → DIRIGERA → "Importar dispositivos".\nAparecerá con control completo.',
    understood: 'Entendido', devicesAddedFmt: '{n} dispositivos añadidos',
    haFound: 'Home Assistant encontrado',
    haConnectedFmt: 'Conectado — {n} dispositivos importados',
    haConnect: 'Conectar',
    haReconnectSync: 'Reconectar y sincronizar',
    haTokenHint: 'Crea el Token en: Perfil → Long-Lived Access Tokens',
    importFromHa: 'Importar dispositivos de Home Assistant',
    scanningDevices: 'Buscando dispositivos…',
    scanHint: 'Pulsa "Escanear" para buscar dispositivos en la red',
    addAllFmt: 'Añadir todo ({n} dispositivos)',
    matterCommTitle: 'Vincular dispositivo Matter',
    matterCommSubtitle: 'Escanea el QR en la etiqueta del dispositivo',
    matterCommScanBtn: 'Escanear QR', matterCommManualBtn: 'Introducir código manualmente',
    matterCommManualHint: 'Código de 11 dígitos (ej. 12345-67890)',
    matterCommissioning: 'Vinculando con Home Assistant…',
    matterCommSuccess: '¡Dispositivo vinculado con éxito!',
    matterCommFailed: 'Vinculación fallida. Verifica que la integración Matter esté activa en HA.',
    matterCommNoHa: 'Home Assistant no conectado. Conecta HA primero.',
    matterCommRetry: 'Reintentar', matterCommCodeHint: 'MT:… o código de 11 dígitos',
    blindsHubTitle: 'Persianas y Cubiertas', openAll: 'Abrir todo', closeAll: 'Cerrar todo',
    noBlindsFound: 'No se encontraron persianas',
    blindsHint: 'Añade persianas a través de Home Assistant',
    smartLocksTitle: 'Cerraduras inteligentes', lockedStatus: 'Cerrado', unlockedStatus: 'Abierto',
    lockAll: 'Cerrar todo', unlockAll: 'Abrir todo',
    noLocksFound: 'No se encontraron cerraduras',
    lockHint: 'Añade una cerradura inteligente a través de Home Assistant',
    lightsHubTitle: 'Luces', lightsAllOn: 'Todo encendido', lightsAllOff: 'Todo apagado',
    noLightsFound: 'No se encontraron luces',
    lightsHint: 'Añade luces a través de Home Assistant',
    plugsHubTitle: 'Enchufes inteligentes', plugsAllOn: 'Todo encendido', plugsAllOff: 'Todo apagado',
    noPlugsFound: 'No se encontraron enchufes',
    plugsHint: 'Añade enchufes escaneando WiFi',
    acHubTitle: 'Aire acondicionado',
    intercomTitle: 'Intercomunicador', intercomNoDevices: 'No se encontraron dispositivos de intercomunicador',
    intercomHint: 'Añade un intercomunicador desde el catálogo o importación de pasarela',
    intercomRing: 'Timbrar', intercomAnswer: 'Contestar', intercomDecline: 'Rechazar',
    intercomCategory: 'Timbre de vídeo', intercomRinging: 'Alguien en la puerta…',
    vacuumCategory: 'Robot aspirador', vacuumNoDevices: 'No se encontraron robots aspiradores',
    vacuumHint: 'Conecta tu robot aspirador a través de Home Assistant para verlo aquí',
    vacuumStart: 'Iniciar', vacuumPause: 'Pausar', vacuumDock: 'Volver a la base',
    vacuumCleaning: 'Limpiando', vacuumDocked: 'En la base',
    intercomUnlockDoor: 'Abrir puerta',
    energyRateLabel: 'Tarifa eléctrica', energyRateEdit: 'Editar tarifa',
    energyRateUnit: '₪/kWh', energyRateSaved: 'Tarifa guardada',
    backupTitle: 'Copia de seguridad y restauración', backupExport: 'Exportar ajustes',
    backupImport: 'Importar ajustes', backupExportDone: 'Ajustes exportados a Descargas',
    backupImportDone: 'Ajustes restaurados con éxito', backupImportError: 'Error al importar — archivo no válido',
    backupSection: 'Datos y copia de seguridad',
    biometricSplashLabel: 'Autenticar',
    camLocationPermission: 'Se requiere permiso de ubicación para escanear la red',
    camNoWifiIp: 'No pudimos detectar tu red WiFi — conéctate a WiFi e inténtalo de nuevo, o añade la cámara manualmente',
    camScanNoneFound: 'No se encontraron cámaras en la red. Si la tuya no es compatible con ONVIF, añádela manualmente con su dirección IP.',
    showHideSections: 'Mostrar / Ocultar secciones', restoreDefaults: '¿Restaurar valores predeterminados?', restoreDefaultsConfirm: 'Esto restablecerá el diseño del panel de seguridad. No se puede deshacer.', restore: 'Restaurar', systemTest: 'Prueba del sistema',
  );

  // ── Russian ───────────────────────────────────────────────────
  static const S _ru = S(
    homeGreetingSub: 'Ваш дом — безопасный и умный.', energyToday: 'Энергия сегодня', vsYesterday: 'к вчера',
    climateEnergyTitle: 'Климат и энергия', homeManagementTitle: 'Управление домом',
    energyAnalytics: 'Аналитика Энергии',
    securitySystemLabel: 'Система охраны', secArmedShort: 'Включена', secDisarmedShort: 'Отключена', allOkLabel: 'Всё в порядке', emergencyBtn: 'Тревога',
    showAll: 'Показать все', roomsHeader: 'Комнаты', statHomesLabel: 'Дома', devicesUnit: 'устройств',
    qaLock: 'Замок', qaLights: 'Свет', qaAc: 'Климат', qaCameras: 'Камеры', qaAlerts: 'Уведомления',
    qaPlugs: 'Розетки', qaWaterHeater: 'Бойлер', qaBreakers: 'Щиток',
    qaNoDevices: 'Нет устройств', qaNoAlerts: 'Нет уведомлений', qaResetAll: 'Сбросить всё', qaScanDevice: 'Поиск устройства',
    adAddLink: 'Добавить ссылку', adCustomLink: 'Своя ссылка',
    systemStatus: 'Статус системы', statusInternet: 'Интернет', statusSensors: 'Датчики', connectedLabel: 'Подключено',
    camMotion: 'Движение', camOnline: 'Онлайн', camOffline: 'Не в сети', locationUnavailable: 'Геолокация недоступна', gatewaysManage: 'Управление', gatewaysTitle: 'Шлюзы', statusOffline: 'Не в сети',
    secArmStayBtn: 'Дома', secDisarmBtn: 'Снять', roomNameMedia: 'Медиа', mediaRoomTitle: 'Медиа',
    roomOccupantLabel: 'Кто пользуется комнатой?', occupantNone: 'Нет', occupantKids: 'Дети', occupantAdults: 'Взрослые',
    navHome: 'Главная', navCameras: 'Камеры', navSecurity: 'Охрана', navProfile: 'Профиль', navAutomations: 'Автоматизации',
    greetingPrefix: 'Привет', homeSecured: 'Дом под защитой', homeNotSecured: 'Дом не защищён',
    allSystemsActive: 'Все системы активны', tapToActivate: 'Нажмите для активации',
    alarmTitle: 'Охрана', alarmSecured: 'Защищён', alarmOff: 'Выключена', roomManagement: 'Управление домом', roomsUnit: 'комнат',
    camerasTitle: 'Камеры', lightsOn: 'света включены', lightingTitle: 'Освещение',
    tempTitle: 'Температура', tempComfy: 'Комфортно', aiSubtitle: 'Как я могу вам помочь?', aiTopSubtitle: 'Помощник вашего умного дома',
    quickActions: 'Быстрые действия', leaveHome: 'Уйти из дома', turnOffAll: 'Выключить всё', goodNight: 'Спокойной ночи', movieMode: 'Режим фильма',
    mediaTitle: 'Медиа', mediaSpeakers: 'Колонки', mediaScan: 'Поиск устройств', mediaNoDevices: 'Колонки не найдены. Нажмите поиск.',
    bioTitle: 'Быстрый вход', bioPrompt: 'Включить вход по отпечатку в следующий раз?', bioEnable: 'Включить', bioSkip: 'Не сейчас', bioReason: 'Подтвердите личность для входа',
    onbNext: 'Далее', onbStart: 'Начать', onbSkip: 'Пропустить', onbAllow: 'Разрешить', onbLater: 'Позже', onb1Title: 'Добро пожаловать в FantaTech', onb1Body: 'Ваш умный дом — свет, безопасность, климат и энергия в одном месте.', onb2Title: 'Полный контроль', onb2Body: 'Управляйте камерами, датчиками, выключателями откуда угодно.', onb3Title: 'Умные сценарии', onb3Body: 'Создавайте сцены, экономьте энергию и получайте уведомления.', onbPermTitle: 'Разрешения для поиска устройств', onbPermBody: 'Чтобы найти устройства в сети, нужны Геолокация и Bluetooth. Данные остаются только на вашем устройстве.',
    secSection: 'Безопасность', bioLoginLabel: 'Вход по отпечатку', bioLoginSub: 'Быстрый вход по биометрии', bioUnavailable: 'Биометрия не поддерживается на этом устройстве', legalSection: 'Правовая информация', termsLabel: 'Условия использования', privacyLabel: 'Политика конфиденциальности',
    sceneCreate: 'Создать сцену', sceneNew: 'Новая сцена', sceneName: 'Название сцены', sceneActions: 'Действия', actPlugs: 'Розетки', valKeep: 'Без изменений', valOn: 'Вкл', valOff: 'Выкл',
    authEmailHint: 'Email или телефон', authPassHint: 'Пароль', loginGreeting: 'Здравствуйте!', loginSubtitle: 'Войдите в свой аккаунт', loginForgot: 'Забыли пароль?', resetEmailHint: 'Введите email и мы отправим ссылку для сброса пароля.', resetEmailSent: 'Ссылка отправлена! Проверьте почту.', okButton: 'ОК', cancelButton: 'Отмена', sendButton: 'Отправить', loginButton: 'Войти', authOr: 'или', loginNoAccount: 'Нет аккаунта?', registerNow: 'Зарегистрироваться', continueAsGuest: 'Продолжить как гость', loginWith: 'Войти через', appTagline: 'Решения для умного дома и безопасности', registerTitle: 'Создать аккаунт', registerSubtitle: 'Присоединяйтесь к умному дому FantaTech', confirmPassHint: 'Подтвердите пароль', registerButton: 'Регистрация', haveAccount: 'Уже есть аккаунт?', loginHousehold: 'Член семьи',
    errEnterName: 'Введите полное имя', errEnterEmail: 'Введите email или телефон', errPassShort: 'Пароль должен быть не менее 6 символов', errPassMismatch: 'Пароли не совпадают',
    acMode: 'Режим', acFanSpeed: 'Вентилятор', acSwing: 'Качание', acPreset: 'Пресет', acMethod: 'Управление', modeCool: 'Охлаждение', modeHeat: 'Обогрев', modeFan: 'Вентилятор', modeDry: 'Осушение', modeAuto: 'Авто', fanLow: 'Низкий', fanMed: 'Средний', fanHigh: 'Высокий',
    mediaMaster: 'Общая громкость', mediaParty: 'Играть на всех', mediaStopAll: 'Остановить все',
    tvRemote: 'Пульт ТВ', tvSource: 'Источник', tvChannel: 'Канал', tvMute: 'Без звука',
    faq1Q: 'Как добавить устройство?', faq1A: 'Нажмите + на панели и выберите устройство из каталога.', faq2Q: 'Как сменить язык?', faq2A: 'Профиль → Настройки → Язык.', faq3Q: 'Работает ли без интернета?', faq3A: 'Локальные команды работают. Облако требует интернет.', faq4Q: 'Как настроить автоматизацию?', faq4A: 'Нажмите "Автоматизации" в нижнем меню → Добавить.',
    energyTitle: 'Потребление энергии', automationsTitle: 'Автоматизация', activeAutomations: 'активных сценариев',
    myProfile: 'Мой профиль', myHome: 'Мой дом', usersTitle: 'Пользователи',
    subscriptionTitle: 'Подписка', settingsTitle: 'Настройки', helpTitle: 'Помощь',
    signOut: 'Выйти', languageLabel: 'Язык', themeLabel: 'Тема',
    darkMode: 'Тёмная', lightMode: 'Светлая', appearanceTitle: 'Внешний вид', themeFont: 'Шрифт', themeAccent: 'Акцент', themeBg: 'Фон', themeRadius: 'Скругление', themeBgDarkBlue: 'Тёмно-синий', themeBgAmoled: 'AMOLED чёрный', themeBgDarkGray: 'Тёмно-серый', themeBgLightGray: 'Светло-голубой', themeBgLightWhite: 'Чисто белый', themeRadiusSharp: 'Острые', themeRadiusNormal: 'Обычные', themeRadiusRound: 'Круглые', saveChanges: 'Сохранить',
    editProfile: 'Редактировать', fullName: 'Полное имя', emailLabel: 'Эл. почта',
    profileUpdated: 'Профиль обновлён', signOutConfirm: 'Выйти', signOutQuestion: 'Вы уверены, что хотите выйти?', confirmSignOut: 'Выйти',
    securityTitle: 'Безопасность', armedMode: 'Вооружён', disarmedMode: 'Разоружён',
    doorSensor: 'Входная дверь', windowsSensor: 'Окна', motionSensors: 'Датчики движения', smokeDetector: 'Датчик дыма', waterLeakSensor: 'Датчик протечки воды',
    securedStatus: 'Защищён', openStatus: 'Открыт', activeStatus: 'Активен', normalStatus: 'Норма',
    panicButton: 'Тревога', panicActivate: 'Активировать!', panicWarning: 'Будет отправлен сигнал SOS',
    welcomeGuestBtn: 'Добро пожаловать, гость', welcomeGuestActive: 'Режим гостя активен', welcomeGuestTimer: 'осталось {n} мин', welcomeGuestCancel: 'Отменить режим гостя', welcomeGuestHint: 'Отключает охрану для гостя · автовосстановление',
    welcomeGuestChoose: 'Выберите длительность', guestOptShort: 'Короткий визит', guestOptMedium: 'Обычный визит', guestOptLong: 'Долгий визит', guestMinutes: 'мин',
    chooseBrand: 'Выбор бренда', pairingSteps: 'Шаги сопряжения',
    allCameras: 'Все камеры', liveLabel: 'ПРЯМОЙ ЭФИР', offlineLabel: 'Не в сети', deviceOn: 'Вкл', deviceOff: 'Выкл', deleteAll: 'Удалить всё', deleteAllConfirm: 'Удалить все устройства из списка?',
    addDeviceBtn: 'Добавить устройство', notificationsTitle: 'Уведомления',
    timeNow: 'сейчас', timeMinAgo: '{n} мин назад', timeHrAgo: '{n} ч назад', timeDayAgo: '{n} д назад', deviceConnectedFmt: 'Устройство подключено: {name}',
    camFrontDoor: 'Входная дверь', camBackDoor: 'Задняя дверь', camGarage: 'Гараж', camBackyard: 'Задний двор', camEntrance: 'Вход', camDriveway: 'Подъездная дорожка', camBalcony: 'Балкон',
    autoMotionNight: 'Ночной свет по движению', autoArrive: 'Прибытие домой', autoMorning: 'Доброе утро', autoEnergySave: 'Экономия энергии',
    condMotionNight: 'Движение ночью (21:00–06:00)', condNobodyHome: 'Если никого нет дома', condArrive: 'По прибытии домой', condTime2300: 'В 23:00', condMorningWeekday: 'В 07:00 по будням', condNoMotion30: 'Если нет движения 30 мин',
    actAllLightsOn: 'Включить весь свет', actAlarmOffAll: 'Поставить на охрану + выключить всё', actLightsAlarmOff: 'Свет вкл + снять с охраны', actOffLock: 'Выключить всё + запереть двери', actBlindsCoffee: 'Открыть жалюзи + включить кофе', actOffLightsAc: 'Выключить свет и кондиционер',
    catSmoke: 'Дым', catEnergy: 'Энергия', actionTurnOn: 'Включить', actionTurnOff: 'Выключить',
    cyberNoEvents: 'Нет недавних событий', cyberNetworkMap: 'Карта сети', cyberNetworkTopology: 'Топология сети', cyberPhones: 'Телефоны', cyberOnlineFmt: '{on} / {total} онлайн',
    homeTypeLabels: const ['Дом','Квартира','Вилла','Коттедж','Кабина','Башня','Пентхаус','Ферма','Ранчо','Яхта'],
    homeColorLabels: const ['Синий','Фиолетовый','Зелёный','Оранжевый','Золотой','Красный','Бирюзовый','Розовый','Коричневый','Серый'],
    homeTypeTitle: 'Тип дома', homeColorTitle: 'Цвет', colorMix: 'Смешивание цветов', pickLabel: 'Выбрать',
    profilePhotoFmt: 'Фото профиля — {name}', inviteSubject: 'Приглашение в мой умный дом', inviteBodyFmt: 'Здравствуйте,\n\nПриглашаю вас в мой умный дом через приложение FantaTech.\n\nКод присоединения: {code}\n\nСкачайте приложение и введите код, чтобы присоединиться.', noEmailApp: 'Почтовое приложение не найдено на устройстве', regManagerMsg: 'Вы зарегистрированы как управляющий домом!', nameFieldFmt: 'Имя: {name}', homeJoinTitle: 'Код присоединения к дому', shareCodeHint: 'Поделитесь кодом с членами семьи\nчтобы они могли присоединиться', gotIt: 'Понятно', homeStyleTitle: 'Стиль дома', registerAsFmt: 'Зарегистрироваться как: {name}', newCodeFmt: 'Создан новый код: {code}', joinCodeInline: 'Код присоединения к дому:  ', inviteByEmail: 'Пригласить по эл. почте', inviteByEmailSub: 'Отправить код присоединения по эл. почте',
    tailscaleWhat: 'Что такое Tailscale?', tailscaleDesc: 'Бесплатный VPN для удалённого доступа к домашней сети.\nБезопасно подключает телефон к домашней сети, даже когда вы не дома.', tailscaleStep1: 'Установите Tailscale на телефон и Raspberry Pi / HA Green', tailscaleStep2: 'Войдите с тем же аккаунтом (Google / Apple / Email)', tailscaleStep3: 'Включите переключатель — приложение откроет Tailscale', tailscaleOpen: 'Открыть / Установить Tailscale',
    camScanNetwork: 'Сканировать сеть', camScanning: 'Сканирование...', camAddManual: 'Добавить камеру вручную', camFieldName: 'Имя', camPort: 'Порт', camUser: 'Пользователь', camRtspPath: 'Путь RTSP', camStreamPath: 'Путь потока', camRtspHint: '/  или  /cam/realmonitor?channel=1', camPtzTitle: 'PTZ-камера', camPtzSub: 'Включить управление Pan / Tilt / Zoom', camTestConn: 'Проверить соединение', camAddBtn: 'Добавить камеру', camFoundFmt: '✓ Камера найдена! {info} — открытые порты: {ports}', camConnectFailFmt: '✗ Не удаётся подключиться к {addr}',
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
    aiInputHint: 'Введите или говорите со мной', aiMicUnavailable: 'Микрофон недоступен',
    aiSug1: 'Выключить весь свет',
    aiSug2: 'Статус дома сейчас?',
    aiSug3: 'Активировать ночной режим',
    aiSug4: 'Есть активные оповещения?',
    aiSugDesc1: 'Я могу выключить весь свет в доме',
    aiSugDesc2: 'Получите полную сводку о доме и его системах',
    aiSugDesc3: 'Я включу все настройки ночного режима',
    aiSugDesc4: 'Проверить наличие оповещений и необычных ситуаций',
    aiPrivacyNote: 'Ваша информация конфиденциальна и защищена', aiClearChat: 'Очистить разговор',
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
    deviceWillBeRemoved: 'Устройство будет удалено из списка', haRemoveDeviceFailed: 'Удалено из списка, но не удалось удалить из Home Assistant', ipAddressLabel: 'IP-адрес',
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
    scanBarcode: 'Сканировать штрихкод / QR', editUserName: 'Изменить имя пользователя', searchScanProducts: 'Поиск устройств в сети',
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
    roomNameLiving: 'Гостиная', roomNameKitchen: 'Кухня', roomNameBedroom: 'Спальня',
    roomNameKids: 'Детская', roomNameGarden: 'Сад', roomNameBathroom: 'Ванная',
    roomNameStorage: 'Кладовая', roomNameAc: 'Кондиционер',
    rememberMe: 'Запомнить меня',
    notConnectedLabel: 'Не подключено', solarTitle: 'Солнечная система', solarProduction: 'Выработка', solarConsumption: 'Потребление',
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
    assignRoom: 'Назначить комнату', noRoom: 'Без комнаты', newRoom: 'Новая комната…',
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
    keepShabbatLabel: 'Соблюдение субботы', shabbatSection: 'Суббота',
    shabbatCandlesDesc: 'Выключить всё ✡️ и заблокировать двери до Шаббата',
    shabbatHavdalahDesc: 'Восстановить устройства после окончания Шаббата',
    acConnected: 'кондиционеров подключено', acNoUnits: 'Нет кондиционеров',
    adStoreLabel: 'Магазин FantaTech', adTrackTitle: 'Настройки рекламы',
    adTrackSub: 'Выберите товары для отображения в баннере',
    adFeaturedLabel: 'Рекомендуемые', adFeaturedSub: 'Hub Pro, Camera 4K, Smart Bulb, Sensor',
    adNewLabel: 'Новинки магазина', adNewSub: 'Smart Blind, Smart Plug 16A, Gateway, LED Strip',
    adAllLabel: 'Все товары', adAllSub: 'Полная ротация каталога',
    adNoneLabel: 'Без рекламы', adNoneSub: 'Полностью скрыть баннер',
    autoThemeLabel: 'Авто тема', autoThemeDesc: 'Подстраивается под освещение',
    autoThemeActive: 'Активна', autoThemeWaiting: 'Ожидание датчика…',
    homeLayoutLabel: 'Макет главного экрана',
    signOutAppTitle: 'Выйти из приложения', signOutChoose: 'Выберите способ выхода',
    signOutToLogin: 'Выйти и вернуться ко входу', signOutToLoginSub: 'Отключает аккаунт — нужен повторный вход',
    signOutFull: 'Полный выход', signOutFullSub: 'Выходит и закрывает приложение',
    accountSection: 'Аккаунт',
    switchAccountTitle: 'Сменить аккаунт', switchAccountSub: 'Выйти и войти под другим аккаунтом',
    switchAccountConfirmTitle: 'Сменить аккаунт?', switchAccountConfirmBody: 'Вы выйдете из системы и вернётесь на экран входа.',
    switchAccountConfirmBtn: 'Сменить аккаунт', switchAccountPasswordPrompt: 'Введите пароль для подтверждения',
    switchAccountWrongPassword: 'Неверный пароль',
    installerBadge: 'УСТАНОВЩИК', installerCodeTitle: 'Режим установщика',
    installerCodeHint: 'Введите код установщика', installerCodeWrong: 'Неверный код установщика',
    installerModeOnMsg: 'Режим установщика активирован', installerModeOffMsg: 'Режим установщика завершён',
    installerExitConfirm: 'Выйти из режима установщика?',
    deviceOfflineHint: 'Устройство не в сети — проверьте подключение',
    aiBackendNotConfigured: 'ИИ-ассистент ещё не настроен',
    aiRequestFailed: 'Извините, не удалось связаться с ассистентом',
    aiEmptyReply: 'Готово.',
    aiTooManySteps: 'Этот запрос требует слишком много шагов — попробуйте проще',
    mirrorScreenTitle: 'Умное зеркало', adBannerShop: 'Магазин',
    confirm: 'Подтвердить', pickDay: 'День', pickMonth: 'Месяц',
    pickHebrewDate: 'Выбрать еврейскую дату',
    hebrewDateFmt: 'Еврейская дата: {date}', hebrewCalendarChip: 'Еврейская дата…',
    storeBuyAt: 'Купить у ',
    loginBiometric: 'Войти по отпечатку / лицу',
    errInvalidEmail: 'Неверный адрес электронной почты',
    loginGoogleEmailPrompt: 'Введите Gmail для продолжения',
    scanNetworkTitle: 'Сканирование сети', scanSelectDevice: 'Выберите устройство для добавления',
    stop: 'Стоп', scanSensorsShutters: 'Датчики · Шторы',
    sensorHubTitle: 'Датчики и Шторы',
    sensorHubFoundFmt: '{sensors} датчиков · {covers} штор',
    sensorsTab: 'Датчики', shuttersTab: 'Шторы',
    noSensorsFound: 'Датчики не найдены', noCoversFound: 'Шторы не найдены',
    coverOpen: '▲  Открыть', coverStop: '■  Стоп', coverClose: '▼  Закрыть',
    switchScanningAll: 'Сканирование всех протоколов…',
    switchAddedFmt: '✓ {name} добавлен в дом',
    keyStoredLocal: 'Ключ хранится только на вашем устройстве.',
    saveAndControl: 'Сохранить и управлять',
    tapoLogin: 'Tapo — Войти',
    tapoCredHint: 'Те же данные, что и в приложении TP-Link Tapo.',
    connectAndControl: 'Подключить и управлять',
    errControlFmt: 'Ошибка управления {name}',
    switchSearchingAll: 'Поиск умных выключателей по всем протоколам…',
    switchNoFound: 'Умные выключатели не найдены',
    switchHint: 'Убедитесь, что выключатели подключены к той же WiFi.\nShelly/ESPHome — режим STA\nSonoff — режим DIY (прошивка 3.6+)\nHome Assistant / Zigbee2MQTT — подключите в настройках',
    camFrameCaptureError: 'Ошибка захвата кадра',
    camNoFaces: 'Лица не распознаны',
    camFacesFoundFmt: 'Распознано {count} лиц — {known} идентифицировано 🎯',
    camFacesOnlyFmt: 'Распознано {count} лиц 🎯',
    camAnalysisErrorFmt: 'Ошибка анализа: {error}',
    camCaptureError: 'Ошибка захвата',
    camSnapshotSavedFmt: '📸 Сохранено: snapshot_{ts}.png',
    camSaveSnapshotError: 'Ошибка сохранения снимка',
    camConnectingFmt: 'Подключение к {name}...',
    camIdentifyingFaces: 'Идентификация лиц и личностей...',
    camDetectingFaces: 'Обнаружение лиц...',
    camFaceLabelFmt: 'Лицо {n}', camStreamConnFailed: 'Не удалось подключиться к потоку',
    addWizBulb: 'Добавить лампу WiZ',
    addWizBulbSub: 'Реальное управление через LAN · без облака',
    deviceNotFoundStatus: 'Устройство не найдено', manualAddStatus: 'Добавить вручную',
    connecting: 'Подключение...',
    deviceNotFoundHint: 'Убедитесь, что устройство подключено к питанию и WiFi,\nили что Bluetooth включён.',
    manualAddLabel: 'Добавить вручную', deviceNameLabel: 'Имя устройства', deviceDeleteConfirm: 'Удалить это устройство из приложения? Позже его можно будет снова добавить повторным сканированием.',
    ipAddressOptional: 'IP-адрес (необязательно)', back: 'Назад',
    faceConfigured: '✓ Настроено', faceIdTitle: 'Идентификация лица',
    faceIdSubtitle: 'Зарегистрируйте людей для автоматического распознавания',
    faceTraining: 'Обучение модели...',
    faceTrainModelFmt: 'Обучение модели ({enrolled}/{total} зарегистрировано)',
    facePrepGroup: 'Подготовка группы...',
    faceTrainStartFailed: '❌ Не удалось начать обучение',
    faceTrainingProgress: 'Обучение... (может занять до 60 секунд)',
    faceTrainSuccess: '✅ Модель успешно обучена! Распознавание активно.',
    faceTrainFailed: '❌ Обучение не удалось. Попробуйте снова.',
    faceSetAzureKeyFirst: 'Сначала добавьте ключ Azure API',
    faceAddingPhoto: 'Добавление фото в Azure...',
    faceCreateRecordError: '❌ Ошибка создания записи в Azure',
    faceFaceNotDetected: '❌ Не удалось обнаружить лицо на этом фото',
    facePhotoAddedFmt: '✅ Фото добавлено в {name}. Обучите модель.',
    faceNotConfiguredTap: 'Не настроено — нажмите для настройки',
    faceCheckConnection: 'Проверьте подключение',
    faceGetFreeApiKey: 'Получите бесплатный ключ API на portal.azure.com → Cognitive Services',
    faceSaveSettingsFirst: '⚠️ Сначала сохраните настройки',
    faceAzureConnOk: '✅ Подключение к Azure успешно!',
    faceAzureConnFailed: '❌ Не удалось подключиться. Проверьте Endpoint + Key',
    faceEnrolledAzure: '✓ Зарегистрирован в Azure', faceNotEnrolled: '⚠ Не зарегистрирован — добавьте фото',
    faceAddPerson: 'Добавить человека', faceFullNameHint: 'Полное имя',
    faceEnterName: 'Введите имя', faceCreatingRecord: 'Создание записи...',
    faceNoPeople: 'Нет зарегистрированных людей',
    faceNoPeopleHint: 'Добавьте людей, чтобы камеры\nраспознавали их по имени',
    roomSettings: 'Настройки комнаты', capComingSoonFmt: '{cap} — скоро',
    householdNoAdmin: 'Администратор дома ещё не назначен',
    householdMemberNote: 'Доступ как участник станет доступен после регистрации администратора через Google или Apple.',
    backToLogin: 'Вернуться ко входу', householdAdmin: 'Администратор дома',
    selectProfile: 'Выбрать профиль', noMembersYet: 'Участников пока нет',
    addMembersHint: 'Администратор может добавлять участников\nиз Профиля → Управление домом.',
    switchScanProgressFmt: 'Сканирование... {n} / 254',
    switchNoDevicesHint: 'Устройства не найдены. Убедитесь, что они подключены к той же WiFi',
    scanDoneFmt: 'Сканирование завершено — {n} устройств', scanWifi: 'Сканировать WiFi',
    faceAnalysisTitle: 'Анализ распознавания лиц',
    faceAnalysisSubtitle: 'История сканирований камер',
    clear: 'Очистить', clearHistory: 'Очистить историю',
    clearHistoryConfirm: 'Удалить все результаты анализа?',
    statScans: 'Сканирований', statFacesDetected: 'Лиц обнаружено',
    statAlerts: 'Оповещений', faces: 'Лица', smiling: 'Улыбается', eyesClosed: 'Глаза закрыты',
    noFacesInFrame: 'Лица не обнаружены в этом кадре',
    noAnalysesYet: 'Анализов пока нет',
    faceAnalysisHint: 'Откройте камеру и нажмите "Анализ"\nдля начала распознавания лиц',
    smartHomeTitle: 'Умный дом',
    temperatureFmt: 'Темп: {n}°C', brightnessFmt: 'Яркость: {n}%', positionFmt: 'Позиция: {n}%',
    wizIdentifyingWifi: 'Определение сети WiFi…',
    wizNoWifi: 'Нет WiFi — введите IP вручную',
    wizBroadcastingFmt: 'Трансляция на {prefix}.x …',
    wizNoFound: 'Лампы WiZ не найдены — попробуйте вручную',
    wizFoundFmt: 'Найдено {n} ламп',
    wizScanFailed: 'Сканирование не удалось — попробуйте вручную',
    wizBlinkingFmt: 'Мигание {ip} …',
    wizBlinkSentFmt: 'Команда мигания отправлена на {ip} ✓',
    wizNoResponseFmt: 'Нет ответа от {ip} - убедитесь, что лампа в сети',
    wizDeviceAddedFmt: '{name} добавлено — управление активно',
    wizManualAdd: 'Добавить вручную по IP', wizTest: 'Тест',
    gatewayHubTitle: 'Мосты и Хабы',
    gatewayHubSubtitle: 'Подключите хабы Zigbee, Z-Wave, WiFi и облачные',
    connected: 'Подключено', addGateway: 'Добавить мост', gatewayTypesFmt: '{n} типов',
    devicesImportedFmt: '{n} устройств импортировано из {name}',
    allDevicesExist: 'Все устройства уже существуют',
    diagnosisTitle: 'Устройства, сообщённые хабом',
    disconnectConfirmFmt: 'Отключить "{name}"?',
    importedDevicesNote: 'Импортированные устройства останутся, но больше нельзя будет импортировать.',
    disconnect: 'Отключить', deviceCountFmt: '{n} устройств',
    importDevices: 'Импортировать устройства', connect: 'Подключить',
    connectAfterButton: 'Подключить (после нажатия кнопки)',
    connectedSuccess: 'Успешно подключено!',
    secondsRemainingFmt: '{n} секунд осталось', cloud: 'Облако',
    cloudConnectionNote: 'Облачное подключение — данные проходят через серверы производителя',
    setupStepsHintFmt: 'Как получить данные? ({n} шагов)',
    tokenPortalFmt: 'Token создаётся на портале {name}', optional: 'Необязательно',
    z2mEnterIp: 'Введите IP Zigbee2MQTT',
    z2mUnreachableFmt: 'Не удалось подключиться к Zigbee2MQTT по {ip}:{port}\nУбедитесь, что фронтенд активен и IP верный',
    z2mUnknownError: 'Неизвестная ошибка',
    z2mSubtitle: 'Подключите Zigbee хаб — автоимпорт устройств',
    z2mIpLabel: 'IP Z2M', z2mIpHint: 'Пример: 192.168.1.50',
    z2mPortLabel: 'Порт', z2mTokenLabel: 'API Token (необязательно)',
    z2mTokenHint: 'Если настроен', z2mFoundFmt: 'Найдено {n} Zigbee устройств!',
    z2mConnectImport: 'Подключить и импортировать',
    z2mFrontendHelp: 'Включите фронтенд в настройках Z2M:\n  frontend:\n    port: 8080',
    discoveryTitle: 'Обнаружение устройств', scan: 'Сканировать',
    matterDeviceTitle: 'Устройство Matter',
    matterDeviceHelp: 'Устройства Matter (например лампы IKEA) подключаются через хаб Matter — не напрямую из приложения.\n\nПростой способ:\n1. Подключите лампу к DIRIGERA через приложение IKEA Home smart.\n2. Здесь: Мосты → DIRIGERA → "Импортировать устройства".\nЛампа появится с полным управлением.',
    understood: 'Понятно', devicesAddedFmt: 'Добавлено {n} устройств',
    haFound: 'Home Assistant найден',
    haConnectedFmt: 'Подключено — импортировано {n} устройств',
    haConnect: 'Подключить',
    haReconnectSync: 'Переподключить и синхронизировать',
    haTokenHint: 'Создайте Token в: Профиль → Long-Lived Access Tokens',
    importFromHa: 'Импортировать устройства из Home Assistant',
    scanningDevices: 'Поиск устройств…',
    scanHint: 'Нажмите "Сканировать" для поиска устройств в сети',
    addAllFmt: 'Добавить все ({n} устройств)',
    matterCommTitle: 'Сопряжение устройства Matter',
    matterCommSubtitle: 'Сканируйте QR на этикетке устройства',
    matterCommScanBtn: 'Сканировать QR', matterCommManualBtn: 'Ввести код вручную',
    matterCommManualHint: 'Код из 11 цифр (пример 12345-67890)',
    matterCommissioning: 'Сопряжение через Home Assistant…',
    matterCommSuccess: 'Устройство успешно сопряжено!',
    matterCommFailed: 'Сопряжение не удалось. Убедитесь, что интеграция Matter активна в HA.',
    matterCommNoHa: 'Home Assistant не подключён. Сначала подключите HA.',
    matterCommRetry: 'Повторить', matterCommCodeHint: 'MT:… или код из 11 цифр',
    blindsHubTitle: 'Шторы и Жалюзи', openAll: 'Открыть все', closeAll: 'Закрыть все',
    noBlindsFound: 'Шторы не найдены',
    blindsHint: 'Добавьте шторы через Home Assistant',
    smartLocksTitle: 'Умные замки', lockedStatus: 'Заблокировано', unlockedStatus: 'Разблокировано',
    lockAll: 'Заблокировать все', unlockAll: 'Разблокировать все',
    noLocksFound: 'Замки не найдены',
    lockHint: 'Добавьте умный замок через Home Assistant',
    lightsHubTitle: 'Освещение', lightsAllOn: 'Включить все', lightsAllOff: 'Выключить все',
    noLightsFound: 'Освещение не найдено',
    lightsHint: 'Добавьте освещение через Home Assistant',
    plugsHubTitle: 'Умные розетки', plugsAllOn: 'Включить все', plugsAllOff: 'Выключить все',
    noPlugsFound: 'Розетки не найдены',
    plugsHint: 'Добавьте розетки через сканирование WiFi',
    acHubTitle: 'Кондиционирование',
    intercomTitle: 'Домофон', intercomNoDevices: 'Устройства домофона не найдены',
    intercomHint: 'Добавьте домофон из каталога или через импорт шлюза',
    intercomRing: 'Позвонить', intercomAnswer: 'Ответить', intercomDecline: 'Отклонить',
    intercomCategory: 'Видеозвонок', intercomRinging: 'Кто-то у двери…',
    vacuumCategory: 'Робот-пылесос', vacuumNoDevices: 'Роботы-пылесосы не найдены',
    vacuumHint: 'Подключите робота-пылесоса через Home Assistant, чтобы увидеть его здесь',
    vacuumStart: 'Старт', vacuumPause: 'Пауза', vacuumDock: 'На базу',
    vacuumCleaning: 'Уборка', vacuumDocked: 'На базе',
    intercomUnlockDoor: 'Открыть дверь',
    energyRateLabel: 'Тариф электроэнергии', energyRateEdit: 'Изменить тариф',
    energyRateUnit: '₪/кВт·ч', energyRateSaved: 'Тариф сохранён',
    backupTitle: 'Резервное копирование и восстановление', backupExport: 'Экспорт настроек',
    backupImport: 'Импорт настроек', backupExportDone: 'Настройки экспортированы',
    backupImportDone: 'Настройки успешно восстановлены', backupImportError: 'Ошибка импорта — неверный файл',
    backupSection: 'Данные и резервное копирование',
    biometricSplashLabel: 'Аутентификация',
    camLocationPermission: 'Для сканирования сети требуется разрешение геолокации',
    camNoWifiIp: 'Не удалось определить вашу сеть WiFi — подключитесь к WiFi и попробуйте снова, или добавьте камеру вручную',
    camScanNoneFound: 'Камеры в сети не найдены. Если ваша камера не поддерживает ONVIF, добавьте её вручную по IP-адресу.',
    showHideSections: 'Показать / Скрыть разделы', restoreDefaults: 'Восстановить настройки по умолчанию?', restoreDefaultsConfirm: 'Это сбросит расположение панели безопасности. Отменить невозможно.', restore: 'Восстановить', systemTest: 'Тест системы',
  );

  // ── French ────────────────────────────────────────────────────
  static const S _fr = S(
    homeGreetingSub: 'Votre maison, sûre et intelligente.', energyToday: 'Énergie aujourd\'hui', vsYesterday: 'vs hier',
    climateEnergyTitle: 'Climat et énergie', homeManagementTitle: 'Gestion de la maison',
    energyAnalytics: 'Analyse énergétique', securitySystemLabel: 'Système de sécurité',
    secArmedShort: 'Armé', secDisarmedShort: 'Désarmé', allOkLabel: 'Tous les systèmes OK', emergencyBtn: 'Urgence',
    showAll: 'Tout voir', roomsHeader: 'Pièces', statHomesLabel: 'Maisons', devicesUnit: 'appareils',
    systemStatus: 'État du système', statusInternet: 'Internet', statusSensors: 'Capteurs', connectedLabel: 'Connecté',
    camMotion: 'Mouvement détecté', camOnline: 'En ligne', camOffline: 'Hors ligne', locationUnavailable: 'Localisation indisponible',
    gatewaysManage: 'Gérer', secArmStayBtn: 'Armer (présence)', secDisarmBtn: 'Désarmer',
    roomNameMedia: 'Médias', mediaRoomTitle: 'Médias', roomOccupantLabel: 'Qui utilise cette pièce ?',
    occupantNone: 'Personne', occupantKids: 'Enfants', occupantAdults: 'Adultes',
    navHome: 'Accueil', navCameras: 'Caméras', navSecurity: 'Sécurité', navProfile: 'Profil', navAutomations: 'Automatisations',
    greetingPrefix: 'Bonjour', homeSecured: 'Votre maison est sécurisée', homeNotSecured: 'Maison non sécurisée',
    allSystemsActive: 'Tous les systèmes actifs', tapToActivate: 'Touchez pour activer la sécurité',
    alarmTitle: 'Alarme', alarmSecured: 'Sécurisé', alarmOff: 'Désactivé', roomManagement: 'Gestion du foyer', roomsUnit: 'pièces',
    camerasTitle: 'Caméras', lightsOn: 'lumières allumées', lightingTitle: 'Éclairage',
    tempTitle: 'Température', tempComfy: 'Confortable', aiSubtitle: 'Comment puis-je vous aider ?', aiTopSubtitle: 'L\'assistant de votre maison intelligente',
    quickActions: 'Actions rapides', leaveHome: 'Quitter la maison', turnOffAll: 'Tout éteindre', goodNight: 'Bonne nuit', movieMode: 'Mode cinéma',
    mediaTitle: 'Médias', mediaSpeakers: 'Enceintes', mediaScan: 'Rechercher des appareils', mediaNoDevices: 'Aucune enceinte trouvée. Touchez pour rechercher.',
    bioTitle: 'Connexion rapide', bioPrompt: "Activer la connexion par empreinte la prochaine fois ?", bioEnable: 'Activer', bioSkip: 'Plus tard', bioReason: 'Authentifiez-vous pour vous connecter',
    onbNext: 'Suivant', onbStart: 'Commencer', onbSkip: 'Passer', onbAllow: 'Autoriser', onbLater: 'Plus tard', onb1Title: 'Bienvenue sur FantaTech', onb1Body: 'Votre maison intelligente — éclairage, sécurité, climat et énergie, tout au même endroit.', onb2Title: 'Contrôle total', onb2Body: 'Gérez caméras, capteurs, interrupteurs et détecteurs depuis partout, dans toutes les langues.', onb3Title: 'Automatisations intelligentes', onb3Body: 'Créez des scènes, économisez l\'énergie et recevez des alertes en temps réel.', onbPermTitle: 'Autorisations pour la découverte d\'appareils', onbPermBody: 'Pour trouver les appareils sur votre réseau, nous avons besoin de l\'accès à la Localisation et au Bluetooth. Vos données restent uniquement sur votre appareil.',
    secSection: 'Sécurité', bioLoginLabel: 'Connexion par empreinte', bioLoginSub: 'Connectez-vous rapidement en biométrie', bioUnavailable: 'Biométrie non prise en charge sur cet appareil', legalSection: 'Mentions légales et confidentialité', termsLabel: 'Conditions d\'utilisation', privacyLabel: 'Politique de confidentialité',
    sceneCreate: 'Créer une scène', sceneNew: 'Nouvelle scène', sceneName: 'Nom de la scène', sceneActions: 'Actions', actPlugs: 'Prises', valKeep: 'Inchangé', valOn: 'Allumé', valOff: 'Éteint',
    authEmailHint: 'E-mail ou téléphone', authPassHint: 'Mot de passe', loginGreeting: 'Bonjour !', loginSubtitle: 'Connectez-vous à votre compte', loginForgot: 'Mot de passe oublié ?', resetEmailHint: 'Entrez votre e-mail et nous vous enverrons un lien de réinitialisation.', resetEmailSent: 'Lien envoyé ! Vérifiez votre boîte mail.', okButton: 'OK', cancelButton: 'Annuler', sendButton: 'Envoyer', loginButton: 'Se connecter', authOr: 'ou', loginNoAccount: "Vous n'avez pas de compte ?", registerNow: "S'inscrire", continueAsGuest: "Continuer en tant qu'invité", loginWith: 'Se connecter avec', appTagline: 'Solutions maison intelligente et sécurité', registerTitle: 'Créer un compte', registerSubtitle: 'Rejoignez la maison intelligente FantaTech', confirmPassHint: 'Confirmer le mot de passe', registerButton: "S'inscrire", haveAccount: 'Vous avez déjà un compte ?', loginHousehold: 'Membre du foyer',
    errEnterName: 'Veuillez saisir votre nom complet', errEnterEmail: 'Veuillez saisir un e-mail ou un téléphone', errPassShort: 'Le mot de passe doit comporter au moins 6 caractères', errPassMismatch: 'Les mots de passe ne correspondent pas',
    acMode: 'Mode', acFanSpeed: 'Vitesse du ventilateur', acSwing: 'Oscillation', acPreset: 'Préréglage', acMethod: 'Contrôle', modeCool: 'Froid', modeHeat: 'Chaud', modeFan: 'Ventilation', modeDry: 'Déshumidification', modeAuto: 'Auto', fanLow: 'Faible', fanMed: 'Moyen', fanHigh: 'Élevé',
    mediaMaster: 'Volume principal', mediaParty: 'Lire partout', mediaStopAll: 'Tout arrêter',
    tvRemote: 'Télécommande TV', tvSource: 'Source', tvChannel: 'Chaîne', tvMute: 'Muet',
    faq1Q: 'Comment ajouter un appareil ?', faq1A: 'Touchez + sur le tableau de bord et choisissez l\'appareil dans le catalogue.', faq2Q: 'Comment changer de langue ?', faq2A: 'Profil → Paramètres → Langue.', faq3Q: 'L\'application fonctionne-t-elle hors ligne ?', faq3A: 'Les commandes locales fonctionnent. Le cloud nécessite Internet.', faq4Q: 'Comment créer une automatisation ?', faq4A: 'Touchez « Automatisations » dans le menu du bas → Ajouter.',
    energyTitle: 'Consommation d\'énergie', automationsTitle: 'Automatisations', activeAutomations: 'automatisations actives',
    myProfile: 'Mon profil', myHome: 'Ma maison', usersTitle: 'Utilisateurs',
    subscriptionTitle: 'Abonnement', settingsTitle: 'Paramètres', helpTitle: 'Aide et support',
    signOut: 'Se déconnecter', languageLabel: 'Langue', themeLabel: 'Thème',
    darkMode: 'Sombre', lightMode: 'Clair', appearanceTitle: 'Apparence', themeFont: 'Police', themeAccent: 'Couleur d\'accent', themeBg: 'Arrière-plan', themeRadius: 'Arrondi', themeBgDarkBlue: 'Bleu foncé', themeBgAmoled: 'Noir AMOLED', themeBgDarkGray: 'Gris foncé', themeBgLightGray: 'Bleu clair', themeBgLightWhite: 'Blanc pur', themeRadiusSharp: 'Net', themeRadiusNormal: 'Normal', themeRadiusRound: 'Arrondi', saveChanges: 'Enregistrer',
    editProfile: 'Modifier le profil', fullName: 'Nom complet', emailLabel: 'E-mail',
    profileUpdated: 'Profil mis à jour avec succès', signOutConfirm: 'Se déconnecter', signOutQuestion: 'Voulez-vous vraiment vous déconnecter ?', confirmSignOut: 'Se déconnecter',
    securityTitle: 'Sécurité', armedMode: 'Armé', disarmedMode: 'Désarmé',
    doorSensor: 'Porte d\'entrée', windowsSensor: 'Fenêtres', motionSensors: 'Détecteurs de mouvement', smokeDetector: 'Détecteur de fumée', waterLeakSensor: 'Détecteur de fuite d\'eau',
    securedStatus: 'Sécurisé', openStatus: 'Ouvert', activeStatus: 'Actif', normalStatus: 'Normal',
    panicButton: 'Bouton panique', panicActivate: 'Activer !', panicWarning: 'Cela enverra une alerte d\'urgence',
    welcomeGuestBtn: 'Bienvenue Invité', welcomeGuestActive: 'Mode invité actif', welcomeGuestTimer: '{n} min restantes', welcomeGuestCancel: 'Annuler mode invité', welcomeGuestHint: 'Désarme la sécurité pour l\'invité · réarmement auto',
    welcomeGuestChoose: 'Choisir la durée', guestOptShort: 'Visite courte', guestOptMedium: 'Visite standard', guestOptLong: 'Visite longue', guestMinutes: 'min',
    chooseBrand: 'Choisir la marque', pairingSteps: 'Étapes de couplage',
    allCameras: 'Toutes les caméras', liveLabel: 'EN DIRECT', offlineLabel: 'Hors ligne', deviceOn: 'Activé', deviceOff: 'Désactivé', deleteAll: 'Tout supprimer', deleteAllConfirm: 'Supprimer tous les appareils de la liste?',
    addDeviceBtn: 'Ajouter un appareil', notificationsTitle: 'Notifications',
    timeNow: 'maintenant', timeMinAgo: 'il y a {n} min', timeHrAgo: 'il y a {n} h', timeDayAgo: 'il y a {n} j', deviceConnectedFmt: 'Appareil connecté : {name}',
    camFrontDoor: 'Porte d\'entrée', camBackDoor: 'Porte arrière', camGarage: 'Garage', camBackyard: 'Cour arrière', camEntrance: 'Entrée', camDriveway: 'Allée', camBalcony: 'Balcon',
    autoMotionNight: 'Éclairage nocturne par mouvement', autoArrive: 'Arrivée à la maison', autoMorning: 'Bonjour', autoEnergySave: 'Économie d\'énergie',
    condMotionNight: 'Mouvement la nuit (21:00–06:00)', condNobodyHome: 'Si personne n\'est à la maison', condArrive: 'À l\'arrivée à la maison', condTime2300: 'À 23:00', condMorningWeekday: 'À 07:00 en semaine', condNoMotion30: 'Si aucun mouvement pendant 30 min',
    actAllLightsOn: 'Allumer toutes les lumières', actAlarmOffAll: 'Armer l\'alarme + tout éteindre', actLightsAlarmOff: 'Lumières allumées + désarmer', actOffLock: 'Tout éteindre + verrouiller', actBlindsCoffee: 'Ouvrir les volets + lancer le café', actOffLightsAc: 'Éteindre lumières et clim',
    catSmoke: 'Fumée', catEnergy: 'Énergie', actionTurnOn: 'Allumer', actionTurnOff: 'Éteindre',
    cyberNoEvents: 'Aucun événement récent', cyberNetworkMap: 'Carte du réseau', cyberNetworkTopology: 'Topologie du réseau', cyberPhones: 'Téléphones', cyberOnlineFmt: '{on} / {total} en ligne',
    homeTypeLabels: const ['Maison','Appartement','Villa','Chalet','Cabane','Tour','Penthouse','Ferme','Ranch','Yacht'],
    homeColorLabels: const ['Bleu','Violet','Vert','Orange','Or','Rouge','Turquoise','Rose','Marron','Gris'],
    homeTypeTitle: 'Type de maison', homeColorTitle: 'Couleur', colorMix: 'Mélange de couleurs', pickLabel: 'Choisir',
    profilePhotoFmt: 'Photo de profil — {name}', inviteSubject: 'Invitation à rejoindre ma maison intelligente', inviteBodyFmt: 'Bonjour,\n\nJe vous invite à rejoindre ma maison intelligente via l\'application FantaTech.\n\nCode d\'adhésion : {code}\n\nTéléchargez l\'application et entrez le code pour rejoindre.', noEmailApp: 'Aucune application e-mail trouvée sur l\'appareil', regManagerMsg: 'Enregistré comme gestionnaire du foyer !', nameFieldFmt: 'Nom : {name}', homeJoinTitle: 'Code d\'adhésion au foyer', shareCodeHint: 'Partagez le code avec les membres du foyer\npour qu\'ils puissent rejoindre', gotIt: 'Compris', homeStyleTitle: 'Style de la maison', registerAsFmt: 'S\'inscrire comme : {name}', newCodeFmt: 'Nouveau code généré : {code}', joinCodeInline: 'Code d\'adhésion au foyer :  ', inviteByEmail: 'Inviter un membre par e-mail', inviteByEmailSub: 'Envoyer le code d\'adhésion directement par e-mail',
    tailscaleWhat: 'Qu\'est-ce que Tailscale ?', tailscaleDesc: 'Un VPN gratuit pour l\'accès à distance à votre réseau domestique.\nConnecte votre téléphone au réseau de la maison de façon chiffrée, même à l\'extérieur.', tailscaleStep1: 'Installez Tailscale sur votre téléphone et Raspberry Pi / HA Green', tailscaleStep2: 'Connectez-vous avec le même compte (Google / Apple / Email)', tailscaleStep3: 'Activez le bouton — l\'app ouvrira Tailscale', tailscaleOpen: 'Ouvrir / Installer Tailscale',
    camScanNetwork: 'Scanner le réseau', camScanning: 'Analyse...', camAddManual: 'Ajouter une caméra manuellement', camFieldName: 'Nom', camPort: 'Port', camUser: 'Utilisateur', camRtspPath: 'Chemin RTSP', camStreamPath: 'Chemin du flux', camRtspHint: '/  ou  /cam/realmonitor?channel=1', camPtzTitle: 'Caméra PTZ', camPtzSub: 'Activer le contrôle Pan / Tilt / Zoom', camTestConn: 'Tester la connexion', camAddBtn: 'Ajouter la caméra', camFoundFmt: '✓ Caméra trouvée ! {info} — ports ouverts : {ports}', camConnectFailFmt: '✗ Impossible de se connecter à {addr}',
    automationsAll: 'Toutes les automatisations', automationsRec: 'Suggestions', addAutomation: 'Ajouter une automatisation',
    autoName: 'Nom de l\'automatisation', autoCondition: 'Condition (Si...)', autoAction: 'Action (Alors...)',
    recPeakName: 'Économie aux heures de pointe', recPeakDesc: 'Éteindre les appareils non essentiels entre 17h00 et 20h00',
    recTravelName: 'Mode voyage', recTravelDesc: 'Sécurité complète lorsque vous êtes absent',
    recTempName: 'Contrôle de la température', recTempDesc: 'Maintenir 22° quand quelqu\'un est à la maison',
    monthlyConsumption: 'Consommation mensuelle', activeDevices: 'Appareils actifs', fullReport: 'Voir le rapport complet', fromLastMonth: 'par rapport au mois dernier',
    allNotif: 'Toutes', alertsNotif: 'Alertes', camerasNotif: 'Caméras', markAllRead: 'Tout marquer comme lu',
    devicesTitle: 'Appareils', allDevices: 'Tous', devicesOn: 'appareils allumés',
    lightsCategory: 'Lumières', blindsCategory: 'Volets', acCategory: 'Climatisation',
    plugsCategory: 'Prises', switchesCategory: 'Interrupteurs', sensorsCategory: 'Capteurs',
    deviceTemp: 'Température', deviceBrightness: 'Luminosité', devicePosition: 'Position',
    notifSettings: 'Paramètres de notification', aboutApp: 'À propos de l\'application',
    aiInputHint: 'Écrivez ou parlez-moi', aiMicUnavailable: 'Microphone non disponible',
    aiSug1: 'Éteindre toutes les lumières',
    aiSug2: 'Quel est l\'état de la maison ?',
    aiSug3: 'Activer le mode nuit',
    aiSug4: 'Y a-t-il des alertes actives ?',
    aiSugDesc1: 'Je peux éteindre toutes les lumières de la maison',
    aiSugDesc2: 'Obtenez un résumé complet de la maison et de ses systèmes',
    aiSugDesc3: 'J\'active tous les paramètres du mode nuit',
    aiSugDesc4: 'Vérifier les alertes et situations inhabituelles',
    aiPrivacyNote: 'Vos informations sont privées et protégées', aiClearChat: 'Effacer la conversation',
    aiReply1: 'Extinction de toutes les lumières... ✅\n8 lumières éteintes avec succès.',
    aiReply2: 'La maison est en bon état 🏠\n• Sécurité : Armée ✅\n• Lumières : 3 allumées\n• Température : 24°C',
    aiReply3: 'Mode nuit activé 🌙\nToutes les lumières éteintes, volets fermés.',
    aiReply4: 'Vérification du système de sécurité... 🔍\nAucune alerte active. Tous les capteurs sont normaux.',
    aiReplyDefault: 'Compris ! Je m\'en occupe... 🤖\nMise à jour à venir.',
    addDeviceTitle: 'Ajouter un appareil', autoScan: 'Analyse automatique', deviceCatalog: 'Catalogue d\'appareils',
    searchHint: 'Rechercher un appareil ou un interrupteur...', searching: 'Recherche d\'appareils...', devicesFound: 'Appareils trouvés', noResults: 'Aucun résultat',
    navDevices: 'Appareils',
    subscriptionPro: 'Abonnement Pro', subscriptionValid: 'Actif jusqu\'au 31/12/2025', subscriptionRenew: 'Renouveler l\'abonnement',
    subscriptionFeat1: 'Caméras illimitées', subscriptionFeat2: 'Stockage cloud 30 jours', subscriptionFeat3: 'IA intelligente', subscriptionFeat4: 'Support 24/7',
    catalogLights: 'Éclairage', catalogSwitches: 'Interrupteurs et prises', catalogSensors: 'Capteurs', catalogCameras: 'Caméras', catalogAC: 'Climatisation', catalogBlinds: 'Volets et portails', catalogNetwork: 'Routeurs et passerelles',
    scanPairingHint: 'Assurez-vous que l\'appareil est en mode appairage et allumé',
    acRemoteName: 'Télécommande IR de climatiseur', acRemoteCategory: 'Télécommande IR',
    acWifiName: 'Climatiseur WiFi', acWifiCategory: 'Climatiseur WiFi',
    devBulb: 'Ampoule connectée', devStrip: 'Bande LED', devSwitch: 'Interrupteur connecté', devDimmer: 'Variateur connecté', devPlug: 'Prise connectée',
    devMotionSensor: 'Détecteur de mouvement', devDoorSensor: 'Capteur de porte', devWindowSensor: 'Capteur de fenêtre', devSmokeDetector: 'Détecteur de fumée',
    devIndoorCam: 'Caméra intérieure', devOutdoorCam: 'Caméra extérieure',
    devSmartAC: 'Climatiseur connecté', devWaterHeater: 'Chauffe-eau', devThermostat: 'Thermostat',
    devSmartBlind: 'Volet connecté', devSmartGate: 'Portail connecté',
    devRouterWifi: 'Routeur WiFi', devGwZigbee: 'Passerelle Zigbee', devGwWifi: 'Passerelle WiFi', devGwMatter: 'Passerelle Matter',
    catLight: 'Lumière', catSwitch: 'Interrupteur', catPlug: 'Prise', catSensor: 'Capteur', catCamera: 'Caméra',
    catClimate: 'Climat', catBlind: 'Volet', catGate: 'Portail', catRouter: 'Routeur', catGateway: 'Passerelle',
    networkLabel: 'Réseau', wifiNotConnected: 'Non connecté au WiFi',
    connectWifiHint: 'Connectez-vous au WiFi de votre maison et réessayez',
    scanComplete: 'Analyse terminée', scanError: 'Erreur d\'analyse', rescan: 'Analyser à nouveau',
    noDevicesOnNetwork: 'Aucun appareil trouvé sur le réseau',
    sameWifiHint: 'Assurez-vous que les appareils sont sur le même WiFi',
    connectedStatus: 'Connecté', noDevicesConnected: 'Aucun appareil connecté',
    scanToDiscover: 'Analysez votre réseau pour découvrir et ajouter des appareils intelligents',
    scanFindDevices: 'Analyser et trouver des appareils', remove: 'Supprimer',
    deviceWillBeRemoved: 'L\'appareil sera retiré de la liste', haRemoveDeviceFailed: 'Retiré de la liste, mais impossible de le supprimer de Home Assistant', ipAddressLabel: 'Adresse IP',
    displayLabel: 'Affichage', discoverDevices: 'Découvrir des appareils', scanViaGateway: 'Analyse via',
    scanStarting: 'Démarrage de l\'analyse…',
    scanWifiLog: 'WiFiScanner : démarrage de l\'analyse LAN',
    scanWifiDoneFmt: 'WiFiScanner : terminé ({n} hôtes)',
    scanBleLog: 'BLEScanner : démarrage de l\'analyse BLE',
    scanBleDone: 'BLEScanner : terminé',
    scanMatterLog: 'MatterDiscovery : recherche mDNS',
    scanMatterDone: 'MatterDiscovery : terminé',
    scanGatewayFmt: 'Sondage approfondi de {n} appareils',
    scanGatewayDone: 'Sondage approfondi : terminé',
    scanIdentifyingFmt: 'Identification de {n} appareils…',
    scanIdentifyingProgress: 'Identification des appareils…',
    scanFinishedFmt: 'Analyse terminée — {n} appareils trouvés',
    scanFoundFmt: '{n} appareils trouvés',
    scanNoDevicesFound: 'Aucun appareil trouvé',
    scanCancelledProgress: 'Analyse annulée',
    scanCancelledLog: 'Analyse annulée par l\'utilisateur',
    fromGallery: 'Choisir dans la galerie', fromCamera: 'Prendre une photo', removePhoto: 'Supprimer la photo',
    scanBarcode: 'Scanner code-barres / QR', editUserName: 'Modifier le nom d\'utilisateur', searchScanProducts: 'Rechercher des produits sur le réseau',
    cameraRoomIndoor: 'Intérieur', cameraRoomOutdoor: 'Extérieur',
    micLabel: 'Micro', speakLabel: 'Parler', screenshotLabel: 'Capturer', recordLabel: 'Enregistrer',
    deviceFound: 'Appareil trouvé !', linkDevice: 'Associer l\'appareil',
    deviceNotFound: 'Appareil introuvable', retrySearch: 'Réessayer',
    cyberTitle: 'Cybersécurité', cyberScore: 'Score', cyberNetProtected: 'Réseau protégé', cyberNeedsImprovement: 'À améliorer',
    cyberNoThreats: 'Aucune menace active détectée', cyberActiveThreats: 'menaces actives', cyberLastScan: 'Dernière mise à jour : il y a 2 heures',
    cyberDevicesMetric: 'Appareils', cyberConnected: 'Connecté', cyberThreats: 'Menaces', cyberNoThreatsSub: 'Aucune menace',
    cyberNeedsTreatment: 'Attention requise', cyberEncryption: 'Chiffrement', cyberNetProtection: 'Protection du réseau',
    cyberFirewallTitle: 'Pare-feu', cyberFirewallSub: 'Protège le réseau domestique',
    cyberVpnSub: 'Chiffre le trafic réseau', cyberDnsTitle: 'Blocage DNS malveillant', cyberDnsSub: 'Filtre les sites dangereux',
    cyberIotTitle: 'Isolation des appareils IoT', cyberIotSub: 'Réseau séparé pour les appareils connectés',
    cyberDeviceAudit: 'Audit des appareils', cyberFirmware: 'Mises à jour du firmware', cyberFirmwareUpToDate: 'appareils à jour',
    cyberDefaultPassTitle: 'Mots de passe par défaut', cyberDefaultPassSub: 'Aucun mot de passe par défaut trouvé',
    cyberSecurityProto: 'Protocole de sécurité', cyberRemoteAccess: 'Accès à distance', cyberRemoteAccessSub: 'Limité aux utilisateurs autorisés',
    cyberStatusActive: 'Actif', cyberStatusOff: 'Désactivé', cyberStatusWarning: 'Avertissement',
    cyberBadgeOk: 'OK', cyberBadgeRecommended: 'Recommandé', cyberBadgeCheck: 'Vérifier',
    cyberRecentEvents: 'Événements récents',
    cyberEvent1Time: 'Il y a 2 heures', cyberEvent1Text: 'Analyse du réseau terminée avec succès',
    cyberEvent2Time: 'Il y a 6 heures', cyberEvent2Text: 'Nouvel appareil connecté au réseau',
    cyberEvent3Time: 'Hier 22:14', cyberEvent3Text: 'Tentative d\'accès non autorisé bloquée',
    cyberEvent4Time: 'Il y a 3 jours', cyberEvent4Text: 'Mise à jour de sécurité installée automatiquement',
    cyberNavLabel: 'Cyber',
    storeTitle: 'Ma boutique', storeNavLabel: 'Boutique', storeFeatured: 'Produits en vedette',
    storeNewArrivals: 'Nouveautés', storeAddToCart: 'Ajouter au panier', storeComingSoon: 'Bientôt disponible',
    storeSearchHint: 'Rechercher des produits…', storeNoResultsFor: 'Aucun résultat pour',
    storeSearchSite: 'Rechercher sur FantaTech', storeViewAll: 'Tout voir',
    storeNotifyMe: 'Me prévenir', storeNotifyDesc: 'Saisissez votre e-mail et nous vous préviendrons dès que le Hub Pro 2.0 sera disponible :',
    storeYourEmail: 'Votre e-mail', storeHubProTagline: 'Le hub de maison intelligente nouvelle génération.',
    storeBrowserError: 'Impossible d\'ouvrir le navigateur',
    storeNotifySuccess: '✓ Inscription réussie ! Nous vous tiendrons informé.',
    prodMotionSensor: 'Détecteur de mouvement Shelly', prodBlindMotor: 'Moteur de volet connecté',
    prodSmartPlug: 'Prise connectée 16A', prodLedStrip: 'Bande LED 5m',
    cancel: 'Annuler', save: 'Enregistrer', add: 'Ajouter', added: 'Ajouté ✓', edit: 'Modifier', delete: 'Supprimer', close: 'Fermer',
    noNotifications: 'Aucune notification',
    qaLock: 'Verrou', qaLights: 'Lumières', qaAc: 'Clim', qaCameras: 'Caméras', qaAlerts: 'Alertes',
    qaPlugs: 'Prises', qaWaterHeater: 'Ballon', qaBreakers: 'Tableau',
    qaNoDevices: 'Aucun appareil connecté', qaNoAlerts: 'Aucune alerte', qaResetAll: 'Tout réinitialiser', qaScanDevice: 'Rechercher un appareil',
    adAddLink: 'Ajouter un lien', adCustomLink: 'Lien personnalisé',
    panicLabel: 'PANIQUE', emergencyActivated: '🚨 Mode urgence activé ! Les autorités ont été averties.',
    helpFaq: 'FAQ', helpContact: 'Nous contacter',
    helpRegisterTitle: 'S\'inscrire au support', helpNameHint: 'Nom complet', helpEmailHint: 'Adresse e-mail',
    helpMsgHint: 'Message (facultatif)', helpSendBtn: 'Envoyer', helpSentSuccess: 'Détails enregistrés ! Nous reviendrons vers vous bientôt.',
    visitWebsite: 'Visiter le site web',
    addRoom: 'Ajouter une pièce', editRoom: 'Modifier la pièce', deleteRoom: 'Supprimer la pièce',
    roomNameHint: 'Nom de la pièce', roomAdded: 'Pièce ajoutée', roomDeleted: 'Pièce supprimée', roomEdited: 'Pièce mise à jour',
    roomIconLabel: 'Icône',
    roomNameLiving: 'Salon', roomNameKitchen: 'Cuisine', roomNameBedroom: 'Chambre',
    roomNameKids: 'Chambre d\'enfants', roomNameGarden: 'Jardin', roomNameBathroom: 'Salle de bain',
    roomNameStorage: 'Rangement', roomNameAc: 'Climatisation',
    rememberMe: 'Se souvenir de moi',
    notConnectedLabel: 'Non connecté', solarTitle: 'Système solaire', solarProduction: 'Production', solarConsumption: 'Consommation',
    solarBattery: 'Batterie', solarGrid: 'Réseau', solarFeedIn: 'Injection au réseau',
    solarToday: 'Aujourd\'hui', solarConnect: 'Connecter le système', solarSaving: 'Économies',
    solarKw: 'kWh', solarStatus: 'État du système',
    energyDay: 'Jour', energyWeek: 'Semaine', energyMonth: 'Mois', energyPeak: 'Pic',
    breakersTitle: 'Disjoncteurs connectés', breakerMain: 'Disjoncteur principal',
    breakerOn: 'Marche', breakerOff: 'Arrêt', breakerTripped: 'Déclenché',
    breakerConnect: 'Connecter le disjoncteur', breakerAmps: 'Ampères',
    breakerPanel: 'Tableau électrique', breakerWifi: 'WiFi', breakerZigbee: 'Zigbee',
    calendarTitle: 'Calendrier', calendarHebrew: 'Calendrier hébraïque', calendarGregorian: 'Grégorien',
    calendarToday: 'Aujourd\'hui', calendarHoliday: 'Fête', hebrewYear: 'Année',
    hMonthTishrei: 'Tishri', hMonthCheshvan: 'Hèchvan', hMonthKislev: 'Kislev',
    hMonthTevet: 'Tévet', hMonthShvat: 'Chevat', hMonthAdar: 'Adar',
    hMonthNissan: 'Nissan', hMonthIyar: 'Iyar', hMonthSivan: 'Sivan',
    hMonthTamuz: 'Tamouz', hMonthAv: 'Av', hMonthElul: 'Eloul',
    holidayRoshHashana: 'Roch Hachana', holidayYomKippur: 'Yom Kippour',
    holidaySukkot: 'Souccot', holidaySheminiAtzeret: 'Chemini Atséret',
    holidayHanukkah: 'Hanoucca', holidayTuBishvat: 'Tou Bichvat',
    holidayPurim: 'Pourim', holidayPesach: 'Pessah',
    holidayYomHaatzmaut: 'Yom Haatsmaout', holidayLagBaomer: 'Lag Baomer',
    holidayShavuot: 'Chavouot', holidayTishaBeav: 'Ticha Beav',
    boilerTitle: 'Chauffe-eau connecté', boilerOn: 'Marche', boilerOff: 'Arrêt',
    boilerSchedule: 'Programmation', boilerTempLabel: 'Température',
    boilerTimer: 'Minuteur', boilerMode: 'Mode',
    boilerModeEco: 'Éco', boilerModeFull: 'Plein',
    boilerConnect: 'Connecter l\'appareil', boilerWifi: 'WiFi',
    boilerZigbee: 'Zigbee', boilerAddDevice: 'Ajouter un chauffe-eau',
    boilerStatus: 'État',
    boilerNotResponding: 'Ne répond pas', boilerFindGateway: 'Trouver la passerelle',
    boilerScanning: 'Analyse du réseau...', boilerGatewayFound: 'Passerelle trouvée',
    boilerGatewayNone: 'Aucune passerelle trouvée', boilerDownloadDriver: 'Télécharger le pilote',
    boilerDriverDownloading: 'Téléchargement...', boilerDriverReady: 'Pilote prêt ✓',
    boilerReconnect: 'Reconnecter', boilerSelectGateway: 'Sélectionner une passerelle',
    socketsTitle: 'Prises connectées', socketRegister: 'Enregistrer la prise',
    socketRegistered: 'Prise enregistrée', socketPower: 'Puissance',
    socketAddNew: 'Ajouter une prise', socketName: 'Nom de la prise',
    socketRoom: 'Pièce', socketProtocol: 'Protocole',
    deviceEditName: 'Modifier le nom', deviceRename: 'Nouveau nom',
    deviceRenamed: 'Nom mis à jour',
    assignRoom: 'Assigner une pièce', noRoom: 'Sans pièce', newRoom: 'Nouvelle pièce…',
    planFree: 'Gratuit', planBasic: 'Basique',
    planAdvanced: 'Avancé', planAdvancedPlus: 'Avancé Plus',
    planUnlimited: 'Illimité',
    planCurrentBadge: 'Actif', planUpgradeNow: 'Mettre à niveau',
    planSelected: 'Sélectionné', planDevicesLabel: 'Appareils',
    planRoomsLabel: 'Pièces', planAutoLabel: 'Automatisations',
    planUnlimitedLabel: 'Illimité', planAiLabel: 'Assistant IA',
    planIntercomLabel: 'Interphone',
    planCamerasLabel: 'Caméras', planSupportLabel: 'Support',
    planReadOnly: 'Lecture seule', planViewOnly: 'Contrôle : lecture seule',
    planMonthly: '/ mois',
    planFreePrice: '\$0', planBasicPrice: '\$19',
    planAdvancedPrice: '\$39', planAdvancedPlusPrice: '\$69',
    planUnlimitedPrice: '\$100',
    homeManagerLabel: 'Gestionnaire du foyer', memberLabel: 'Membre du foyer',
    noHomeUsers: 'Aucun utilisateur enregistré', registerAsManager: 'S\'inscrire comme gestionnaire',
    addMember: 'Ajouter un membre', memberName: 'Nom du membre',
    setPinCode: 'Définir un code PIN', pinCodeLabel: 'Code PIN (4 chiffres)',
    pinSaved: 'PIN enregistré', pinRemoved: 'PIN supprimé',
    devicesInRoom: 'Appareils dans la pièce', noDevicesInRoom: 'Aucun appareil dans cette pièce',
    shabbatCandles: 'Allumage des bougies', shabbatHavdalah: 'Havdala',
    keepShabbatLabel: 'Observer le Chabbat', shabbatSection: 'Chabbat',
    shabbatCandlesDesc: 'Tout éteindre ✡️ et verrouiller avant le Chabbat',
    shabbatHavdalahDesc: 'Restaurer les appareils après la fin du Chabbat',
    acConnected: 'climatiseurs connectés', acNoUnits: 'Aucun climatiseur connecté',
    adStoreLabel: 'Boutique FantaTech', adTrackTitle: 'Paramètres publicitaires',
    adTrackSub: 'Choisissez les produits affichés dans la bannière',
    adFeaturedLabel: 'Produits en vedette', adFeaturedSub: 'Hub Pro, Camera 4K, Smart Bulb, Sensor',
    adNewLabel: 'Nouveautés en boutique', adNewSub: 'Smart Blind, Smart Plug 16A, Gateway, LED Strip',
    adAllLabel: 'Tous les produits', adAllSub: 'Rotation complète du catalogue',
    adNoneLabel: 'Sans publicité', adNoneSub: 'Masquer complètement la bannière',
    autoThemeLabel: 'Thème automatique', autoThemeDesc: 'Adapte le thème à la lumière ambiante',
    autoThemeActive: 'Actif', autoThemeWaiting: 'En attente du capteur…',
    homeLayoutLabel: 'Disposition de l\'accueil',
    signOutAppTitle: 'Quitter l\'application', signOutChoose: 'Choisissez comment quitter',
    signOutToLogin: 'Se déconnecter et revenir à la connexion', signOutToLoginSub: 'Déconnecte le compte — connexion requise',
    signOutFull: 'Sortie complète', signOutFullSub: 'Se déconnecte et ferme l\'application',
    accountSection: 'Compte',
    switchAccountTitle: 'Changer de compte', switchAccountSub: 'Se déconnecter et se connecter avec un autre compte',
    switchAccountConfirmTitle: 'Changer de compte ?', switchAccountConfirmBody: 'Vous serez déconnecté et renvoyé à l\'écran de connexion.',
    switchAccountConfirmBtn: 'Changer de compte', switchAccountPasswordPrompt: 'Entrez votre mot de passe pour confirmer',
    switchAccountWrongPassword: 'Mot de passe incorrect',
    installerBadge: 'INSTALLATEUR', installerCodeTitle: 'Mode Installateur',
    installerCodeHint: "Entrez le code installateur", installerCodeWrong: 'Code installateur incorrect',
    installerModeOnMsg: 'Mode Installateur activé', installerModeOffMsg: 'Mode Installateur désactivé',
    installerExitConfirm: 'Quitter le Mode Installateur ?',
    deviceOfflineHint: 'Appareil hors ligne — vérifiez sa connexion',
    aiBackendNotConfigured: "L'assistant IA n'est pas encore configuré",
    aiRequestFailed: "Désolé, je n'ai pas pu joindre l'assistant",
    aiEmptyReply: 'Fait.',
    aiTooManySteps: 'Cette demande nécessite trop d\'étapes — essayez plus simple',
    mirrorScreenTitle: 'Miroir connecté', adBannerShop: 'Boutique',
    gatewaysTitle: 'Passerelles', statusOffline: 'Hors ligne',
    confirm: 'Confirmer', pickDay: 'Jour', pickMonth: 'Mois',
    pickHebrewDate: 'Choisir une date hébraïque',
    hebrewDateFmt: 'Date hébraïque : {date}', hebrewCalendarChip: 'Date hébraïque…',
    storeBuyAt: 'Acheter chez ',
    loginBiometric: 'Se connecter par empreinte / visage',
    errInvalidEmail: 'Adresse e-mail invalide',
    loginGoogleEmailPrompt: 'Entrez votre Gmail pour continuer',
    scanNetworkTitle: 'Scanner le réseau', scanSelectDevice: 'Sélectionner un appareil à ajouter',
    stop: 'Arrêter', scanSensorsShutters: 'Capteurs · Volets',
    sensorHubTitle: 'Capteurs et Volets',
    sensorHubFoundFmt: '{sensors} capteurs · {covers} volets',
    sensorsTab: 'Capteurs', shuttersTab: 'Volets',
    noSensorsFound: 'Aucun capteur trouvé', noCoversFound: 'Aucun volet trouvé',
    coverOpen: '▲  Ouvrir', coverStop: '■  Arrêter', coverClose: '▼  Fermer',
    switchScanningAll: 'Scan de tous les protocoles…',
    switchAddedFmt: '✓ {name} ajouté au foyer',
    keyStoredLocal: 'La clé est stockée uniquement sur votre appareil.',
    saveAndControl: 'Sauvegarder et contrôler',
    tapoLogin: 'Tapo — Connexion',
    tapoCredHint: 'Mêmes identifiants que l\'application TP-Link Tapo.',
    connectAndControl: 'Connecter et contrôler',
    errControlFmt: 'Erreur de contrôle de {name}',
    switchSearchingAll: 'Recherche d\'interrupteurs intelligents sur tous les protocoles…',
    switchNoFound: 'Aucun interrupteur intelligent trouvé',
    switchHint: 'Assurez-vous que les interrupteurs sont sur le même WiFi.\nShelly/ESPHome — mode STA\nSonoff — mode DIY (firmware 3.6+)\nHome Assistant / Zigbee2MQTT — connectez dans les paramètres',
    camFrameCaptureError: 'Erreur de capture d\'image',
    camNoFaces: 'Aucun visage reconnu',
    camFacesFoundFmt: '{count} visages reconnus — {known} identifiés 🎯',
    camFacesOnlyFmt: '{count} visages reconnus 🎯',
    camAnalysisErrorFmt: 'Erreur d\'analyse : {error}',
    camCaptureError: 'Erreur de capture',
    camSnapshotSavedFmt: '📸 Enregistré : snapshot_{ts}.png',
    camSaveSnapshotError: 'Erreur d\'enregistrement de l\'image',
    camConnectingFmt: 'Connexion à {name}...',
    camIdentifyingFaces: 'Identification des visages et des identités...',
    camDetectingFaces: 'Détection des visages...',
    camFaceLabelFmt: 'Visage {n}', camStreamConnFailed: 'Impossible de se connecter au flux',
    addWizBulb: 'Ajouter une ampoule WiZ',
    addWizBulbSub: 'Contrôle LAN réel · sans cloud',
    deviceNotFoundStatus: 'Appareil introuvable', manualAddStatus: 'Ajouter manuellement',
    connecting: 'Connexion en cours...',
    deviceNotFoundHint: 'Vérifiez que l\'appareil est alimenté et connecté au WiFi,\nou que le Bluetooth est activé.',
    manualAddLabel: 'Ajouter manuellement', deviceNameLabel: 'Nom de l\'appareil', deviceDeleteConfirm: 'Supprimer cet appareil de l\'application ? Vous pourrez le rajouter plus tard en relançant une recherche.',
    ipAddressOptional: 'Adresse IP (optionnel)', back: 'Retour',
    faceConfigured: '✓ Configuré', faceIdTitle: 'Identification faciale',
    faceIdSubtitle: 'Enregistrez des personnes pour une identification automatique',
    faceTraining: 'Entraînement du modèle...',
    faceTrainModelFmt: 'Entraînement du modèle ({enrolled}/{total} enregistrés)',
    facePrepGroup: 'Préparation du groupe...',
    faceTrainStartFailed: '❌ Impossible de démarrer l\'entraînement',
    faceTrainingProgress: 'Entraînement... (peut prendre jusqu\'à 60 secondes)',
    faceTrainSuccess: '✅ Modèle entraîné avec succès ! Identification active.',
    faceTrainFailed: '❌ Entraînement échoué. Réessayez.',
    faceSetAzureKeyFirst: 'Ajoutez d\'abord la clé Azure API',
    faceAddingPhoto: 'Ajout de la photo dans Azure...',
    faceCreateRecordError: '❌ Erreur de création d\'enregistrement dans Azure',
    faceFaceNotDetected: '❌ Aucun visage détecté sur cette photo',
    facePhotoAddedFmt: '✅ Photo ajoutée à {name}. Entraînez le modèle.',
    faceNotConfiguredTap: 'Non configuré — appuyez pour configurer',
    faceCheckConnection: 'Vérifiez la connexion',
    faceGetFreeApiKey: 'Obtenez une clé API gratuite sur portal.azure.com → Cognitive Services',
    faceSaveSettingsFirst: '⚠️ Sauvegardez d\'abord les paramètres',
    faceAzureConnOk: '✅ Connexion Azure réussie !',
    faceAzureConnFailed: '❌ Connexion impossible. Vérifiez Endpoint + Key',
    faceEnrolledAzure: '✓ Enregistré dans Azure', faceNotEnrolled: '⚠ Non enregistré — ajoutez une photo',
    faceAddPerson: 'Ajouter une personne', faceFullNameHint: 'Nom complet',
    faceEnterName: 'Entrez un nom', faceCreatingRecord: 'Création de l\'enregistrement...',
    faceNoPeople: 'Aucune personne enregistrée',
    faceNoPeopleHint: 'Ajoutez des personnes pour que les caméras\nles reconnaissent par leur nom',
    roomSettings: 'Paramètres de la pièce', capComingSoonFmt: '{cap} — bientôt disponible',
    householdNoAdmin: 'Aucun administrateur du foyer pour l\'instant',
    householdMemberNote: 'L\'accès en tant que membre sera disponible après l\'inscription de l\'administrateur via Google ou Apple.',
    backToLogin: 'Retour à la connexion', householdAdmin: 'Administrateur du foyer',
    selectProfile: 'Sélectionner un profil', noMembersYet: 'Pas encore de membres',
    addMembersHint: 'L\'administrateur peut ajouter des membres\ndepuis Profil → Gestion du foyer.',
    switchScanProgressFmt: 'Scan en cours... {n} / 254',
    switchNoDevicesHint: 'Aucun appareil trouvé. Vérifiez qu\'ils sont sur le même WiFi',
    scanDoneFmt: 'Scan terminé — {n} appareils', scanWifi: 'Scanner WiFi',
    faceAnalysisTitle: 'Analyse de reconnaissance faciale',
    faceAnalysisSubtitle: 'Historique des analyses de caméras',
    clear: 'Effacer', clearHistory: 'Effacer l\'historique',
    clearHistoryConfirm: 'Supprimer tous les résultats d\'analyse ?',
    statScans: 'Analyses', statFacesDetected: 'Visages détectés',
    statAlerts: 'Alertes', faces: 'Visages', smiling: 'Souriant', eyesClosed: 'Yeux fermés',
    noFacesInFrame: 'Aucun visage détecté dans cette image',
    noAnalysesYet: 'Aucune analyse pour l\'instant',
    faceAnalysisHint: 'Ouvrez la caméra et appuyez sur "Analyser"\npour démarrer la reconnaissance faciale',
    smartHomeTitle: 'Maison intelligente',
    temperatureFmt: 'Temp : {n}°C', brightnessFmt: 'Luminosité : {n}%', positionFmt: 'Position : {n}%',
    wizIdentifyingWifi: 'Identification du réseau WiFi…',
    wizNoWifi: 'Pas de WiFi — entrez l\'IP manuellement',
    wizBroadcastingFmt: 'Diffusion sur {prefix}.x …',
    wizNoFound: 'Aucune ampoule WiZ trouvée — essayez manuellement',
    wizFoundFmt: '{n} ampoules trouvées',
    wizScanFailed: 'Scan échoué — essayez manuellement',
    wizBlinkingFmt: 'Clignotement {ip} …',
    wizBlinkSentFmt: 'Commande de clignotement envoyée à {ip} ✓',
    wizNoResponseFmt: 'Pas de réponse de {ip} - vérifiez que l\'ampoule est sur le réseau',
    wizDeviceAddedFmt: '{name} ajouté — contrôle actif',
    wizManualAdd: 'Ajouter manuellement avec IP', wizTest: 'Tester',
    gatewayHubTitle: 'Bridges et Hubs',
    gatewayHubSubtitle: 'Connectez des hubs Zigbee, Z-Wave, WiFi et cloud',
    connected: 'Connecté', addGateway: 'Ajouter un bridge', gatewayTypesFmt: '{n} types',
    devicesImportedFmt: '{n} appareils importés depuis {name}',
    allDevicesExist: 'Tous les appareils existent déjà',
    diagnosisTitle: 'Appareils signalés par le hub',
    disconnectConfirmFmt: 'Déconnecter « {name} » ?',
    importedDevicesNote: 'Les appareils importés resteront, mais l\'importation ne sera plus possible.',
    disconnect: 'Déconnecter', deviceCountFmt: '{n} appareils',
    importDevices: 'Importer les appareils', connect: 'Connecter',
    connectAfterButton: 'Connecter (après avoir appuyé sur le bouton)',
    connectedSuccess: 'Connexion réussie !',
    secondsRemainingFmt: '{n} secondes restantes', cloud: 'Cloud',
    cloudConnectionNote: 'Connexion cloud — les données passent par les serveurs du fabricant',
    setupStepsHintFmt: 'Comment obtenir les détails ? ({n} étapes)',
    tokenPortalFmt: 'Token créé sur le portail {name}', optional: 'Optionnel',
    z2mEnterIp: 'Entrez l\'IP de Zigbee2MQTT',
    z2mUnreachableFmt: 'Impossible d\'accéder à Zigbee2MQTT via {ip}:{port}\nVérifiez que le frontend est actif et l\'IP correct',
    z2mUnknownError: 'Erreur inconnue',
    z2mSubtitle: 'Connectez le hub Zigbee — importation automatique des appareils',
    z2mIpLabel: 'IP Z2M', z2mIpHint: 'Ex : 192.168.1.50',
    z2mPortLabel: 'Port', z2mTokenLabel: 'Token API (optionnel)',
    z2mTokenHint: 'Si configuré', z2mFoundFmt: '{n} appareils Zigbee trouvés !',
    z2mConnectImport: 'Connecter et importer',
    z2mFrontendHelp: 'Activez le frontend dans les paramètres Z2M :\n  frontend:\n    port: 8080',
    discoveryTitle: 'Découverte d\'appareils', scan: 'Scanner',
    matterDeviceTitle: 'Appareil Matter',
    matterDeviceHelp: 'Les appareils Matter (ex. ampoules IKEA) se couplent via un hub Matter — pas directement depuis l\'app.\n\nMéthode simple :\n1. Couplez l\'ampoule à DIRIGERA avec l\'app IKEA Home smart.\n2. Ici : Bridges → DIRIGERA → « Importer les appareils ».\nL\'ampoule apparaîtra avec le contrôle complet.',
    understood: 'Compris', devicesAddedFmt: '{n} appareils ajoutés',
    haFound: 'Home Assistant trouvé',
    haConnectedFmt: 'Connecté — {n} appareils importés',
    haConnect: 'Connecter',
    haReconnectSync: 'Se reconnecter et synchroniser',
    haTokenHint: 'Créez le Token dans : Profil → Long-Lived Access Tokens',
    importFromHa: 'Importer les appareils depuis Home Assistant',
    scanningDevices: 'Recherche d\'appareils…',
    scanHint: 'Appuyez sur « Scanner » pour rechercher des appareils sur le réseau',
    addAllFmt: 'Tout ajouter ({n} appareils)',
    matterCommTitle: 'Coupler un appareil Matter',
    matterCommSubtitle: 'Scannez le QR sur l\'étiquette de l\'appareil',
    matterCommScanBtn: 'Scanner QR', matterCommManualBtn: 'Saisir le code manuellement',
    matterCommManualHint: 'Code de 11 chiffres (ex. 12345-67890)',
    matterCommissioning: 'Couplage via Home Assistant…',
    matterCommSuccess: 'Appareil couplé avec succès !',
    matterCommFailed: 'Couplage échoué. Vérifiez que l\'intégration Matter est active dans HA.',
    matterCommNoHa: 'Home Assistant non connecté. Connectez d\'abord HA.',
    matterCommRetry: 'Réessayer', matterCommCodeHint: 'MT:… ou code de 11 chiffres',
    blindsHubTitle: 'Volets et Stores', openAll: 'Tout ouvrir', closeAll: 'Tout fermer',
    noBlindsFound: 'Aucun volet trouvé',
    blindsHint: 'Ajoutez des volets via Home Assistant',
    smartLocksTitle: 'Serrures intelligentes', lockedStatus: 'Verrouillé', unlockedStatus: 'Déverrouillé',
    lockAll: 'Tout verrouiller', unlockAll: 'Tout déverrouiller',
    noLocksFound: 'Aucune serrure trouvée',
    lockHint: 'Ajoutez une serrure intelligente via Home Assistant',
    lightsHubTitle: 'Éclairage', lightsAllOn: 'Tout allumer', lightsAllOff: 'Tout éteindre',
    noLightsFound: 'Aucun éclairage trouvé',
    lightsHint: 'Ajoutez de l\'éclairage via Home Assistant',
    plugsHubTitle: 'Prises intelligentes', plugsAllOn: 'Tout allumer', plugsAllOff: 'Tout éteindre',
    noPlugsFound: 'Aucune prise trouvée',
    plugsHint: 'Ajoutez des prises via le scan WiFi',
    acHubTitle: 'Climatisation',
    intercomTitle: 'Interphone', intercomNoDevices: 'Aucun interphone trouvé',
    intercomHint: 'Ajoutez un interphone via le catalogue ou l\'importation de passerelle',
    intercomRing: 'Sonner', intercomAnswer: 'Répondre', intercomDecline: 'Refuser',
    intercomCategory: 'Sonnette vidéo', intercomRinging: 'Quelqu\'un à la porte…',
    vacuumCategory: 'Robot aspirateur', vacuumNoDevices: 'Aucun robot aspirateur trouvé',
    vacuumHint: 'Connectez votre robot aspirateur via Home Assistant pour le voir ici',
    vacuumStart: 'Démarrer', vacuumPause: 'Pause', vacuumDock: 'Retour à la base',
    vacuumCleaning: 'Nettoyage', vacuumDocked: 'À la base',
    intercomUnlockDoor: 'Déverrouiller la porte',
    energyRateLabel: 'Tarif électricité', energyRateEdit: 'Modifier le tarif',
    energyRateUnit: '₪/kWh', energyRateSaved: 'Tarif enregistré',
    backupTitle: 'Sauvegarde et restauration', backupExport: 'Exporter les paramètres',
    backupImport: 'Importer les paramètres', backupExportDone: 'Paramètres exportés',
    backupImportDone: 'Paramètres restaurés avec succès', backupImportError: 'Erreur d\'importation — fichier invalide',
    backupSection: 'Données et sauvegarde',
    biometricSplashLabel: 'Authentifier',
    camLocationPermission: 'Autorisation de localisation requise pour scanner le réseau',
    camNoWifiIp: "Impossible de détecter votre réseau WiFi — connectez-vous au WiFi et réessayez, ou ajoutez la caméra manuellement",
    camScanNoneFound: "Aucune caméra trouvée sur le réseau. Si la vôtre n'est pas compatible ONVIF, ajoutez-la manuellement avec son adresse IP.",
    showHideSections: 'Afficher / Masquer les sections', restoreDefaults: 'Restaurer les paramètres par défaut ?', restoreDefaultsConfirm: "Cette action réinitialisera la disposition du panneau de sécurité. Impossible d'annuler.", restore: 'Restaurer', systemTest: 'Test système',
  );
}
