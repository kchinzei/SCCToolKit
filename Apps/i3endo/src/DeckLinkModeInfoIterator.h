//
//  DeckLinkModeInfoIterator.h
//  cvstereoqt
//
//  Created by 鎮西 清行 on 13/03/23.
//
//

#ifndef __cvstereoqt__DeckLinkModeInfoIterator__
#define __cvstereoqt__DeckLinkModeInfoIterator__

#include <iostream>
#include "DeckLinkAPI.h"

class DeckLinkModeInfoIterator {
public:
    static DeckLinkModeInfoIterator* sharedInstance()
    {
    	static DeckLinkModeInfoIterator instance;
    	return &instance;
    }
    void initAsInput();
    void initAsOutput();
    void initWithGivenInputDevice(IDeckLinkInput *inputDevice);
    void initWithGivenOutputDevice(IDeckLinkOutput *outputDevice);
    int nextDisplayMode(char *modeName, size_t buflen, BMDDisplayMode *mode, long *width, long *height, double *fps);
    int findDisplayModeByMode(char *modeName, size_t buflen, const BMDDisplayMode mode, long *width, long *height, double *fps);
    int getModelName(char *buf, size_t buflen);
    static const char *getPixelFormatName(BMDPixelFormat fmt)
    {
        switch (fmt) {
            case bmdFormat8BitYUV:  return "8bit YUV"; break;
            case bmdFormat8BitBGRA: return "8bit BGRA"; break;
            case bmdFormat8BitARGB: return "8bit ARGB"; break;
            case bmdFormat10BitYUV: return "10bit YUV"; break;
            case bmdFormat10BitRGB: return "10bit RGB"; break;
        }
        return NULL;
    }
    
private:
    // These are hidden from others.
    DeckLinkModeInfoIterator();
    ~DeckLinkModeInfoIterator();
    DeckLinkModeInfoIterator(const DeckLinkModeInfoIterator& rhs) {};
    DeckLinkModeInfoIterator& operator=(const DeckLinkModeInfoIterator& rhs) {DeckLinkModeInfoIterator *r = sharedInstance(); return *r;};

    IDeckLinkIterator *deckLinkIterator;
    IDeckLink *deckLink;
    IDeckLinkInput *deckLinkInput;
    IDeckLinkOutput *deckLinkOutput;
    IDeckLinkDisplayModeIterator *displayModeIterator;
    
    void cleanup();
    void initialize(bool isInput);
};

#endif /* defined(__cvstereoqt__DeckLinkModeInfoIterator__) */
