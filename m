From: Peter Hutterer <peter.hutterer@who-t.net>
Date: Mon, 22 Dec 2025 09:43:37 +1000
Subject: [PATCH v2 4/4] selftests/hid: add a test for the Digitizer/Button
 Type pressurepad
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251222-wip-hid-pressurepad-v2-4-054ac9689bb7@who-t.net>
References: <20251222-wip-hid-pressurepad-v2-0-054ac9689bb7@who-t.net>
In-Reply-To: <20251222-wip-hid-pressurepad-v2-0-054ac9689bb7@who-t.net>
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>, 
 Shuah Khan <shuah@kernel.org>
Cc: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 linux-input@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vadim Klishko <vadim@cirque.com>, 
 Peter Hutterer <peter.hutterer@who-t.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766360621; l=5561;
 i=peter.hutterer@who-t.net; s=20251222; h=from:subject:message-id;
 bh=j0qjZKwtNCCu5/YF3Pfm0aG8auUBK2LU4XnpWcX86SM=;
 b=5HPb77NTJCuJUrI8Fn6q1CovxvLMLMCWKWTaQuOhX9nyCuXuNpmTatCt7dBkrl+27MnoWp84z
 izgIrMvovXrADD6mRLuf++19y000n5mtL5vYvVZ6NGNFbintzIjNIol
X-Developer-Key: i=peter.hutterer@who-t.net; a=ed25519;
 pk=QoL66HDbFudb9Xt36p2XxsSohZSHVHesRR9c0pI28a4=
X-Endpoint-Received: by B4 Relay for peter.hutterer@who-t.net/20251222 with auth_id=582
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We have to resort to a bit of a hack: python-libevdev gets the
properties from libevdev at module init time. If libevdev hasn't been
rebuilt with the new property it won't be automatically populated. So we
hack around this by constructing the property manually.

Signed-off-by: Peter Hutterer <peter.hutterer@who-t.net>
---
 .../testing/selftests/hid/tests/test_multitouch.py | 39 +++++++++++++++++++---
 1 file changed, 35 insertions(+), 4 deletions(-)

diff --git a/tools/testing/selftests/hid/tests/test_multitouch.py b/tools/testing/selftests/hid/tests/test_multitouch.py
index a06a087f00b6991f7514adf7f8c713bef1a43563..fa4fb2054bd4febb1d2497f2787944f538b27889 100644
--- a/tools/testing/selftests/hid/tests/test_multitouch.py
+++ b/tools/testing/selftests/hid/tests/test_multitouch.py
@@ -979,15 +979,36 @@ class BaseTest:
             assert libevdev.InputEvent(libevdev.EV_ABS.ABS_MT_ORIENTATION, 90) in events
 
     class TestPTP(TestWin8Multitouch):
+        def test_buttontype(self):
+            """Check for the right ButtonType."""
+            uhdev = self.uhdev
+            assert uhdev is not None
+            evdev = uhdev.get_evdev()
+
+            # If libevdev.so is not yet compiled with INPUT_PROP_PRESSUREPAD
+            # python-libevdev won't have it either, let's fake it
+            if not getattr(libevdev, "INPUT_PROP_PRESSUREPAD", None):
+                prop = libevdev.InputProperty(name="INPUT_PROP_PRESSUREPAD", value=0x7)
+                libevdev.INPUT_PROP_PRESSUREPAD = prop
+                libevdev.props.append(prop)
+
+            if uhdev.buttontype == HIDButtonType.CLICKPAD:
+                assert libevdev.INPUT_PROP_BUTTONPAD in evdev.properties
+            elif uhdev.buttontype == HIDButtonType.PRESSUREPAD:
+                assert libevdev.INPUT_PROP_PRESSUREPAD in evdev.properties
+            else:
+                assert libevdev.INPUT_PROP_PRESSUREPAD not in evdev.properties
+                assert libevdev.INPUT_PROP_BUTTONPAD not in evdev.properties
+
         def test_ptp_buttons(self):
             """check for button reliability.
-            There are 2 types of touchpads: the click pads and the pressure pads.
-            Each should reliably report the BTN_LEFT events.
+            There are 3 types of touchpads: click pads + pressure pads and
+            those with discrete buttons. Each should reliably report the BTN_LEFT events.
             """
             uhdev = self.uhdev
             evdev = uhdev.get_evdev()
 
