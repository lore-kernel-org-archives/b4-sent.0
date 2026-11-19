From: Oleh Kurudz <admin@or1k.net>
Subject: [PATCH 0/2] USB: core: Disconnect a parent hub on suspend for
 HyperX QuadCast S
Date: Fri, 20 Nov 2026 00:22:24 +0200
Message-Id: <20261120-quadcast-s-suspend-v1-0-add8ccf12c8f@or1k.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3MQQrCQAwF0KuEv26gGaHUuYq4iDNRsxnrxBah9
 O6C7wBvR1h3C2Ta0W3z8FdDJhkI5antYewVmZDGNImkkd+r1qLx4eBYY7FW+SY1yWk+a5kVA2H
 pdvfvP71cj+MH5I456WQAAAA=
X-Change-ID: 20261120-quadcast-s-suspend-b1d21389ac8a
To: Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Alan Stern <stern@rowland.harvard.edu>, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-usb@vger.kernel.org, 
 Oleh Kurudz <admin@or1k.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795126946; l=2397;
 i=admin@or1k.net; s=20261120; h=from:subject:message-id;
 bh=MEMGo5g61PY933MO5JFk74iMl4YxUIg5MC75DGdWosk=;
 b=oeyFB+9TSEv7kTebJT0NfJPxoY8q8EsyAow+xcjI6Qn/S5NM8UElZzB8O5iL8iD4/dcXjZGOQ
 5mdAdBGPWJ7Bnjy1BeuSYYf/YbCRALEkaF8vXCwUcwEszD1xDQEBuuw
X-Developer-Key: i=admin@or1k.net; a=ed25519;
 pk=99OKf9VLJkjldneE6gRk0c6oTl7G+EdqRiFo4h8sH6Q=
X-Endpoint-Received: by B4 Relay for admin@or1k.net/20261120 with auth_id=1577
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HyperX QuadCast S microphone is an audio function and an HID (RGB)
function behind a hub built into the microphone. During system suspend
the HID function drops off that hub, and the hub then wakes the system
even though remote wakeup is disabled for it. On s2idle machines the
suspend bounces back within about a second. Users report the same
symptom online, with unplugging the microphone as the usual workaround.

The existing USB_QUIRK_DISCONNECT_SUSPEND would fix this if it were set
on the hub, but the hub is a generic Huasheng 214b:7250 chip, and setting
the quirk on it would also stop keyboards behind other hubs with that
chip from waking the system. So patch 1 adds a quirk for the child
device that makes usb_suspend() disable the upstream port of its parent
hub, and patch 2 sets it for the two QuadCast S functions.

Other QuadCast models (QuadCast, QuadCast 2, the HP-era 03f0:xxxx IDs)
may have the same problem, but I only have the QuadCast S to test with.
They can be tried with usbcore.quirks=<vid>:<pid>:s.

Tested on usb-next (7.4.0-rc3) on an AMD laptop with s2idle.

How this was made: I had been working around the problem with a
systemd-sleep hook that disabled the microphone's upstream port, and
asked an AI coding assistant (Claude, claude-opus-5-5) to turn it into
a kernel fix. It read the USB core code, proposed the approach, wrote
both patches and the changelogs, and built the test kernel. I reviewed
the patches and ran the tests on my laptop: with the quirk cleared via
usbcore.quirks the bouncing suspend is reproducible, with it the system
stays suspended. checkpatch.pl --strict is clean and each patch builds
on its own with W=1.

Signed-off-by: Oleh Kurudz <admin@or1k.net>
---
Oleh Kurudz (2):
      USB: core: Add USB_QUIRK_DISCONNECT_PARENT_SUSPEND
      USB: quirks: Add USB_QUIRK_DISCONNECT_PARENT_SUSPEND for HyperX QuadCast S

 Documentation/admin-guide/kernel-parameters.txt |  5 +++++
 drivers/usb/core/driver.c                       | 20 +++++++++++++++++++-
 drivers/usb/core/quirks.c                       |  9 +++++++++
 include/linux/usb/quirks.h                      |  7 +++++++
 4 files changed, 40 insertions(+), 1 deletion(-)
---
base-commit: f11fe7603df07fbb9fa02b0d385c1696c87a6dab
change-id: 20261120-quadcast-s-suspend-b1d21389ac8a

Best regards,
-- 
Oleh Kurudz <admin@or1k.net>

