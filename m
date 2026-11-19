From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/2] drm/rockchip: RK3588 HDMI interlaced modes
Date: Thu, 19 Nov 2026 10:05:59 +0000
Message-Id: <20261119-rk3588-interlace-v1-0-993212e389cd@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBA0auQWdOEaZUUr0JYlHYqg6aQKRoSw
 t2tunyL/w/IJEwZbtUBQm/OvKQCrCvwk0t3UhyKQTe6RcROycNcrVWcNpKn86R8i11jo72YGKB
 kq1Dk/bfsh7/za5zJb98PnOcHiCJyo3QAAAA=
X-Change-ID: 20261119-rk3588-interlace-c61908f843fd
To: Sandy Huang <hjc@rock-chips.com>, 
 =?utf-8?q?Heiko_St=C3=BCbner?= <heiko@sntech.de>, 
 Andy Yan <andyshrk@163.com>, Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Luca Ceresoli <luca.ceresoli@bootlin.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sascha Hauer <s.hauer@pengutronix.de>
Cc: dri-devel@lists.freedesktop.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Cristian Ciocaltea <cristian.ciocaltea@collabora.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795082759; l=1081;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=R9RXsFkub066PZWp+rp0tXeW89o/uXELOYPZveB+DEc=;
 b=jMxdtnlAV5oAn1dA1lIoCpHGxLQHES3il63J5mA6kBBuRjlxCuCM0pBo5ZPk+7fIIJZ528iEi
 4q+fsLrFqE8DWA7cka6E9VwR/QzXnr3EddCMClhWMIWOnnwv0vWheZN
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patch 1 rejects the pixel repeated modes (480i, 576i, 240p, 288p) that
RK3588 cannot send. Patch 2 lets dw-hdmi-qp keep the interlaced modes of
the sink; VOP2 already generates the fields.

Tested on an Orange Pi 5 (RK3588S, 7.3-based kernel): 1080i60, 1080i59.94
and 1080i50 on an HDMI TV show a correct picture with the right field rate
and AVI VIC; 1080p60 unchanged. With an EDID override listing 480i and
576i, both modes are pruned. RK3576 uses the same bridge and was not
tested.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

---
Arun Iyengar (2):
      drm/rockchip: vop2: Reject double clocked modes on RK3588
      drm/bridge: synopsys: dw-hdmi-qp: Allow interlaced modes

 drivers/gpu/drm/bridge/synopsys/dw-hdmi-qp.c | 1 +
 drivers/gpu/drm/rockchip/rockchip_drm_vop2.c | 5 +++++
 2 files changed, 6 insertions(+)
---
base-commit: fac7a5f16230779cfb0d50ca49e9467cc94a2ea9
change-id: 20261119-rk3588-interlace-c61908f843fd

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

