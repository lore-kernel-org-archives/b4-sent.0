From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/2] iommu/sun50i: Don't report TLB prefetch walks as page
 faults
Date: Tue, 10 Nov 2026 06:05:16 +0000
Message-Id: <20261110-sun50i-iommu-prefetch-v1-0-43428e792ef6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBCF4avIrB1IhIj2KsWFTid1BKNkjAji3
 Rvt8uPx/hOUo7DCqzgh8i4qS8iwZQE09uHLKJ9sqExVW2sNagrOCMoyzwnXyJ43GrFxRC2T986
 1kL/3IMfTfXd/axompu2OwXX9AGmBtZx5AAAA
X-Change-ID: 20261110-sun50i-iommu-prefetch-85cc9ecff559
To: "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: iommu@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794290717; l=1731;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=1HWI9g6TGPVRDjXZAWrid5CsNT0iypzvfoEB9OnZ4/c=;
 b=Me2JoZVpnSuI1KduurX44yUYuz80n91+47NwqBz+j+T3bVEoG7PhKHnEjJfE8zjJcNgdtG7T2
 8Wl1d/2jJAJBB7ZByCyazwlMv3D1Qz9I5yxRgcMdAEAXNW5IDAMiBqp
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On an H616 with a display scanning out, the IOMMU reports page faults
with master -1 at the IOVA right after the end of the framebuffer: once
at the first fbcon frame, and then once per frame for a while after
each TLB flush, e.g. while a video decoder frees its buffers. They are
failed walks of the TLB prefetcher, which the hardware flags with bit 31
of the page table interrupt registers and no master bit. Patch 1 stops
reporting them. Patch 2 makes the remaining fault messages say which
walk failed and what the interrupt register held.

Tested on an Orange Pi Zero2 (H616) with HDMI forced on at 1024x768 and
three 4K H.264 decodes through cedrus, on 7.3 kernels with and without
the patches:
- without: 214 "Page fault ... (master -1, dir rd)" lines;
- with: none, no "Page fault" line at all, and no decode errors or
  timeouts.
Since the patched kernel prints every fault that is not a masterless
prefetch walk, this also shows that the hardware sets bit 31 for these
walks.

These patches were developed with Claude (Anthropic) as a coding
assistant. It investigated the problem and wrote the code and the commit
messages; I reviewed them, and they were tested on an Orange Pi Zero2
(H616) as described above.

---
Arun Iyengar (2):
      iommu/sun50i: Don't report TLB prefetches of unmapped pages as faults
      iommu/sun50i: Print the page table level and status of a fault

 drivers/iommu/sun50i-iommu.c | 50 ++++++++++++++++++++++++++++++++++----------
 1 file changed, 39 insertions(+), 11 deletions(-)
---
base-commit: 2cf4be57b301ed2d7af82e70cff5dfd96894d8de
change-id: 20261110-sun50i-iommu-prefetch-85cc9ecff559

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

