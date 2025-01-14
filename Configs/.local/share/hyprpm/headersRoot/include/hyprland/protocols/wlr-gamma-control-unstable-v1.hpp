// Generated with hyprwayland-scanner 0.4.2. Made with vaxry's keyboard and ❤️.
// wlr_gamma_control_unstable_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2015 Giulio camuffo
    Copyright © 2018 Simon Ser

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

enum zwlrGammaControlV1Error : uint32_t {
    ZWLR_GAMMA_CONTROL_V1_ERROR_INVALID_GAMMA = 1,
};


class CZwlrGammaControlManagerV1;
class CZwlrGammaControlV1;
class CWlOutput;
class CZwlrGammaControlV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwlr_gamma_control_manager_v1_interface;
extern const wl_interface zwlr_gamma_control_v1_interface;

#endif

struct CZwlrGammaControlManagerV1DestroyWrapper {
    wl_listener listener;
    CZwlrGammaControlManagerV1* parent = nullptr;
};
            

class CZwlrGammaControlManagerV1 {
  public:
    CZwlrGammaControlManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrGammaControlManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrGammaControlManagerV1*)> handler) {
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

    void setGetGammaControl(F<void(CZwlrGammaControlManagerV1*, uint32_t, wl_resource*)> handler);
    void setDestroy(F<void(CZwlrGammaControlManagerV1*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwlrGammaControlManagerV1*, uint32_t, wl_resource*)> getGammaControl;
        F<void(CZwlrGammaControlManagerV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrGammaControlManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrGammaControlManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwlrGammaControlV1DestroyWrapper {
    wl_listener listener;
    CZwlrGammaControlV1* parent = nullptr;
};
            

class CZwlrGammaControlV1 {
  public:
    CZwlrGammaControlV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrGammaControlV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrGammaControlV1*)> handler) {
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

    void setSetGamma(F<void(CZwlrGammaControlV1*, int32_t)> handler);
    void setDestroy(F<void(CZwlrGammaControlV1*)> handler);

    // --------------- Events --------------- //

    void sendGammaSize(uint32_t);
    void sendFailed();
    void sendGammaSizeRaw(uint32_t);
    void sendFailedRaw();

  private:
    struct {
        F<void(CZwlrGammaControlV1*, int32_t)> setGamma;
        F<void(CZwlrGammaControlV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrGammaControlV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrGammaControlV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
