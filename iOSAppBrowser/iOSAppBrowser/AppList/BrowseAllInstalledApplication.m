//
//  BrowseAllInstalledApplication.m
//  iosAsst
//
//  Created by peter_peng on 14-10-10.
//  Copyright (c) 2014年 www.iphonezs.com. All rights reserved.
//

#import "BrowseAllInstalledApplication.h"
#import <dlfcn.h>
#include <objc/runtime.h>
#import <objc/message.h>

#import <UIKit/UIImage.h>
#import "Application.h"

/*
 @param format
 0 - 29x29
 1 - 40x40
 2 - 62x62
 3 - 42x42
 4 - 37x48
 5 - 37x48
 6 - 82x82
 7 - 62x62
 8 - 20x20
 9 - 37x48
 10 - 37x48
 11 - 122x122
 12 - 58x58
 */

@interface UIImage (UIApplicationIconPrivate)
+ (id)_iconForResourceProxy:(id)arg1 format:(int)arg2;
+ (id)_iconForResourceProxy:(id)arg1 variant:(int)arg2 variantsScale:(float)arg3;
+ (id)_applicationIconImageForBundleIdentifier:(id)arg1 roleIdentifier:(id)arg2 format:(int)arg3 scale:(float)arg4;
+ (id)_applicationIconImageForBundleIdentifier:(id)arg1 roleIdentifier:(id)arg2 format:(int)arg3;
+ (id)_applicationIconImageForBundleIdentifier:(id)arg1 format:(int)arg2 scale:(float)arg3;
+ (id)_applicationIconImageForBundleIdentifier:(id)arg1 format:(int)arg2;
+ (int)_iconVariantForUIApplicationIconFormat:(int)arg1 scale:(float *)arg2;
- (id)_applicationIconImageForFormat:(int)arg1 precomposed:(BOOL)arg2 scale:(float)arg3;
- (id)_applicationIconImageForFormat:(int)arg1 precomposed:(BOOL)arg2;
@end


static NSString *PARAM_APPLICATION_IDENTIFIER = @"applicationIdentifier";
static NSString *PARAM_SHORT_VERSION_STRING = @"shortVersionString";
static NSString *PARAM_BUNDLE_VERSION = @"bundleVersion";
static NSString *PARAM_SIGNER_IDENTITY = @"signerIdentity";
static NSString *PARAM_BUNDLE_EXECUTABLE = @"bundleExecutable";
static NSString *PARAM_ENTITLEMENTS = @"entitlements";
static NSString *PARAM_ENVIRONMENT_VARIABLES = @"environmentVariables";
static NSString *PARAM_BUNDLE_URL = @"bundleURL";
static NSString *PARAM_BUNDLE_CONTAINER_URL = @"bundleContainerURL";

static NSString *PARAM_LOCALIZED_NAME = @"localizedName";
static NSString *PARAM_LOCALIZED_SHORT_NAME = @"localizedShortName";
static NSString *PARAM_APPLICATION_TYPE = @"applicationType";
static NSString *PARAM_TEAM_ID = @"teamID";
static NSString *PARAM_VENDOR_NAME = @"vendorName";
static NSString *PARAM_SOURCE_APP_IDENTIFIER = @"sourceAppIdentifier";
static NSString *PARAM_REGISTERED_DATE = @"registeredDate";

static NSString *PARAM_CONTAINER_URL = @"containerURL";
static NSString *PARAM_DATA_CONTAINER_URL = @"dataContainerURL";

static NSString *PARAM_APPSTORE_RECEIPT_URL = @"appStoreReceiptURL";
static NSString *PARAM_STORE_FRONT = @"storeFront";
static NSString *PARAM_PURCHASER_DSID = @"purchaserDSID";
static NSString *PARAM_APPLICATION_DSID = @"applicationDSID";

static NSString *PARAM_CACHE_GUID = @"cacheGUID";
static NSString *PARAM_UNIQUE_IDENTIFIER = @"uniqueIdentifier";
static NSString *PARAM_MACH_O_UUIDS = @"machOUUIDs";

static NSString *PARAM_INSTALL_TYPE = @"installType";
static NSString *PARAM_ORIGINAL_INSTALL_TYPE = @"originalInstallType";
static NSString *PARAM_SEQUENCE_NUMBER = @"sequenceNumber";
static NSString *PARAM_HASH = @"hash";

static NSString *PARAM_FOUND_BACKING_BUNDLE = @"foundBackingBundle";

static NSString *PARAM_IS_ADHOC_CODE_SIGNED = @"isAdHocCodeSigned";
static NSString *PARAM_PROFILE_VALIDATED = @"profileValidated";
static NSString *PARAM_IS_INSTALLED = @"isInstalled";
static NSString *PARAM_IS_RESTRICTED = @"isRestricted";

