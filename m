From: Peter Hutterer <peter.hutterer@who-t.net>
Date: Mon, 22 Dec 2025 09:43:36 +1000
Subject: [PATCH v2 3/4] selftests/hid: use a enum class for the different
 button types
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251222-wip-hid-pressurepad-v2-3-054ac9689bb7@who-t.net>
References: <20251222-wip-hid-pressurepad-v2-0-054ac9689bb7@who-t.net>
In-Reply-To: <20251222-wip-hid-pressurepad-v2-0-054ac9689bb7@who-t.net>
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>, 
 Shuah Khan <shuah@kernel.org>
Cc: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 linux-input@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vadim Klishko <vadim@cirque.com>, 
 Peter Hutterer <peter.hutterer@who-t.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766360621; l=7116;
 i=peter.hutterer@who-t.net; s=20251222; h=from:subject:message-id;
 bh=Lc3IOQF10ywFvV7hlfa4v/mu7pLgSPj6/TO/Ja4brfA=;
 b=be1TXsyc3klUOWVtg9Md0zXS1vSGB/carvnuIXFXabGv6/EIcszBj8qEa/lXtowogLGGmjuUn
 VUcWeCuDOOzCF/EM537qaOWU5ejZFfyzB5DSXXNd0uVkllCMcdSK+Hu
X-Developer-Key: i=peter.hutterer@who-t.net; a=ed25519;
 pk=QoL66HDbFudb9Xt36p2XxsSohZSHVHesRR9c0pI28a4=
X-Endpoint-Received: by B4 Relay for peter.hutterer@who-t.net/20251222 with auth_id=582
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of multiple spellings of a string-provided argument, let's make
this a tad more type-safe and use an enum here.

And while we do this fix the two wrong devices:
- elan_04f3_313a (HP ZBook Fury 15) is discrete button pad
- dell_044e_1220 (Dell Precision 7740) is a discrete button pad

Equivalent hid-tools commit
https://gitlab.freedesktop.org/libevdev/hid-tools/-/commit/8300a55bf4213c6a252cab8cb5b34c9ddb191625

Signed-off-by: Peter Hutterer <peter.hutterer@who-t.net>
---
 .../testing/selftests/hid/tests/test_multitouch.py | 24 +++++++++++++---------
 1 file changed, 14 insertions(+), 10 deletions(-)

diff --git a/tools/testing/selftests/hid/tests/test_multitouch.py b/tools/testing/selftests/hid/tests/test_multitouch.py
index ece0ba8e7d34b75d42245e5936ecf804c46b0846..a06a087f00b6991f7514adf7f8c713bef1a43563 100644
--- a/tools/testing/selftests/hid/tests/test_multitouch.py
+++ b/tools/testing/selftests/hid/tests/test_multitouch.py
@@ -9,6 +9,7 @@
 from . import base
 from hidtools.hut import HUT
 from hidtools.util import BusType
+import enum
 import libevdev
 import logging
 import pytest
@@ -232,11 +233,17 @@ class Digitizer(base.UHIDTestDevice):
         return 0
 
 
+class HIDButtonType(enum.IntEnum):
+    CLICKPAD = 0
+    PRESSUREPAD = 1
+    DISCRETE_BUTTONS = 2
+
+
 class PTP(Digitizer):
     def __init__(
         self,
         name,
-        type="Click Pad",
+        buttontype=HIDButtonType.CLICKPAD,
         rdesc_str=None,
         rdesc=None,
         application="Touch Pad",
@@ -244,11 +251,8 @@ class PTP(Digitizer):
         max_contacts=None,
         input_info=None,
     ):
-        self.type = type.lower().replace(" ", "")
-        if self.type == "clickpad":
-            self.buttontype = 0
-        else:  # pressurepad
-            self.buttontype = 1
+        self.buttontype = buttontype
+
         self.clickpad_state = False
         self.left_state = False
         self.right_state = False
@@ -983,7 +987,7 @@ class BaseTest:
             uhdev = self.uhdev
             evdev = uhdev.get_evdev()
 
