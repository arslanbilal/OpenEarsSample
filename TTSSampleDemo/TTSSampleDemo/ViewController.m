//
//  ViewController.m
//  TTSSampleDemo
//
//  Created by Bilal Arslan on 11/08/15.
//  Copyright (c) 2015 Bilal Arslan. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVAudioSession.h>
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

@end

#pragma mark - Class Implementation

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // OEEventsObserver is the class which keeps you continuously updated about the status of your listening session, among other things, via delegate callbacks
    _openEarsEventsObserver = [[OEEventsObserver alloc] init];
    [_openEarsEventsObserver setDelegate:self];
    
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    
    _micControlButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 50, width - 100, 50)];
    [[_micControlButton layer] setCornerRadius:7.5];
    [_micControlButton setTitle:@"Listening" forState:UIControlStateNormal];
    [_micControlButton setBackgroundColor:[UIColor greenColor]];
    [_micControlButton addTarget:self action:@selector(didTapMicButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_micControlButton];
    [_micControlButton setHidden:YES];
    
    _recognizedText = [[UILabel alloc] initWithFrame:CGRectMake(25, 125, width - 50, 100)];
    [_recognizedText setNumberOfLines:0];
    [_recognizedText setText:@"-"];
    [self.view addSubview:_recognizedText];
    
    _languageModelGenerator = [[OELanguageModelGenerator alloc] init];

    // Dictionary of commands want to recognize by App
    _recognizedCommands =      @{
                                 ThisWillBeSaidOnce : @[
                                         @{ OneOfTheseWillBeSaidOnce : @[@"HELLO IRIS", @"HEY IRIS"] },
                                         @{ OneOfTheseWillBeSaidOnce : @[@"TURN ON LIGHTS", @"TURN OFF LIGHTS"] },
                                         @{ OneOfTheseWillBeSaidOnce : @[@"FLOOR ONE", @"FLOOR TWO", @"FLOOR THREE"] },
                                         @{ ThisCanBeSaidOnce : @[@"THANK YOU"]}
                                         ]
                                 };
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        
        if (granted == true) {
            NSError *error = [_languageModelGenerator generateGrammarFromDictionary:_recognizedCommands
                                                                     withFilesNamed:kFileName
                                                             forAcousticModelAtPath:[OEAcousticModel
                                                                                     pathToModel:kAcousticModel]];
            
            if (error == nil) {
                _languageModelPath  = [_languageModelGenerator pathToSuccessfullyGeneratedGrammarWithRequestedName:kFileName];
                _dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:kFileName];
                
                [[OEPocketsphinxController sharedInstance] setActive:YES error:nil];
                [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:_languageModelPath
                                                                                dictionaryAtPath:_dictionaryPath
                                                                             acousticModelAtPath:[OEAcousticModel
                                                                                                  pathToModel:kAcousticModel]
                                                                             languageModelIsJSGF:YES];
                [_micControlButton setHidden:NO];
                [_recognizedText setHidden:NO];
            } else {
                NSLog(@"Error: %@", [error localizedDescription]);
                [_micControlButton setHidden:YES];
                [_recognizedText setHidden:NO];
                [_recognizedText setText:[NSString stringWithFormat:@"There was an error, here is the description: %@", [error localizedDescription]]];
            }
        } else {
            [_micControlButton setHidden:YES];
            [_recognizedText setHidden:YES];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"IMPORTANT!" message:@"Please open the microphone permisson in the settings." delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil, nil];
            [alertView show];
        }
        
    }];
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

- (void)pocketsphinxDidReceiveNBestHypothesisArray:(NSArray *)hypothesisArray {
    NSLog(@"The received hypothesis array is: %@", hypothesisArray);
}

- (void)pocketsphinxDidStartListening {
    NSLog(@"Pocketsphinx is now listening.");
}

- (void)pocketsphinxDidDetectSpeech {
    NSLog(@"Pocketsphinx has detected speech.");
}

- (void)pocketsphinxDidDetectFinishedSpeech {
    NSLog(@"Pocketsphinx has detected a period of silence, concluding an utterance.");
}

- (void)pocketsphinxDidStopListening {
    NSLog(@"Pocketsphinx has stopped listening.");
}

- (void)pocketsphinxDidSuspendRecognition {
    NSLog(@"Pocketsphinx has suspended recognition.");
}

- (void)pocketsphinxDidResumeRecognition {
    NSLog(@"Pocketsphinx has resumed recognition.");
}

- (void)pocketSphinxContinuousSetupDidFailWithReason:(NSString *)reasonForFailure {
    NSLog(@"Listening setup wasn't successful and returned the failure reason: %@", reasonForFailure);
}

- (void)pocketSphinxContinuousTeardownDidFailWithReason:(NSString *)reasonForFailure {
    NSLog(@"Listening teardown wasn't successful and returned the failure reason: %@", reasonForFailure);
}

- (void)micPermissionCheckCompleted:(BOOL)result {
    if (result == true) {
    
    } else {
    }
}

@end