//
//  XDMicroJSBridge_WK.h
//  XDMicroJSBridge
//
//  Created by 蔡欣东 on 2018/6/19.
//

#import <WebKit/WebKit.h>

typedef void(^XDMCJSBCallback)(NSDictionary *response);
typedef void(^XDMCJSBHandle)(NSArray *params, XDMCJSBCallback callback);

@interface XDMicroJSBridge_WK : NSObject

//为注入的方法设置命名空间，默认是XDMCBridge
@property (nonatomic, copy) NSString *nameSpace;

- (WKWebView *)getBridgeWebView;

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
- (void)callAction:(NSString *)action param:(NSDictionary *)param;

@end
