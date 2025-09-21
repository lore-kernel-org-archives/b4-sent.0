From: Rudraksha Gupta <guptarud@gmail.com>
Date: Sat, 20 Sep 2025 23:41:04 -0700
Subject: [PATCH 2/5] arm64: dts: rk3399-pinephone-pro: Add accelerometer
 sensor support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250920-ppp_light_accel_mag_vol-down-v1-2-c8bbcd3e2e94@gmail.com>
References: <20250920-ppp_light_accel_mag_vol-down-v1-0-c8bbcd3e2e94@gmail.com>
In-Reply-To: <20250920-ppp_light_accel_mag_vol-down-v1-0-c8bbcd3e2e94@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, Ondrej Jirman <megi@xff.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758436863; l=883;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=SfqrwYTRcKhC1h7DV8dOsoX/vi0YcmV/gXhDpcpF9vw=;
 b=7qCe7uXU7IlkiQxeGNCcIveyXGrAhfeincuEYiMyWR3o4jwBCh7vttA2bIreRtDoMYHdckn/x
 Q6Kd7ALLhJmDazfyL4BMXqDB6MJlB20zGdduy4HUWaONbY0qPnOpsoz
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Ondrej Jirman <megi@xff.cz>

Pinephone Pro uses mpu6500.

Signed-off-by: Ondrej Jirman <megi@xff.cz>
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts b/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts
index 7d1257a3f2e0cbdc65a810062ecd5117f9f5b687..da7ce905152269436410b959be937e07c23772b2 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts
@@ -544,7 +544,13 @@ mpu6500@68 {
 		reg = <0x68>;
 		interrupt-parent = <&gpio1>;
 		interrupts = <RK_PC6 IRQ_TYPE_LEVEL_LOW>;
+		vdd-supply = <&vcc_1v8>;
 		vddio-supply = <&vcc_1v8>;
+
+		mount-matrix =
+			"1", "0", "0",
+			"0", "-1", "0",
+			"0", "0", "1";
 	};
 };
 

-- 
2.51.0

