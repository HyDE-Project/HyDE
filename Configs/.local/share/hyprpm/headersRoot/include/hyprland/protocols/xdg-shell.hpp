// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// xdg_shell

/*
 This protocol's authors' copyright notice is:


    Copyright © 2008-2013 Kristian Høgsberg
    Copyright © 2013      Rafael Antognolli
    Copyright © 2013      Jasper St. Pierre
    Copyright © 2010-2013 Intel Corporation
    Copyright © 2015-2017 Samsung Electronics Co., Ltd
    Copyright © 2015-2017 Red Hat Inc.

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

enum xdgWmBaseError : uint32_t {
    XDG_WM_BASE_ERROR_ROLE = 0,
    XDG_WM_BASE_ERROR_DEFUNCT_SURFACES = 1,
    XDG_WM_BASE_ERROR_NOT_THE_TOPMOST_POPUP = 2,
    XDG_WM_BASE_ERROR_INVALID_POPUP_PARENT = 3,
    XDG_WM_BASE_ERROR_INVALID_SURFACE_STATE = 4,
    XDG_WM_BASE_ERROR_INVALID_POSITIONER = 5,
    XDG_WM_BASE_ERROR_UNRESPONSIVE = 6,
};

enum xdgPositionerError : uint32_t {
    XDG_POSITIONER_ERROR_INVALID_INPUT = 0,
};

enum xdgPositionerAnchor : uint32_t {
    XDG_POSITIONER_ANCHOR_NONE = 0,
    XDG_POSITIONER_ANCHOR_TOP = 1,
    XDG_POSITIONER_ANCHOR_BOTTOM = 2,
    XDG_POSITIONER_ANCHOR_LEFT = 3,
    XDG_POSITIONER_ANCHOR_RIGHT = 4,
    XDG_POSITIONER_ANCHOR_TOP_LEFT = 5,
    XDG_POSITIONER_ANCHOR_BOTTOM_LEFT = 6,
    XDG_POSITIONER_ANCHOR_TOP_RIGHT = 7,
    XDG_POSITIONER_ANCHOR_BOTTOM_RIGHT = 8,
};

enum xdgPositionerGravity : uint32_t {
    XDG_POSITIONER_GRAVITY_NONE = 0,
    XDG_POSITIONER_GRAVITY_TOP = 1,
    XDG_POSITIONER_GRAVITY_BOTTOM = 2,
    XDG_POSITIONER_GRAVITY_LEFT = 3,
    XDG_POSITIONER_GRAVITY_RIGHT = 4,
    XDG_POSITIONER_GRAVITY_TOP_LEFT = 5,
    XDG_POSITIONER_GRAVITY_BOTTOM_LEFT = 6,
    XDG_POSITIONER_GRAVITY_TOP_RIGHT = 7,
    XDG_POSITIONER_GRAVITY_BOTTOM_RIGHT = 8,
};

enum xdgPositionerConstraintAdjustment : uint32_t {
    XDG_POSITIONER_CONSTRAINT_ADJUSTMENT_NONE = 0,
    XDG_POSITIONER_CONSTRAINT_ADJUSTMENT_SLIDE_X = 1,
    XDG_POSITIONER_CONSTRAINT_ADJUSTMENT_SLIDE_Y = 2,
    XDG_POSITIONER_CONSTRAINT_ADJUSTMENT_FLIP_X = 4,
    XDG_POSITIONER_CONSTRAINT_ADJUSTMENT_FLIP_Y = 8,
    XDG_POSITIONER_CONSTRAINT_ADJUSTMENT_RESIZE_X = 16,
    XDG_POSITIONER_CONSTRAINT_ADJUSTMENT_RESIZE_Y = 32,
};

enum xdgSurfaceError : uint32_t {
    XDG_SURFACE_ERROR_NOT_CONSTRUCTED = 1,
    XDG_SURFACE_ERROR_ALREADY_CONSTRUCTED = 2,
    XDG_SURFACE_ERROR_UNCONFIGURED_BUFFER = 3,
    XDG_SURFACE_ERROR_INVALID_SERIAL = 4,
    XDG_SURFACE_ERROR_INVALID_SIZE = 5,
    XDG_SURFACE_ERROR_DEFUNCT_ROLE_OBJECT = 6,
};

enum xdgToplevelError : uint32_t {
    XDG_TOPLEVEL_ERROR_INVALID_RESIZE_EDGE = 0,
    XDG_TOPLEVEL_ERROR_INVALID_PARENT = 1,
    XDG_TOPLEVEL_ERROR_INVALID_SIZE = 2,
};

enum xdgToplevelResizeEdge : uint32_t {
    XDG_TOPLEVEL_RESIZE_EDGE_NONE = 0,
    XDG_TOPLEVEL_RESIZE_EDGE_TOP = 1,
    XDG_TOPLEVEL_RESIZE_EDGE_BOTTOM = 2,
    XDG_TOPLEVEL_RESIZE_EDGE_LEFT = 4,
    XDG_TOPLEVEL_RESIZE_EDGE_TOP_LEFT = 5,
    XDG_TOPLEVEL_RESIZE_EDGE_BOTTOM_LEFT = 6,
    XDG_TOPLEVEL_RESIZE_EDGE_RIGHT = 8,
    XDG_TOPLEVEL_RESIZE_EDGE_TOP_RIGHT = 9,
    XDG_TOPLEVEL_RESIZE_EDGE_BOTTOM_RIGHT = 10,
};

enum xdgToplevelState : uint32_t {
    XDG_TOPLEVEL_STATE_MAXIMIZED = 1,
    XDG_TOPLEVEL_STATE_FULLSCREEN = 2,
    XDG_TOPLEVEL_STATE_RESIZING = 3,
    XDG_TOPLEVEL_STATE_ACTIVATED = 4,
    XDG_TOPLEVEL_STATE_TILED_LEFT = 5,
    XDG_TOPLEVEL_STATE_TILED_RIGHT = 6,
    XDG_TOPLEVEL_STATE_TILED_TOP = 7,
    XDG_TOPLEVEL_STATE_TILED_BOTTOM = 8,
    XDG_TOPLEVEL_STATE_SUSPENDED = 9,
};

enum xdgToplevelWmCapabilities : uint32_t {
    XDG_TOPLEVEL_WM_CAPABILITIES_WINDOW_MENU = 1,
    XDG_TOPLEVEL_WM_CAPABILITIES_MAXIMIZE = 2,
    XDG_TOPLEVEL_WM_CAPABILITIES_FULLSCREEN = 3,
    XDG_TOPLEVEL_WM_CAPABILITIES_MINIMIZE = 4,
};

enum xdgPopupError : uint32_t {
    XDG_POPUP_ERROR_INVALID_GRAB = 0,
};


class CXdgWmBase;
class CXdgPositioner;
class CXdgSurface;
class CWlSurface;
class CXdgPositioner;
class CXdgSurface;
class CXdgToplevel;
class CXdgPopup;
class CXdgSurface;
class CXdgPositioner;
class CXdgToplevel;
class CXdgToplevel;
class CWlSeat;
class CWlSeat;
class CWlSeat;
class CWlOutput;
class CXdgPopup;
class CWlSeat;
class CXdgPositioner;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface xdg_wm_base_interface;
extern const wl_interface xdg_positioner_interface;
extern const wl_interface xdg_surface_interface;
extern const wl_interface xdg_toplevel_interface;
extern const wl_interface xdg_popup_interface;

#endif

struct CXdgWmBaseDestroyWrapper {
    wl_listener listener;
    CXdgWmBase* parent = nullptr;
};
            

class CXdgWmBase {
  public:
    CXdgWmBase(wl_client* client, uint32_t version, uint32_t id);
    ~CXdgWmBase();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CXdgWmBase*)> handler) {
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

    void setDestroy(F<void(CXdgWmBase*)> handler);
    void setCreatePositioner(F<void(CXdgWmBase*, uint32_t)> handler);
    void setGetXdgSurface(F<void(CXdgWmBase*, uint32_t, wl_resource*)> handler);
    void setPong(F<void(CXdgWmBase*, uint32_t)> handler);

    // --------------- Events --------------- //

    void sendPing(uint32_t);
    void sendPingRaw(uint32_t);

  private:
    struct {
        F<void(CXdgWmBase*)> destroy;
        F<void(CXdgWmBase*, uint32_t)> createPositioner;
        F<void(CXdgWmBase*, uint32_t, wl_resource*)> getXdgSurface;
        F<void(CXdgWmBase*, uint32_t)> pong;
    } requests;

    void onDestroyCalled();

    F<void(CXdgWmBase*)> onDestroy;

    wl_resource* pResource = nullptr;

    CXdgWmBaseDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CXdgPositionerDestroyWrapper {
    wl_listener listener;
    CXdgPositioner* parent = nullptr;
};
            

class CXdgPositioner {
  public:
    CXdgPositioner(wl_client* client, uint32_t version, uint32_t id);
    ~CXdgPositioner();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CXdgPositioner*)> handler) {
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

    void setDestroy(F<void(CXdgPositioner*)> handler);
    void setSetSize(F<void(CXdgPositioner*, int32_t, int32_t)> handler);
    void setSetAnchorRect(F<void(CXdgPositioner*, int32_t, int32_t, int32_t, int32_t)> handler);
    void setSetAnchor(F<void(CXdgPositioner*, xdgPositionerAnchor)> handler);
    void setSetGravity(F<void(CXdgPositioner*, xdgPositionerGravity)> handler);
    void setSetConstraintAdjustment(F<void(CXdgPositioner*, xdgPositionerConstraintAdjustment)> handler);
    void setSetOffset(F<void(CXdgPositioner*, int32_t, int32_t)> handler);
    void setSetReactive(F<void(CXdgPositioner*)> handler);
    void setSetParentSize(F<void(CXdgPositioner*, int32_t, int32_t)> handler);
    void setSetParentConfigure(F<void(CXdgPositioner*, uint32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CXdgPositioner*)> destroy;
        F<void(CXdgPositioner*, int32_t, int32_t)> setSize;
        F<void(CXdgPositioner*, int32_t, int32_t, int32_t, int32_t)> setAnchorRect;
        F<void(CXdgPositioner*, xdgPositionerAnchor)> setAnchor;
        F<void(CXdgPositioner*, xdgPositionerGravity)> setGravity;
        F<void(CXdgPositioner*, xdgPositionerConstraintAdjustment)> setConstraintAdjustment;
        F<void(CXdgPositioner*, int32_t, int32_t)> setOffset;
        F<void(CXdgPositioner*)> setReactive;
        F<void(CXdgPositioner*, int32_t, int32_t)> setParentSize;
        F<void(CXdgPositioner*, uint32_t)> setParentConfigure;
    } requests;

    void onDestroyCalled();

    F<void(CXdgPositioner*)> onDestroy;

    wl_resource* pResource = nullptr;

    CXdgPositionerDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CXdgSurfaceDestroyWrapper {
    wl_listener listener;
    CXdgSurface* parent = nullptr;
};
            

class CXdgSurface {
  public:
    CXdgSurface(wl_client* client, uint32_t version, uint32_t id);
    ~CXdgSurface();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CXdgSurface*)> handler) {
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

    void setDestroy(F<void(CXdgSurface*)> handler);
    void setGetToplevel(F<void(CXdgSurface*, uint32_t)> handler);
    void setGetPopup(F<void(CXdgSurface*, uint32_t, wl_resource*, wl_resource*)> handler);
    void setSetWindowGeometry(F<void(CXdgSurface*, int32_t, int32_t, int32_t, int32_t)> handler);
    void setAckConfigure(F<void(CXdgSurface*, uint32_t)> handler);

    // --------------- Events --------------- //

    void sendConfigure(uint32_t);
    void sendConfigureRaw(uint32_t);

  private:
    struct {
        F<void(CXdgSurface*)> destroy;
        F<void(CXdgSurface*, uint32_t)> getToplevel;
        F<void(CXdgSurface*, uint32_t, wl_resource*, wl_resource*)> getPopup;
        F<void(CXdgSurface*, int32_t, int32_t, int32_t, int32_t)> setWindowGeometry;
        F<void(CXdgSurface*, uint32_t)> ackConfigure;
    } requests;

    void onDestroyCalled();

    F<void(CXdgSurface*)> onDestroy;

    wl_resource* pResource = nullptr;

    CXdgSurfaceDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CXdgToplevelDestroyWrapper {
    wl_listener listener;
    CXdgToplevel* parent = nullptr;
};
            

class CXdgToplevel {
  public:
    CXdgToplevel(wl_client* client, uint32_t version, uint32_t id);
    ~CXdgToplevel();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CXdgToplevel*)> handler) {
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

    void setDestroy(F<void(CXdgToplevel*)> handler);
    void setSetParent(F<void(CXdgToplevel*, wl_resource*)> handler);
    void setSetTitle(F<void(CXdgToplevel*, const char*)> handler);
    void setSetAppId(F<void(CXdgToplevel*, const char*)> handler);
    void setShowWindowMenu(F<void(CXdgToplevel*, wl_resource*, uint32_t, int32_t, int32_t)> handler);
    void setMove(F<void(CXdgToplevel*, wl_resource*, uint32_t)> handler);
    void setResize(F<void(CXdgToplevel*, wl_resource*, uint32_t, xdgToplevelResizeEdge)> handler);
    void setSetMaxSize(F<void(CXdgToplevel*, int32_t, int32_t)> handler);
    void setSetMinSize(F<void(CXdgToplevel*, int32_t, int32_t)> handler);
    void setSetMaximized(F<void(CXdgToplevel*)> handler);
    void setUnsetMaximized(F<void(CXdgToplevel*)> handler);
    void setSetFullscreen(F<void(CXdgToplevel*, wl_resource*)> handler);
    void setUnsetFullscreen(F<void(CXdgToplevel*)> handler);
    void setSetMinimized(F<void(CXdgToplevel*)> handler);

    // --------------- Events --------------- //

    void sendConfigure(int32_t, int32_t, wl_array*);
    void sendClose();
    void sendConfigureBounds(int32_t, int32_t);
    void sendWmCapabilities(wl_array*);
    void sendConfigureRaw(int32_t, int32_t, wl_array*);
    void sendCloseRaw();
    void sendConfigureBoundsRaw(int32_t, int32_t);
    void sendWmCapabilitiesRaw(wl_array*);

  private:
    struct {
        F<void(CXdgToplevel*)> destroy;
        F<void(CXdgToplevel*, wl_resource*)> setParent;
        F<void(CXdgToplevel*, const char*)> setTitle;
        F<void(CXdgToplevel*, const char*)> setAppId;
        F<void(CXdgToplevel*, wl_resource*, uint32_t, int32_t, int32_t)> showWindowMenu;
        F<void(CXdgToplevel*, wl_resource*, uint32_t)> move;
        F<void(CXdgToplevel*, wl_resource*, uint32_t, xdgToplevelResizeEdge)> resize;
        F<void(CXdgToplevel*, int32_t, int32_t)> setMaxSize;
        F<void(CXdgToplevel*, int32_t, int32_t)> setMinSize;
        F<void(CXdgToplevel*)> setMaximized;
        F<void(CXdgToplevel*)> unsetMaximized;
        F<void(CXdgToplevel*, wl_resource*)> setFullscreen;
        F<void(CXdgToplevel*)> unsetFullscreen;
        F<void(CXdgToplevel*)> setMinimized;
    } requests;

    void onDestroyCalled();

    F<void(CXdgToplevel*)> onDestroy;

    wl_resource* pResource = nullptr;

    CXdgToplevelDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CXdgPopupDestroyWrapper {
    wl_listener listener;
    CXdgPopup* parent = nullptr;
};
            

class CXdgPopup {
  public:
    CXdgPopup(wl_client* client, uint32_t version, uint32_t id);
    ~CXdgPopup();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CXdgPopup*)> handler) {
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

    void setDestroy(F<void(CXdgPopup*)> handler);
    void setGrab(F<void(CXdgPopup*, wl_resource*, uint32_t)> handler);
    void setReposition(F<void(CXdgPopup*, wl_resource*, uint32_t)> handler);

    // --------------- Events --------------- //

    void sendConfigure(int32_t, int32_t, int32_t, int32_t);
    void sendPopupDone();
    void sendRepositioned(uint32_t);
    void sendConfigureRaw(int32_t, int32_t, int32_t, int32_t);
    void sendPopupDoneRaw();
    void sendRepositionedRaw(uint32_t);

  private:
    struct {
        F<void(CXdgPopup*)> destroy;
        F<void(CXdgPopup*, wl_resource*, uint32_t)> grab;
        F<void(CXdgPopup*, wl_resource*, uint32_t)> reposition;
    } requests;

    void onDestroyCalled();

    F<void(CXdgPopup*)> onDestroy;

    wl_resource* pResource = nullptr;

    CXdgPopupDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
