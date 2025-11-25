From: Rudraksha Gupta <guptarud@gmail.com>
Date: Mon, 24 Nov 2025 19:47:02 -0800
Subject: [PATCH v5 3/4] arm64: dts: rockchip: Add magnetometer sensor to
 Pinephone Pro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251124-ppp_light_accel_mag_vol-down-v5-3-f9a10a0a50eb@gmail.com>
References: <20251124-ppp_light_accel_mag_vol-down-v5-0-f9a10a0a50eb@gmail.com>
In-Reply-To: <20251124-ppp_light_accel_mag_vol-down-v5-0-f9a10a0a50eb@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>, 
 Ondrej Jirman <megi@xff.cz>, "Leonardo G. Trombetta" <lgtrombetta@gmx.com>, 
 Pavel Machek <pavel@ucw.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764042420; l=1356;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=6kNPA+rufMDaioiLjzVrw3yC2YKarI4Xs7vCiBTyO0Y=;
 b=mjYYXO4VbxbQzJyStmB8AZAeOSbBj75gjJppJVbTQOdHHt/2CWOeQhbgrytShK5eHi5ku4QNZ
 fuP4qIKj7w2AxQqtJKaj3+ht/F8kA6jIf1mEFpB6PerrijUO2jTOo6z
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Ondrej Jirman <megi@xff.cz>

Pinephone Pro uses AF8133J according to the schematic.

The mount-matrix was added by Leonardo on top of Ondrej's work of adding
the magnetometer. It was verified with Leonardo's compass app:

https://gitlab.com/lgtrombetta/compass

Co-developed-by: Leonardo G. Trombetta <lgtrombetta@gmx.com>
Signed-off-by: Leonardo G. Trombetta <lgtrombetta@gmx.com>
Signed-off-by: Ondrej Jirman <megi@xff.cz>
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
Reviewed-by: Pavel Machek <pavel@ucw.cz>
---
 arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts b/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts
index f8c74b43ae9f..03721d71766c 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts
@@ -553,6 +553,21 @@ mpu6500@68 {
 	};
 };
 
+&i2c4 {
+	af8133j: compass@1c {
+		compatible = "voltafield,af8133j";
+		reg = <0x1c>;
+		reset-gpios = <&gpio1 RK_PA1 GPIO_ACTIVE_LOW>;
+		avdd-supply = <&vcc_3v0>;
+		dvdd-supply = <&vcc_1v8>;
+
+		mount-matrix =
+			"0", "1", "0",
+			"-1", "0", "0",
+			"0", "0", "1";
+	};
+};
+
 &io_domains {
 	bt656-supply = <&vcc1v8_dvp>;
 	audio-supply = <&vcca1v8_codec>;

-- 
2.52.0

