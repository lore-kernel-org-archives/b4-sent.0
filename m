From: Xi Zhang <xz.ca.cn@gmail.com>
Subject: [PATCH v2 0/6] drm/msm/dpu: various dpu resource
 allocation/release mismatch fix
Date: Mon, 26 Oct 2026 17:25:41 -0300
Message-Id: <20261026-msm-dpu-res-clean-v2-0-3d864435186e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NwQ6CMBBEf4Xs2TVdQDCe/A/DoZYt1FAgXSAaw
 r9b8O5hDi+ZebOCcHAscEtWCLw4cUMfIT0lYFrdN4yujgypSguKQS8e63HGwIKmY92jpVLlpIr
 8klmIuzGwde/D+ah+LPPzxWbaRXujdTIN4XOcLrT3/vkXQoU2LyhT+qpLKu+N1647m8FDtW3bF
 7V9J8LEAAAA
X-Change-ID: 20261026-msm-dpu-res-clean-f1704106453f
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Xi Zhang <xz.ca.cn@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793046364; l=2411;
 i=xz.ca.cn@gmail.com; s=20261026; h=from:subject:message-id;
 bh=UVZ0FP0vB3+dqaosznwwckHsKb9132cEaz7lbbhZycE=;
 b=aAAOtE8VWiLHW047vwU7KeXFOCIn5E3D2gJPmPL46lWFaVplS6WdNri9jyWpA+OslCObFu7uD
 iwPJ0J2uJYZDgTSXljBPVAp57OVVM4MZBzlmLMHja8B29eXS+6ld+vE
X-Developer-Key: i=xz.ca.cn@gmail.com; a=ed25519;
 pk=aRUll5L3eJbwG8Y4BO9uySKGzm+Uy+Ccei9prnRVZRs=
X-Endpoint-Received: by B4 Relay for xz.ca.cn@gmail.com/20261026 with auth_id=1328
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello,

Sorry for the quick v2, this version fixes issue found by
sashiko bot (Good AI!).

This series fixes various resource de-allocation issues in DPU
resource cleanup code. Aim is more reliable mode set, in particular
when multiple displays/encoders are connected, to avoid blue screen
or snowy dsc displays.

Tested with v7.3 + msm-next, on Ayaneo Pocket DS (SM8550 Kalama).
Changes are not device/chip specific.

---
Changes in v2:
- Removed problematic patches as indicated by sashiko bot.
- - removed [PATCH 5/8] drm/msm/dpu: use cached PINGPONGs from mode set in cwb setup
- - removed [PATCH 6/8] drm/msm/dpu: workaround res re-assignment issues by pairing enc/crtc
- Fixed issues indicaed by sashiko bot
- - [PATCH 2/8] drm/msm/dpu: save LMs in encoder mode_set for cleanup use later
Re-add dpu_hw_ctl_setup_blendstage calls
- Link to v1: https://patch.msgid.link/20261026-msm-dpu-res-clean-v1-0-f46130a8a717@gmail.com

To: Rob Clark <robin.clark@oss.qualcomm.com>
To: Dmitry Baryshkov <lumag@kernel.org>
To: Abhinav Kumar <abhinav.kumar@linux.dev>
To: Jessica Zhang <jesszhan0024@gmail.com>
To: Sean Paul <sean@poorly.run>
To: Marijn Suijten <marijn.suijten@somainline.org>
To: David Airlie <airlied@gmail.com>
To: Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org
Cc: dri-devel@lists.freedesktop.org
Cc: freedreno@lists.freedesktop.org
Cc: linux-kernel@vger.kernel.org
Signed-off-by: Xi Zhang <xz.ca.cn@gmail.com>

---
Xi Zhang (6):
      drm/msm/dpu: reset unassigned resource slots to NULL on topology update
      drm/msm/dpu: save LMs in encoder mode_set for cleanup use later
      drm/msm/dpu: use common helper cleanup function in cmd mode disable
      drm/msm/dpu: Match setup_dither cleanup to the way it was set up
      drm/msm: force mode_changed on color_mgmt_changed, not just ctm
      drm/msm/dpu: reset DSC_CMN_MAIN_CNF in dsc disable

 drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c        | 92 +++++++++++++---------
 .../gpu/drm/msm/disp/dpu1/dpu_encoder_phys_cmd.c   | 10 +--
 drivers/gpu/drm/msm/disp/dpu1/dpu_hw_dsc_1_2.c     |  1 +
 drivers/gpu/drm/msm/msm_atomic.c                   |  3 +-
 4 files changed, 57 insertions(+), 49 deletions(-)
---
base-commit: d024361c631b3f020a26c07d683e5103404b0fbf
change-id: 20261026-msm-dpu-res-clean-f1704106453f

Best regards,
--  
Xi Zhang <xz.ca.cn@gmail.com>

