// Generated with hyprwayland-scanner 0.4.2. Made with vaxry's keyboard and ❤️.
// wlr_output_management_unstable_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2019 Purism SPC

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

enum zwlrOutputHeadV1AdaptiveSyncState : uint32_t {
    ZWLR_OUTPUT_HEAD_V1_ADAPTIVE_SYNC_STATE_DISABLED = 0,
    ZWLR_OUTPUT_HEAD_V1_ADAPTIVE_SYNC_STATE_ENABLED = 1,
};

enum zwlrOutputConfigurationV1Error : uint32_t {
    ZWLR_OUTPUT_CONFIGURATION_V1_ERROR_ALREADY_CONFIGURED_HEAD = 1,
    ZWLR_OUTPUT_CONFIGURATION_V1_ERROR_UNCONFIGURED_HEAD = 2,
    ZWLR_OUTPUT_CONFIGURATION_V1_ERROR_ALREADY_USED = 3,
};

enum zwlrOutputConfigurationHeadV1Error : uint32_t {
    ZWLR_OUTPUT_CONFIGURATION_HEAD_V1_ERROR_ALREADY_SET = 1,
    ZWLR_OUTPUT_CONFIGURATION_HEAD_V1_ERROR_INVALID_MODE = 2,
    ZWLR_OUTPUT_CONFIGURATION_HEAD_V1_ERROR_INVALID_CUSTOM_MODE = 3,
    ZWLR_OUTPUT_CONFIGURATION_HEAD_V1_ERROR_INVALID_TRANSFORM = 4,
    ZWLR_OUTPUT_CONFIGURATION_HEAD_V1_ERROR_INVALID_SCALE = 5,
    ZWLR_OUTPUT_CONFIGURATION_HEAD_V1_ERROR_INVALID_ADAPTIVE_SYNC_STATE = 6,
};


class CZwlrOutputManagerV1;
class CZwlrOutputConfigurationV1;
class CZwlrOutputHeadV1;
class CZwlrOutputHeadV1;
class CZwlrOutputModeV1;
class CZwlrOutputModeV1;
class CZwlrOutputModeV1;
class CZwlrOutputConfigurationV1;
class CZwlrOutputConfigurationHeadV1;
class CZwlrOutputHeadV1;
class CZwlrOutputHeadV1;
class CZwlrOutputConfigurationHeadV1;
class CZwlrOutputModeV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwlr_output_manager_v1_interface;
extern const wl_interface zwlr_output_head_v1_interface;
extern const wl_interface zwlr_output_mode_v1_interface;
extern const wl_interface zwlr_output_configuration_v1_interface;
extern const wl_interface zwlr_output_configuration_head_v1_interface;

#endif

struct CZwlrOutputManagerV1DestroyWrapper {
    wl_listener listener;
    CZwlrOutputManagerV1* parent = nullptr;
};
            

