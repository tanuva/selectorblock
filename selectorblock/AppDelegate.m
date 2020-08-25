//
//  AppDelegate.m
//  selectorblock
//
//  Created by Frosch on 24.08.20.
//

#import "AppDelegate.h"

#ifdef PANEL_SEL
static NSString* getAppPath()
{
    NSString* appPath = [[NSBundle mainBundle] executablePath];
    appPath = [appPath stringByDeletingLastPathComponent];
    appPath = [appPath stringByDeletingLastPathComponent];
    appPath = [appPath stringByDeletingLastPathComponent];
    appPath = [appPath stringByDeletingLastPathComponent];
    return appPath;
}
#endif

#pragma mark ConfirmUnsavedChangesContextInfo
@interface ConfirmUnsavedChangesContextInfo : NSObject
{
    id target;
    SEL acceptAction;
    SEL rejectAction;
}

+ (ConfirmUnsavedChangesContextInfo*)contextInfoForTarget:(id)t
                                             acceptAction:(SEL)aa
                                             rejectAction:(SEL)ra;
- (void)performAcceptAction;
- (void)performRejectAction;
@end

@implementation ConfirmUnsavedChangesContextInfo

+ (ConfirmUnsavedChangesContextInfo*)contextInfoForTarget:(id)t
                                             acceptAction:(SEL)aa
                                             rejectAction:(SEL)ra
{
    ConfirmUnsavedChangesContextInfo* ci = [[ConfirmUnsavedChangesContextInfo alloc] init];
    ci->target = t;
    ci->acceptAction = aa;
    ci->rejectAction = ra;
    return [ci autorelease];
}

- (void)performAcceptAction
{
    if (acceptAction)
        [target performSelector:acceptAction];
}

- (void)performRejectAction
{
    if (rejectAction)
        [target performSelector:rejectAction];
}

@end

#pragma mark AppDelegate

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

#ifdef ALERT_SEL
- (void)confirmUnsavedChangesAlertDidEnd:(NSAlert*)alert
                              returnCode:(NSInteger)returnCode
                             contextInfo:(void*)contextInfo
{
    printf("confirmUnsavedChangesAlertDidEnd\n");
    ConfirmUnsavedChangesContextInfo* ci = (ConfirmUnsavedChangesContextInfo*)contextInfo;
    if (returnCode ==  NSAlertFirstButtonReturn) {
        printf("alert: yes, save\n");
        [self performSelector:@selector(fileSaveWithContextInfo:)
                   withObject:ci
                   afterDelay:0.0
                      inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode,
                                                        NSModalPanelRunLoopMode,
                                                        NSEventTrackingRunLoopMode,
                                                        nil]];
    } else if (returnCode ==  NSAlertSecondButtonReturn) {
        [ci performRejectAction];
        [ci release];
    } else if (returnCode ==  NSAlertThirdButtonReturn) {
        [ci performAcceptAction];
        [ci release];
    }
    [alert autorelease];
}
#endif

- (void)confirmUnsavedChanges:(ConfirmUnsavedChangesContextInfo*)contextInfo
{
    [contextInfo retain];

    NSAlert* alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSWarningAlertStyle];
    [[alert window] setTitle:@"Save Changes?"];
    [alert setMessageText:@"Save Changes?"];
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Discard"];

#ifdef ALERT_SEL
    [alert beginSheetModalForWindow:_window
                      modalDelegate:self
                     didEndSelector:@selector(confirmUnsavedChangesAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:contextInfo];
#else
    [alert beginSheetModalForWindow:_window completionHandler:^(NSModalResponse returnCode) {
        switch(returnCode) {
            case NSAlertFirstButtonReturn:
                printf("alert: yes, save\n");
                [self performSelector:@selector(fileSaveWithContextInfo:)
                           withObject:contextInfo
                           afterDelay:0.0
                              inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode,
                                       NSModalPanelRunLoopMode,
                                       NSEventTrackingRunLoopMode,
                                       nil]];
            case NSAlertSecondButtonReturn:
                [contextInfo performRejectAction];
                [contextInfo release];
            case NSAlertThirdButtonReturn:
                [contextInfo performAcceptAction];
                [contextInfo release];
        }
        
        [alert autorelease];
    }];
#endif
}

#ifdef PANEL_SEL
- (void)fileSavePanelDidEnd:(NSOpenPanel*)panel
                 returnCode:(int)returnCode
                contextInfo:(void*)contextInfo
{
    ConfirmUnsavedChangesContextInfo* ci = (ConfirmUnsavedChangesContextInfo*)contextInfo;
    if (returnCode == NSModalResponseOK) {
        printf("Saving to %s\n", [[[panel URL] absoluteString] UTF8String]);
        _saved = true;
        [ci performAcceptAction];
        [ci release];
    } else {
        printf("savePanel rejected\n");
        [ci performRejectAction];
        [ci release];
    }
}
#endif

- (void)fileSaveWithContextInfo:(void*)contextInfo
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *downloadsFolder = [[fileManager URLsForDirectory:NSDownloadsDirectory
                                                  inDomains:NSUserDomainMask] firstObject];
    
    NSSavePanel* savePanel = [NSSavePanel savePanel];
    [savePanel setDirectoryURL:downloadsFolder];
    [savePanel setAllowsOtherFileTypes:NO];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"adr"]];

#ifdef PANEL_SEL
    [savePanel beginSheetForDirectory:getAppPath()
                                 file:nil
                       modalForWindow:_window
                        modalDelegate:self
                       didEndSelector:@selector(fileSavePanelDidEnd:returnCode:contextInfo:)
                          contextInfo:contextInfo];
#else
    [savePanel beginSheetModalForWindow:_window completionHandler:^(NSModalResponse result) {
        ConfirmUnsavedChangesContextInfo* ci = (ConfirmUnsavedChangesContextInfo*)contextInfo;
        if (result == NSFileHandlingPanelOKButton) {
            printf("Saving to %s\n", [[[savePanel URL] absoluteString] UTF8String]);
            _saved = true;
            [ci performAcceptAction];
        } else {
            printf("savePanel rejected\n");
            [ci performRejectAction];
        }
        
        [ci release];
    }];
#endif
}

#pragma mark NSApplicationDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [_window setDelegate:self];
    _saved = false;
}

- (void)appterminationConfirmationAccept
{
    [NSApp replyToApplicationShouldTerminate:YES];
}

- (void)appterminationConfirmationReject
{
    [NSApp replyToApplicationShouldTerminate:NO];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)sender
{
    printf("appShouldTerminate\n");
    if (!_saved) {
        ConfirmUnsavedChangesContextInfo* ci =
            [ConfirmUnsavedChangesContextInfo contextInfoForTarget:self
                                                      acceptAction:@selector(appterminationConfirmationAccept)
                                                      rejectAction:@selector(appterminationConfirmationReject)];
        [self confirmUnsavedChanges:ci];
        return NSTerminateLater;
    }
    
    return NSTerminateNow;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app
{
    return YES;
}

#pragma mark NSWindowDelegate

- (void)wincloseConfirmationAccept
{
    printf("wincloseConfirmationAccept\n");
    [_window close];
    [_window autorelease];
    _window = nil;
}

- (BOOL)windowShouldClose:(id)sender
{
    printf("windowShouldClose\n");
    ConfirmUnsavedChangesContextInfo* ci =
        [ConfirmUnsavedChangesContextInfo contextInfoForTarget:self
                                                  acceptAction:@selector(wincloseConfirmationAccept)
                                                  rejectAction:nil];
    [self confirmUnsavedChanges:ci];
    return NO;
}
@end
