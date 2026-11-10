From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/8] drm/rockchip: vop2: RK3588 clocking, sync polarity,
 AXI port and window fixes
Date: Tue, 10 Nov 2026 07:18:48 +0000
Message-Id: <20261110-vop2-fixes-v1-0-d336e9dd90d3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSw5AMBAG4KvIrDUxjUe4ilhQU8YC6dBIGndXL
 L/8jwBCjkmgSQI48iy8rRGYJmDmfp1I8RgNOtMlImbKb7tWli8SZfu8wFxXdW0Q4mB39AWx33a
 /5RwWMsf7APf9AJQbo+1uAAAA
X-Change-ID: 20261110-vop2-fixes-fa45142799c1
To: Sandy Huang <hjc@rock-chips.com>, 
 =?utf-8?q?Heiko_St=C3=BCbner?= <heiko@sntech.de>, 
 Andy Yan <andyshrk@163.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sascha Hauer <s.hauer@pengutronix.de>
Cc: dri-devel@lists.freedesktop.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295129; l=4031;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=fo7rQJTAOXCeB/21ZdTRGQqHaTQfZ2L5wF/0HI3nMtM=;
 b=r9LUei76hUrXdgmi2KacbwxDOIS0mEAd6hhWFCzVEP8Kf+EaRuAqe+KnA0v7jAtuB075BZ9b/
 cS5y2FN73XiBanfNEpqhxB3lgYYK8/uGBsuHj824b0xFBnb7nvKN9/Y
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series collects fixes for the RK3588 VOP2 found while bringing up
HDMI and DisplayPort output on an Orange Pi 5 (RK3588S).

Patches 1 and 2 fix the RK3588 interface setup: rk3588_calc_cru_cfg()
leaves dividers it does not use uninitialised and the garbage ends up in
VP_CLK_CTRL, and rk3588_get_hdmi_pol() decodes the POLFLAG bits it is
handed as DRM mode flags, so the GRF sync polarity bits are wrong for
most modes.

Patch 3 stops the RK3588 Cluster windows from advertising AFBC with the
lossless colour transform (YTR) for RGB565/BGR565, which the decoder
cannot display (black picture plus POST_BUF_EMPTY).

Patches 4 and 5 deal with POST_BUF_EMPTY underflows. The VOP2 fetches
through two AXI read ports but the port of each window is fixed in the
window table, so the usual primary plane plus overlay configuration of
a video port puts both layers on one port while the other sits idle.
One port cannot sustain two full screen 4K@120Hz layers (measured: the
fetch rate collapses from ~6 GB/s to ~3 GB/s and about half of all
lines underflow). Patch 4 assigns the port when a window starts
fetching, balancing the estimated load; patch 5 rate-limits the
POST_BUF_EMPTY interrupt to once per frame, since an underflowing port
otherwise keeps the CPU in the interrupt handler 50000 to 300000 times
per second.

Patches 6 to 8 are smaller fixes: the start mixer search skipped
Esmart3 (for_each_set_bit() was given the highest window id as the bit
count), a gamma LUT update cleared the other fields of LUT_PORT_SEL
(the VP0/VP2 dclk source selection and the VP0/VP1 merge enable), and
the AFBC tile count and transform offset were wrong for a source that
starts inside a 16 pixel superblock.

Tested on an Orange Pi 5 (RK3588S) with an HDMI 2.1 TV and a
DisplayPort monitor, pictures judged with a camera. Patches 1 and 2:
VP0_CLK_CTRL reads back without the garbage dclk_out divider, the sync
polarities seen by the HDMI controller (VIDEO_INTERFACE_STATUS0) match
the mode flags for +/+ (1080p, 2160p) and -/- (720x480, 640x480) modes,
and the picture is correct over TMDS and FRL modes from 27 to
1188 MHz. Patch 3: RGB565 is offered on the Cluster windows only
without YTR, and those planes scan out correctly on three Cluster
windows. Patches 4 and 5: 3840x2160@120 with a full screen overlay
(previously ~120000 POST_BUF_EMPTY per second and a scrambled picture)
and a dual-display session (HDMI 4K@60 plus DP 4K@30, two video players,
ten minutes) run with zero underflows. Patches 6 to 8 were found while
driving Esmart3 and partial AFBC overlays: an AFBC overlay placed at
x=1001 shows correctly. All eight have been in the board's kernel for
the display test runs since.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages, and I reviewed and tested
every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (8):
      drm/rockchip: vop2: Don't use uninitialised dividers on RK3588
      drm/rockchip: vop2: Fix the HDMI sync polarity on RK3588
      drm/rockchip: vop2: Don't accept AFBC YTR for RGB565 on RK3588
      drm/rockchip: vop2: Balance window fetches across both AXI ports on RK3588
      drm/rockchip: vop2: Report POST_BUF_EMPTY at most once per frame
      drm/rockchip: vop2: Find the first mixer of a video port with Esmart3 too
      drm/rockchip: vop2: Keep the other LUT_PORT_SEL fields on gamma LUT updates
      drm/rockchip: vop2: Fix the AFBC offsets of a source that starts inside a superblock

 drivers/gpu/drm/rockchip/rockchip_drm_vop2.c | 186 +++++++++++++++++++++++++--
 drivers/gpu/drm/rockchip/rockchip_drm_vop2.h |  24 ++++
 drivers/gpu/drm/rockchip/rockchip_vop2_reg.c |  27 +++-
 3 files changed, 223 insertions(+), 14 deletions(-)
---
base-commit: 8deaade4a5a4ff635df91e246e42139ab2b33f6d
change-id: 20261110-vop2-fixes-fa45142799c1

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

