// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// ext_session_lock_v1

/*
 This protocol's authors' copyright notice is:


    Copyright 2021 Isaac Freund

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
  
*/

#pragma once

#include <functional>
#include <cstdint>
#include <string>
#include <wayland-server.h>

#define F std::function

struct wl_client;
struct wl_resource;

enum extSessionLockV1Error : uint32_t {
    EXT_SESSION_LOCK_V1_ERROR_INVALID_DESTROY = 0,
    EXT_SESSION_LOCK_V1_ERROR_INVALID_UNLOCK = 1,
    EXT_SESSION_LOCK_V1_ERROR_ROLE = 2,
    EXT_SESSION_LOCK_V1_ERROR_DUPLICATE_OUTPUT = 3,
    EXT_SESSION_LOCK_V1_ERROR_ALREADY_CONSTRUCTED = 4,
};

enum extSessionLockSurfaceV1Error : uint32_t {
    EXT_SESSION_LOCK_SURFACE_V1_ERROR_COMMIT_BEFORE_FIRST_ACK = 0,
    EXT_SESSION_LOCK_SURFACE_V1_ERROR_NULL_BUFFER = 1,
    EXT_SESSION_LOCK_SURFACE_V1_ERROR_DIMENSIONS_MISMATCH = 2,
    EXT_SESSION_LOCK_SURFACE_V1_ERROR_INVALID_SERIAL = 3,
};


class CExtSessionLockManagerV1;
class CExtSessionLockV1;
class CExtSessionLockV1;
class CExtSessionLockSurfaceV1;
class CWlSurface;
class CWlOutput;
class CExtSessionLockSurfaceV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface ext_session_lock_manager_v1_interface;
extern const wl_interface ext_session_lock_v1_interface;
extern const wl_interface ext_session_lock_surface_v1_interface;

#endif

struct CExtSessionLockManagerV1DestroyWrapper {
    wl_listener listener;
    CExtSessionLockManagerV1* parent = nullptr;
};
            

class CExtSessionLockManagerV1 {
  public:
    CExtSessionLockManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CExtSessionLockManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CExtSessionLockManagerV1*)> handler) {
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

    void setDestroy(F<void(CExtSessionLockManagerV1*)> handler);
    void setLock(F<void(CExtSessionLockManagerV1*, uint32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CExtSessionLockManagerV1*)> destroy;
        F<void(CExtSessionLockManagerV1*, uint32_t)> lock;
    } requests;

    void onDestroyCalled();

    F<void(CExtSessionLockManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CExtSessionLockManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CExtSessionLockV1DestroyWrapper {
    wl_listener listener;
    CExtSessionLockV1* parent = nullptr;
};
            

class CExtSessionLockV1 {
  public:
    CExtSessionLockV1(wl_client* client, uint32_t version, uint32_t id);
    ~CExtSessionLockV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CExtSessionLockV1*)> handler) {
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

    void setDestroy(F<void(CExtSessionLockV1*)> handler);
    void setGetLockSurface(F<void(CExtSessionLockV1*, uint32_t, wl_resource*, wl_resource*)> handler);
    void setUnlockAndDestroy(F<void(CExtSessionLockV1*)> handler);

    // --------------- Events --------------- //

    void sendLocked();
    void sendFinished();
    void sendLockedRaw();
    void sendFinishedRaw();

  private:
    struct {
        F<void(CExtSessionLockV1*)> destroy;
        F<void(CExtSessionLockV1*, uint32_t, wl_resource*, wl_resource*)> getLockSurface;
        F<void(CExtSessionLockV1*)> unlockAndDestroy;
    } requests;

    void onDestroyCalled();

    F<void(CExtSessionLockV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CExtSessionLockV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CExtSessionLockSurfaceV1DestroyWrapper {
    wl_listener listener;
    CExtSessionLockSurfaceV1* parent = nullptr;
};
            

class CExtSessionLockSurfaceV1 {
  public:
    CExtSessionLockSurfaceV1(wl_client* client, uint32_t version, uint32_t id);
    ~CExtSessionLockSurfaceV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CExtSessionLockSurfaceV1*)> handler) {
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

    void setDestroy(F<void(CExtSessionLockSurfaceV1*)> handler);
    void setAckConfigure(F<void(CExtSessionLockSurfaceV1*, uint32_t)> handler);

    // --------------- Events --------------- //

    void sendConfigure(uint32_t, uint32_t, uint32_t);
    void sendConfigureRaw(uint32_t, uint32_t, uint32_t);

  private:
    struct {
        F<void(CExtSessionLockSurfaceV1*)> destroy;
        F<void(CExtSessionLockSurfaceV1*, uint32_t)> ackConfigure;
    } requests;

    void onDestroyCalled();

    F<void(CExtSessionLockSurfaceV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CExtSessionLockSurfaceV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
