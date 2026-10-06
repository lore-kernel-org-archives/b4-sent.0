From: Hans van Essen <hans@kilurion.com>
Date: Tue, 06 Oct 2026 10:06:43 +0200
Subject: [PATCH] thunderbolt: Keep Meteor Lake host routers powered in DP
 redrive mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-tb-mtl-redrive-v1-1-5ec921114c37@kilurion.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWTNJKdikXsWwsPCjYxTNtBISw
 t0psPwW7y0UoYJI12IhxSRRvmNGVRbUPe/jAyx9NlljXWWM4xT4k96s6FUmcO0CPLz1vrlQjn6
 KQeZjeGtPx394oUv7hdZ1A9/FhDFyAAAA
X-Change-ID: 20261006-tb-mtl-redrive-36be9e929945
To: Mika Westerberg <westeri@kernel.org>
Cc: Andreas Noever <andreas.noever@gmail.com>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hans van Essen <hans@kilurion.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791274009; l=2551;
 i=hans@kilurion.com; s=20261006; h=from:subject:message-id;
 bh=EqVI84jrNriCfmc4DxSSo78uh9LcZ/nE5LXz5NQilu4=;
 b=FkAOp1JcDaLEmGeafHFUpFTMSSY32is3iUXDygUiBtcc+o5aSMU3eKY+dEWoZeaAJzGQCX4PI
 2G0R7Eqbo+ZC5SyquXwTvE9Cw8bM1pmoxHGN9Z8mmCmgKucutxSQDxR
X-Developer-Key: i=hans@kilurion.com; a=ed25519;
 pk=1Qqd7FQOGBgV4kpJP4kZLbjH4wFg7+EdQaxwe+dr7Bs=
X-Endpoint-Received: by B4 Relay for hans@kilurion.com/20261006 with auth_id=1123
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a DisplayPort Alt Mode (non-Thunderbolt) dock is connected to the
USB4 port of an Arrow Lake-H system with the integrated Meteor Lake-P
host router (8086:7ec2), the USB functions of the dock work but the DP
AUX transfers time out and no monitor is detected. It only works if the
port was used with a Thunderbolt dock before and the system was not
powered off in between; suspend and warm reboot keep it working.

The Barlow Ridge host routers already have QUIRK_KEEP_POWER_IN_DP_REDRIVE
so that the host router does not enter runtime suspend while the USB4
port is in DP redrive mode. Apply the same quirk to the integrated
Meteor Lake host routers. With this the driver logs "enter redrive mode,
keeping powered" when the dock is plugged in and the monitors come up
after a cold boot.

Tested on an ASUS ROG Zephyrus G16 (GU605CW) with a Lenovo ThinkPad
USB-C Dock (40AY).

Signed-off-by: Hans van Essen <hans@kilurion.com>
---
Single patch; adds the Meteor Lake (also used by Arrow Lake) integrated
host routers to the existing Barlow Ridge redrive runtime PM quirk.
---
 drivers/thunderbolt/quirks.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/thunderbolt/quirks.c b/drivers/thunderbolt/quirks.c
index 96b7fe0..770e6f9 100644
--- a/drivers/thunderbolt/quirks.c
+++ b/drivers/thunderbolt/quirks.c
@@ -103,13 +103,19 @@ static const struct tb_quirk tb_quirks[] = {
 	{ 0x8087, PCI_DEVICE_ID_INTEL_BARLOW_RIDGE_HUB_80G_BRIDGE, 0x01ea, 0x83b5,
 		  quirk_clx_disable },
 	/*
-	 * Block Runtime PM in DP redrive mode for Intel Barlow Ridge host
-	 * controllers.
+	 * Block Runtime PM in DP redrive mode for Intel Barlow Ridge and
+	 * Meteor Lake (also Arrow Lake) host controllers.
 	 */
 	{ 0x8087, PCI_DEVICE_ID_INTEL_BARLOW_RIDGE_HOST_80G_NHI, 0x0000, 0x0000,
 		  quirk_block_rpm_in_redrive },
 	{ 0x8087, PCI_DEVICE_ID_INTEL_BARLOW_RIDGE_HOST_40G_NHI, 0x0000, 0x0000,
 		  quirk_block_rpm_in_redrive },
+	{ 0x8087, PCI_DEVICE_ID_INTEL_MTL_M_NHI0, 0x0000, 0x0000,
+		  quirk_block_rpm_in_redrive },
+	{ 0x8087, PCI_DEVICE_ID_INTEL_MTL_P_NHI0, 0x0000, 0x0000,
+		  quirk_block_rpm_in_redrive },
+	{ 0x8087, PCI_DEVICE_ID_INTEL_MTL_P_NHI1, 0x0000, 0x0000,
+		  quirk_block_rpm_in_redrive },
 	/*
 	 * CLx is not supported on AMD USB4 Yellow Carp and Pink Sardine platforms.
 	 */

---
base-commit: 74957ec2a70c08fd3ddc5ca251aaf3c3a81c82d4
change-id: 20261006-tb-mtl-redrive-36be9e929945

Best regards,
--  
Hans van Essen <hans@kilurion.com>

