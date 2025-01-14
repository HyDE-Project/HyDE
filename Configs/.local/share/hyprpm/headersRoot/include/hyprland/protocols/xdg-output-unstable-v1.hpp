// Generated with hyprwayland-scanner 0.4.2. Made with vaxry's keyboard and ❤️.
// xdg_output_unstable_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2017 Red Hat Inc.

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


class CZxdgOutputManagerV1;
class CZxdgOutputV1;
class CWlOutput;
class CZxdgOutputV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zxdg_output_manager_v1_interface;
extern const wl_interface zxdg_output_v1_interface;

#endif

struct CZxdgOutputManagerV1DestroyWrapper {
    wl_listener listener;
    CZxdgOutputManagerV1* parent = nullptr;
};
            

class CZxdgOutputManagerV1 {
  public:
    CZxdgOutputManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZxdgOutputManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZxdgOutputManagerV1*)> handler) {
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

    void setDestroy(F<void(CZxdgOutputManagerV1*)> handler);
    void setGetXdgOutput(F<void(CZxdgOutputManagerV1*, uint32_t, wl_resource*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZxdgOutputManagerV1*)> destroy;
        F<void(CZxdgOutputManagerV1*, uint32_t, wl_resource*)> getXdgOutput;
    } requests;

    void onDestroyCalled();

    F<void(CZxdgOutputManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZxdgOutputManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZxdgOutputV1DestroyWrapper {
    wl_listener listener;
    CZxdgOutputV1* parent = nullptr;
};
            

class CZxdgOutputV1 {
  public:
    CZxdgOutputV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZxdgOutputV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZxdgOutputV1*)> handler) {
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

    void setDestroy(F<void(CZxdgOutputV1*)> handler);

    // --------------- Events --------------- //

    void sendLogicalPosition(int32_t, int32_t);
    void sendLogicalSize(int32_t, int32_t);
    void sendDone();
    void sendName(const char*);
    void sendDescription(const char*);
    void sendLogicalPositionRaw(int32_t, int32_t);
    void sendLogicalSizeRaw(int32_t, int32_t);
    void sendDoneRaw();
    void sendNameRaw(const char*);
    void sendDescriptionRaw(const char*);

  private:
    struct {
        F<void(CZxdgOutputV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZxdgOutputV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZxdgOutputV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
