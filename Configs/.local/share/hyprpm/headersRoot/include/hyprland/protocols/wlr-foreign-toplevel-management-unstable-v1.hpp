// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// wlr_foreign_toplevel_management_unstable_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2018 Ilia Bozhinov

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

enum zwlrForeignToplevelHandleV1State : uint32_t {
    ZWLR_FOREIGN_TOPLEVEL_HANDLE_V1_STATE_MAXIMIZED = 0,
    ZWLR_FOREIGN_TOPLEVEL_HANDLE_V1_STATE_MINIMIZED = 1,
    ZWLR_FOREIGN_TOPLEVEL_HANDLE_V1_STATE_ACTIVATED = 2,
    ZWLR_FOREIGN_TOPLEVEL_HANDLE_V1_STATE_FULLSCREEN = 3,
};

enum zwlrForeignToplevelHandleV1Error : uint32_t {
    ZWLR_FOREIGN_TOPLEVEL_HANDLE_V1_ERROR_INVALID_RECTANGLE = 0,
};


class CZwlrForeignToplevelManagerV1;
class CZwlrForeignToplevelHandleV1;
class CZwlrForeignToplevelHandleV1;
class CWlSeat;
class CWlSurface;
class CWlOutput;
class CWlOutput;
class CWlOutput;
class CZwlrForeignToplevelHandleV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwlr_foreign_toplevel_manager_v1_interface;
extern const wl_interface zwlr_foreign_toplevel_handle_v1_interface;

#endif

struct CZwlrForeignToplevelManagerV1DestroyWrapper {
    wl_listener listener;
    CZwlrForeignToplevelManagerV1* parent = nullptr;
};
            

class CZwlrForeignToplevelManagerV1 {
  public:
    CZwlrForeignToplevelManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrForeignToplevelManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrForeignToplevelManagerV1*)> handler) {
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

    void setStop(F<void(CZwlrForeignToplevelManagerV1*)> handler);

    // --------------- Events --------------- //

    void sendToplevel(CZwlrForeignToplevelHandleV1*);
    void sendFinished();
    void sendToplevelRaw(CZwlrForeignToplevelHandleV1*);
    void sendFinishedRaw();

  private:
    struct {
        F<void(CZwlrForeignToplevelManagerV1*)> stop;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrForeignToplevelManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrForeignToplevelManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwlrForeignToplevelHandleV1DestroyWrapper {
    wl_listener listener;
    CZwlrForeignToplevelHandleV1* parent = nullptr;
};
            

class CZwlrForeignToplevelHandleV1 {
  public:
    CZwlrForeignToplevelHandleV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrForeignToplevelHandleV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrForeignToplevelHandleV1*)> handler) {
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

    void setSetMaximized(F<void(CZwlrForeignToplevelHandleV1*)> handler);
    void setUnsetMaximized(F<void(CZwlrForeignToplevelHandleV1*)> handler);
    void setSetMinimized(F<void(CZwlrForeignToplevelHandleV1*)> handler);
    void setUnsetMinimized(F<void(CZwlrForeignToplevelHandleV1*)> handler);
    void setActivate(F<void(CZwlrForeignToplevelHandleV1*, wl_resource*)> handler);
    void setClose(F<void(CZwlrForeignToplevelHandleV1*)> handler);
    void setSetRectangle(F<void(CZwlrForeignToplevelHandleV1*, wl_resource*, int32_t, int32_t, int32_t, int32_t)> handler);
    void setDestroy(F<void(CZwlrForeignToplevelHandleV1*)> handler);
    void setSetFullscreen(F<void(CZwlrForeignToplevelHandleV1*, wl_resource*)> handler);
    void setUnsetFullscreen(F<void(CZwlrForeignToplevelHandleV1*)> handler);

    // --------------- Events --------------- //

    void sendTitle(const char*);
    void sendAppId(const char*);
    void sendOutputEnter(wl_resource*);
    void sendOutputLeave(wl_resource*);
    void sendState(wl_array*);
    void sendDone();
    void sendClosed();
    void sendParent(CZwlrForeignToplevelHandleV1*);
    void sendTitleRaw(const char*);
    void sendAppIdRaw(const char*);
    void sendOutputEnterRaw(wl_resource*);
    void sendOutputLeaveRaw(wl_resource*);
    void sendStateRaw(wl_array*);
    void sendDoneRaw();
    void sendClosedRaw();
    void sendParentRaw(wl_resource*);

  private:
    struct {
        F<void(CZwlrForeignToplevelHandleV1*)> setMaximized;
        F<void(CZwlrForeignToplevelHandleV1*)> unsetMaximized;
        F<void(CZwlrForeignToplevelHandleV1*)> setMinimized;
        F<void(CZwlrForeignToplevelHandleV1*)> unsetMinimized;
        F<void(CZwlrForeignToplevelHandleV1*, wl_resource*)> activate;
        F<void(CZwlrForeignToplevelHandleV1*)> close;
        F<void(CZwlrForeignToplevelHandleV1*, wl_resource*, int32_t, int32_t, int32_t, int32_t)> setRectangle;
        F<void(CZwlrForeignToplevelHandleV1*)> destroy;
        F<void(CZwlrForeignToplevelHandleV1*, wl_resource*)> setFullscreen;
        F<void(CZwlrForeignToplevelHandleV1*)> unsetFullscreen;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrForeignToplevelHandleV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrForeignToplevelHandleV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
