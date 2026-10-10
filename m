From: Igor Velkov <iav@iav.lv>
Date: Sat, 10 Oct 2026 23:00:16 +0300
Subject: [PATCH] arm64: dts: rockchip: Add the buzzer to Kobol Helios64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-helios64-beeper-v1-1-6235643158cf@iav.lv>
X-B4-Tracking: v=1; b=H4sIAFCZymoC/x3MwQpAQBRG4VfRXbt1ZwzJq8hi8OOW0ExJad7dZ
 PktznkpIigidcVLAbdGPY8MUxY0bf5YwTpnkxXbGDHCo+MNu56xcTwCFwJ7Uwmst1UtLeXwClj
 0+af9kNIHU5U6eGQAAAA=
To: Heiko Stuebner <heiko@sntech.de>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1395; i=iav@iav.lv;
 h=from:subject:message-id; bh=CLjRnKOQVnSgjGYiJTawa4WmYQi+xZfiDphqtnkUSz0=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFmnZgZGPnopq23L8KTpTftrtQJp7gzji4+ZMvW/F58Ie
 +W8cPLpjlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjCRrXIM/wyqdJSauPsM2HNq
 bZt9Tv3l2RL3XP6PRmEmT1eES3jvNIb/EbXJe2aGTNzAqqE4W9+N0fHuHI/cz4otD3aEh13yXcf
 JDwA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Helios64 has a 2-pin header, P4, for an external buzzer: pin 1 is 5 V,
pin 2 is switched to ground by a MOSFET driven from GPIO4_D3
(BUZZER_ON), active high. Describe it as a gpio-beeper.

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Schematic, sheets 30 and 35:
https://wiki.kobol.io/helios64/files/schematics/Helios64_Schematics_Rev1.2.pdf
P4 in the header list ("Buzzer Alarm Speaker"):
https://wiki.kobol.io/helios64/hardware/

Tested on mainline: GPIO4_D3 follows the beeper input events. Nothing is
plugged into P4 here, so no sound check.
---
 arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
index 63ad79b4c8ac..d84b777b7153 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
@@ -58,6 +58,11 @@ avdd_1v8_s0: regulator-avdd-1v8-s0 {
 		vin-supply = <&vcc3v3_sys_s3>;
 	};
 
+	beeper {
+		compatible = "gpio-beeper";
+		gpios = <&gpio4 RK_PD3 GPIO_ACTIVE_HIGH>;
+	};
+
 	chosen {
 		stdout-path = "serial2:1500000n8";
 	};

---
base-commit: d2abcbb905b0e4b2e06b257fa1e5bcf4faa6dbda
change-id: 20261010-b4-helios64-beeper-a130e2a23508

Best regards,
-- 
Igor Velkov <iav@iav.lv>

