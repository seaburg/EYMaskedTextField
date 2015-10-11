//
//  EYMaskedTextField.m
//
//
//  Created by Evgeniy Yurtaev on 10/09/15.
//  Copyright (c) 2015 Evgeniy Yurtaev. All rights reserved.
//

#import "EYMaskedTextField.h"

static NSString *const EYMaskAnySymbol = @"⍓";

static NSUInteger EYNSStringNumberOfSymbols(NSString *string)
{
    __block NSUInteger numberOfSymbols = 0;
    [string enumerateSubstringsInRange:NSMakeRange(0, string.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        numberOfSymbols += 1;
    }];
    return numberOfSymbols;
}

static NSRange EYNSStringRangeToSymbolsRange(NSString *string, NSRange range)
{
    __block NSUInteger location = 0;
    __block NSUInteger length = 0;
    [string enumerateSubstringsInRange:NSMakeRange(0, string.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if (NSMaxRange(substringRange) <= range.location) {
            ++location;
        } else if (NSMaxRange(substringRange) <= NSMaxRange(range)) {
            ++length;
        } else {
            *stop = YES;
        }
    }];
    if (range.length < 1) {
        length = 0;
    }
    return NSMakeRange(location, length);
}

static NSRange EYNSStringSymbolsRangeToRange(NSString *string, NSRange symbolsRange)
{
    __block NSUInteger numberOfSkippedSymbols = symbolsRange.location;
    __block NSUInteger numberOfTakenSymbols = symbolsRange.length;

    __block NSUInteger location = 0;
    __block NSUInteger length = 0;

    [string enumerateSubstringsInRange:NSMakeRange(0, string.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if (numberOfSkippedSymbols > 0) {
            --numberOfSkippedSymbols;
            location += substring.length;
        } else if (numberOfTakenSymbols > 0) {
            --numberOfTakenSymbols;
            length += substring.length;
        } else {
            *stop = YES;
        }
    }];

    return NSMakeRange(location, length);
}

@interface EYMaskedTextField () <EYMaskedTextFieldDelegate>

@property (assign, nonatomic) id<EYMaskedTextFieldDelegate> originDelegate;

@end

@implementation EYMaskedTextField

@dynamic delegate;

- (void)commonInit
{
    if (self.delegate != self) {
        [super setDelegate:self];
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self commonInit];
}

#pragma mark - Properties

- (void)setMask:(NSString *)mask
{
    NSString *unformattedText = [self filteredStringFromString:self.text cursorPosition:NULL];
    _mask = mask;
    self.unformattedText = unformattedText;
}

- (NSString *)unformattedText
{
    if (!self.text) {
        return nil;
    }
    return [self filteredStringFromString:self.text cursorPosition:NULL];
}

- (void)setUnformattedText:(NSString *)unformattedText
{
    self.text = [self formattedStringFromString:unformattedText cursorPosition:NULL];
}

