// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// wayland

/*
 This protocol's authors' copyright notice is:


    Copyright © 2008-2011 Kristian Høgsberg
    Copyright © 2010-2011 Intel Corporation
    Copyright © 2012-2013 Collabora, Ltd.

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation files
    (the "Software"), to deal in the Software without restriction,
    including without limitation the rights to use, copy, modify, merge,
    publish, distribute, sublicense, and/or sell copies of the Software,
    and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

    The above copyright notice and this permission notice (including the
    next paragraph) shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
    BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
    ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
  
*/

#pragma once

#include <functional>
#include <cstdint>
#include <string>
#include <wayland-server.h>

#define F std::function

struct wl_client;
struct wl_resource;


class CWlDisplay;
class CWlCallback;
class CWlRegistry;
class CWlRegistry;
class CWlCallback;
class CWlCompositor;
class CWlSurface;
class CWlRegion;
class CWlShmPool;
class CWlBuffer;
class CWlShm;
class CWlShmPool;
class CWlBuffer;
class CWlDataOffer;
class CWlDataSource;
class CWlDataDevice;
class CWlDataSource;
class CWlSurface;
class CWlSurface;
class CWlDataSource;
class CWlDataOffer;
class CWlSurface;
class CWlDataOffer;
class CWlDataOffer;
class CWlDataDeviceManager;
class CWlDataSource;
class CWlDataDevice;
class CWlSeat;
class CWlShell;
class CWlShellSurface;
class CWlSurface;
class CWlShellSurface;
class CWlSeat;
class CWlSeat;
class CWlSurface;
class CWlOutput;
class CWlSeat;
class CWlSurface;
class CWlOutput;
class CWlSurface;
class CWlBuffer;
class CWlCallback;
class CWlRegion;
class CWlRegion;
class CWlOutput;
class CWlOutput;
class CWlSeat;
class CWlPointer;
class CWlKeyboard;
class CWlTouch;
class CWlPointer;
class CWlSurface;
class CWlSurface;
class CWlSurface;
class CWlKeyboard;
class CWlSurface;
class CWlSurface;
class CWlTouch;
class CWlSurface;
class CWlOutput;
class CWlRegion;
class CWlSubcompositor;
class CWlSubsurface;
class CWlSurface;
class CWlSurface;
class CWlSubsurface;
class CWlSurface;
class CWlSurface;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface wl_display_interface;
extern const wl_interface wl_registry_interface;
extern const wl_interface wl_callback_interface;
extern const wl_interface wl_compositor_interface;
extern const wl_interface wl_shm_pool_interface;
extern const wl_interface wl_shm_interface;
extern const wl_interface wl_buffer_interface;
extern const wl_interface wl_data_offer_interface;
extern const wl_interface wl_data_source_interface;
extern const wl_interface wl_data_device_interface;
extern const wl_interface wl_data_device_manager_interface;
extern const wl_interface wl_shell_interface;
extern const wl_interface wl_shell_surface_interface;
extern const wl_interface wl_surface_interface;
extern const wl_interface wl_seat_interface;
extern const wl_interface wl_pointer_interface;
extern const wl_interface wl_keyboard_interface;
extern const wl_interface wl_touch_interface;
extern const wl_interface wl_output_interface;
extern const wl_interface wl_region_interface;
extern const wl_interface wl_subcompositor_interface;
extern const wl_interface wl_subsurface_interface;

#endif

struct CWlDisplayDestroyWrapper {
    wl_listener listener;
    CWlDisplay* parent = nullptr;
};
            

