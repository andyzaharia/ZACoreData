//
//  NSManagedObjectContext+Custom.m
//  CocoaPodsManager
//
//  Created by Andrei Zaharia on 9/18/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "NSManagedObjectContext+Custom.h"

@implementation NSManagedObjectContext (Custom)

static NSMutableDictionary *_managedObjectContextsDictionary = nil;

+ (NSString *) generateGUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge NSString *)string;
}

+ (NSManagedObjectContext *) contextForMainThread
{
    if (!_managedObjectContextsDictionary) {
        _managedObjectContextsDictionary = [[NSMutableDictionary alloc] init];
    }
    
    NSThread *thread = [NSThread mainThread];
    if (![[thread name] length]) {
        [thread setName: [NSManagedObjectContext generateGUID]];
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
        context.persistentStoreCoordinator = [NSPersistentStoreCoordinator sharedPersisntentStoreCoordinator];
        [_managedObjectContextsDictionary setObject:context forKey: [thread name]];
        return context;
    } else {
        return [_managedObjectContextsDictionary objectForKey: [thread name]];
    }
}

+ (NSManagedObjectContext *) contextForCurrentThread
{
    if (!_managedObjectContextsDictionary) {
        _managedObjectContextsDictionary = [[NSMutableDictionary alloc] init];
    }
    
    NSThread *currentThread = [NSThread currentThread];
    if (![[currentThread name] length]) {
        [currentThread setName: [NSManagedObjectContext generateGUID]];
        
        NSManagedObjectContextConcurrencyType contextType = ([currentThread isMainThread]) ? NSMainQueueConcurrencyType : NSPrivateQueueConcurrencyType;
        
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType: contextType];
        
        if ([currentThread isMainThread]) {
            context.persistentStoreCoordinator = [NSPersistentStoreCoordinator sharedPersisntentStoreCoordinator];
        }
        
        if (![currentThread isMainThread]) {
            context.parentContext = [NSManagedObjectContext contextForMainThread];
        }
        [_managedObjectContextsDictionary setObject:context forKey: [currentThread name]];
        
        return context;
    } else {
        return [_managedObjectContextsDictionary objectForKey: [currentThread name]];
    }
}

+ (void) cleanContextsForCurrentThread
{
    if (_managedObjectContextsDictionary) {
        NSThread *currentThread = [NSThread currentThread];
        if ([[currentThread name] length]) {
            [_managedObjectContextsDictionary removeObjectForKey: [currentThread name]];
        }
    }
}

+ (NSManagedObjectContext *) contextForBackgroundThread
{
    NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.parentContext = [NSManagedObjectContext contextForMainThread];
    return backgroundContext;
}

@end
