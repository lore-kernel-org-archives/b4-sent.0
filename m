From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 13 Apr 2025 14:35:35 -0500
Subject: [PATCH v4 4/4] arm64: tegra: Wire up cec to devkits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250413-tegra-cec-v4-4-b6337b66ccad@gmail.com>
References: <20250413-tegra-cec-v4-0-b6337b66ccad@gmail.com>
In-Reply-To: <20250413-tegra-cec-v4-0-b6337b66ccad@gmail.com>
To: Hans Verkuil <hverkuil@xs4all.nl>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-tegra@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744572933; l=4050;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=/KKv/TYqLGMeib4RLCtBAkuSb2lVtoCy1X50R5bg7FY=;
 b=Uexyi3o309WD9eQ/0aJvKa0CavS2qH7yjjWfDPCINGJF7tfJNyL5GAim8c0wFkW5gz4rsIbeo
 1X1DZs4gj7kAC1eHTi1PqfNQbjPpeI6/UHPm+bYnFI1DbrW93wyM5Ko
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This enables hdmi cec and routes it to the hdmi port on all supported
Tegra210, Tegra186, and Tegra194 devkits.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra186-p2771-0000.dts            | 6 ++++++
 arch/arm64/boot/dts/nvidia/tegra186-p3509-0000+p3636-0001.dts | 6 ++++++
 arch/arm64/boot/dts/nvidia/tegra194-p2972-0000.dts            | 6 ++++++
 arch/arm64/boot/dts/nvidia/tegra194-p3509-0000.dtsi           | 6 ++++++
 arch/arm64/boot/dts/nvidia/tegra210-p2371-2180.dts            | 6 ++++++
 arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts            | 6 ++++++
 6 files changed, 36 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra186-p2771-0000.dts b/arch/arm64/boot/dts/nvidia/tegra186-p2771-0000.dts
index 15aa49fc450399c7bd525adcdb6e92a27a185805..90155e4ff1feb609f79416a410c3666ebef8b634 100644
--- a/arch/arm64/boot/dts/nvidia/tegra186-p2771-0000.dts
+++ b/arch/arm64/boot/dts/nvidia/tegra186-p2771-0000.dts
@@ -2394,6 +2394,12 @@ usb@3550000 {
 		phy-names = "usb2-0";
 	};
 
+	cec@3960000 {
+		status = "okay";
+
+		hdmi-phandle = <&sor1>;
+	};
+
 	i2c@c250000 {
 		/* carrier board ID EEPROM */
 		eeprom@57 {
diff --git a/arch/arm64/boot/dts/nvidia/tegra186-p3509-0000+p3636-0001.dts b/arch/arm64/boot/dts/nvidia/tegra186-p3509-0000+p3636-0001.dts
index 26f71651933d1d8ef32bbd1645cac1820bd2e104..a6d7fec2e84fb917018aff843845b02c34fede33 100644
--- a/arch/arm64/boot/dts/nvidia/tegra186-p3509-0000+p3636-0001.dts
+++ b/arch/arm64/boot/dts/nvidia/tegra186-p3509-0000+p3636-0001.dts
@@ -712,6 +712,12 @@ usb@3550000 {
 		phy-names = "usb2-0";
 	};
 
+	cec@3960000 {
+		status = "okay";
+
+		hdmi-phandle = <&sor1>;
+	};
+
 	hsp@3c00000 {
 		status = "okay";
 	};
diff --git a/arch/arm64/boot/dts/nvidia/tegra194-p2972-0000.dts b/arch/arm64/boot/dts/nvidia/tegra194-p2972-0000.dts
index c32876699a43e9f57b3888c5bc0f5da73c5b95b5..ea6f397a27926e3dcd54002177f68749bc1cc309 100644
--- a/arch/arm64/boot/dts/nvidia/tegra194-p2972-0000.dts
+++ b/arch/arm64/boot/dts/nvidia/tegra194-p2972-0000.dts
@@ -2121,6 +2121,12 @@ usb@3610000 {
 			phy-names = "usb2-0", "usb2-1", "usb2-3", "usb3-0", "usb3-2", "usb3-3";
 		};
 
+		cec@3960000 {
+			status = "okay";
+
+			hdmi-phandle = <&sor2>;
+		};
+
 		i2c@c240000 {
 			typec@8 {
 				compatible = "cypress,cypd4226";
diff --git a/arch/arm64/boot/dts/nvidia/tegra194-p3509-0000.dtsi b/arch/arm64/boot/dts/nvidia/tegra194-p3509-0000.dtsi
index 4a17ea5e40fd034c6f4acb023cd7908d6800f710..16cf4414de599baea96362b494be40c800a8197f 100644
--- a/arch/arm64/boot/dts/nvidia/tegra194-p3509-0000.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra194-p3509-0000.dtsi
@@ -2174,6 +2174,12 @@ usb@3610000 {
 			phy-names = "usb2-1", "usb2-2", "usb3-2";
 		};
 
+		cec@3960000 {
+			status = "okay";
+
+			hdmi-phandle = <&sor1>;
+		};
+
 		host1x@13e00000 {
 			display-hub@15200000 {
 				status = "okay";
diff --git a/arch/arm64/boot/dts/nvidia/tegra210-p2371-2180.dts b/arch/arm64/boot/dts/nvidia/tegra210-p2371-2180.dts
index a6a58e51822d90f8815df880ea7e668caff1b1ec..627abf51a5a472ddcc42fdc1d783876b0a03da47 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210-p2371-2180.dts
+++ b/arch/arm64/boot/dts/nvidia/tegra210-p2371-2180.dts
@@ -90,6 +90,12 @@ eeprom@57 {
 		};
 	};
 
+	cec@70015000 {
+		status = "okay";
+
+		hdmi-phandle = <&sor1>;
+	};
+
 	clock@70110000 {
 		status = "okay";
 
diff --git a/arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts b/arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts
index 0ecdd7243b2eb1abba9adbe9a404b226c29b85ef..ec0e84cb83ef9bf8f0e52e2958db33666813917c 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts
+++ b/arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts
@@ -419,6 +419,12 @@ pmc@7000e400 {
 		nvidia,sys-clock-req-active-high;
 	};
 
+	cec@70015000 {
+		status = "okay";
+
+		hdmi-phandle = <&sor1>;
+	};
+
 	hda@70030000 {
 		nvidia,model = "NVIDIA Jetson Nano HDA";
 

-- 
2.48.1

