//
//  PhotoCollection.h
//  MyMinigram
//
//  Created by Marvin Galang on 3/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageDownloader.h"

@class PhotoCollection;
@protocol PhotoCollectionDelegate <NSObject>
@required
- (void) photoCollectionDidFinishedLoadingCollection:(PhotoCollection *)myPhotoCollection;
- (void) errorGetPhoto:(PhotoCollection *)myPhotoCollection error:(NSString *) error;
@end


@interface PhotoCollection : NSObject

@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) ImageDownloader *imageDownloader;
@property (strong, nonatomic) id <PhotoCollectionDelegate> delegate;

-(void)refreshPhotoList;

@end
