// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// wlr_virtual_pointer_unstable_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2019 Josef Gajdusek

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

enum zwlrVirtualPointerV1Error : uint32_t {
    ZWLR_VIRTUAL_POINTER_V1_ERROR_INVALID_AXIS = 0,
    ZWLR_VIRTUAL_POINTER_V1_ERROR_INVALID_AXIS_SOURCE = 1,
};


class CZwlrVirtualPointerV1;
class CZwlrVirtualPointerManagerV1;
class CWlSeat;
class CZwlrVirtualPointerV1;
class CWlSeat;
class CWlOutput;
class CZwlrVirtualPointerV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwlr_virtual_pointer_v1_interface;
extern const wl_interface zwlr_virtual_pointer_manager_v1_interface;

#endif

struct CZwlrVirtualPointerV1DestroyWrapper {
    wl_listener listener;
    CZwlrVirtualPointerV1* parent = nullptr;
};
            

class CZwlrVirtualPointerV1 {
  public:
    CZwlrVirtualPointerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrVirtualPointerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrVirtualPointerV1*)> handler) {
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

    void setMotion(F<void(CZwlrVirtualPointerV1*, uint32_t, wl_fixed_t, wl_fixed_t)> handler);
    void setMotionAbsolute(F<void(CZwlrVirtualPointerV1*, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t)> handler);
    void setButton(F<void(CZwlrVirtualPointerV1*, uint32_t, uint32_t, uint32_t)> handler);
    void setAxis(F<void(CZwlrVirtualPointerV1*, uint32_t, uint32_t, wl_fixed_t)> handler);
    void setFrame(F<void(CZwlrVirtualPointerV1*)> handler);
    void setAxisSource(F<void(CZwlrVirtualPointerV1*, uint32_t)> handler);
    void setAxisStop(F<void(CZwlrVirtualPointerV1*, uint32_t, uint32_t)> handler);
    void setAxisDiscrete(F<void(CZwlrVirtualPointerV1*, uint32_t, uint32_t, wl_fixed_t, int32_t)> handler);
    void setDestroy(F<void(CZwlrVirtualPointerV1*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwlrVirtualPointerV1*, uint32_t, wl_fixed_t, wl_fixed_t)> motion;
        F<void(CZwlrVirtualPointerV1*, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t)> motionAbsolute;
        F<void(CZwlrVirtualPointerV1*, uint32_t, uint32_t, uint32_t)> button;
        F<void(CZwlrVirtualPointerV1*, uint32_t, uint32_t, wl_fixed_t)> axis;
        F<void(CZwlrVirtualPointerV1*)> frame;
        F<void(CZwlrVirtualPointerV1*, uint32_t)> axisSource;
        F<void(CZwlrVirtualPointerV1*, uint32_t, uint32_t)> axisStop;
        F<void(CZwlrVirtualPointerV1*, uint32_t, uint32_t, wl_fixed_t, int32_t)> axisDiscrete;
        F<void(CZwlrVirtualPointerV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrVirtualPointerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrVirtualPointerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwlrVirtualPointerManagerV1DestroyWrapper {
    wl_listener listener;
    CZwlrVirtualPointerManagerV1* parent = nullptr;
};
            

class CZwlrVirtualPointerManagerV1 {
  public:
    CZwlrVirtualPointerManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrVirtualPointerManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrVirtualPointerManagerV1*)> handler) {
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

    void setCreateVirtualPointer(F<void(CZwlrVirtualPointerManagerV1*, wl_resource*, uint32_t)> handler);
    void setDestroy(F<void(CZwlrVirtualPointerManagerV1*)> handler);
    void setCreateVirtualPointerWithOutput(F<void(CZwlrVirtualPointerManagerV1*, wl_resource*, wl_resource*, uint32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwlrVirtualPointerManagerV1*, wl_resource*, uint32_t)> createVirtualPointer;
        F<void(CZwlrVirtualPointerManagerV1*)> destroy;
        F<void(CZwlrVirtualPointerManagerV1*, wl_resource*, wl_resource*, uint32_t)> createVirtualPointerWithOutput;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrVirtualPointerManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrVirtualPointerManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
