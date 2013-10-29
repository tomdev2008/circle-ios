//
//  BaseMessageViewController.m
//  Circle
//
//  Created by admin on 13-9-30.
//  Copyright (c) 2013年 icss. All rights reserved.
//

#import "BaseMessageViewController.h"
#import "MMessageInfo.h"
#import "MLoginInfo.h"
#import "BRImagePickerViewController.h"
#import "BRCameraPickerViewController.h"
#import "UserProfileViewController.h"
#import "MyProfileViewController.h"
#import "MJPhotoBrowser.h"
#import "MJPhoto.h"

#define FRAME_ORIGIN_Y self.view.frame.origin.y

@interface BaseMessageViewController (){
    MessageInputView *toolBar;
    NSString *_myJID;
    MMessageInfo* mMessage;
    POVoiceHUD* voiceHud;
    NSMutableArray *tempMessages;
    BOOL IS_KEY_BOARD_SHOW;
    BOOL IS_SELECT_AREA;
    float toolBar_Y;
}
@property (assign, nonatomic) CGFloat previousTextViewContentHeight;
@end

@implementation BaseMessageViewController

- (id) initWithId:(NSString *)jid isGroup:(BOOL)isGroup
{
    self = [super init];
    if(self){
        targetJID = jid;
        isGrouping = isGroup;
    }
    return self;
} 
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.loadMoreEnabled = NO;
    [self setupHeader];
    [self setupInput];
    [self setupVoice];
    tempMessages = [[NSMutableArray alloc] init];
    if(self.navigationController.navigationBar.backItem == nil){
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"menu", nil)
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:(DEMONavigationController *)self.navigationController
                                                                                action:@selector(showMenu)];
    }
    
    _myJID = [MLoginInfo getActiveUserId];
    self.title = [MBaseModel getNameCache:targetJID];
    self.tableView.separatorColor=[UIColor clearColor];
    self.tableView.frame = CGRectMake(0.0f, 0.0f,self.view.frame.size.width, self.view.frame.size.height - INPUT_HEIGHT);
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableTabRecognizer:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    [self.tableView addGestureRecognizer:singleTapRecognizer];
    page = 0;
    mMessage = [[MMessageInfo alloc] initWithId:targetJID isGroup:isGrouping push:^(NSObject *result, MDataOperator mDataOperator,BOOL hasError) {
        if(result){
            XMPPMessageArchiving_Message_CoreDataObject *msg = (XMPPMessageArchiving_Message_CoreDataObject *)result;
            if(msg.isOutgoing && ([msg.message hasImageRequest]||[msg.message hasFileRequest]))return;
            if(items.count>0){
                NSString *splitTime = [self autoTimeRowItem:result insertItem:items[items.count-1]];
                if(splitTime!=nil){
                    [items addObject:splitTime];
                }
            }else{ 
                [self addTimeRow:result];
            }
            [items addObject:result];
            [self.tableView reloadData];
            [self scrollToBottomAnimated:YES];
        }
    }];
    [self refresh];

}
-(void)setupVoice{
    voiceHud = [[POVoiceHUD alloc] initWithParentView:self.view];
    voiceHud.title = NSLocalizedString(@"voice.title", nil);
    [voiceHud setDelegate:self];
    [self.view addSubview:voiceHud];
}
- (void)setupInput
{
    CGSize size = self.view.frame.size;
    CGRect inputFrame = CGRectMake(0.0f, size.height - INPUT_HEIGHT, size.width, INPUT_HEIGHT);
    toolBar_Y = inputFrame.origin.y;
    toolBar = [[MessageInputView alloc] initWithFrame:inputFrame];
    toolBar.textView.returnKeyType = UIReturnKeySend;
    toolBar.textView.delegate = self;
    toolBar.shareMoreView.delegate = self;
    [toolBar.soundButton addTarget:self action:@selector(soundPressed:) forControlEvents:UIControlEventTouchUpInside];
    [toolBar.attachedButton addTarget:self action:@selector(attachedPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:toolBar];
    
}

- (void) pinHeaderView
{
    [super pinHeaderView];
    // do custom handling for the header view
    DemoTableHeaderView *hv = (DemoTableHeaderView *)self.headerView;
    [hv.activityIndicator startAnimating];
    hv.title.text = NSLocalizedString(@"tip.loading", nil);
}
//
// Update the header text while the user is dragging
//
- (void) headerViewDidScroll:(BOOL)willRefreshOnRelease scrollView:(UIScrollView *)scrollView
{
    DemoTableHeaderView *hv = (DemoTableHeaderView *)self.headerView;
    if (willRefreshOnRelease)
        hv.title.text = NSLocalizedString(@"tip.release.loadmore", nil);
    else
        hv.title.text = NSLocalizedString(@"tip.pull.loadmore", nil);
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleWillShowKeyboard:)
												 name:UIKeyboardWillShowNotification
                                               object:nil];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleWillHideKeyboard:)
												 name:UIKeyboardWillHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}
