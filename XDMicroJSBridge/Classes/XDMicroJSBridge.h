//
//  XDMicroJSBridge.h
//  XDMicroJSBridge
//
//  Created by 蔡欣东 on 2018/4/19.
//

#import <UIKit/UIKit.h>

typedef void(^XDMCJSBCallback)(NSDictionary *response);
typedef void(^XDMCJSBHandle)(NSArray *params, XDMCJSBCallback callback);
typedef void(^XDMCJSBWebViewDidStartLoad)(UIWebView *webView);
typedef void(^XDMCJSBWebViewFinishLoad)(UIWebView *webView);
typedef void(^XDMCJSBWebViewDidFailLoad)(UIWebView *webView, NSError *error);

@interface XDMicroJSBridge : NSObject

//为注入的方法设置命名空间，默认是XDMCBridge
@property (nonatomic, copy) NSString *nameSpace;

//初始化bridge
+ (instancetype)bridgeForWebView:(UIWebView *)webView;

/**
 注册js函数给h5进行原生调用
 
 @param action 函数名
 @param handler 原生处理方法
 */
- (void)registerAction:(NSString *)action handler:(XDMCJSBHandle)handler;

/**
 原生调用h5的js函数
 
 @param action 函数名
 @param param 函数参数列表
 */
- (void)callAction:(NSString *)action param:(NSArray *)param;

@end
