// Generated with hyprwayland-scanner 0.4.2. Made with vaxry's keyboard and ❤️.
// cursor_shape_v1

/*
 This protocol's authors' copyright notice is:


    Copyright 2018 The Chromium Authors
    Copyright 2023 Simon Ser

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
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
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

enum wpCursorShapeDeviceV1Shape : uint32_t {
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_DEFAULT = 1,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_CONTEXT_MENU = 2,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_HELP = 3,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_POINTER = 4,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_PROGRESS = 5,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_WAIT = 6,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_CELL = 7,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_CROSSHAIR = 8,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_TEXT = 9,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_VERTICAL_TEXT = 10,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_ALIAS = 11,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_COPY = 12,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_MOVE = 13,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_NO_DROP = 14,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_NOT_ALLOWED = 15,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_GRAB = 16,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_GRABBING = 17,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_E_RESIZE = 18,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_N_RESIZE = 19,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_NE_RESIZE = 20,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_NW_RESIZE = 21,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_S_RESIZE = 22,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_SE_RESIZE = 23,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_SW_RESIZE = 24,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_W_RESIZE = 25,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_EW_RESIZE = 26,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_NS_RESIZE = 27,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_NESW_RESIZE = 28,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_NWSE_RESIZE = 29,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_COL_RESIZE = 30,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_ROW_RESIZE = 31,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_ALL_SCROLL = 32,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_ZOOM_IN = 33,
    WP_CURSOR_SHAPE_DEVICE_V1_SHAPE_ZOOM_OUT = 34,
};

enum wpCursorShapeDeviceV1Error : uint32_t {
    WP_CURSOR_SHAPE_DEVICE_V1_ERROR_INVALID_SHAPE = 1,
};


class CWpCursorShapeManagerV1;
class CWpCursorShapeDeviceV1;
class CWlPointer;
class CWpCursorShapeDeviceV1;
class CZwpTabletToolV2;
class CWpCursorShapeDeviceV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface wp_cursor_shape_manager_v1_interface;
extern const wl_interface wp_cursor_shape_device_v1_interface;

#endif

struct CWpCursorShapeManagerV1DestroyWrapper {
    wl_listener listener;
    CWpCursorShapeManagerV1* parent = nullptr;
};
            

class CWpCursorShapeManagerV1 {
  public:
    CWpCursorShapeManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CWpCursorShapeManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpCursorShapeManagerV1*)> handler) {
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

    void setDestroy(F<void(CWpCursorShapeManagerV1*)> handler);
    void setGetPointer(F<void(CWpCursorShapeManagerV1*, uint32_t, wl_resource*)> handler);
    void setGetTabletToolV2(F<void(CWpCursorShapeManagerV1*, uint32_t, wl_resource*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWpCursorShapeManagerV1*)> destroy;
        F<void(CWpCursorShapeManagerV1*, uint32_t, wl_resource*)> getPointer;
        F<void(CWpCursorShapeManagerV1*, uint32_t, wl_resource*)> getTabletToolV2;
    } requests;

    void onDestroyCalled();

    F<void(CWpCursorShapeManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpCursorShapeManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWpCursorShapeDeviceV1DestroyWrapper {
    wl_listener listener;
    CWpCursorShapeDeviceV1* parent = nullptr;
};
            

class CWpCursorShapeDeviceV1 {
  public:
    CWpCursorShapeDeviceV1(wl_client* client, uint32_t version, uint32_t id);
    ~CWpCursorShapeDeviceV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpCursorShapeDeviceV1*)> handler) {
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

    void setDestroy(F<void(CWpCursorShapeDeviceV1*)> handler);
    void setSetShape(F<void(CWpCursorShapeDeviceV1*, uint32_t, wpCursorShapeDeviceV1Shape)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWpCursorShapeDeviceV1*)> destroy;
        F<void(CWpCursorShapeDeviceV1*, uint32_t, wpCursorShapeDeviceV1Shape)> setShape;
    } requests;

    void onDestroyCalled();

    F<void(CWpCursorShapeDeviceV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpCursorShapeDeviceV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
