// Generated with hyprwayland-scanner 0.4.2. Made with vaxry's keyboard and ❤️.
// wp_primary_selection_unstable_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2015, 2016 Red Hat

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


class CZwpPrimarySelectionDeviceManagerV1;
class CZwpPrimarySelectionSourceV1;
class CZwpPrimarySelectionDeviceV1;
class CWlSeat;
class CZwpPrimarySelectionDeviceV1;
class CZwpPrimarySelectionSourceV1;
class CZwpPrimarySelectionOfferV1;
class CZwpPrimarySelectionOfferV1;
class CZwpPrimarySelectionOfferV1;
class CZwpPrimarySelectionSourceV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwp_primary_selection_device_manager_v1_interface;
extern const wl_interface zwp_primary_selection_device_v1_interface;
extern const wl_interface zwp_primary_selection_offer_v1_interface;
extern const wl_interface zwp_primary_selection_source_v1_interface;

#endif

struct CZwpPrimarySelectionDeviceManagerV1DestroyWrapper {
    wl_listener listener;
    CZwpPrimarySelectionDeviceManagerV1* parent = nullptr;
};
            

class CZwpPrimarySelectionDeviceManagerV1 {
  public:
    CZwpPrimarySelectionDeviceManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpPrimarySelectionDeviceManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpPrimarySelectionDeviceManagerV1*)> handler) {
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

    void setCreateSource(F<void(CZwpPrimarySelectionDeviceManagerV1*, uint32_t)> handler);
    void setGetDevice(F<void(CZwpPrimarySelectionDeviceManagerV1*, uint32_t, wl_resource*)> handler);
    void setDestroy(F<void(CZwpPrimarySelectionDeviceManagerV1*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwpPrimarySelectionDeviceManagerV1*, uint32_t)> createSource;
        F<void(CZwpPrimarySelectionDeviceManagerV1*, uint32_t, wl_resource*)> getDevice;
        F<void(CZwpPrimarySelectionDeviceManagerV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpPrimarySelectionDeviceManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpPrimarySelectionDeviceManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpPrimarySelectionDeviceV1DestroyWrapper {
    wl_listener listener;
    CZwpPrimarySelectionDeviceV1* parent = nullptr;
};
            

class CZwpPrimarySelectionDeviceV1 {
  public:
    CZwpPrimarySelectionDeviceV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpPrimarySelectionDeviceV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpPrimarySelectionDeviceV1*)> handler) {
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

    void setSetSelection(F<void(CZwpPrimarySelectionDeviceV1*, wl_resource*, uint32_t)> handler);
    void setDestroy(F<void(CZwpPrimarySelectionDeviceV1*)> handler);

    // --------------- Events --------------- //

    void sendDataOffer(CZwpPrimarySelectionOfferV1*);
    void sendSelection(CZwpPrimarySelectionOfferV1*);
    void sendDataOfferRaw(CZwpPrimarySelectionOfferV1*);
    void sendSelectionRaw(wl_resource*);

  private:
    struct {
        F<void(CZwpPrimarySelectionDeviceV1*, wl_resource*, uint32_t)> setSelection;
        F<void(CZwpPrimarySelectionDeviceV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpPrimarySelectionDeviceV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpPrimarySelectionDeviceV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpPrimarySelectionOfferV1DestroyWrapper {
    wl_listener listener;
    CZwpPrimarySelectionOfferV1* parent = nullptr;
};
            

class CZwpPrimarySelectionOfferV1 {
  public:
    CZwpPrimarySelectionOfferV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpPrimarySelectionOfferV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpPrimarySelectionOfferV1*)> handler) {
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

    void setReceive(F<void(CZwpPrimarySelectionOfferV1*, const char*, int32_t)> handler);
    void setDestroy(F<void(CZwpPrimarySelectionOfferV1*)> handler);

    // --------------- Events --------------- //

    void sendOffer(const char*);
    void sendOfferRaw(const char*);

  private:
    struct {
        F<void(CZwpPrimarySelectionOfferV1*, const char*, int32_t)> receive;
        F<void(CZwpPrimarySelectionOfferV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpPrimarySelectionOfferV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpPrimarySelectionOfferV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpPrimarySelectionSourceV1DestroyWrapper {
    wl_listener listener;
    CZwpPrimarySelectionSourceV1* parent = nullptr;
};
            

class CZwpPrimarySelectionSourceV1 {
  public:
    CZwpPrimarySelectionSourceV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpPrimarySelectionSourceV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpPrimarySelectionSourceV1*)> handler) {
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

    void setOffer(F<void(CZwpPrimarySelectionSourceV1*, const char*)> handler);
    void setDestroy(F<void(CZwpPrimarySelectionSourceV1*)> handler);

    // --------------- Events --------------- //

    void sendSend(const char*, int32_t);
    void sendCancelled();
    void sendSendRaw(const char*, int32_t);
    void sendCancelledRaw();

  private:
    struct {
        F<void(CZwpPrimarySelectionSourceV1*, const char*)> offer;
        F<void(CZwpPrimarySelectionSourceV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpPrimarySelectionSourceV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpPrimarySelectionSourceV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
