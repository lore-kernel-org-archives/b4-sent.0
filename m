From: Cunhao Lu <1579567540@qq.com>
Date: Fri, 06 Nov 2026 17:28:26 +0800
Subject: [PATCH] usb: core: hcd: Skip PHY rollback on failed autoresume
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-fix-usb-hcd-autoresume-phy-rollback-v1-1-1ed900ddcd2d@qq.com>
X-B4-Tracking: v=1; b=H4sIALmd7WoC/yXNwQ7CIBCE4Vdp9uwmhUYafRXjAegoaC0NW4ym6
 buLevwO889KghwhdGxWynhGiWmqULuGfLDTFRyHatKtNkq1hi/xxUUcBz+wLUvKkPIAz+HNOY2
 js/7OOKCHdvvOmJ5qac6os9/L6fy3FHeDX75p2rYP/5Q1aYcAAAA=
X-Change-ID: 20261106-fix-usb-hcd-autoresume-phy-rollback-e9e7e2b53667
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Alan Stern <stern@rowland.harvard.edu>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Chunfeng Yun <chunfeng.yun@mediatek.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Cunhao Lu <1579567540@qq.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793957314; l=2560;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=+UkhgORE1S10jMlcch7WwpiOoh63ObUq75ZT5p51K+0=;
 b=qMn9jaDlRH01ky+tRH0T1p+YC0f/c0Y3Dxtj7ZuSDT9aOB8MWY05ZJWqILt28oU5ZZznq7RcG
 n3eBDhIsR9vBDbD+clBxoJbVA31y6tJSzXulewfhD9IW0JLV3kJlqeC
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hcd_bus_resume() resumes the root-hub PHYs only for non-automatic PM
events, but its failure path suspends them unconditionally.

A failed autoresume therefore drops PHY power references without a
matching acquisition. If wakeup is disabled for the controller, it can
also drop PHY initialization references. Subsequent cleanup can then
report unbalanced regulator disables.

Guard the failure-path PHY suspend with !PMSG_IS_AUTO(msg), matching
the condition used for PHY resume.

Fixes: 178a0bce05cb ("usb: core: hcd: integrate the PHY wrapper into the HCD core")
Cc: stable@vger.kernel.org
Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
This USB core issue was found during the RK3572 mainlining work.

hcd_bus_resume() resumes the root-hub PHYs only for system PM, but its
failure path suspends them even for an automatic resume. This releases
PHY power references without a matching acquisition and, depending on
the wakeup policy, can also drop initialization references. Subsequent
cleanup can then produce unbalanced regulator-disable warnings.

This patch guards the failure-path PHY suspend with the same
!PMSG_IS_AUTO(msg) condition as the PHY resume. This preserves the PHY
references when an automatic resume fails and retains the existing
system-PM rollback.

Validation:

- Hardware testing on the Forlinx OK3572-C reproduced native xHCI
  Run/Stop timeouts in two USB2-only configurations. With the fix,
  eleven failed automatic resumes returned -ESHUTDOWN. Tracing showed
  unchanged PHY initialization and power counts across each call, no
  extra PHY suspend, power-off or exit calls, and no regulator warnings.
  No trace events were lost or probes missed.
---
 drivers/usb/core/hcd.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/core/hcd.c b/drivers/usb/core/hcd.c
index 8e8a5f59b319b..fc4c28b7d4398 100644
--- a/drivers/usb/core/hcd.c
+++ b/drivers/usb/core/hcd.c
@@ -2368,7 +2368,9 @@ int hcd_bus_resume(struct usb_device *rhdev, pm_message_t msg)
 		}
 	} else {
 		hcd->state = old_state;
-		usb_phy_roothub_suspend(hcd->self.sysdev, hcd->phy_roothub);
+		if (!PMSG_IS_AUTO(msg))
+			usb_phy_roothub_suspend(hcd->self.sysdev,
+						hcd->phy_roothub);
 		dev_dbg(&rhdev->dev, "bus %s fail, err %d\n",
 				"resume", status);
 		if (status != -ESHUTDOWN)

---
base-commit: a804c5742bff224d4cb4d25dd383554d598be32b
change-id: 20261106-fix-usb-hcd-autoresume-phy-rollback-e9e7e2b53667

Best regards,
--  
Cunhao Lu <1579567540@qq.com>

