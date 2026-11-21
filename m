From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 21 Nov 2026 19:05:20 +0000
Subject: [PATCH] drm/panfrost: Unmask the interrupts of a re-enabled
 address space
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-panfrost-mmu-as-mask-v1-1-13ffb84d5562@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDtggm1Jr1K6mOhEpyVRMiqCe
 HfTdvkW/++gnIUVHtUOmVdRGVOBuVTQDpR6RumKwdb2Zow1OFEKedQZY1yQFCPpB8OV755q5xr
 voKRT5iDbb/t8/a2Lf3M7f19wHCddOqdMeAAAAA==
X-Change-ID: 20261121-panfrost-mmu-as-mask-f5e7ba0994b9
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Rob Herring <robh@kernel.org>, Steven Price <steven.price@arm.com>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795287919; l=1936;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=K0pQ9F7/VC+mXmqa5mrb5ZLu5JBV43cmtWNL0qBRLk8=;
 b=UTi0Pl9F3glZ6ZBQdexj6k4QpYeIH3xdTWKCxQwZRzr2XU/a/JTVxlvc7B02k0uyoGWKrATcT
 g+FcGFgPdCNDTEHA+NQjKMyEW6LFejD0V9/42nHHqn7aCUM0ZctiwOG
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sashiko reported this in a review of an unrelated patch.

After an unhandled fault the AS is in as_faulty_mask and its interrupts
are masked. panfrost_mmu_as_get() re-enables the AS but writes
MMU_INT_MASK before it clears the AS from as_faulty_mask, so the
interrupts stay masked and the next fault on the AS hangs the job until
the scheduler timeout. Clear the bit first.

Fixes: ed7a34c57def ("drm/panfrost: Disable the AS on unhandled page faults")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://lore.kernel.org/all/20260811215454.A1C8D1F000E9@smtp.kernel.org/
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on a Mali-G31 (H616), 7.3.5 with 8a597d099b8b and e9672bf9382f:
a heap fault after an unhandled fault got no MMU interrupt and the job
timed out; with this patch as the only change it is handled at once.

Claude (Anthropic) wrote the patch and the commit message; I reviewed
them and tested as above.
---
 drivers/gpu/drm/panfrost/panfrost_mmu.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panfrost/panfrost_mmu.c b/drivers/gpu/drm/panfrost/panfrost_mmu.c
index faa62643c..98d52aca4 100644
--- a/drivers/gpu/drm/panfrost/panfrost_mmu.c
+++ b/drivers/gpu/drm/panfrost/panfrost_mmu.c
@@ -283,9 +283,9 @@ int panfrost_mmu_as_get(struct panfrost_device *pfdev, struct panfrost_mmu *mmu)
 			 * disabled. We need to re-enable the MMU after
 			 * clearing+unmasking the AS interrupts.
 			 */
+			pfdev->as_faulty_mask &= ~mask;
 			mmu_write(pfdev, MMU_INT_CLEAR, mask);
 			mmu_write(pfdev, MMU_INT_MASK, ~pfdev->as_faulty_mask);
-			pfdev->as_faulty_mask &= ~mask;
 			panfrost_mmu_enable(pfdev, mmu);
 		}
 

---
base-commit: c408466a4dfaee4b12587e926c5b85e68c8b3c40
change-id: 20261121-panfrost-mmu-as-mask-f5e7ba0994b9

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

