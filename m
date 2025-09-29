From: Rudraksha Gupta <guptarud@gmail.com>
Date: Mon, 29 Sep 2025 00:35:13 -0700
Subject: [PATCH v4 2/4] arm64: dts: rk3399-pinephone-pro: Add accelerometer
 sensor support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250929-ppp_light_accel_mag_vol-down-v4-2-6598f22d3451@gmail.com>
References: <20250929-ppp_light_accel_mag_vol-down-v4-0-6598f22d3451@gmail.com>
In-Reply-To: <20250929-ppp_light_accel_mag_vol-down-v4-0-6598f22d3451@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, Ondrej Jirman <megi@xff.cz>, 
 Martijn Braam <martijn@brixit.nl>, 
 =?utf-8?q?Kamil_Trzci=C5=84ski?= <ayufan@ayufan.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759131312; l=1864;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=BRZsP1UdL6OFWqM2mRykWAS8dysAco3k6Kyv3eBDv+E=;
 b=qUkXHOgkg9QDIAccXCuh9iCn8uQ3DvTVFAEX5pjOxmDyP/Lb8YzSzOTQ9g1e2KPPpd/59qbKB
 g0enuB+eYi2Cnr3VE6toJhAopuGqneFWjEEu9KY9/XFj1TSugfTHMNz
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Ondrej Jirman <megi@xff.cz>

Pinephone Pro uses mpu6500 according to the schematic.

Tests:
// Setup: This watches the raw values from the device. The variable with
// the biggest magnitude and its sign will be recorded
$ sudo systemctl stop iio-sensor-proxy
$ cat /sys/bus/iio/devices/iio:device3/in_accel_{x,y,z}_raw

// Let's start with phone screen facing up to the sky and the charger
// port closer to you than the front camera.
z: -16000

// Tilt the phone onto it's left edge
x: -16000

// Tilt the phone onto it's right edge
x: 16000

// Tilt the phone so that the charger port is pointing straight up to
// the sky
y: -16000

// Tilt the phone so that the top of the phone is pointing straight up
// to the sky
y: 16000

// Put the phone face down so the screen is touching the table
z: 16000

Co-developed-by: Martijn Braam <martijn@brixit.nl>
Signed-off-by: Martijn Braam <martijn@brixit.nl>
Co-developed-by: Kamil Trzciński <ayufan@ayufan.eu>
Signed-off-by: Kamil Trzciński <ayufan@ayufan.eu>
Signed-off-by: Ondrej Jirman <megi@xff.cz>
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts b/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts
index 71d32c4bae0d0336ac0c912043618fc9b94919ef..d9f18a8005f15f3ec26e086e5b451bf1bbdc21c0 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts
@@ -542,7 +542,13 @@ mpu6500@68 {
 		reg = <0x68>;
 		interrupt-parent = <&gpio1>;
 		interrupts = <RK_PC6 IRQ_TYPE_LEVEL_LOW>;
+		vdd-supply = <&vcc_1v8>;
 		vddio-supply = <&vcc_1v8>;
+
+		mount-matrix =
+			"1", "0", "0",
+			"0", "1", "0",
+			"0", "0", "-1";
 	};
 };
 

-- 
2.51.0