class CWlDisplay {
  public:
    CWlDisplay(wl_client* client, uint32_t version, uint32_t id);
    ~CWlDisplay();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlDisplay*)> handler) {
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

    void setSync(F<void(CWlDisplay*, uint32_t)> handler);
    void setGetRegistry(F<void(CWlDisplay*, uint32_t)> handler);

    // --------------- Events --------------- //

    void sendError(wl_resource*, uint32_t, const char*);
    void sendDeleteId(uint32_t);
    void sendErrorRaw(wl_resource*, uint32_t, const char*);
    void sendDeleteIdRaw(uint32_t);

  private:
    struct {
        F<void(CWlDisplay*, uint32_t)> sync;
        F<void(CWlDisplay*, uint32_t)> getRegistry;
    } requests;

    void onDestroyCalled();

    F<void(CWlDisplay*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlDisplayDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlRegistryDestroyWrapper {
    wl_listener listener;
    CWlRegistry* parent = nullptr;
};
            

class CWlRegistry {
  public:
    CWlRegistry(wl_client* client, uint32_t version, uint32_t id);
    ~CWlRegistry();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlRegistry*)> handler) {
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

    void setBind(F<void(CWlRegistry*, uint32_t, uint32_t)> handler);

    // --------------- Events --------------- //

    void sendGlobal(uint32_t, const char*, uint32_t);
    void sendGlobalRemove(uint32_t);
    void sendGlobalRaw(uint32_t, const char*, uint32_t);
    void sendGlobalRemoveRaw(uint32_t);

  private:
    struct {
        F<void(CWlRegistry*, uint32_t, uint32_t)> bind;
    } requests;

    void onDestroyCalled();

    F<void(CWlRegistry*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlRegistryDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlCallbackDestroyWrapper {
    wl_listener listener;
    CWlCallback* parent = nullptr;
};
            

class CWlCallback {
  public:
    CWlCallback(wl_client* client, uint32_t version, uint32_t id);
    ~CWlCallback();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlCallback*)> handler) {
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


    // --------------- Events --------------- //

    void sendDone(uint32_t);
    void sendDoneRaw(uint32_t);

  private:
    struct {
    } requests;

    void onDestroyCalled();

    F<void(CWlCallback*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlCallbackDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlCompositorDestroyWrapper {
    wl_listener listener;
    CWlCompositor* parent = nullptr;
};
            

class CWlCompositor {
  public:
    CWlCompositor(wl_client* client, uint32_t version, uint32_t id);
    ~CWlCompositor();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlCompositor*)> handler) {
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

    void setCreateSurface(F<void(CWlCompositor*, uint32_t)> handler);
    void setCreateRegion(F<void(CWlCompositor*, uint32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWlCompositor*, uint32_t)> createSurface;
        F<void(CWlCompositor*, uint32_t)> createRegion;
    } requests;

    void onDestroyCalled();

    F<void(CWlCompositor*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlCompositorDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlShmPoolDestroyWrapper {
    wl_listener listener;
    CWlShmPool* parent = nullptr;
};
            

class CWlShmPool {
  public:
    CWlShmPool(wl_client* client, uint32_t version, uint32_t id);
    ~CWlShmPool();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlShmPool*)> handler) {
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

    void setCreateBuffer(F<void(CWlShmPool*, uint32_t, int32_t, int32_t, int32_t, int32_t, uint32_t)> handler);
    void setDestroy(F<void(CWlShmPool*)> handler);
    void setResize(F<void(CWlShmPool*, int32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWlShmPool*, uint32_t, int32_t, int32_t, int32_t, int32_t, uint32_t)> createBuffer;
        F<void(CWlShmPool*)> destroy;
        F<void(CWlShmPool*, int32_t)> resize;
    } requests;

    void onDestroyCalled();

    F<void(CWlShmPool*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlShmPoolDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlShmDestroyWrapper {
    wl_listener listener;
    CWlShm* parent = nullptr;
};
            

class CWlShm {
  public:
    CWlShm(wl_client* client, uint32_t version, uint32_t id);
    ~CWlShm();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlShm*)> handler) {
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

    void setCreatePool(F<void(CWlShm*, uint32_t, int32_t, int32_t)> handler);
    void setRelease(F<void(CWlShm*)> handler);

    // --------------- Events --------------- //

    void sendFormat(enum wl_shm_format);
    void sendFormatRaw(enum wl_shm_format);

  private:
    struct {
        F<void(CWlShm*, uint32_t, int32_t, int32_t)> createPool;
        F<void(CWlShm*)> release;
    } requests;

    void onDestroyCalled();

    F<void(CWlShm*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlShmDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlBufferDestroyWrapper {
    wl_listener listener;
    CWlBuffer* parent = nullptr;
};
            

class CWlBuffer {
  public:
    CWlBuffer(wl_client* client, uint32_t version, uint32_t id);
    ~CWlBuffer();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlBuffer*)> handler) {
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

    void setDestroy(F<void(CWlBuffer*)> handler);

    // --------------- Events --------------- //

    void sendRelease();
    void sendReleaseRaw();

  private:
    struct {
        F<void(CWlBuffer*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CWlBuffer*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlBufferDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlDataOfferDestroyWrapper {
    wl_listener listener;
    CWlDataOffer* parent = nullptr;
};
            

class CWlDataOffer {
  public:
    CWlDataOffer(wl_client* client, uint32_t version, uint32_t id);
    ~CWlDataOffer();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlDataOffer*)> handler) {
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

    void setAccept(F<void(CWlDataOffer*, uint32_t, const char*)> handler);
    void setReceive(F<void(CWlDataOffer*, const char*, int32_t)> handler);
    void setDestroy(F<void(CWlDataOffer*)> handler);
    void setFinish(F<void(CWlDataOffer*)> handler);
    void setSetActions(F<void(CWlDataOffer*, uint32_t, uint32_t)> handler);

    // --------------- Events --------------- //

    void sendOffer(const char*);
    void sendSourceActions(uint32_t);
    void sendAction(uint32_t);
    void sendOfferRaw(const char*);
    void sendSourceActionsRaw(uint32_t);
    void sendActionRaw(uint32_t);

  private:
    struct {
        F<void(CWlDataOffer*, uint32_t, const char*)> accept;
        F<void(CWlDataOffer*, const char*, int32_t)> receive;
        F<void(CWlDataOffer*)> destroy;
        F<void(CWlDataOffer*)> finish;
        F<void(CWlDataOffer*, uint32_t, uint32_t)> setActions;
    } requests;

    void onDestroyCalled();

    F<void(CWlDataOffer*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlDataOfferDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlDataSourceDestroyWrapper {
    wl_listener listener;
    CWlDataSource* parent = nullptr;
};
            

class CWlDataSource {
  public:
    CWlDataSource(wl_client* client, uint32_t version, uint32_t id);
    ~CWlDataSource();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlDataSource*)> handler) {
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

    void setOffer(F<void(CWlDataSource*, const char*)> handler);
    void setDestroy(F<void(CWlDataSource*)> handler);
    void setSetActions(F<void(CWlDataSource*, uint32_t)> handler);

    // --------------- Events --------------- //

    void sendTarget(const char*);
    void sendSend(const char*, int32_t);
    void sendCancelled();
    void sendDndDropPerformed();
    void sendDndFinished();
    void sendAction(uint32_t);
    void sendTargetRaw(const char*);
    void sendSendRaw(const char*, int32_t);
    void sendCancelledRaw();
    void sendDndDropPerformedRaw();
    void sendDndFinishedRaw();
    void sendActionRaw(uint32_t);

  private:
    struct {
        F<void(CWlDataSource*, const char*)> offer;
        F<void(CWlDataSource*)> destroy;
        F<void(CWlDataSource*, uint32_t)> setActions;
    } requests;

    void onDestroyCalled();

    F<void(CWlDataSource*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlDataSourceDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlDataDeviceDestroyWrapper {
    wl_listener listener;
    CWlDataDevice* parent = nullptr;
};
            

class CWlDataDevice {
  public:
    CWlDataDevice(wl_client* client, uint32_t version, uint32_t id);
    ~CWlDataDevice();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlDataDevice*)> handler) {
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

    void setStartDrag(F<void(CWlDataDevice*, wl_resource*, wl_resource*, wl_resource*, uint32_t)> handler);
    void setSetSelection(F<void(CWlDataDevice*, wl_resource*, uint32_t)> handler);
    void setRelease(F<void(CWlDataDevice*)> handler);

    // --------------- Events --------------- //

    void sendDataOffer(CWlDataOffer*);
    void sendEnter(uint32_t, CWlSurface*, wl_fixed_t, wl_fixed_t, CWlDataOffer*);
    void sendLeave();
    void sendMotion(uint32_t, wl_fixed_t, wl_fixed_t);
    void sendDrop();
    void sendSelection(CWlDataOffer*);
    void sendDataOfferRaw(CWlDataOffer*);
    void sendEnterRaw(uint32_t, wl_resource*, wl_fixed_t, wl_fixed_t, wl_resource*);
    void sendLeaveRaw();
    void sendMotionRaw(uint32_t, wl_fixed_t, wl_fixed_t);
    void sendDropRaw();
    void sendSelectionRaw(wl_resource*);

  private:
    struct {
        F<void(CWlDataDevice*, wl_resource*, wl_resource*, wl_resource*, uint32_t)> startDrag;
        F<void(CWlDataDevice*, wl_resource*, uint32_t)> setSelection;
        F<void(CWlDataDevice*)> release;
    } requests;

    void onDestroyCalled();

    F<void(CWlDataDevice*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlDataDeviceDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlDataDeviceManagerDestroyWrapper {
    wl_listener listener;
    CWlDataDeviceManager* parent = nullptr;
};
            

class CWlDataDeviceManager {
  public:
    CWlDataDeviceManager(wl_client* client, uint32_t version, uint32_t id);
    ~CWlDataDeviceManager();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlDataDeviceManager*)> handler) {
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

    void setCreateDataSource(F<void(CWlDataDeviceManager*, uint32_t)> handler);
    void setGetDataDevice(F<void(CWlDataDeviceManager*, uint32_t, wl_resource*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWlDataDeviceManager*, uint32_t)> createDataSource;
        F<void(CWlDataDeviceManager*, uint32_t, wl_resource*)> getDataDevice;
    } requests;

    void onDestroyCalled();

    F<void(CWlDataDeviceManager*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlDataDeviceManagerDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlShellDestroyWrapper {
    wl_listener listener;
    CWlShell* parent = nullptr;
};
            

class CWlShell {
  public:
    CWlShell(wl_client* client, uint32_t version, uint32_t id);
    ~CWlShell();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlShell*)> handler) {
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

    void setGetShellSurface(F<void(CWlShell*, uint32_t, wl_resource*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWlShell*, uint32_t, wl_resource*)> getShellSurface;
    } requests;

    void onDestroyCalled();

    F<void(CWlShell*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlShellDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlShellSurfaceDestroyWrapper {
    wl_listener listener;
    CWlShellSurface* parent = nullptr;
};
            

class CWlShellSurface {
  public:
    CWlShellSurface(wl_client* client, uint32_t version, uint32_t id);
    ~CWlShellSurface();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlShellSurface*)> handler) {
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

    void setPong(F<void(CWlShellSurface*, uint32_t)> handler);
    void setMove(F<void(CWlShellSurface*, wl_resource*, uint32_t)> handler);
    void setResize(F<void(CWlShellSurface*, wl_resource*, uint32_t, enum wl_shell_surface_resize)> handler);
    void setSetToplevel(F<void(CWlShellSurface*)> handler);
    void setSetTransient(F<void(CWlShellSurface*, wl_resource*, int32_t, int32_t, enum wl_shell_surface_transient)> handler);
    void setSetFullscreen(F<void(CWlShellSurface*, enum wl_shell_surface_fullscreen_method, uint32_t, wl_resource*)> handler);
    void setSetPopup(F<void(CWlShellSurface*, wl_resource*, uint32_t, wl_resource*, int32_t, int32_t, enum wl_shell_surface_transient)> handler);
    void setSetMaximized(F<void(CWlShellSurface*, wl_resource*)> handler);
    void setSetTitle(F<void(CWlShellSurface*, const char*)> handler);
    void setSetClass(F<void(CWlShellSurface*, const char*)> handler);

    // --------------- Events --------------- //

    void sendPing(uint32_t);
    void sendConfigure(enum wl_shell_surface_resize, int32_t, int32_t);
    void sendPopupDone();
    void sendPingRaw(uint32_t);
    void sendConfigureRaw(enum wl_shell_surface_resize, int32_t, int32_t);
    void sendPopupDoneRaw();

  private:
    struct {
        F<void(CWlShellSurface*, uint32_t)> pong;
        F<void(CWlShellSurface*, wl_resource*, uint32_t)> move;
        F<void(CWlShellSurface*, wl_resource*, uint32_t, enum wl_shell_surface_resize)> resize;
        F<void(CWlShellSurface*)> setToplevel;
        F<void(CWlShellSurface*, wl_resource*, int32_t, int32_t, enum wl_shell_surface_transient)> setTransient;
        F<void(CWlShellSurface*, enum wl_shell_surface_fullscreen_method, uint32_t, wl_resource*)> setFullscreen;
        F<void(CWlShellSurface*, wl_resource*, uint32_t, wl_resource*, int32_t, int32_t, enum wl_shell_surface_transient)> setPopup;
        F<void(CWlShellSurface*, wl_resource*)> setMaximized;
        F<void(CWlShellSurface*, const char*)> setTitle;
        F<void(CWlShellSurface*, const char*)> setClass;
    } requests;

    void onDestroyCalled();

    F<void(CWlShellSurface*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlShellSurfaceDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlSurfaceDestroyWrapper {
    wl_listener listener;
    CWlSurface* parent = nullptr;
};
            

class CWlSurface {
  public:
    CWlSurface(wl_client* client, uint32_t version, uint32_t id);
    ~CWlSurface();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlSurface*)> handler) {
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

    void setDestroy(F<void(CWlSurface*)> handler);
    void setAttach(F<void(CWlSurface*, wl_resource*, int32_t, int32_t)> handler);
    void setDamage(F<void(CWlSurface*, int32_t, int32_t, int32_t, int32_t)> handler);
    void setFrame(F<void(CWlSurface*, uint32_t)> handler);
    void setSetOpaqueRegion(F<void(CWlSurface*, wl_resource*)> handler);
    void setSetInputRegion(F<void(CWlSurface*, wl_resource*)> handler);
    void setCommit(F<void(CWlSurface*)> handler);
    void setSetBufferTransform(F<void(CWlSurface*, int32_t)> handler);
    void setSetBufferScale(F<void(CWlSurface*, int32_t)> handler);
    void setDamageBuffer(F<void(CWlSurface*, int32_t, int32_t, int32_t, int32_t)> handler);
    void setOffset(F<void(CWlSurface*, int32_t, int32_t)> handler);

    // --------------- Events --------------- //

    void sendEnter(CWlOutput*);
    void sendLeave(CWlOutput*);
    void sendPreferredBufferScale(int32_t);
    void sendPreferredBufferTransform(uint32_t);
    void sendEnterRaw(wl_resource*);
    void sendLeaveRaw(wl_resource*);
    void sendPreferredBufferScaleRaw(int32_t);
    void sendPreferredBufferTransformRaw(uint32_t);

  private:
    struct {
        F<void(CWlSurface*)> destroy;
        F<void(CWlSurface*, wl_resource*, int32_t, int32_t)> attach;
        F<void(CWlSurface*, int32_t, int32_t, int32_t, int32_t)> damage;
        F<void(CWlSurface*, uint32_t)> frame;
        F<void(CWlSurface*, wl_resource*)> setOpaqueRegion;
        F<void(CWlSurface*, wl_resource*)> setInputRegion;
        F<void(CWlSurface*)> commit;
        F<void(CWlSurface*, int32_t)> setBufferTransform;
        F<void(CWlSurface*, int32_t)> setBufferScale;
        F<void(CWlSurface*, int32_t, int32_t, int32_t, int32_t)> damageBuffer;
        F<void(CWlSurface*, int32_t, int32_t)> offset;
    } requests;

    void onDestroyCalled();

    F<void(CWlSurface*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlSurfaceDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlSeatDestroyWrapper {
    wl_listener listener;
    CWlSeat* parent = nullptr;
};
            

class CWlSeat {
  public:
    CWlSeat(wl_client* client, uint32_t version, uint32_t id);
    ~CWlSeat();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlSeat*)> handler) {
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

    void setGetPointer(F<void(CWlSeat*, uint32_t)> handler);
    void setGetKeyboard(F<void(CWlSeat*, uint32_t)> handler);
    void setGetTouch(F<void(CWlSeat*, uint32_t)> handler);
    void setRelease(F<void(CWlSeat*)> handler);

    // --------------- Events --------------- //

    void sendCapabilities(enum wl_seat_capability);
    void sendName(const char*);
    void sendCapabilitiesRaw(enum wl_seat_capability);
    void sendNameRaw(const char*);

  private:
    struct {
        F<void(CWlSeat*, uint32_t)> getPointer;
        F<void(CWlSeat*, uint32_t)> getKeyboard;
        F<void(CWlSeat*, uint32_t)> getTouch;
        F<void(CWlSeat*)> release;
    } requests;

    void onDestroyCalled();

    F<void(CWlSeat*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlSeatDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlPointerDestroyWrapper {
    wl_listener listener;
    CWlPointer* parent = nullptr;
};
            

class CWlPointer {
  public:
    CWlPointer(wl_client* client, uint32_t version, uint32_t id);
    ~CWlPointer();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlPointer*)> handler) {
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

    void setSetCursor(F<void(CWlPointer*, uint32_t, wl_resource*, int32_t, int32_t)> handler);
    void setRelease(F<void(CWlPointer*)> handler);

    // --------------- Events --------------- //

    void sendEnter(uint32_t, CWlSurface*, wl_fixed_t, wl_fixed_t);
    void sendLeave(uint32_t, CWlSurface*);
    void sendMotion(uint32_t, wl_fixed_t, wl_fixed_t);
    void sendButton(uint32_t, uint32_t, uint32_t, enum wl_pointer_button_state);
    void sendAxis(uint32_t, enum wl_pointer_axis, wl_fixed_t);
    void sendFrame();
    void sendAxisSource(enum wl_pointer_axis_source);
    void sendAxisStop(uint32_t, enum wl_pointer_axis);
    void sendAxisDiscrete(enum wl_pointer_axis, int32_t);
    void sendAxisValue120(enum wl_pointer_axis, int32_t);
    void sendAxisRelativeDirection(enum wl_pointer_axis, enum wl_pointer_axis_relative_direction);
    void sendEnterRaw(uint32_t, wl_resource*, wl_fixed_t, wl_fixed_t);
    void sendLeaveRaw(uint32_t, wl_resource*);
    void sendMotionRaw(uint32_t, wl_fixed_t, wl_fixed_t);
    void sendButtonRaw(uint32_t, uint32_t, uint32_t, enum wl_pointer_button_state);
    void sendAxisRaw(uint32_t, enum wl_pointer_axis, wl_fixed_t);
    void sendFrameRaw();
    void sendAxisSourceRaw(enum wl_pointer_axis_source);
    void sendAxisStopRaw(uint32_t, enum wl_pointer_axis);
    void sendAxisDiscreteRaw(enum wl_pointer_axis, int32_t);
    void sendAxisValue120Raw(enum wl_pointer_axis, int32_t);
    void sendAxisRelativeDirectionRaw(enum wl_pointer_axis, enum wl_pointer_axis_relative_direction);

  private:
    struct {
        F<void(CWlPointer*, uint32_t, wl_resource*, int32_t, int32_t)> setCursor;
        F<void(CWlPointer*)> release;
    } requests;

    void onDestroyCalled();

    F<void(CWlPointer*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlPointerDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlKeyboardDestroyWrapper {
    wl_listener listener;
    CWlKeyboard* parent = nullptr;
};
            

class CWlKeyboard {
  public:
    CWlKeyboard(wl_client* client, uint32_t version, uint32_t id);
    ~CWlKeyboard();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlKeyboard*)> handler) {
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

    void setRelease(F<void(CWlKeyboard*)> handler);

    // --------------- Events --------------- //

    void sendKeymap(enum wl_keyboard_keymap_format, int32_t, uint32_t);
    void sendEnter(uint32_t, CWlSurface*, wl_array*);
    void sendLeave(uint32_t, CWlSurface*);
    void sendKey(uint32_t, uint32_t, uint32_t, enum wl_keyboard_key_state);
    void sendModifiers(uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);
    void sendRepeatInfo(int32_t, int32_t);
    void sendKeymapRaw(enum wl_keyboard_keymap_format, int32_t, uint32_t);
    void sendEnterRaw(uint32_t, wl_resource*, wl_array*);
    void sendLeaveRaw(uint32_t, wl_resource*);
    void sendKeyRaw(uint32_t, uint32_t, uint32_t, enum wl_keyboard_key_state);
    void sendModifiersRaw(uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);
    void sendRepeatInfoRaw(int32_t, int32_t);

  private:
    struct {
        F<void(CWlKeyboard*)> release;
    } requests;

    void onDestroyCalled();

    F<void(CWlKeyboard*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlKeyboardDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlTouchDestroyWrapper {
    wl_listener listener;
    CWlTouch* parent = nullptr;
};
            

class CWlTouch {
  public:
    CWlTouch(wl_client* client, uint32_t version, uint32_t id);
    ~CWlTouch();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlTouch*)> handler) {
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

    void setRelease(F<void(CWlTouch*)> handler);

    // --------------- Events --------------- //

    void sendDown(uint32_t, uint32_t, CWlSurface*, int32_t, wl_fixed_t, wl_fixed_t);
    void sendUp(uint32_t, uint32_t, int32_t);
    void sendMotion(uint32_t, int32_t, wl_fixed_t, wl_fixed_t);
    void sendFrame();
    void sendCancel();
    void sendShape(int32_t, wl_fixed_t, wl_fixed_t);
    void sendOrientation(int32_t, wl_fixed_t);
    void sendDownRaw(uint32_t, uint32_t, wl_resource*, int32_t, wl_fixed_t, wl_fixed_t);
    void sendUpRaw(uint32_t, uint32_t, int32_t);
    void sendMotionRaw(uint32_t, int32_t, wl_fixed_t, wl_fixed_t);
    void sendFrameRaw();
    void sendCancelRaw();
    void sendShapeRaw(int32_t, wl_fixed_t, wl_fixed_t);
    void sendOrientationRaw(int32_t, wl_fixed_t);

  private:
    struct {
        F<void(CWlTouch*)> release;
    } requests;

    void onDestroyCalled();

    F<void(CWlTouch*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlTouchDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlOutputDestroyWrapper {
    wl_listener listener;
    CWlOutput* parent = nullptr;
};
            

class CWlOutput {
  public:
    CWlOutput(wl_client* client, uint32_t version, uint32_t id);
    ~CWlOutput();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlOutput*)> handler) {
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

    void setRelease(F<void(CWlOutput*)> handler);

    // --------------- Events --------------- //

    void sendGeometry(int32_t, int32_t, int32_t, int32_t, int32_t, const char*, const char*, int32_t);
    void sendMode(enum wl_output_mode, int32_t, int32_t, int32_t);
    void sendDone();
    void sendScale(int32_t);
    void sendName(const char*);
    void sendDescription(const char*);
    void sendGeometryRaw(int32_t, int32_t, int32_t, int32_t, int32_t, const char*, const char*, int32_t);
    void sendModeRaw(enum wl_output_mode, int32_t, int32_t, int32_t);
    void sendDoneRaw();
    void sendScaleRaw(int32_t);
    void sendNameRaw(const char*);
    void sendDescriptionRaw(const char*);

  private:
    struct {
        F<void(CWlOutput*)> release;
    } requests;

    void onDestroyCalled();

    F<void(CWlOutput*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlOutputDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlRegionDestroyWrapper {
    wl_listener listener;
    CWlRegion* parent = nullptr;
};
            

class CWlRegion {
  public:
    CWlRegion(wl_client* client, uint32_t version, uint32_t id);
    ~CWlRegion();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlRegion*)> handler) {
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

    void setDestroy(F<void(CWlRegion*)> handler);
    void setAdd(F<void(CWlRegion*, int32_t, int32_t, int32_t, int32_t)> handler);
    void setSubtract(F<void(CWlRegion*, int32_t, int32_t, int32_t, int32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWlRegion*)> destroy;
        F<void(CWlRegion*, int32_t, int32_t, int32_t, int32_t)> add;
        F<void(CWlRegion*, int32_t, int32_t, int32_t, int32_t)> subtract;
    } requests;

    void onDestroyCalled();

    F<void(CWlRegion*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlRegionDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlSubcompositorDestroyWrapper {
    wl_listener listener;
    CWlSubcompositor* parent = nullptr;
};
            

class CWlSubcompositor {
  public:
    CWlSubcompositor(wl_client* client, uint32_t version, uint32_t id);
    ~CWlSubcompositor();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlSubcompositor*)> handler) {
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

    void setDestroy(F<void(CWlSubcompositor*)> handler);
    void setGetSubsurface(F<void(CWlSubcompositor*, uint32_t, wl_resource*, wl_resource*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWlSubcompositor*)> destroy;
        F<void(CWlSubcompositor*, uint32_t, wl_resource*, wl_resource*)> getSubsurface;
    } requests;

    void onDestroyCalled();

    F<void(CWlSubcompositor*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlSubcompositorDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWlSubsurfaceDestroyWrapper {
    wl_listener listener;
    CWlSubsurface* parent = nullptr;
};
            

class CWlSubsurface {
  public:
    CWlSubsurface(wl_client* client, uint32_t version, uint32_t id);
    ~CWlSubsurface();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWlSubsurface*)> handler) {
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

    void setDestroy(F<void(CWlSubsurface*)> handler);
    void setSetPosition(F<void(CWlSubsurface*, int32_t, int32_t)> handler);
    void setPlaceAbove(F<void(CWlSubsurface*, wl_resource*)> handler);
    void setPlaceBelow(F<void(CWlSubsurface*, wl_resource*)> handler);
    void setSetSync(F<void(CWlSubsurface*)> handler);
    void setSetDesync(F<void(CWlSubsurface*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CWlSubsurface*)> destroy;
        F<void(CWlSubsurface*, int32_t, int32_t)> setPosition;
        F<void(CWlSubsurface*, wl_resource*)> placeAbove;
        F<void(CWlSubsurface*, wl_resource*)> placeBelow;
        F<void(CWlSubsurface*)> setSync;
        F<void(CWlSubsurface*)> setDesync;
    } requests;

    void onDestroyCalled();

    F<void(CWlSubsurface*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWlSubsurfaceDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
