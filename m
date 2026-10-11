From: Ryan Leung <untilscour@protonmail.com>
Date: Sun, 11 Oct 2026 06:27:42 +0000
Subject: [PATCH] arm64: dts: rockchip: add maskrom and recovery ADC buttons
 to NanoPi M5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-nanopi-m5-adc-v1-1-822edeb1acf4@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAF0sy2oC/yXMTQ5AMBBA4avIrE3S+g1XEYtqByNR0iIScXfF8
 lu8d4Enx+Shji5wdLDnxQbIOAI9KjsQsgmGRCSFFFKiVXZZGeccldFYkEhN1qVVXpYQmtVRz+f
 3a9rffu8m0ts7gft+ABA07nZxAAAA
X-Change-ID: 20261011-nanopi-m5-adc-6e03d4b39577
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ryan Leung <untilscour@protonmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791700071; l=1728;
 i=untilscour@protonmail.com; s=20260906; h=from:subject:message-id;
 bh=kg6KVsnzM/S6c7CrUcQL5EMoEDLITm6RqDphdFMeMKY=;
 b=dV8N2jv8eLKcK6TyO8zkxuVRUG+UslFvJPAxdBtKgxpIlzoMOG0owvnjync47Ne68aflqv4d+
 6Ya5ousvZTsB+1Kv3OOTGPcqR7+KmFswpgy9P3VtuqMtIuZfjsX4/lB
X-Developer-Key: i=untilscour@protonmail.com; a=ed25519;
 pk=eCaNcoQNRWYKZ9D7KbOGKvQVK2YFguJXZxglTtAR7Xk=
X-Endpoint-Received: by B4 Relay for untilscour@protonmail.com/20260906 with auth_id=1011
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FriendlyELEC Nanopi M5 has MASKROM and RECOVERY buttons connected
via SARADC (sheets 6 and 19 of the schematic for both the LPDDR4X [1]
and LPDDR5 [2] versions). Add the two buttons to the device tree.

[1]: https://wiki.friendlyelec.com/wiki/images/1/10/NanoPi_M5_LP4X_2411_SCH.PDF
[2]: https://wiki.friendlyelec.com/wiki/images/9/97/NanoPi_M5_LP5_2411_SCH.pdf

Signed-off-by: Ryan Leung <untilscour@protonmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3576-nanopi-m5.dts | 28 +++++++++++++++++++++++
 1 file changed, 28 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3576-nanopi-m5.dts b/arch/arm64/boot/dts/rockchip/rk3576-nanopi-m5.dts
index 3a305408fa16..46c88b1ccde7 100644
--- a/arch/arm64/boot/dts/rockchip/rk3576-nanopi-m5.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3576-nanopi-m5.dts
@@ -41,6 +41,34 @@ hdmi_con_in: endpoint {
 		};
 	};
 
+	adc-keys-0 {
+		compatible = "adc-keys";
+		io-channels = <&saradc 0>;
+		io-channel-names = "buttons";
+		keyup-threshold-microvolt = <1800000>;
+		poll-interval = <100>;
+
+		button-maskrom {
+			label = "maskrom";
+			linux,code = <KEY_SETUP>;
+			press-threshold-microvolt = <0>;
+		};
+	};
+
+	adc-keys-1 {
+		compatible = "adc-keys";
+		io-channels = <&saradc 1>;
+		io-channel-names = "buttons";
+		keyup-threshold-microvolt = <1800000>;
+		poll-interval = <100>;
+
+		button-recovery {
+			label = "recovery";
+			linux,code = <KEY_VENDOR>;
+			press-threshold-microvolt = <0>;
+		};
+	};
+
 	keys {
 		compatible = "gpio-keys";
 

---
base-commit: d2abcbb905b0e4b2e06b257fa1e5bcf4faa6dbda
change-id: 20261011-nanopi-m5-adc-6e03d4b39577

Best regards,
--  
Ryan Leung <untilscour@protonmail.com>

