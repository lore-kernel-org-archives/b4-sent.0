From: Alex Kononov <alex@albefly.com>
Date: Mon, 23 Nov 2026 13:26:32 -0500
Subject: [PATCH] usb: xhci: Demote isoch buffer overrun message to debug
 level
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-xhci-overrun-dbg-v1-1-4e5a2f11740d@albefly.com>
X-B4-Tracking: v=1; b=H4sIAFeFBGsC/x3MMQqAMAxA0auUzAZsK4JeRRy0iZqlSopFkN7d4
 viG/19IrMIJRvOCcpYkZ6ywjYFwLHFnFKoG17reWufxOYLgmVn1jkjrjjyQ954sU+egZpfyJs+
 /nOZSPse2GBxiAAAA
X-Change-ID: 20261123-xhci-overrun-dbg-e9d333d1ed42
To: Mathias Nyman <mathias.nyman@intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Michal Pecio <michal.pecio@gmail.com>, Alex Kononov <alex@albefly.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795458394; l=1879;
 i=alex@albefly.com; s=20261123; h=from:subject:message-id;
 bh=u+iI1iAggLCRGR0rnKKFeDkRp02wixUihtaOmHnQhog=;
 b=BFA99X9w25yNj5WzNcCScet0Hzq+cz0KIYve1wY7kDXm51PxKZGZFfQT8ElFnnZf2BjR/bWTY
 gvvaCQNu3GvBo1YMbsL9dzh5HkpAhjp/rFBB8qn48edCVxKm3RpVz2p
X-Developer-Key: i=alex@albefly.com; a=ed25519;
 pk=ixYEiZnk4RC7w0j2uj7JxJC3KhroqtYXGx4EgLM0u/0=
X-Endpoint-Received: by B4 Relay for alex@albefly.com/20261123 with auth_id=1618
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An isochronous Buffer Overrun event means the device sent more
data than the TD could hold.
This is triggered by the device, not by a driver bug, and the
error is already reported to the class driver as
-EOVERFLOW in iso_frame_desc[].status.

Logging it with xhci_warn() can flood the kernel log.
A USB S/PDIF adapter (262a:9123) whose S/PDIF input loses its
signal produces this event on nearly every microframe,
about 7,200 messages per second, keeping systemd-journald
busy at 100% of a CPU.

Use xhci_dbg() like the other device-triggerable completion codes.

Suggested-by: Michal Pecio <michal.pecio@gmail.com>
Signed-off-by: Alex Kononov <alex@albefly.com>
---
As suggested by Michal and agreed by Mathias in the discussion:
https://lore.kernel.org/linux-usb/2ffafaa3-bdea-4d67-b224-2f18d76134be@linux.intel.com/T/

COMP_BANDWIDTH_OVERRUN_ERROR is arguably device-triggerable as well and
has been reported to flood logs (https://bugs.debian.org/1035939);
I left it alone here. Happy to send a separate patch if you think
it should get the same treatment.
---
 drivers/usb/host/xhci-ring.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/usb/host/xhci-ring.c b/drivers/usb/host/xhci-ring.c
index a1fa188680f5867e151c32ab94e2218cd6e26864..39d214e8a0289ec0b86e75833a566c2b7a91adb8 100644
--- a/drivers/usb/host/xhci-ring.c
+++ b/drivers/usb/host/xhci-ring.c
@@ -2815,7 +2815,7 @@ static int handle_tx_event(struct xhci_hcd *xhci,
 			  slot_id, ep_index);
 		break;
 	case COMP_ISOCH_BUFFER_OVERRUN:
-		xhci_warn(xhci,
+		xhci_dbg(xhci,
 			  "WARN: buffer overrun event for slot %u ep %u on endpoint",
 			  slot_id, ep_index);
 		break;

---
base-commit: 8e31dedb9ad496ea7dd7064d77d6f7d459c1c90f
change-id: 20261123-xhci-overrun-dbg-e9d333d1ed42

Best regards,
-- 
Alex Kononov <alex@albefly.com>

