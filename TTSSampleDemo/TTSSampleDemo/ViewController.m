//
//  ViewController.m
//  TTSSampleDemo
//
//  Created by Bilal Arslan on 11/08/15.
//  Copyright (c) 2015 Bilal Arslan. All rights reserved.
//

#import "ViewController.h"
#import "PureLayout.h"
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
@property (nonatomic, strong) OEFliteController *fliteController;
@property (nonatomic, strong) Slt *slt;
@property (nonatomic, strong) OEEventsObserver *openEarsEventsObserver;

@property (nonatomic, strong) NSDictionary *recognizedCommands;
@property (nonatomic, strong) NSString *languageModelPath;
@property (nonatomic, strong) NSString *dictionaryPath;

@property (nonatomic, strong) UIButton *micControlButton;
@property (nonatomic, strong) UILabel *recognizedText;
@property (nonatomic, strong) UILabel *recognizableText;

@end

#pragma mark - Class Implementation

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    
    _micControlButton = [[UIButton alloc] initForAutoLayout];
    [_micControlButton setTitle:@"Listen" forState:UIControlStateNormal];
    [_micControlButton setBackgroundColor:[UIColor redColor]];
    [[_micControlButton layer] setCornerRadius:7.5];
    [_micControlButton addTarget:self action:@selector(didTapMicButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_micControlButton];
    
    [_micControlButton autoSetDimension:ALDimensionHeight toSize:50];
    [_micControlButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(30, 50, 50, 50) excludingEdge:ALEdgeBottom];
    
    
    _recognizedText = [[UILabel alloc] initForAutoLayout];
    [_recognizedText setNumberOfLines:0];
    [_recognizedText setText:@"Your Speech will come here when the IRIS understand the correct commands.."];
    [_recognizedText setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:_recognizedText];
    
    CGFloat minumunHeight = 25.0;
    [_recognizedText autoSetDimension:ALDimensionHeight toSize:minumunHeight relation:NSLayoutRelationGreaterThanOrEqual];
    [_recognizedText autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:30.0];
    [_recognizedText autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:30.0];
    [_recognizedText autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_micControlButton withOffset:30.0];
    
    
    _recognizableText = [[UILabel alloc] initForAutoLayout];
    [_recognizableText setNumberOfLines:0];
    [_recognizableText setText:@" 0) COMMANDS: \n 1) HELLO/HEY IRIS \n 2) TURN ON/OFF LIGHTS \n 3) FLOOR ONE/TWO/THREE \n 4) (THANK YOU)"];
    [_recognizableText setTextAlignment:NSTextAlignmentLeft];
    [self.view addSubview:_recognizableText];
    
    [_recognizableText autoSetDimension:ALDimensionHeight toSize:minumunHeight relation:NSLayoutRelationGreaterThanOrEqual];
    [_recognizableText autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:30.0];
    [_recognizableText autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:30.0];
    [_recognizableText autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_recognizedText withOffset:30.0];
    
    //[_scrollView setContentSize:_scrollContentView.frame.size];
    
    
    // OEEventsObserver is the class which keeps you continuously updated about the status of your listening session, among other things, via delegate callbacks
    _openEarsEventsObserver = [[OEEventsObserver alloc] init];
    [_openEarsEventsObserver setDelegate:self];
    
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
                
                [_micControlButton setTitle:@"Listening.." forState:UIControlStateNormal];
                [_micControlButton setBackgroundColor:[UIColor greenColor]];
                [_micControlButton setUserInteractionEnabled:YES];
            } else {
                NSLog(@"Error: %@", [error localizedDescription]);
                [_micControlButton setUserInteractionEnabled:NO];
                [_recognizedText setText:[NSString stringWithFormat:@"There was an error, here is the description: %@", [error localizedDescription]]];
            }
        } else {
            [_micControlButton setUserInteractionEnabled:NO];
            
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