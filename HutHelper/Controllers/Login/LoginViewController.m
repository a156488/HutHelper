//
//  LoginViewController.m
//  HutHelper
//
//  Created by nine on 2016/10/17.
//  Copyright © 2016年 nine. All rights reserved.
//

#import "LoginViewController.h"
#import "WebViewController.h"
#import "LeftSortsViewController.h"
#import "JSONKit.h"
#import "AppDelegate.h"
#import "UMessage.h"
#import "MainPageViewController.h"
#import "MBProgressHUD.h"
#import "AFNetworking.h"
#import "MBProgressHUD+MJ.h"
#import "User.h"
#import <RongIMKit/RongIMKit.h>

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *UserName;
@property (weak, nonatomic) IBOutlet UITextField *Password;
@end

@implementation LoginViewController

- (NSString*)dictionaryToJson:(NSDictionary *)dic
{
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (IBAction)Login:(id)sender {
     [self.view endEditing:YES];
    NSString *UserName_String =[NSString stringWithFormat:@"%@",_UserName.text];
    NSString *Password_String =[NSString stringWithFormat:@"%@",_Password.text];
    [MBProgressHUD showMessage:@"登录中" toView:self.view];
    if ([UserName_String isEqualToString:@""]||[Password_String isEqualToString:@""]) {
        HideAllHUD
        [MBProgressHUD showError:@"请输入账号密码" toView:self.view];
        return;
    }
    [APIRequest GET:[Config getApiLogin:UserName_String passWord:Password_String] parameters:nil
            success:^(id responseObject) {
                 HideAllHUD
        NSDictionary *userAll = [NSDictionary dictionaryWithDictionary:responseObject];
        NSString *msg=userAll[@"msg"];
        if ([msg isEqualToString: @"ok"])
        {
            [Config saveUser:userAll[@"data"]];
            [Config saveRememberCodeApp:userAll[@"remember_code_app"]];
            [Config saveCurrentVersion:[[[NSBundle mainBundle] infoDictionary]
                                        objectForKey:@"CFBundleShortVersionString"]];
            [Config addNotice];
            /**设置友盟标签&别名*/
            [Config saveUmeng];
            //如果是特殊用户
            if (Config.getTrueName ==nil) {
                [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:([self.navigationController.viewControllers count] -2)] animated:YES];  //返回上一个View
                return;
            }
            //请求即时聊天服务的Token
                NSDictionary *dic=@{@"userid":Config.getUserId,
                                    @"name":Config.getTrueName
                                    };
                [APIRequest POST:[Config getApiImToken] parameters:dic
                         success:^(id responseObject) {
                             NSDictionary *resultDictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
                             NSLog(@"%@",resultDictionary);
                             [Config saveImToken:resultDictionary[@"token"]];
                             [[RCIM sharedRCIM] connectWithToken:[Config getImToken]
                                                         success:^(NSString *userId) {
                                                             NSLog(@"登陆成功。当前登录的用户ID：%@", userId);
                                                         } error:^(RCConnectErrorCode status) {
                                                             NSLog(@"私信模块登录错误，错误码:%ld");
                                                         } tokenIncorrect:^{
                                                             NSLog(@"Token错误,您无法使用私信功能,可尝试重新登录");
                                                         }];
                         }
                         failure:^(NSError *error) {
                             NSLog(@"Token获取失败,您无法使用私信功能,可尝试重新登录");
                         }];
            //返回主界面
            [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:([self.navigationController.viewControllers count] -2)] animated:YES];  //返回上一个View
        }
        else {
            NSString *Show_Msg=[msg stringByAppendingString:@",默认密码身份证后六位"];
            if ([msg isEqualToString:@"多次失败，请稍后再试，或修改密码"]) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"密码多次错误" message:msg preferredStyle:  UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"稍后再试" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    //点击按钮的响应事件；
                }]];
                [alert addAction:[UIAlertAction actionWithTitle:@"修改密码" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    UIStoryboard *mainStoryBoard              = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    WebViewController *webViewController = [mainStoryBoard instantiateViewControllerWithIdentifier:@"Web"];
                    webViewController.urlString=Config.getApiLoginReset;
                    webViewController.viewTitle=@"重置密码";
                    [self.navigationController pushViewController:webViewController animated:YES];
                }]];
                //弹出提示框；
                [self presentViewController:alert animated:true completion:nil];
            } else{
                [MBProgressHUD showError:Show_Msg toView:self.view];
            }
            
        }
    }failure:^(NSError *error) {
        HideAllHUD
        [MBProgressHUD showError:@"网络错误或超时" toView:self.view];
    }];
}
- (IBAction)touristBtn:(id)sender {
    NSString *plistPath = [[NSBundle mainBundle]pathForResource:@"touristData" ofType:@"plist"];
    NSDictionary *userAll = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
        NSLog(@"%@",userAll);
    [Config saveUser:userAll[@"data"]];
    [Config saveRememberCodeApp:userAll[@"remember_code_app"]];
    [Config saveCurrentVersion:[[[NSBundle mainBundle] infoDictionary]
                                objectForKey:@"CFBundleShortVersionString"]];
    [Config addNotice];
    [Config saveUmeng];
    [Config saveTourist:YES];
    [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:([self.navigationController.viewControllers count] -2)] animated:YES];  //返回上一个View
}



