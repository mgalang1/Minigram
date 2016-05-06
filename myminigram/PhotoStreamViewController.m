//
//  PhotoStreamViewController.m
//  MyMinigram
//
//  Created by Marvin Galang on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PhotoStreamViewController.h"
#import "PhotoDetailViewController.h"
#import <QuartzCore/QuartzCore.h>

#define kCustomRowHeight    60.0

@interface PhotoStreamViewController () <PhotoCollectionDelegate,UIScrollViewDelegate,ThumbnailDownloaderDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate,ImageDownloaderDelegate,PhotoDetailViewControllerDelegate> 

@property (nonatomic, strong) PhotoCollection *photoList;
@property (nonatomic, strong) NSMutableDictionary *thumbIcons;
@property (nonatomic, strong) NSMutableArray *thumbKeys;
@property (nonatomic, strong) NSMutableDictionary *iconDownloadsInProgress;

@property (nonatomic, strong) IBOutlet UIView *captionBar;
@property (nonatomic, strong) IBOutlet UITextField *captionField;
@property (nonatomic, strong) IBOutlet UIView *imageSourceView;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIProgressView *progressBar;
@property (nonatomic, strong) IBOutlet UIButton *cameraOption;

@property (nonatomic, strong) NSData *jpegData;
@property (nonatomic, assign) NSUInteger imageSource;


- (void)startIconDownload:(NSString *)key urlString:(NSString *)urlString atIndexPath:(NSIndexPath *) indexPath;
- (void)loadImagesForOnscreenRows;
- (void)uploadNewPhotoWithImageData:(NSData *)jpegData caption:(NSString *)caption;
- (void)presentImagePickerController;
- (void) hideKeyboard;
- (CGRect)getRectForImageToDisplay: (CGSize) size;


- (IBAction)cancelImageSource:(id)sender;
- (IBAction)presentImageSource:(id)sender;
- (IBAction)selectedImageSource:(id)sender;

- (IBAction)uploadPhoto:(id)sender;
- (IBAction)cancelUpload:(id)sender;
- (IBAction)refreshData:(id)sender;

@end

@implementation PhotoStreamViewController

@synthesize photoList=photoList_;
@synthesize thumbKeys=thumbKeys_;
@synthesize thumbIcons=thumbIcons_;
@synthesize captionBar = captionBar_;
@synthesize captionField = captionField_;
@synthesize jpegData = jpegData_;
@synthesize imageSource=imageSource_;
@synthesize imageSourceView=imageSourceView_;
@synthesize tableView=tableView_;
@synthesize progressBar=progressBar_;
@synthesize iconDownloadsInProgress=iconDownloadsInProgress_;
@synthesize cameraOption=cameraOption_;

#pragma mark - Initializers

