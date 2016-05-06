//
//  PhotoCollection.m
//  MyMinigram
//
//  Created by Marvin Galang on 3/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PhotoCollection.h"


@interface PhotoCollection ()
@property (nonatomic, strong) NSURLConnection *connPhotos;
@property (nonatomic, strong) NSMutableData *jsonData;
@property (nonatomic, assign, getter=isDownloading) BOOL downloading;
@end


@implementation PhotoCollection

@synthesize photos=photos_;
@synthesize connPhotos=connPhotos_;
@synthesize jsonData=jsonData_;
@synthesize imageDownloader=imageDownloader_;
@synthesize delegate;
@synthesize downloading=downloading_;



- (id)init
{
    self = [super init];
    if (self) {
        self.photos=[[NSMutableArray alloc] init];
        self.imageDownloader = [[ImageDownloader alloc] init];
        self.downloading=NO;
    }
    return self;
}

#pragma mark - Refresh PhotoList

-(void)refreshPhotoList {
    
    if (self.isDownloading==YES) {
        NSLog(@"Current refresh ongoing");
        return;
    }
        
    // Construct the URL
    NSURL *url=[NSURL URLWithString:@"http://minigram.herokuapp.com/photos"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"73edf1c0-3fb7-012f-5dee-48bcc8c61670" forHTTPHeaderField:@"X-Minigram-Auth"];
    
    self.connPhotos = [[NSURLConnection alloc] initWithRequest:request 
                                                 delegate:self 
                                         startImmediately:YES];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    if ([httpResponse statusCode] == 200) {
        // Create a new data container for the photoList
        self.jsonData = [[NSMutableData alloc] init];
        self.downloading=YES;
        
    } else {
        // do error handling here
        [self.connPhotos cancel];
        self.connPhotos=nil;
        self.jsonData=nil;
        
        NSLog(@"remote url returned error %d %@",[httpResponse statusCode],[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]]);
        
        [delegate errorGetPhoto:self error:[NSString stringWithFormat:@"%d %@",[httpResponse statusCode],[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]]]];
    }
    
    
   NSLog(@"%d %@",[httpResponse statusCode],[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]]);
    
}


// This method will be called several times as the data arrives
- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
    // Add the incoming chunk of data to the container we are keeping
    // The data always comes in the correct order
    [self.jsonData appendData:data];
    
    //NSLog(@"jsonData Received");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
    NSError *error;
    // Create the parser object with the data received from the web service
    
    if (self.jsonData) {
        id jsonObject = [NSJSONSerialization JSONObjectWithData:self.jsonData options:0 error:&error];
    
            NSLog(@"JSON data is not nil");
    
        [self.photos setArray:jsonObject];
    
        [delegate photoCollectionDidFinishedLoadingCollection:self];
    
        //set json object to nil
        self.jsonData = nil;
        self.connPhotos=nil;
        self.downloading=NO;
    
    }
    
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{

    [self.connPhotos cancel];
    self.connPhotos=nil;
    self.jsonData=nil;
    
    NSLog(@"remote url returned error %i %@",[error code],[error localizedDescription]);
    
    [delegate errorGetPhoto:self error:[NSString stringWithFormat:@"%i %@",[error code],[error localizedDescription]]];
    
    self.downloading=NO;
    
}


@end
