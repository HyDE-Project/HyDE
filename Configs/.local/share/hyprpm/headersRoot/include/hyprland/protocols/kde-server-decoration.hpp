// Generated with hyprwayland-scanner 0.4.2. Made with vaxry's keyboard and ❤️.
// server_decoration

/*
 This protocol's authors' copyright notice is:


    SPDX-FileCopyrightText: 2015 Martin Gräßlin

    SPDX-License-Identifier: LGPL-2.1-or-later
  
*/

#pragma once

#include <functional>
#include <cstdint>
#include <string>
#include <wayland-server.h>

#define F std::function

struct wl_client;
struct wl_resource;

enum orgKdeKwinServerDecorationManagerMode : uint32_t {
    ORG_KDE_KWIN_SERVER_DECORATION_MANAGER_MODE_NONE = 0,
    ORG_KDE_KWIN_SERVER_DECORATION_MANAGER_MODE_CLIENT = 1,
    ORG_KDE_KWIN_SERVER_DECORATION_MANAGER_MODE_SERVER = 2,
};

enum orgKdeKwinServerDecorationMode : uint32_t {
    ORG_KDE_KWIN_SERVER_DECORATION_MODE_NONE = 0,
    ORG_KDE_KWIN_SERVER_DECORATION_MODE_CLIENT = 1,
    ORG_KDE_KWIN_SERVER_DECORATION_MODE_SERVER = 2,
};


class COrgKdeKwinServerDecorationManager;
class COrgKdeKwinServerDecoration;
class CWlSurface;
class COrgKdeKwinServerDecoration;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface org_kde_kwin_server_decoration_manager_interface;
extern const wl_interface org_kde_kwin_server_decoration_interface;

#endif

struct COrgKdeKwinServerDecorationManagerDestroyWrapper {
    wl_listener listener;
    COrgKdeKwinServerDecorationManager* parent = nullptr;
};
            

class COrgKdeKwinServerDecorationManager {
  public:
    COrgKdeKwinServerDecorationManager(wl_client* client, uint32_t version, uint32_t id);
    ~COrgKdeKwinServerDecorationManager();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(COrgKdeKwinServerDecorationManager*)> handler) {
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

    void setCreate(F<void(COrgKdeKwinServerDecorationManager*, uint32_t, wl_resource*)> handler);

    // --------------- Events --------------- //

    void sendDefaultMode(uint32_t);
    void sendDefaultModeRaw(uint32_t);

  private:
    struct {
        F<void(COrgKdeKwinServerDecorationManager*, uint32_t, wl_resource*)> create;
    } requests;

    void onDestroyCalled();

    F<void(COrgKdeKwinServerDecorationManager*)> onDestroy;

    wl_resource* pResource = nullptr;

    COrgKdeKwinServerDecorationManagerDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct COrgKdeKwinServerDecorationDestroyWrapper {
    wl_listener listener;
    COrgKdeKwinServerDecoration* parent = nullptr;
};
            

class COrgKdeKwinServerDecoration {
  public:
    COrgKdeKwinServerDecoration(wl_client* client, uint32_t version, uint32_t id);
    ~COrgKdeKwinServerDecoration();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(COrgKdeKwinServerDecoration*)> handler) {
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

    void setRelease(F<void(COrgKdeKwinServerDecoration*)> handler);
    void setRequestMode(F<void(COrgKdeKwinServerDecoration*, uint32_t)> handler);

    // --------------- Events --------------- //

    void sendMode(uint32_t);
    void sendModeRaw(uint32_t);

  private:
    struct {
        F<void(COrgKdeKwinServerDecoration*)> release;
        F<void(COrgKdeKwinServerDecoration*, uint32_t)> requestMode;
    } requests;

    void onDestroyCalled();

    F<void(COrgKdeKwinServerDecoration*)> onDestroy;

    wl_resource* pResource = nullptr;

    COrgKdeKwinServerDecorationDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
