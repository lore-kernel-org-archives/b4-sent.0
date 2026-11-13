From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v3 0/8] drm/rockchip: vop2: RK3588 clocking, sync polarity
 and window fixes
Date: Fri, 13 Nov 2026 16:39:17 +0000
Message-Id: <20261113-vop2-fixes-v3-0-08ae37e83b5c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NQQ7CIBBFr9KwFsMMtVJX3sO4QKAtxpYGKtE0v
 btQNzVx+TLv/ZlJMN6aQE7FTLyJNlg3JOC7gqhODq2hVicmyLACAEajG5E29mUCbWR5gBKPda2
 ApGD0Zj0k/3L9cnje7kZNeSEbnQ2T8+/1W4Ts/R2OQBnVnFem1rpmmp/bXtrHXrme5OGI2xR/U
 kypQBAKVCOkEtt0WZYPBeXZ8PEAAAA=
X-Change-ID: 20261110-vop2-fixes-fa45142799c1
To: Sandy Huang <hjc@rock-chips.com>, 
 =?utf-8?q?Heiko_St=C3=BCbner?= <heiko@sntech.de>, 
 Andy Yan <andyshrk@163.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sascha Hauer <s.hauer@pengutronix.de>
Cc: Piotr Zalewski <pZ010001011111@proton.me>, 
 Chaoyi Chen <chaoyi.chen@rock-chips.com>, 
 Damon Ding <damon.ding@rock-chips.com>, dri-devel@lists.freedesktop.org, 
 linux-rockchip@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>, 
 stable@vger.kernel.org, 
 Cristian Ciocaltea <cristian.ciocaltea@collabora.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794587957; l=3685;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=3nX1ah8wCORjYYGpxUjgpxkB0S7zXmDkM8EtPt38fzU=;
 b=m5r2YCVxxS4oJSbZYrG5XEnLM48AgEiNksBbi8xzuW3wzVaIs4VxPUbmnt5HcGayVBETAu6Ks
 yf54lD6cAVwBfwO+erZUx9v6EDG1P9lSiCD7hKTyd0rNeh47xH/6inh
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes for the RK3588 VOP2 found while bringing up HDMI and DisplayPort
on an Orange Pi 5 (RK3588S).

Tested on an Orange Pi 5 with an HDMI 2.1 TV and a DisplayPort monitor,
pictures judged with a camera, v7.3 based kernel: VP_CLK_CTRL reads back
without the garbage divider; the HDMI controller sees the sync polarities
of +/+ and mixed modes; HDMI from 148.5 to 1188 MHz (TMDS and FRL) and DP
show a correct picture; RGB565 on the Cluster windows scans out without
YTR; NV12 in two GEM objects and an AFBC overlay at x=1001 show correctly.
Not tested: -HSync/-VSync modes (none in the TV's list), BGR565, HDMI1,
eDP, MIPI DSI and DPI (no hardware).

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Changes in v3:
- Dropped v2 patch 5, which balanced the windows of a video port across
  both AXI ports: the TRM doesn't allow one port's layers on AXI0 and
  AXI1 (Chaoyi Chen). He pointed to the VP merge series for that case [1].
- Patch 1: dropped the comment (Chaoyi Chen).
- Patch 2: no common initialisation; every interface sets the dividers
  it doesn't use to 1, and an unused dclk_out is no longer kept at the
  dclk_core rate (Damon Ding).
- Patch 3: commit message corrected (Damon Ding); Reviewed-by added
  (Chaoyi Chen, Damon Ding); Cc Cristian Ciocaltea.
- New patch 4: the HDMI vsync and hsync polarity bits were swapped.
- Patch 5: YTR is only accepted for the 8 bit RGB formats, as the TRM
  says (Chaoyi Chen); comment dropped; new subject.
- Dropped v2 patch 6, which reported POST_BUF_EMPTY at most once per
  frame: it hides an underflow instead of fixing its cause (Damon Ding).
- Patch 6: Reviewed-by added (Chaoyi Chen, Damon Ding).
- Patch 7: Reviewed-by added (Damon Ding).
- Shorter commit messages and comments, no code change otherwise.
- [1] https://lore.kernel.org/all/20261029081429.862-1-kernel@airkyi.com/
- Link to v2: https://patch.msgid.link/20261112-vop2-fixes-v2-0-8218c1cf8ac8@gmail.com

Changes in v2:
- New patch 1: UV plane address from fb->obj[1] (Sashiko).
- Mixer search: bounded by the new ROCKCHIP_VOP2_MAX_LAYER_ID (Chaoyi
  Chen); Fixes: tag (Sashiko).
- LUT_PORT_SEL: Fixes: tag (Sashiko), Reviewed-by (Chaoyi Chen).
- AFBC offsets: x offset modulo the superblock width, 32 with
  AFBC_FORMAT_MOD_BLOCK_SIZE_32x8 (Sashiko); Fixes: tag (Sashiko).
- Cc Piotr Zalewski (author of the commit the LUT_PORT_SEL patch fixes).
- Link to v1: https://patch.msgid.link/20261110-vop2-fixes-v1-0-d336e9dd90d3@gmail.com

---
Arun Iyengar (8):
      drm/rockchip: vop2: Take the UV plane address from the second GEM object
      drm/rockchip: vop2: Don't use uninitialised dividers on RK3588
      drm/rockchip: vop2: Fix the HDMI sync polarity on RK3588
      drm/rockchip: vop2: Fix the HDMI sync polarity bit order on RK3588
      drm/rockchip: vop2: Only accept AFBC YTR for 8 bit RGB on RK3588
      drm/rockchip: vop2: Find the first mixer of a video port with Esmart3 too
      drm/rockchip: vop2: Keep the other LUT_PORT_SEL fields on gamma LUT updates
      drm/rockchip: vop2: Fix the AFBC offsets of a source that starts inside a superblock

 drivers/gpu/drm/rockchip/rockchip_drm_vop2.c | 23 +++++++++++++++--------
 drivers/gpu/drm/rockchip/rockchip_drm_vop2.h |  1 +
 drivers/gpu/drm/rockchip/rockchip_vop2_reg.c | 17 +++++++++++++----
 3 files changed, 29 insertions(+), 12 deletions(-)
---
base-commit: 8deaade4a5a4ff635df91e246e42139ab2b33f6d
change-id: 20261110-vop2-fixes-fa45142799c1

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

