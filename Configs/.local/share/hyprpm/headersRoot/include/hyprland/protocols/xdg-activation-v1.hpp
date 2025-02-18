// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// xdg_activation_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2020 Aleix Pol Gonzalez <aleixpol@kde.org>
    Copyright © 2020 Carlos Garnacho <carlosg@gnome.org>

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

enum xdgActivationTokenV1Error : uint32_t {
    XDG_ACTIVATION_TOKEN_V1_ERROR_ALREADY_USED = 0,
};


class CXdgActivationV1;
class CXdgActivationTokenV1;
class CWlSurface;
class CXdgActivationTokenV1;
class CWlSeat;
class CWlSurface;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface xdg_activation_v1_interface;
extern const wl_interface xdg_activation_token_v1_interface;

#endif

struct CXdgActivationV1DestroyWrapper {
    wl_listener listener;
    CXdgActivationV1* parent = nullptr;
};
            

class CXdgActivationV1 {
  public:
    CXdgActivationV1(wl_client* client, uint32_t version, uint32_t id);
    ~CXdgActivationV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CXdgActivationV1*)> handler) {
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

    void setDestroy(F<void(CXdgActivationV1*)> handler);
    void setGetActivationToken(F<void(CXdgActivationV1*, uint32_t)> handler);
    void setActivate(F<void(CXdgActivationV1*, const char*, wl_resource*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CXdgActivationV1*)> destroy;
        F<void(CXdgActivationV1*, uint32_t)> getActivationToken;
        F<void(CXdgActivationV1*, const char*, wl_resource*)> activate;
    } requests;

    void onDestroyCalled();

    F<void(CXdgActivationV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CXdgActivationV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CXdgActivationTokenV1DestroyWrapper {
    wl_listener listener;
    CXdgActivationTokenV1* parent = nullptr;
};
            

class CXdgActivationTokenV1 {
  public:
    CXdgActivationTokenV1(wl_client* client, uint32_t version, uint32_t id);
    ~CXdgActivationTokenV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CXdgActivationTokenV1*)> handler) {
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

    void setSetSerial(F<void(CXdgActivationTokenV1*, uint32_t, wl_resource*)> handler);
    void setSetAppId(F<void(CXdgActivationTokenV1*, const char*)> handler);
    void setSetSurface(F<void(CXdgActivationTokenV1*, wl_resource*)> handler);
    void setCommit(F<void(CXdgActivationTokenV1*)> handler);
    void setDestroy(F<void(CXdgActivationTokenV1*)> handler);

    // --------------- Events --------------- //

    void sendDone(const char*);
    void sendDoneRaw(const char*);

  private:
    struct {
        F<void(CXdgActivationTokenV1*, uint32_t, wl_resource*)> setSerial;
        F<void(CXdgActivationTokenV1*, const char*)> setAppId;
        F<void(CXdgActivationTokenV1*, wl_resource*)> setSurface;
        F<void(CXdgActivationTokenV1*)> commit;
        F<void(CXdgActivationTokenV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CXdgActivationTokenV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CXdgActivationTokenV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
