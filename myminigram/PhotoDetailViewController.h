//
//  PhotoDetailViewController.h
//  MyMinigram
//
//  Created by Marvin Galang on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoCollection.h"

@class PhotoDetailViewController;
@protocol PhotoDetailViewControllerDelegate <NSObject>
@optional
- (void) imageDidNewImageSelected:(PhotoDetailViewController *)photoDetailViewControllerObj row:(NSUInteger) row;
- (void) dismissDetailSegue:(PhotoDetailViewController *)photoDetailViewControllerObj;
@end

@interface PhotoDetailViewController : UIViewController <ImageDownloaderDelegate>


@property (strong, nonatomic) id <PhotoDetailViewControllerDelegate> delegate;

@property (nonatomic, weak) PhotoCollection *photoList;
@property (nonatomic, assign) NSUInteger currentIndexRow;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *indicator;



@end
