From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/2] iommu/vsi: Fix the runtime PM of the IOMMU
Date: Fri, 13 Nov 2026 20:04:35 +0000
Message-Id: <20261113-vsi-iommu-pm-ref-v1-0-fd917eebdf18@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0Nj3bLiTN3M/NzcUt2CXN2i1DRdI6NkC+NEUxNz46RUJaC2AqBgZgX
 YyOhYCL+4NCkrNbkEZI5SbS0A2OhOpXQAAAA=
X-Change-ID: 20261113-vsi-iommu-pm-ref-22c83a5473be
To: Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794600275; l=1341;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=OnaLvuwoDST0/gcJvgeXw4+Y6GTFZAaQ3WwkuisPspY=;
 b=a0QmlQGMI02EGwxxNhSePSHkOd98uDn0EbSCnEajjB24tD6MO/hrdOt//32l4Z1nbwRIS2D0x
 cnbrsDOSwUaAJOdprstpzS0q+TUDntWYIvavBHaV6nW/4vc9SgJiDHD
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patch 1 lets the IOMMU suspend again: a failed pm_runtime_get() in the
TLB flush leaked a usage count. Patch 2 stops the interrupt handler
from resuming the IOMMU in hard IRQ context.

Tested on RK3588S (Orange Pi 5), v7.3-based kernel that also has
hantro-robust v3 [1] and the vsi-iommu suspend patch I will send next:
without patch 1 the AV1 IOMMU stayed active after decoding. With both
it is runtime suspended with usage count 0 after AV1 fluster (203/242,
unchanged), 20 AV1 decoder unbind/bind cycles and 3 s2idle cycles. No
IOMMU fault occurred, so patch 2's handler path did not run.

No conflict with patch 10 of [1], which touches the probe.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

[1] https://lore.kernel.org/r/20261113-hantro-robust-v3-0-82383c722ad2@gmail.com

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (2):
      iommu/vsi: Don't leak a runtime PM reference in the TLB flush
      iommu/vsi: Don't resume the IOMMU in its interrupt handler

 drivers/iommu/vsi-iommu.c | 9 +++++----
 1 file changed, 5 insertions(+), 4 deletions(-)
---
base-commit: 2cf4be57b301ed2d7af82e70cff5dfd96894d8de
change-id: 20261113-vsi-iommu-pm-ref-22c83a5473be

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

