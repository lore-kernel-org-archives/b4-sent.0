From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 01 Nov 2025 18:01:11 -0500
Subject: [PATCH 2/2] arm64: tegra: Enable mmu on Tegra194 display
 controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251101-tegra194-dc-mmu-v1-2-8401c45d8f13@gmail.com>
References: <20251101-tegra194-dc-mmu-v1-0-8401c45d8f13@gmail.com>
In-Reply-To: <20251101-tegra194-dc-mmu-v1-0-8401c45d8f13@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762038074; l=2239;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=gIFvvjKC8J9h0M+DsoDhgCl08bhHOHnaUk5WvYxThAE=;
 b=cTgCrSMGDYH+R8928UWZ8Nk9WaqnORNRo6olgy2CKkepQ2H5hq4JUcgroXewOiEiL33vvm1av
 87lgcCzirukCtVLbfJwkgQUqovoDciBFJ/hxtjqwhBbUuKbCjw8ZSjg
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These use a separate mmu instance compared to everything else currently
enabled for the soc.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra194.dtsi | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/nvidia/tegra194.dtsi b/arch/arm64/boot/dts/nvidia/tegra194.dtsi
index 854ed6d46aa1d8eedcdfbae1fdde1374adf40337..e75b0af81ab76fec5b7531e9c0932a629cbd8768 100644
--- a/arch/arm64/boot/dts/nvidia/tegra194.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra194.dtsi
@@ -1734,7 +1734,7 @@ bpmp-noc@d600000 {
 			status = "okay";
 		};
 
-		iommu@10000000 {
+		smmu_iso: iommu@10000000 {
 			compatible = "nvidia,tegra194-smmu", "nvidia,smmu-500";
 			reg = <0x0 0x10000000 0x0 0x800000>;
 			interrupts = <GIC_SPI 240 IRQ_TYPE_LEVEL_HIGH>,
@@ -1975,6 +1975,7 @@ display@15200000 {
 					interconnects = <&mc TEGRA194_MEMORY_CLIENT_NVDISPLAYR &emc>,
 							<&mc TEGRA194_MEMORY_CLIENT_NVDISPLAYR1 &emc>;
 					interconnect-names = "dma-mem", "read-1";
+					iommus = <&smmu_iso TEGRA194_SID_NVDISPLAY>;
 
 					nvidia,outputs = <&sor0 &sor1 &sor2 &sor3>;
 					nvidia,head = <0>;
@@ -1993,6 +1994,7 @@ display@15210000 {
 					interconnects = <&mc TEGRA194_MEMORY_CLIENT_NVDISPLAYR &emc>,
 							<&mc TEGRA194_MEMORY_CLIENT_NVDISPLAYR1 &emc>;
 					interconnect-names = "dma-mem", "read-1";
+					iommus = <&smmu_iso TEGRA194_SID_NVDISPLAY>;
 
 					nvidia,outputs = <&sor0 &sor1 &sor2 &sor3>;
 					nvidia,head = <1>;
@@ -2011,6 +2013,7 @@ display@15220000 {
 					interconnects = <&mc TEGRA194_MEMORY_CLIENT_NVDISPLAYR &emc>,
 							<&mc TEGRA194_MEMORY_CLIENT_NVDISPLAYR1 &emc>;
 					interconnect-names = "dma-mem", "read-1";
+					iommus = <&smmu_iso TEGRA194_SID_NVDISPLAY>;
 
 					nvidia,outputs = <&sor0 &sor1 &sor2 &sor3>;
 					nvidia,head = <2>;
@@ -2029,6 +2032,7 @@ display@15230000 {
 					interconnects = <&mc TEGRA194_MEMORY_CLIENT_NVDISPLAYR &emc>,
 							<&mc TEGRA194_MEMORY_CLIENT_NVDISPLAYR1 &emc>;
 					interconnect-names = "dma-mem", "read-1";
+					iommus = <&smmu_iso TEGRA194_SID_NVDISPLAY>;
 
 					nvidia,outputs = <&sor0 &sor1 &sor2 &sor3>;
 					nvidia,head = <3>;

-- 
2.51.0