static NSString *PARAM_UI_BACKGROUND_MODES = @"UIBackgroundModes";

static NSString *PARAM_STORE_COHORT_METADATA = @"storeCohortMetadata";
static NSString *PARAM_APP_TAGS = @"appTags";
static NSString *PARAM_COMPANION_APP_IDENTIFIER = @"companionApplicationIdentifier";

@implementation BrowseAllInstalledApplication

typedef NSDictionary* (*MobileInstallationLookup)(NSDictionary* params, id callback_unknown_usage);
NSMutableArray* browseInstalledAppListForIos7()
{
    const char *path="/System/Library/PrivateFrameworks/MobileInstallation.framework/MobileInstallation";
    void* lib = dlopen(path, RTLD_LAZY);
    if (lib) {
        MobileInstallationLookup sMobileInstallationLookup = (MobileInstallationLookup)dlsym(lib, "MobileInstallationLookup");
        if (sMobileInstallationLookup) {
            
            NSDictionary* params = [NSDictionary dictionaryWithObject:@"User"
                                                               forKey:@"ApplicationType"];
            NSMutableArray* appList = [NSMutableArray array];
            NSDictionary* dict = sMobileInstallationLookup(params, NULL);
            NSArray* allkeys = [dict allKeys];
            
            for (NSString *key in allkeys) {
                
                NSDictionary* value = [dict objectForKey:key];
                NSString* bundleVersion = [value objectForKey:@"CFBundleVersion"];
                NSString* bundleShortVersion = [value objectForKey:@"CFBundleShortVersionString"];
                NSString* bundleDisplayName = [value objectForKey:@"CFBundleDisplayName"];
                if (bundleVersion == nil) {
                    bundleVersion = @"1.0";
                }
                if (bundleShortVersion == nil) {
                    bundleShortVersion = @"1.0";
                }
                
                if (bundleDisplayName == nil) {
                    bundleDisplayName = @"Unknown";
                }

                NSDictionary* appDictionary = @{
                                                 @"bundleid" : key,
                                                 @"bundleShortVersion" : bundleShortVersion,
                                                 @"bundleVersion" : bundleVersion,
                                                 @"appName" : bundleDisplayName
                                                 };
                
                [appList addObject:appDictionary];
            }
            return appList;
        }
    }
    return nil;
}

