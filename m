From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 11 Jun 2025 13:53:38 -0500
Subject: [PATCH v2 2/2] arm64: tegra: Add NVIDIA Jetson Nano 2GB Developer
 Kit support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250611-p3452-v2-2-fd2679706c63@gmail.com>
References: <20250611-p3452-v2-0-fd2679706c63@gmail.com>
In-Reply-To: <20250611-p3452-v2-0-fd2679706c63@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749668025; l=3203;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=42OimoFJFrvH09yIqaz1jWdoda8v/mnkO8i3GiH9JpM=;
 b=s9iva6uoq+uW+o+2KkN3I/3FReqx2GkSwk5aFp5eApaNzLaZxXMZdb9o6G5SFcQyryaIz6W4u
 hJeNJRTC1A3DPtrb7saPzfe9Bq4TIacnCWDgeuliVkSm52C6EnDKWeU
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This devkit is very similar to P3450, except it has less ram, no display
port, and only 3 usb host ports. Derive from P3450 and disable the
hardware that is unavailable.

Gpio PA6 is used to control the hdmi power rail and needs to be on for
hotplug detect to work. This is mapped to the 3.3V usb hub on P3450.
That usb rail is not used here, so delete the regulator to avoid
conflicts.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/Makefile                |  2 +
 arch/arm64/boot/dts/nvidia/tegra210-p3541-0000.dts | 59 ++++++++++++++++++++++
 2 files changed, 61 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/Makefile b/arch/arm64/boot/dts/nvidia/Makefile
index 0fbb8a494dba5089d9b7243e766bd6028b7f3744..2989550e0d482e0dde09c1ff89930f7eb7b5b644 100644
--- a/arch/arm64/boot/dts/nvidia/Makefile
+++ b/arch/arm64/boot/dts/nvidia/Makefile
@@ -3,6 +3,7 @@
 # Enables support for device-tree overlays
 DTC_FLAGS_tegra210-p2371-2180 := -@
 DTC_FLAGS_tegra210-p3450-0000 := -@
+DTC_FLAGS_tegra210-p3541-0000 := -@
 DTC_FLAGS_tegra186-p2771-0000 := -@
 DTC_FLAGS_tegra186-p3509-0000+p3636-0001 := -@
 DTC_FLAGS_tegra194-p2972-0000 := -@
@@ -18,6 +19,7 @@ dtb-$(CONFIG_ARCH_TEGRA_210_SOC) += tegra210-p2371-0000.dtb
 dtb-$(CONFIG_ARCH_TEGRA_210_SOC) += tegra210-p2371-2180.dtb
 dtb-$(CONFIG_ARCH_TEGRA_210_SOC) += tegra210-p2571.dtb
 dtb-$(CONFIG_ARCH_TEGRA_210_SOC) += tegra210-p3450-0000.dtb
+dtb-$(CONFIG_ARCH_TEGRA_210_SOC) += tegra210-p3541-0000.dtb
 dtb-$(CONFIG_ARCH_TEGRA_210_SOC) += tegra210-smaug.dtb
 dtb-$(CONFIG_ARCH_TEGRA_210_SOC) += tegra210-p2894-0050-a08.dtb
 dtb-$(CONFIG_ARCH_TEGRA_186_SOC) += tegra186-p2771-0000.dtb
diff --git a/arch/arm64/boot/dts/nvidia/tegra210-p3541-0000.dts b/arch/arm64/boot/dts/nvidia/tegra210-p3541-0000.dts
new file mode 100644
index 0000000000000000000000000000000000000000..b86e271dde0bee7ceb70f16113eba5cf06da98e2
--- /dev/null
+++ b/arch/arm64/boot/dts/nvidia/tegra210-p3541-0000.dts
@@ -0,0 +1,59 @@
+// SPDX-License-Identifier: GPL-2.0
+/dts-v1/;
+
+#include "tegra210-p3450-0000.dts"
+
+/ {
+	model = "NVIDIA Jetson Nano 2GB Developer Kit";
+	compatible = "nvidia,p3541-0000", "nvidia,p3450-0000", "nvidia,tegra210";
+
+	memory@80000000 {
+		reg = <0x0 0x80000000 0x0 0x80000000>;
+	};
+
+	host1x@50000000 {
+		sor@54540000 {
+			status = "disabled";
+		};
+
+		dpaux@545c0000 {
+			status = "disabled";
+		};
+	};
+
+	padctl@7009f000 {
+		ports {
+			usb2-1 {
+				vbus-supply = <&vdd_hub_5v0>;
+			};
+
+			usb2-2 {
+				vbus-supply = <&vdd_hub_5v0>;
+			};
+
+			usb3-0 {
+				/delete-property/ vbus-supply;
+			};
+		};
+	};
+
+	regulator-vdd-hdmi-5v0 {
+		gpio = <&gpio TEGRA_GPIO(A, 6) GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+	};
+
+	/delete-node/ regulator-vdd-hub-3v3;
+
+	vdd_hub_5v0: regulator-vdd-hub-5v0 {
+		compatible = "regulator-fixed";
+
+		regulator-name = "VDD_HUB_5V0";
+		regulator-min-microvolt = <5000000>;
+		regulator-max-microvolt = <5000000>;
+
+		gpio = <&gpio TEGRA_GPIO(I, 2) GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+
+		vin-supply = <&vdd_5v0_sys>;
+	};
+};

-- 
2.49.0

