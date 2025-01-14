// Generated with hyprwayland-scanner 0.4.2. Made with vaxry's keyboard and ❤️.
// ext_foreign_toplevel_list_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2018 Ilia Bozhinov
    Copyright © 2020 Isaac Freund
    Copyright © 2022 wb9688
    Copyright © 2023 i509VCB

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


class CExtForeignToplevelListV1;
class CExtForeignToplevelHandleV1;
class CExtForeignToplevelHandleV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface ext_foreign_toplevel_list_v1_interface;
extern const wl_interface ext_foreign_toplevel_handle_v1_interface;

#endif

struct CExtForeignToplevelListV1DestroyWrapper {
    wl_listener listener;
    CExtForeignToplevelListV1* parent = nullptr;
};
            

class CExtForeignToplevelListV1 {
  public:
    CExtForeignToplevelListV1(wl_client* client, uint32_t version, uint32_t id);
    ~CExtForeignToplevelListV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CExtForeignToplevelListV1*)> handler) {
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

    void setStop(F<void(CExtForeignToplevelListV1*)> handler);
    void setDestroy(F<void(CExtForeignToplevelListV1*)> handler);

    // --------------- Events --------------- //

    void sendToplevel(CExtForeignToplevelHandleV1*);
    void sendFinished();
    void sendToplevelRaw(CExtForeignToplevelHandleV1*);
    void sendFinishedRaw();

  private:
    struct {
        F<void(CExtForeignToplevelListV1*)> stop;
        F<void(CExtForeignToplevelListV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CExtForeignToplevelListV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CExtForeignToplevelListV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CExtForeignToplevelHandleV1DestroyWrapper {
    wl_listener listener;
    CExtForeignToplevelHandleV1* parent = nullptr;
};
            

class CExtForeignToplevelHandleV1 {
  public:
    CExtForeignToplevelHandleV1(wl_client* client, uint32_t version, uint32_t id);
    ~CExtForeignToplevelHandleV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CExtForeignToplevelHandleV1*)> handler) {
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

    void setDestroy(F<void(CExtForeignToplevelHandleV1*)> handler);

    // --------------- Events --------------- //

    void sendClosed();
    void sendDone();
    void sendTitle(const char*);
    void sendAppId(const char*);
    void sendIdentifier(const char*);
    void sendClosedRaw();
    void sendDoneRaw();
    void sendTitleRaw(const char*);
    void sendAppIdRaw(const char*);
    void sendIdentifierRaw(const char*);

  private:
    struct {
        F<void(CExtForeignToplevelHandleV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CExtForeignToplevelHandleV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CExtForeignToplevelHandleV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
