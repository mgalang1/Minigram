//
//  ImageDownloader.m
//  MyMinigram
//
//  Created by Marvin Galang on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImageDownloader.h"
#import "NSMutableData+MGMultipartFormData.h"

@interface ImageDownloader ()

@property (nonatomic, strong) NSMutableData *activeDownload;
@property (nonatomic, strong) NSURLConnection *imageDownloadConnection;
@property (nonatomic, strong) NSURLConnection *imageUploadConnection;
@property (nonatomic, strong) NSMutableDictionary *cacheImage;
@property (nonatomic, strong) NSMutableArray *cacheKeys;
@property (nonatomic, strong) NSString *currentKey;

@end

@implementation ImageDownloader

@synthesize delegate;
@synthesize activeDownload=activeDownload_;
@synthesize imageDownloadConnection=imageDownloadConnection_;
@synthesize imageUploadConnection=imageUploadConnection_;
@synthesize cacheKeys=cacheKeys_;
@synthesize cacheImage=cacheImage_;
@synthesize currentKey=currentKey_;

- (id)init
{
    self = [super init];
    if (self) {
        self.cacheKeys=[NSMutableArray array];
        self.cacheImage=[NSMutableDictionary dictionary];
    }
    return self;
}

-(void)downloadImage:(NSString *) urlString {
    
    NSRange range = [urlString rangeOfString:@"?" options:NSCaseInsensitiveSearch | NSBackwardsSearch];
    self.currentKey=[urlString substringFromIndex:range.location + 1];
    
    //check if image is cached
    if ([self.cacheImage valueForKey:self.currentKey]) {
        [delegate imageDidFinishedLoading:self image:[self.cacheImage valueForKey:self.currentKey]];
    
    }
    else {
        // Construct the URL
        self.imageDownloadConnection=[[NSURLConnection alloc] initWithRequest:
                              [NSURLRequest requestWithURL:
                               [NSURL URLWithString:urlString]] delegate:self];
    }
}

-(void)uploadImage:(NSString *) caption image:(NSData *)jpegData {
    
    //Construct Ramdom File name
    NSString *fileName=[NSString stringWithFormat:@"mlg-%d.jpg",rand()];
    
    // Construct the URL
    NSURL *url=[NSURL URLWithString:@"http://minigram.herokuapp.com/photos"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:@"73edf1c0-3fb7-012f-5dee-48bcc8c61670" forHTTPHeaderField:@"X-Minigram-Auth"];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [request setValue:[NSData mg_contentTypeForMultipartFormData] forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *body=[NSMutableData data];
    
    [body mg_appendFormValue:caption forKey:@"photo[title]"];
    [body mg_appendFileData:jpegData forKey:@"photo[image]" filename:fileName mimeType:@"image/jpeg"];
    [body mg_appendMultipartFooter];
    
    [request setHTTPBody:body];
    
    self.imageUploadConnection = [[NSURLConnection alloc] initWithRequest:request 
                                                      delegate:self 
                                              startImmediately:YES];
}

- (void)cancelDownload
{
    [self.imageDownloadConnection cancel];
    self.imageDownloadConnection = nil;
    self.activeDownload = nil;

}

-(void) clearCache {
    self.cacheKeys=nil;
    self.cacheImage=nil;
}

- (void)cancelUpload
{
    [self.imageUploadConnection cancel];
    self.imageUploadConnection = nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    if (connection==self.imageDownloadConnection) {
    
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
        if ([httpResponse statusCode] == 200) {
            // Create a new data container for the photoList
            self.activeDownload = [[NSMutableData alloc] init];
        
        } else {
            // do error handling here
            [self.imageDownloadConnection cancel];
            self.imageDownloadConnection = nil;
            
            NSLog(@"remote url returned error %d %@",[httpResponse statusCode],[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]]);
        
            [delegate errorOccurred:self error:[NSString stringWithFormat:@"%d %@",[httpResponse statusCode],[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]]]];
            
        }
    }
    
    if (connection==self.imageUploadConnection) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if ([httpResponse statusCode] != 201) {
            
            [self.imageUploadConnection cancel];
            self.imageUploadConnection=nil;
            
            NSLog(@"remote url returned error %d %@",[httpResponse statusCode],[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]]);
            
            [delegate progressBarUpdated:self progress:2.0 error:[NSString stringWithFormat:@"%d %@",[httpResponse statusCode],[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]]]];
            
        }
        
        
    }
    
    
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (connection==self.imageDownloadConnection) {
    
        // Set appIcon and clear temporary data/image
        UIImage *image = [[UIImage alloc] initWithData:self.activeDownload];
    
        self.activeDownload = nil;
        self.imageDownloadConnection = nil;
    
        if ([self.cacheKeys count]>5) {
            NSString *removeKey= [self.cacheKeys objectAtIndex:0];
            [self.cacheKeys removeObjectAtIndex:0];
            [self.cacheImage removeObjectForKey:removeKey];
        }
        
        if(!self.cacheKeys)
            self.cacheKeys=[NSMutableArray array];
        if(!self.cacheImage)
            self.cacheImage=[NSMutableDictionary dictionary];
        
        [self.cacheKeys addObject:self.currentKey];
        [self.cacheImage setValue:image forKey:self.currentKey];
    
        // call our delegate and tell it that our icon is ready for display
        [delegate imageDidFinishedLoading:self image:image];
        
    }
    
    if (connection==self.imageUploadConnection) {
        [delegate imageDidFinishedUploading:self];
    
    }
    
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (connection==self.imageDownloadConnection) 
        [self.activeDownload appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if (connection==self.imageDownloadConnection) {
    // Clear the activeDownload property to allow later attempts
        self.activeDownload = nil;
        [self.imageDownloadConnection cancel];
        self.imageDownloadConnection = nil;
        
        NSLog(@"remote url returned error %i %@",[error code],[error localizedDescription]);
        
        [delegate errorOccurred:self error:[NSString stringWithFormat:@"%i %@",[error code],[error localizedDescription]]];
        
        
    }
    if (connection==self.imageUploadConnection) {
        [self.imageUploadConnection cancel];
        self.imageUploadConnection = nil;
    
        NSLog(@"remote url returned error %i %@",[error code],[error localizedDescription]);
    
        [delegate progressBarUpdated:self progress:2.0 error:[NSString stringWithFormat:@"%i %@",[error code],[error localizedDescription]]];
    }
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite 
{   
    float progressPercent=(float) totalBytesWritten/totalBytesExpectedToWrite;
    [delegate progressBarUpdated:self progress:progressPercent error:nil];
    
}



@end
