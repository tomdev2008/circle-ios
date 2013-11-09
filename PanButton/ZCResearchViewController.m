//
//  ZCResearchViewController.m
//  Circle
//
//  Created by Iijy ZC on 13-11-8.
//  Copyright (c) 2013年 icss. All rights reserved.
//

#import "ZCResearchViewController.h"
#import "ZCObjects.h"
#import "ZCLocationView.h"
#import <QuartzCore/QuartzCore.h>
//#import "HMSegmentedControl.h"
#define KBREAK_LABELS 40
#define KRECT_TITLE  80,60,100,25
#define KRECT_LOCATIONVIEW 320, 220, 160, 100
#define KTAG_LABELS 1000
#define KTAG_SEGMENT 2000
//@class ZCLabels;
@interface ZCResearchViewController ()
{
    NSMutableArray *arraylabeltxt;
    NSMutableArray *arraysegmentpaicutxt;
    NSMutableArray *arraysegmentroletxt;
    NSMutableArray *arraysegmentsextxt;
}
@property (strong, nonatomic) UIWindow *window;
@property ZCTextField *textfieldbook;
@property ZCLabels *labelbook;
@property ZCLabelsADD *labeladdbook;
@property ZCSegmentControl *segpaixubook;
@property ZCSegmentControl *segrolebook;
@property ZCSegmentControl *segsexbook;
@end

@implementation ZCResearchViewController

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//----------textfield------//
    _textfieldbook=[[ZCTextField alloc]init];
    _textfieldbook.placeholder=@"请输入姓名";
    [self.view addSubview:_textfieldbook];
    
//----------labels------//
    _labelbook=[[ZCLabels alloc]init];
    _labelbook.frame=CGRectMake(KRECT_TITLE);
    _labelbook.text=@"我要找";
    _labelbook.tag=1999;
    [self.view addSubview:_labelbook];
    arraylabeltxt=[NSMutableArray arrayWithObjects:@"姓名",@"排序", @"角色",@"性别",@"位置",@"圈子",@"常用标签",nil];
    CGFloat yypaixu;
    CGFloat yyrole;
    CGFloat yysex;
    CGFloat yylocation;
    CGFloat yyquanzi;
    for (int i=0; i<7; i++) {
        _labelbook=[[ZCLabels alloc]init];
        _labelbook.frame=CGRectMake(_labelbook.frame.origin.x, _labelbook.frame.origin.y+KBREAK_LABELS*i, _labelbook.frame.size.width, _labelbook.frame.size.height);
        _labelbook.text=[arraylabeltxt objectAtIndex:i];
        if ([_labelbook.text isEqualToString:@"排序"]) {
            yypaixu=_labelbook.frame.origin.y;
        }
        if ([_labelbook.text isEqualToString:@"角色"]) {
            yyrole=_labelbook.frame.origin.y;
        }
        if ([_labelbook.text isEqualToString:@"性别"]) {
            yysex=_labelbook.frame.origin.y;
        }
        if ([_labelbook.text isEqualToString:@"位置"]) {
            yylocation=_labelbook.frame.origin.y;
        }
        if ([_labelbook.text isEqualToString:@"圈子"]) {
            yyquanzi=_labelbook.frame.origin.y;
        }
        
        _labelbook.tag=KTAG_LABELS+i;
        [self.view addSubview:_labelbook];
    }
//----------addlabels------//
    _labeladdbook=[[ZCLabelsADD alloc]init];
    
    _labeladdbook.frame=CGRectMake(_labeladdbook.frame.origin.x,yylocation , _labeladdbook.frame.size.width, _labeladdbook.frame.size.height);
     [_labeladdbook setUserInteractionEnabled:YES];
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(taptheadd:)];
    [_labeladdbook addGestureRecognizer:tap];
    
    [self.view addSubview:_labeladdbook];

    
//----------segmentcontrols------//
    arraysegmentpaicutxt=[NSMutableArray arrayWithObjects:@"远近",@"年龄",@"积分",nil];
    arraysegmentroletxt=[NSMutableArray arrayWithObjects:@"全部",@"飞行",@"乘务",nil];
    arraysegmentsextxt=[NSMutableArray arrayWithObjects:@"全部",@"男",@"女",nil];
    _segpaixubook = [[ZCSegmentControl alloc] initWithItems:arraysegmentpaicutxt];
    _segpaixubook.frame=CGRectMake(_segpaixubook.frame.origin.x, yypaixu, _segpaixubook.frame.size.width, _segpaixubook.frame.size.height);
    [_segpaixubook setTag:KTAG_SEGMENT];
    [self.view addSubview:_segpaixubook];
    

    _segrolebook = [[ZCSegmentControl alloc] initWithItems:arraysegmentroletxt];
    _segrolebook.frame=CGRectMake(_segrolebook.frame.origin.x, yyrole, _segrolebook.frame.size.width, _segrolebook.frame.size.height);
    [_segrolebook setTag:KTAG_SEGMENT+1];
    [self.view addSubview:_segrolebook];

    _segsexbook = [[ZCSegmentControl alloc] initWithItems:arraysegmentsextxt];
    [_segsexbook setTag:KTAG_SEGMENT+2];
    _segsexbook.frame=CGRectMake(_segsexbook.frame.origin.x, yysex, _segsexbook.frame.size.width, _segsexbook.frame.size.height);
    [self.view addSubview:_segsexbook];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)taptheadd:(UIGestureRecognizer *)gesture{
    NSLog(@"hello");
 
    ZCLocationView *locationview=[[ZCLocationView alloc]initWithFrame:CGRectMake(KRECT_LOCATIONVIEW)];
    [self.view addSubview:locationview];
}
@end
