//
//  ImageDownloader.h
//  MyMinigram
//
//  Created by Marvin Galang on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ImageDownloader;
@protocol ImageDownloaderDelegate <NSObject>
@optional
- (void) imageDidFinishedLoading:(ImageDownloader*)imageDownloaderObj image:(UIImage *) image;
- (void) imageDidFinishedUploading:(ImageDownloader*)imageDownloaderObj;
- (void) progressBarUpdated:(ImageDownloader*)imageDownloaderObj progress:(float) progress error:(NSString *) error;
- (void) errorOccurred:(ImageDownloader*)imageDownloaderObj error:(NSString *) error;

@end

@interface ImageDownloader : NSObject

@property (strong, nonatomic) id <ImageDownloaderDelegate> delegate;

-(void)downloadImage:(NSString *) urlString;
-(void)uploadImage:(NSString *) caption image:(NSData *)jpegData;
-(void)cancelDownload;
-(void)clearCache;
- (void)cancelUpload;

@end
