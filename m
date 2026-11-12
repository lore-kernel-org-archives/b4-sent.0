From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:25:10 +0000
Subject: [PATCH v2] arm64: dts: rockchip: Mark the Orange Pi 5/5B Type-C
 port self-powered
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-opi5-typec-self-powered-v2-1-751906d65b70@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMywrCMBBG4Vcps3bADGqKryIuNPmjI9KETOuF0
 nc36vJbnDOToSqM9t1MFQ81zUODrDoK19NwAWtsJlnLzjknnItueXwXBDbcE5f8REXk5KMX9Kn
 feE+tLhVJX7/z4fi3Tecbwvjd0bJ8AOfJKHV7AAAA
X-Change-ID: 20261112-opi5-typec-self-powered-f7d72e8f8477
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794471910; l=2783;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=mTmto45zL5e2iy6mJQ65zZtp+JqwhKT47UOcR9QvZRQ=;
 b=Gtwhzcqebs2Kpwt08HAdD8Qmf1L/z6vUvuOwPX1Ky3oxf+oEt+2w3jJEJo88J2CuUBKldcwSc
 KQGJEpMdbAPAfO9D10xRFhsNrlq7dKTKXsCPtvqWU4evetVlaPJ2oQk
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The board is powered from its separate power-only USB-C input. The
FUSB302 port's VBUS comes from vcc5v0_sys through a load switch, so the
board never runs from this port's VBUS.

Without self-powered, tcpm keeps Rp on CC during PORT_RESET (error
recovery), because opening CC on a port-powered device would remove its
own supply. With self-powered, the port opens CC for tErrorRecovery
whenever it resets, including at boot. A partner left in a stale state
by a warm reboot then sees a real detach.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
This was patch 3 of the series "usb: typec: Find a Type-C partner
after a warm reboot on the Orange Pi 5"; it is split out of v2 of that
series so that it goes through the Rockchip tree. It does not depend on
that series to build, but without its tcpm patch ("usb: typec: tcpm:
Don't cut a pending state delay short on a re-queue" [1]) the open-CC
period at boot is cut short.

It touches the line next to the one my "arm64: dts: rockchip: Add
USB-C DP AltMode for Orange Pi 5/5B" (opi5-dts v2) adds a node to;
applying both needs git am -3 (no conflict). I can resend it rebased.

Tested on an Orange Pi 5 together with that series (v1): after a warm
reboot the USB-C DisplayPort cable was detected on 4/4 boots, and in a
later run of 30 reboots the partner was attached on 30/30, with CC
opened in PORT_RESET for 100-112 ms on every boot. Not tested on the
Orange Pi 5B (same dtsi). CHECK_DTBS for the Orange Pi 5 and 5B shows
no new warnings.

This patch was developed with Claude (Anthropic) as a coding assistant:
it wrote the change and the commit message, and I reviewed and tested
it as described above.

[1] https://lore.kernel.org/r/20261112-tcpm-attach-reboot-v2-1-b4bc6ca83490@gmail.com

Changes in v2:
- Split out of the USB series, where it was patch 3/3; unchanged
- Link to v1: https://patch.msgid.link/20261110-tcpm-attach-reboot-v1-3-7657cc1e2dca@gmail.com
---
 arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi
index c153e7248727..04cc0b4ff661 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi
@@ -142,6 +142,7 @@ usb_con: connector {
 				<PDO_FIXED(5000, 1000, PDO_FIXED_USB_COMM)>;
 			source-pdos =
 				<PDO_FIXED(5000, 3000, PDO_FIXED_USB_COMM)>;
+			self-powered;
 			try-power-role = "source";
 
 			ports {

---
base-commit: c3baae5f1a15645cddadcb2b9abddef5df291f59
change-id: 20261112-opi5-typec-self-powered-f7d72e8f8477

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