- (IBAction)End:(id)sender {
    [sender resignFirstResponder];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor whiteColor];
    _UserName.placeholder=@"学 号";
    [_UserName setValue:RGB(202,202,202,1) forKeyPath:@"_placeholderLabel.textColor"];
    _Password.placeholder=@"密 码";
    [_Password setValue:RGB(202,202,202,1) forKeyPath:@"_placeholderLabel.textColor"];
    self.UserName.delegate=self;
    self.Password.delegate=self;
    /** 标题栏样式 */
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = item;
    //空白收起键盘
    self.view.userInteractionEnabled = YES;
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fingerTapped:)];
    [self.view addGestureRecognizer:singleTap];
    //注册键盘弹出通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    //注册键盘隐藏通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    
}

-(void)keyboardWillShow:(NSNotification *)note
{
    NSDictionary *info = [note userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    //目标视图UITextField
    CGRect frame = self.Password.frame;
    int y = frame.origin.y + frame.size.height - (self.view.frame.size.height - keyboardSize.height);
    NSTimeInterval animationDuration = 0.30f;
    [UIView beginAnimations:@"ResizeView" context:nil];
    [UIView setAnimationDuration:animationDuration];
    if(y > 0)
    {
        self.view.frame = CGRectMake(0, -y, self.view.frame.size.width, self.view.frame.size.height);
    }
    [UIView commitAnimations];
}

//键盘隐藏后将视图恢复到原始状态
-(void)keyboardWillHide:(NSNotification *)note
{
    NSTimeInterval animationDuration = 0.30f;
    [UIView beginAnimations:@"ResizeView" context:nil];
    [UIView setAnimationDuration:animationDuration];
    self.view.frame =CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [UIView commitAnimations];
}
- (IBAction)resetpassword:(id)sender {
    UIStoryboard *mainStoryBoard              = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    WebViewController *webViewController = [mainStoryBoard instantiateViewControllerWithIdentifier:@"Web"];
    webViewController.urlString=Config.getApiLoginReset;
    webViewController.viewTitle=@"重置密码";
    [self.navigationController pushViewController:webViewController animated:YES];
}


- (void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    self.navigationController.navigationBarHidden = YES;
}
- (void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    self.navigationController.navigationBarHidden = NO;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

# pragma  mark - 代理方法
-(void)fingerTapped:(UITapGestureRecognizer *)gestureRecognizer
{
    [self.view endEditing:YES];
}



@end

