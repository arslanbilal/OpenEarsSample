//
//  ViewController.m
//  TTSSampleDemo
//
//  Created by Bilal Arslan on 11/08/15.
//  Copyright (c) 2015 Bilal Arslan. All rights reserved.
//

#import "ViewController.h"
#import <OpenEars/OELanguageModelGenerator.h>
#import <OpenEars/OEPocketsphinxController.h>
#import <OpenEars/OEFliteController.h>
#import <OpenEars/OEAcousticModel.h>
#import <OpenEars/OEEventsObserver.h>
#import <Slt/Slt.h>


#define kFileName @"language-model-files"
#define kAcousticModel @"AcousticModelEnglish"


@interface ViewController () <OEEventsObserverDelegate>

@property (nonatomic, strong) OELanguageModelGenerator *languageModelGenerator;
@property (nonatomic, strong) NSDictionary *recognizedCommands;
@property (nonatomic, strong) NSArray *recognizedCommandsArray;
@property (nonatomic, strong) NSString *languageModelPath;
@property (nonatomic, strong) NSString *dictionaryPath;
@property (nonatomic, strong) OEFliteController *fliteController;
@property (nonatomic, strong) Slt *slt;
@property (nonatomic, strong) OEEventsObserver *openEarsEventsObserver;
@property (nonatomic, strong) UIButton *micControlButton;
@property (nonatomic, strong) UILabel *recognizedText;
@property (nonatomic, assign) CGFloat width;

@end

#pragma mark - Class Implementation

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // OEEventsObserver is the class which keeps you continuously updated about the status of your listening session, among other things, via delegate callbacks
    _openEarsEventsObserver = [[OEEventsObserver alloc] init];
    [_openEarsEventsObserver setDelegate:self];
    
    _width = [[UIScreen mainScreen] bounds].size.width;
    
    _micControlButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 50, _width - 100, 50)];
    [[_micControlButton layer] setCornerRadius:7.5];
    [_micControlButton setTitle:@"Listening" forState:UIControlStateNormal];
    [_micControlButton setBackgroundColor:[UIColor greenColor]];
    [_micControlButton addTarget:self action:@selector(didTapMicButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_micControlButton];
    
    _recognizedText = [[UILabel alloc] initWithFrame:CGRectMake(25, 125, _width - 50, 100)];
    [_recognizedText setNumberOfLines:0];
    [_recognizedText setText:@"-"];
    [self.view addSubview:_recognizedText];
    
    _languageModelGenerator = [[OELanguageModelGenerator alloc] init];

    // Array(Dictionary) of Words and Phares taht want to recognize by App
    
    /*
     @{
     ThisWillBeSaidOnce : @[
     @{ OneOfTheseCanBeSaidOnce : @[@"HELLO COMPUTER", @"GREETINGS ROBOT"]},
     @{ OneOfTheseWillBeSaidOnce : @[@"DO THE FOLLOWING", @"INSTRUCTION"]},
     @{ OneOfTheseWillBeSaidOnce : @[@"GO", @"MOVE"]},
     @{ThisWillBeSaidWithOptionalRepetitions : @[
     @{ OneOfTheseWillBeSaidOnce : @[@"10", @"20",@"30"]},
     @{ OneOfTheseWillBeSaidOnce : @[@"LEFT", @"RIGHT", @"FORWARD"]}
     ]},
     @{ OneOfTheseWillBeSaidOnce : @[@"EXECUTE", @"DO IT"]},
     @{ ThisCanBeSaidOnce : @[@"THANK YOU"]}
     ]
     };
     */
    
    _recognizedCommands = @{
                             ThisWillBeSaidOnce : @[
                                     //@{ OneOfTheseWillBeSaidOnce : @[@"HELLO IRIS", @"HEY IRIS", @"HEY"]},
                                     @{ OneOfTheseWillBeSaidOnce : @[@"ONE", @"TWO"]},
                                     @{ OneOfTheseWillBeSaidOnce : @[@"THREE", @"FOUR"]},
                                     @{ ThisCanBeSaidOnce : @[@"THANK YOU"]}
                                     ],
                             OneOfTheseWillBeSaidOnce : @[@"TEN", @"ELEVEN", @"TWELVE", @"HUNDRED"],
                             OneOfTheseCanBeSaidOnce : @[@"TABLE", @"DESK", @"FLOOR"]
                             };
    
    _recognizedCommandsArray = @[@"DEMO APP"];
    
    
//    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:_recognizedCommandsArray
//                                                              withFilesNamed:kFileName
//                                                      forAcousticModelAtPath:[OEAcousticModel
//                                                                              pathToModel:kAcousticModel]];
    
    NSError *error = [_languageModelGenerator generateGrammarFromDictionary:_recognizedCommands
                                                             withFilesNamed:kFileName
                                                     forAcousticModelAtPath:[OEAcousticModel
                                                                pathToModel:kAcousticModel]];
    
    if (error == nil) {
        _languageModelPath = [_languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:kFileName];
        _dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:kFileName];
        
        [[OEPocketsphinxController sharedInstance] setActive:YES error:nil];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:_languageModelPath
                                                                        dictionaryAtPath:_dictionaryPath
                                                                     acousticModelAtPath:[OEAcousticModel
                                                                                          pathToModel:kAcousticModel]
                                                                     languageModelIsJSGF:NO];
        

    } else {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    
}