-            if uhdev.type == "clickpad":
+            if uhdev.buttontype == HIDButtonType.CLICKPAD:
                 r = uhdev.event(click=True)
                 events = uhdev.next_sync_events()
                 self.debug_reports(r, uhdev, events)
@@ -1918,7 +1922,7 @@ class Testdell_044e_1220(BaseTest.TestPTP):
     def create_device(self):
         return PTP(
             "uhid test dell_044e_1220",
-            type="pressurepad",
+            buttontype=HIDButtonType.DISCRETE_BUTTONS,
             rdesc="05 01 09 02 a1 01 85 01 09 01 a1 00 05 09 19 01 29 03 15 00 25 01 75 01 95 03 81 02 95 05 81 01 05 01 09 30 09 31 15 81 25 7f 75 08 95 02 81 06 09 38 95 01 81 06 05 0c 0a 38 02 81 06 c0 c0 05 0d 09 05 a1 01 85 08 09 22 a1 02 15 00 25 01 09 47 09 42 95 02 75 01 81 02 95 01 75 03 25 05 09 51 81 02 75 01 95 03 81 03 05 01 15 00 26 af 04 75 10 55 0e 65 11 09 30 35 00 46 e8 03 95 01 81 02 26 7b 02 46 12 02 09 31 81 02 c0 55 0c 66 01 10 47 ff ff 00 00 27 ff ff 00 00 75 10 95 01 05 0d 09 56 81 02 09 54 25 05 95 01 75 08 81 02 05 09 19 01 29 03 25 01 75 01 95 03 81 02 95 05 81 03 05 0d 85 09 09 55 75 08 95 01 25 05 b1 02 06 00 ff 85 0a 09 c5 15 00 26 ff 00 75 08 96 00 01 b1 02 c0 06 01 ff 09 01 a1 01 85 03 09 01 15 00 26 ff 00 95 1b 81 02 85 04 09 02 95 50 81 02 85 05 09 03 95 07 b1 02 85 06 09 04 81 02 c0 06 02 ff 09 01 a1 01 85 07 09 02 95 86 75 08 b1 02 c0 05 0d 09 0e a1 01 85 0b 09 22 a1 02 09 52 15 00 25 0a 75 08 95 01 b1 02 c0 09 22 a1 00 85 0c 09 57 09 58 75 01 95 02 25 01 b1 02 95 06 b1 03 c0 c0",
         )
 
@@ -2018,7 +2022,7 @@ class Testelan_04f3_313a(BaseTest.TestPTP):
     def create_device(self):
         return PTP(
             "uhid test elan_04f3_313a",
-            type="touchpad",
+            buttontype=HIDButtonType.DISCRETE_BUTTONS,
             input_info=(BusType.I2C, 0x04F3, 0x313A),
             rdesc="05 01 09 02 a1 01 85 01 09 01 a1 00 05 09 19 01 29 03 15 00 25 01 75 01 95 03 81 02 95 05 81 03 05 01 09 30 09 31 15 81 25 7f 75 08 95 02 81 06 75 08 95 05 81 03 c0 06 00 ff 09 01 85 0e 09 c5 15 00 26 ff 00 75 08 95 04 b1 02 85 0a 09 c6 15 00 26 ff 00 75 08 95 04 b1 02 c0 06 00 ff 09 01 a1 01 85 5c 09 01 95 0b 75 08 81 06 85 0d 09 c5 15 00 26 ff 00 75 08 95 04 b1 02 85 0c 09 c6 96 80 03 75 08 b1 02 85 0b 09 c7 95 82 75 08 b1 02 c0 05 0d 09 05 a1 01 85 04 09 22 a1 02 15 00 25 01 09 47 09 42 95 02 75 01 81 02 05 09 09 02 09 03 15 00 25 01 75 01 95 02 81 02 05 0d 95 01 75 04 25 0f 09 51 81 02 05 01 15 00 26 d7 0e 75 10 55 0d 65 11 09 30 35 00 46 44 2f 95 01 81 02 46 12 16 26 eb 06 26 eb 06 09 31 81 02 05 0d 15 00 25 64 95 03 c0 55 0c 66 01 10 47 ff ff 00 00 27 ff ff 00 00 75 10 95 01 09 56 81 02 09 54 25 7f 95 01 75 08 81 02 25 01 75 01 95 08 81 03 09 c5 75 08 95 02 81 03 05 0d 85 02 09 55 09 59 75 04 95 02 25 0f b1 02 85 07 09 60 75 01 95 01 15 00 25 01 b1 02 95 0f b1 03 06 00 ff 06 00 ff 85 06 09 c5 15 00 26 ff 00 75 08 96 00 01 b1 02 c0 05 0d 09 0e a1 01 85 03 09 22 a1 00 09 52 15 00 25 0a 75 10 95 01 b1 02 c0 09 22 a1 00 85 05 09 57 09 58 75 01 95 02 25 01 b1 02 95 0e b1 03 c0 c0 05 01 09 02 a1 01 85 2a 09 01 a1 00 05 09 19 01 29 03 15 00 25 01 75 01 95 03 81 02 95 05 81 03 05 01 09 30 09 31 15 81 25 7f 35 81 45 7f 55 00 65 13 75 08 95 02 81 06 75 08 95 05 81 03 c0 c0",
         )
