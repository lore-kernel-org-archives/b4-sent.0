From: Janne Grunau <j@jannau.net>
Subject: [PATCH 0/6] USB keyboard improvements for asahi / desktop systems
Date: Wed, 21 Feb 2024 08:25:00 +0100
Message-Id: <20240221-asahi-keyboards-v1-0-814b2e741790@jannau.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEyl1WUC/x3MMQqAMAxA0atIZgttcBCvIg7RpjYIrTQgivTuF
 sc3/P+CchFWmLoXCl+iklOD6zvYIqWdjfhmQIuDRTcaUopiDn7WTMWrCeg9BWsRV4RWnYWD3P9
 xXmr9ADamOS9hAAAA
To: Bin Meng <bmeng.cn@gmail.com>, Marek Vasut <marex@denx.de>, 
 Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, asahi@lists.linux.dev, 
 Janne Grunau <j@jannau.net>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2193; i=j@jannau.net;
 h=from:subject:message-id; bh=ynOznLwaFS4HtoVUVCPAAF/KFqCJNndMCJjEjVINauk=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtSrSyNr/MS2lfI4dTBvXRT49uv5Ak1tv8naBic3fgq4e
 Se54iBzRykLgxgXg6yYIkuS9ssOhtU1ijG1D8Jg5rAygQxh4OIUgIm8PMnI0PXx3ZqjPnl3Sv5L
 c1TsuL71RfTNo8bet+Yy/52+ML+AV5bhr/jTuUXPLn9v+VYV3/zn5J/WdKF4jcu10W/5N+pW7Lu
 uzAwA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apple USB Keyboards from 2021 need quirks to be useable. The boot HID
keyboard protocol is unfortunately not described in the first interface
descriptor but the second. This needs several changes. The USB keyboard
driver has to look at all (2) interface descriptors during probing.
Since I didn't want to rebuild the USB driver probe code the Apple
keyboards are bound to the keyboard driver via USB vendor and product
IDs.
To make the keyboards useable on Apple silicon devices the xhci driver
needs to initializes rings for the endpoints of the first two interface
descriptors. If this is causes concerns regarding regressions or memory
use the USB_MAX_ACTIVE_INTERFACES define could be turned into a CONFIG
option.
Even after this changes the keyboards still do not probe successfully
since they apparently do not behave HID standard compliant. They only
generate reports on key events. This leads the final check whether the
keyboard is operational to fail unless the user presses keys during the
probe. Skip this check for known keyboards.
Keychron seems to emulate Apple keyboards (some models even "re-use"
Apple's USB vendor ID) so apply this quirk as well.

Some devices like Yubikeys emulate a keyboard. since u-boot only binds a
single keyboard block this kind of devices from the USB keyboard driver.

Signed-off-by: Janne Grunau <j@jannau.net>
---
Hector Martin (1):
      usb: kbd: Ignore Yubikeys

Janne Grunau (5):
      usb: xhci: refactor xhci_set_configuration
      usb: xhci: Set up endpoints for the first 2 interfaces
      usb: xhci: Abort transfers with unallocated rings
      usb: kbd: support Apple Magic Keyboards (2021)
      usb: kbd: Add probe quirk for Apple and Keychron keyboards

 common/usb_kbd.c             |  80 +++++++++++++++++++++++++--
 drivers/usb/host/xhci-ring.c |   5 ++
 drivers/usb/host/xhci.c      | 126 +++++++++++++++++++++++++++----------------
 include/usb.h                |   6 +++
 4 files changed, 167 insertions(+), 50 deletions(-)
---
base-commit: 37345abb97ef0dd9c50a03b2a72617612dcae585
change-id: 20240218-asahi-keyboards-f2ddaf0022b2

Best regards,
-- 
Janne Grunau <j@jannau.net>

