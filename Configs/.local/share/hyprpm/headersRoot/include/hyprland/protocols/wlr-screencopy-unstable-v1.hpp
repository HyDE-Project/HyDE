// Generated with hyprwayland-scanner 0.4.2. Made with vaxry's keyboard and ❤️.
// wlr_screencopy_unstable_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2018 Simon Ser
    Copyright © 2019 Andri Yngvason

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice (including the next
    paragraph) shall be included in all copies or substantial portions of the
    Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
  
*/

#pragma once

#include <functional>
#include <cstdint>
#include <string>
#include <wayland-server.h>

#define F std::function

struct wl_client;
struct wl_resource;

enum zwlrScreencopyFrameV1Error : uint32_t {
    ZWLR_SCREENCOPY_FRAME_V1_ERROR_ALREADY_USED = 0,
    ZWLR_SCREENCOPY_FRAME_V1_ERROR_INVALID_BUFFER = 1,
};

enum zwlrScreencopyFrameV1Flags : uint32_t {
    ZWLR_SCREENCOPY_FRAME_V1_FLAGS_Y_INVERT = 1,
};


class CZwlrScreencopyManagerV1;
class CZwlrScreencopyFrameV1;
class CWlOutput;
class CZwlrScreencopyFrameV1;
class CWlOutput;
class CZwlrScreencopyFrameV1;
class CWlBuffer;
class CWlBuffer;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwlr_screencopy_manager_v1_interface;
extern const wl_interface zwlr_screencopy_frame_v1_interface;

#endif

struct CZwlrScreencopyManagerV1DestroyWrapper {
    wl_listener listener;
    CZwlrScreencopyManagerV1* parent = nullptr;
};
            

class CZwlrScreencopyManagerV1 {
  public:
    CZwlrScreencopyManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrScreencopyManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrScreencopyManagerV1*)> handler) {
        onDestroy = handler;
    }

    // set the data for this resource
    void setData(void* data) {
        pData = data;
    }

    // get the data for this resource
    void* data() {
        return pData;
    }

    // get the raw wl_resource ptr
    wl_resource* resource() {
        return pResource;
    }

    // get the client
    wl_client* client() {
        return wl_resource_get_client(pResource);
    }

    // send an error
    void error(uint32_t error, const std::string& message) {
        wl_resource_post_error(pResource, error, "%s", message.c_str());
    }

    // send out of memory
    void noMemory() {
        wl_resource_post_no_memory(pResource);
    }

    // get the resource version
    int version() {
        return wl_resource_get_version(pResource);
    }
            
    // --------------- Requests --------------- //

    void setCaptureOutput(F<void(CZwlrScreencopyManagerV1*, uint32_t, int32_t, wl_resource*)> handler);
    void setCaptureOutputRegion(F<void(CZwlrScreencopyManagerV1*, uint32_t, int32_t, wl_resource*, int32_t, int32_t, int32_t, int32_t)> handler);
    void setDestroy(F<void(CZwlrScreencopyManagerV1*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwlrScreencopyManagerV1*, uint32_t, int32_t, wl_resource*)> captureOutput;
        F<void(CZwlrScreencopyManagerV1*, uint32_t, int32_t, wl_resource*, int32_t, int32_t, int32_t, int32_t)> captureOutputRegion;
        F<void(CZwlrScreencopyManagerV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrScreencopyManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrScreencopyManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwlrScreencopyFrameV1DestroyWrapper {
    wl_listener listener;
    CZwlrScreencopyFrameV1* parent = nullptr;
};
            

class CZwlrScreencopyFrameV1 {
  public:
    CZwlrScreencopyFrameV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrScreencopyFrameV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrScreencopyFrameV1*)> handler) {
        onDestroy = handler;
    }

    // set the data for this resource
    void setData(void* data) {
        pData = data;
    }

    // get the data for this resource
    void* data() {
        return pData;
    }

    // get the raw wl_resource ptr
    wl_resource* resource() {
        return pResource;
    }

    // get the client
    wl_client* client() {
        return wl_resource_get_client(pResource);
    }

    // send an error
    void error(uint32_t error, const std::string& message) {
        wl_resource_post_error(pResource, error, "%s", message.c_str());
    }

    // send out of memory
    void noMemory() {
        wl_resource_post_no_memory(pResource);
    }

    // get the resource version
    int version() {
        return wl_resource_get_version(pResource);
    }
            
    // --------------- Requests --------------- //

    void setCopy(F<void(CZwlrScreencopyFrameV1*, wl_resource*)> handler);
    void setDestroy(F<void(CZwlrScreencopyFrameV1*)> handler);
    void setCopyWithDamage(F<void(CZwlrScreencopyFrameV1*, wl_resource*)> handler);

    // --------------- Events --------------- //

    void sendBuffer(uint32_t, uint32_t, uint32_t, uint32_t);
    void sendFlags(zwlrScreencopyFrameV1Flags);
    void sendReady(uint32_t, uint32_t, uint32_t);
    void sendFailed();
    void sendDamage(uint32_t, uint32_t, uint32_t, uint32_t);
    void sendLinuxDmabuf(uint32_t, uint32_t, uint32_t);
    void sendBufferDone();
    void sendBufferRaw(uint32_t, uint32_t, uint32_t, uint32_t);
    void sendFlagsRaw(zwlrScreencopyFrameV1Flags);
    void sendReadyRaw(uint32_t, uint32_t, uint32_t);
    void sendFailedRaw();
    void sendDamageRaw(uint32_t, uint32_t, uint32_t, uint32_t);
    void sendLinuxDmabufRaw(uint32_t, uint32_t, uint32_t);
    void sendBufferDoneRaw();

  private:
    struct {
        F<void(CZwlrScreencopyFrameV1*, wl_resource*)> copy;
        F<void(CZwlrScreencopyFrameV1*)> destroy;
        F<void(CZwlrScreencopyFrameV1*, wl_resource*)> copyWithDamage;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrScreencopyFrameV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrScreencopyFrameV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
