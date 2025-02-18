// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// text_input_unstable_v1

/*
 This protocol's authors' copyright notice is:


    Copyright © 2012, 2013 Intel Corporation

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

enum zwpTextInputV1ContentHint : uint32_t {
    ZWP_TEXT_INPUT_V1_CONTENT_HINT_NONE = 0,
    ZWP_TEXT_INPUT_V1_CONTENT_HINT_DEFAULT = 7,
    ZWP_TEXT_INPUT_V1_CONTENT_HINT_PASSWORD = 192,
    ZWP_TEXT_INPUT_V1_CONTENT_HINT_AUTO_COMPLETION = 1,
    ZWP_TEXT_INPUT_V1_CONTENT_HINT_AUTO_CORRECTION = 2,
    ZWP_TEXT_INPUT_V1_CONTENT_HINT_AUTO_CAPITALIZATION = 4,
    ZWP_TEXT_INPUT_V1_CONTENT_HINT_LOWERCASE = 8,
    ZWP_TEXT_INPUT_V1_CONTENT_HINT_UPPERCASE = 16,
    ZWP_TEXT_INPUT_V1_CONTENT_HINT_TITLECASE = 32,
    ZWP_TEXT_INPUT_V1_CONTENT_HINT_HIDDEN_TEXT = 64,
    ZWP_TEXT_INPUT_V1_CONTENT_HINT_SENSITIVE_DATA = 128,
    ZWP_TEXT_INPUT_V1_CONTENT_HINT_LATIN = 256,
    ZWP_TEXT_INPUT_V1_CONTENT_HINT_MULTILINE = 512,
};

enum zwpTextInputV1ContentPurpose : uint32_t {
    ZWP_TEXT_INPUT_V1_CONTENT_PURPOSE_NORMAL = 0,
    ZWP_TEXT_INPUT_V1_CONTENT_PURPOSE_ALPHA = 1,
    ZWP_TEXT_INPUT_V1_CONTENT_PURPOSE_DIGITS = 2,
    ZWP_TEXT_INPUT_V1_CONTENT_PURPOSE_NUMBER = 3,
    ZWP_TEXT_INPUT_V1_CONTENT_PURPOSE_PHONE = 4,
    ZWP_TEXT_INPUT_V1_CONTENT_PURPOSE_URL = 5,
    ZWP_TEXT_INPUT_V1_CONTENT_PURPOSE_EMAIL = 6,
    ZWP_TEXT_INPUT_V1_CONTENT_PURPOSE_NAME = 7,
    ZWP_TEXT_INPUT_V1_CONTENT_PURPOSE_PASSWORD = 8,
    ZWP_TEXT_INPUT_V1_CONTENT_PURPOSE_DATE = 9,
    ZWP_TEXT_INPUT_V1_CONTENT_PURPOSE_TIME = 10,
    ZWP_TEXT_INPUT_V1_CONTENT_PURPOSE_DATETIME = 11,
    ZWP_TEXT_INPUT_V1_CONTENT_PURPOSE_TERMINAL = 12,
};

enum zwpTextInputV1PreeditStyle : uint32_t {
    ZWP_TEXT_INPUT_V1_PREEDIT_STYLE_DEFAULT = 0,
    ZWP_TEXT_INPUT_V1_PREEDIT_STYLE_NONE = 1,
    ZWP_TEXT_INPUT_V1_PREEDIT_STYLE_ACTIVE = 2,
    ZWP_TEXT_INPUT_V1_PREEDIT_STYLE_INACTIVE = 3,
    ZWP_TEXT_INPUT_V1_PREEDIT_STYLE_HIGHLIGHT = 4,
    ZWP_TEXT_INPUT_V1_PREEDIT_STYLE_UNDERLINE = 5,
    ZWP_TEXT_INPUT_V1_PREEDIT_STYLE_SELECTION = 6,
    ZWP_TEXT_INPUT_V1_PREEDIT_STYLE_INCORRECT = 7,
};

enum zwpTextInputV1TextDirection : uint32_t {
    ZWP_TEXT_INPUT_V1_TEXT_DIRECTION_AUTO = 0,
    ZWP_TEXT_INPUT_V1_TEXT_DIRECTION_LTR = 1,
    ZWP_TEXT_INPUT_V1_TEXT_DIRECTION_RTL = 2,
};


class CZwpTextInputV1;
class CWlSeat;
class CWlSurface;
class CWlSeat;
class CWlSurface;
class CZwpTextInputManagerV1;
class CZwpTextInputV1;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwp_text_input_v1_interface;
extern const wl_interface zwp_text_input_manager_v1_interface;

#endif

struct CZwpTextInputV1DestroyWrapper {
    wl_listener listener;
    CZwpTextInputV1* parent = nullptr;
};
            

class CZwpTextInputV1 {
  public:
    CZwpTextInputV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpTextInputV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpTextInputV1*)> handler) {
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

    void setActivate(F<void(CZwpTextInputV1*, wl_resource*, wl_resource*)> handler);
    void setDeactivate(F<void(CZwpTextInputV1*, wl_resource*)> handler);
    void setShowInputPanel(F<void(CZwpTextInputV1*)> handler);
    void setHideInputPanel(F<void(CZwpTextInputV1*)> handler);
    void setReset(F<void(CZwpTextInputV1*)> handler);
    void setSetSurroundingText(F<void(CZwpTextInputV1*, const char*, uint32_t, uint32_t)> handler);
    void setSetContentType(F<void(CZwpTextInputV1*, zwpTextInputV1ContentHint, zwpTextInputV1ContentPurpose)> handler);
    void setSetCursorRectangle(F<void(CZwpTextInputV1*, int32_t, int32_t, int32_t, int32_t)> handler);
    void setSetPreferredLanguage(F<void(CZwpTextInputV1*, const char*)> handler);
    void setCommitState(F<void(CZwpTextInputV1*, uint32_t)> handler);
    void setInvokeAction(F<void(CZwpTextInputV1*, uint32_t, uint32_t)> handler);

    // --------------- Events --------------- //

    void sendEnter(wl_resource*);
    void sendLeave();
    void sendModifiersMap(wl_array*);
    void sendInputPanelState(uint32_t);
    void sendPreeditString(uint32_t, const char*, const char*);
    void sendPreeditStyling(uint32_t, uint32_t, zwpTextInputV1PreeditStyle);
    void sendPreeditCursor(int32_t);
    void sendCommitString(uint32_t, const char*);
    void sendCursorPosition(int32_t, int32_t);
    void sendDeleteSurroundingText(int32_t, uint32_t);
    void sendKeysym(uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);
    void sendLanguage(uint32_t, const char*);
    void sendTextDirection(uint32_t, zwpTextInputV1TextDirection);
    void sendEnterRaw(wl_resource*);
    void sendLeaveRaw();
    void sendModifiersMapRaw(wl_array*);
    void sendInputPanelStateRaw(uint32_t);
    void sendPreeditStringRaw(uint32_t, const char*, const char*);
    void sendPreeditStylingRaw(uint32_t, uint32_t, zwpTextInputV1PreeditStyle);
    void sendPreeditCursorRaw(int32_t);
    void sendCommitStringRaw(uint32_t, const char*);
    void sendCursorPositionRaw(int32_t, int32_t);
    void sendDeleteSurroundingTextRaw(int32_t, uint32_t);
    void sendKeysymRaw(uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);
    void sendLanguageRaw(uint32_t, const char*);
    void sendTextDirectionRaw(uint32_t, zwpTextInputV1TextDirection);

  private:
    struct {
        F<void(CZwpTextInputV1*, wl_resource*, wl_resource*)> activate;
        F<void(CZwpTextInputV1*, wl_resource*)> deactivate;
        F<void(CZwpTextInputV1*)> showInputPanel;
        F<void(CZwpTextInputV1*)> hideInputPanel;
        F<void(CZwpTextInputV1*)> reset;
        F<void(CZwpTextInputV1*, const char*, uint32_t, uint32_t)> setSurroundingText;
        F<void(CZwpTextInputV1*, zwpTextInputV1ContentHint, zwpTextInputV1ContentPurpose)> setContentType;
        F<void(CZwpTextInputV1*, int32_t, int32_t, int32_t, int32_t)> setCursorRectangle;
        F<void(CZwpTextInputV1*, const char*)> setPreferredLanguage;
        F<void(CZwpTextInputV1*, uint32_t)> commitState;
        F<void(CZwpTextInputV1*, uint32_t, uint32_t)> invokeAction;
    } requests;

    void onDestroyCalled();

    F<void(CZwpTextInputV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpTextInputV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpTextInputManagerV1DestroyWrapper {
    wl_listener listener;
    CZwpTextInputManagerV1* parent = nullptr;
};
            

class CZwpTextInputManagerV1 {
  public:
    CZwpTextInputManagerV1(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpTextInputManagerV1();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpTextInputManagerV1*)> handler) {
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

    void setCreateTextInput(F<void(CZwpTextInputManagerV1*, uint32_t)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwpTextInputManagerV1*, uint32_t)> createTextInput;
    } requests;

    void onDestroyCalled();

    F<void(CZwpTextInputManagerV1*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpTextInputManagerV1DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
