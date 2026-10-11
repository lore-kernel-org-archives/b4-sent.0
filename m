From: Ryan Leung <untilscour@protonmail.com>
Date: Sun, 11 Oct 2026 06:54:47 +0000
Subject: [PATCH] arm64: dts: rockchip: add maskrom ADC button to NanoPi
 R76S
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-nanopi-r76s-adc-v1-1-392993e7a36e@protonmail.com>
X-B4-Tracking: v=1; b=H4sIALYyy2oC/yXMQQqDMBBG4avIrB0wKU3Aq4iLGP+200WUjIog3
 r3RLr/FewcpskCprQ7K2ERlSgWmrih+QnqDZSwm21hnGmM4hTTNwtk75TBGRhi89e6BpwWVas5
 4yX4fu/5vXYcv4nJt6Dx/vbfNHnMAAAA=
X-Change-ID: 20261011-nanopi-r76s-adc-eab72763e52e
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ryan Leung <untilscour@protonmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791701696; l=1321;
 i=untilscour@protonmail.com; s=20260906; h=from:subject:message-id;
 bh=rLOeuuXx3FAnjzW7dZAAyxmysgcJ5FIHHWY+mqfvl84=;
 b=gitg/aFgnqCVWwuKBdhmMpsgSdC+YGCRSlpBzKb7TFeWAKA1JnsUPsIPIUjb2O9MRE5w6P1hv
 l0s4qVfDJz/BPAjFHPn41r1vCbfMopbfC3b0lmN7mtPCUY+GmESiG/z
X-Developer-Key: i=untilscour@protonmail.com; a=ed25519;
 pk=eCaNcoQNRWYKZ9D7KbOGKvQVK2YFguJXZxglTtAR7Xk=
X-Endpoint-Received: by B4 Relay for untilscour@protonmail.com/20260906 with auth_id=1011
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FriendlyELEC Nanopi R76S has a MASKROM button connected via SARADC
(sheets 5, 19 of the schematic [1]). Add the button to the device tree.

[1]: https://wiki.friendlyelec.com/wiki/images/6/60/NanoPi_R76S_LP4X_2411_SCH.pdf

Signed-off-by: Ryan Leung <untilscour@protonmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3576-nanopi-r76s.dts | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3576-nanopi-r76s.dts b/arch/arm64/boot/dts/rockchip/rk3576-nanopi-r76s.dts
index 7f356fd41574..b6afeb4163d1 100644
--- a/arch/arm64/boot/dts/rockchip/rk3576-nanopi-r76s.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3576-nanopi-r76s.dts
@@ -29,6 +29,20 @@ chosen {
 		stdout-path = "serial0:1500000n8";
 	};
 
+	adc-keys {
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
 	gpio-keys {
 		compatible = "gpio-keys";
 		pinctrl-names = "default";

---
base-commit: d2abcbb905b0e4b2e06b257fa1e5bcf4faa6dbda
change-id: 20261011-nanopi-r76s-adc-eab72763e52e

Best regards,
--  
Ryan Leung <untilscour@protonmail.com>

