// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// frog_color_management_v1

/*
 This protocol's authors' copyright notice is:


		Copyright © 2023 Joshua Ashton for Valve Software
		Copyright © 2023 Xaver Hugl

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

enum frogColorManagedSurfaceTransferFunction : uint32_t {
    FROG_COLOR_MANAGED_SURFACE_TRANSFER_FUNCTION_UNDEFINED = 0,
    FROG_COLOR_MANAGED_SURFACE_TRANSFER_FUNCTION_SRGB = 1,
    FROG_COLOR_MANAGED_SURFACE_TRANSFER_FUNCTION_GAMMA_22 = 2,
    FROG_COLOR_MANAGED_SURFACE_TRANSFER_FUNCTION_ST2084_PQ = 3,
    FROG_COLOR_MANAGED_SURFACE_TRANSFER_FUNCTION_SCRGB_LINEAR = 4,
};

enum frogColorManagedSurfacePrimaries : uint32_t {
    FROG_COLOR_MANAGED_SURFACE_PRIMARIES_UNDEFINED = 0,
    FROG_COLOR_MANAGED_SURFACE_PRIMARIES_REC709 = 1,
    FROG_COLOR_MANAGED_SURFACE_PRIMARIES_REC2020 = 2,
};

enum frogColorManagedSurfaceRenderIntent : uint32_t {
    FROG_COLOR_MANAGED_SURFACE_RENDER_INTENT_PERCEPTUAL = 0,
};


class CFrogColorManagementFactoryV1;
class CWlSurface;
class CFrogColorManagedSurface;
class CFrogColorManagedSurface;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface frog_color_management_factory_v1_interface;
extern const wl_interface frog_color_managed_surface_interface;

#endif

struct CFrogColorManagementFactoryV1DestroyWrapper {
    wl_listener listener;
    CFrogColorManagementFactoryV1* parent = nullptr;
};
            

class CFrogColorManagementFactoryV1 {
  public:
    CFrogColorManagementFactoryV1(wl_client* client, uint32_t version, uint32_t id);
    ~CFrogColorManagementFactoryV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CFrogColorManagementFactoryV1*)> handler) {
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

    void setDestroy(F<void(CFrogColorManagementFactoryV1*)> handler);
    void setGetColorManagedSurface(F<void(CFrogColorManagementFactoryV1*, wl_resource*, uint32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CFrogColorManagementFactoryV1*)> destroy;
        F<void(CFrogColorManagementFactoryV1*, wl_resource*, uint32_t)> getColorManagedSurface;
    } requests;

    void onDestroyCalled();

    F<void(CFrogColorManagementFactoryV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CFrogColorManagementFactoryV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CFrogColorManagedSurfaceDestroyWrapper {
    wl_listener listener;
    CFrogColorManagedSurface* parent = nullptr;
};
            

class CFrogColorManagedSurface {
  public:
    CFrogColorManagedSurface(wl_client* client, uint32_t version, uint32_t id);
    ~CFrogColorManagedSurface();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CFrogColorManagedSurface*)> handler) {
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

    void setDestroy(F<void(CFrogColorManagedSurface*)> handler);
    void setSetKnownTransferFunction(F<void(CFrogColorManagedSurface*, frogColorManagedSurfaceTransferFunction)> handler);
    void setSetKnownContainerColorVolume(F<void(CFrogColorManagedSurface*, frogColorManagedSurfacePrimaries)> handler);
    void setSetRenderIntent(F<void(CFrogColorManagedSurface*, frogColorManagedSurfaceRenderIntent)> handler);
    void setSetHdrMetadata(F<void(CFrogColorManagedSurface*, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t)> handler);

    // --------------- Events --------------- //

    void sendPreferredMetadata(frogColorManagedSurfaceTransferFunction, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);
    void sendPreferredMetadataRaw(frogColorManagedSurfaceTransferFunction, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);

  private:
    struct {
        F<void(CFrogColorManagedSurface*)> destroy;
        F<void(CFrogColorManagedSurface*, frogColorManagedSurfaceTransferFunction)> setKnownTransferFunction;
        F<void(CFrogColorManagedSurface*, frogColorManagedSurfacePrimaries)> setKnownContainerColorVolume;
        F<void(CFrogColorManagedSurface*, frogColorManagedSurfaceRenderIntent)> setRenderIntent;
        F<void(CFrogColorManagedSurface*, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t)> setHdrMetadata;
    } requests;

    void onDestroyCalled();

    F<void(CFrogColorManagedSurface*)> onDestroy;

    wl_resource* pResource = nullptr;

    CFrogColorManagedSurfaceDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
