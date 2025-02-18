// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// wlr_layer_shell_unstable_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2017 Drew DeVault

    Permission to use, copy, modify, distribute, and sell this
    software and its documentation for any purpose is hereby granted
    without fee, provided that the above copyright notice appear in
    all copies and that both that copyright notice and this permission
    notice appear in supporting documentation, and that the name of
    the copyright holders not be used in advertising or publicity
    pertaining to distribution of the software without specific,
    written prior permission.  The copyright holders make no
    representations about the suitability of this software for any
    purpose.  It is provided "as is" without express or implied
    warranty.

    THE COPYRIGHT HOLDERS DISCLAIM ALL WARRANTIES WITH REGARD TO THIS
    SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
    FITNESS, IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
    SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
    WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
    AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
    ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
    THIS SOFTWARE.
  
*/

#pragma once

#include <functional>
#include <cstdint>
#include <string>
#include <wayland-server.h>

#define F std::function

struct wl_client;
struct wl_resource;

enum zwlrLayerShellV1Error : uint32_t {
    ZWLR_LAYER_SHELL_V1_ERROR_ROLE = 0,
    ZWLR_LAYER_SHELL_V1_ERROR_INVALID_LAYER = 1,
    ZWLR_LAYER_SHELL_V1_ERROR_ALREADY_CONSTRUCTED = 2,
};

enum zwlrLayerShellV1Layer : uint32_t {
    ZWLR_LAYER_SHELL_V1_LAYER_BACKGROUND = 0,
    ZWLR_LAYER_SHELL_V1_LAYER_BOTTOM = 1,
    ZWLR_LAYER_SHELL_V1_LAYER_TOP = 2,
    ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY = 3,
};

enum zwlrLayerSurfaceV1KeyboardInteractivity : uint32_t {
    ZWLR_LAYER_SURFACE_V1_KEYBOARD_INTERACTIVITY_NONE = 0,
    ZWLR_LAYER_SURFACE_V1_KEYBOARD_INTERACTIVITY_EXCLUSIVE = 1,
    ZWLR_LAYER_SURFACE_V1_KEYBOARD_INTERACTIVITY_ON_DEMAND = 2,
};

enum zwlrLayerSurfaceV1Error : uint32_t {
    ZWLR_LAYER_SURFACE_V1_ERROR_INVALID_SURFACE_STATE = 0,
    ZWLR_LAYER_SURFACE_V1_ERROR_INVALID_SIZE = 1,
    ZWLR_LAYER_SURFACE_V1_ERROR_INVALID_ANCHOR = 2,
    ZWLR_LAYER_SURFACE_V1_ERROR_INVALID_KEYBOARD_INTERACTIVITY = 3,
    ZWLR_LAYER_SURFACE_V1_ERROR_INVALID_EXCLUSIVE_EDGE = 4,
};

enum zwlrLayerSurfaceV1Anchor : uint32_t {
    ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP = 1,
    ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM = 2,
    ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT = 4,
    ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT = 8,
};


class CZwlrLayerShellV1;
class CZwlrLayerSurfaceV1;
class CWlSurface;
class CWlOutput;
class CZwlrLayerSurfaceV1;
class CXdgPopup;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwlr_layer_shell_v1_interface;
extern const wl_interface zwlr_layer_surface_v1_interface;

#endif

struct CZwlrLayerShellV1DestroyWrapper {
    wl_listener listener;
    CZwlrLayerShellV1* parent = nullptr;
};
            

class CZwlrLayerShellV1 {
  public:
    CZwlrLayerShellV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrLayerShellV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrLayerShellV1*)> handler) {
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

    void setGetLayerSurface(F<void(CZwlrLayerShellV1*, uint32_t, wl_resource*, wl_resource*, zwlrLayerShellV1Layer, const char*)> handler);
    void setDestroy(F<void(CZwlrLayerShellV1*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwlrLayerShellV1*, uint32_t, wl_resource*, wl_resource*, zwlrLayerShellV1Layer, const char*)> getLayerSurface;
        F<void(CZwlrLayerShellV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrLayerShellV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrLayerShellV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwlrLayerSurfaceV1DestroyWrapper {
    wl_listener listener;
    CZwlrLayerSurfaceV1* parent = nullptr;
};
            

class CZwlrLayerSurfaceV1 {
  public:
    CZwlrLayerSurfaceV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrLayerSurfaceV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrLayerSurfaceV1*)> handler) {
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

    void setSetSize(F<void(CZwlrLayerSurfaceV1*, uint32_t, uint32_t)> handler);
    void setSetAnchor(F<void(CZwlrLayerSurfaceV1*, zwlrLayerSurfaceV1Anchor)> handler);
    void setSetExclusiveZone(F<void(CZwlrLayerSurfaceV1*, int32_t)> handler);
    void setSetMargin(F<void(CZwlrLayerSurfaceV1*, int32_t, int32_t, int32_t, int32_t)> handler);
    void setSetKeyboardInteractivity(F<void(CZwlrLayerSurfaceV1*, zwlrLayerSurfaceV1KeyboardInteractivity)> handler);
    void setGetPopup(F<void(CZwlrLayerSurfaceV1*, wl_resource*)> handler);
    void setAckConfigure(F<void(CZwlrLayerSurfaceV1*, uint32_t)> handler);
    void setDestroy(F<void(CZwlrLayerSurfaceV1*)> handler);
    void setSetLayer(F<void(CZwlrLayerSurfaceV1*, uint32_t)> handler);
    void setSetExclusiveEdge(F<void(CZwlrLayerSurfaceV1*, zwlrLayerSurfaceV1Anchor)> handler);

    // --------------- Events --------------- //

    void sendConfigure(uint32_t, uint32_t, uint32_t);
    void sendClosed();
    void sendConfigureRaw(uint32_t, uint32_t, uint32_t);
    void sendClosedRaw();

  private:
    struct {
        F<void(CZwlrLayerSurfaceV1*, uint32_t, uint32_t)> setSize;
        F<void(CZwlrLayerSurfaceV1*, zwlrLayerSurfaceV1Anchor)> setAnchor;
        F<void(CZwlrLayerSurfaceV1*, int32_t)> setExclusiveZone;
        F<void(CZwlrLayerSurfaceV1*, int32_t, int32_t, int32_t, int32_t)> setMargin;
        F<void(CZwlrLayerSurfaceV1*, zwlrLayerSurfaceV1KeyboardInteractivity)> setKeyboardInteractivity;
        F<void(CZwlrLayerSurfaceV1*, wl_resource*)> getPopup;
        F<void(CZwlrLayerSurfaceV1*, uint32_t)> ackConfigure;
        F<void(CZwlrLayerSurfaceV1*)> destroy;
        F<void(CZwlrLayerSurfaceV1*, uint32_t)> setLayer;
        F<void(CZwlrLayerSurfaceV1*, zwlrLayerSurfaceV1Anchor)> setExclusiveEdge;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrLayerSurfaceV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrLayerSurfaceV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
