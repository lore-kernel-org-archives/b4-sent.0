From: Mizuno Miotsuki <founder@crepuse.com>
Date: Tue, 13 Oct 2026 23:04:52 +0800
Subject: [PATCH v3] arm64: dts: rockchip: add UNIHIKER M10 V1.2 touchscreen
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-review-self-touchscreen-v3-20261013-v3-1-beec2a35cdb8@crepuse.com>
References: <20261013-review-self-touchscreen-v3-20261013-v3-0-beec2a35cdb8@crepuse.com>
In-Reply-To: <20261013-review-self-touchscreen-v3-20261013-v3-0-beec2a35cdb8@crepuse.com>
To: heiko@sntech.de
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-rockchip@lists.infradead.org, conor+dt@kernel.org, krzk+dt@kernel.org, 
 robh@kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1528; i=founder@crepuse.com;
 s=20261012; h=from:subject:message-id;
 bh=niQemHq0zIYyejRqSf64CgT+VZtMHF21KC+IBXETBh4=;
 b=kA0DAAoWFtY8A0Xkb6QByyZiAGrOSJOg3Uk1iEB/UQW6AHIMhLgXnDiU/com3J6bMPYkquRg5
 4iRBAAWCgA5FiEEmxUHd8KDqNadkII+FtY8A0Xkb6QFAmrOSJMbFIAAAAAABAAObWFudTIsMi41
 KzEuMTIsMCwzAAoJEBbWPANF5G+k60YBAJhYsdJkB1AQZ/lpiN34RkGKJ+49aU5kZqH53WFi8OO
 HAQCi6cmGzLlP1oQ4AldK1QEhNyzjsfgcY19W2UmQtAzOBg==
X-Developer-Key: i=founder@crepuse.com; a=openpgp;
 fpr=9B150777C283A8D69D90823E16D63C0345E46FA4
X-Endpoint-Received: by B4 Relay for founder@crepuse.com/20261012 with auth_id=1166
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the NS2009 on I2C2 with the validated raw Z1 contact threshold and
Y-axis inversion. Connect its VDD to the existing always-on vcc_io supply.

The NS2009 VDD is connected to the board's common 3.3 V rail, represented
by vcc_io. This connection was verified by continuity measurements
against the exposed 3.3 V header. Additional measurements around the
SD/MMC interface and SoC decoupling capacitors are consistent with the
existing vcc_io supply topology.

Reuse the existing supply without adding an enable GPIO or changing its
shared supply constraints. The 10-pin NS2009 has no separate VREF pin.
PENIRQ routing has not been established; retain polling without declaring
an interrupt or claiming that the pin is disconnected.

Signed-off-by: Mizuno Miotsuki <founder@crepuse.com>
---
 arch/arm64/boot/dts/rockchip/rk3308-unihiker-m10-v1.2.dts | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3308-unihiker-m10-v1.2.dts b/arch/arm64/boot/dts/rockchip/rk3308-unihiker-m10-v1.2.dts
index 0c03f118378a..933d3a139ace 100644
--- a/arch/arm64/boot/dts/rockchip/rk3308-unihiker-m10-v1.2.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3308-unihiker-m10-v1.2.dts
@@ -134,6 +134,14 @@ &emmc {
 &i2c2 {
 	clock-frequency = <400000>;
 	status = "okay";
+
+	touchscreen@48 {
+		compatible = "nsiway,ns2009";
+		reg = <0x48>;
+		vdd-supply = <&vcc_io>;
+		touchscreen-min-pressure = <150>;
+		touchscreen-inverted-y;
+	};
 };
 
 &io_domains {

-- 
2.56.0

