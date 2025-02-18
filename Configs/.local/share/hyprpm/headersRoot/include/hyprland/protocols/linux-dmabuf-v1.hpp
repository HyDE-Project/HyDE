// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// linux_dmabuf_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2014, 2015 Collabora, Ltd.

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

enum zwpLinuxBufferParamsV1Error : uint32_t {
    ZWP_LINUX_BUFFER_PARAMS_V1_ERROR_ALREADY_USED = 0,
    ZWP_LINUX_BUFFER_PARAMS_V1_ERROR_PLANE_IDX = 1,
    ZWP_LINUX_BUFFER_PARAMS_V1_ERROR_PLANE_SET = 2,
    ZWP_LINUX_BUFFER_PARAMS_V1_ERROR_INCOMPLETE = 3,
    ZWP_LINUX_BUFFER_PARAMS_V1_ERROR_INVALID_FORMAT = 4,
    ZWP_LINUX_BUFFER_PARAMS_V1_ERROR_INVALID_DIMENSIONS = 5,
    ZWP_LINUX_BUFFER_PARAMS_V1_ERROR_OUT_OF_BOUNDS = 6,
    ZWP_LINUX_BUFFER_PARAMS_V1_ERROR_INVALID_WL_BUFFER = 7,
};

enum zwpLinuxBufferParamsV1Flags : uint32_t {
    ZWP_LINUX_BUFFER_PARAMS_V1_FLAGS_Y_INVERT = 1,
    ZWP_LINUX_BUFFER_PARAMS_V1_FLAGS_INTERLACED = 2,
    ZWP_LINUX_BUFFER_PARAMS_V1_FLAGS_BOTTOM_FIRST = 4,
};

enum zwpLinuxDmabufFeedbackV1TrancheFlags : uint32_t {
    ZWP_LINUX_DMABUF_FEEDBACK_V1_TRANCHE_FLAGS_SCANOUT = 1,
};


class CZwpLinuxDmabufV1;
class CZwpLinuxBufferParamsV1;
class CZwpLinuxDmabufFeedbackV1;
class CZwpLinuxDmabufFeedbackV1;
class CWlSurface;
class CZwpLinuxBufferParamsV1;
class CWlBuffer;
class CWlBuffer;
class CZwpLinuxDmabufFeedbackV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwp_linux_dmabuf_v1_interface;
extern const wl_interface zwp_linux_buffer_params_v1_interface;
extern const wl_interface zwp_linux_dmabuf_feedback_v1_interface;

#endif

struct CZwpLinuxDmabufV1DestroyWrapper {
    wl_listener listener;
    CZwpLinuxDmabufV1* parent = nullptr;
};
            

class CZwpLinuxDmabufV1 {
  public:
    CZwpLinuxDmabufV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpLinuxDmabufV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpLinuxDmabufV1*)> handler) {
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

    void setDestroy(F<void(CZwpLinuxDmabufV1*)> handler);
    void setCreateParams(F<void(CZwpLinuxDmabufV1*, uint32_t)> handler);
    void setGetDefaultFeedback(F<void(CZwpLinuxDmabufV1*, uint32_t)> handler);
    void setGetSurfaceFeedback(F<void(CZwpLinuxDmabufV1*, uint32_t, wl_resource*)> handler);

    // --------------- Events --------------- //

    void sendFormat(uint32_t);
    void sendModifier(uint32_t, uint32_t, uint32_t);
    void sendFormatRaw(uint32_t);
    void sendModifierRaw(uint32_t, uint32_t, uint32_t);

  private:
    struct {
        F<void(CZwpLinuxDmabufV1*)> destroy;
        F<void(CZwpLinuxDmabufV1*, uint32_t)> createParams;
        F<void(CZwpLinuxDmabufV1*, uint32_t)> getDefaultFeedback;
        F<void(CZwpLinuxDmabufV1*, uint32_t, wl_resource*)> getSurfaceFeedback;
    } requests;

    void onDestroyCalled();

    F<void(CZwpLinuxDmabufV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpLinuxDmabufV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpLinuxBufferParamsV1DestroyWrapper {
    wl_listener listener;
    CZwpLinuxBufferParamsV1* parent = nullptr;
};
            

class CZwpLinuxBufferParamsV1 {
  public:
    CZwpLinuxBufferParamsV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpLinuxBufferParamsV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpLinuxBufferParamsV1*)> handler) {
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

    void setDestroy(F<void(CZwpLinuxBufferParamsV1*)> handler);
    void setAdd(F<void(CZwpLinuxBufferParamsV1*, int32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t)> handler);
    void setCreate(F<void(CZwpLinuxBufferParamsV1*, int32_t, int32_t, uint32_t, zwpLinuxBufferParamsV1Flags)> handler);
    void setCreateImmed(F<void(CZwpLinuxBufferParamsV1*, uint32_t, int32_t, int32_t, uint32_t, zwpLinuxBufferParamsV1Flags)> handler);

    // --------------- Events --------------- //

    void sendCreated(wl_resource*);
    void sendFailed();
    void sendCreatedRaw(wl_resource*);
    void sendFailedRaw();

  private:
    struct {
        F<void(CZwpLinuxBufferParamsV1*)> destroy;
        F<void(CZwpLinuxBufferParamsV1*, int32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t)> add;
        F<void(CZwpLinuxBufferParamsV1*, int32_t, int32_t, uint32_t, zwpLinuxBufferParamsV1Flags)> create;
        F<void(CZwpLinuxBufferParamsV1*, uint32_t, int32_t, int32_t, uint32_t, zwpLinuxBufferParamsV1Flags)> createImmed;
    } requests;

    void onDestroyCalled();

    F<void(CZwpLinuxBufferParamsV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpLinuxBufferParamsV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpLinuxDmabufFeedbackV1DestroyWrapper {
    wl_listener listener;
    CZwpLinuxDmabufFeedbackV1* parent = nullptr;
};
            

class CZwpLinuxDmabufFeedbackV1 {
  public:
    CZwpLinuxDmabufFeedbackV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpLinuxDmabufFeedbackV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpLinuxDmabufFeedbackV1*)> handler) {
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

    void setDestroy(F<void(CZwpLinuxDmabufFeedbackV1*)> handler);

    // --------------- Events --------------- //

    void sendDone();
    void sendFormatTable(int32_t, uint32_t);
    void sendMainDevice(wl_array*);
    void sendTrancheDone();
    void sendTrancheTargetDevice(wl_array*);
    void sendTrancheFormats(wl_array*);
    void sendTrancheFlags(zwpLinuxDmabufFeedbackV1TrancheFlags);
    void sendDoneRaw();
    void sendFormatTableRaw(int32_t, uint32_t);
    void sendMainDeviceRaw(wl_array*);
    void sendTrancheDoneRaw();
    void sendTrancheTargetDeviceRaw(wl_array*);
    void sendTrancheFormatsRaw(wl_array*);
    void sendTrancheFlagsRaw(zwpLinuxDmabufFeedbackV1TrancheFlags);

  private:
    struct {
        F<void(CZwpLinuxDmabufFeedbackV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpLinuxDmabufFeedbackV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpLinuxDmabufFeedbackV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