-            if uhdev.buttontype == HIDButtonType.CLICKPAD:
+            if uhdev.buttontype in [HIDButtonType.CLICKPAD, HIDButtonType.PRESSUREPAD]:
                 r = uhdev.event(click=True)
                 events = uhdev.next_sync_events()
                 self.debug_reports(r, uhdev, events)
@@ -999,7 +1020,7 @@ class BaseTest:
                 self.debug_reports(r, uhdev, events)
                 assert libevdev.InputEvent(libevdev.EV_KEY.BTN_LEFT, 0) in events
                 assert evdev.value[libevdev.EV_KEY.BTN_LEFT] == 0
-            else:
+            elif uhdev.buttontype == HIDButtonType.DISCRETE_BUTTONS:
                 r = uhdev.event(left=True)
                 events = uhdev.next_sync_events()
                 self.debug_reports(r, uhdev, events)
@@ -2062,6 +2083,16 @@ class Testite_06cb_2968(BaseTest.TestPTP):
         )
 
 
+class Testven_0488_108c(BaseTest.TestPTP):
+    def create_device(self):
+        return PTP(
+            "uhid test ven_0488_108c",
+            rdesc="05 01 09 02 a1 01 85 06 09 01 a1 00 05 09 19 01 29 03 15 00 25 01 95 03 75 01 81 02 95 01 75 05 81 03 05 01 09 30 09 31 09 38 15 81 25 7f 75 08 95 03 81 06 c0 c0 05 0d 09 05 a1 01 85 01 05 0d 09 22 a1 02 15 00 25 01 09 47 09 42 95 02 75 01 81 02 95 01 75 03 25 05 09 51 81 02 81 03 05 01 15 00 26 ba 0d 75 10 55 0e 65 11 09 30 35 00 46 d0 05 95 01 81 02 26 d0 06 46 bb 02 09 31 81 02 05 0d 95 01 75 10 26 ff 7f 46 ff 7f 09 30 81 02 c0 05 0d 09 22 a1 02 15 00 25 01 09 47 09 42 95 02 75 01 81 02 95 01 75 03 25 05 09 51 81 02 81 03 05 01 15 00 26 ba 0d 75 10 55 0e 65 11 09 30 35 00 46 d0 05 95 01 81 02 26 d0 06 46 bb 02 09 31 81 02 05 0d 95 01 75 10 26 ff 7f 46 ff 7f 09 30 81 02 c0 05 0d 09 22 a1 02 15 00 25 01 09 47 09 42 95 02 75 01 81 02 95 01 75 03 25 05 09 51 81 02 81 03 05 01 15 00 26 ba 0d 75 10 55 0e 65 11 09 30 35 00 46 d0 05 95 01 81 02 26 d0 06 46 bb 02 09 31 81 02 05 0d 95 01 75 10 26 ff 7f 46 ff 7f 09 30 81 02 c0 55 0c 66 01 10 47 ff ff 00 00 27 ff ff 00 00 75 10 95 01 05 0d 09 56 81 02 09 54 25 05 95 01 75 08 81 02 05 09 09 01 25 01 75 01 95 01 81 02 95 07 81 03 05 0d 85 02 09 55 75 08 95 01 25 05 b1 02 09 59 b1 02 06 00 ff 85 03 09 c5 15 00 26 ff 00 75 08 96 00 01 b1 02 05 0e 09 01 a1 02 85 13 09 23 15 00 25 64 75 08 95 01 b1 02 c0 c0 05 0d 09 0e a1 01 85 04 09 22 a1 02 09 52 15 00 25 0a 75 08 95 01 b1 02 c0 09 22 a1 00 85 05 09 57 09 58 75 01 95 02 25 01 b1 02 95 06 b1 03 c0 c0 06 01 ff 09 02 a1 01 09 00 85 07 15 00 26 ff 00 75 08 96 12 02 b1 02 c0 06 00 ff 09 01 a1 01 85 0d 15 00 26 ff 00 75 08 95 11 09 01 81 02 09 01 91 02 c0 05 0e 09 01 a1 01 85 11 09 35 15 00 26 ff 00 75 08 95 17 b1 02 c0 06 81 ff 09 01 a1 01 09 20 85 17 15 00 26 ff 00 75 08 95 3f 09 01 81 02 09 01 91 02 c0",
+            input_info=(0x18, 0x0488, 0x108C),
+            buttontype=HIDButtonType.PRESSUREPAD,
+        )
+
+
 class Testn_trig_1b96_0c01(BaseTest.TestWin8Multitouch):
     def create_device(self):
         return Digitizer(

-- 
2.51.1

