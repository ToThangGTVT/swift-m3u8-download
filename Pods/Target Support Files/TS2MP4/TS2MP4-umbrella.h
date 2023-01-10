#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "mp4mux.h"
#import "KMMedia.h"
#import "ac3.h"
#import "common.h"
#import "h264.h"
#import "ts.h"
#import "NSFileManager+Temporary.h"
#import "KMMediaAsset.h"
#import "KMMediaAssetExportSession.h"
#import "KMMediaFormat.h"

FOUNDATION_EXPORT double TS2MP4VersionNumber;
FOUNDATION_EXPORT const unsigned char TS2MP4VersionString[];

