// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// wlr_data_control_unstable_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2018 Simon Ser
    Copyright © 2019 Ivan Molodetskikh

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

enum zwlrDataControlDeviceV1Error : uint32_t {
    ZWLR_DATA_CONTROL_DEVICE_V1_ERROR_USED_SOURCE = 1,
};

enum zwlrDataControlSourceV1Error : uint32_t {
    ZWLR_DATA_CONTROL_SOURCE_V1_ERROR_INVALID_OFFER = 1,
};


class CZwlrDataControlManagerV1;
class CZwlrDataControlSourceV1;
class CZwlrDataControlDeviceV1;
class CWlSeat;
class CZwlrDataControlDeviceV1;
class CZwlrDataControlSourceV1;
class CZwlrDataControlSourceV1;
class CZwlrDataControlOfferV1;
class CZwlrDataControlOfferV1;
class CZwlrDataControlOfferV1;
class CZwlrDataControlSourceV1;
class CZwlrDataControlOfferV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwlr_data_control_manager_v1_interface;
extern const wl_interface zwlr_data_control_device_v1_interface;
extern const wl_interface zwlr_data_control_source_v1_interface;
extern const wl_interface zwlr_data_control_offer_v1_interface;

#endif

struct CZwlrDataControlManagerV1DestroyWrapper {
    wl_listener listener;
    CZwlrDataControlManagerV1* parent = nullptr;
};
            

class CZwlrDataControlManagerV1 {
  public:
    CZwlrDataControlManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrDataControlManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrDataControlManagerV1*)> handler) {
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

    void setCreateDataSource(F<void(CZwlrDataControlManagerV1*, uint32_t)> handler);
    void setGetDataDevice(F<void(CZwlrDataControlManagerV1*, uint32_t, wl_resource*)> handler);
    void setDestroy(F<void(CZwlrDataControlManagerV1*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwlrDataControlManagerV1*, uint32_t)> createDataSource;
        F<void(CZwlrDataControlManagerV1*, uint32_t, wl_resource*)> getDataDevice;
        F<void(CZwlrDataControlManagerV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrDataControlManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrDataControlManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwlrDataControlDeviceV1DestroyWrapper {
    wl_listener listener;
    CZwlrDataControlDeviceV1* parent = nullptr;
};
            

class CZwlrDataControlDeviceV1 {
  public:
    CZwlrDataControlDeviceV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrDataControlDeviceV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrDataControlDeviceV1*)> handler) {
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

    void setSetSelection(F<void(CZwlrDataControlDeviceV1*, wl_resource*)> handler);
    void setDestroy(F<void(CZwlrDataControlDeviceV1*)> handler);
    void setSetPrimarySelection(F<void(CZwlrDataControlDeviceV1*, wl_resource*)> handler);

    // --------------- Events --------------- //

    void sendDataOffer(CZwlrDataControlOfferV1*);
    void sendSelection(CZwlrDataControlOfferV1*);
    void sendFinished();
    void sendPrimarySelection(CZwlrDataControlOfferV1*);
    void sendDataOfferRaw(CZwlrDataControlOfferV1*);
    void sendSelectionRaw(wl_resource*);
    void sendFinishedRaw();
    void sendPrimarySelectionRaw(wl_resource*);

  private:
    struct {
        F<void(CZwlrDataControlDeviceV1*, wl_resource*)> setSelection;
        F<void(CZwlrDataControlDeviceV1*)> destroy;
        F<void(CZwlrDataControlDeviceV1*, wl_resource*)> setPrimarySelection;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrDataControlDeviceV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrDataControlDeviceV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwlrDataControlSourceV1DestroyWrapper {
    wl_listener listener;
    CZwlrDataControlSourceV1* parent = nullptr;
};
            

class CZwlrDataControlSourceV1 {
  public:
    CZwlrDataControlSourceV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrDataControlSourceV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrDataControlSourceV1*)> handler) {
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

    void setOffer(F<void(CZwlrDataControlSourceV1*, const char*)> handler);
    void setDestroy(F<void(CZwlrDataControlSourceV1*)> handler);

    // --------------- Events --------------- //

    void sendSend(const char*, int32_t);
    void sendCancelled();
    void sendSendRaw(const char*, int32_t);
    void sendCancelledRaw();

  private:
    struct {
        F<void(CZwlrDataControlSourceV1*, const char*)> offer;
        F<void(CZwlrDataControlSourceV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrDataControlSourceV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrDataControlSourceV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwlrDataControlOfferV1DestroyWrapper {
    wl_listener listener;
    CZwlrDataControlOfferV1* parent = nullptr;
};
            

class CZwlrDataControlOfferV1 {
  public:
    CZwlrDataControlOfferV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrDataControlOfferV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrDataControlOfferV1*)> handler) {
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

    void setReceive(F<void(CZwlrDataControlOfferV1*, const char*, int32_t)> handler);
    void setDestroy(F<void(CZwlrDataControlOfferV1*)> handler);

    // --------------- Events --------------- //

    void sendOffer(const char*);
    void sendOfferRaw(const char*);

  private:
    struct {
        F<void(CZwlrDataControlOfferV1*, const char*, int32_t)> receive;
        F<void(CZwlrDataControlOfferV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrDataControlOfferV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrDataControlOfferV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
