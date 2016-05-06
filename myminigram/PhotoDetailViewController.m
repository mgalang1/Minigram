//
//  PhotoDetailViewController.m
//  MyMinigram
//
//  Created by Marvin Galang on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PhotoDetailViewController.h"


@interface PhotoDetailViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *nextButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *prevButton;

-(IBAction)moveToNextPhoto:(id)sender;
-(IBAction)moveToPrevPhoto:(id)sender;
-(void) downloadImage;
- (CGRect)getRectForImageToDisplay: (CGSize) size;

@end


@implementation PhotoDetailViewController

@synthesize indicator=indicator_;
@synthesize photoList=photoList_;
@synthesize currentIndexRow=currentIndexRow_;

@synthesize imageView=imageView_;
@synthesize nextButton=nextButton_;
@synthesize prevButton=prevButton_;
@synthesize delegate;

#pragma mark - Photo Support Methods
-(IBAction)moveToNextPhoto:(id)sender {
    
    //if currently downloading then cancel current loading
    if (self.indicator.hidden==NO) {
        [self.indicator stopAnimating];
        self.indicator.hidden=YES;
        [self.photoList.imageDownloader cancelDownload];
        }
    
    self.currentIndexRow++;
    self.imageView.image=nil;
    self.indicator.hidden=NO;
    [self.indicator startAnimating];
    [self downloadImage];
    
    //disable button if the last object is loaded
    if (self.currentIndexRow+1==[self.photoList.photos count])
        self.nextButton.enabled=!self.nextButton.enabled;
    
    if (self.currentIndexRow>0 && self.prevButton.enabled==NO)
        self.prevButton.enabled=!self.prevButton.enabled;
    
    if (self.currentIndexRow+1<[self.photoList.photos count] && self.nextButton.enabled==NO)
        self.nextButton.enabled=!self.nextButton.enabled;
    
    //update photostream controller which row is currently being viewed
    [delegate imageDidNewImageSelected:self row:self.currentIndexRow];
}

-(IBAction)moveToPrevPhoto:(id)sender {
    //if currently downloading then cancel current load
    if (self.indicator.hidden==NO) {
        [self.indicator stopAnimating];
        self.indicator.hidden=YES;
        [self.photoList.imageDownloader cancelDownload];
    }
    
    self.currentIndexRow--;
    self.imageView.image=nil;
    self.indicator.hidden=NO;
    [self.indicator startAnimating];
    [self downloadImage];
    
    //disable button if the first object is loaded
    if (self.currentIndexRow==0)
        self.prevButton.enabled=!self.prevButton.enabled;
    
    if (self.currentIndexRow>0 && self.prevButton.enabled==NO)
        self.prevButton.enabled=!self.prevButton.enabled;
    
    if (self.currentIndexRow+1<[self.photoList.photos count] && self.nextButton.enabled==NO)
        self.nextButton.enabled=!self.nextButton.enabled;
    
    //update photostream controller which row is currently being viewed
    [delegate imageDidNewImageSelected:self row:self.currentIndexRow];

    
}

-(void) downloadImage {
    NSString *urlString=[[self.photoList.photos objectAtIndex:self.currentIndexRow] valueForKeyPath:@"image_url"];
    [self.photoList.imageDownloader downloadImage:urlString];
}

- (CGRect)getRectForImageToDisplay: (CGSize) size {
    CGFloat scale=320/size.width;
    CGFloat yOffset = scale * size.height;
    
    if (floorf(208-(yOffset/2)-22) < 0) {
        return CGRectMake(0, 0, 320, 374);
    }
    else return CGRectMake(0, floorf(208-(yOffset/2)-22), 320, floorf(yOffset));
}

#pragma mark 

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
    [self.photoList.imageDownloader cancelDownload];
    [self.photoList.imageDownloader clearCache];
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.indicator startAnimating];
    if (self.currentIndexRow+1==[self.photoList.photos count])
        self.nextButton.enabled=!self.nextButton.enabled;
    
    if (self.currentIndexRow==0)
        self.prevButton.enabled=!self.prevButton.enabled;
    
    [self downloadImage];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.photoList.imageDownloader cancelDownload];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.indicator=nil;
    self.photoList=nil;
    self.imageView=nil;
    self.prevButton=nil;
    self.nextButton=nil;    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - ImageDownloader Delegate

- (void) imageDidFinishedLoading:(ImageDownloader*)imageDownloaderObj image:(UIImage *) image {
    [self.indicator stopAnimating];
    self.indicator.hidden=YES;
    self.imageView.frame=[self getRectForImageToDisplay:image.size];
    self.imageView.image=image;
}

- (void) errorOccurred:(ImageDownloader*)imageDownloaderObj error:(NSString *) error {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Returned" message:error delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil,nil];
    [alert show];
    self.indicator.hidden=YES;
    [delegate dismissDetailSegue:self];
}
@end
