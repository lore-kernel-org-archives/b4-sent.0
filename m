From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 15 May 2026 15:35:29 -0500
Subject: [PATCH 3/3] arm64: tegra: Add iommu and dma properties for
 Tegra194 QSPI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260515-tegra194-qspi-iommu-v1-3-57dfb63cd3d6@gmail.com>
References: <20260515-tegra194-qspi-iommu-v1-0-57dfb63cd3d6@gmail.com>
In-Reply-To: <20260515-tegra194-qspi-iommu-v1-0-57dfb63cd3d6@gmail.com>
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Thierry Reding <thierry.reding@gmail.com>, linux-spi@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778877338; l=1187;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=Np/pDfMhrl4vh3eC9VslgUn4DVBcUQmUCasGPdu9S6s=;
 b=XNElFQVNTMTXCC1rsHQEhqgqighB+BXthtnfT1GQGvp9+UcgAvg2MufyoHJKVYT7dCA8LSXGx
 ImTaWbQKrbrBQPjCga4kRxY7DIcgD6WmFx8mv8dZq6NsB2fS3mxUkZ9
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without iommu and dma enabled, flash storage such as the spi-nor on the
p3668 module times out and cannot complete any transfers.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra194.dtsi | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra194.dtsi b/arch/arm64/boot/dts/nvidia/tegra194.dtsi
index 1d659454a6f9fe..0e0a20befe9e68 100644
--- a/arch/arm64/boot/dts/nvidia/tegra194.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra194.dtsi
@@ -923,6 +923,10 @@ spi@3270000 {
 				 <&bpmp TEGRA194_CLK_QSPI0_PM>;
 			clock-names = "qspi", "qspi_out";
 			resets = <&bpmp TEGRA194_RESET_QSPI0>;
+			iommus = <&smmu TEGRA194_SID_GPCDMA_0>;
+			dma-coherent;
+			dmas = <&gpcdma 5>, <&gpcdma 5>;
+			dma-names = "rx", "tx";
 			status = "disabled";
 		};
 
@@ -1013,6 +1017,10 @@ spi@3300000 {
 				 <&bpmp TEGRA194_CLK_QSPI1_PM>;
 			clock-names = "qspi", "qspi_out";
 			resets = <&bpmp TEGRA194_RESET_QSPI1>;
+			iommus = <&smmu TEGRA194_SID_GPCDMA_0>;
+			dma-coherent;
+			dmas = <&gpcdma 6>, <&gpcdma 6>;
+			dma-names = "rx", "tx";
 			status = "disabled";
 		};
 

-- 
2.53.0

