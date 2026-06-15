//
//  MPDocument.h
//  MacDown
//
//  Created by Tzu-ping Chung  on 6/06/2014.
//  Copyright (c) 2014 Tzu-ping Chung . All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MPPreferences;


@interface MPDocument : NSDocument

@property (nonatomic, readonly) MPPreferences *preferences;
@property (readonly) BOOL previewVisible;
@property (readonly) BOOL editorVisible;

@property (nonatomic, readwrite) NSString *markdown;
@property (nonatomic, readonly) NSString *html;

- (BOOL)openWorkspaceAtURL:(NSURL *)directoryURL error:(NSError **)error;
- (BOOL)openWorkspaceAtURL:(NSURL *)directoryURL
          selectingFileURL:(NSURL *)fileURL error:(NSError **)error;
- (IBAction)toggleContinuousReading:(id)sender;
- (IBAction)selectEditorLayoutButton:(id)sender;
- (IBAction)selectPreviewLayoutButton:(id)sender;
- (NSUInteger)layoutStateForToolbar;
- (BOOL)continuousReadingEnabledForToolbar;
- (IBAction)increasePreviewZoom:(id)sender;
- (IBAction)decreasePreviewZoom:(id)sender;
- (IBAction)resetPreviewZoom:(id)sender;

@end
