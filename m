From: "David R. Hedges" <linuxdev844@thelittleman.net>
Subject: [PATCH 0/5] drm/nouveau: GSP DP control call fixes and two KMS
 fixes
Date: Tue, 03 Nov 2026 13:28:00 -0600
Message-Id: <20261103-nouveau-dp-fixes-v1-0-892f4bd357cd@thelittleman.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSwqDQBCE4atIr21wxhfJVSQLH2XSLkaZzogg3
 t1Rlx/FXzspvEDpnezksYrK7CJMmlD/a90XLEM02cxWxmQ5uzmsaAMPC4+yQblAWdS2ql+jySl
 mi8c9xKr5PNbQTej/1w8dxwkGce+ddAAAAA==
X-Change-ID: 20261103-nouveau-dp-fixes-4e5472679f13
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dave Airlie <airlied@redhat.com>, Ben Skeggs <bskeggs@redhat.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, 
 "David R. Hedges" <linuxdev844@thelittleman.net>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793734092; l=3561;
 i=linuxdev844@thelittleman.net; s=20261103; h=from:subject:message-id;
 bh=kyihAzwfIJ9HHfvSKZq5cUSMRFvsoDqjqldRWUxUoXk=;
 b=mNNgoyfahRS6gsbtCUR7JisVyYP2F/b4pOOLEw4sXzJ0BB6BWnJr/uvT/VkxwT91fZ+tlWr+p
 A+Q2wo1QbZmA1Xg15bSAkL14u9suiUQahTEw8ELHw3rWVwMUjWbSDQP
X-Developer-Key: i=linuxdev844@thelittleman.net; a=ed25519;
 pk=Cynzuei/w0GLdh3LuNJdvH7aaszLrHSxY5UyujS7l+g=
X-Endpoint-Received: by B4 Relay for linuxdev844@thelittleman.net/20261103 with auth_id=1397
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These turned up while debugging a DP monitor on a GA102 (GSP-RM
570.144) that stays dark after DPMS off [1].  The fix for that is a
separate series for drm-misc-next, based on this one.  These five
don't depend on it, or on each other:

 - 1: r535_gsp_rpc_rm_ctrl_push() reports success with a NULL reply
   when the reply it was waiting for goes missing.  That only happens
   after a WARN in r535_gsp_msgq_recv(); found by reading the code.
 - 2: r535_dp_aux_xfer() has, since v6.12, passed RM's reply fields up
   as a completed AUX transaction even when RM failed the call.  With
   Ubuntu's 7.3 kernel this machine logs bursts of 40-50 such failures
   each time the monitor fails to come back from DPMS off.
 - 3: r535_dp_train_target() dereferences a NULL reply after a GSP RPC
   timeout.  Seen once, turning a display engine hang into an oops.
 - 4: a modeset racing a probe that lost the EDID drives the output at
   0 bpc and trips the WARN in nv50_sor_dp_watermark_sst().  Seen with
   Ubuntu's 7.3 kernel.
 - 5: since v6.2, a plug or unplug event pending together with an
   IRQ_HPD, including the sink count changes nouveau_dp_irq() reports
   that way, skips connector detection.  Found by reading the code; I
   have nothing that changes its sink count to test it with.

Testing, on the GA102 above with Ubuntu's 7.3.0-9-generic kernel and
nouveau built from v7.3 plus this series and the drm-misc-next one:

 - the DPMS, cable replug, S3 suspend/resume and power button tests
   described in the other series, with drm.debug=0x106, and five days
   of normal use: no WARNs, oopses or display engine hangs.  The only
   GSP errors were AUXCH_CTRL failures (0x65) while the monitor was
   switched off, and those now reach the DP helpers as errors ("Too
   many retries, giving up. First error: -22") rather than as
   completed transfers.
 - 1, 3 and 5 deal with conditions I can't reproduce on demand, and the
   0-bpc race 4 fixes didn't recur.

Both series build with W=1 on drm-misc-fixes (this one) and on
drm-misc-next (both), with no new W=1 or sparse warnings in the
touched files.  checkpatch --strict only points out RM's camel-case
replyType field.

This series was developed with the help of Claude Code (Claude Opus
5.5).  It analysed the kernel logs, read the nouveau, DRM and NVIDIA
open-gpu-kernel-modules sources, drafted the patches and changelogs,
and ran the build and checkpatch checks.  I provided evidence and
direction, reviewed changes, and ran the hardware tests.

[1] https://gitlab.freedesktop.org/drm/nouveau/-/work_items/515

Signed-off-by: David R. Hedges <linuxdev844@thelittleman.net>
---
David R. Hedges (5):
      drm/nouveau/gsp: fail control calls whose reply went missing
      drm/nouveau/gsp: don't report failed DP AUX transfers as completed
      drm/nouveau/gsp: don't dereference a failed DP_CTRL reply
      drm/nouveau/kms/nv50-: don't drive outputs at 0 bpc
      drm/nouveau: don't let an IRQ_HPD hide a plug or unplug event

 drivers/gpu/drm/nouveau/dispnv50/disp.c                |  7 +++++--
 drivers/gpu/drm/nouveau/nouveau_display.c              |  7 ++++++-
 drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/ctrl.c |  3 +++
 drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/disp.c | 11 +++++++----
 4 files changed, 21 insertions(+), 7 deletions(-)
---
base-commit: 54a88d9afcca66221d14f438d0960472984968ec
change-id: 20261103-nouveau-dp-fixes-4e5472679f13

Best regards,
--  
David R. Hedges <linuxdev844@thelittleman.net>

