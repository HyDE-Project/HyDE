// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// viewporter

/*
 This protocol's authors' copyright notice is:


    Copyright © 2013-2016 Collabora, Ltd.

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

enum wpViewporterError : uint32_t {
    WP_VIEWPORTER_ERROR_VIEWPORT_EXISTS = 0,
};

enum wpViewportError : uint32_t {
    WP_VIEWPORT_ERROR_BAD_VALUE = 0,
    WP_VIEWPORT_ERROR_BAD_SIZE = 1,
    WP_VIEWPORT_ERROR_OUT_OF_BUFFER = 2,
    WP_VIEWPORT_ERROR_NO_SURFACE = 3,
};


class CWpViewporter;
class CWpViewport;
class CWlSurface;
class CWpViewport;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface wp_viewporter_interface;
extern const wl_interface wp_viewport_interface;

#endif

struct CWpViewporterDestroyWrapper {
    wl_listener listener;
    CWpViewporter* parent = nullptr;
};
            

class CWpViewporter {
  public:
    CWpViewporter(wl_client* client, uint32_t version, uint32_t id);
    ~CWpViewporter();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpViewporter*)> handler) {
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

    void setDestroy(F<void(CWpViewporter*)> handler);
    void setGetViewport(F<void(CWpViewporter*, uint32_t, wl_resource*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWpViewporter*)> destroy;
        F<void(CWpViewporter*, uint32_t, wl_resource*)> getViewport;
    } requests;

    void onDestroyCalled();

    F<void(CWpViewporter*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpViewporterDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWpViewportDestroyWrapper {
    wl_listener listener;
    CWpViewport* parent = nullptr;
};
            

class CWpViewport {
  public:
    CWpViewport(wl_client* client, uint32_t version, uint32_t id);
    ~CWpViewport();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpViewport*)> handler) {
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

    void setDestroy(F<void(CWpViewport*)> handler);
    void setSetSource(F<void(CWpViewport*, wl_fixed_t, wl_fixed_t, wl_fixed_t, wl_fixed_t)> handler);
    void setSetDestination(F<void(CWpViewport*, int32_t, int32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWpViewport*)> destroy;
        F<void(CWpViewport*, wl_fixed_t, wl_fixed_t, wl_fixed_t, wl_fixed_t)> setSource;
        F<void(CWpViewport*, int32_t, int32_t)> setDestination;
    } requests;

    void onDestroyCalled();

    F<void(CWpViewport*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpViewportDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
