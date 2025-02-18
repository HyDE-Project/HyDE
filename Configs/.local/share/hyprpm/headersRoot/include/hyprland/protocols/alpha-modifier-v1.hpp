// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// alpha_modifier_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2024 Xaver Hugl

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

enum wpAlphaModifierV1Error : uint32_t {
    WP_ALPHA_MODIFIER_V1_ERROR_ALREADY_CONSTRUCTED = 0,
};

enum wpAlphaModifierSurfaceV1Error : uint32_t {
    WP_ALPHA_MODIFIER_SURFACE_V1_ERROR_NO_SURFACE = 0,
};


class CWpAlphaModifierV1;
class CWpAlphaModifierSurfaceV1;
class CWlSurface;
class CWpAlphaModifierSurfaceV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface wp_alpha_modifier_v1_interface;
extern const wl_interface wp_alpha_modifier_surface_v1_interface;

#endif

struct CWpAlphaModifierV1DestroyWrapper {
    wl_listener listener;
    CWpAlphaModifierV1* parent = nullptr;
};
            

class CWpAlphaModifierV1 {
  public:
    CWpAlphaModifierV1(wl_client* client, uint32_t version, uint32_t id);
    ~CWpAlphaModifierV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpAlphaModifierV1*)> handler) {
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

    void setDestroy(F<void(CWpAlphaModifierV1*)> handler);
    void setGetSurface(F<void(CWpAlphaModifierV1*, uint32_t, wl_resource*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWpAlphaModifierV1*)> destroy;
        F<void(CWpAlphaModifierV1*, uint32_t, wl_resource*)> getSurface;
    } requests;

    void onDestroyCalled();

    F<void(CWpAlphaModifierV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpAlphaModifierV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWpAlphaModifierSurfaceV1DestroyWrapper {
    wl_listener listener;
    CWpAlphaModifierSurfaceV1* parent = nullptr;
};
            

class CWpAlphaModifierSurfaceV1 {
  public:
    CWpAlphaModifierSurfaceV1(wl_client* client, uint32_t version, uint32_t id);
    ~CWpAlphaModifierSurfaceV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpAlphaModifierSurfaceV1*)> handler) {
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

    void setDestroy(F<void(CWpAlphaModifierSurfaceV1*)> handler);
    void setSetMultiplier(F<void(CWpAlphaModifierSurfaceV1*, uint32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWpAlphaModifierSurfaceV1*)> destroy;
        F<void(CWpAlphaModifierSurfaceV1*, uint32_t)> setMultiplier;
    } requests;

    void onDestroyCalled();

    F<void(CWpAlphaModifierSurfaceV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpAlphaModifierSurfaceV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
