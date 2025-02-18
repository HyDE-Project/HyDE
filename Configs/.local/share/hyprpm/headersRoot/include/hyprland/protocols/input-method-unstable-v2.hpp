// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// input_method_unstable_v2

/*
 This protocol's authors' copyright notice is:


    Copyright © 2008-2011 Kristian Høgsberg
    Copyright © 2010-2011 Intel Corporation
    Copyright © 2012-2013 Collabora, Ltd.
    Copyright © 2012, 2013 Intel Corporation
    Copyright © 2015, 2016 Jan Arne Petersen
    Copyright © 2017, 2018 Red Hat, Inc.
    Copyright © 2018       Purism SPC

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

enum zwpInputMethodV2Error : uint32_t {
    ZWP_INPUT_METHOD_V2_ERROR_ROLE = 0,
};


class CZwpInputMethodV2;
class CZwpInputPopupSurfaceV2;
class CWlSurface;
class CZwpInputMethodKeyboardGrabV2;
class CZwpInputPopupSurfaceV2;
class CZwpInputMethodKeyboardGrabV2;
class CZwpInputMethodManagerV2;
class CWlSeat;
class CZwpInputMethodV2;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwp_input_method_v2_interface;
extern const wl_interface zwp_input_popup_surface_v2_interface;
extern const wl_interface zwp_input_method_keyboard_grab_v2_interface;
extern const wl_interface zwp_input_method_manager_v2_interface;

#endif

struct CZwpInputMethodV2DestroyWrapper {
    wl_listener listener;
    CZwpInputMethodV2* parent = nullptr;
};
            

class CZwpInputMethodV2 {
  public:
    CZwpInputMethodV2(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpInputMethodV2();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpInputMethodV2*)> handler) {
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

    void setCommitString(F<void(CZwpInputMethodV2*, const char*)> handler);
    void setSetPreeditString(F<void(CZwpInputMethodV2*, const char*, int32_t, int32_t)> handler);
    void setDeleteSurroundingText(F<void(CZwpInputMethodV2*, uint32_t, uint32_t)> handler);
    void setCommit(F<void(CZwpInputMethodV2*, uint32_t)> handler);
    void setGetInputPopupSurface(F<void(CZwpInputMethodV2*, uint32_t, wl_resource*)> handler);
    void setGrabKeyboard(F<void(CZwpInputMethodV2*, uint32_t)> handler);
    void setDestroy(F<void(CZwpInputMethodV2*)> handler);

    // --------------- Events --------------- //

    void sendActivate();
    void sendDeactivate();
    void sendSurroundingText(const char*, uint32_t, uint32_t);
    void sendTextChangeCause(uint32_t);
    void sendContentType(uint32_t, uint32_t);
    void sendDone();
    void sendUnavailable();
    void sendActivateRaw();
    void sendDeactivateRaw();
    void sendSurroundingTextRaw(const char*, uint32_t, uint32_t);
    void sendTextChangeCauseRaw(uint32_t);
    void sendContentTypeRaw(uint32_t, uint32_t);
    void sendDoneRaw();
    void sendUnavailableRaw();

  private:
    struct {
        F<void(CZwpInputMethodV2*, const char*)> commitString;
        F<void(CZwpInputMethodV2*, const char*, int32_t, int32_t)> setPreeditString;
        F<void(CZwpInputMethodV2*, uint32_t, uint32_t)> deleteSurroundingText;
        F<void(CZwpInputMethodV2*, uint32_t)> commit;
        F<void(CZwpInputMethodV2*, uint32_t, wl_resource*)> getInputPopupSurface;
        F<void(CZwpInputMethodV2*, uint32_t)> grabKeyboard;
        F<void(CZwpInputMethodV2*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpInputMethodV2*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpInputMethodV2DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpInputPopupSurfaceV2DestroyWrapper {
    wl_listener listener;
    CZwpInputPopupSurfaceV2* parent = nullptr;
};
            

class CZwpInputPopupSurfaceV2 {
  public:
    CZwpInputPopupSurfaceV2(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpInputPopupSurfaceV2();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpInputPopupSurfaceV2*)> handler) {
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

    void setDestroy(F<void(CZwpInputPopupSurfaceV2*)> handler);

    // --------------- Events --------------- //

    void sendTextInputRectangle(int32_t, int32_t, int32_t, int32_t);
    void sendTextInputRectangleRaw(int32_t, int32_t, int32_t, int32_t);

  private:
    struct {
        F<void(CZwpInputPopupSurfaceV2*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpInputPopupSurfaceV2*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpInputPopupSurfaceV2DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpInputMethodKeyboardGrabV2DestroyWrapper {
    wl_listener listener;
    CZwpInputMethodKeyboardGrabV2* parent = nullptr;
};
            

class CZwpInputMethodKeyboardGrabV2 {
  public:
    CZwpInputMethodKeyboardGrabV2(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpInputMethodKeyboardGrabV2();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpInputMethodKeyboardGrabV2*)> handler) {
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

    void setRelease(F<void(CZwpInputMethodKeyboardGrabV2*)> handler);

    // --------------- Events --------------- //

    void sendKeymap(uint32_t, int32_t, uint32_t);
    void sendKey(uint32_t, uint32_t, uint32_t, uint32_t);
    void sendModifiers(uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);
    void sendRepeatInfo(int32_t, int32_t);
    void sendKeymapRaw(uint32_t, int32_t, uint32_t);
    void sendKeyRaw(uint32_t, uint32_t, uint32_t, uint32_t);
    void sendModifiersRaw(uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);
    void sendRepeatInfoRaw(int32_t, int32_t);

  private:
    struct {
        F<void(CZwpInputMethodKeyboardGrabV2*)> release;
    } requests;

    void onDestroyCalled();

    F<void(CZwpInputMethodKeyboardGrabV2*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpInputMethodKeyboardGrabV2DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpInputMethodManagerV2DestroyWrapper {
    wl_listener listener;
    CZwpInputMethodManagerV2* parent = nullptr;
};
            

class CZwpInputMethodManagerV2 {
  public:
    CZwpInputMethodManagerV2(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpInputMethodManagerV2();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpInputMethodManagerV2*)> handler) {
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

    void setGetInputMethod(F<void(CZwpInputMethodManagerV2*, wl_resource*, uint32_t)> handler);
    void setDestroy(F<void(CZwpInputMethodManagerV2*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwpInputMethodManagerV2*, wl_resource*, uint32_t)> getInputMethod;
        F<void(CZwpInputMethodManagerV2*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpInputMethodManagerV2*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpInputMethodManagerV2DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
