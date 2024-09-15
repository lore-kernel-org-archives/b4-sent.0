From: Jasper Korten <jja2000@gmail.com>
Date: Mon, 16 Sep 2024 00:48:13 +0200
Subject: [PATCH 1/2] arm64: dts: nvidia: tegra210-smaug: Add touchscreen
 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240916-touch-temp-v1-1-5a008b2acbc8@gmail.com>
References: <20240916-touch-temp-v1-0-5a008b2acbc8@gmail.com>
In-Reply-To: <20240916-touch-temp-v1-0-5a008b2acbc8@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Diogo Ivo <diogo.ivo@tecnico.ulisboa.pt>, 
 Jasper Korten <jja2000@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726440502; l=1157;
 i=jja2000@gmail.com; s=20240916; h=from:subject:message-id;
 bh=6mK996nKHGO6KB4fA8zD2TKs8erLyGTuSaVELErvZ74=;
 b=K7zIyR+AKL4IAWMMntVNlIcMsY14XFP0GGL6wY0Iw4hKElB5bXLmsx2VXUv0ETKdmZHAm4K5U
 TIW81mUuxX4Cv3lRNtSKBcw0n7TMIPK+KPZFuTr/NjSeQsIBBh0CCOc
X-Developer-Key: i=jja2000@gmail.com; a=ed25519;
 pk=NV6r6q/S3nZILZkoOEuEM7F+uxANotfAYeXyNZTniJc=
X-Endpoint-Received: by B4 Relay for jja2000@gmail.com/20240916 with auth_id=210
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Google Pixel C contains a RMI4 HID over I2C touchscreen.
Add a DT node for the touchscreen.

Information gathered from downstream tree.
Link: https://android.googlesource.com/kernel/tegra/+/refs/heads/android-tegra-dragon-3.18-oreo-m8/arch/arm64/boot/dts/tegra/tegra210-smaug.dtsi#542

Signed-off-by: Jasper Korten <jja2000@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra210-smaug.dts | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210-smaug.dts b/arch/arm64/boot/dts/nvidia/tegra210-smaug.dts
index 2e5b6b2c1f56..6f77540fd397 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210-smaug.dts
+++ b/arch/arm64/boot/dts/nvidia/tegra210-smaug.dts
@@ -1362,6 +1362,19 @@ bluetooth {
 		};
 	};
 
+	i2c@7000c000 {
+		status = "okay";
+		clock-frequency = <1000000>;
+
+		touchscreen: i2c-hid-dev@20 {
+				compatible = "hid-over-i2c";
+				reg = <0x20>;
+				hid-descr-addr = <0x0020>;
+				interrupt-parent = <&gpio>;
+				interrupts = <TEGRA_GPIO(X, 1) IRQ_TYPE_EDGE_FALLING>;
+		};
+	};
+
 	i2c@7000c400 {
 		status = "okay";
 		clock-frequency = <1000000>;

-- 
2.46.0

