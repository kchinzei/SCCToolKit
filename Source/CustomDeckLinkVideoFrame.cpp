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

#include "CustomDeckLinkVideoFrame.h"

CustomDeckLinkVideoFrame::CustomDeckLinkVideoFrame()
    : width(0)
    , height(0)
    , rowBytes(0)
    , buffer(0)
    , m_refCount(0)
{
    mSemaphore = dispatch_semaphore_create(1);
}

CustomDeckLinkVideoFrame::~CustomDeckLinkVideoFrame()
{
    if (this->buffer) free(this->buffer);
    dispatch_release(mSemaphore);
}

ULONG CustomDeckLinkVideoFrame::AddRef(void)
{
    dispatch_semaphore_wait(mSemaphore, DISPATCH_TIME_FOREVER);
	m_refCount++;
	dispatch_semaphore_signal(mSemaphore);
    
	return (ULONG)m_refCount;
}

ULONG CustomDeckLinkVideoFrame::Release(void)
{
    dispatch_semaphore_wait(mSemaphore, DISPATCH_TIME_FOREVER);
	m_refCount--;
	dispatch_semaphore_signal(mSemaphore);
    
	if (m_refCount == 0) {
		delete this;
		return 0;
	}
	return (ULONG)m_refCount;
}


HRESULT CustomDeckLinkVideoFrame::GetBytes (/* out */ void **buffer)
{
    *buffer = this->buffer;
    return S_OK;
}

HRESULT CustomDeckLinkVideoFrame::AllocateVideoFrame (int32_t w, int32_t h, BMDPixelFormat p, BMDFrameFlags f)
{
    this->width = w;
    this->height = h;
    this->pixelFormat = p;
    this->flags = f;
    
    switch(p) {
        case bmdFormat8BitYUV:
            this->rowBytes = w * 16 / 8;
            break;
        case bmdFormat10BitYUV:
            this->rowBytes = (w + 47) / 48 * 128;
            break;
        case bmdFormat8BitARGB:
        case bmdFormat8BitBGRA:
            this->rowBytes = w * 32 / 8;
            break;
        case bmdFormat10BitRGB:
            this->rowBytes = (w + 63) / 64 * 256;
            break;
    }
    if (this->buffer) free(this->buffer);
    this->buffer = nullptr;
    this->buffer = calloc(this->rowBytes, this->height);
    if (this->buffer)
        return S_OK;
    else
        return E_FAIL;
}

