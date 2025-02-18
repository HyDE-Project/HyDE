// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// relative_pointer_unstable_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2014      Jonas Ådahl
    Copyright © 2015      Red Hat Inc.

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


class CZwpRelativePointerManagerV1;
class CZwpRelativePointerV1;
class CWlPointer;
class CZwpRelativePointerV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwp_relative_pointer_manager_v1_interface;
extern const wl_interface zwp_relative_pointer_v1_interface;

#endif

struct CZwpRelativePointerManagerV1DestroyWrapper {
    wl_listener listener;
    CZwpRelativePointerManagerV1* parent = nullptr;
};
            

class CZwpRelativePointerManagerV1 {
  public:
    CZwpRelativePointerManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpRelativePointerManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpRelativePointerManagerV1*)> handler) {
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

    void setDestroy(F<void(CZwpRelativePointerManagerV1*)> handler);
    void setGetRelativePointer(F<void(CZwpRelativePointerManagerV1*, uint32_t, wl_resource*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwpRelativePointerManagerV1*)> destroy;
        F<void(CZwpRelativePointerManagerV1*, uint32_t, wl_resource*)> getRelativePointer;
    } requests;

    void onDestroyCalled();

    F<void(CZwpRelativePointerManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpRelativePointerManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpRelativePointerV1DestroyWrapper {
    wl_listener listener;
    CZwpRelativePointerV1* parent = nullptr;
};
            

class CZwpRelativePointerV1 {
  public:
    CZwpRelativePointerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpRelativePointerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpRelativePointerV1*)> handler) {
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

    void setDestroy(F<void(CZwpRelativePointerV1*)> handler);

    // --------------- Events --------------- //

    void sendRelativeMotion(uint32_t, uint32_t, wl_fixed_t, wl_fixed_t, wl_fixed_t, wl_fixed_t);
    void sendRelativeMotionRaw(uint32_t, uint32_t, wl_fixed_t, wl_fixed_t, wl_fixed_t, wl_fixed_t);

  private:
    struct {
        F<void(CZwpRelativePointerV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpRelativePointerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpRelativePointerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