class CZwlrOutputManagerV1 {
  public:
    CZwlrOutputManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrOutputManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrOutputManagerV1*)> handler) {
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

    void setCreateConfiguration(F<void(CZwlrOutputManagerV1*, uint32_t, uint32_t)> handler);
    void setStop(F<void(CZwlrOutputManagerV1*)> handler);

    // --------------- Events --------------- //

    void sendHead(CZwlrOutputHeadV1*);
    void sendDone(uint32_t);
    void sendFinished();
    void sendHeadRaw(CZwlrOutputHeadV1*);
    void sendDoneRaw(uint32_t);
    void sendFinishedRaw();

  private:
    struct {
        F<void(CZwlrOutputManagerV1*, uint32_t, uint32_t)> createConfiguration;
        F<void(CZwlrOutputManagerV1*)> stop;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrOutputManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrOutputManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwlrOutputHeadV1DestroyWrapper {
    wl_listener listener;
    CZwlrOutputHeadV1* parent = nullptr;
};
            

class CZwlrOutputHeadV1 {
  public:
    CZwlrOutputHeadV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrOutputHeadV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrOutputHeadV1*)> handler) {
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

    void setRelease(F<void(CZwlrOutputHeadV1*)> handler);

    // --------------- Events --------------- //

    void sendName(const char*);
    void sendDescription(const char*);
    void sendPhysicalSize(int32_t, int32_t);
    void sendMode(CZwlrOutputModeV1*);
    void sendEnabled(int32_t);
    void sendCurrentMode(CZwlrOutputModeV1*);
    void sendPosition(int32_t, int32_t);
    void sendTransform(int32_t);
    void sendScale(wl_fixed_t);
    void sendFinished();
    void sendMake(const char*);
    void sendModel(const char*);
    void sendSerialNumber(const char*);
    void sendAdaptiveSync(zwlrOutputHeadV1AdaptiveSyncState);
    void sendNameRaw(const char*);
    void sendDescriptionRaw(const char*);
    void sendPhysicalSizeRaw(int32_t, int32_t);
    void sendModeRaw(CZwlrOutputModeV1*);
    void sendEnabledRaw(int32_t);
    void sendCurrentModeRaw(wl_resource*);
    void sendPositionRaw(int32_t, int32_t);
    void sendTransformRaw(int32_t);
    void sendScaleRaw(wl_fixed_t);
    void sendFinishedRaw();
    void sendMakeRaw(const char*);
    void sendModelRaw(const char*);
    void sendSerialNumberRaw(const char*);
    void sendAdaptiveSyncRaw(zwlrOutputHeadV1AdaptiveSyncState);

  private:
    struct {
        F<void(CZwlrOutputHeadV1*)> release;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrOutputHeadV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrOutputHeadV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwlrOutputModeV1DestroyWrapper {
    wl_listener listener;
    CZwlrOutputModeV1* parent = nullptr;
};
            

class CZwlrOutputModeV1 {
  public:
    CZwlrOutputModeV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrOutputModeV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrOutputModeV1*)> handler) {
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

    void setRelease(F<void(CZwlrOutputModeV1*)> handler);

    // --------------- Events --------------- //

    void sendSize(int32_t, int32_t);
    void sendRefresh(int32_t);
    void sendPreferred();
    void sendFinished();
    void sendSizeRaw(int32_t, int32_t);
    void sendRefreshRaw(int32_t);
    void sendPreferredRaw();
    void sendFinishedRaw();

  private:
    struct {
        F<void(CZwlrOutputModeV1*)> release;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrOutputModeV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrOutputModeV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwlrOutputConfigurationV1DestroyWrapper {
    wl_listener listener;
    CZwlrOutputConfigurationV1* parent = nullptr;
};
            

class CZwlrOutputConfigurationV1 {
  public:
    CZwlrOutputConfigurationV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrOutputConfigurationV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrOutputConfigurationV1*)> handler) {
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

    void setEnableHead(F<void(CZwlrOutputConfigurationV1*, uint32_t, wl_resource*)> handler);
    void setDisableHead(F<void(CZwlrOutputConfigurationV1*, wl_resource*)> handler);
    void setApply(F<void(CZwlrOutputConfigurationV1*)> handler);
    void setTest(F<void(CZwlrOutputConfigurationV1*)> handler);
    void setDestroy(F<void(CZwlrOutputConfigurationV1*)> handler);

    // --------------- Events --------------- //

    void sendSucceeded();
    void sendFailed();
    void sendCancelled();
    void sendSucceededRaw();
    void sendFailedRaw();
    void sendCancelledRaw();

  private:
    struct {
        F<void(CZwlrOutputConfigurationV1*, uint32_t, wl_resource*)> enableHead;
        F<void(CZwlrOutputConfigurationV1*, wl_resource*)> disableHead;
        F<void(CZwlrOutputConfigurationV1*)> apply;
        F<void(CZwlrOutputConfigurationV1*)> test;
        F<void(CZwlrOutputConfigurationV1*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrOutputConfigurationV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrOutputConfigurationV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwlrOutputConfigurationHeadV1DestroyWrapper {
    wl_listener listener;
    CZwlrOutputConfigurationHeadV1* parent = nullptr;
};
            

class CZwlrOutputConfigurationHeadV1 {
  public:
    CZwlrOutputConfigurationHeadV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwlrOutputConfigurationHeadV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwlrOutputConfigurationHeadV1*)> handler) {
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

    void setSetMode(F<void(CZwlrOutputConfigurationHeadV1*, wl_resource*)> handler);
    void setSetCustomMode(F<void(CZwlrOutputConfigurationHeadV1*, int32_t, int32_t, int32_t)> handler);
    void setSetPosition(F<void(CZwlrOutputConfigurationHeadV1*, int32_t, int32_t)> handler);
    void setSetTransform(F<void(CZwlrOutputConfigurationHeadV1*, int32_t)> handler);
    void setSetScale(F<void(CZwlrOutputConfigurationHeadV1*, wl_fixed_t)> handler);
    void setSetAdaptiveSync(F<void(CZwlrOutputConfigurationHeadV1*, uint32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwlrOutputConfigurationHeadV1*, wl_resource*)> setMode;
        F<void(CZwlrOutputConfigurationHeadV1*, int32_t, int32_t, int32_t)> setCustomMode;
        F<void(CZwlrOutputConfigurationHeadV1*, int32_t, int32_t)> setPosition;
        F<void(CZwlrOutputConfigurationHeadV1*, int32_t)> setTransform;
        F<void(CZwlrOutputConfigurationHeadV1*, wl_fixed_t)> setScale;
        F<void(CZwlrOutputConfigurationHeadV1*, uint32_t)> setAdaptiveSync;
    } requests;

    void onDestroyCalled();

    F<void(CZwlrOutputConfigurationHeadV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwlrOutputConfigurationHeadV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