#pragma mark - Actions

- (void)viewBecomeActive:(NSNotification *)notification
{
    [toolBar.textView resignFirstResponder];
}
- (void)tableTabRecognizer:(UIGestureRecognizer *)guestureRecognizer
{
    float y = self.view.frame.origin.y;
    if(!IS_KEY_BOARD_SHOW && y<0){
        [self resizeFrame:KEY_BOARD_HEIGHT];
    }
    [toolBar.textView resignFirstResponder];
}

- (void) completeSendMessage{
    [MessageSoundEffect playMessageSentSound];
    [toolBar.textView setText:nil];
    [self textViewDidChange:toolBar.textView];
}
- (void) resetToolBar{
    [toolBar.textView setInputView:nil];
    [toolBar.textView setText:nil];
    self.previousTextViewContentHeight = toolBar.textView.contentSize.height;
    [toolBar changeSelectButton:toolBar.attachedButton];
    [self textViewDidChange:toolBar.textView];
    [toolBar.textView resignFirstResponder];
}
- (void) resetToolBarUnSetButton{
    [toolBar.textView setInputView:nil];
    [toolBar.textView setText:nil];
    self.previousTextViewContentHeight = toolBar.textView.contentSize.height;
    [self textViewDidChange:toolBar.textView];
    [toolBar.textView resignFirstResponder];
}
- (void)soundPressed:(UIButton *)sender{
    [self resetToolBarUnSetButton];
    [voiceHud startForFilePath:[NSString stringWithFormat:@"%@/Documents/%lu.caf", NSHomeDirectory(),(long)[[NSDate date] timeIntervalSince1970]]];
}
- (void)attachedPressed:(UIButton *)sender{
    [toolBar.textView setInputView:nil];
    [toolBar.textView setText:nil];
    [toolBar.textView reloadInputViews];
    [toolBar.textView resignFirstResponder];
    if(FRAME_ORIGIN_Y==0){
        [self resizeFrame:-KEY_BOARD_HEIGHT];
    }
    IS_SELECT_AREA = YES;
}
- (void) pickImageHandle:(BRImagePickerViewControllerType) sourceType{
    BRImagePickerViewController *imagePicker = [[BRImagePickerViewController alloc] init];
    imagePicker.sourceType = sourceType;
    imagePicker.captureHandler = ^(BRAbstarctPreviewViewController *previewViewController,UIImage *image,NSData * imageData){
        [self dismissViewControllerAnimated:YES completion:NULL];
        NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
        [item setObject:@"image" forKey:@"type"];
        [item setObject:imageData forKey:@"content"];
        [items addObject:item];
        [self resetToolBar];
        [self.tableView reloadData];
        [self scrollToBottomAnimated:YES];
    };
    imagePicker.canceledHandler =^(){
        [self resetToolBar];
    };
    [imagePicker presentImagePickerInViewController:self];
}

- (void)pickPhoto
{
    [self pickImageHandle:BRImagePickerViewControllerTypePhotoLibrary];
}