- (void)setDelegate:(id<EYMaskedTextFieldDelegate>)delegate
{
    self.originDelegate = delegate;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSInteger targetCursorPosition;
    NSRange symbolsRange = EYNSStringRangeToSymbolsRange(self.text, range);
    BOOL isBackspace = string.length < 1;
    if (isBackspace) {
        symbolsRange = [self backspaceRangeWithSymbolsRange:symbolsRange];
        targetCursorPosition = symbolsRange.location;
    } else {
        targetCursorPosition = [self cursorPositionWithSymbolsRange:symbolsRange];
    }

    NSRange filteredTextSymbolsRange = [self filteredRangeFromFormattedSymbolsRange:symbolsRange];
    NSString *filteredText = [self filteredStringFromString:textField.text cursorPosition:&targetCursorPosition];
    
    NSRange filteredTextRange = EYNSStringSymbolsRangeToRange(filteredText, filteredTextSymbolsRange);
    if ([self.originDelegate respondsToSelector:@selector(textField:shouldChangeUnformattedText:inRange:replacementString:)]) {
        if (![self.originDelegate textField:self shouldChangeUnformattedText:filteredText inRange:filteredTextRange replacementString:string]) {
            return NO;
        }
    }
    filteredText = [filteredText stringByReplacingCharactersInRange:filteredTextRange withString:string];

    NSUInteger numberOfStringSymbols = EYNSStringNumberOfSymbols(string);
    targetCursorPosition = MIN(numberOfStringSymbols + targetCursorPosition, EYNSStringNumberOfSymbols(filteredText));
    NSString *targetText = [self formattedStringFromString:filteredText cursorPosition:&targetCursorPosition];

    BOOL shouldChange = YES;
    if (self.originDelegate != self && [self.originDelegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        NSRange changeSybmolsRange = [self formattedRangeFromFilteredRange:NSMakeRange(filteredTextSymbolsRange.location, numberOfStringSymbols)];
        NSString *replacementString = [targetText substringWithRange:EYNSStringSymbolsRangeToRange(targetText, changeSybmolsRange)];
        shouldChange = [self.originDelegate textField:self shouldChangeCharactersInRange:range replacementString:replacementString];
    }

    if (shouldChange) {
        self.text = targetText;
        NSInteger cursorPosition = EYNSStringSymbolsRangeToRange(self.text, NSMakeRange(targetCursorPosition, 0)).location;
        UITextPosition *targetPosition = [textField positionFromPosition:[textField beginningOfDocument] offset:(NSInteger)cursorPosition];
        [textField setSelectedTextRange:[textField textRangeFromPosition:targetPosition toPosition:targetPosition]];

        [self sendActionsForControlEvents:UIControlEventEditingChanged];
    }

    return NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    BOOL shouldBeginEditing = YES;
    if (self.originDelegate != self && [self.originDelegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]) {
        shouldBeginEditing = [self.originDelegate textFieldShouldBeginEditing:textField];
    }
    return shouldBeginEditing;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.originDelegate != self && [self.originDelegate respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
        [self.originDelegate textFieldDidBeginEditing:textField];
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    BOOL shouldEndEditing = YES;
    if (self.originDelegate != self && [self.originDelegate respondsToSelector:@selector(textFieldShouldEndEditing:)]) {
        shouldEndEditing = [self.originDelegate textFieldShouldEndEditing:textField];
    }
    return shouldEndEditing;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.originDelegate != self && [self.originDelegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
        [self.originDelegate textFieldDidEndEditing:textField];
    }
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    BOOL shouldClear = YES;
    if (self.originDelegate != self && [self.originDelegate respondsToSelector:@selector(textFieldShouldClear:)]) {
        shouldClear = [self.originDelegate textFieldShouldClear:textField];
    }
    return shouldClear;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BOOL shouldReturn = YES;
    if (self.originDelegate != self && [self.originDelegate respondsToSelector:@selector(textFieldShouldReturn:)]) {
        shouldReturn = [self.originDelegate textFieldShouldReturn:textField];
    }
    return shouldReturn;
}

#pragma mark - Private methods

- (NSString *)filteredStringFromString:(NSString *)string cursorPosition:(NSInteger *)cursorPositionPtr
{
    __block NSInteger cursorPosition = cursorPositionPtr ? *cursorPositionPtr : 0;
    __block NSInteger originCursorPosition = cursorPosition;
    NSUInteger maskLength = EYNSStringNumberOfSymbols(self.mask);

    __block NSUInteger stringSymbolIndex = 0;
    __block NSUInteger maskSymbolIndex = 0;
    NSMutableString *filteredString = [NSMutableString string];
    [string enumerateSubstringsInRange:NSMakeRange(0, string.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if (stringSymbolIndex >= maskLength) {
            *stop = YES;
            return;
        }
        NSRange maskSymbolRange = [self.mask rangeOfComposedCharacterSequenceAtIndex:maskSymbolIndex];
        NSString *maskSymbol = [self.mask substringWithRange:maskSymbolRange];

        if ([maskSymbol isEqualToString:EYMaskAnySymbol]) {
            [filteredString appendString:substring];
        } else {
            if ((NSInteger)stringSymbolIndex < originCursorPosition) {
                cursorPosition -= 1;
            }
        }
        ++stringSymbolIndex;
        maskSymbolIndex += maskSymbolRange.length;
    }];
    if (cursorPositionPtr) {
        *cursorPositionPtr = MAX(cursorPosition, 0);
    }

    return [filteredString copy];
}

- (NSString *)formattedStringFromString:(NSString *)string cursorPosition:(NSInteger *)cursorPositionPtr
{
    __block NSInteger cursorPosition = cursorPositionPtr ? *cursorPositionPtr : 0;

    __block NSUInteger stringIndex = 0;
    __block NSUInteger maskSymbolIndex = 0;

    NSMutableString *formattedString = [NSMutableString string];
    [self.mask enumerateSubstringsInRange:NSMakeRange(0, self.mask.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {

        if (![substring isEqualToString:EYMaskAnySymbol]) {
            [formattedString appendString:substring];
            if ((NSInteger)maskSymbolIndex <= cursorPosition) {
                cursorPosition += 1;
            }
        } else if (stringIndex < string.length) {
            NSRange stringSymbolRange = [string rangeOfComposedCharacterSequenceAtIndex:stringIndex];
            NSString *stringSymbol = [string substringWithRange:stringSymbolRange];
            [formattedString appendString:stringSymbol];
            stringIndex += stringSymbolRange.length;
        } else {
            *stop = YES;
            return;
        }
        ++maskSymbolIndex;
    }];
    if (cursorPositionPtr) {
        *cursorPositionPtr = MIN(cursorPosition, EYNSStringNumberOfSymbols(formattedString));
    }

    return [formattedString copy];
}

- (NSRange)filteredRangeFromFormattedSymbolsRange:(NSRange)formattedSymbolsRange
{
    __block NSUInteger filteredRangeLocation = 0;
    __block NSUInteger filteredRangeLength = 0;

    __block NSUInteger maskSymbolIndex = 0;
    [self.mask enumerateSubstringsInRange:NSMakeRange(0, self.mask.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if (maskSymbolIndex >= NSMaxRange(formattedSymbolsRange)) {
            *stop = YES;
            return;
        }

        if ([substring isEqualToString:EYMaskAnySymbol]) {
            if (maskSymbolIndex < formattedSymbolsRange.location) {
                ++filteredRangeLocation;
            } else {
                ++filteredRangeLength;
            }
        }
        ++maskSymbolIndex;
    }];
    return NSMakeRange(filteredRangeLocation, filteredRangeLength);
}

- (NSRange)formattedRangeFromFilteredRange:(NSRange)filteredRange
{
    __block NSUInteger numberOfSkippedSymbols = filteredRange.location;
    __block NSUInteger numberOfTakenSymbols = filteredRange.length;

    __block NSUInteger formattedRangeLocation = 0;
    __block NSUInteger formattedRangeLength = 0;

    [self.mask enumerateSubstringsInRange:NSMakeRange(0, self.mask.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if (numberOfSkippedSymbols > 0) {
            if ([substring isEqualToString:EYMaskAnySymbol]) {
                --numberOfSkippedSymbols;
            }
            ++formattedRangeLocation;
        } else if (numberOfTakenSymbols > 0) {
            if ([substring isEqualToString:EYMaskAnySymbol]) {
                --numberOfTakenSymbols;
            }
            ++formattedRangeLength;
        } else {
            *stop = YES;
            return;
        }
    }];
    return NSMakeRange(formattedRangeLocation, formattedRangeLength);
}

- (NSRange)backspaceRangeWithSymbolsRange:(NSRange)symbolsRange
{
    NSRange maskRange = EYNSStringSymbolsRangeToRange(self.mask, symbolsRange);
    NSString *removedSubmask = [self.mask substringWithRange:maskRange];
    if ([removedSubmask rangeOfString:EYMaskAnySymbol].length > 0) {
        return symbolsRange;
    }

    __block NSRange backspaceRange = symbolsRange;
    [self.mask enumerateSubstringsInRange:NSMakeRange(0, maskRange.location) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if ([substring isEqualToString:EYMaskAnySymbol]) {
            backspaceRange = substringRange;
        }
    }];
    NSRange backspaceSymbolsRange = EYNSStringRangeToSymbolsRange(self.mask, backspaceRange);

    return backspaceSymbolsRange;
}

- (NSInteger)cursorPositionWithSymbolsRange:(NSRange)symbolsRange
{
    NSRange maskRange = EYNSStringSymbolsRangeToRange(self.mask, symbolsRange);

    NSRange anySumbolRange = [self.mask rangeOfString:EYMaskAnySymbol options:0 range:NSMakeRange(maskRange.location, self.mask.length - maskRange.location)];

    NSUInteger cursorPosition;
    if (anySumbolRange.location != NSNotFound) {
        cursorPosition = EYNSStringRangeToSymbolsRange(self.mask, anySumbolRange).location;
    } else {
        cursorPosition = symbolsRange.location;
    }
    return (NSInteger)cursorPosition;
}

@end
