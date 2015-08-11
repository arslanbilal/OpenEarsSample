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
#import <Slt/Slt.h>

#define kFileName @"language-model-files"
#define kAcousticModel @"AcousticModelEnglish"


@interface ViewController ()

@property (nonatomic, strong) OELanguageModelGenerator *languageModelGenerator;
@property (nonatomic, strong) NSArray *recognizedWords;
@property (nonatomic, strong) NSString *languageModelPath;
@property (nonatomic, strong) NSString *dictionaryPath;
@property (nonatomic, strong) OEFliteController *fliteController;
@property (nonatomic, strong) Slt *slt;
@property (nonatomic, strong) OEEventsObserver *openEarsEventsObserver;
@property (nonatomic, strong) UIButton *micControlButton;

@end


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
    [_micControlButton setBackgroundColor:[UIColor greenColor]];
    [_micControlButton setTitle:@"Listening..." forState:UIControlStateNormal];
    [_micControlButton setTintColor:[UIColor whiteColor]];
    [_micControlButton addTarget:self action:@selector(didTapMicButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_micControlButton];
    
    
    
    
    _languageModelGenerator = [[OELanguageModelGenerator alloc] init];
    _recognizedWords = @[@"OPEN DOOR"];
    
    NSError *error = [_languageModelGenerator generateLanguageModelFromArray:_recognizedWords withFilesNamed:kFileName forAcousticModelAtPath:[OEAcousticModel pathToModel:kAcousticModel]];
    
    if (error == nil) {
        _languageModelPath = [_languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:kFileName];
        _dictionaryPath = [_languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:kFileName];
        
        [[OEPocketsphinxController sharedInstance] setActive:YES error:nil];
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:_languageModelPath dictionaryAtPath:_dictionaryPath acousticModelAtPath:[OEAcousticModel pathToModel:kAcousticModel] languageModelIsJSGF:NO];
        
    } else {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    
    // calling speech
    _fliteController = [[OEFliteController alloc] init];
    _slt = [[Slt alloc] init];
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
    [_fliteController say:hypothesis withVoice:_slt];
}

//- (void)pocketsphinxDidStartListening {
//    NSLog(@"Pocketsphinx is now listening.");
//}

- (void)pocketsphinxDidDetectSpeech {
    NSLog(@"Pocketsphinx has detected speech.");
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

@end
