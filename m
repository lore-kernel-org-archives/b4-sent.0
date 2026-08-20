From: Markuss Broks <markuss.broks@gmail.com>
Subject: [PATCH 0/4] IOMMU driver improvements for modern Exynos SysMMUs
Date: Thu, 20 Aug 2026 22:12:04 +0300
Message-Id: <20260820-exynos-iommu-fixes-v1-0-6bbcd673bb15@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMUQqDMBCE4avIPndhG0TEq5Q+tHHSrmBSslUU8
 e7G9vFj+GcjQ1YYddVGGbOaplhwvVTk34/4AmtfTE5cI60TxrLGZKxpHCcOusAYgrpvgwQvDZX
 wk/EbSne7/23Tc4D/nk+07wdZ0Jc7dgAAAA==
X-Change-ID: 20260820-exynos-iommu-fixes-e0e4d8f0fc06
To: Marek Szyprowski <m.szyprowski@samsung.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: iommu@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Markuss Broks <markuss.broks@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787253126; l=2066;
 i=markuss.broks@gmail.com; s=20260803; h=from:subject:message-id;
 bh=eOP+RA4mnWGtFVmDZnso+934UzTGqKnTNVZ92PuZ8Bc=;
 b=ISPOHNvudmR8znZALCiIIFA6iPpiCNxVuLytNm3IHeDKPyijmVlhi5VGISK+wzWdDUObCBnFt
 bF++bdKHIZQAXUKtRHk49vIbKTWhQjlf4dJI0ha3F3Vt0gwgRVZNcuV
X-Developer-Key: i=markuss.broks@gmail.com; a=ed25519;
 pk=oKzGUTm30BCDqinRMpiHQqByOx1mp2mwmhg80Mv7Zg4=
X-Endpoint-Received: by B4 Relay for markuss.broks@gmail.com/20260803 with auth_id=911
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Newer SysMMU v7+ instances can lack BLOCK mode: CAPA1 bit 15 reports
that the CTRL_BLOCK function is not implemented, and MMU_STATUS never
reports a blocked state. The SysMMUs on Exynos 8835 are such
instances.

The driver currently assumes blocking always works, with two
consequences on such hardware:

The enable path writes CTRL_BLOCK first, which there acts as a plain 
enable and starts translation before the page table base is programmed.

Worse, both TLB invalidation paths gate the invalidation writes on
sysmmu_block() succeeding, which it never does - so every unmap silently
skips the invalidation. A stale TLB entry is a valid entry pointing
at a freed page, so nothing ever faults: the device reads back garbage
and its writebacks corrupt whatever the kernel has since reused those pages for.
 
This was tracked down on Exynos 8835 with the MFC, where the
first decoder session of a boot worked and later sessions produced
garbage along with random kernel memory corruption.
Patches 1-3 add detection of the capability bit and adapt the enable
sequence and the invalidation paths, matching the vendor driver's
handling of these parts. Patch 4 is an independent debugging
improvement: decode the v7 fault transaction info word (AxID/AxLEN),
which identifies the issuing port when a master containing several
DMA engines faults.

Tested on the Samsung Galaxy Tab S9 FE (Exynos 8835/Exynos 1380).

Signed-off-by: Markuss Broks <markuss.broks@gmail.com>
---
Markuss Broks (4):
      iommu/exynos: detect SysMMUs without BLOCK mode
      iommu/exynos: fix the enable sequence for no-block SysMMUs
      iommu/exynos: fix TLB invalidation for no-block SysMMUs
      iommu/exynos: decode the v7 fault transaction info

 drivers/iommu/exynos-iommu.c | 37 +++++++++++++++++++++++++++++++++----
 1 file changed, 33 insertions(+), 4 deletions(-)
---
base-commit: 415606a7be939835db9b0d6b711887586646346d
change-id: 20260820-exynos-iommu-fixes-e0e4d8f0fc06

Best regards,
--  
Markuss Broks <markuss.broks@gmail.com>