#pragma mark - Button Actions

- (void)didTapMicButton:(UIButton *)button {
    
    UIColor *buttonBackgroundColor = nil;
    NSString *buttonTitle = nil;
    
    if (_micControlButton.backgroundColor == [UIColor greenColor]) {
        buttonBackgroundColor = [UIColor redColor];
        buttonTitle = @"Listen";
        [[OEPocketsphinxController sharedInstance] suspendRecognition];
    } else {
        buttonBackgroundColor = [UIColor greenColor];
        buttonTitle = @"Listening...";
        [[OEPocketsphinxController sharedInstance] resumeRecognition];
    }

    [_micControlButton setBackgroundColor:buttonBackgroundColor];
    [_micControlButton setTitle:buttonTitle forState:UIControlStateNormal];
}

#pragma mark - OEEventsObserver Delegate

- (void)pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID);
    [_recognizedText setText:hypothesis];
}

- (void)pocketsphinxDidStartListening {
    NSLog(@"Pocketsphinx is now listening.");
}

- (void)pocketsphinxDidDetectSpeech {
    NSLog(@"Pocketsphinx has detected speech.");
    //[_recognizedText setText:@"-"];
}

//- (void)pocketsphinxDidDetectFinishedSpeech {
//    NSLog(@"Pocketsphinx has detected a period of silence, concluding an utterance.");
//}

//- (void)pocketsphinxDidStopListening {
//    NSLog(@"Pocketsphinx has stopped listening.");
//}

- (void)pocketsphinxDidSuspendRecognition {
    NSLog(@"Pocketsphinx has suspended recognition.");
}

- (void)pocketsphinxDidResumeRecognition {
    NSLog(@"Pocketsphinx has resumed recognition.");
}

//- (void)pocketsphinxDidChangeLanguageModelToFile:(NSString *)newLanguageModelPathAsString andDictionary:(NSString *)newDictionaryPathAsString {
//    NSLog(@"Pocketsphinx is now using the following language model: \n%@ and the following dictionary: %@",newLanguageModelPathAsString,newDictionaryPathAsString);
//}

//- (void)pocketSphinxContinuousSetupDidFailWithReason:(NSString *)reasonForFailure {
//    NSLog(@"Listening setup wasn't successful and returned the failure reason: %@", reasonForFailure);
//}

//- (void)pocketSphinxContinuousTeardownDidFailWithReason:(NSString *)reasonForFailure {
//    NSLog(@"Listening teardown wasn't successful and returned the failure reason: %@", reasonForFailure);
//}

- (void)pocketsphinxFailedNoMicPermissions {

}

- (void)micPermissionCheckCompleted:(BOOL)result {
    if (result) { } else { }
}

@end
;