//
//  DeckLinkModeInfoIterator.cpp
//  cvstereoqt
//
//  Created by 鎮西 清行 on 13/03/23.
//
//

#include "DeckLinkModeInfoIterator.h"
#include <dispatch/dispatch.h>

DeckLinkModeInfoIterator::DeckLinkModeInfoIterator()
    : displayModeIterator(NULL)
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        deckLinkIterator = NULL;
        deckLink = NULL;
        deckLinkInput = NULL;
        deckLinkOutput = NULL;
    });
}

DeckLinkModeInfoIterator::~DeckLinkModeInfoIterator()
{
    cleanup();
}

void DeckLinkModeInfoIterator::initialize(bool isInput)
{
    cleanup();
    
    deckLinkIterator = CreateDeckLinkIteratorInstance();
    if (deckLinkIterator == NULL)
        goto bail;
    
    if (deckLinkIterator->Next(&deckLink) != S_OK)
        goto bail;

    if (isInput) {
        if (deckLink->QueryInterface(IID_IDeckLinkInput, (void**)&deckLinkInput) != S_OK)
            goto bail;
        
        if (deckLinkInput->GetDisplayModeIterator(&displayModeIterator) != S_OK)
            goto bail;
    } else {
        if (deckLink->QueryInterface(IID_IDeckLinkOutput, (void**)&deckLinkOutput) != S_OK)
            goto bail;
        
        if (deckLinkOutput->GetDisplayModeIterator(&displayModeIterator) != S_OK)
            goto bail;
    }
    return;

bail:
    cleanup();
}

void DeckLinkModeInfoIterator::cleanup()
{
    if (displayModeIterator) displayModeIterator->Release();
    if (deckLinkOutput)   deckLinkOutput->Release();
    if (deckLinkInput)    deckLinkInput->Release();
    if (deckLink)         deckLink->Release();
    if (deckLinkIterator) deckLinkIterator->Release();
    displayModeIterator = NULL;
    deckLinkInput = NULL;
    deckLink = NULL;
    deckLinkIterator = NULL;
}


void DeckLinkModeInfoIterator::initAsInput()
{
    initialize(true);
}

void DeckLinkModeInfoIterator::initAsOutput()
{
    initialize(false);
}

void DeckLinkModeInfoIterator::initWithGivenInputDevice(IDeckLinkInput *inputDevice)
{
    cleanup();
    if (inputDevice) {
        inputDevice->GetDisplayModeIterator(&displayModeIterator);
    }
}

void DeckLinkModeInfoIterator::initWithGivenOutputDevice(IDeckLinkOutput *outputDevice)
{
    cleanup();
    if (outputDevice) {
        outputDevice->GetDisplayModeIterator(&displayModeIterator);
    }
}

int DeckLinkModeInfoIterator::getModelName(char *buf, size_t buflen)
{
    int len = 0;
    if (buf) buf[0] = '\0';

    IDeckLinkIterator *tmpIterator = deckLinkIterator;
    IDeckLink *tmpDeckLink = deckLink;
    
    if (tmpDeckLink == NULL) {
        if (tmpIterator == NULL) {
            tmpIterator = CreateDeckLinkIteratorInstance();
            if (tmpIterator == NULL)
                goto bail;
        }
        if (tmpIterator->Next(&tmpDeckLink) != S_OK)
            goto bail;
    }
    
    if (buf) {
        HRESULT result;
        
        CFStringRef cfstr;
        result = tmpDeckLink->GetModelName(&cfstr);
        if (result == S_OK) {
            if (CFStringGetCString(cfstr, buf, buflen, kCFStringEncodingUTF8))
            len = strlen(buf);
        }
        buf[len] = '\0';
    }
    
bail:
    if (tmpDeckLink != deckLink)
        tmpDeckLink->Release();
    if (tmpIterator != deckLinkIterator)
        tmpIterator->Release();
    return len;
}

int DeckLinkModeInfoIterator::nextDisplayMode(char *modeName, size_t buflen, BMDDisplayMode *mode, long *width, long *height, double *fps)
{
    if (displayModeIterator == NULL) {
        return 0;
    }
        
    IDeckLinkDisplayMode *displayMode = NULL;
    if (displayModeIterator->Next(&displayMode) == S_OK) {
        if (modeName) {
            HRESULT result;
            
            CFStringRef dstr;
            result = displayMode->GetName(&dstr);
            if (result == S_OK) {
                CFStringGetCString(dstr, modeName, buflen, kCFStringEncodingUTF8);
            }
        }
        if (mode) {
            *mode = displayMode->GetDisplayMode();
        }
        if (width) {
            *width = displayMode->GetWidth();
        }
        if (height) {
            *height = displayMode->GetHeight();
        }
        if (fps) {
            BMDTimeValue frameRateDuration, frameRateScale;
            displayMode->GetFrameRate(&frameRateDuration, &frameRateScale);
            *fps = frameRateScale / frameRateDuration;
        }
        
        displayMode->Release();
        
        return 1;
    } else {
        cleanup();
        
        return 0;
    }
}

int DeckLinkModeInfoIterator::findDisplayModeByMode(char *modeName, size_t buflen, const BMDDisplayMode mode, long *width, long *height, double *fps)
{
    char buf[buflen];
    char *s = buf;
    long w, h;
    double f;
    
    int i = 0;
    BMDDisplayMode mTmp = 0;
    while (nextDisplayMode(s, buflen, &mTmp, &w, &h, &f)) {
        if (mTmp == mode) {
            if (modeName) strlcpy(modeName, buf, buflen);
            if (width) *width = w;
            if (height) *height = h;
            if (fps) *fps = f;
            return i;
        }
        i++;
    }
    return -1;
}
