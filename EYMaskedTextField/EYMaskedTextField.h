//
//  EYMaskedTextField.h
//
//
//  Created by Evgeniy Yurtaev on 10/09/15.
//  Copyright (c) 2015 Evgeniy Yurtaev. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EYMaskedTextFieldDelegate <UITextFieldDelegate>

@optional
- (BOOL)textField:(UITextField *)textField shouldChangeUnformattedText:(NSString *)unformattedText inRange:(NSRange)range replacementString:(NSString *)string;

@end

@interface EYMaskedTextField : UITextField

@property (copy, nonatomic) IBInspectable NSString *mask;

@property (copy, nonatomic) IBInspectable NSString *unformattedText;

@property (assign, nonatomic) id<EYMaskedTextFieldDelegate> delegate;

@end
