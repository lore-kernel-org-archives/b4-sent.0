From: Igor Velkov <iav@iav.lv>
Date: Sun, 11 Oct 2026 00:51:50 +0300
Subject: [PATCH] arm64: dts: rockchip: Enable USB host0 on Kobol Helios64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-b4-helios64-usb-host0-v1-1-693fe316701b@iav.lv>
X-B4-Tracking: v=1; b=H4sIAHWzymoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0ND3SQT3YzUnMz8YjMT3dLiJN2M/OISA10TgyTjpORkC1NDQ3MloN6
 CotS0zAqwudGxtbUAu+CJwmcAAAA=
To: Heiko Stuebner <heiko@sntech.de>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1470; i=iav@iav.lv;
 h=from:subject:message-id; bh=sOQzi5FpUnQRY9CzfpIrcgu8d6QPkrlieETtWvyjiVY=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFmnNpf/zlN1581VmqNuLyprdcWlMpZj80sDU8ZykT6+D
 RcWO0h2lLIwiHExyIopskw4pHErY8nVv/4e5g9g5rAygQxh4OIUgInwczEybH/0/9C+3PN1zzZI
 LUzmOJf4997RfcUb2KbPe/G8KPL1KkFGhvM7tePOGvs3n8i02n5VSWP2g1/RBw1qf11NXiIj8PP
 WW0YA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

USB host0 of the RK3399 (USB0_DP/DN) is wired to the USB 2.0 pins of
the M.2 Key-B slot J2. Enable the host port of u2phy0 and the EHCI and
OHCI controllers behind it.

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Schematic, sheet 33:
https://wiki.kobol.io/helios64/files/schematics/Helios64_Schematics_Rev1.2.pdf

Tested on mainline: the EHCI and OHCI root hubs come up. The M.2 slot
is empty here, so no device was attached.
---
 arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
index 63ad79b4c8ac..ae887806f21d 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
@@ -639,6 +639,15 @@ &tsadc {
 	status = "okay";
 };
 
+&u2phy0 {
+	status = "okay";
+
+	host-port {
+		/* phy for &usb_host0_ehci and &usb_host0_ohci, M.2 slot */
+		status = "okay";
+	};
+};
+
 &u2phy1 {
 	status = "okay";
 
@@ -653,6 +662,14 @@ &uart2 {
 	status = "okay";
 };
 
+&usb_host0_ehci {
+	status = "okay";
+};
+
+&usb_host0_ohci {
+	status = "okay";
+};
+
 &usbdrd3_1 {
 	status = "okay";
 

---
base-commit: d2abcbb905b0e4b2e06b257fa1e5bcf4faa6dbda
change-id: 20261011-b4-helios64-usb-host0-40b3bcc85117

Best regards,
-- 
Igor Velkov <iav@iav.lv>

