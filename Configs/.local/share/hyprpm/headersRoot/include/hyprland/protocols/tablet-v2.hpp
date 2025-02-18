// Generated with hyprwayland-scanner 0.4.4. Made with vaxry's keyboard and ❤️.
// tablet_v2

/*
 This protocol's authors' copyright notice is:


    Copyright 2014 © Stephen "Lyude" Chandler Paul
    Copyright 2015-2016 © Red Hat, Inc.

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

enum zwpTabletToolV2Type : uint32_t {
    ZWP_TABLET_TOOL_V2_TYPE_PEN = 320,
    ZWP_TABLET_TOOL_V2_TYPE_ERASER = 321,
    ZWP_TABLET_TOOL_V2_TYPE_BRUSH = 322,
    ZWP_TABLET_TOOL_V2_TYPE_PENCIL = 323,
    ZWP_TABLET_TOOL_V2_TYPE_AIRBRUSH = 324,
    ZWP_TABLET_TOOL_V2_TYPE_FINGER = 325,
    ZWP_TABLET_TOOL_V2_TYPE_MOUSE = 326,
    ZWP_TABLET_TOOL_V2_TYPE_LENS = 327,
};

enum zwpTabletToolV2Capability : uint32_t {
    ZWP_TABLET_TOOL_V2_CAPABILITY_TILT = 1,
    ZWP_TABLET_TOOL_V2_CAPABILITY_PRESSURE = 2,
    ZWP_TABLET_TOOL_V2_CAPABILITY_DISTANCE = 3,
    ZWP_TABLET_TOOL_V2_CAPABILITY_ROTATION = 4,
    ZWP_TABLET_TOOL_V2_CAPABILITY_SLIDER = 5,
    ZWP_TABLET_TOOL_V2_CAPABILITY_WHEEL = 6,
};

enum zwpTabletToolV2ButtonState : uint32_t {
    ZWP_TABLET_TOOL_V2_BUTTON_STATE_RELEASED = 0,
    ZWP_TABLET_TOOL_V2_BUTTON_STATE_PRESSED = 1,
};

enum zwpTabletToolV2Error : uint32_t {
    ZWP_TABLET_TOOL_V2_ERROR_ROLE = 0,
};

enum zwpTabletPadRingV2Source : uint32_t {
    ZWP_TABLET_PAD_RING_V2_SOURCE_FINGER = 1,
};

enum zwpTabletPadStripV2Source : uint32_t {
    ZWP_TABLET_PAD_STRIP_V2_SOURCE_FINGER = 1,
};

enum zwpTabletPadV2ButtonState : uint32_t {
    ZWP_TABLET_PAD_V2_BUTTON_STATE_RELEASED = 0,
    ZWP_TABLET_PAD_V2_BUTTON_STATE_PRESSED = 1,
};


class CZwpTabletManagerV2;
class CZwpTabletSeatV2;
class CWlSeat;
class CZwpTabletSeatV2;
class CZwpTabletV2;
class CZwpTabletToolV2;
class CZwpTabletPadV2;
class CZwpTabletToolV2;
class CWlSurface;
class CZwpTabletV2;
class CWlSurface;
class CZwpTabletV2;
class CZwpTabletPadRingV2;
class CZwpTabletPadStripV2;
class CZwpTabletPadGroupV2;
class CZwpTabletPadRingV2;
class CZwpTabletPadStripV2;
class CZwpTabletPadV2;
class CZwpTabletPadGroupV2;
class CZwpTabletV2;
class CWlSurface;
class CWlSurface;

#ifndef HYPRWAYLAND_SCANNER_NO_INTERFACES
extern const wl_interface zwp_tablet_manager_v2_interface;
extern const wl_interface zwp_tablet_seat_v2_interface;
extern const wl_interface zwp_tablet_tool_v2_interface;
extern const wl_interface zwp_tablet_v2_interface;
extern const wl_interface zwp_tablet_pad_ring_v2_interface;
extern const wl_interface zwp_tablet_pad_strip_v2_interface;
extern const wl_interface zwp_tablet_pad_group_v2_interface;
extern const wl_interface zwp_tablet_pad_v2_interface;

#endif

struct CZwpTabletManagerV2DestroyWrapper {
    wl_listener listener;
    CZwpTabletManagerV2* parent = nullptr;
};
            

class CZwpTabletManagerV2 {
  public:
    CZwpTabletManagerV2(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpTabletManagerV2();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpTabletManagerV2*)> handler) {
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

    void setGetTabletSeat(F<void(CZwpTabletManagerV2*, uint32_t, wl_resource*)> handler);
    void setDestroy(F<void(CZwpTabletManagerV2*)> handler);

    // --------------- Events --------------- //


  private:
    struct {
        F<void(CZwpTabletManagerV2*, uint32_t, wl_resource*)> getTabletSeat;
        F<void(CZwpTabletManagerV2*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpTabletManagerV2*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpTabletManagerV2DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpTabletSeatV2DestroyWrapper {
    wl_listener listener;
    CZwpTabletSeatV2* parent = nullptr;
};
            

class CZwpTabletSeatV2 {
  public:
    CZwpTabletSeatV2(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpTabletSeatV2();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpTabletSeatV2*)> handler) {
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

    void setDestroy(F<void(CZwpTabletSeatV2*)> handler);

    // --------------- Events --------------- //

    void sendTabletAdded(CZwpTabletV2*);
    void sendToolAdded(CZwpTabletToolV2*);
    void sendPadAdded(CZwpTabletPadV2*);
    void sendTabletAddedRaw(CZwpTabletV2*);
    void sendToolAddedRaw(CZwpTabletToolV2*);
    void sendPadAddedRaw(CZwpTabletPadV2*);

  private:
    struct {
        F<void(CZwpTabletSeatV2*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpTabletSeatV2*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpTabletSeatV2DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpTabletToolV2DestroyWrapper {
    wl_listener listener;
    CZwpTabletToolV2* parent = nullptr;
};
            

class CZwpTabletToolV2 {
  public:
    CZwpTabletToolV2(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpTabletToolV2();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpTabletToolV2*)> handler) {
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

    void setSetCursor(F<void(CZwpTabletToolV2*, uint32_t, wl_resource*, int32_t, int32_t)> handler);
    void setDestroy(F<void(CZwpTabletToolV2*)> handler);

    // --------------- Events --------------- //

    void sendType(zwpTabletToolV2Type);
    void sendHardwareSerial(uint32_t, uint32_t);
    void sendHardwareIdWacom(uint32_t, uint32_t);
    void sendCapability(zwpTabletToolV2Capability);
    void sendDone();
    void sendRemoved();
    void sendProximityIn(uint32_t, CZwpTabletV2*, wl_resource*);
    void sendProximityOut();
    void sendDown(uint32_t);
    void sendUp();
    void sendMotion(wl_fixed_t, wl_fixed_t);
    void sendPressure(uint32_t);
    void sendDistance(uint32_t);
    void sendTilt(wl_fixed_t, wl_fixed_t);
    void sendRotation(wl_fixed_t);
    void sendSlider(int32_t);
    void sendWheel(wl_fixed_t, int32_t);
    void sendButton(uint32_t, uint32_t, zwpTabletToolV2ButtonState);
    void sendFrame(uint32_t);
    void sendTypeRaw(zwpTabletToolV2Type);
    void sendHardwareSerialRaw(uint32_t, uint32_t);
    void sendHardwareIdWacomRaw(uint32_t, uint32_t);
    void sendCapabilityRaw(zwpTabletToolV2Capability);
    void sendDoneRaw();
    void sendRemovedRaw();
    void sendProximityInRaw(uint32_t, wl_resource*, wl_resource*);
    void sendProximityOutRaw();
    void sendDownRaw(uint32_t);
    void sendUpRaw();
    void sendMotionRaw(wl_fixed_t, wl_fixed_t);
    void sendPressureRaw(uint32_t);
    void sendDistanceRaw(uint32_t);
    void sendTiltRaw(wl_fixed_t, wl_fixed_t);
    void sendRotationRaw(wl_fixed_t);
    void sendSliderRaw(int32_t);
    void sendWheelRaw(wl_fixed_t, int32_t);
    void sendButtonRaw(uint32_t, uint32_t, zwpTabletToolV2ButtonState);
    void sendFrameRaw(uint32_t);

  private:
    struct {
        F<void(CZwpTabletToolV2*, uint32_t, wl_resource*, int32_t, int32_t)> setCursor;
        F<void(CZwpTabletToolV2*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpTabletToolV2*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpTabletToolV2DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpTabletV2DestroyWrapper {
    wl_listener listener;
    CZwpTabletV2* parent = nullptr;
};
            

class CZwpTabletV2 {
  public:
    CZwpTabletV2(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpTabletV2();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpTabletV2*)> handler) {
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

    void setDestroy(F<void(CZwpTabletV2*)> handler);

    // --------------- Events --------------- //

    void sendName(const char*);
    void sendId(uint32_t, uint32_t);
    void sendPath(const char*);
    void sendDone();
    void sendRemoved();
    void sendNameRaw(const char*);
    void sendIdRaw(uint32_t, uint32_t);
    void sendPathRaw(const char*);
    void sendDoneRaw();
    void sendRemovedRaw();

  private:
    struct {
        F<void(CZwpTabletV2*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpTabletV2*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpTabletV2DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpTabletPadRingV2DestroyWrapper {
    wl_listener listener;
    CZwpTabletPadRingV2* parent = nullptr;
};
            

class CZwpTabletPadRingV2 {
  public:
    CZwpTabletPadRingV2(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpTabletPadRingV2();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpTabletPadRingV2*)> handler) {
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

    void setSetFeedback(F<void(CZwpTabletPadRingV2*, const char*, uint32_t)> handler);
    void setDestroy(F<void(CZwpTabletPadRingV2*)> handler);

    // --------------- Events --------------- //

    void sendSource(zwpTabletPadRingV2Source);
    void sendAngle(wl_fixed_t);
    void sendStop();
    void sendFrame(uint32_t);
    void sendSourceRaw(zwpTabletPadRingV2Source);
    void sendAngleRaw(wl_fixed_t);
    void sendStopRaw();
    void sendFrameRaw(uint32_t);

  private:
    struct {
        F<void(CZwpTabletPadRingV2*, const char*, uint32_t)> setFeedback;
        F<void(CZwpTabletPadRingV2*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpTabletPadRingV2*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpTabletPadRingV2DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpTabletPadStripV2DestroyWrapper {
    wl_listener listener;
    CZwpTabletPadStripV2* parent = nullptr;
};
            

class CZwpTabletPadStripV2 {
  public:
    CZwpTabletPadStripV2(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpTabletPadStripV2();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpTabletPadStripV2*)> handler) {
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

    void setSetFeedback(F<void(CZwpTabletPadStripV2*, const char*, uint32_t)> handler);
    void setDestroy(F<void(CZwpTabletPadStripV2*)> handler);

    // --------------- Events --------------- //

    void sendSource(zwpTabletPadRingV2Source);
    void sendPosition(uint32_t);
    void sendStop();
    void sendFrame(uint32_t);
    void sendSourceRaw(zwpTabletPadRingV2Source);
    void sendPositionRaw(uint32_t);
    void sendStopRaw();
    void sendFrameRaw(uint32_t);

  private:
    struct {
        F<void(CZwpTabletPadStripV2*, const char*, uint32_t)> setFeedback;
        F<void(CZwpTabletPadStripV2*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpTabletPadStripV2*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpTabletPadStripV2DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpTabletPadGroupV2DestroyWrapper {
    wl_listener listener;
    CZwpTabletPadGroupV2* parent = nullptr;
};
            

class CZwpTabletPadGroupV2 {
  public:
    CZwpTabletPadGroupV2(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpTabletPadGroupV2();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpTabletPadGroupV2*)> handler) {
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

    void setDestroy(F<void(CZwpTabletPadGroupV2*)> handler);

    // --------------- Events --------------- //

    void sendButtons(wl_array*);
    void sendRing(CZwpTabletPadRingV2*);
    void sendStrip(CZwpTabletPadStripV2*);
    void sendModes(uint32_t);
    void sendDone();
    void sendModeSwitch(uint32_t, uint32_t, uint32_t);
    void sendButtonsRaw(wl_array*);
    void sendRingRaw(CZwpTabletPadRingV2*);
    void sendStripRaw(CZwpTabletPadStripV2*);
    void sendModesRaw(uint32_t);
    void sendDoneRaw();
    void sendModeSwitchRaw(uint32_t, uint32_t, uint32_t);

  private:
    struct {
        F<void(CZwpTabletPadGroupV2*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpTabletPadGroupV2*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpTabletPadGroupV2DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};


struct CZwpTabletPadV2DestroyWrapper {
    wl_listener listener;
    CZwpTabletPadV2* parent = nullptr;
};
            

class CZwpTabletPadV2 {
  public:
    CZwpTabletPadV2(wl_client* client, uint32_t version, uint32_t id);
    ~CZwpTabletPadV2();


    // set a listener for when this resource is _being_ destroyed
    void setOnDestroy(F<void(CZwpTabletPadV2*)> handler) {
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

    void setSetFeedback(F<void(CZwpTabletPadV2*, uint32_t, const char*, uint32_t)> handler);
    void setDestroy(F<void(CZwpTabletPadV2*)> handler);

    // --------------- Events --------------- //

    void sendGroup(CZwpTabletPadGroupV2*);
    void sendPath(const char*);
    void sendButtons(uint32_t);
    void sendDone();
    void sendButton(uint32_t, uint32_t, zwpTabletToolV2ButtonState);
    void sendEnter(uint32_t, CZwpTabletV2*, wl_resource*);
    void sendLeave(uint32_t, wl_resource*);
    void sendRemoved();
    void sendGroupRaw(CZwpTabletPadGroupV2*);
    void sendPathRaw(const char*);
    void sendButtonsRaw(uint32_t);
    void sendDoneRaw();
    void sendButtonRaw(uint32_t, uint32_t, zwpTabletToolV2ButtonState);
    void sendEnterRaw(uint32_t, wl_resource*, wl_resource*);
    void sendLeaveRaw(uint32_t, wl_resource*);
    void sendRemovedRaw();

  private:
    struct {
        F<void(CZwpTabletPadV2*, uint32_t, const char*, uint32_t)> setFeedback;
        F<void(CZwpTabletPadV2*)> destroy;
    } requests;

    void onDestroyCalled();

    F<void(CZwpTabletPadV2*)> onDestroy;

    wl_resource* pResource = nullptr;

    CZwpTabletPadV2DestroyWrapper resourceDestroyListener;

    void* pData = nullptr;
};



#undef F
