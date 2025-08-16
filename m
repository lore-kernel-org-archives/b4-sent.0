From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 16 Aug 2025 01:03:21 -0500
Subject: [PATCH] arm64: tegra: Enable NVDEC and NVENC on Tegra210
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250816-tegra210-media-enable-v1-1-bdb1c2554f0d@gmail.com>
X-B4-Tracking: v=1; b=H4sIACgfoGgC/x3MQQqDMBBG4avIrDuQRGOLVyldTPTXDmgqSRFBv
 LvB5bd476CMpMjUVQclbJr1Fwvso6L+K3EC61BMzjhvXrbhP6YkzhpeMKgwooQZ7J9tCK3UTfA
 9lXZNGHW/v+/PeV7Rh4PlZwAAAA==
X-Change-ID: 20250814-tegra210-media-enable-576bb6a34b5c
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755324210; l=2019;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=FBhRZXiIPTHOUSFEUddsbuop3pvSiuDmwcrMPsGiLyM=;
 b=EjnvL0KmoI3A2wSMUAvnWqw3XeIalqm2Jr2reVDXWjpc186wnONzAPqQ9B5CBRQN18IK3LZZk
 RabPK1Y4JM3CqWlsUUk1cQEiFn3d87FtcaifaVf9Zq01itwKQ2seRFL
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The other engines are already enabled, finish filling out the media
engine nodes and power domains.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra210.dtsi | 28 ++++++++++++++++++++++++++--
 1 file changed, 26 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210.dtsi b/arch/arm64/boot/dts/nvidia/tegra210.dtsi
index 402b0ede1472af625d9d9e811f5af306d436cc98..80d7571d0350205b080bcf48b8b8e2c1b93227f2 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra210.dtsi
@@ -277,13 +277,25 @@ dsib: dsi@54400000 {
 		nvdec@54480000 {
 			compatible = "nvidia,tegra210-nvdec";
 			reg = <0x0 0x54480000 0x0 0x00040000>;
-			status = "disabled";
+			clocks = <&tegra_car TEGRA210_CLK_NVDEC>;
+			clock-names = "nvdec";
+			resets = <&tegra_car 194>;
+			reset-names = "nvdec";
+
+			iommus = <&mc TEGRA_SWGROUP_NVDEC>;
+			power-domains = <&pd_nvdec>;
 		};
 
 		nvenc@544c0000 {
 			compatible = "nvidia,tegra210-nvenc";
 			reg = <0x0 0x544c0000 0x0 0x00040000>;
-			status = "disabled";
+			clocks = <&tegra_car TEGRA210_CLK_NVENC>;
+			clock-names = "nvenc";
+			resets = <&tegra_car 219>;
+			reset-names = "nvenc";
+
+			iommus = <&mc TEGRA_SWGROUP_NVENC>;
+			power-domains = <&pd_nvenc>;
 		};
 
 		tsec@54500000 {
@@ -894,6 +906,18 @@ pd_audio: aud {
 				#power-domain-cells = <0>;
 			};
 
+			pd_nvenc: mpe {
+				clocks = <&tegra_car TEGRA210_CLK_NVENC>;
+				resets = <&tegra_car 219>;
+				#power-domain-cells = <0>;
+			};
+
+			pd_nvdec: nvdec {
+				clocks = <&tegra_car TEGRA210_CLK_NVDEC>;
+				resets = <&tegra_car 194>;
+				#power-domain-cells = <0>;
+			};
+
 			pd_sor: sor {
 				clocks = <&tegra_car TEGRA210_CLK_SOR0>,
 					 <&tegra_car TEGRA210_CLK_SOR1>,

---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250814-tegra210-media-enable-576bb6a34b5c

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