@@ -2110,7 +2114,7 @@ class Testsipodev_0603_0002(BaseTest.TestPTP):
     def create_device(self):
         return PTP(
             "uhid test sipodev_0603_0002",
-            type="clickpad",
+            buttontype=HIDButtonType.CLICKPAD,
             rdesc="05 01 09 02 a1 01 85 03 09 01 a1 00 05 09 19 01 29 02 25 01 75 01 95 02 81 02 95 06 81 03 05 01 09 30 09 31 15 80 25 7f 75 08 95 02 81 06 c0 c0 05 0d 09 05 a1 01 85 04 09 22 a1 02 15 00 25 01 09 47 09 42 95 02 75 01 81 02 75 01 95 02 81 03 95 01 75 04 25 05 09 51 81 02 05 01 15 00 26 44 0a 75 0c 55 0e 65 11 09 30 35 00 46 ac 03 95 01 81 02 46 fe 01 26 34 05 75 0c 09 31 81 02 05 0d c0 55 0c 66 01 10 47 ff ff 00 00 27 ff ff 00 00 75 10 95 01 09 56 81 02 09 54 25 0a 95 01 75 04 81 02 75 01 95 03 81 03 05 09 09 01 25 01 75 01 95 01 81 02 05 0d 85 0a 09 55 09 59 75 04 95 02 25 0f b1 02 85 0b 09 60 75 01 95 01 15 00 25 01 b1 02 95 07 b1 03 85 09 06 00 ff 09 c5 15 00 26 ff 00 75 08 96 00 01 b1 02 c0 05 0d 09 0e a1 01 85 06 09 22 a1 02 09 52 15 00 25 0a 75 08 95 01 b1 02 c0 09 22 a1 00 85 07 09 57 09 58 75 01 95 02 25 01 b1 02 95 06 b1 03 c0 c0 05 01 09 0c a1 01 85 08 15 00 25 01 09 c6 75 01 95 01 81 06 75 07 81 03 c0 05 01 09 80 a1 01 85 01 15 00 25 01 75 01 0a 81 00 0a 82 00 0a 83 00 95 03 81 06 95 05 81 01 c0 06 0c 00 09 01 a1 01 85 02 25 01 15 00 75 01 0a b5 00 0a b6 00 0a b7 00 0a cd 00 0a e2 00 0a a2 00 0a e9 00 0a ea 00 95 08 81 02 0a 83 01 0a 6f 00 0a 70 00 0a 88 01 0a 8a 01 0a 92 01 0a a8 02 0a 24 02 95 08 81 02 0a 21 02 0a 23 02 0a 96 01 0a 25 02 0a 26 02 0a 27 02 0a 23 02 0a b1 02 95 08 81 02 c0 06 00 ff 09 01 a1 01 85 05 15 00 26 ff 00 19 01 29 02 75 08 95 05 b1 02 c0",
         )
 

-- 
2.51.1

