From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v4 0/8] drm/rockchip: vop2: RK3588 clocking, sync polarity
 and window fixes
Date: Thu, 19 Nov 2026 05:21:41 +0000
Message-Id: <20261119-vop2-fixes-v4-0-4b8f5e7148c9@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23NTQ6CMBAF4KuQrq3ptPwUV97DuCjtIDVCCcVGQ
 7i7BTdgXL7M+95MxONg0ZNTMpEBg/XWdTGkh4ToRnU3pNbETDjjOQAwGlzPaW1f6Gmt0gxSXpS
 lBhJBP+B6iP3L9Zv9s7qjHpeFpdFYP7rhvX4LsPT+DgegjBohciyNKZkR51ur7OOoXUuW4cC3l
 O8oj1RykBp0LZWWv1RsqdhRESmTCkWBUlSZ3tJ5nj8H1MxvLAEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795065702; l=2365;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=DKrZ8YElBahQy97+zTx5tNNcwtO0wt30KXIKbUCDTYw=;
 b=2jM2Zi1py2UsUHQUdVkIAlqdFMsTjXBj/1UjMtCrB5xm3N6FTGzjOaEBYzzuCTj850TNisq6f
 D2Zn5oaZT6jClH79GzpqahDXk6SQrQXl8M+bwfvnnnNYEpeaOlSQU/u
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
Changes in v4:
- Patches 1 and 2: Reviewed-by added (Damon Ding).
- Patch 4: the GRF sync polarity bits get names in rockchip_drm_vop2.h
  (Damon Ding); comment dropped.
- Patch 5: check moved after the 10bpc check, with a comment and a
  drm_dbg_kms() (Damon Ding); it tests drm_is_afbc() there, as it now
  runs before the linear return.
- Rebased on drm-misc-next.
- Link to v3: https://patch.msgid.link/20261113-vop2-fixes-v3-0-08ae37e83b5c@gmail.com

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

 drivers/gpu/drm/rockchip/rockchip_drm_vop2.c | 27 +++++++++++++++++++--------
 drivers/gpu/drm/rockchip/rockchip_drm_vop2.h |  3 +++
 drivers/gpu/drm/rockchip/rockchip_vop2_reg.c | 16 ++++++++++++----
 3 files changed, 34 insertions(+), 12 deletions(-)
---
base-commit: fac7a5f16230779cfb0d50ca49e9467cc94a2ea9
change-id: 20261110-vop2-fixes-fa45142799c1

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

