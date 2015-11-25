//
//  EYMaskedTextField.h
//
//
//  Created by Evgeniy Yurtaev on 10/09/15.
//  Copyright (c) 2015 Evgeniy Yurtaev. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol EYMaskedTextFieldDelegate <UITextFieldDelegate>

@optional
- (BOOL)textField:(nonnull UITextField *)textField shouldChangeUnformattedText:(nullable NSString *)unformattedText inRange:(NSRange)range replacementString:(nullable NSString *)string;

@end

@interface EYMaskedTextField : UITextField

@property (copy, nonatomic, nullable) IBInspectable NSString *mask;

@property (copy, nonatomic, nullable) IBInspectable NSString *unformattedText;

@property (assign, nonatomic, nullable) id<EYMaskedTextFieldDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
