// Generated with hyprwayland-scanner 0.4.2. Made with vaxry's keyboard and ❤️.
// pointer_constraints_unstable_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2014      Jonas Ådahl
    Copyright © 2015      Red Hat Inc.

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

enum zwpPointerConstraintsV1Error : uint32_t {
    ZWP_POINTER_CONSTRAINTS_V1_ERROR_ALREADY_CONSTRAINED = 1,
};

enum zwpPointerConstraintsV1Lifetime : uint32_t {
    ZWP_POINTER_CONSTRAINTS_V1_LIFETIME_ONESHOT = 1,
    ZWP_POINTER_CONSTRAINTS_V1_LIFETIME_PERSISTENT = 2,
};


class CZwpPointerConstraintsV1;
class CZwpLockedPointerV1;
class CWlSurface;
class CWlPointer;
class CWlRegion;
class CZwpConfinedPointerV1;
class CWlSurface;
class CWlPointer;
class CWlRegion;
class CZwpLockedPointerV1;
class CWlRegion;
class CZwpConfinedPointerV1;
class CWlRegion;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwp_pointer_constraints_v1_interface;
extern const wl_interface zwp_locked_pointer_v1_interface;
extern const wl_interface zwp_confined_pointer_v1_interface;

#endif

struct CZwpPointerConstraintsV1DestroyWrapper {
    wl_listener listener;
    CZwpPointerConstraintsV1* parent = nullptr;
};
            

class CZwpPointerConstraintsV1 {
  public:
    CZwpPointerConstraintsV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpPointerConstraintsV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpPointerConstraintsV1*)> handler) {
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

    void setDestroy(F<void(CZwpPointerConstraintsV1*)> handler);
    void setLockPointer(F<void(CZwpPointerConstraintsV1*, uint32_t, wl_resource*, wl_resource*, wl_resource*, zwpPointerConstraintsV1Lifetime)> handler);
    void setConfinePointer(F<void(CZwpPointerConstraintsV1*, uint32_t, wl_resource*, wl_resource*, wl_resource*, zwpPointerConstraintsV1Lifetime)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwpPointerConstraintsV1*)> destroy;
        F<void(CZwpPointerConstraintsV1*, uint32_t, wl_resource*, wl_resource*, wl_resource*, zwpPointerConstraintsV1Lifetime)> lockPointer;
        F<void(CZwpPointerConstraintsV1*, uint32_t, wl_resource*, wl_resource*, wl_resource*, zwpPointerConstraintsV1Lifetime)> confinePointer;
    } requests;

    void onDestroyCalled();

    F<void(CZwpPointerConstraintsV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpPointerConstraintsV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpLockedPointerV1DestroyWrapper {
    wl_listener listener;
    CZwpLockedPointerV1* parent = nullptr;
};
            

class CZwpLockedPointerV1 {
  public:
    CZwpLockedPointerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpLockedPointerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpLockedPointerV1*)> handler) {
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

    void setDestroy(F<void(CZwpLockedPointerV1*)> handler);
    void setSetCursorPositionHint(F<void(CZwpLockedPointerV1*, wl_fixed_t, wl_fixed_t)> handler);
    void setSetRegion(F<void(CZwpLockedPointerV1*, wl_resource*)> handler);

    // --------------- Events --------------- //

    void sendLocked();
    void sendUnlocked();
    void sendLockedRaw();
    void sendUnlockedRaw();

  private:
    struct {
        F<void(CZwpLockedPointerV1*)> destroy;
        F<void(CZwpLockedPointerV1*, wl_fixed_t, wl_fixed_t)> setCursorPositionHint;
        F<void(CZwpLockedPointerV1*, wl_resource*)> setRegion;
    } requests;

    void onDestroyCalled();

    F<void(CZwpLockedPointerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpLockedPointerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpConfinedPointerV1DestroyWrapper {
    wl_listener listener;
    CZwpConfinedPointerV1* parent = nullptr;
};
            

class CZwpConfinedPointerV1 {
  public:
    CZwpConfinedPointerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpConfinedPointerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpConfinedPointerV1*)> handler) {
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

    void setDestroy(F<void(CZwpConfinedPointerV1*)> handler);
    void setSetRegion(F<void(CZwpConfinedPointerV1*, wl_resource*)> handler);

    // --------------- Events --------------- //

    void sendConfined();
    void sendUnconfined();
    void sendConfinedRaw();
    void sendUnconfinedRaw();

  private:
    struct {
        F<void(CZwpConfinedPointerV1*)> destroy;
        F<void(CZwpConfinedPointerV1*, wl_resource*)> setRegion;
    } requests;

    void onDestroyCalled();

    F<void(CZwpConfinedPointerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpConfinedPointerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
