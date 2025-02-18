// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// linux_drm_syncobj_v1

/*
 This protocol's authors' copyright notice is:


    Copyright 2016 The Chromium Authors.
    Copyright 2017 Intel Corporation
    Copyright 2018 Collabora, Ltd
    Copyright 2021 Simon Ser

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

enum wpLinuxDrmSyncobjManagerV1Error : uint32_t {
    WP_LINUX_DRM_SYNCOBJ_MANAGER_V1_ERROR_SURFACE_EXISTS = 0,
    WP_LINUX_DRM_SYNCOBJ_MANAGER_V1_ERROR_INVALID_TIMELINE = 1,
};

enum wpLinuxDrmSyncobjSurfaceV1Error : uint32_t {
    WP_LINUX_DRM_SYNCOBJ_SURFACE_V1_ERROR_NO_SURFACE = 1,
    WP_LINUX_DRM_SYNCOBJ_SURFACE_V1_ERROR_UNSUPPORTED_BUFFER = 2,
    WP_LINUX_DRM_SYNCOBJ_SURFACE_V1_ERROR_NO_BUFFER = 3,
    WP_LINUX_DRM_SYNCOBJ_SURFACE_V1_ERROR_NO_ACQUIRE_POINT = 4,
    WP_LINUX_DRM_SYNCOBJ_SURFACE_V1_ERROR_NO_RELEASE_POINT = 5,
    WP_LINUX_DRM_SYNCOBJ_SURFACE_V1_ERROR_CONFLICTING_POINTS = 6,
};


class CWpLinuxDrmSyncobjManagerV1;
class CWpLinuxDrmSyncobjSurfaceV1;
class CWlSurface;
class CWpLinuxDrmSyncobjTimelineV1;
class CWpLinuxDrmSyncobjTimelineV1;
class CWpLinuxDrmSyncobjSurfaceV1;
class CWpLinuxDrmSyncobjTimelineV1;
class CWpLinuxDrmSyncobjTimelineV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface wp_linux_drm_syncobj_manager_v1_interface;
extern const wl_interface wp_linux_drm_syncobj_timeline_v1_interface;
extern const wl_interface wp_linux_drm_syncobj_surface_v1_interface;

#endif

struct CWpLinuxDrmSyncobjManagerV1DestroyWrapper {
    wl_listener listener;
    CWpLinuxDrmSyncobjManagerV1* parent = nullptr;
};
            

class CWpLinuxDrmSyncobjManagerV1 {
  public:
    CWpLinuxDrmSyncobjManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CWpLinuxDrmSyncobjManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpLinuxDrmSyncobjManagerV1*)> handler) {
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

    void setDestroy(F<void(CWpLinuxDrmSyncobjManagerV1*)> handler);
    void setGetSurface(F<void(CWpLinuxDrmSyncobjManagerV1*, uint32_t, wl_resource*)> handler);
    void setImportTimeline(F<void(CWpLinuxDrmSyncobjManagerV1*, uint32_t, int32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWpLinuxDrmSyncobjManagerV1*)> destroy;
        F<void(CWpLinuxDrmSyncobjManagerV1*, uint32_t, wl_resource*)> getSurface;
        F<void(CWpLinuxDrmSyncobjManagerV1*, uint32_t, int32_t)> importTimeline;
    } requests;

    void onDestroyCalled();

    F<void(CWpLinuxDrmSyncobjManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpLinuxDrmSyncobjManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWpLinuxDrmSyncobjTimelineV1DestroyWrapper {
    wl_listener listener;
    CWpLinuxDrmSyncobjTimelineV1* parent = nullptr;
};
            

class CWpLinuxDrmSyncobjTimelineV1 {
  public:
    CWpLinuxDrmSyncobjTimelineV1(wl_client* client, uint32_t version, uint32_t id);
    ~CWpLinuxDrmSyncobjTimelineV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpLinuxDrmSyncobjTimelineV1*)> handler) {
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

    void setDestroy(F<void(CWpLinuxDrmSyncobjTimelineV1*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWpLinuxDrmSyncobjTimelineV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CWpLinuxDrmSyncobjTimelineV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpLinuxDrmSyncobjTimelineV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWpLinuxDrmSyncobjSurfaceV1DestroyWrapper {
    wl_listener listener;
    CWpLinuxDrmSyncobjSurfaceV1* parent = nullptr;
};
            

class CWpLinuxDrmSyncobjSurfaceV1 {
  public:
    CWpLinuxDrmSyncobjSurfaceV1(wl_client* client, uint32_t version, uint32_t id);
    ~CWpLinuxDrmSyncobjSurfaceV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpLinuxDrmSyncobjSurfaceV1*)> handler) {
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

    void setDestroy(F<void(CWpLinuxDrmSyncobjSurfaceV1*)> handler);
    void setSetAcquirePoint(F<void(CWpLinuxDrmSyncobjSurfaceV1*, wl_resource*, uint32_t, uint32_t)> handler);
    void setSetReleasePoint(F<void(CWpLinuxDrmSyncobjSurfaceV1*, wl_resource*, uint32_t, uint32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWpLinuxDrmSyncobjSurfaceV1*)> destroy;
        F<void(CWpLinuxDrmSyncobjSurfaceV1*, wl_resource*, uint32_t, uint32_t)> setAcquirePoint;
        F<void(CWpLinuxDrmSyncobjSurfaceV1*, wl_resource*, uint32_t, uint32_t)> setReleasePoint;
    } requests;

    void onDestroyCalled();

    F<void(CWpLinuxDrmSyncobjSurfaceV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpLinuxDrmSyncobjSurfaceV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
