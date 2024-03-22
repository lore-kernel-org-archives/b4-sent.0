From: Janne Grunau <j@jannau.net>
Subject: [PATCH v3 0/6] USB keyboard improvements for asahi / desktop
 systems
Date: Fri, 22 Mar 2024 08:47:03 +0100
Message-Id: <20240322-asahi-keyboards-v3-0-3106dd4c4e19@jannau.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHc3/WUC/2XN0QrCIBTG8VcJrzM8R2nWVe8RXWgemwUudElj7
 N1zI4jY5f+D8zsjy5QCZXbcjCxRCTl0sYbcbti1NfFGPLjaDAUqgaC5yaYN/EGD7UxymXt0zng
 hEC2yevVM5MN7Ec+X2m3IfZeG5UGBef1aCCurABdcg7JIjYLmIE53E6N57SL1bMYK/gAJzRrAC
 jjpldVSK7/Xf8A0TR+TSoeZ8AAAAA==
To: Bin Meng <bmeng.cn@gmail.com>, Marek Vasut <marex@denx.de>, 
 Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Joe Hershberger <joe.hershberger@ni.com>
Cc: u-boot@lists.denx.de, asahi@lists.linux.dev, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3162; i=j@jannau.net;
 h=from:subject:message-id; bh=svsswazAvj+ohqZ8/5rv0sVrY14pCNTj2K2lFULM2ww=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtS/5s0GXLeOHONl9AkVi+e94ZIb1qUnw8xQJcd6pPNuw
 2m2gtiOUhYGMS4GWTFFliTtlx0Mq2sUY2ofhMHMYWUCGcLAxSkAE1k/j+F/aOvs/lX7Azi86tZf
 8Niw2ThkL4PFspgZyutZWKZsWlP1iZGhQfvoXoEzdv6zvH+u2zM9J7ixPv+W8zH+iI7iE4F5wZu
 5AA==
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
Changes in v3:
- collected "Reviewed-by:" tags
- rename usb_blocklist to usb_ignorelist
- use BIT macro for USB KBD quirk bit
- refactor usb_device_is_blocked() to use 0 / negated errors as return
  value, sed -e 's/block/ignore/', simplify it and add comments
- rewritten usb_ignorelist documentation
- Link to v2: https://lore.kernel.org/r/20240317-asahi-keyboards-v2-0-d3f4b8384f68@jannau.net

Changes in v2:
- rewritten commit message for "[PATCH 2/6] usb: xhci: Set up endpoints for the first 2 interfaces"
- Replaced the usb keyboard Yubikey block with an env based USB device blocklist
- Use "-EINVAL" as return value in "[PATCH 3/6] usb: xhci: Abort transfers with unallocated rings"
- added "Reviewed-by:" tags
- Link to v1: https://lore.kernel.org/r/20240221-asahi-keyboards-v1-0-814b2e741790@jannau.net

---
Janne Grunau (6):
      usb: xhci: refactor xhci_set_configuration
      usb: xhci: Set up endpoints for the first 2 interfaces
      usb: xhci: Abort transfers with unallocated rings
      usb: Add environment based device ignorelist
      usb: kbd: support Apple Magic Keyboards (2021)
      usb: kbd: Add probe quirk for Apple and Keychron keyboards

 common/usb.c                 |  57 ++++++++++++++++++++
 common/usb_kbd.c             |  59 ++++++++++++++++++--
 doc/usage/environment.rst    |  13 +++++
 drivers/usb/host/xhci-ring.c |   5 ++
 drivers/usb/host/xhci.c      | 126 +++++++++++++++++++++++++++----------------
 include/env_default.h        |  11 ++++
 include/usb.h                |   6 +++
 7 files changed, 228 insertions(+), 49 deletions(-)
---
base-commit: 37345abb97ef0dd9c50a03b2a72617612dcae585
change-id: 20240218-asahi-keyboards-f2ddaf0022b2

Best regards,
-- 
Janne Grunau <j@jannau.net>

