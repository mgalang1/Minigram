//
//  ThumbnailDownloader.m
//  MyMinigram
//
//  Created by Marvin Galang on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ThumbnailDownloader.h"

#define kAppIconHeight 48

@interface ThumbnailDownloader ()

@property (nonatomic, strong) NSMutableData *activeDownload;
@property (nonatomic, strong) NSURLConnection *iconConnection;
@property (nonatomic, strong) NSString *urlKey;
@property (nonatomic, strong) NSIndexPath *index;

@end


@implementation ThumbnailDownloader

@synthesize delegate;
@synthesize activeDownload;
@synthesize iconConnection;
@synthesize urlKey;
@synthesize index;


#pragma mark -
#pragma mark Download Related Methods

-(void)downLoadThumbnail:(NSString *) key urlString:(NSString *) urlString atIndexPath:(NSIndexPath *) indexPath {
    
    // Construct the URL
    self.iconConnection = [[NSURLConnection alloc] initWithRequest:
                             [NSURLRequest requestWithURL:
                              [NSURL URLWithString:urlString]] delegate:self];
    
    
    self.urlKey=key;
    self.index=indexPath;
}

- (void)cancelDownload
{
    [self.iconConnection cancel];
    self.iconConnection = nil;
    self.activeDownload = nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    if ([httpResponse statusCode] == 200) {
        // Create a new data container for the photoList
        self.activeDownload = [[NSMutableData alloc] init];
        
    } else {
        // do error handling here
        [self.iconConnection cancel];
        self.iconConnection = nil;
        self.activeDownload = nil;
        
        NSLog(@"remote url returned error %d %@",[httpResponse statusCode],[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]]);
        
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.activeDownload appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Set appIcon and clear temporary data/image
    UIImage *image = [[UIImage alloc] initWithData:self.activeDownload];
    
    if (image.size.width != kAppIconHeight && image.size.height != kAppIconHeight)
        {
        CGSize itemSize = CGSizeMake(kAppIconHeight, kAppIconHeight);
		UIGraphicsBeginImageContext(itemSize);
		CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
		[image drawInRect:imageRect];
		image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
        }

    self.activeDownload = nil;
    self.iconConnection = nil;
    
    // call our delegate and tell it that our icon is ready for display
    [delegate iconDidFinishedLoading:self key:self.urlKey image:image atIndexPath:self.index];

}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	// Clear the activeDownload property to allow later attempts
    [self.iconConnection cancel];
    self.iconConnection = nil;
    self.activeDownload = nil;
    self.urlKey=nil;
    
    NSLog(@"remote url returned error %i %@",[error code],[error localizedDescription]);
    
}



@end
