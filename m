From: Jasper Korten <jja2000@gmail.com>
Date: Mon, 16 Sep 2024 00:48:14 +0200
Subject: [PATCH 2/2] arm64: dts: nvidia: tegra210-smaug: Add TMP451
 temperature sensor node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240916-touch-temp-v1-2-5a008b2acbc8@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726440502; l=1092;
 i=jja2000@gmail.com; s=20240916; h=from:subject:message-id;
 bh=bYRs+oTSlXN9NAJLiXE80By1YDR7fhYWaFKCs20PGS8=;
 b=ZeKzeV/Lb0PWjkv6ZN8ArjPpFKgoBtyxJe2gDH5S/UqnreuqZ/4dGEwyfUjR7BPszHFZEK0XG
 0NQgB3qh8Q0AjaQY2viy6oX4DqvMOn6YbNWh5NWLqmXE6ORhcRwvKhu
X-Developer-Key: i=jja2000@gmail.com; a=ed25519;
 pk=NV6r6q/S3nZILZkoOEuEM7F+uxANotfAYeXyNZTniJc=
X-Endpoint-Received: by B4 Relay for jja2000@gmail.com/20240916 with auth_id=210
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Google Pixel C contains a TI TMP451 temperature sensor.
Add a DT node for temperature sensor.

Information gathered from downstream tree.
Link: https://android.googlesource.com/kernel/tegra/+/refs/heads/android-tegra-dragon-3.18-oreo-m8/arch/arm64/boot/dts/tegra/tegra210-smaug.dtsi#1000

Signed-off-by: Jasper Korten <jja2000@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra210-smaug.dts | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210-smaug.dts b/arch/arm64/boot/dts/nvidia/tegra210-smaug.dts
index 6f77540fd397..c724cb4d5ad8 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210-smaug.dts
+++ b/arch/arm64/boot/dts/nvidia/tegra210-smaug.dts
@@ -1732,6 +1732,15 @@ audio-codec@2d {
 			#gpio-cells = <2>;
 			status = "okay";
 		};
+
+		tmp451: temperature-sensor@4c {
+			compatible = "ti,tmp451";
+			reg = <0x4c>;
+			interrupt-parent = <&gpio>;
+			interrupts = <TEGRA_GPIO(X, 4) IRQ_TYPE_LEVEL_LOW>;
+			vcc-supply = <&pp1800>;
+			#thermal-sensor-cells = <1>;
+		};
 	};
 
 	pmc@7000e400 {

-- 
2.46.0

