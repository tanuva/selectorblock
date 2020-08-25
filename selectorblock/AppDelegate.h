//
//  AppDelegate.h
//  selectorblock
//
//  Created by Frosch on 24.08.20.
//

#import <Cocoa/Cocoa.h>


// =======================================
// Switch implementations here.
// Old: SELector-based completion handling
// New: block-based completion handling
#define ALERT_SEL
//#define PANEL_SEL
// =======================================


@class ConfirmUnsavedChangesContextInfo;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
{
    BOOL _saved;
}

#ifdef ALERT_SEL
- (void)confirmUnsavedChangesAlertDidEnd:(NSAlert*)alert
                              returnCode:(NSInteger)returnCode
                             contextInfo:(void*)contextInfo;
#endif
- (void)confirmUnsavedChanges:(ConfirmUnsavedChangesContextInfo*)contextInfo;

#ifdef PANEL_SEL
- (void)fileSavePanelDidEnd:(NSOpenPanel*)panel
                 returnCode:(int)returnCode
                contextInfo:(void*)contextInfo;
#endif
- (void)fileSaveWithContextInfo:(void*)contextInfo;

@end

