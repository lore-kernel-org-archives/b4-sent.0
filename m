From: Nizat Mikayilli <nacht@dxdmail.cc>
Date: Thu, 19 Nov 2026 23:40:09 +0100
Subject: [PATCH 6/6] arm64: dts: qcom: sm8550-samsung-gts9wifi: Add battery
 fuel gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-b4-gts9wifi-followups-v1-6-2e2388589a62@dxdmail.cc>
References: <20261119-b4-gts9wifi-followups-v1-0-2e2388589a62@dxdmail.cc>
In-Reply-To: <20261119-b4-gts9wifi-followups-v1-0-2e2388589a62@dxdmail.cc>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795128013; l=1170;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=SC0fR7IdkPE9KI0mhNhppX3NRSeVztJ4Sg+R3uWJmHM=;
 b=rUTWbpFzV8ibiDY7TqHYTQe09CIeutNAS64fOQk3yhCmxPEFhE9Zo4f7Sq2KSzrQy9OQciSTj
 N+dsVkDNZ/ACzee0eN6Zdm0AFtnMYoL5r78K7+igiZWRJcjFUYbBZU7
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the Silicon Mitus SM5714 fuel gauge on I2C hub 8 and the
built-in 8400 mAh battery it monitors.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
 arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts b/arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts
index 8323eb837710..511bdd05d49b 100644
--- a/arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts
+++ b/arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts
@@ -31,6 +31,12 @@ aliases {
 		serial1 = &uart14;
 	};
 
+	battery: battery {
+		compatible = "simple-battery";
+		device-chemistry = "lithium-ion";
+		charge-full-design-microamp-hours = <8400000>;
+	};
+
 	chosen {
 		#address-cells = <2>;
 		#size-cells = <2>;
@@ -604,6 +610,18 @@ cirrus,gpio-ctrl2 {
 	};
 };
 
+&i2c_hub_8 {
+	clock-frequency = <400000>;
+
+	status = "okay";
+
+	fuel-gauge@71 {
+		compatible = "siliconmitus,sm5714-fuel-gauge";
+		reg = <0x71>;
+		monitored-battery = <&battery>;
+	};
+};
+
 &i2c_master_hub_0 {
 	status = "okay";
 };

-- 
2.56.1

