// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// wlr_output_power_management_unstable_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2019 Purism SPC

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

enum zwlrOutputPowerV1Mode : uint32_t {
    ZWLR_OUTPUT_POWER_V1_MODE_OFF = 0,
    ZWLR_OUTPUT_POWER_V1_MODE_ON = 1,
};

enum zwlrOutputPowerV1Error : uint32_t {
    ZWLR_OUTPUT_POWER_V1_ERROR_INVALID_MODE = 1,
};


class CZwlrOutputPowerManagerV1;
class CZwlrOutputPowerV1;
class CWlOutput;
class CZwlrOutputPowerV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwlr_output_power_manager_v1_interface;
extern const wl_interface zwlr_output_power_v1_interface;

#endif

struct CZwlrOutputPowerManagerV1DestroyWrapper {
    wl_listener listener;
    CZwlrOutputPowerManagerV1* parent = nullptr;
};
            

class CZwlrOutputPowerManagerV1 {
  public:
    CZwlrOutputPowerManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrOutputPowerManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrOutputPowerManagerV1*)> handler) {
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

    void setGetOutputPower(F<void(CZwlrOutputPowerManagerV1*, uint32_t, wl_resource*)> handler);
    void setDestroy(F<void(CZwlrOutputPowerManagerV1*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwlrOutputPowerManagerV1*, uint32_t, wl_resource*)> getOutputPower;
        F<void(CZwlrOutputPowerManagerV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrOutputPowerManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrOutputPowerManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwlrOutputPowerV1DestroyWrapper {
    wl_listener listener;
    CZwlrOutputPowerV1* parent = nullptr;
};
            

class CZwlrOutputPowerV1 {
  public:
    CZwlrOutputPowerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrOutputPowerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrOutputPowerV1*)> handler) {
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

    void setSetMode(F<void(CZwlrOutputPowerV1*, zwlrOutputPowerV1Mode)> handler);
    void setDestroy(F<void(CZwlrOutputPowerV1*)> handler);

    // --------------- Events --------------- //

    void sendMode(zwlrOutputPowerV1Mode);
    void sendFailed();
    void sendModeRaw(zwlrOutputPowerV1Mode);
    void sendFailedRaw();

  private:
    struct {
        F<void(CZwlrOutputPowerV1*, zwlrOutputPowerV1Mode)> setMode;
        F<void(CZwlrOutputPowerV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrOutputPowerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrOutputPowerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
