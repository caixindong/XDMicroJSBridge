//
//  XDMicroJSBridge.m
//  XDMicroJSBridge
//
//  Created by 蔡欣东 on 2018/4/19.
//

#import "XDMicroJSBridge.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface XDMicroJSBridge()

@property (nonatomic, strong) UIWebView *webView;

@property (nonatomic, strong) JSContext *context;

@end

@implementation XDMicroJSBridge

+ (instancetype)bridgeForWebView:(UIWebView *)webView {
    XDMicroJSBridge *brige = [[XDMicroJSBridge alloc] init];
    [brige _setupContext:webView];
    return brige;
}

- (void)_setupContext:(UIWebView *)webView {
    _webView = webView;
    _context = [_webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    _nameSpace = @"XDMCBridge";
    _context[_nameSpace] = @{};
    //解决callback同步问题（会阻塞线程）
    [_context evaluateScript:@"function asyncallback(callback,params) {if(typeof callback == 'function'){setTimeout(function () {callback(params);},0);}}"];
}

- (void)registerAction:(NSString *)action handler:(XDMCJSBHandle)handler {
    if (action && handler) {
        _context[_nameSpace][action] = ^{
            NSArray *args = [JSContext currentArguments];
            JSValue *last = (JSValue *)[args lastObject];
            XDMCJSBCallback ncallback = nil;
            NSMutableArray *trueArgs = [NSMutableArray arrayWithArray:args];
            //context这样引用才不会会循环引用
            JSContext *currentContext = [JSContext currentContext];
            if ([last isObject] && [[last toDictionary] isEqualToDictionary:@{}]) {
                [trueArgs removeLastObject];
                ncallback = ^(NSDictionary *params){
                    //经过测试发现，js执行线程在主线程，所以回调js callback的时候也要回到主线程，如果在其他线程回调callback可能会有野指针carsh
                    dispatch_async(dispatch_get_main_queue(), ^{
                        JSValue *async = currentContext[@"asyncallback"];
                        [async callWithArguments:@[last,params]];
                    });
                };
            }
            NSMutableArray *trueOCArgs = [NSMutableArray array];
            for (JSValue *value in trueArgs) {
                if ([value isObject]) {
                    [trueOCArgs addObject:[value toDictionary]];
                } else if ([value isString]) {
                    [trueOCArgs addObject:[value toString]];
                } else if ([value isNull]) {
                    [trueOCArgs addObject:[NSNull null]];
                } else if ([value isBoolean]) {
                    [trueOCArgs addObject:[NSNumber numberWithBool:[value toBool]]];
                }
            }
            handler([trueOCArgs copy], ncallback);
        };
    }
}

- (void)callAction:(NSString *)action param:(NSArray *)param {
    if (action && param) {
        JSValue *jsMethod = _context[action];
        [jsMethod callWithArguments:param];
    }
}

- (void)setNameSpace:(NSString *)nameSpace {
    _nameSpace = nameSpace;
    _context[_nameSpace] = @{};
}

@end
