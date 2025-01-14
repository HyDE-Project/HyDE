// Generated with hyprwayland-scanner 0.4.2. Made with vaxry's keyboard and ❤️.
// security_context_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2021 Simon Ser

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

enum wpSecurityContextManagerV1Error : uint32_t {
    WP_SECURITY_CONTEXT_MANAGER_V1_ERROR_INVALID_LISTEN_FD = 1,
    WP_SECURITY_CONTEXT_MANAGER_V1_ERROR_NESTED = 2,
};

enum wpSecurityContextV1Error : uint32_t {
    WP_SECURITY_CONTEXT_V1_ERROR_ALREADY_USED = 1,
    WP_SECURITY_CONTEXT_V1_ERROR_ALREADY_SET = 2,
    WP_SECURITY_CONTEXT_V1_ERROR_INVALID_METADATA = 3,
};


class CWpSecurityContextManagerV1;
class CWpSecurityContextV1;
class CWpSecurityContextV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface wp_security_context_manager_v1_interface;
extern const wl_interface wp_security_context_v1_interface;

#endif

struct CWpSecurityContextManagerV1DestroyWrapper {
    wl_listener listener;
    CWpSecurityContextManagerV1* parent = nullptr;
};
            

class CWpSecurityContextManagerV1 {
  public:
    CWpSecurityContextManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CWpSecurityContextManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpSecurityContextManagerV1*)> handler) {
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

    void setDestroy(F<void(CWpSecurityContextManagerV1*)> handler);
    void setCreateListener(F<void(CWpSecurityContextManagerV1*, uint32_t, int32_t, int32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWpSecurityContextManagerV1*)> destroy;
        F<void(CWpSecurityContextManagerV1*, uint32_t, int32_t, int32_t)> createListener;
    } requests;

    void onDestroyCalled();

    F<void(CWpSecurityContextManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpSecurityContextManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWpSecurityContextV1DestroyWrapper {
    wl_listener listener;
    CWpSecurityContextV1* parent = nullptr;
};
            

class CWpSecurityContextV1 {
  public:
    CWpSecurityContextV1(wl_client* client, uint32_t version, uint32_t id);
    ~CWpSecurityContextV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpSecurityContextV1*)> handler) {
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

    void setDestroy(F<void(CWpSecurityContextV1*)> handler);
    void setSetSandboxEngine(F<void(CWpSecurityContextV1*, const char*)> handler);
    void setSetAppId(F<void(CWpSecurityContextV1*, const char*)> handler);
    void setSetInstanceId(F<void(CWpSecurityContextV1*, const char*)> handler);
    void setCommit(F<void(CWpSecurityContextV1*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWpSecurityContextV1*)> destroy;
        F<void(CWpSecurityContextV1*, const char*)> setSandboxEngine;
        F<void(CWpSecurityContextV1*, const char*)> setAppId;
        F<void(CWpSecurityContextV1*, const char*)> setInstanceId;
        F<void(CWpSecurityContextV1*)> commit;
    } requests;

    void onDestroyCalled();

    F<void(CWpSecurityContextV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpSecurityContextV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
