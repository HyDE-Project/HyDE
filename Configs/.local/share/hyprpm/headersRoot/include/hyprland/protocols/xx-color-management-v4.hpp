// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// xx_color_management_v4

/*
 This protocol's authors' copyright notice is:


    Copyright 2019 Sebastian Wick
    Copyright 2019 Erwin Burema
    Copyright 2020 AMD
    Copyright 2020-2024 Collabora, Ltd.
    Copyright 2024 Xaver Hugl

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
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
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

enum xxColorManagerV4Error : uint32_t {
    XX_COLOR_MANAGER_V4_ERROR_UNSUPPORTED_FEATURE = 0,
    XX_COLOR_MANAGER_V4_ERROR_SURFACE_EXISTS = 1,
};

enum xxColorManagerV4RenderIntent : uint32_t {
    XX_COLOR_MANAGER_V4_RENDER_INTENT_PERCEPTUAL = 0,
    XX_COLOR_MANAGER_V4_RENDER_INTENT_RELATIVE = 1,
    XX_COLOR_MANAGER_V4_RENDER_INTENT_SATURATION = 2,
    XX_COLOR_MANAGER_V4_RENDER_INTENT_ABSOLUTE = 3,
    XX_COLOR_MANAGER_V4_RENDER_INTENT_RELATIVE_BPC = 4,
};

enum xxColorManagerV4Feature : uint32_t {
    XX_COLOR_MANAGER_V4_FEATURE_ICC_V2_V4 = 0,
    XX_COLOR_MANAGER_V4_FEATURE_PARAMETRIC = 1,
    XX_COLOR_MANAGER_V4_FEATURE_SET_PRIMARIES = 2,
    XX_COLOR_MANAGER_V4_FEATURE_SET_TF_POWER = 3,
    XX_COLOR_MANAGER_V4_FEATURE_SET_LUMINANCES = 4,
    XX_COLOR_MANAGER_V4_FEATURE_SET_MASTERING_DISPLAY_PRIMARIES = 5,
    XX_COLOR_MANAGER_V4_FEATURE_EXTENDED_TARGET_VOLUME = 6,
};

enum xxColorManagerV4Primaries : uint32_t {
    XX_COLOR_MANAGER_V4_PRIMARIES_SRGB = 0,
    XX_COLOR_MANAGER_V4_PRIMARIES_PAL_M = 1,
    XX_COLOR_MANAGER_V4_PRIMARIES_PAL = 2,
    XX_COLOR_MANAGER_V4_PRIMARIES_NTSC = 3,
    XX_COLOR_MANAGER_V4_PRIMARIES_GENERIC_FILM = 4,
    XX_COLOR_MANAGER_V4_PRIMARIES_BT2020 = 5,
    XX_COLOR_MANAGER_V4_PRIMARIES_CIE1931_XYZ = 6,
    XX_COLOR_MANAGER_V4_PRIMARIES_DCI_P3 = 7,
    XX_COLOR_MANAGER_V4_PRIMARIES_DISPLAY_P3 = 8,
    XX_COLOR_MANAGER_V4_PRIMARIES_ADOBE_RGB = 9,
};

enum xxColorManagerV4TransferFunction : uint32_t {
    XX_COLOR_MANAGER_V4_TRANSFER_FUNCTION_BT709 = 0,
    XX_COLOR_MANAGER_V4_TRANSFER_FUNCTION_GAMMA22 = 1,
    XX_COLOR_MANAGER_V4_TRANSFER_FUNCTION_GAMMA28 = 2,
    XX_COLOR_MANAGER_V4_TRANSFER_FUNCTION_ST240 = 3,
    XX_COLOR_MANAGER_V4_TRANSFER_FUNCTION_LINEAR = 4,
    XX_COLOR_MANAGER_V4_TRANSFER_FUNCTION_LOG_100 = 5,
    XX_COLOR_MANAGER_V4_TRANSFER_FUNCTION_LOG_316 = 6,
    XX_COLOR_MANAGER_V4_TRANSFER_FUNCTION_XVYCC = 7,
    XX_COLOR_MANAGER_V4_TRANSFER_FUNCTION_BT1361 = 8,
    XX_COLOR_MANAGER_V4_TRANSFER_FUNCTION_SRGB = 9,
    XX_COLOR_MANAGER_V4_TRANSFER_FUNCTION_EXT_SRGB = 10,
    XX_COLOR_MANAGER_V4_TRANSFER_FUNCTION_ST2084_PQ = 11,
    XX_COLOR_MANAGER_V4_TRANSFER_FUNCTION_ST428 = 12,
    XX_COLOR_MANAGER_V4_TRANSFER_FUNCTION_HLG = 13,
};

enum xxColorManagementSurfaceV4Error : uint32_t {
    XX_COLOR_MANAGEMENT_SURFACE_V4_ERROR_RENDER_INTENT = 0,
    XX_COLOR_MANAGEMENT_SURFACE_V4_ERROR_IMAGE_DESCRIPTION = 1,
};

enum xxColorManagementFeedbackSurfaceV4Error : uint32_t {
    XX_COLOR_MANAGEMENT_FEEDBACK_SURFACE_V4_ERROR_INERT = 0,
};

enum xxImageDescriptionCreatorIccV4Error : uint32_t {
    XX_IMAGE_DESCRIPTION_CREATOR_ICC_V4_ERROR_INCOMPLETE_SET = 0,
    XX_IMAGE_DESCRIPTION_CREATOR_ICC_V4_ERROR_ALREADY_SET = 1,
    XX_IMAGE_DESCRIPTION_CREATOR_ICC_V4_ERROR_BAD_FD = 2,
    XX_IMAGE_DESCRIPTION_CREATOR_ICC_V4_ERROR_BAD_SIZE = 3,
    XX_IMAGE_DESCRIPTION_CREATOR_ICC_V4_ERROR_OUT_OF_FILE = 4,
};

enum xxImageDescriptionCreatorParamsV4Error : uint32_t {
    XX_IMAGE_DESCRIPTION_CREATOR_PARAMS_V4_ERROR_INCOMPLETE_SET = 0,
    XX_IMAGE_DESCRIPTION_CREATOR_PARAMS_V4_ERROR_INCONSISTENT_SET = 1,
    XX_IMAGE_DESCRIPTION_CREATOR_PARAMS_V4_ERROR_ALREADY_SET = 2,
    XX_IMAGE_DESCRIPTION_CREATOR_PARAMS_V4_ERROR_UNSUPPORTED_FEATURE = 3,
    XX_IMAGE_DESCRIPTION_CREATOR_PARAMS_V4_ERROR_INVALID_TF = 4,
    XX_IMAGE_DESCRIPTION_CREATOR_PARAMS_V4_ERROR_INVALID_PRIMARIES = 5,
    XX_IMAGE_DESCRIPTION_CREATOR_PARAMS_V4_ERROR_INVALID_LUMINANCE = 6,
    XX_IMAGE_DESCRIPTION_CREATOR_PARAMS_V4_ERROR_INVALID_MASTERING = 7,
};

enum xxImageDescriptionV4Error : uint32_t {
    XX_IMAGE_DESCRIPTION_V4_ERROR_NOT_READY = 0,
    XX_IMAGE_DESCRIPTION_V4_ERROR_NO_INFORMATION = 1,
};

enum xxImageDescriptionV4Cause : uint32_t {
    XX_IMAGE_DESCRIPTION_V4_CAUSE_LOW_VERSION = 0,
    XX_IMAGE_DESCRIPTION_V4_CAUSE_UNSUPPORTED = 1,
    XX_IMAGE_DESCRIPTION_V4_CAUSE_OPERATING_SYSTEM = 2,
    XX_IMAGE_DESCRIPTION_V4_CAUSE_NO_OUTPUT = 3,
};


class CXxColorManagerV4;
class CXxColorManagementOutputV4;
class CWlOutput;
class CXxColorManagementSurfaceV4;
class CWlSurface;
class CXxColorManagementFeedbackSurfaceV4;
class CWlSurface;
class CXxImageDescriptionCreatorIccV4;
class CXxImageDescriptionCreatorParamsV4;
class CXxColorManagementOutputV4;
class CXxImageDescriptionV4;
class CXxColorManagementSurfaceV4;
class CXxImageDescriptionV4;
class CXxColorManagementFeedbackSurfaceV4;
class CXxImageDescriptionV4;
class CXxImageDescriptionCreatorIccV4;
class CXxImageDescriptionV4;
class CXxImageDescriptionCreatorParamsV4;
class CXxImageDescriptionV4;
class CXxImageDescriptionV4;
class CXxImageDescriptionInfoV4;
class CXxImageDescriptionInfoV4;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface xx_color_manager_v4_interface;
extern const wl_interface xx_color_management_output_v4_interface;
extern const wl_interface xx_color_management_surface_v4_interface;
extern const wl_interface xx_color_management_feedback_surface_v4_interface;
extern const wl_interface xx_image_description_creator_icc_v4_interface;
extern const wl_interface xx_image_description_creator_params_v4_interface;
extern const wl_interface xx_image_description_v4_interface;
extern const wl_interface xx_image_description_info_v4_interface;

#endif

struct CXxColorManagerV4DestroyWrapper {
    wl_listener listener;
    CXxColorManagerV4* parent = nullptr;
};
            

class CXxColorManagerV4 {
  public:
    CXxColorManagerV4(wl_client* client, uint32_t version, uint32_t id);
    ~CXxColorManagerV4();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CXxColorManagerV4*)> handler) {
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

    void setDestroy(F<void(CXxColorManagerV4*)> handler);
    void setGetOutput(F<void(CXxColorManagerV4*, uint32_t, wl_resource*)> handler);
    void setGetSurface(F<void(CXxColorManagerV4*, uint32_t, wl_resource*)> handler);
    void setGetFeedbackSurface(F<void(CXxColorManagerV4*, uint32_t, wl_resource*)> handler);
    void setNewIccCreator(F<void(CXxColorManagerV4*, uint32_t)> handler);
    void setNewParametricCreator(F<void(CXxColorManagerV4*, uint32_t)> handler);

    // --------------- Events --------------- //

    void sendSupportedIntent(xxColorManagerV4RenderIntent);
    void sendSupportedFeature(xxColorManagerV4Feature);
    void sendSupportedTfNamed(xxColorManagerV4TransferFunction);
    void sendSupportedPrimariesNamed(xxColorManagerV4Primaries);
    void sendSupportedIntentRaw(xxColorManagerV4RenderIntent);
    void sendSupportedFeatureRaw(xxColorManagerV4Feature);
    void sendSupportedTfNamedRaw(xxColorManagerV4TransferFunction);
    void sendSupportedPrimariesNamedRaw(xxColorManagerV4Primaries);

  private:
    struct {
        F<void(CXxColorManagerV4*)> destroy;
        F<void(CXxColorManagerV4*, uint32_t, wl_resource*)> getOutput;
        F<void(CXxColorManagerV4*, uint32_t, wl_resource*)> getSurface;
        F<void(CXxColorManagerV4*, uint32_t, wl_resource*)> getFeedbackSurface;
        F<void(CXxColorManagerV4*, uint32_t)> newIccCreator;
        F<void(CXxColorManagerV4*, uint32_t)> newParametricCreator;
    } requests;

    void onDestroyCalled();

    F<void(CXxColorManagerV4*)> onDestroy;

    wl_resource* pResource = nullptr;

    CXxColorManagerV4DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CXxColorManagementOutputV4DestroyWrapper {
    wl_listener listener;
    CXxColorManagementOutputV4* parent = nullptr;
};
            

class CXxColorManagementOutputV4 {
  public:
    CXxColorManagementOutputV4(wl_client* client, uint32_t version, uint32_t id);
    ~CXxColorManagementOutputV4();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CXxColorManagementOutputV4*)> handler) {
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

    void setDestroy(F<void(CXxColorManagementOutputV4*)> handler);
    void setGetImageDescription(F<void(CXxColorManagementOutputV4*, uint32_t)> handler);

    // --------------- Events --------------- //

    void sendImageDescriptionChanged();
    void sendImageDescriptionChangedRaw();

  private:
    struct {
        F<void(CXxColorManagementOutputV4*)> destroy;
        F<void(CXxColorManagementOutputV4*, uint32_t)> getImageDescription;
    } requests;

    void onDestroyCalled();

    F<void(CXxColorManagementOutputV4*)> onDestroy;

    wl_resource* pResource = nullptr;

    CXxColorManagementOutputV4DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CXxColorManagementSurfaceV4DestroyWrapper {
    wl_listener listener;
    CXxColorManagementSurfaceV4* parent = nullptr;
};
            

class CXxColorManagementSurfaceV4 {
  public:
    CXxColorManagementSurfaceV4(wl_client* client, uint32_t version, uint32_t id);
    ~CXxColorManagementSurfaceV4();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CXxColorManagementSurfaceV4*)> handler) {
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

    void setDestroy(F<void(CXxColorManagementSurfaceV4*)> handler);
    void setSetImageDescription(F<void(CXxColorManagementSurfaceV4*, wl_resource*, uint32_t)> handler);
    void setUnsetImageDescription(F<void(CXxColorManagementSurfaceV4*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CXxColorManagementSurfaceV4*)> destroy;
        F<void(CXxColorManagementSurfaceV4*, wl_resource*, uint32_t)> setImageDescription;
        F<void(CXxColorManagementSurfaceV4*)> unsetImageDescription;
    } requests;

    void onDestroyCalled();

    F<void(CXxColorManagementSurfaceV4*)> onDestroy;

    wl_resource* pResource = nullptr;

    CXxColorManagementSurfaceV4DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CXxColorManagementFeedbackSurfaceV4DestroyWrapper {
    wl_listener listener;
    CXxColorManagementFeedbackSurfaceV4* parent = nullptr;
};
            

class CXxColorManagementFeedbackSurfaceV4 {
  public:
    CXxColorManagementFeedbackSurfaceV4(wl_client* client, uint32_t version, uint32_t id);
    ~CXxColorManagementFeedbackSurfaceV4();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CXxColorManagementFeedbackSurfaceV4*)> handler) {
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

    void setDestroy(F<void(CXxColorManagementFeedbackSurfaceV4*)> handler);
    void setGetPreferred(F<void(CXxColorManagementFeedbackSurfaceV4*, uint32_t)> handler);

    // --------------- Events --------------- //

    void sendPreferredChanged();
    void sendPreferredChangedRaw();

  private:
    struct {
        F<void(CXxColorManagementFeedbackSurfaceV4*)> destroy;
        F<void(CXxColorManagementFeedbackSurfaceV4*, uint32_t)> getPreferred;
    } requests;

    void onDestroyCalled();

    F<void(CXxColorManagementFeedbackSurfaceV4*)> onDestroy;

    wl_resource* pResource = nullptr;

    CXxColorManagementFeedbackSurfaceV4DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CXxImageDescriptionCreatorIccV4DestroyWrapper {
    wl_listener listener;
    CXxImageDescriptionCreatorIccV4* parent = nullptr;
};
            

class CXxImageDescriptionCreatorIccV4 {
  public:
    CXxImageDescriptionCreatorIccV4(wl_client* client, uint32_t version, uint32_t id);
    ~CXxImageDescriptionCreatorIccV4();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CXxImageDescriptionCreatorIccV4*)> handler) {
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

    void setCreate(F<void(CXxImageDescriptionCreatorIccV4*, uint32_t)> handler);
    void setSetIccFile(F<void(CXxImageDescriptionCreatorIccV4*, int32_t, uint32_t, uint32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CXxImageDescriptionCreatorIccV4*, uint32_t)> create;
        F<void(CXxImageDescriptionCreatorIccV4*, int32_t, uint32_t, uint32_t)> setIccFile;
    } requests;

    void onDestroyCalled();

    F<void(CXxImageDescriptionCreatorIccV4*)> onDestroy;

    wl_resource* pResource = nullptr;

    CXxImageDescriptionCreatorIccV4DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CXxImageDescriptionCreatorParamsV4DestroyWrapper {
    wl_listener listener;
    CXxImageDescriptionCreatorParamsV4* parent = nullptr;
};
            

class CXxImageDescriptionCreatorParamsV4 {
  public:
    CXxImageDescriptionCreatorParamsV4(wl_client* client, uint32_t version, uint32_t id);
    ~CXxImageDescriptionCreatorParamsV4();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CXxImageDescriptionCreatorParamsV4*)> handler) {
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

    void setCreate(F<void(CXxImageDescriptionCreatorParamsV4*, uint32_t)> handler);
    void setSetTfNamed(F<void(CXxImageDescriptionCreatorParamsV4*, uint32_t)> handler);
    void setSetTfPower(F<void(CXxImageDescriptionCreatorParamsV4*, uint32_t)> handler);
    void setSetPrimariesNamed(F<void(CXxImageDescriptionCreatorParamsV4*, uint32_t)> handler);
    void setSetPrimaries(F<void(CXxImageDescriptionCreatorParamsV4*, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t)> handler);
    void setSetLuminances(F<void(CXxImageDescriptionCreatorParamsV4*, uint32_t, uint32_t, uint32_t)> handler);
    void setSetMasteringDisplayPrimaries(F<void(CXxImageDescriptionCreatorParamsV4*, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t)> handler);
    void setSetMasteringLuminance(F<void(CXxImageDescriptionCreatorParamsV4*, uint32_t, uint32_t)> handler);
    void setSetMaxCll(F<void(CXxImageDescriptionCreatorParamsV4*, uint32_t)> handler);
    void setSetMaxFall(F<void(CXxImageDescriptionCreatorParamsV4*, uint32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CXxImageDescriptionCreatorParamsV4*, uint32_t)> create;
        F<void(CXxImageDescriptionCreatorParamsV4*, uint32_t)> setTfNamed;
        F<void(CXxImageDescriptionCreatorParamsV4*, uint32_t)> setTfPower;
        F<void(CXxImageDescriptionCreatorParamsV4*, uint32_t)> setPrimariesNamed;
        F<void(CXxImageDescriptionCreatorParamsV4*, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t)> setPrimaries;
        F<void(CXxImageDescriptionCreatorParamsV4*, uint32_t, uint32_t, uint32_t)> setLuminances;
        F<void(CXxImageDescriptionCreatorParamsV4*, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t)> setMasteringDisplayPrimaries;
        F<void(CXxImageDescriptionCreatorParamsV4*, uint32_t, uint32_t)> setMasteringLuminance;
        F<void(CXxImageDescriptionCreatorParamsV4*, uint32_t)> setMaxCll;
        F<void(CXxImageDescriptionCreatorParamsV4*, uint32_t)> setMaxFall;
    } requests;

    void onDestroyCalled();

    F<void(CXxImageDescriptionCreatorParamsV4*)> onDestroy;

    wl_resource* pResource = nullptr;

    CXxImageDescriptionCreatorParamsV4DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CXxImageDescriptionV4DestroyWrapper {
    wl_listener listener;
    CXxImageDescriptionV4* parent = nullptr;
};
            

class CXxImageDescriptionV4 {
  public:
    CXxImageDescriptionV4(wl_client* client, uint32_t version, uint32_t id);
    ~CXxImageDescriptionV4();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CXxImageDescriptionV4*)> handler) {
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

    void setDestroy(F<void(CXxImageDescriptionV4*)> handler);
    void setGetInformation(F<void(CXxImageDescriptionV4*, uint32_t)> handler);

    // --------------- Events --------------- //

    void sendFailed(xxImageDescriptionV4Cause, const char*);
    void sendReady(uint32_t);
    void sendFailedRaw(xxImageDescriptionV4Cause, const char*);
    void sendReadyRaw(uint32_t);

  private:
    struct {
        F<void(CXxImageDescriptionV4*)> destroy;
        F<void(CXxImageDescriptionV4*, uint32_t)> getInformation;
    } requests;

    void onDestroyCalled();

    F<void(CXxImageDescriptionV4*)> onDestroy;

    wl_resource* pResource = nullptr;

    CXxImageDescriptionV4DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CXxImageDescriptionInfoV4DestroyWrapper {
    wl_listener listener;
    CXxImageDescriptionInfoV4* parent = nullptr;
};
            

class CXxImageDescriptionInfoV4 {
  public:
    CXxImageDescriptionInfoV4(wl_client* client, uint32_t version, uint32_t id);
    ~CXxImageDescriptionInfoV4();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CXxImageDescriptionInfoV4*)> handler) {
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

    void sendDone();
    void sendIccFile(int32_t, uint32_t);
    void sendPrimaries(int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t);
    void sendPrimariesNamed(uint32_t);
    void sendTfPower(uint32_t);
    void sendTfNamed(uint32_t);
    void sendLuminances(uint32_t, uint32_t, uint32_t);
    void sendTargetPrimaries(int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t);
    void sendTargetLuminance(uint32_t, uint32_t);
    void sendTargetMaxCll(uint32_t);
    void sendTargetMaxFall(uint32_t);
    void sendDoneRaw();
    void sendIccFileRaw(int32_t, uint32_t);
    void sendPrimariesRaw(int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t);
    void sendPrimariesNamedRaw(uint32_t);
    void sendTfPowerRaw(uint32_t);
    void sendTfNamedRaw(uint32_t);
    void sendLuminancesRaw(uint32_t, uint32_t, uint32_t);
    void sendTargetPrimariesRaw(int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t, int32_t);
    void sendTargetLuminanceRaw(uint32_t, uint32_t);
    void sendTargetMaxCllRaw(uint32_t);
    void sendTargetMaxFallRaw(uint32_t);

  private:
    struct {
    } requests;

    void onDestroyCalled();

    F<void(CXxImageDescriptionInfoV4*)> onDestroy;

    wl_resource* pResource = nullptr;

    CXxImageDescriptionInfoV4DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
