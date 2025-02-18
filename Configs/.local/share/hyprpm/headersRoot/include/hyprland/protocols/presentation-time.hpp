// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// presentation_time

/*
 This protocol's authors' copyright notice is:


    Copyright © 2013-2014 Collabora, Ltd.

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

enum wpPresentationError : uint32_t {
    WP_PRESENTATION_ERROR_INVALID_TIMESTAMP = 0,
    WP_PRESENTATION_ERROR_INVALID_FLAG = 1,
};

enum wpPresentationFeedbackKind : uint32_t {
    WP_PRESENTATION_FEEDBACK_KIND_VSYNC = 1,
    WP_PRESENTATION_FEEDBACK_KIND_HW_CLOCK = 2,
    WP_PRESENTATION_FEEDBACK_KIND_HW_COMPLETION = 4,
    WP_PRESENTATION_FEEDBACK_KIND_ZERO_COPY = 8,
};


class CWpPresentation;
class CWlSurface;
class CWpPresentationFeedback;
class CWpPresentationFeedback;
class CWlOutput;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface wp_presentation_interface;
extern const wl_interface wp_presentation_feedback_interface;

#endif

struct CWpPresentationDestroyWrapper {
    wl_listener listener;
    CWpPresentation* parent = nullptr;
};
            

class CWpPresentation {
  public:
    CWpPresentation(wl_client* client, uint32_t version, uint32_t id);
    ~CWpPresentation();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpPresentation*)> handler) {
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

    void setDestroy(F<void(CWpPresentation*)> handler);
    void setFeedback(F<void(CWpPresentation*, wl_resource*, uint32_t)> handler);

    // --------------- Events --------------- //

    void sendClockId(uint32_t);
    void sendClockIdRaw(uint32_t);

  private:
    struct {
        F<void(CWpPresentation*)> destroy;
        F<void(CWpPresentation*, wl_resource*, uint32_t)> feedback;
    } requests;

    void onDestroyCalled();

    F<void(CWpPresentation*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpPresentationDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CWpPresentationFeedbackDestroyWrapper {
    wl_listener listener;
    CWpPresentationFeedback* parent = nullptr;
};
            

class CWpPresentationFeedback {
  public:
    CWpPresentationFeedback(wl_client* client, uint32_t version, uint32_t id);
    ~CWpPresentationFeedback();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CWpPresentationFeedback*)> handler) {
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

    void sendSyncOutput(wl_resource*);
    void sendPresented(uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, wpPresentationFeedbackKind);
    void sendDiscarded();
    void sendSyncOutputRaw(wl_resource*);
    void sendPresentedRaw(uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, wpPresentationFeedbackKind);
    void sendDiscardedRaw();

  private:
    struct {
    } requests;

    void onDestroyCalled();

    F<void(CWpPresentationFeedback*)> onDestroy;

    wl_resource* pResource = nullptr;

    CWpPresentationFeedbackDestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
