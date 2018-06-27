//
//  XDViewController.m
//  XDMicroJSBridge
//
//  Created by 458770054@qq.com on 04/19/2018.
//  Copyright (c) 2018 458770054@qq.com. All rights reserved.
//

#import "XDViewController.h"
#import "XDMicroJSBridge.h"
#import "Base64.h"
#import "XDViewController_WK.h"

@interface XDViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic, strong) UIWebView *webview;

@property (nonatomic, strong) XDMicroJSBridge *bridge;

@property (nonatomic, copy) XDMCJSBCallback callback;

@end

@implementation XDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"XDMicroJSBridge demo";
    
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont systemFontOfSize:18]}];
    
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self _initWebView];
    
    [self _initBridge];
}

- (void)_initWebView {
    self.webview = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:_webview];
    [self.view sendSubviewToBack:_webview];
    
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"];
    NSString *content = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    [_webview loadHTMLString:content baseURL:nil];
}

- (void)_initBridge {
    self.bridge = [XDMicroJSBridge bridgeForWebView:_webview];
    
    __weak typeof(self) weakself = self;
    [_bridge registerAction:@"camerapicker" handler:^(NSArray *params, XDMCJSBCallback callback) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                weakself.callback = callback;
            }
            UIImagePickerController *cameraVC = [[UIImagePickerController alloc] init];
            cameraVC.delegate = weakself;
            cameraVC.sourceType = UIImagePickerControllerSourceTypeCamera;
            [weakself presentViewController:cameraVC animated:YES completion:nil];
        });
    }];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:@"public.image"]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSData *imageData = UIImageJPEGRepresentation(image,1) ;
        if (imageData.length > 500000) {
            CGFloat ratio = 500000.0/imageData.length;
            imageData = UIImageJPEGRepresentation(image,ratio) ;
        }
        NSString *base64 = [imageData base64EncodedString];
        NSString *source = [NSString stringWithFormat:@"data:image/jpeg;base64,%@", base64];
        NSArray *soureArr = @[source];
        NSDictionary *value = @{@"photos":soureArr};
        if(self.callback) {
            self.callback(value);
        }
        
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)wkdemoclick:(UIButton *)sender {
    XDViewController_WK *vc = [[XDViewController_WK alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}


@end
