From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 20:06:43 +0000
Subject: [PATCH] iommu/vsi: Don't write the enable register on suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-vsi-iommu-disable-v1-1-94f7f44540b3@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrB1IUgm0VxEX6kx1SqOSUSkE7
 260y7f4P4FyFFZ4FQki76IyTxm2LKAf22lgFMoGZ5y31j5wV0GZQ9iQRNvuy1g5JvLOkzFPyN0
 S+S2/+1k3f+vWfbhfrxEcxwll7r8XdQAAAA==
X-Change-ID: 20261113-vsi-iommu-disable-42edd626d009
To: Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794600402; l=1969;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=uftO9/StWDRCH/AfNoCaBYaLw8jONKGe5KoaJEmiG08=;
 b=y7eNt27TUkgxu4uCnx3TKetXTmEPoFfqs/j1r46vKVfhIhhpXMPBwxTcrKJGIbkM3oUZmEAK9
 wme1g+bGihiA0Utpxf5tmDqLALSf4NhU5r0LpuEWxwWfxbhQdGaukwI
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Benjamin Gaignard pointed out that, per the IOMMU documentation, the
IOMMU can't be disabled once enabled. Drop the write on suspend:
resume reprograms the IOMMU anyway.

Suggested-by: Benjamin Gaignard <benjamin.gaignard@collabora.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Benjamin suggested this in the hantro-robust review:
https://lore.kernel.org/r/f212840b-92fd-4d97-a6a7-2768a55483f7@collabora.com

Identity attach keeps the write. On RK3588 it does clear the enable
bit (AHB_CONTROL reads 0x1 before, 0x0 after), and without it the
IOMMU would keep using the old domain's page table. Benjamin, should
that one go too?

Tested on RK3588S (Orange Pi 5), v7.3-based kernel with [1] and
hantro-robust v3 [2]: AV1 fluster unchanged (203/242), 20 AV1 decoder
unbind/bind cycles, 3 s2idle cycles. The IOMMU runtime suspended
after each step; no SError or IOMMU fault.
Not tested: identity domains, suspend to RAM.
No conflict with [1] or with patch 10 of [2].

Developed with Claude (Anthropic), which wrote the code and the commit
message. I reviewed it.

[1] https://lore.kernel.org/r/20261113-vsi-iommu-pm-ref-v1-0-fd917eebdf18@gmail.com
[2] https://lore.kernel.org/r/20261113-hantro-robust-v3-0-82383c722ad2@gmail.com
---
 drivers/iommu/vsi-iommu.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iommu/vsi-iommu.c b/drivers/iommu/vsi-iommu.c
index 5dac20b143a5..bd984060253b 100644
--- a/drivers/iommu/vsi-iommu.c
+++ b/drivers/iommu/vsi-iommu.c
@@ -740,7 +740,7 @@ static int __maybe_unused vsi_iommu_suspend(struct device *dev)
 {
 	struct vsi_iommu *iommu = dev_get_drvdata(dev);
 
-	vsi_iommu_disable(iommu);
+	iommu->enable = false;
 
 	clk_bulk_disable(iommu->num_clocks, iommu->clocks);
 

---
base-commit: 2cf4be57b301ed2d7af82e70cff5dfd96894d8de
change-id: 20261113-vsi-iommu-disable-42edd626d009

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

