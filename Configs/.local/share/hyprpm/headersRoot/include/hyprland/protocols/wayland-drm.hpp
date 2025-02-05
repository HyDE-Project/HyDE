// Generated with hyprwayland-scanner 0.4.2. Made with vaxry's keyboard and ❤️.
// drm

/*
 This protocol's authors' copyright notice is:


    Copyright © 2008-2011 Kristian Høgsberg
    Copyright © 2010-2011 Intel Corporation

    Permission to use, copy, modify, distribute, and sell this
    software and its documentation for any purpose is hereby granted
    without fee, provided that\n the above copyright notice appear in
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

enum wlDrmError : uint32_t {
    WL_DRM_ERROR_AUTHENTICATE_FAIL = 0,
    WL_DRM_ERROR_INVALID_FORMAT = 1,
    WL_DRM_ERROR_INVALID_NAME = 2,
};

enum wlDrmFormat : uint32_t {
    WL_DRM_FORMAT_C8 = 538982467,
    WL_DRM_FORMAT_RGB332 = 943867730,
    WL_DRM_FORMAT_BGR233 = 944916290,
    WL_DRM_FORMAT_XRGB4444 = 842093144,
    WL_DRM_FORMAT_XBGR4444 = 842089048,
    WL_DRM_FORMAT_RGBX4444 = 842094674,
    WL_DRM_FORMAT_BGRX4444 = 842094658,
    WL_DRM_FORMAT_ARGB4444 = 842093121,
    WL_DRM_FORMAT_ABGR4444 = 842089025,
    WL_DRM_FORMAT_RGBA4444 = 842088786,
    WL_DRM_FORMAT_BGRA4444 = 842088770,
    WL_DRM_FORMAT_XRGB1555 = 892424792,
    WL_DRM_FORMAT_XBGR1555 = 892420696,
    WL_DRM_FORMAT_RGBX5551 = 892426322,
    WL_DRM_FORMAT_BGRX5551 = 892426306,
    WL_DRM_FORMAT_ARGB1555 = 892424769,
    WL_DRM_FORMAT_ABGR1555 = 892420673,
    WL_DRM_FORMAT_RGBA5551 = 892420434,
    WL_DRM_FORMAT_BGRA5551 = 892420418,
    WL_DRM_FORMAT_RGB565 = 909199186,
    WL_DRM_FORMAT_BGR565 = 909199170,
    WL_DRM_FORMAT_RGB888 = 875710290,
    WL_DRM_FORMAT_BGR888 = 875710274,
    WL_DRM_FORMAT_XRGB8888 = 875713112,
    WL_DRM_FORMAT_XBGR8888 = 875709016,
    WL_DRM_FORMAT_RGBX8888 = 875714642,
    WL_DRM_FORMAT_BGRX8888 = 875714626,
    WL_DRM_FORMAT_ARGB8888 = 875713089,
    WL_DRM_FORMAT_ABGR8888 = 875708993,
    WL_DRM_FORMAT_RGBA8888 = 875708754,
    WL_DRM_FORMAT_BGRA8888 = 875708738,
    WL_DRM_FORMAT_XRGB2101010 = 808669784,
    WL_DRM_FORMAT_XBGR2101010 = 808665688,
    WL_DRM_FORMAT_RGBX1010102 = 808671314,
    WL_DRM_FORMAT_BGRX1010102 = 808671298,
    WL_DRM_FORMAT_ARGB2101010 = 808669761,
    WL_DRM_FORMAT_ABGR2101010 = 808665665,
    WL_DRM_FORMAT_RGBA1010102 = 808665426,
    WL_DRM_FORMAT_BGRA1010102 = 808665410,
    WL_DRM_FORMAT_YUYV = 1448695129,
    WL_DRM_FORMAT_YVYU = 1431918169,
    WL_DRM_FORMAT_UYVY = 1498831189,
    WL_DRM_FORMAT_VYUY = 1498765654,
    WL_DRM_FORMAT_AYUV = 1448433985,
    WL_DRM_FORMAT_XYUV8888 = 1448434008,
    WL_DRM_FORMAT_NV12 = 842094158,
    WL_DRM_FORMAT_NV21 = 825382478,
    WL_DRM_FORMAT_NV16 = 909203022,
    WL_DRM_FORMAT_NV61 = 825644622,
    WL_DRM_FORMAT_YUV410 = 961959257,
    WL_DRM_FORMAT_YVU410 = 961893977,
    WL_DRM_FORMAT_YUV411 = 825316697,
    WL_DRM_FORMAT_YVU411 = 825316953,
    WL_DRM_FORMAT_YUV420 = 842093913,
    WL_DRM_FORMAT_YVU420 = 842094169,
    WL_DRM_FORMAT_YUV422 = 909202777,
    WL_DRM_FORMAT_YVU422 = 909203033,
    WL_DRM_FORMAT_YUV444 = 875713881,
    WL_DRM_FORMAT_YVU444 = 875714137,
    WL_DRM_FORMAT_ABGR16F = 1211384385,
    WL_DRM_FORMAT_XBGR16F = 1211384408,
};

enum wlDrmCapability : uint32_t {
    WL_DRM_CAPABILITY_PRIME = 1,
};


class CWlDrm;
class CWlBuffer;
class CWlBuffer;
class CWlBuffer;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface wl_drm_interface;

#endif

struct CWlDrmDestroyWrapper {
    wl_listener listener;
    CWlDrm* parent = nullptr;
};
            

class CWlDrm {
  public:
    CWlDrm(wl_client* client, uint32_t version, uint32_t id);
    ~CWlDrm();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlDrm*)> handler) {
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

    void setAuthenticate(F<void(CWlDrm*, uint32_t)> handler);
    void setCreateBuffer(F<void(CWlDrm*, uint32_t, uint32_t, int32_t, int32_t, uint32_t, uint32_t)> handler);
    void setCreatePlanarBuffer(F<void(CWlDrm*, uint32_t, uint32_t, int32_t, int32_t, uint32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t)> handler);
    void setCreatePrimeBuffer(F<void(CWlDrm*, uint32_t, int32_t, int32_t, int32_t, uint32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t)> handler);

    // --------------- Events --------------- //

    void sendDevice(const char*);
    void sendFormat(uint32_t);
    void sendAuthenticated();
    void sendCapabilities(uint32_t);
    void sendDeviceRaw(const char*);
    void sendFormatRaw(uint32_t);
    void sendAuthenticatedRaw();
    void sendCapabilitiesRaw(uint32_t);

  private:
    struct {
        F<void(CWlDrm*, uint32_t)> authenticate;
        F<void(CWlDrm*, uint32_t, uint32_t, int32_t, int32_t, uint32_t, uint32_t)> createBuffer;
        F<void(CWlDrm*, uint32_t, uint32_t, int32_t, int32_t, uint32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t)> createPlanarBuffer;
        F<void(CWlDrm*, uint32_t, int32_t, int32_t, int32_t, uint32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t)> createPrimeBuffer;
    } requests;

    void onDestroyCalled();

    F<void(CWlDrm*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlDrmDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
