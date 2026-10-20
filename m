From: Brad Drury <drury.brad@gmail.com>
Date: Tue, 20 Oct 2026 16:40:59 +0800
Subject: [PATCH] drm/amdgpu/gmc6: restore FB location and HDP non-surface
 programming
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-gmc6-writes-only-v3-v1-1-70730a302504@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMPQ6DMAxA4asgz7WUH8HAVVCHJBgwglDFQIsQd
 ydtx2947wShxCRQFyck2ll4iRn6UUAYXOwJuc0Go0yllVHYz6HCd+KVBJc4HbhbtFaX2rngfOc
 hl69EHX9+1+b5t2x+pLB+V3BdN2T+Y1l3AAAA
X-Change-ID: 20261020-gmc6-writes-only-v3-33151aacabfb
To: Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>
Cc: amd-gfx@lists.freedesktop.org, stable@vger.kernel.org, 
 Brad Drury <drury.brad@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792485661; l=4500;
 i=drury.brad@gmail.com; s=20261020; h=from:subject:message-id;
 bh=raIwOSTMc66p8OsMKySvOqV197RJo30SgKnIRMjJUaQ=;
 b=qlVrHHTaGlVubwyQsxPbVgSl3AaxIXEaz/lqwKoS7+P5x50WLXNJ14ZTm1bfd+0lrSqB2kgjn
 OIMTgBeU860A32iXHLG698uljaE/S7HWIQmJB7CfWs59s23lcMRNWAn
X-Developer-Key: i=drury.brad@gmail.com; a=ed25519;
 pk=vbLeVFkpkhLWuDhWMxes9in024/YW681CJos0eosnVQ=
X-Endpoint-Received: by B4 Relay for drury.brad@gmail.com/20261020 with auth_id=1247
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a MacBookPro11,5 (Radeon R9 M370X, Verde, PCI 1002:6821), used as a
headless PRIME offload GPU with the panel on i915, every S3 resume with
amdgpu fails:

  amdgpu 0000:01:00.0: [drm] ring gfx test failed (-110)
  amdgpu 0000:01:00.0: resume of IP block <gfx_v6_0> failed -110

followed by SDMA timeouts and a failed GPU recovery.  The GPU stays
unusable until reboot.  radeon resumes the same card fine.

Instrumenting the resume path with a write/read-back VRAM probe through
MM_INDEX/MM_DATA shows that VRAM is still intact after the driver
re-POSTs the card and at the start of gmc_v6_0_hw_init(), but is corrupt
at the end of it.  The gfx ring test failure is a consequence.

Commit 71086a3e8470 ("drm/amdgpu/gmc6: drop fb location programming")
removed the MC_VM_FB_LOCATION and HDP_NONSURFACE_* writes from
gmc_v6_0_mc_program(), on the grounds that the vbios sets these up.
That holds after the system firmware POSTs the card at boot, but it does
not appear to hold after S3, where the card is only re-POSTed via
asic_init.  radeon's si_mc_program() still writes them on every init and
resume.

Write them again, with the same values as radeon, after the AGP aperture
registers.  gmc_v8_0_mc_program() already does the same for SR-IOV VFs.

Unlike radeon and the code removed by 71086a3e8470, this does not black
out the MC around the writes.  The old gmc_v6_0_mc_stop() relied on
amdgpu_display_stop_mc_access() to blank the CRTCs first, and that was
removed by commit e4f6b39e8bcd ("drm/amdgpu: remove *_mc_access from
display funcs"), so restoring the blackout now would stop the MC under a
live scanout.  On this machine the writes alone fix resume; a variant that
also restored the blackout behaved the same.

It is not established which of these writes is the one that matters.
At boot on this machine FB_LOCATION and HDP_NONSURFACE_BASE already hold
the values written here, but HDP_NONSURFACE_INFO/SIZE do not.  The
register state on a failing resume could not be captured.

Tested on linux 7.3-rc7, MacBookPro11,5, amdgpu.si_support=1
radeon.si_support=0, mem_sleep=deep, with this change alone on top of
the stock driver:
 - 7/7 S3 cycles clean, from a few seconds to 10 h 49 min asleep, on
   battery and on AC, including two back-to-back cycles woken by the
   RTC alarm
 - DRI_PRIME=1 glxinfo (radeonsi), glxgears and vkcube (RADV) work
   after each resume; no ring, -110 or reset errors in the log
 - cold boot unaffected

The variant with the MC blackout passed a further 6/6 cycles, up to
9 h 40 min asleep.

This patch applies to amd-staging-drm-next with only a line offset from
the tested 7.3-rc7 change and has been build-tested there.

Not tested: other SI parts (Tahiti, Pitcairn, Oland, Hainan), and an SI
dGPU that drives a display.

Fixes: 71086a3e8470 ("drm/amdgpu/gmc6: drop fb location programming")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Brad Drury <drury.brad@gmail.com>
---
I can run further tests on this machine (MacBookPro11,5, R9 M370X /
Verde) if that would help, e.g. register dumps or other variants.
---
 drivers/gpu/drm/amd/amdgpu/gmc_v6_0.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/gpu/drm/amd/amdgpu/gmc_v6_0.c b/drivers/gpu/drm/amd/amdgpu/gmc_v6_0.c
index a7c353d1a..d6e315f4b 100644
--- a/drivers/gpu/drm/amd/amdgpu/gmc_v6_0.c
+++ b/drivers/gpu/drm/amd/amdgpu/gmc_v6_0.c
@@ -223,6 +223,17 @@ static void gmc_v6_0_mc_program(struct amdgpu_device *adev)
 	WREG32(mmMC_VM_AGP_BASE, 0);
 	WREG32(mmMC_VM_AGP_TOP, adev->gmc.agp_end >> 22);
 	WREG32(mmMC_VM_AGP_BOT, adev->gmc.agp_start >> 22);
+	/*
+	 * Don't rely on the vbios having set these up.  After S3 the card is
+	 * only re-POSTed with asic_init, and without these (as written by
+	 * radeon's si_mc_program()) VRAM is corrupt by the end of hw_init.
+	 */
+	WREG32(mmMC_VM_FB_LOCATION,
+	       (((adev->gmc.vram_end >> 24) & 0xFFFF) << 16) |
+	       ((adev->gmc.vram_start >> 24) & 0xFFFF));
+	WREG32(mmHDP_NONSURFACE_BASE, adev->gmc.vram_start >> 8);
+	WREG32(mmHDP_NONSURFACE_INFO, (2 << 7) | (1 << 30));
+	WREG32(mmHDP_NONSURFACE_SIZE, 0x3FFFFFFF);
 
 	if (gmc_v6_0_wait_for_idle(ip_block))
 		dev_warn(adev->dev, "Wait for MC idle timedout !\n");

---
base-commit: f307e9d20cc7bd6dd54a3fd8c2af767dd7ef2931
change-id: 20261020-gmc6-writes-only-v3-33151aacabfb

Best regards,
--  
Brad Drury <drury.brad@gmail.com>