- (void)cameraPhoto
{
    [self pickImageHandle:BRImagePickerViewControllerTypeCamera];
}

#pragma mark - CustomMessageDelegate
-(void)upLoadMessageImageProgress:(NSData *)content progress:(ProgressIndicator *)progress completed:(ActionCompletedBlock)completedBlock
{
    [mMessage uploadImage:content progress:progress completed:^(NSObject *result, BOOL hasError) {
        if(hasError){
            return;
        }
        [mMessage postImage:(NSString*)result completed:^(NSObject *result2, BOOL hasError) {
            [tempMessages addObject:result2];
            if(completedBlock)completedBlock((NSString*)result,hasError);
            [self completeSendMessage];
        }];
    }];
}
-(void)upLoadMessageSoundProgress:(NSString *)content progress:(ProgressIndicator *)progress completed:(ActionCompletedBlock)completedBlock
{
    [mMessage uploadSound:content progress:progress completed:^(NSObject *result, BOOL hasError) {
        if(hasError){
            return;
        }
        [mMessage postFile:(NSString*)result completed:^(NSObject *result2, BOOL hasError) {
            [tempMessages addObject:result2];
            if(completedBlock)completedBlock((NSString*)result,hasError);
            [self completeSendMessage];
        }];
    }];
}
- (void)viewMessageFullImage:(NSString *)content image:(UIImage *)image{
    
    NSMutableArray *bImages = [[NSMutableArray alloc] init];
    NSMutableArray *sImages = [[NSMutableArray alloc] init];
    int pos = 0;
    for(int i=0;i<items.count;i++){
        if([items[i] isKindOfClass:[NSDictionary class]]){
            NSDictionary *dict = items[i];
            if([[dict objectForKey:@"type"] isEqualToString:@"image"] && [dict objectForKey:@"img"]!=nil){
                if([[dict objectForKey:@"img"] isEqualToString:content]){
                    pos = bImages.count;
                }
                [bImages addObject:[NSString stringWithFormat:API_DOWN_IMAGE_URL,[dict objectForKey:@"img"]]];
                [sImages addObject:[NSString stringWithFormat:API_DOWN_IMAGE_URL,[NSString stringWithFormat:@"small/%@",[dict objectForKey:@"img"]]]];
            }
            continue;
        }
        if(![items[i] isKindOfClass:[XMPPMessageArchiving_Message_CoreDataObject class]])continue;
        XMPPMessageArchiving_Message_CoreDataObject *msg =  (XMPPMessageArchiving_Message_CoreDataObject *)items[i];
        BOOL hasImage = [msg.message hasImageRequest];
        if(!hasImage)continue;
        if([msg.body isEqualToString:content]){
            pos = bImages.count;
        }
        [bImages addObject:[NSString stringWithFormat:API_DOWN_IMAGE_URL,msg.body]];
        [sImages addObject:[NSString stringWithFormat:API_DOWN_IMAGE_URL,[NSString stringWithFormat:@"small/%@",msg.body]]];
    }
    int count = bImages.count;
    // 1.封装图片数据
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i<count; i++) {
        //替换为中等尺寸图片
        MJPhoto *photo = [[MJPhoto alloc] init];
        photo.url = [NSURL URLWithString:bImages[i]]; // 图片路径
        //photo.srcImageView = self.view.subviews[i]; // 来源于哪个UIImageView
        [photos addObject:photo];
    }
    
    // 2.显示相册
    MJPhotoBrowser *browser = [[MJPhotoBrowser alloc] init];
    browser.currentPhotoIndex = pos; // 弹出相册时显示的第一张图片是？
    browser.photos = photos; // 设置所有的图片
    [browser show];
}
- (void)viewMessageUserProfile:(NSString *)profileId{
    [self resetToolBarUnSetButton];
    UIViewController *controller = [[UserProfileViewController alloc] initWithProfileId:profileId sourceType:@"chat"];
    if(profileId == _myJID){
        controller = [[MyProfileViewController alloc] init];
    }else{
        controller = [[UserProfileViewController alloc] initWithProfileId:profileId sourceType:@"chat"];
    }
    [self.navigationController pushViewController:controller animated:YES];
}
#pragma mark - POVoiceHUD Delegate

