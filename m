From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 20 Jul 2025 21:15:10 -0500
Subject: [PATCH v2 16/17] arm64: tegra: Add Tegra210B01 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250720-t210b01-v2-16-9cb209f1edfc@gmail.com>
References: <20250720-t210b01-v2-0-9cb209f1edfc@gmail.com>
In-Reply-To: <20250720-t210b01-v2-0-9cb209f1edfc@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Nagarjuna Kristam <nkristam@nvidia.com>, JC Kuo <jckuo@nvidia.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Mathias Nyman <mathias.nyman@intel.com>, 
 Peter De Schrijver <pdeschrijver@nvidia.com>, 
 Prashant Gaikwad <pgaikwad@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-phy@lists.infradead.org, 
 linux-usb@vger.kernel.org, Thierry Reding <treding@nvidia.com>, 
 linux-pm@vger.kernel.org, linux-clk@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753064238; l=1982;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=49OX805LYoy4B3LF8skuT6ywroy9Cv9R181cjDO5IEQ=;
 b=oMVw8JtuhnOyL5sYPqAD8v+W7FmFHchQmwUYJ7IgbcGTDm7t/8Wop5PETkYVy1RjMNHclfNxh
 u0XFXiUhd/2CUs0Ipn+o0vaXkzLHwjiABqWIKxODj92Ph3IVLOzfPl/
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Also known as Tegra X1+, the Tegra210B01 has higher CPU and GPU clocks
than the original Tegra210.

Add a SoC-level device tree file that describes most of the hardware
available on the SoC. This is derived from the Tegra210 dtsi, as they
share a lot.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra210b01.dtsi | 64 +++++++++++++++++++++++++++++
 1 file changed, 64 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210b01.dtsi b/arch/arm64/boot/dts/nvidia/tegra210b01.dtsi
new file mode 100644
index 0000000000000000000000000000000000000000..87e55af3ed2466c5d353dbd8706230aef97b90f7
--- /dev/null
+++ b/arch/arm64/boot/dts/nvidia/tegra210b01.dtsi
@@ -0,0 +1,64 @@
+// SPDX-License-Identifier: GPL-2.0
+#include "tegra210.dtsi"
+
+/ {
+	compatible = "nvidia,tegra210b01", "nvidia,tegra210";
+
+	host1x@50000000 {
+		/delete-node/ sor@54540000;
+		/delete-node/ dpaux@545c0000;
+
+		dc@54200000 {
+			nvidia,outputs = <&dsia &dsib &sor1>;
+		};
+
+		dc@54240000 {
+			nvidia,outputs = <&dsia &dsib &sor1>;
+		};
+	};
+
+	clock@60006000 {
+		compatible = "nvidia,tegra210b01-car";
+	};
+
+	i2c@7000d100 {
+		/delete-property/ pinctrl-0;
+		/delete-property/ pinctrl-1;
+		/delete-property/ pinctrl-names;
+	};
+
+	pmc@7000e400 {
+		compatible = "nvidia,tegra210b01-pmc";
+	};
+
+	bpmp@70016000 {
+		status = "okay";
+	};
+
+	usb@70090000 {
+		compatible = "nvidia,tegra210b01-xusb";
+	};
+
+	padctl@7009f000 {
+		compatible = "nvidia,tegra210b01-xusb-padctl";
+	};
+
+	usb@700d0000 {
+		compatible = "nvidia,tegra210b01-xudc";
+	};
+
+	thermal-sensor@700e2000 {
+		compatible = "nvidia,tegra210b01-soctherm";
+
+		throttle-cfgs {
+			heavy {
+				nvidia,cpu-throt-percent = <0>;
+				nvidia,gpu-throt-level = <TEGRA_SOCTHERM_THROT_LEVEL_NONE>;
+			};
+		};
+	};
+
+	clock@70110000 {
+		compatible = "nvidia,tegra210b01-dfll";
+	};
+};

-- 
2.50.1

