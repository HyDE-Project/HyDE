// Generated with hyprwayland-scanner 0.4.2. Made with vaxry's keyboard and ❤️.
// virtual_keyboard_unstable_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2008-2011  Kristian Høgsberg
    Copyright © 2010-2013  Intel Corporation
    Copyright © 2012-2013  Collabora, Ltd.
    Copyright © 2018       Purism SPC

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

enum zwpVirtualKeyboardV1Error : uint32_t {
    ZWP_VIRTUAL_KEYBOARD_V1_ERROR_NO_KEYMAP = 0,
};

enum zwpVirtualKeyboardManagerV1Error : uint32_t {
    ZWP_VIRTUAL_KEYBOARD_MANAGER_V1_ERROR_UNAUTHORIZED = 0,
};


class CZwpVirtualKeyboardV1;
class CZwpVirtualKeyboardManagerV1;
class CWlSeat;
class CZwpVirtualKeyboardV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwp_virtual_keyboard_v1_interface;
extern const wl_interface zwp_virtual_keyboard_manager_v1_interface;

#endif

struct CZwpVirtualKeyboardV1DestroyWrapper {
    wl_listener listener;
    CZwpVirtualKeyboardV1* parent = nullptr;
};
            

class CZwpVirtualKeyboardV1 {
  public:
    CZwpVirtualKeyboardV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpVirtualKeyboardV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpVirtualKeyboardV1*)> handler) {
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

    void setKeymap(F<void(CZwpVirtualKeyboardV1*, uint32_t, int32_t, uint32_t)> handler);
    void setKey(F<void(CZwpVirtualKeyboardV1*, uint32_t, uint32_t, uint32_t)> handler);
    void setModifiers(F<void(CZwpVirtualKeyboardV1*, uint32_t, uint32_t, uint32_t, uint32_t)> handler);
    void setDestroy(F<void(CZwpVirtualKeyboardV1*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwpVirtualKeyboardV1*, uint32_t, int32_t, uint32_t)> keymap;
        F<void(CZwpVirtualKeyboardV1*, uint32_t, uint32_t, uint32_t)> key;
        F<void(CZwpVirtualKeyboardV1*, uint32_t, uint32_t, uint32_t, uint32_t)> modifiers;
        F<void(CZwpVirtualKeyboardV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpVirtualKeyboardV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpVirtualKeyboardV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpVirtualKeyboardManagerV1DestroyWrapper {
    wl_listener listener;
    CZwpVirtualKeyboardManagerV1* parent = nullptr;
};
            

class CZwpVirtualKeyboardManagerV1 {
  public:
    CZwpVirtualKeyboardManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpVirtualKeyboardManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpVirtualKeyboardManagerV1*)> handler) {
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

    void setCreateVirtualKeyboard(F<void(CZwpVirtualKeyboardManagerV1*, wl_resource*, uint32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwpVirtualKeyboardManagerV1*, wl_resource*, uint32_t)> createVirtualKeyboard;
    } requests;

    void onDestroyCalled();

    F<void(CZwpVirtualKeyboardManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpVirtualKeyboardManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