+ (void)openApplicationWithBundleID:(NSString *)bundleID
{
    Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
    NSObject* workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
    SEL selector = NSSelectorFromString(@"openApplicationWithBundleID:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[LSApplicationWorkspace_class instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:workspace];
    [invocation setArgument:&bundleID atIndex:2];
    [invocation invoke];
}

+ (void)getBundleDetails:(NSString *)bundleID
{
    Class LSBundleProxy_class = objc_getClass("LSBundleProxy");
    NSObject *bundle = [[LSBundleProxy_class alloc] init];
    SEL selector = NSSelectorFromString(@"bundleProxyForIdentifier:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[LSBundleProxy_class instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:bundle];
    [invocation setArgument:&bundleID atIndex:2];
    [invocation invoke];
    NSObject *returnValue;
    [invocation getReturnValue:&returnValue];
    NSLog(@"ret val class: %@",[returnValue class]);
    
    if(returnValue)
    {
        selector = NSSelectorFromString(@"bundleVersion");
        invocation = [NSInvocation invocationWithMethodSignature:[LSBundleProxy_class instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:returnValue];
//        [invocation setArgument:&bundleID atIndex:2];
        [invocation invoke];
        
        NSString *bundleVersion;
        [invocation getReturnValue:&bundleVersion];
        NSLog(@"ret val class: %@",[bundleVersion class]);
        NSLog(@"Bundle version: %@",bundleVersion);
    }
}

+ (NSMutableArray *)browseInstalledAppListForIos8{
    
    Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
    NSObject* workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
    NSArray *list=[workspace performSelector:@selector(allInstalledApplications)];
    
    NSMutableArray* appList = [NSMutableArray array];
    
    for (id object in list)
    {
        SEL aSelector = NSSelectorFromString(PARAM_APPLICATION_IDENTIFIER);
        NSString *appIdentifier = @"NA";
        if([object respondsToSelector:aSelector])
        {
            appIdentifier = [object performSelector:aSelector];
            if(appIdentifier == nil)
            {
                appIdentifier = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_SHORT_VERSION_STRING);
        NSString *shortVersion = @"NA";
        if([object respondsToSelector:aSelector])
        {
            shortVersion = [object performSelector:aSelector];
            if(shortVersion == nil)
            {
                shortVersion = @"NA";
            }
        }
//        NSString *msVersion=[object performSelector:@selector(minimumSystemVersion)];
        
        aSelector = NSSelectorFromString(PARAM_BUNDLE_VERSION);
        NSString *bundleVersion = @"NA";
        if([object respondsToSelector:aSelector])
        {
            bundleVersion = [object performSelector:aSelector];
            if(bundleVersion == nil)
            {
                bundleVersion = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_SIGNER_IDENTITY);
        NSString *signerIdentity = @"NA";
        if([object respondsToSelector:aSelector])
        {
            signerIdentity = [object performSelector:aSelector];
            if(signerIdentity == nil)
            {
                signerIdentity = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_BUNDLE_EXECUTABLE);
        NSString *bundleExecutable = @"NA";
        if([object respondsToSelector:aSelector])
        {
            bundleExecutable = [object performSelector:aSelector];
            if(bundleExecutable == nil)
            {
                bundleExecutable = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_ENTITLEMENTS);
        NSDictionary *entitlements = nil;
        if([object respondsToSelector:aSelector])
        {
            entitlements = [object performSelector:aSelector];
        }
        
        aSelector = NSSelectorFromString(PARAM_ENVIRONMENT_VARIABLES);
        NSDictionary *environmentVariables = nil;
        if([object respondsToSelector:aSelector])
        {
            environmentVariables = [object performSelector:aSelector];
        }
        
        aSelector = NSSelectorFromString(PARAM_BUNDLE_URL);
        NSURL *bundleURL = nil;
        NSString *strBundleURL = @"NA";
        if([object respondsToSelector:aSelector])
        {
            bundleURL = [object performSelector:aSelector];
            if(bundleURL != nil)
            {
                strBundleURL = [bundleURL absoluteString];
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_BUNDLE_CONTAINER_URL);
        NSURL *bundleContainerURL = nil;
        NSString *strBundleContainerURL = @"NA";
        if([object respondsToSelector:aSelector])
        {
            bundleContainerURL = [object performSelector:aSelector];
            if(bundleContainerURL != nil)
            {
                strBundleContainerURL = [bundleContainerURL absoluteString];
            }
        }
        
        aSelector = NSSelectorFromString(@"itemName");
        NSString *itemName = @"NA";
        if([object respondsToSelector:aSelector])
        {
            itemName = [object performSelector:aSelector];
            if(itemName == nil)
            {
                itemName = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_LOCALIZED_NAME);
        NSString *localizedName = @"NA";
        if([object respondsToSelector:aSelector])
        {
            localizedName = [object performSelector:aSelector];
            if(localizedName == nil)
            {
                localizedName = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_LOCALIZED_SHORT_NAME);
        NSString *localizedShortName = @"NA";
        if([object respondsToSelector:aSelector])
        {
            localizedShortName = [object performSelector:aSelector];
            if(localizedShortName == nil)
            {
                localizedShortName = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_APPLICATION_TYPE);
        NSString *appType = @"NA";
        if([object respondsToSelector:aSelector])
        {
            appType = [object performSelector:aSelector];
            if(appType == nil)
            {
                appType = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(@"applicationVariant");
        NSString *applicationVariant = @"NA";
        if([object respondsToSelector:aSelector])
        {
            applicationVariant = [object performSelector:aSelector];
            if(applicationVariant == nil)
            {
                applicationVariant = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_TEAM_ID);
        NSString *teamID = @"NA";
        if([object respondsToSelector:aSelector])
        {
            teamID = [object performSelector:aSelector];
            if(teamID == nil)
            {
                teamID = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_VENDOR_NAME);
        NSString *vendorName = @"NA";
        if([object respondsToSelector:aSelector])
        {
            vendorName = [object performSelector:aSelector];
            if(vendorName == nil)
            {
                vendorName = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_SOURCE_APP_IDENTIFIER);
        NSString *sourceAppIdentifier = @"NA";
        if([object respondsToSelector:aSelector])
        {
            sourceAppIdentifier = [object performSelector:aSelector];
            if(sourceAppIdentifier == nil)
            {
                sourceAppIdentifier = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_REGISTERED_DATE);
        NSDate *registeredDate = nil;
        if([object respondsToSelector:aSelector])
        {
             registeredDate = [object performSelector:aSelector];
        }
        
//        NSNumber *staticDiskUsage=[object performSelector:@selector(staticDiskUsage)];
//        NSString *resourcesDirectoryURL=[object performSelector:@selector(resourcesDirectoryURL)];
        
        aSelector = NSSelectorFromString(PARAM_CONTAINER_URL);
        NSURL *containerURL = nil;
        NSString *strContainerURL = @"NA";
        if([object respondsToSelector:aSelector])
        {
            containerURL = [object performSelector:aSelector];
            if(containerURL != nil)
            {
                strContainerURL = [containerURL absoluteString];
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_DATA_CONTAINER_URL);
        NSURL *dataContainerURL = nil;
        NSString *strDataContainerURL = @"NA";
        if([object respondsToSelector:aSelector])
        {
            dataContainerURL = [object performSelector:aSelector];
            if(dataContainerURL != nil)
            {
                strDataContainerURL = [dataContainerURL absoluteString];
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_STORE_FRONT);
        NSNumber *storeFront = nil;
        if([object respondsToSelector:aSelector])
        {
            storeFront = [object performSelector:aSelector];
        }
        
        aSelector = NSSelectorFromString(PARAM_PURCHASER_DSID);
        NSNumber *purchaserDSID = nil;
        if([object respondsToSelector:aSelector])
        {
            purchaserDSID = [object performSelector:aSelector];
        }
        
        aSelector = NSSelectorFromString(@"downloaderDSID");
        NSNumber *downloaderDSID = nil;
        if([object respondsToSelector:aSelector])
        {
            downloaderDSID = [object performSelector:aSelector];
        }
        
        aSelector = NSSelectorFromString(PARAM_APPLICATION_DSID);
        NSString *applicationDSID = @"NA";
        if([object respondsToSelector:aSelector])
        {
            applicationDSID = [object performSelector:aSelector];
            if(applicationDSID == nil)
            {
                applicationDSID = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_APPSTORE_RECEIPT_URL);
        NSURL *appStoreReceiptURL = nil;
        NSString *strAppStoreReceiptURL = @"NA";
        if([object respondsToSelector:aSelector])
        {
            appStoreReceiptURL = [object performSelector:aSelector];
            if(appStoreReceiptURL != nil)
            {
                strAppStoreReceiptURL = [appStoreReceiptURL absoluteString];
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_CACHE_GUID);
        NSUUID *cacheGUID = nil;
        NSString *strCacheGUID = @"NA";
        if([object respondsToSelector:aSelector])
        {
            cacheGUID = [object performSelector:aSelector];
            if(cacheGUID != nil)
            {
                strCacheGUID = [cacheGUID UUIDString];
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_UNIQUE_IDENTIFIER);
        NSUUID *uniqueIdentifier = nil;
        NSString *strUniqueIdentifier = @"NA";
        if([object respondsToSelector:aSelector])
        {
            uniqueIdentifier = [object performSelector:aSelector];
            if(uniqueIdentifier)
            {
                strUniqueIdentifier = [uniqueIdentifier UUIDString];
                if(strUniqueIdentifier == nil)
                {
                    strUniqueIdentifier = @"NA";
                }
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_MACH_O_UUIDS);
        NSArray *machOUUIDs = @[@"No machO UUIDs"];
        if([object respondsToSelector:aSelector])
        {
            machOUUIDs = [object performSelector:aSelector];
            if(machOUUIDs == nil)
            {
                machOUUIDs = @[@"No machO UUIDs"];
            }
        }
        
        unsigned long long bundleFlags = 0;
        NSString *strBundleFlags = @"NA";
        if((bundleFlags = [object valueForKey:@"_bundleFlags"]))
        {
            strBundleFlags = [NSString stringWithFormat:@"%llu",bundleFlags];
            if(strBundleFlags == nil)
            {
                strBundleFlags = @"NA";
            }
        }
        
        unsigned long long plistContentFlags = 0;
        NSString *strPlistContentFlags = @"NA";
        if((plistContentFlags = [object valueForKey:@"_plistContentFlags"]))
        {
            strPlistContentFlags = [NSString stringWithFormat:@"%llu",plistContentFlags];
            if(strPlistContentFlags == nil)
            {
                strPlistContentFlags = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_INSTALL_TYPE);
        unsigned long long installType = 0;
        NSString *strInstallType = @"NA";
        if([object respondsToSelector:aSelector])
        {
            installType = [object performSelector:aSelector];
            strInstallType = [NSString stringWithFormat:@"%llu",installType];
            if(strInstallType == nil)
            {
                strInstallType = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_ORIGINAL_INSTALL_TYPE);
        unsigned long long originalInstallType = 0;
        NSString *strOriginalInstallType = @"NA";
        if([object respondsToSelector:aSelector])
        {
            originalInstallType = [object performSelector:aSelector];
            strOriginalInstallType = [NSString stringWithFormat:@"%llu",originalInstallType];
            if(strOriginalInstallType == nil)
            {
                strOriginalInstallType = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_SEQUENCE_NUMBER);
        unsigned int appSequenceNumber = 0;
        NSString *strAppSequenceNumber = @"NA";
        if([object respondsToSelector:aSelector])
        {
            appSequenceNumber = [object performSelector:aSelector];
            strAppSequenceNumber = [NSString stringWithFormat:@"%u",appSequenceNumber];
            if(strAppSequenceNumber == nil)
            {
                strAppSequenceNumber = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_HASH);
        unsigned int appHash = 0;
        NSString *strAppHash = @"NA";
        if([object respondsToSelector:aSelector])
        {
            appHash = [object performSelector:aSelector];
            strAppHash = [NSString stringWithFormat:@"%u",appHash];
            if(strAppHash == nil)
            {
                strAppHash = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_FOUND_BACKING_BUNDLE);
        BOOL foundBackingBundle = NO;
        NSString *strFoundBackingBundle = @"NO";
        if([object respondsToSelector:aSelector])
        {
            foundBackingBundle = [object performSelector:aSelector];
            strFoundBackingBundle = [NSString stringWithFormat:@"%@",foundBackingBundle ? @"YES" : @"NO"];
        }
        
        aSelector = NSSelectorFromString(PARAM_IS_ADHOC_CODE_SIGNED);
        BOOL isAdHocCodeSigned = NO;
        NSString *strIsAdHocCodeSigned = @"NO";
        if([object respondsToSelector:aSelector])
        {
            isAdHocCodeSigned = [object performSelector:aSelector];
            strIsAdHocCodeSigned = [NSString stringWithFormat:@"%@",isAdHocCodeSigned ? @"YES" : @"NO"];
        }
        
        aSelector = NSSelectorFromString(PARAM_PROFILE_VALIDATED);
        BOOL isProfileValidated = NO;
        NSString *strIsProfileValidated = @"NO";
        if([object respondsToSelector:aSelector])
        {
            isProfileValidated = [object performSelector:aSelector];
            strIsProfileValidated = [NSString stringWithFormat:@"%@",isProfileValidated ? @"YES" : @"NO"];
        }
        
        aSelector = NSSelectorFromString(PARAM_IS_INSTALLED);
        BOOL isInstalled = NO;
        NSString *strIsInstalled = @"NO";
        if([object respondsToSelector:aSelector])
        {
            isInstalled = [object performSelector:aSelector];
            strIsInstalled = [NSString stringWithFormat:@"%@",isInstalled ? @"YES" : @"NO"];
        }
        
        aSelector = NSSelectorFromString(PARAM_IS_RESTRICTED);
        BOOL isRestricted = NO;
        NSString *strIsRestricted = @"NO";
        if([object respondsToSelector:aSelector])
        {
            isRestricted = [object performSelector:aSelector];
            strIsRestricted = [NSString stringWithFormat:@"%@",isRestricted ? @"YES" : @"NO"];
        }
        
        aSelector = NSSelectorFromString(PARAM_STORE_COHORT_METADATA);
        NSString *storeCohortMetadata = @"NA";
        if([object respondsToSelector:aSelector])
        {
            storeCohortMetadata = [object performSelector:aSelector];
            if(storeCohortMetadata == nil)
            {
                storeCohortMetadata = @"NA";
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_UI_BACKGROUND_MODES);
        NSArray *uiBackgroundModes = @[@"No UI Background Modes"];
        if([object respondsToSelector:aSelector])
        {
            uiBackgroundModes = [object performSelector:aSelector];
            if(uiBackgroundModes == nil)
            {
                uiBackgroundModes = @[@"No UI Background Modes"];
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_APP_TAGS);
        NSArray *appTags = @[@"No tags"];
//        appTags = @[@"Tag1",@"Tag2",@"Tag3",@"Tag4",@"Tag5"];
        if([object respondsToSelector:aSelector])
        {
            appTags = [object performSelector:aSelector];
            if(appTags == nil)
            {
                appTags = @[@"No tags"];
            }
        }
        
        aSelector = NSSelectorFromString(PARAM_COMPANION_APP_IDENTIFIER);
        NSString *companionApplicationIdentifier = @"NA";
        if([object respondsToSelector:aSelector])
        {
            companionApplicationIdentifier = [object performSelector:aSelector];
            if(companionApplicationIdentifier == nil)
            {
                companionApplicationIdentifier = @"NA";
            }
        }
        
        NSLog(@"Bundle ID: %@",appIdentifier);
//        NSLog(@"Short Version: %@",shortVersion);
//        NSLog(@"Bundle Version: %@",bundleVersion);
//        NSLog(@"Signer identity: %@",signerIdentity);
//        NSLog(@"Bundle Executable: %@",bundleExecutable);
//        NSLog(@"Entitlements: %@",entitlements);
//        NSLog(@"Environment Variables: %@",environmentVariables);
//        NSLog(@"Bundle URL: %@",strBundleURL);
//        NSLog(@"Bundle Container URL: %@",strBundleContainerURL);
//
//        NSLog(@"Item Name: %@",itemName);
//        NSLog(@"App Short Name: %@",localizedShortName);
//        NSLog(@"App Name: %@",localizedName);
//        NSLog(@"App Type: %@",appType);
//        NSLog(@"App Variant: %@",applicationVariant);
//        NSLog(@"Team ID: %@",teamID);
//        NSLog(@"Vendor Name: %@",vendorName);
//        NSLog(@"Source App Identifier: %@",sourceAppIdentifier);
//        NSLog(@"Registered Date: %@",registeredDate);
//        
//        NSLog(@"Container URL: %@",strContainerURL);
//        NSLog(@"Data Container URL: %@",strDataContainerURL);
//        
//        NSLog(@"AppStore Receipt URL: %@",strAppStoreReceiptURL);
//        NSLog(@"PurchaserDSID: %@",purchaserDSID);
//        NSLog(@"DownloaderDSID: %@",downloaderDSID);
//        NSLog(@"ApplicationDSID: %@",applicationDSID);
//        NSLog(@"Store front: %@",storeFront);
//
//        NSLog(@"Cache GUID: %@",strCacheGUID);
//        NSLog(@"Unique Identifier: %@",strUniqueIdentifier);
//        NSLog(@"Mach O UUIDs: %@",machOUUIDs);
        NSLog(@"UI Background Modes: %@",uiBackgroundModes);
//
//        NSLog(@"Bundle flags: %@",strBundleFlags);
//        NSLog(@"Plist content flags: %@",strPlistContentFlags);
//        NSLog(@"Install Type: %@",strInstallType);
//        NSLog(@"Original Install Type: %@",strOriginalInstallType);
//        NSLog(@"Sequence Number: %@",strAppSequenceNumber);
//        NSLog(@"App hash: %@",strAppHash);
//        
//        NSLog(@"Found backing bundle: %@",strFoundBackingBundle);
//
//        NSLog(@"Is AdHoc Code Signed: %@",strIsAdHocCodeSigned);
//        NSLog(@"Profile Validate: %@",strIsProfileValidated);
//        NSLog(@"Is Installed: %@",strIsInstalled);
//        NSLog(@"Is Restricted: %@",strIsRestricted);
//        
//        NSLog(@"Store Cohort Metadata: %@",storeCohortMetadata);
//        NSLog(@"App tags: %@",appTags);
//        NSLog(@"Companion App Identifier: %@",companionApplicationIdentifier);
        
        NSString *appName;
        if(localizedName == nil)
        {
            if(localizedShortName == nil)
            {
                appName = @"Unknown";
            }
            else
            {
                appName = localizedName;
            }
        }
        else
        {
            appName = localizedName;
        }
        
        if(bundleVersion == nil)
        {
            bundleVersion = @"1.0";
        }
        if(shortVersion == nil)
        {
            shortVersion = @"1.0";
        }
        
        UIImage *iconImage = [self appIconImageForBundleIdentifier:appIdentifier];
        NSString *strIconImage = nil;
        if(iconImage)
        {
            NSData *imageData = UIImagePNGRepresentation(iconImage);
            if(imageData)
            {
                strIconImage = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            }
            else
            {
                strIconImage = @"";
            }
        }
        
//        Application *application = [[Application alloc] initWithBundleID:appIdentifier name:localizedName version:bundleVersion];
        Application *application = [[Application alloc] init];
        application.bundleID = appIdentifier;
        application.bundleShortVersion = shortVersion;
        application.bundleVersion = bundleVersion;
        application.signerIdentity = signerIdentity;
        application.bundleExecutable = bundleExecutable;
        application.entitlements = entitlements;
        application.environmentVariables = environmentVariables;
        application.bundleURL = strBundleURL;
        application.bundleContainerURL = strBundleContainerURL;
        
        application.name = localizedName;
        application.shortName = localizedShortName;
        application.type = appType;
        application.teamID = teamID;
        application.vendorName = vendorName;
        application.sourceAppIdentifier = sourceAppIdentifier;
        application.registeredDate = registeredDate;
        application.iconImage = strIconImage;
        
        application.containerURL = strContainerURL;
        application.dataContainerURL = strDataContainerURL;
        
        application.appStoreReceiptURL = strAppStoreReceiptURL;
        application.storeFront = storeFront;
        application.purchaserDSID = purchaserDSID;
        application.applicationDSID = applicationDSID;
        
        application.cacheGUID = cacheGUID;
        application.uniqueIdentifier = uniqueIdentifier;
        application.machOUUIDs = machOUUIDs;
        
        application.installType = installType;
        application.originalInstallType = originalInstallType;
        application.sequenceNumber = appSequenceNumber;
        application.appHash = appHash;
        
        application.foundBackingBundle = foundBackingBundle;
        
        application.isAdHocCodeSigned = isAdHocCodeSigned;
        application.profileValidated = isProfileValidated;
        application.isInstalled = isInstalled;
        application.isRestricted = isRestricted;
        
        application.storeCohortMetadata = storeCohortMetadata;
        application.uiBackgroundModes = uiBackgroundModes;
        application.tags = appTags;
        application.companionAppIdentifier = companionApplicationIdentifier;

        [appList addObject:application];
    }
    return appList;
}

#pragma mark-
#pragma mark- get all installed app
+ (NSMutableArray *)browseInstalledAppList{
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        return [self browseInstalledAppListForIos8];
    }else{
        return browseInstalledAppListForIos7();
    }
}
#pragma mark
#pragma mark- get installed app icon with identifier image default size 122x122
+ (UIImage *)appIconImageForBundleIdentifier:(NSString *)bundleId {
    
    UIImage* iconImage = [UIImage _applicationIconImageForBundleIdentifier:bundleId format:0 scale:[UIScreen mainScreen].scale];
    return iconImage;
}


+ (void)getDeviceDetails
{
    NSString *clName = @"AADeviceInfo";
    Class AADeviceInfo_class = objc_getClass(clName.UTF8String);
    if(Nil == AADeviceInfo_class)
    {
        NSLog(@"AADeviceInfo class is nil");
        
        const char *path="/System/Library/PrivateFrameworks/AppleAccount.framework/AppleAccount";
        void* lib = dlopen(path, RTLD_LAZY);
        if (lib)
        {
            AADeviceInfo_class = objc_getClass(clName.UTF8String);
            if(Nil == AADeviceInfo_class)
            {
                NSLog(@"AADeviceInfo class is still nil");
                return;
            }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            
            /*AVAILABLE VALUES*/
                //appleIDClientIdentifier
                //buildVersion
                //clientInfoHeader
                //deviceClass
                //deviceColor
                //deviceEnclosureColor
                //deviceInfoDictionary
                //deviceName
                //hasCellularCapability
                //modelNumber
                //osName
                //osVersion
                //productType
                //productVersion
                //regionCode
                //storageCapacity
                //userAgentHeader
            
            /*UNAVAILABLE VALUES*/
                //apnsToken
                //internationalMobileEquipmentIdentity
                //mobileEquipmentIdentifier
                //serialNumber
                //udid
                //wifiMacAddress
            
            SEL selector = NSSelectorFromString(@"regionCode");
            NSObject *aaDeviceObj = [[AADeviceInfo_class alloc] init];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[AADeviceInfo_class instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:aaDeviceObj];
            [invocation invoke];
            NSString *returnValue;
            [invocation getReturnValue:&returnValue];
            NSLog(@"ret val class: %@",[returnValue class]);
            NSLog(@"Returned %@", returnValue);
            
//            BOOL boolReturnValue;
//            [invocation getReturnValue:&boolReturnValue];
//            NSLog(@"Returned %d", boolReturnValue);
            
//            objc_msgSend([[AADeviceInfo_class alloc] init], sel_getUid("udid"));
        }
    }
}

+ (void)getStoreAccountDetails
{
    NSString *clName = @"BluetoothManager";
    Class SSDevice_class = objc_getClass(clName.UTF8String);
    if(Nil == SSDevice_class)
    {
        NSLog(@"SSDevice class is nil");
        
        const char *path="/System/Library/PrivateFrameworks/BluetoothManager.framework/BluetoothManager";
        void* lib = dlopen(path, RTLD_LAZY);
        if (lib)
        {
            SSDevice_class = objc_getClass(clName.UTF8String);
            if(Nil == SSDevice_class)
            {
                NSLog(@"SSDevice class is still nil");
                return;
            }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            
            /*AVAILABLE VALUES*/
            //appleIDClientIdentifier
            //buildVersion
            //clientInfoHeader
            //deviceClass
            //deviceColor
            //deviceEnclosureColor
            //deviceInfoDictionary
            //deviceName
            //hasCellularCapability
            //modelNumber
            //osName
            //osVersion
            //productType
            //productVersion
            //regionCode
            //storageCapacity
            //userAgentHeader
            
            /*UNAVAILABLE VALUES*/
            //accountKind
            //accountName
            //ITunesPassSerialNumber
            //firstName
            //serialNumber
            //udid
            //wifiMacAddress
            
            SEL selector = NSSelectorFromString(@"audioConnected");
            NSObject *ssDeviceObj = [[SSDevice_class alloc] init];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[SSDevice_class instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:ssDeviceObj];
            [invocation invoke];
            id returnValue;
//            [invocation getReturnValue:&returnValue];
//            NSLog(@"ret val class: %@",[returnValue class]);
//            if([returnValue isKindOfClass:[NSArray class]])
//            {
//                NSArray *devices = returnValue;
//                NSLog(@"Count: %ld",(unsigned long)devices.count);
//                for (id object in devices)
//                {
//                    SEL aSelector = NSSelectorFromString(@"name");
//                    NSString *name = @"NA";
//                    if([object respondsToSelector:aSelector])
//                    {
//                        name = [object performSelector:aSelector];
//                        if(name == nil)
//                        {
//                            name = @"NA";
//                        }
//                    }
//                }
//            }
//            NSLog(@"Returned %@", returnValue);
            
                        BOOL boolReturnValue;
                        [invocation getReturnValue:&boolReturnValue];
                        NSLog(@"Returned %d", boolReturnValue);
            
//                        objc_msgSend([[SSDevice_class alloc] init], sel_getUid("udid"));
        }
    }
}

+ (void)getAccountDetails
{
    NSString *clName = @"AAAccountManager";
    Class AAAccount_class = objc_getClass(clName.UTF8String);
    if(Nil == AAAccount_class)
    {
        NSLog(@"AAAccount class is nil");
        
        const char *path="/System/Library/PrivateFrameworks/AppleAccount.framework/AppleAccount";
        void* lib = dlopen(path, RTLD_LAZY);
        if (lib)
        {
            AAAccount_class = objc_getClass(clName.UTF8String);
            if(Nil == AAAccount_class)
            {
                NSLog(@"AAAccount class is still nil");
                return;
            }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            
            /*AVAILABLE VALUES*/
            //appleIDClientIdentifier
            //buildVersion
            //clientInfoHeader
            //deviceClass
            //deviceColor
            //deviceEnclosureColor
            //deviceInfoDictionary
            //deviceName
            //hasCellularCapability
            //modelNumber
            //osName
            //osVersion
            //productType
            //productVersion
            //regionCode
            //storageCapacity
            //userAgentHeader
            
            /*UNAVAILABLE VALUES*/
            //apnsToken
            //internationalMobileEquipmentIdentity
            //mobileEquipmentIdentifier
            //serialNumber
            //udid
            //wifiMacAddress
            
            SEL selector = NSSelectorFromString(@"accounts");
            NSObject *aaAccountObj = [[AAAccount_class alloc] init];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[AAAccount_class instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:aaAccountObj];
            [invocation invoke];
//            NSString *returnValue;
//            [invocation getReturnValue:&returnValue];
//            NSLog(@"ret val class: %@",[returnValue class]);
//            NSLog(@"Returned %@", returnValue);
            
            NSArray *arrReturnValue;
            [invocation getReturnValue:&arrReturnValue];
            NSLog(@"Returned %@", arrReturnValue);

            
//            BOOL boolReturnValue;
//            [invocation getReturnValue:&boolReturnValue];
//            NSLog(@"Returned %d", boolReturnValue);
//            
//            objc_msgSend([[AADeviceInfo_class alloc] init], sel_getUid("udid"));
        }
    }
}

+ (void)getNetworkDetails
{
    NSString *clName = @"NWNetworkDescription";
    Class NWStatisticsTCPSource_class = objc_getClass(clName.UTF8String);
    if(Nil == NWStatisticsTCPSource_class)
    {
        NSLog(@"NWStatisticsTCPSource class is nil");
        
        const char *path="/System/Library/PrivateFrameworks/Network.framework/Network";
        void* lib = dlopen(path, RTLD_LAZY);
        if (lib)
        {
            NWStatisticsTCPSource_class = objc_getClass(clName.UTF8String);
            if(Nil == NWStatisticsTCPSource_class)
            {
                NSLog(@"NWStatisticsTCPSource class is still nil");
                return;
            }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            
            
            SEL selector = NSSelectorFromString(@"description");
            NSObject *nwStatisticsTCPSourceObj = [[NWStatisticsTCPSource_class alloc] init];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[NWStatisticsTCPSource_class instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:nwStatisticsTCPSourceObj];
            [invocation invoke];
            NSString *returnValue;
            [invocation getReturnValue:&returnValue];
            NSLog(@"ret val class: %@",[returnValue class]);
            NSLog(@"Returned %@", returnValue);
        }
    }
}
@end