- (id)initWithCoder:(NSCoder *)coder;
{
    if ((self = [super initWithCoder:coder])) {
        // initialize photoList
        self.photoList=[[PhotoCollection alloc] init];
        self.photoList.delegate=self;
        
        //refresh photolist by sending GET request
        [self.photoList refreshPhotoList];
        
        //initialize dictionary that will hold the icon images
        self.thumbIcons = [NSMutableDictionary dictionary];
        self.thumbKeys = [NSMutableArray array];
        self.iconDownloadsInProgress = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark -

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    self.thumbIcons=nil;
    self.thumbKeys=nil;
    [self.photoList.imageDownloader cancelUpload];
    
    // terminate all pending download connections
    NSArray *allDownloads = [self.iconDownloadsInProgress allValues];
    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
    
    // Release any cached data, images, etc that aren't in use.
    [self.photoList.imageDownloader cancelDownload];
    [self.photoList.imageDownloader clearCache];
    self.jpegData=nil;
    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.thumbIcons=nil;
    self.thumbKeys=nil;
    self.captionBar=nil;
    self.captionField=nil;
    self.imageSourceView=nil;
    self.tableView=nil;
    self.jpegData=nil;
    self.iconDownloadsInProgress=nil;
    self.cameraOption=nil;
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    int count = [self.photoList.photos count];
	
	// if there's no data yet, return enough rows to fill the screen
    if (count == 0)
        {
        self.tableView.allowsSelection=NO;
        return 6;
        }
    self.tableView.allowsSelection=YES;
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *CellIdentifier = @"PhotoStreamCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UIActivityIndicatorView *iconProgress = nil;
    for (UIView *oneView in cell.contentView.subviews) {
        if ([oneView isMemberOfClass:[UIActivityIndicatorView class]])
            iconProgress = (UIActivityIndicatorView *)oneView;
    }
    
    if (!iconProgress) {
        UIActivityIndicatorView *iconProgress = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(27, 27, 15, 15)];
        iconProgress.activityIndicatorViewStyle=UIActivityIndicatorViewStyleGray;
        [cell.contentView addSubview:iconProgress];
    }
    
    //this if statement wont be called since a tabkeViewCell is configured in the NIB
    /*if (cell == nil)
        {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier] ;   
        cell.detailTextLabel.textAlignment = UITextAlignmentCenter;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
        }*/
    
    int nodeCount = [self.photoList.photos count];
    
    if (nodeCount == 0 ) {
        
        cell.textLabel.text=nil;
        cell.detailTextLabel.text = @"Loading…";
        cell.imageView.image=[UIImage imageNamed:@"Placeholder.png"];
        
        [cell.contentView bringSubviewToFront:iconProgress];
        iconProgress.hidden=NO;
        [iconProgress startAnimating];
        
        UIActivityIndicatorView *iconP = nil;
        
        for (UIView *oneView in cell.contentView.subviews) {
            if ([oneView isMemberOfClass:[UIActivityIndicatorView class]])
                iconP = (UIActivityIndicatorView *)oneView;
        }
        [cell.contentView bringSubviewToFront:iconP];
        iconP.hidden=NO;
        [iconP startAnimating];
        
        return cell;
        }
    
    if (nodeCount > 0) {
        NSUInteger row = [indexPath row];
        cell.textLabel.text = [[self.photoList.photos objectAtIndex:row] valueForKeyPath:@"title"];
        cell.detailTextLabel.text=[[self.photoList.photos objectAtIndex:row] valueForKeyPath:@"username"];
        cell.imageView.image=[UIImage imageNamed:@"Placeholder.png"];
        
        //determineKey from the thumbnail URL
        NSString *urlString=[[self.photoList.photos objectAtIndex:row] valueForKeyPath:@"image_thumbnail_url"];
        NSRange range = [urlString rangeOfString:@".png?" options:NSCaseInsensitiveSearch | NSBackwardsSearch];
        
        NSString *key=[urlString substringFromIndex:range.location + 5];

        // Only load cached images; defer new downloads until scrolling ends
        if (![self.thumbIcons valueForKey:key])
            {
            if (self.tableView.dragging == NO && self.tableView.decelerating == NO)
                {
                [self startIconDownload:key urlString:urlString atIndexPath:indexPath];
                }
                // if a download is deferred or in progress, return a placeholder image
                cell.imageView.image = [UIImage imageNamed:@"Placeholder.png"];
                UIActivityIndicatorView *iconP = nil;
            
                for (UIView *oneView in cell.contentView.subviews) {
                    if ([oneView isMemberOfClass:[UIActivityIndicatorView class]])
                        iconP = (UIActivityIndicatorView *)oneView;
                }
                [cell.contentView bringSubviewToFront:iconP];
                iconP.hidden=NO;
                [iconP startAnimating];
            }
        else
            {
                cell.imageView.image = [self.thumbIcons valueForKey:key];
                
                UIActivityIndicatorView *iconP = nil;
                for (UIView *oneView in cell.contentView.subviews) {
                    if ([oneView isMemberOfClass:[UIActivityIndicatorView class]])
                        iconP = (UIActivityIndicatorView *)oneView;
                    }
                [iconP stopAnimating];
                iconP.hidden=YES;
                
            }
    }
    return cell;

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}
    

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}


#pragma mark - Custom Delegate Methods

//array containing photos already downloaded from the web server
- (void) photoCollectionDidFinishedLoadingCollection:(PhotoCollection *)myPhotoCollection {
    
    [self.tableView reloadData];
}

//Finished uploading photo
- (void) imageDidFinishedUploading:(ImageDownloader*)imageDownloaderObj {
    //hide progress bar once uploading is completed.
    self.progressBar.hidden=YES;
    
    //refresh photoList
    [self.photoList refreshPhotoList];
}

//An Icon had been downloaded successfully
- (void) iconDidFinishedLoading:(ThumbnailDownloader*)thumbnailDownloaderObj key:(NSString *)key image:(UIImage *) image atIndexPath:(NSIndexPath *) indexPath {
    
    //remove ThumbnailDownloader object from the IconDownloader currently in progress dictionary
    [self.iconDownloadsInProgress removeObjectForKey:key];
    
    //if thumbicons anf thumbkeys had been release due to memory warning, initialize it again
    if (!self.thumbKeys)
        self.thumbKeys = [NSMutableArray array];
        
    if (!self.thumbIcons)
        self.thumbIcons = [NSMutableDictionary dictionary];
    
    
    //check if iconCollection exceeds 100, store only 100 icons
    if ([self.thumbIcons count]>100) {
        NSString *removeKey=[self.thumbKeys objectAtIndex:0];
        [self.thumbKeys removeObjectAtIndex:0];
        [self.thumbIcons removeObjectForKey:removeKey];
    }
    
    [self.thumbKeys addObject:key];
    [self.thumbIcons setValue:image forKey:key];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    // Display the newly loaded image
    cell.imageView.image = image;
    
    UIActivityIndicatorView *iconP = nil;
    
    for (UIView *oneView in cell.contentView.subviews) {
        if ([oneView isMemberOfClass:[UIActivityIndicatorView class]])
            iconP = (UIActivityIndicatorView *)oneView;
    }
    [iconP stopAnimating];
    iconP.hidden=YES;
    
    
}


