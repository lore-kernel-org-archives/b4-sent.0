From: Xi Zhang <xz.ca.cn@gmail.com>
Subject: [PATCH 0/8] drm/msm/dpu: various dpu resource allocation/release
 mismatch fix
Date: Mon, 26 Oct 2026 16:16:48 -0300
Message-Id: <20261026-msm-dpu-res-clean-v1-0-f46130a8a717@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDINbNLc7VTSko1S1KLdZNzklNzNNNMzQ3MDE0MDMxNU5TAuorKEpNy6w
 AmxkdC+EXlyZlpSaXgAxSqq0FANyDXEd1AAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793042236; l=2550;
 i=xz.ca.cn@gmail.com; s=20261026; h=from:subject:message-id;
 bh=2/d8EjRzSoHnBXV69zMC8k8JvAq0euVt9rPufF4ekUk=;
 b=tvvfgQt/49+WodVm0S42JjyPwwc8dvflO44G5lU42tTV1BsYKYjcRhW818+MdktdvZlgpqz5g
 baRO9hlmGxHBs6CTqblKd9jO76mCXw/oCXrD1pca4RImCz0tYtDleHD
X-Developer-Key: i=xz.ca.cn@gmail.com; a=ed25519;
 pk=aRUll5L3eJbwG8Y4BO9uySKGzm+Uy+Ccei9prnRVZRs=
X-Endpoint-Received: by B4 Relay for xz.ca.cn@gmail.com/20261026 with auth_id=1328
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes various resource de-allocation issues in DPU
resource cleanup code. Aim is more reliable mode set, in particular
when multiple displays/encoders are connected, to avoid blue screen
or snowy dsc displays.

Tested with v7.3 + msm-next, on Ayaneo Pocket DS (SM8550 Kalama).
Changes are not device/chip specific.

Some of the changes has lived in ROCKNIX distro for a few months.
https://github.com/ROCKNIX/distribution/pull/2716

Note: The first patch in that PR was problematic: uninitialized pointer
variable field access (since fixed), and I did not understand drm
atomic state tracking, so it wasn't doing anything at all and
is not included in this series.

The third patch linked above has more changes than what's included in
this series. The extra change did not do anything that's needed.

The following 2 commits are new and are not in ROCKNIX:

[Patch 6/8] ("drm/msm/dpu: workaround res re-assignment issues by pairing enc/crtc")
[Patch 7/8] ("drm/msm: force mode_changed on color_mgmt_changed, not just ctm")

[Patch 7/8] would fix, from my testing:
https://lore.kernel.org/all/33424a9d-10a6-4479-bba6-12f8ce60da1a@packett.cool/
See original report by Stephan Gerhold:
https://gitlab.freedesktop.org/drm/msm/-/work_items/102

Note: I'm not part of the ROCKNIX team, just contributed a few patches
there.

Signed-off-by: Xi Zhang <xz.ca.cn@gmail.com>
---
Xi Zhang (8):
      drm/msm/dpu: reset unassigned resource slots to NULL on topology update
      drm/msm/dpu: save LMs in encoder mode_set for cleanup use later
      drm/msm/dpu: use common helper cleanup function in cmd mode disable
      drm/msm/dpu: Match setup_dither cleanup to the way it was set up
      drm/msm/dpu: use cached PINGPONGs from mode set in cwb setup
      drm/msm/dpu: workaround res re-assignment issues by pairing enc/crtc
      drm/msm: force mode_changed on color_mgmt_changed, not just ctm
      drm/msm/dpu: reset DSC_CMN_MAIN_CNF in dsc disable

 drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c        | 115 ++++++++++-----------
 .../gpu/drm/msm/disp/dpu1/dpu_encoder_phys_cmd.c   |  10 +-
 drivers/gpu/drm/msm/disp/dpu1/dpu_hw_dsc_1_2.c     |   1 +
 drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c            |  15 ++-
 drivers/gpu/drm/msm/msm_atomic.c                   |   3 +-
 5 files changed, 70 insertions(+), 74 deletions(-)
---
base-commit: d024361c631b3f020a26c07d683e5103404b0fbf
change-id: 20261026-msm-dpu-res-clean-f1704106453f

Best regards,
--  
Xi Zhang <xz.ca.cn@gmail.com>

