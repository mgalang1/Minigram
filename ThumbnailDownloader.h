//
//  ThumbnailDownloader.h
//  MyMinigram
//
//  Created by Marvin Galang on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ThumbnailDownloader;
@protocol ThumbnailDownloaderDelegate <NSObject>
@required
- (void) iconDidFinishedLoading:(ThumbnailDownloader*)thumbnailDownloaderObj key:(NSString *)key image:(UIImage *) image atIndexPath:(NSIndexPath *) indexPath;

@end

@interface ThumbnailDownloader : NSObject
@property (strong, nonatomic) id <ThumbnailDownloaderDelegate> delegate;

-(void)downLoadThumbnail:(NSString *) key urlString:(NSString *) urlString atIndexPath:(NSIndexPath *) indexPath;
-(void)cancelDownload;

@end
