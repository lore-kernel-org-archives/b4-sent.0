From: Daniel Drake <dan@reactivated.net>
Date: Sun, 27 Sep 2026 14:09:05 +0100
Subject: [PATCH v7 6/6] arm64: dts: broadcom: bcm2712: Add GPU IOMMU and
 IOMMU cache nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260927-bcm2712-iommu-submit-v7-6-dfa2b975cbc9@reactivated.net>
References: <20260927-bcm2712-iommu-submit-v7-0-dfa2b975cbc9@reactivated.net>
In-Reply-To: <20260927-bcm2712-iommu-submit-v7-0-dfa2b975cbc9@reactivated.net>
To: "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>, 
 Daniel Drake <dan@reactivated.net>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-rpi-kernel@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, nick.hollinghurst@raspberrypi.com, 
 james.quinlan@broadcom.com, Jason Gunthorpe <jgg@ziepe.ca>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1369; i=dan@reactivated.net;
 h=from:subject:message-id; bh=XBvii0RwgTrT6cNpYro0FFGvRHg/uhSq0N5Er7AlhA0=;
 b=owEBbQKS/ZANAwAKAcPmj7FTFEe7AcsmYgBquRWFPaa7eS2gaq7AaVkTNnJd3emegf2BGGFmh
 DbZWcB33gKJAjMEAAEKAB0WIQQ6Rf0sUP1iEhXfVfjD5o+xUxRHuwUCarkVhQAKCRDD5o+xUxRH
 u1NeD/9L4Ly19FTjEUwHyNtmNCGMek+IcasBl2ei3pQ7W+9n+d3K+vxo+T1AbiIhbNf1R9ete+s
 HppNG1FouO3OgwNaCj+TEuR1bVk6bJvS+3hotqwZ2O10QYk1/asgVEadpFBSk5khKBp0DqUwv+m
 kvQgplx/pY1lIgDH0cer18bnpByb13Cw6e2/C93Tf4UmWuEm4grYsz1mG3EreJzVOFntwXD5g/L
 YJVAc5nVreB2RiuSzQnGK7r/yHN83+QTrwM5vzXHLTsoUpxGHVphIZY86LYSqpzgzqvQdUDowjJ
 I5srYJlaawFcwVDkKCqeVSurf95/51YmcG2N4KvbW6iHDme29UoOFIeywhX2RlkIwo+KNWo1b8C
 fnAtNT0NvGFcTDOHmRayRQfK6/rx6dYML0RivLrN5FMSGUvTShrCvM1C3ps0OfpVKR6Wx7JP3BL
 ef5O6li/p6PfUwdoJSq7dhX11m9T66gfWGNa5EClRY9kHOH0iCPnKgTn/U87pf89COQfevljPG1
 T7NbCbZ7U05Y4la2IKOfIvEUyuLSfFKBLrWYXgfWyqJuSjBDt7pKT1ZvXKt3UytC1CbeI1rw0gc
 wC0N1AtlwFIfhdYpGsPJyBssCVCud5aB5tl4KVFqe954JCR+nfmfL9fNZzmOXWapuGjK0hsxJfl
 Dd6icagzsN5qV6Q==
X-Developer-Key: i=dan@reactivated.net; a=openpgp;
 fpr=3A45FD2C50FD621215DF55F8C3E68FB1531447BB
X-Endpoint-Received: by B4 Relay for dan@reactivated.net/default with auth_id=1070
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Define the IOMMU and IOMMUC nodes for the Broadcom BCM2712 SoC found in
the Raspberry Pi 5. Enable use of the IOMMU for the HVS device
that handles memory allocations for the display block.

Signed-off-by: Daniel Drake <dan@reactivated.net>
---
 arch/arm64/boot/dts/broadcom/bcm2712.dtsi | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/arch/arm64/boot/dts/broadcom/bcm2712.dtsi b/arch/arm64/boot/dts/broadcom/bcm2712.dtsi
index 45aa8ec5e2b1..aca9e0e3a874 100644
--- a/arch/arm64/boot/dts/broadcom/bcm2712.dtsi
+++ b/arch/arm64/boot/dts/broadcom/bcm2712.dtsi
@@ -626,6 +626,19 @@ pcie2: pcie@1000120000 {
 			status = "disabled";
 		};
 
+		iommu4: iommu@1000005200 {
+			/* IOMMU for VC4 (HVS & MPL/TXP), Unicam, PISP-FE, MiniBVN */
+			compatible = "brcm,bcm2712-iommu";
+			reg = <0x10 0x5200 0x0 0x80>;
+			#iommu-cells = <0>;
+			brcm,iommu-cache = <&iommuc>;
+		};
+
+		iommuc: iommuc@1000005b00 {
+			compatible = "brcm,bcm2712-iommuc";
+			reg = <0x10 0x5b00 0x0 0x80>;
+		};
+
 		mip0: msi-controller@1000130000 {
 			compatible = "brcm,bcm2712-mip";
 			reg = <0x10 0x00130000 0x00 0xc0>,
@@ -701,5 +714,6 @@ hvs: hvs@107c580000 {
 		interrupt-parent = <&disp_intr>;
 		interrupts = <2>, <9>, <16>;
 		interrupt-names = "ch0-eof", "ch1-eof", "ch2-eof";
+		iommus = <&iommu4>;
 	};
 };

-- 
2.55.0

