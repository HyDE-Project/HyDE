// Generated with hyprwayland-scanner 0.4.2. Made with vaxry's keyboard and ❤️.
// drm_lease_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2018 NXP
    Copyright © 2019 Status Research & Development GmbH.
    Copyright © 2021 Xaver Hugl

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

enum wpDrmLeaseRequestV1Error : uint32_t {
    WP_DRM_LEASE_REQUEST_V1_ERROR_WRONG_DEVICE = 0,
    WP_DRM_LEASE_REQUEST_V1_ERROR_DUPLICATE_CONNECTOR = 1,
    WP_DRM_LEASE_REQUEST_V1_ERROR_EMPTY_LEASE = 2,
};


class CWpDrmLeaseDeviceV1;
class CWpDrmLeaseRequestV1;
class CWpDrmLeaseConnectorV1;
class CWpDrmLeaseConnectorV1;
class CWpDrmLeaseRequestV1;
class CWpDrmLeaseConnectorV1;
class CWpDrmLeaseV1;
class CWpDrmLeaseV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface wp_drm_lease_device_v1_interface;
extern const wl_interface wp_drm_lease_connector_v1_interface;
extern const wl_interface wp_drm_lease_request_v1_interface;
extern const wl_interface wp_drm_lease_v1_interface;

#endif

struct CWpDrmLeaseDeviceV1DestroyWrapper {
    wl_listener listener;
    CWpDrmLeaseDeviceV1* parent = nullptr;
};
            

class CWpDrmLeaseDeviceV1 {
  public:
    CWpDrmLeaseDeviceV1(wl_client* client, uint32_t version, uint32_t id);
    ~CWpDrmLeaseDeviceV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpDrmLeaseDeviceV1*)> handler) {
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

    void setCreateLeaseRequest(F<void(CWpDrmLeaseDeviceV1*, uint32_t)> handler);
    void setRelease(F<void(CWpDrmLeaseDeviceV1*)> handler);

    // --------------- Events --------------- //

    void sendDrmFd(int32_t);
    void sendConnector(CWpDrmLeaseConnectorV1*);
    void sendDone();
    void sendReleased();
    void sendDrmFdRaw(int32_t);
    void sendConnectorRaw(CWpDrmLeaseConnectorV1*);
    void sendDoneRaw();
    void sendReleasedRaw();

  private:
    struct {
        F<void(CWpDrmLeaseDeviceV1*, uint32_t)> createLeaseRequest;
        F<void(CWpDrmLeaseDeviceV1*)> release;
    } requests;

    void onDestroyCalled();

    F<void(CWpDrmLeaseDeviceV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpDrmLeaseDeviceV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWpDrmLeaseConnectorV1DestroyWrapper {
    wl_listener listener;
    CWpDrmLeaseConnectorV1* parent = nullptr;
};
            

class CWpDrmLeaseConnectorV1 {
  public:
    CWpDrmLeaseConnectorV1(wl_client* client, uint32_t version, uint32_t id);
    ~CWpDrmLeaseConnectorV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpDrmLeaseConnectorV1*)> handler) {
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

    void setDestroy(F<void(CWpDrmLeaseConnectorV1*)> handler);

    // --------------- Events --------------- //

    void sendName(const char*);
    void sendDescription(const char*);
    void sendConnectorId(uint32_t);
    void sendDone();
    void sendWithdrawn();
    void sendNameRaw(const char*);
    void sendDescriptionRaw(const char*);
    void sendConnectorIdRaw(uint32_t);
    void sendDoneRaw();
    void sendWithdrawnRaw();

  private:
    struct {
        F<void(CWpDrmLeaseConnectorV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CWpDrmLeaseConnectorV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpDrmLeaseConnectorV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWpDrmLeaseRequestV1DestroyWrapper {
    wl_listener listener;
    CWpDrmLeaseRequestV1* parent = nullptr;
};
            

class CWpDrmLeaseRequestV1 {
  public:
    CWpDrmLeaseRequestV1(wl_client* client, uint32_t version, uint32_t id);
    ~CWpDrmLeaseRequestV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpDrmLeaseRequestV1*)> handler) {
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

    void setRequestConnector(F<void(CWpDrmLeaseRequestV1*, wl_resource*)> handler);
    void setSubmit(F<void(CWpDrmLeaseRequestV1*, uint32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWpDrmLeaseRequestV1*, wl_resource*)> requestConnector;
        F<void(CWpDrmLeaseRequestV1*, uint32_t)> submit;
    } requests;

    void onDestroyCalled();

    F<void(CWpDrmLeaseRequestV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpDrmLeaseRequestV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWpDrmLeaseV1DestroyWrapper {
    wl_listener listener;
    CWpDrmLeaseV1* parent = nullptr;
};
            

class CWpDrmLeaseV1 {
  public:
    CWpDrmLeaseV1(wl_client* client, uint32_t version, uint32_t id);
    ~CWpDrmLeaseV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpDrmLeaseV1*)> handler) {
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

    void setDestroy(F<void(CWpDrmLeaseV1*)> handler);

    // --------------- Events --------------- //

    void sendLeaseFd(int32_t);
    void sendFinished();
    void sendLeaseFdRaw(int32_t);
    void sendFinishedRaw();

  private:
    struct {
        F<void(CWpDrmLeaseV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CWpDrmLeaseV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpDrmLeaseV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
