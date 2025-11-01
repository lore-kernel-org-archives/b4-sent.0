From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 01 Nov 2025 18:01:10 -0500
Subject: [PATCH 1/2] Revert "arm64: tegra: Disable ISO SMMU for Tegra194"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251101-tegra194-dc-mmu-v1-1-8401c45d8f13@gmail.com>
References: <20251101-tegra194-dc-mmu-v1-0-8401c45d8f13@gmail.com>
In-Reply-To: <20251101-tegra194-dc-mmu-v1-0-8401c45d8f13@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762038074; l=777;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=tSEVVrjmjzXWa99QYResO+0NLnexlM0Fps9xvorBbTQ=;
 b=LU265OZErldUjW+6ZPeacgw0HtOeNpzWN1g6nhVHbnmaSjr2riFW+4X9WjrSzX3ekna0w9vv3
 /LUz78GQc+vDGQ9T6kFdsd8zMValgbjWTAj1JbpdXGFKG96KTr7X2wh
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This reverts commit ebea268ea583ba4970df425dfef8c8e21d0a4e12.

Mmu is now being enabled for the display controllers.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra194.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/nvidia/tegra194.dtsi b/arch/arm64/boot/dts/nvidia/tegra194.dtsi
index 1399342f23e1c4f73b278adc66dfb948fc30d326..854ed6d46aa1d8eedcdfbae1fdde1374adf40337 100644
--- a/arch/arm64/boot/dts/nvidia/tegra194.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra194.dtsi
@@ -1807,7 +1807,7 @@ iommu@10000000 {
 			#iommu-cells = <1>;
 
 			nvidia,memory-controller = <&mc>;
-			status = "disabled";
+			status = "okay";
 		};
 
 		smmu: iommu@12000000 {

-- 
2.51.0

