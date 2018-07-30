//
//  XDMicroJSBridge_WK.m
//  XDMicroJSBridge
//
//  Created by 蔡欣东 on 2018/6/19.
//

#import "XDMicroJSBridge_WK.h"

static NSString *injectJS = @"var XDMCBridge = {};var xd_jscallback_center={_callbackbuf:{},addCallback:function(a,c){\"function\"==typeof c&&(this._callbackbuf[a]=c)},fireCallback:function(a,c){if(\"string\"==typeof a){var f=this._callbackbuf[a];\"function\"==typeof f&&(void 0===c?f():f(c))}}};";

static NSString *patternJS = @"%@.%@=function(){var a=arguments.length,e={methodName:\"%@\"},l=Array.from(arguments);a>0&&(\"function\"==typeof l[a-1]?(e.callbackId=\"%@\",e.params=a-1>0?l.slice(0,a-1):[]):e.params=l),null!=e.callbackId&&xd_jscallback_center.addCallback(e.callbackId,l[a-1]),window.webkit.messageHandlers.XDWKJB.postMessage(e)};";

@interface XDWKWeakScriptMessageDelegate:NSObject<WKScriptMessageHandler>

@property (nonatomic, weak) id<WKScriptMessageHandler> delegate;

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>) delegate;

@end

@implementation XDWKWeakScriptMessageDelegate

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate {
    if (self = [super init]) {
        _delegate = delegate;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.delegate userContentController:userContentController didReceiveScriptMessage:message];
}

@end

@interface XDMicroJSBridge_WK()<WKScriptMessageHandler>{
    NSMutableDictionary *_jsValueDict;
}
@property (nonatomic, strong) WKWebView *webview;

@end

@implementation XDMicroJSBridge_WK

- (instancetype)init {
    if (self = [super init]) {
        _jsValueDict = [NSMutableDictionary dictionary];
        _nameSpace = @"XDMCBridge";
    }
    return self;
}

- (WKWebView *)getBridgeWebView {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    // 设置偏好设置
    config.preferences = [[WKPreferences alloc] init];
    // 默认为0
    config.preferences.minimumFontSize = 10;
    // 默认认为YES
    config.preferences.javaScriptEnabled = YES;
    // 在iOS上默认为NO，表示不能自动通过窗口打开
    config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    config.processPool = [[WKProcessPool alloc] init];
    config.userContentController = [[WKUserContentController alloc] init];
    //解决self 循环引用问题
    XDWKWeakScriptMessageDelegate *weakSelf = [[XDWKWeakScriptMessageDelegate alloc] initWithDelegate:self];
    [config.userContentController addScriptMessageHandler:weakSelf name:@"XDWKJB"];
    WKUserScript *injectScript = [[WKUserScript alloc] initWithSource:injectJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [config.userContentController addUserScript:injectScript];
    _webview = [[WKWebView alloc] initWithFrame:CGRectNull configuration:config];
    return _webview;
}

- (void)registerAction:(NSString *)action handler:(XDMCJSBHandle)handler {
    _jsValueDict[action] = handler;
    NSString *jsStr = [NSString stringWithFormat:patternJS,_nameSpace,action,action,action];
    WKUserScript *injectScript = [[WKUserScript alloc] initWithSource:jsStr injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [_webview.configuration.userContentController addUserScript:injectScript];
}

- (void)callAction:(NSString *)action param:(NSDictionary *)param {
    NSData *paramData = [NSJSONSerialization dataWithJSONObject:param options:NSJSONWritingPrettyPrinted error:nil];
    NSString *paramStr = [[NSString alloc] initWithData:paramData encoding:NSUTF8StringEncoding];
    NSString *eJS = [NSString stringWithFormat:@"%@(%@)",action,paramStr];
    [self.webview evaluateJavaScript:eJS completionHandler:^(id _Nullable data, NSError * _Nullable error) {
        if (error) {
            NSLog(@"执行js失败 error:%@",error.localizedDescription);
        } else {
            NSLog(@"执行js成功");
        }
    }];
    
}

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    if ([message.name isEqualToString:@"XDWKJB"]) {
        NSDictionary *method = message.body;
        if (method) {
            NSString *methodName = method[@"methodName"];
            NSArray *params = method[@"params"];
            NSString *callbackId = method[@"callbackId"];
            if ([_jsValueDict.allKeys containsObject:methodName]) {
                XDMCJSBCallback ncallback = nil;
                if (callbackId) {
                    __weak typeof(self) weakself = self;
                    ncallback = ^(NSDictionary *params){
                        __strong typeof(weakself) strongself = weakself;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSData *paramData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
                            NSString *paramStr = [[NSString alloc] initWithData:paramData encoding:NSUTF8StringEncoding];
                            NSString *eJS = [NSString stringWithFormat:@"xd_jscallback_center.fireCallback('%@',%@)",callbackId,paramStr];
                            [strongself.webview evaluateJavaScript:eJS completionHandler:^(id _Nullable data, NSError * _Nullable error) {
                                if (error) {
                                    NSLog(@"执行js失败 error:%@",error.localizedDescription);
                                } else {
                                    NSLog(@"执行js成功");
                                }
                            }];
                        });
                    };
                }
                XDMCJSBHandle handle = _jsValueDict[methodName];
                if (handle) {
                    handle(params, ncallback);
                }
            }
        }
    }
}

- (void)setNameSpace:(NSString *)nameSpace {
    _nameSpace = nameSpace;
    NSString *jsStr = [NSString stringWithFormat:@"var %@ = {};",nameSpace];
    WKUserScript *injectScript = [[WKUserScript alloc] initWithSource:jsStr injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [_webview.configuration.userContentController addUserScript:injectScript];
    
}

- (void)dealloc {
    [_webview.configuration.userContentController removeScriptMessageHandlerForName:@"XDWKJB"];
    [_webview.configuration.userContentController removeAllUserScripts];
    [_jsValueDict removeAllObjects];
    NSLog(@"========================XDMicroJSBridge_WK dealloc========================");
}

@end
