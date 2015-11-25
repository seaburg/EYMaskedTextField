# EYMaskedTextField
UITextField with customizable input mask. 

![Screenshot example](https://raw.githubusercontent.com/seaburg/EYMaskedTextField/master/Screenshots/Screenshot.png)
Installation
------------
```
pod 'EYMaskedTextField', '~> 0.1.1'
```
Usage
-----
    #import <EYMaskedTextField/EYMaskedTextField.h>
    ...
    EYMaskedTextField *textField = [[EYMaskedTextField alloc] init];
    textField.mask = @"+⍓ (⍓⍓⍓) ⍓⍓⍓ ⍓⍓ ⍓⍓";
    ...
