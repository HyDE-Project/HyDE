// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// xdg_decoration_unstable_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2018 Simon Ser

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

enum zxdgToplevelDecorationV1Error : uint32_t {
    ZXDG_TOPLEVEL_DECORATION_V1_ERROR_UNCONFIGURED_BUFFER = 0,
    ZXDG_TOPLEVEL_DECORATION_V1_ERROR_ALREADY_CONSTRUCTED = 1,
    ZXDG_TOPLEVEL_DECORATION_V1_ERROR_ORPHANED = 2,
    ZXDG_TOPLEVEL_DECORATION_V1_ERROR_INVALID_MODE = 3,
};

enum zxdgToplevelDecorationV1Mode : uint32_t {
    ZXDG_TOPLEVEL_DECORATION_V1_MODE_CLIENT_SIDE = 1,
    ZXDG_TOPLEVEL_DECORATION_V1_MODE_SERVER_SIDE = 2,
};


class CZxdgDecorationManagerV1;
class CZxdgToplevelDecorationV1;
class CXdgToplevel;
class CZxdgToplevelDecorationV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zxdg_decoration_manager_v1_interface;
extern const wl_interface zxdg_toplevel_decoration_v1_interface;

#endif

struct CZxdgDecorationManagerV1DestroyWrapper {
    wl_listener listener;
    CZxdgDecorationManagerV1* parent = nullptr;
};
            

class CZxdgDecorationManagerV1 {
  public:
    CZxdgDecorationManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZxdgDecorationManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZxdgDecorationManagerV1*)> handler) {
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

    void setDestroy(F<void(CZxdgDecorationManagerV1*)> handler);
    void setGetToplevelDecoration(F<void(CZxdgDecorationManagerV1*, uint32_t, wl_resource*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZxdgDecorationManagerV1*)> destroy;
        F<void(CZxdgDecorationManagerV1*, uint32_t, wl_resource*)> getToplevelDecoration;
    } requests;

    void onDestroyCalled();

    F<void(CZxdgDecorationManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZxdgDecorationManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZxdgToplevelDecorationV1DestroyWrapper {
    wl_listener listener;
    CZxdgToplevelDecorationV1* parent = nullptr;
};
            

class CZxdgToplevelDecorationV1 {
  public:
    CZxdgToplevelDecorationV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZxdgToplevelDecorationV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZxdgToplevelDecorationV1*)> handler) {
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

    void setDestroy(F<void(CZxdgToplevelDecorationV1*)> handler);
    void setSetMode(F<void(CZxdgToplevelDecorationV1*, zxdgToplevelDecorationV1Mode)> handler);
    void setUnsetMode(F<void(CZxdgToplevelDecorationV1*)> handler);

    // --------------- Events --------------- //

    void sendConfigure(zxdgToplevelDecorationV1Mode);
    void sendConfigureRaw(zxdgToplevelDecorationV1Mode);

  private:
    struct {
        F<void(CZxdgToplevelDecorationV1*)> destroy;
        F<void(CZxdgToplevelDecorationV1*, zxdgToplevelDecorationV1Mode)> setMode;
        F<void(CZxdgToplevelDecorationV1*)> unsetMode;
    } requests;

    void onDestroyCalled();

    F<void(CZxdgToplevelDecorationV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZxdgToplevelDecorationV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
