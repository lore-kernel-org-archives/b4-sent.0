From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/3] iommu/vsi: Fix the domain locking and a probe leak
Date: Sat, 14 Nov 2026 00:14:24 +0000
Message-Id: <20261114-iommu-vsi-fixes-v1-0-1fc7728dfd35@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/z2PS24DIRBErzJiHSRoYABfJfKChiImkn/DjBXJ8
 t2D7SjLUterp76LjqWhi910FwturbfzaQT9MYl8SKcvyFZGFqRo1lob2c7H4yZvvcnaftBlyTQ
 H0hRdLmJQlwWvw4A+9+/cN/5GXp8zf40F122o1ndNXNKaD0O0mwJ7nqFTTJxtjAHVGXjOMVLxJ
 nLW7EyO9rXzT5FPQDBOkWPNs43KJ4KChSUY1KpJIcz8pDh1yDyeaOsAc7UM59kojTIUqQaCV7l
 WV2qJc4i2hAKxfzx+AVT7cNArAQAA
X-Change-ID: 20261113-iommu-vsi-fixes-dc26821295cd
To: Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794615264; l=1685;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=QCr9/CiYUT/P+xObKaTblByhOKT6mvGWS3DUxF3ulxs=;
 b=BWssBIrKSvt+ne8BkBa9CvR6q8qQ7hutK/7Mw612AOm7zCNzvuY4g2Fia6psAK8sX4X2QCMZP
 72f005echsCDxTL31pkjDdmPD1AeGzR925Xkt6N1n1ETej08PFk2k3t
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patch 1 stops identity attach and resume from locking memory past the
static identity domain. Patch 2 takes the old domain's lock to unlink
the IOMMU from its list. Patch 3 fixes a clock prepare leak in probe.
Patches 1 and 2 were found by Sashiko on my vsi-iommu-pm-ref v1 [1] and
hantro-robust v1.

Based on [1]. No conflict with vsi-iommu-disable v1 [2].

Tested on an Orange Pi 5 (RK3588S) with a v7.3-based kernel: the AV1
decoder's IOMMU group switched to identity and back to DMA, then an AV1
decode; 5 unbind/bind cycles of the decoder; VP8 and AV1 fluster with no
new failures; no splats. Patch 2's race and patch 3's error path were
not reproduced.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

[1] https://lore.kernel.org/r/20261113-vsi-iommu-pm-ref-v1-0-fd917eebdf18@gmail.com
[2] https://lore.kernel.org/r/20261113-vsi-iommu-disable-v1-1-94f7f44540b3@gmail.com

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (3):
      iommu/vsi: Don't use the identity domain as a paging domain
      iommu/vsi: Unlink the IOMMU from its old domain under that domain's lock
      iommu/vsi: Unprepare the clocks when getting the IRQ fails

 drivers/iommu/vsi-iommu.c | 54 ++++++++++++++++++++++++++++-------------------
 1 file changed, 32 insertions(+), 22 deletions(-)
---
base-commit: 2cf4be57b301ed2d7af82e70cff5dfd96894d8de
change-id: 20261113-iommu-vsi-fixes-dc26821295cd
prerequisite-patch-id: 8b7b6e1a9abc4998ef53e7bc992d739bc1b53c94
prerequisite-patch-id: 27aee835025b1b64907a2e0e4e42e3eff120e86b

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

