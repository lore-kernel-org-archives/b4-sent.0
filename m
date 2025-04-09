From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 09 Apr 2025 17:57:23 -0500
Subject: [PATCH v3 2/4] arm64: tegra: Add fallback cec compatibles
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250409-tegra-cec-v3-2-91640131dfa2@gmail.com>
References: <20250409-tegra-cec-v3-0-91640131dfa2@gmail.com>
In-Reply-To: <20250409-tegra-cec-v3-0-91640131dfa2@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744239446; l=1680;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=WEs9nof5IjWx7LvH6m7ix7zLOBiBSogzTwy1MrVztiY=;
 b=46oavd/oLmV2yU2/kZqH6kwlG9bEs11YLgcY2zhRZW3azrOWUNPjI7S7yWFbPdNhEuSxjNLDK
 d6w6aCmVsN2Dnc8hjUUnDY/LTG/kWAtCrG8zX+b8aBweh8GjV+QyOMh
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The tegra_cec driver only declares support up to Tegra210 and will not
declare support for Tegra186 or Tegra194. Thus list a fallback
compatible for these archs to tegra210-cec as they work as-is with the
existing driver.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra186.dtsi | 2 +-
 arch/arm64/boot/dts/nvidia/tegra194.dtsi | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/nvidia/tegra186.dtsi b/arch/arm64/boot/dts/nvidia/tegra186.dtsi
index 2b3bb5d0af17bd521f87db0484fcbe943dd1a797..7f76c81d744ac72fd117b82f4b799322d2a11b82 100644
--- a/arch/arm64/boot/dts/nvidia/tegra186.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra186.dtsi
@@ -1183,7 +1183,7 @@ gic: interrupt-controller@3881000 {
 	};
 
 	cec@3960000 {
-		compatible = "nvidia,tegra186-cec";
+		compatible = "nvidia,tegra186-cec", "nvidia,tegra210-cec";
 		reg = <0x0 0x03960000 0x0 0x10000>;
 		interrupts = <GIC_SPI 162 IRQ_TYPE_LEVEL_HIGH>;
 		clocks = <&bpmp TEGRA186_CLK_CEC>;
diff --git a/arch/arm64/boot/dts/nvidia/tegra194.dtsi b/arch/arm64/boot/dts/nvidia/tegra194.dtsi
index 33f92b77cd9d9e530eae87a4bb8ba61993ceffeb..9b39bc126381b78efe067df790614d74b24897ce 100644
--- a/arch/arm64/boot/dts/nvidia/tegra194.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra194.dtsi
@@ -1339,7 +1339,7 @@ gic: interrupt-controller@3881000 {
 		};
 
 		cec@3960000 {
-			compatible = "nvidia,tegra194-cec";
+			compatible = "nvidia,tegra194-cec", "nvidia,tegra210-cec";
 			reg = <0x0 0x03960000 0x0 0x10000>;
 			interrupts = <GIC_SPI 162 IRQ_TYPE_LEVEL_HIGH>;
 			clocks = <&bpmp TEGRA194_CLK_CEC>;

-- 
2.48.1

