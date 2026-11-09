From: Brian Ellis <brianellis@gotenna.com>
Date: Mon, 09 Nov 2026 10:22:31 -0700
Subject: [PATCH] usb: dwc3: apply XCVRDLY after PHY init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-dwc3-xcvrdly-after-phy-init-v1-1-488ed0a0c7da@gotenna.com>
X-B4-Tracking: v=1; b=H4sIAFYB8moC/x3MwQqDMAwA0F+RnA2kug3dr4gHbdMZGJ2kohXpv
 1t2fJd3QWQVjvCuLlDeJcovFJi6ArtM4cMorhgaal7GUI/usC0mu6v7njj5jRXX5UQJsuGT+o5
 a/5jJdlCGVdlL+u/DmPMNhc8OvG0AAAA=
To: Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Ingo Rohloff <ingo.rohloff@lauterbach.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Brian Ellis <brianellis@gotenna.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794244950; l=3926;
 i=brianellis@gotenna.com; s=20260910; h=from:subject:message-id;
 bh=jakNXExeE+3F8RWpGGZDS5fPEZqL1DBayyBy3aFZ4js=;
 b=qHYh4EC0tLu2Dq1qtTAHNTLSQp4jn5DMMM6Fhd/1GuvnW+jOInVLJ0XFKcUiTMcGnWDHfyrbl
 5LzN3MfzJxfCk7lK+FWF3LxMpP6vttnKQpS0lvcyPfANlt8X3wWUE2a
X-Developer-Key: i=brianellis@gotenna.com; a=ed25519;
 pk=JciDR8ctfMqvKeRCDP8VPwNLUDULxCAqDum6H+/ByBY=
X-Endpoint-Received: by B4 Relay for brianellis@gotenna.com/20260910 with auth_id=1022
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit a28de6335657 ("usb: dwc3: Support USB3340x ULPI PHY high-speed
negotiation.") sets GUSB2PHYCFG.XCVRDLY in dwc3_ulpi_setup(), which
dwc3_core_init() calls straight after ULPI init.  That is before
dwc3_core_get_phy(), dwc3_phy_init(), dwc3_core_soft_reset() and
dwc3_phy_power_on(), so the bit is already asserted while the PHY is
brought up.

On a ZynqMP board (DWC3 2.90a, peripheral mode) with a USB3340, that
ordering breaks high-speed links.  Each link enumerates at 480 Mbps and
passes traffic, then drops 2.20-2.23 s after enumeration, and the host's
attempts to re-enumerate the device fail.  We measured 12 such links on
two host root ports; every one died in that window.

What matters is when the bit is written, not its value.  Written at the
end of dwc3_core_init() instead, GUSB2PHYCFG holds the same value
(0x00022710 on this board), and high-speed links on the same board stay
up: one ran continuously for over 1000 s with no receive errors, and 60
re-enumeration cycles completed without a failure.

Move the dwc3_ulpi_setup() call to the end of dwc3_core_init().  The bit
is still set well before any high-speed chirp, which only happens when a
host enumerates the device.

Fixes: a28de6335657 ("usb: dwc3: Support USB3340x ULPI PHY high-speed negotiation.")
Cc: stable@vger.kernel.org
Signed-off-by: Brian Ellis <brianellis@gotenna.com>
---
How this was tested: not on mainline.  The failure and the fix were both
measured on our board running AMD's 6.6-based vendor kernel (through
ADI's tree), with a28de6335657 backported.  The backport calls
dwc3_ulpi_setup() from the same place and differs only in handling a
single USB2 port.  The 12 failing links were attached directly to two
host root ports.  The 1000 s run was through a hub, on a kernel carrying
this change plus five other local dwc3, ULPI and extcon patches.  The 60
re-enumeration cycles were direct to two root ports, on a later build
with more of our local USB fixes.  On mainline the change is
compile-tested only (x86_64 allmodconfig, W=1, no new warnings).

Not established: why the ordering matters.  The outcome follows whether
XCVRDLY is asserted before dwc3_phy_init(), not the value written, but
we have not identified which step of PHY bring-up is sensitive to it.

Ingo, if your USB3340 board is still to hand, it would help to know
whether its high-speed links stay up for more than a few seconds, with
and without this change.

Not addressed here: on our board the ULPI ID read that a28de6335657 uses
to detect the USB3340 fails when no cable is attached at boot, because
this PHY only clocks ULPI with VBUS present, so the bit is never set and
the port runs at full speed.  Fixing that needs a DT property and a
binding update, so it is not part of this fix.

Tool use: an LLM coding assistant (Claude) helped run the investigation
and keep its record, wrote the code change, and drafted this changelog
and these notes from that record.  The measurements were taken on our
hardware.
---
 drivers/usb/dwc3/core.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/usb/dwc3/core.c b/drivers/usb/dwc3/core.c
index fd5c2cd36c..9b37ceda9a 100644
--- a/drivers/usb/dwc3/core.c
+++ b/drivers/usb/dwc3/core.c
@@ -1371,8 +1371,6 @@ int dwc3_core_init(struct dwc3 *dwc)
 		dwc->ulpi_ready = true;
 	}
 
-	dwc3_ulpi_setup(dwc);
-
 	if (!dwc->phys_ready) {
 		ret = dwc3_core_get_phy(dwc);
 		if (ret)
@@ -1534,6 +1532,9 @@ int dwc3_core_init(struct dwc3 *dwc)
 		dwc3_writel(dwc, DWC3_GUCTL3, reg);
 	}
 
+	/* XCVRDLY must not be asserted across PHY init, so set it last. */
+	dwc3_ulpi_setup(dwc);
+
 	return 0;
 
 err_power_off_phy:

---
base-commit: 3149e8b3237f58d4dd440fc64c45c93404c4b064
change-id: 20261109-dwc3-xcvrdly-after-phy-init-509803f4b0c8

Best regards,
-- 
Brian Ellis <brianellis@gotenna.com>

