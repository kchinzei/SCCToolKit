/*=========================================================================
 
 Program:   Small Computings for Clinicals Project
 Module:    $HeadURL: $
 Date:      $Date: $
 Version:   $Revision: $
 URL:       http://scc.pj.aist.go.jp
 
 (c) 2013- Kiyoyuki Chinzei, Ph.D., AIST Japan, All rights reserved.
 
 Acknowledgement: This work is/was supported by many research fundings.
 See Acknowledgement.txt
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.  See License.txt for license terms.
 
 =========================================================================*/

#ifndef __CustomDeckLinkVideoFrame__
#define __CustomDeckLinkVideoFrame__

#include "DeckLinkAPI.h"
#include <dispatch/dispatch.h>


class CustomDeckLinkVideoFrame : public IDeckLinkVideoFrame
{
public:
    CustomDeckLinkVideoFrame();
    ~CustomDeckLinkVideoFrame();

    ULONG STDMETHODCALLTYPE AddRef(void);
	ULONG STDMETHODCALLTYPE  Release(void);
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, LPVOID *ppv) { return E_NOINTERFACE; }

    long GetWidth (void) {return width;};
    long GetHeight (void) {return height;};
    long GetRowBytes (void) {return rowBytes;};
    BMDPixelFormat GetPixelFormat (void) {return pixelFormat;};
    BMDFrameFlags GetFlags (void) {return flags;};
    HRESULT GetBytes (/* out */ void **buffer);
    HRESULT GetTimecode (BMDTimecodeFormat format, IDeckLinkTimecode **timecode) {return E_FAIL;};
    HRESULT GetAncillaryData (IDeckLinkVideoFrameAncillary **ancillary) {return S_FALSE;};
    
    HRESULT AllocateVideoFrame (/* in */ int32_t width, /* in */ int32_t height,  /* in */ BMDPixelFormat pixelFormat, /* in */ BMDFrameFlags flags);

private:
    long width;
    long height;
    long rowBytes;
    BMDPixelFormat pixelFormat;
    BMDFrameFlags  flags;
    void *buffer;
    
    dispatch_semaphore_t mSemaphore;
	ULONG m_refCount;
};

#endif /* defined(e__CustomDeckLinkVideoFrame__) */