- (void)POVoiceHUD:(POVoiceHUD *)voiceHUD voiceRecorded:(NSString *)recordPath length:(float)recordLength{
     NSLog(@"Sound recorded with file %@ for %.2f seconds", [recordPath lastPathComponent], recordLength);
    
    NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
    [item setObject:@"sound" forKey:@"type"];
    [item setObject:recordPath forKey:@"content"];
    [items addObject:item];
    [self resetToolBarUnSetButton];
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
    voiceHUD.alpha = 0.0;
}

- (void)voiceRecordCancelledByUser:(POVoiceHUD *)voiceHUD {
    NSLog(@"Voice recording cancelled for HUD: %@", voiceHUD);
}

#pragma mark - Pull to Refresh

//
// refresh the list. Do your async calls here.
//
- (BOOL) refresh
{
    if (![super refresh])
        return NO;
    [self reloadNextSource];
    return YES;
}

-(void) addTimeRow:(id)curItem
{
    if(curItem == nil)return;
    if([curItem isKindOfClass:[XMPPMessageArchiving_Message_CoreDataObject class]]){
        NSDate *curTime = ((XMPPMessageArchiving_Message_CoreDataObject *)curItem).timestamp;
        [items insertObject:[curTime xmppDisplayDateTimeString] atIndex:0];
    }
}
-(NSString *) autoTimeRowItem:(id) curItem insertItem:(id)insertItem
{
    if(curItem==nil || insertItem==nil)return nil;
    NSTimeInterval secondsInterval = 0;
    NSDate *curTime;
    if([curItem isKindOfClass:[XMPPMessageArchiving_Message_CoreDataObject class]] && [insertItem isKindOfClass:[XMPPMessageArchiving_Message_CoreDataObject class]]){
        NSDate *insertTime = ((XMPPMessageArchiving_Message_CoreDataObject *)insertItem).timestamp;
        curTime = ((XMPPMessageArchiving_Message_CoreDataObject *)curItem).timestamp;
        secondsInterval = [curTime timeIntervalSinceDate:insertTime];
    }
    if(secondsInterval<5*60){
        return nil;
    }
    if(curTime!=nil){
        return [curTime xmppDisplayDateTimeString];
    }
    return nil;
}
-(void) processDataSource:(NSArray*) array
{
    if(array.count==0)
        return;
    for(int i=0;i<array.count;i++){
        NSString *msgId = ((XMPPMessageArchiving_Message_CoreDataObject *)array[i]).messageID;
        if([tempMessages containsObject:msgId])continue;
        NSString *splitTime = [self autoTimeRowItem:items.count==0?nil:items[0] insertItem:array[i]];
        if(splitTime!=nil){
            [items insertObject:splitTime atIndex:0];
        }
        [items insertObject:array[i] atIndex:0];
    }
}
- (void) reloadNextSource
{
    page++;
    [mMessage list:page completed:^(NSObject *result, BOOL hasError) {
        [self refreshCompleted];
        NSArray *dataItems = (NSArray *)result;
        if(hasError || dataItems.count<1){
            page--;
            return;
        }
        [self processDataSource:dataItems];
        [self.tableView reloadData];
        if(page==1){
            [self.tableView setContentOffset:CGPointMake(0, CGFLOAT_MAX) animated:NO];
            //[self scrollToBottomAnimated:YES];
        }
    }];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Standard TableView delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CustomMessageCell *cell;
    BubbleMessageStyle style = [self messageStyleForRowAtIndexPath:indexPath];
    NSString *CellID = [NSString stringWithFormat:@"MessageCell%d", style];
    cell = [tableView dequeueReusableCellWithIdentifier:CellID];
    if(!cell) {
        cell = [[CustomMessageCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellID];
        cell.delegate = self;
    }
    cell.msgStyle = style;
    [cell setMessage:[self jidForRowAtIndexPath:indexPath] content:[self textForRowAtIndexPath:indexPath]];
    return cell;
}
#pragma mark - Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BubbleMessageStyle style = [self messageStyleForRowAtIndexPath:indexPath];
    if(style == BubbleMessageStyleTime){
        return 40;
    }
    else if(style==BubbleMessageStyleOutgoingImage || style==BubbleMessageStyleIncomingImage){
        return 55+70;
    }else if(style==BubbleMessageStyleOutgoingSound || style==BubbleMessageStyleIncomingSound){
        return 55+10;
    }else{
        NSString *orgin = (NSString *)[self textForRowAtIndexPath:indexPath];
        CGSize textSize=[orgin sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:CGSizeMake((320-HEAD_SIZE-3*INSETS-40), TEXT_MAX_HEIGHT) lineBreakMode:NSLineBreakByWordWrapping];
        return MAX(60, 35+textSize.height);
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //BubbleMessageStyle style = [self messageStyleForRowAtIndexPath:indexPath];
}
- (NSString *)jidForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id obj = [items objectAtIndex:indexPath.row];
    if([obj isKindOfClass:[XMPPMessageArchiving_Message_CoreDataObject class]])
    {
        XMPPMessageArchiving_Message_CoreDataObject *msg = (XMPPMessageArchiving_Message_CoreDataObject *)obj;
        if(msg.isOutgoing)
            return _myJID;
        else
            return [msg.bareJid user];
    }else if([obj isKindOfClass:[NSDictionary class]]){
        return _myJID;
    }
    else{
        return nil;
    }
}
- (NSObject *)textForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id obj = [items objectAtIndex:indexPath.row];
    if([obj isKindOfClass:[XMPPMessageArchiving_Message_CoreDataObject class]])
    {
        XMPPMessageArchiving_Message_CoreDataObject *msg = ((XMPPMessageArchiving_Message_CoreDataObject *)obj);
        //return [NSString stringWithFormat:@"%@\n%@",[msg.timestamp xmppDateTimeLongString], msg.body];
        return msg.body;
    }else if([obj isKindOfClass:[NSDictionary class]]){
        return (NSDictionary*)obj;
    }
    else{
        return (NSString *)obj;
    }
}
- (BubbleMessageStyle)messageStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id obj = [items objectAtIndex:indexPath.row];
    if([obj isKindOfClass:[NSDictionary class]]){
        NSDictionary *dict = (NSDictionary*)obj;
        return [[dict objectForKey:@"type"] isEqualToString:@"image"]?BubbleMessageStyleOutgoingImage:BubbleMessageStyleOutgoingSound;
    }
    else if([obj isKindOfClass:[XMPPMessageArchiving_Message_CoreDataObject class]])
    {
        XMPPMessageArchiving_Message_CoreDataObject *msg =  (XMPPMessageArchiving_Message_CoreDataObject *)obj;
        BOOL isOutgoing = [msg isOutgoing];
        BOOL hasImage = [msg.message hasImageRequest];
        BOOL hasFile = [msg.message hasFileRequest];
        if(isOutgoing){
            if(hasImage)
                return BubbleMessageStyleOutgoingImage;
            if(hasFile)
                return BubbleMessageStyleOutgoingSound;
            else
                return BubbleMessageStyleOutgoing;
        }else{
            if(hasImage)
                return BubbleMessageStyleIncomingImage;
            if(hasFile)
                return BubbleMessageStyleIncomingSound;
            else
                return BubbleMessageStyleIncoming;
        }
    }
    else{
        return BubbleMessageStyleTime;
    }
}

