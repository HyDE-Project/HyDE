// Generated with hyprwayland-scanner 0.4.2. Made with vaxry's keyboard and ❤️.
// text_input_unstable_v3

/*
 This protocol's authors' copyright notice is:


    Copyright © 2012, 2013 Intel Corporation
    Copyright © 2015, 2016 Jan Arne Petersen
    Copyright © 2017, 2018 Red Hat, Inc.
    Copyright © 2018       Purism SPC

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

enum zwpTextInputV3ChangeCause : uint32_t {
    ZWP_TEXT_INPUT_V3_CHANGE_CAUSE_INPUT_METHOD = 0,
    ZWP_TEXT_INPUT_V3_CHANGE_CAUSE_OTHER = 1,
};

enum zwpTextInputV3ContentHint : uint32_t {
    ZWP_TEXT_INPUT_V3_CONTENT_HINT_NONE = 0,
    ZWP_TEXT_INPUT_V3_CONTENT_HINT_COMPLETION = 1,
    ZWP_TEXT_INPUT_V3_CONTENT_HINT_SPELLCHECK = 2,
    ZWP_TEXT_INPUT_V3_CONTENT_HINT_AUTO_CAPITALIZATION = 4,
    ZWP_TEXT_INPUT_V3_CONTENT_HINT_LOWERCASE = 8,
    ZWP_TEXT_INPUT_V3_CONTENT_HINT_UPPERCASE = 16,
    ZWP_TEXT_INPUT_V3_CONTENT_HINT_TITLECASE = 32,
    ZWP_TEXT_INPUT_V3_CONTENT_HINT_HIDDEN_TEXT = 64,
    ZWP_TEXT_INPUT_V3_CONTENT_HINT_SENSITIVE_DATA = 128,
    ZWP_TEXT_INPUT_V3_CONTENT_HINT_LATIN = 256,
    ZWP_TEXT_INPUT_V3_CONTENT_HINT_MULTILINE = 512,
};

enum zwpTextInputV3ContentPurpose : uint32_t {
    ZWP_TEXT_INPUT_V3_CONTENT_PURPOSE_NORMAL = 0,
    ZWP_TEXT_INPUT_V3_CONTENT_PURPOSE_ALPHA = 1,
    ZWP_TEXT_INPUT_V3_CONTENT_PURPOSE_DIGITS = 2,
    ZWP_TEXT_INPUT_V3_CONTENT_PURPOSE_NUMBER = 3,
    ZWP_TEXT_INPUT_V3_CONTENT_PURPOSE_PHONE = 4,
    ZWP_TEXT_INPUT_V3_CONTENT_PURPOSE_URL = 5,
    ZWP_TEXT_INPUT_V3_CONTENT_PURPOSE_EMAIL = 6,
    ZWP_TEXT_INPUT_V3_CONTENT_PURPOSE_NAME = 7,
    ZWP_TEXT_INPUT_V3_CONTENT_PURPOSE_PASSWORD = 8,
    ZWP_TEXT_INPUT_V3_CONTENT_PURPOSE_PIN = 9,
    ZWP_TEXT_INPUT_V3_CONTENT_PURPOSE_DATE = 10,
    ZWP_TEXT_INPUT_V3_CONTENT_PURPOSE_TIME = 11,
    ZWP_TEXT_INPUT_V3_CONTENT_PURPOSE_DATETIME = 12,
    ZWP_TEXT_INPUT_V3_CONTENT_PURPOSE_TERMINAL = 13,
};


class CZwpTextInputV3;
class CWlSurface;
class CWlSurface;
class CZwpTextInputManagerV3;
class CZwpTextInputV3;
class CWlSeat;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwp_text_input_v3_interface;
extern const wl_interface zwp_text_input_manager_v3_interface;

#endif

struct CZwpTextInputV3DestroyWrapper {
    wl_listener listener;
    CZwpTextInputV3* parent = nullptr;
};
            

class CZwpTextInputV3 {
  public:
    CZwpTextInputV3(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpTextInputV3();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpTextInputV3*)> handler) {
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

    void setDestroy(F<void(CZwpTextInputV3*)> handler);
    void setEnable(F<void(CZwpTextInputV3*)> handler);
    void setDisable(F<void(CZwpTextInputV3*)> handler);
    void setSetSurroundingText(F<void(CZwpTextInputV3*, const char*, int32_t, int32_t)> handler);
    void setSetTextChangeCause(F<void(CZwpTextInputV3*, zwpTextInputV3ChangeCause)> handler);
    void setSetContentType(F<void(CZwpTextInputV3*, zwpTextInputV3ContentHint, zwpTextInputV3ContentPurpose)> handler);
    void setSetCursorRectangle(F<void(CZwpTextInputV3*, int32_t, int32_t, int32_t, int32_t)> handler);
    void setCommit(F<void(CZwpTextInputV3*)> handler);

    // --------------- Events --------------- //

    void sendEnter(wl_resource*);
    void sendLeave(wl_resource*);
    void sendPreeditString(const char*, int32_t, int32_t);
    void sendCommitString(const char*);
    void sendDeleteSurroundingText(uint32_t, uint32_t);
    void sendDone(uint32_t);
    void sendEnterRaw(wl_resource*);
    void sendLeaveRaw(wl_resource*);
    void sendPreeditStringRaw(const char*, int32_t, int32_t);
    void sendCommitStringRaw(const char*);
    void sendDeleteSurroundingTextRaw(uint32_t, uint32_t);
    void sendDoneRaw(uint32_t);

  private:
    struct {
        F<void(CZwpTextInputV3*)> destroy;
        F<void(CZwpTextInputV3*)> enable;
        F<void(CZwpTextInputV3*)> disable;
        F<void(CZwpTextInputV3*, const char*, int32_t, int32_t)> setSurroundingText;
        F<void(CZwpTextInputV3*, zwpTextInputV3ChangeCause)> setTextChangeCause;
        F<void(CZwpTextInputV3*, zwpTextInputV3ContentHint, zwpTextInputV3ContentPurpose)> setContentType;
        F<void(CZwpTextInputV3*, int32_t, int32_t, int32_t, int32_t)> setCursorRectangle;
        F<void(CZwpTextInputV3*)> commit;
    } requests;

    void onDestroyCalled();

    F<void(CZwpTextInputV3*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpTextInputV3DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpTextInputManagerV3DestroyWrapper {
    wl_listener listener;
    CZwpTextInputManagerV3* parent = nullptr;
};
            

class CZwpTextInputManagerV3 {
  public:
    CZwpTextInputManagerV3(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpTextInputManagerV3();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpTextInputManagerV3*)> handler) {
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

    void setDestroy(F<void(CZwpTextInputManagerV3*)> handler);
    void setGetTextInput(F<void(CZwpTextInputManagerV3*, uint32_t, wl_resource*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwpTextInputManagerV3*)> destroy;
        F<void(CZwpTextInputManagerV3*, uint32_t, wl_resource*)> getTextInput;
    } requests;

    void onDestroyCalled();

    F<void(CZwpTextInputManagerV3*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpTextInputManagerV3DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
