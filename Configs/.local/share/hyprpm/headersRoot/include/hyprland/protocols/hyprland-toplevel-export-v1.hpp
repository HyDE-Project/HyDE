// Generated with hyprwayland-scanner 0.4.2. Made with vaxry's keyboard and ❤️.
// hyprland_toplevel_export_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2022 Vaxry
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this
       list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions and the following disclaimer in the documentation
       and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its
       contributors may be used to endorse or promote products derived from
       this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  
*/

#pragma once

#include <functional>
#include <cstdint>
#include <string>
#include <wayland-server.h>

#define F std::function

struct wl_client;
struct wl_resource;

enum hyprlandToplevelExportFrameV1Error : uint32_t {
    HYPRLAND_TOPLEVEL_EXPORT_FRAME_V1_ERROR_ALREADY_USED = 0,
    HYPRLAND_TOPLEVEL_EXPORT_FRAME_V1_ERROR_INVALID_BUFFER = 1,
};

enum hyprlandToplevelExportFrameV1Flags : uint32_t {
    HYPRLAND_TOPLEVEL_EXPORT_FRAME_V1_FLAGS_Y_INVERT = 1,
};


class CHyprlandToplevelExportManagerV1;
class CHyprlandToplevelExportFrameV1;
class CHyprlandToplevelExportFrameV1;
class CZwlrForeignToplevelHandleV1;
class CHyprlandToplevelExportFrameV1;
class CWlBuffer;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface hyprland_toplevel_export_manager_v1_interface;
extern const wl_interface hyprland_toplevel_export_frame_v1_interface;

#endif

struct CHyprlandToplevelExportManagerV1DestroyWrapper {
    wl_listener listener;
    CHyprlandToplevelExportManagerV1* parent = nullptr;
};
            

class CHyprlandToplevelExportManagerV1 {
  public:
    CHyprlandToplevelExportManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CHyprlandToplevelExportManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CHyprlandToplevelExportManagerV1*)> handler) {
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

    void setCaptureToplevel(F<void(CHyprlandToplevelExportManagerV1*, uint32_t, int32_t, uint32_t)> handler);
    void setDestroy(F<void(CHyprlandToplevelExportManagerV1*)> handler);
    void setCaptureToplevelWithWlrToplevelHandle(F<void(CHyprlandToplevelExportManagerV1*, uint32_t, int32_t, wl_resource*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CHyprlandToplevelExportManagerV1*, uint32_t, int32_t, uint32_t)> captureToplevel;
        F<void(CHyprlandToplevelExportManagerV1*)> destroy;
        F<void(CHyprlandToplevelExportManagerV1*, uint32_t, int32_t, wl_resource*)> captureToplevelWithWlrToplevelHandle;
    } requests;

    void onDestroyCalled();

    F<void(CHyprlandToplevelExportManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CHyprlandToplevelExportManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CHyprlandToplevelExportFrameV1DestroyWrapper {
    wl_listener listener;
    CHyprlandToplevelExportFrameV1* parent = nullptr;
};
            

class CHyprlandToplevelExportFrameV1 {
  public:
    CHyprlandToplevelExportFrameV1(wl_client* client, uint32_t version, uint32_t id);
    ~CHyprlandToplevelExportFrameV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CHyprlandToplevelExportFrameV1*)> handler) {
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

    void setCopy(F<void(CHyprlandToplevelExportFrameV1*, wl_resource*, int32_t)> handler);
    void setDestroy(F<void(CHyprlandToplevelExportFrameV1*)> handler);

    // --------------- Events --------------- //

    void sendBuffer(uint32_t, uint32_t, uint32_t, uint32_t);
    void sendDamage(uint32_t, uint32_t, uint32_t, uint32_t);
    void sendFlags(hyprlandToplevelExportFrameV1Flags);
    void sendReady(uint32_t, uint32_t, uint32_t);
    void sendFailed();
    void sendLinuxDmabuf(uint32_t, uint32_t, uint32_t);
    void sendBufferDone();
    void sendBufferRaw(uint32_t, uint32_t, uint32_t, uint32_t);
    void sendDamageRaw(uint32_t, uint32_t, uint32_t, uint32_t);
    void sendFlagsRaw(hyprlandToplevelExportFrameV1Flags);
    void sendReadyRaw(uint32_t, uint32_t, uint32_t);
    void sendFailedRaw();
    void sendLinuxDmabufRaw(uint32_t, uint32_t, uint32_t);
    void sendBufferDoneRaw();

  private:
    struct {
        F<void(CHyprlandToplevelExportFrameV1*, wl_resource*, int32_t)> copy;
        F<void(CHyprlandToplevelExportFrameV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CHyprlandToplevelExportFrameV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CHyprlandToplevelExportFrameV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