- (void)setBackgroundColor:(UIColor *)color
{
    self.view.backgroundColor = color;
    self.headerView.backgroundColor = color;
    self.tableView.backgroundColor = color;
    self.tableView.separatorColor = color;
}
- (void)scrollToBottomAnimated:(BOOL)animated
{
    if(items.count > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:items.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

#pragma mark - Textview delegate
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [textView becomeFirstResponder];
    if(!self.previousTextViewContentHeight)
		self.previousTextViewContentHeight = textView.contentSize.height;
    
    [self scrollToBottomAnimated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView
{
    IS_SELECT_AREA = NO;
    CGFloat maxHeight = [MessageInputView maxHeight];
    CGFloat textViewContentHeight = textView.contentSize.height;
    CGFloat changeInHeight = textViewContentHeight - self.previousTextViewContentHeight;
    changeInHeight = (textViewContentHeight + changeInHeight >= maxHeight) ? 0.0f : changeInHeight;
    if(changeInHeight != 0.0f) {
        [UIView animateWithDuration:0.25f
                         animations:^{
                             UIEdgeInsets insets = UIEdgeInsetsMake(0.0f, 0.0f, self.tableView.contentInset.bottom + changeInHeight, 0.0f);
                             self.tableView.contentInset = insets;
                             self.tableView.scrollIndicatorInsets = insets;
                             
                             [self scrollToBottomAnimated:NO];
                             
                             CGRect inputViewFrame = toolBar.frame;
                             toolBar.frame = CGRectMake(0.0f,
                                                               inputViewFrame.origin.y - changeInHeight,
                                                               inputViewFrame.size.width,
                                                               inputViewFrame.size.height + changeInHeight);
                         }
                         completion:^(BOOL finished) {
                         }];
        
        self.previousTextViewContentHeight = MIN(textViewContentHeight, maxHeight);
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)atext
{
	if(![textView hasText] && [atext isEqualToString:@""])
    {
        return NO;
	}
	if ([atext isEqualToString:@"\n"])
    {
        NSString *text = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet ]];
        if(text==nil||[text isEqualToString:@""] )return NO;
        [mMessage post:toolBar.textView.text completed:^(NSObject *result, BOOL hasError) {
            if(hasError)return;
            [self completeSendMessage];
        }];
        return NO;
    }
	return YES;
}

#pragma mark - Keyboard notifications
- (void)handleWillShowKeyboard:(NSNotification *)notification
{
    if(IS_SELECT_AREA && FRAME_ORIGIN_Y<0){
        [self resizeFrame:KEY_BOARD_HEIGHT];
    }
    IS_KEY_BOARD_SHOW = YES;
    [self changeKeyBoard:notification];
}

- (void)handleWillHideKeyboard:(NSNotification *)notification
{
    IS_KEY_BOARD_SHOW = NO;
    [self changeKeyBoard:notification];
}

#pragma mark ----键盘高度变化------
-(void)changeKeyBoard:(NSNotification *)aNotifacation
{
    //获取到键盘frame 变化之前的frame
    NSValue *keyboardBeginBounds=[[aNotifacation userInfo]objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect beginRect=[keyboardBeginBounds CGRectValue];
    
    //获取到键盘frame变化之后的frame
    NSValue *keyboardEndBounds=[[aNotifacation userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    CGRect endRect=[keyboardEndBounds CGRectValue];
    CGFloat deltaY=endRect.origin.y-beginRect.origin.y;
    //拿frame变化之后的origin.y-变化之前的origin.y，其差值(带正负号)就是我们self.view的y方向上的增量
    [self resizeFrame:deltaY];
    
}
- (void)resizeFrame:(float)deltaY
{
    NSLog(@"deltaY:%f",deltaY);
    //[UIView animateWithDuration:0.5f
     //                animations:^{
                         [self.view setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+deltaY, self.view.frame.size.width, self.view.frame.size.height)];
                         [self.tableView setContentInset:UIEdgeInsetsMake(self.tableView.contentInset.top-deltaY, 0, 0, 0)];
   //                  }
 //                    completion:^(BOOL finished) {
                     
 //                    }];
}
@end
