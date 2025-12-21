From: Peter Hutterer <peter.hutterer@who-t.net>
Subject: [PATCH v2 0/4] HID: multitouch: set INPUT_PROP_PRESSUREPAD on
 compatible touchpads
Date: Mon, 22 Dec 2025 09:43:33 +1000
Message-Id: <20251222-wip-hid-pressurepad-v2-0-054ac9689bb7@who-t.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NMQ7CMAxFr1J5xihJFaiYuAfqEDUu8ZJWcZuCq
 tydUDHi7f2v/7yDUGISuDU7JMosPMUK5tTAEFx8ErKvDEYZq+vhxjMG9jgnElkTzc5j5zqlBj/
 qTrdQl7Ub+XVYH33lwLJM6X08yfqb/nzmvy9rVEitIWsv1llzvW9hwuUcaYG+lPIB4agIIrYAA
 AA=
X-Change-ID: 20251111-wip-hid-pressurepad-8a800cdf1813
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>, 
 Shuah Khan <shuah@kernel.org>
Cc: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 linux-input@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vadim Klishko <vadim@cirque.com>, 
 Peter Hutterer <peter.hutterer@who-t.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766360621; l=1571;
 i=peter.hutterer@who-t.net; s=20251222; h=from:subject:message-id;
 bh=QBoH70Dkw89XQVaUU1T4z/oKmYh+dG59fCRv+673Egs=;
 b=cOwtMVQybWIsiV2IZpx4Z3rgHj+lWv5Y7FsaRvwvPvr7dSB6F71+YsnU5Emg2bPD7Eyki6K3m
 iT/VWkIKDAqC7BOJkSwGpjTge9T7D5GXAeV1JGhERfp5FwiUGmBfEqc
X-Developer-Key: i=peter.hutterer@who-t.net; a=ed25519;
 pk=QoL66HDbFudb9Xt36p2XxsSohZSHVHesRR9c0pI28a4=
X-Endpoint-Received: by B4 Relay for peter.hutterer@who-t.net/20251222 with auth_id=582
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Nicely enough MS defines a button type for a pressurepad touchpad [2]
and it looks like most touchpad vendors fill this in.

The selftests require a bit of prep work (and a hack for the test
itself) - hidtools 0.12 requires python-libevdev 0.13 which in turn
provides constructors for unknown properties.

[2] https://learn.microsoft.com/en-us/windows-hardware/design/component-guidelines/touchpad-windows-precision-touchpad-collection#device-capabilities-feature-report

Signed-off-by: Peter Hutterer <peter.hutterer@who-t.net>
---
Changes in v2:
- rebased on top of 6.18
- hid-multitouch changes split out into a separate patch
- Patches reordered for slightly nicer history, tests changes are
  grouped together
- Link to v1: https://lore.kernel.org/r/20251121-wip-hid-pressurepad-v1-0-e32e5565a527@who-t.net

---
Peter Hutterer (4):
      HID: multitouch: set INPUT_PROP_PRESSUREPAD based on Digitizer/Button Type
      selftests/hid: require hidtools 0.12
      selftests/hid: use a enum class for the different button types
      selftests/hid: add a test for the Digitizer/Button Type pressurepad

 drivers/hid/hid-multitouch.c                       | 12 ++++-
 tools/testing/selftests/hid/tests/conftest.py      | 14 +++++
 .../testing/selftests/hid/tests/test_multitouch.py | 61 +++++++++++++++++-----
 3 files changed, 73 insertions(+), 14 deletions(-)
---
base-commit: 7d0a66e4bb9081d75c82ec4957c50034cb0ea449
change-id: 20251111-wip-hid-pressurepad-8a800cdf1813

Best regards,
-- 
Peter Hutterer <peter.hutterer@who-t.net>