- (void) imageDidNewImageSelected:(PhotoDetailViewController *)photoDetailViewControllerObj row:(NSUInteger) row {
    
    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
    //update tableView selected cell
    [self.tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    
}

- (void) progressBarUpdated:(ImageDownloader*)imageDownloaderObj progress:(float) progress error:(NSString *) error {
    
    //update progress Bar
    if (progress==2.0) {
        self.progressBar.hidden=YES;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Returned" message:error delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil,nil];
        [alert show];
        return;
    }
    
    self.progressBar.progress=progress;
}

- (void) dismissDetailSegue:(PhotoDetailViewController *)photoDetailViewControllerObj {

}

- (void) errorGetPhoto:(PhotoCollection *)myPhotoCollection error:(NSString *) error {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fetch Photos Failed" message:error delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil,nil];
    [alert show];

}

#pragma mark - Table cell image support

// this method is used in case the user scrolled into a set of cells that don't have their app icons yet
- (void)loadImagesForOnscreenRows
{
    if ([self.photoList.photos count] > 0)
        {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
            {
            //determine Key from the thumbnail URL
            NSString *urlString=[[self.photoList.photos objectAtIndex:indexPath.row] valueForKeyPath:@"image_thumbnail_url"];
            NSRange range = [urlString rangeOfString:@".png?" options:NSCaseInsensitiveSearch | NSBackwardsSearch];
            
            NSString *key=[urlString substringFromIndex:range.location + 5];
            
            if (![self.thumbIcons valueForKey:key])
                {
                [self startIconDownload:key urlString:urlString atIndexPath:indexPath];
                }
            }
        }
}


- (void)startIconDownload:(NSString *)key urlString:(NSString *)urlString atIndexPath:(NSIndexPath *) indexPath
{
    ThumbnailDownloader *iconDownloader = [[ThumbnailDownloader alloc] init];
    iconDownloader.delegate = self;
    [self.iconDownloadsInProgress setObject:iconDownloader forKey:key];
    [iconDownloader downLoadThumbnail:key urlString:urlString atIndexPath:indexPath];
}

- (void)uploadNewPhotoWithImageData:(NSData *)jpegData caption:(NSString *)caption
{
    //set self as delegate
    self.photoList.imageDownloader.delegate=self;
    
    //enable progessView indicator
    self.progressBar.hidden=NO;
    self.progressBar.progress=0;
    
    [self.photoList.imageDownloader uploadImage:caption image:jpegData];
    
    
}

- (void)presentImagePickerController;
{
    
    //Remove imageSourceView from superView
    [self.imageSourceView removeFromSuperview];
    
    // Create an instance of UIImagePickerController
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    
    if (self.imageSource==1) 
        // Configure it to use the camera
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    else
        //Get photo from the photo Library
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    // Become the delegate of the image picker so we're informed when it has cancelled or taken a new photo
    imagePickerController.delegate = self;
    
    // Present the image picker
    [self presentViewController:imagePickerController animated:YES completion:NULL];
}

- (CGRect)getRectForImageToDisplay: (CGSize) size {
    CGFloat scale=320/size.width;
    CGFloat yOffset = scale * size.height;
    
    return CGRectMake(0, floorf(215-(yOffset/2)+44), 320, floorf(yOffset));
    
}

#pragma mark - Segue Notification methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"PhotoDetail"]) {
        PhotoDetailViewController *photoView = [segue destinationViewController];
        photoView.photoList = self.photoList;
        photoView.delegate=self;
        photoView.photoList.imageDownloader.delegate=photoView;
        photoView.currentIndexRow=[[self.tableView indexPathForSelectedRow] row];
        photoView.indicator.hidden=NO;
    }
    
}

#pragma mark -
#pragma mark Deferred image loading (UIScrollViewDelegate)

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
        {
        [self loadImagesForOnscreenRows];
        }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForOnscreenRows];
}


#pragma mark - Target/Action Methods

