//
//  ViewController.m
//  Example
//
//  Created by Evgeniy Yurtaev on 15/09/15.
//
//

#import "ViewController.h"
#import "EYMaskedTextField.h"

@interface ViewController () <EYMaskedTextFieldDelegate>

@end

@implementation ViewController

- (BOOL)textField:(UITextField *)textField shouldChangeUnformattedText:(NSString *)unformattedText inRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *targetText = [unformattedText stringByReplacingCharactersInRange:range withString:string];
    NSCharacterSet *notNumberCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
    NSRange notNumberCharacterRange = [targetText rangeOfCharacterFromSet:notNumberCharacterSet options:0];
    BOOL isNumber = (notNumberCharacterRange.length == 0);
    
    return isNumber;
}

@end