- (IBAction)presentImageSource:(id)sender;
{
    //disable tableView scrolling and selection
    [self.tableView selectRowAtIndexPath:nil animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    self.tableView.allowsSelection=NO;
    self.tableView.scrollEnabled=NO;   
    
    UINib *imageSourceNib = [UINib nibWithNibName:@"imageSourceOption" bundle:nil];
    [imageSourceNib instantiateWithOwner:self options:nil];
    
    //if camera not available disable camera option as source of photo
    if ((![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]))
        {
        self.cameraOption.alpha=0.2;
        self.cameraOption.enabled=NO;
        }
    
    //set image source view frame further down the screen
    CGRect animatedViewFrame = self.imageSourceView.frame;
    animatedViewFrame.origin.y = 1000;
    self.imageSourceView.frame = animatedViewFrame;
    
    [self.view addSubview:self.imageSourceView];
    
    // Animate addition of image source View
    animatedViewFrame.origin.y = 201;
    
      [UIView animateWithDuration:0.25 animations:^{
          
         imageSourceView_.frame = animatedViewFrame;
     }];

}

- (IBAction)selectedImageSource:(id)sender {
    
    //enable tableView scrolling and selection
    self.tableView.allowsSelection=YES;
    self.tableView.scrollEnabled=YES;
    
    UIButton *imageButton=(UIButton *) sender;
    
    if ([imageButton.currentTitle isEqualToString:@"From Camera"]) self.imageSource=1;
    if ([imageButton.currentTitle isEqualToString:@"From Saved Photos"]) self.imageSource=2;    
    
    if (self.imageSource==1 || self.imageSource==2) [self presentImagePickerController];
    
}


- (IBAction)cancelImageSource:(id)sender;
{
    CGRect animatedViewFrame = self.imageSourceView.frame;
    animatedViewFrame.origin.y = 1000;
    self.imageSourceView.frame = animatedViewFrame;
    
    //animate removel of image Source View
    [UIView animateWithDuration:0.25 animations:^{
        imageSourceView_.frame = animatedViewFrame;
    }];
    
    //Remove it from superView
    [self.imageSourceView removeFromSuperview];
    
    //enable tableView scrolling and selection
    self.tableView.allowsSelection=YES;
    self.tableView.scrollEnabled=YES;
}

- (IBAction)refreshData:(id)sender {
    [self.photoList refreshPhotoList];
}

- (IBAction)uploadPhoto:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self uploadNewPhotoWithImageData:self.jpegData caption:self.captionField.text];
        }];
}

- (IBAction)cancelUpload:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
{
    
    // Extract the new image from the picker
    UIImage *photoImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.jpegData = UIImageJPEGRepresentation(photoImage, 0.8);
    
    //set picker views entire window in front of the status bar
    picker.view.window.windowLevel=UIWindowLevelStatusBar;
        
    //Create a view that will fill up the whole screen
    UIView *overlayView = [[UIView alloc] initWithFrame:CGRectMake(0,0,320, 480)];
    overlayView.backgroundColor=[UIColor blackColor];
    
    //Create a tap recognizer object when the user tap the overlay View
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [overlayView addGestureRecognizer:gestureRecognizer];
    
    //add the selected image to the overlaysubview to be presented on top of the picker controller view
    UIImageView *iv = [[UIImageView alloc] initWithFrame:[self getRectForImageToDisplay:photoImage.size]];
        [iv setImage:photoImage];
    [overlayView addSubview:iv];
    
    //set opaque to YES
    overlayView.opaque = YES;
    
    //add the overlayView as subview of picker vieww
    [picker.view addSubview:overlayView];
    
    // Present a caption field to the user
    UINib *captionBarNib = [UINib nibWithNibName:@"imageCaptionBar" bundle:nil];
    [captionBarNib instantiateWithOwner:self options:nil];
    
    // Add drop shadow to set the bar apart from the photo
    self.captionBar.layer.shadowOpacity = 0.5;
    self.captionBar.layer.shadowOffset = CGSizeMake(0, 2);
    self.captionBar.layer.shadowColor = [[UIColor blackColor] CGColor];
    
    //add caption bar to picker view
    [picker.view addSubview:self.captionBar];
    
    
    // Animate the caption field and bar so that they drop in nicely from the top of the screen as the keyboard is sliding up
    CGRect barFrame = self.captionBar.frame;
    barFrame.origin.y = -barFrame.size.height;
    self.captionBar.frame = barFrame;
    
    [UIView animateWithDuration:0.25 animations:^{
        CGRect animatedBarFrame = barFrame;
        animatedBarFrame.origin.y = 0;
        captionBar_.frame = animatedBarFrame;
    }];
    
    // Make the caption field first responder, which will give it key focus and bring up the keyboard
    [self.captionField becomeFirstResponder];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Text Field Methods/Delegate

- (void) hideKeyboard {
    //hide keyboard when textfield is not tap.
    if ([self.captionField isFirstResponder]==YES)
        [self.captionField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    // Dismiss the keyboard
    [textField resignFirstResponder];
    return YES;
}


@end
