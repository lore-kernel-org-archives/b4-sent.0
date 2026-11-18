From: Joachim Eastwood <joachim.eastwood@gmail.com>
Subject: [PATCH 0/4] drm/bridge: dw-hdmi-qp: Fix HDMI output on H96 MAX V58
 board
Date: Wed, 18 Nov 2026 22:45:27 +0100
Message-Id: <20261118-dw-hdmi-qp-bridge_attach-v1-0-e370920bc7f3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDMBBA4avIrDtgjAr2KqWUcTKaEWptkv6Ae
 PfGuvwW760QJahEOBcrBHlr1MecYU4FsKd5FFSXDVVZtcaYBt0HvbsrPhfsg7pRbpQSsUey3NW
 WamJrIedLkEG///Xleji++kk47T/Yth+yBfWofAAAAA==
X-Change-ID: 20261115-dw-hdmi-qp-bridge_attach-a3c943a4ac33
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
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alexey Charkov <alchark@gmail.com>, 
 Cristian Ciocaltea <cristian.ciocaltea@collabora.com>, 
 Nicolas Frattaroli <nicolas.frattaroli@collabora.com>
Cc: dri-devel@lists.freedesktop.org, linux-rockchip@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795038370; l=2393;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=qLDl2nOQQVy/m8nqNSlwQuyIrbStxrYBTQwCyzrBpCs=;
 b=9dyeCuuLG9wmnoYux4WxkNLUiH/3VxZsRlAZiQq7Of6UPXjvjnq681SJWBJZwNzeHKI4J6H57
 45SuEbxG8ooDUEymXbnp91+IX4hdQOQVwwN3iOJMajIb+kq8tuIjfGH
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series is an attempt to fix the broken HDMI out on the H96
MAX V58 board. On this board the on-chip DDC controller doesn't manage
to read the EDID from the connected monitor. The root cause of this is
not known. I attempted enable pull-ups and lower the DDC speed but it
makes no difference. So the solution is to use a i2c-gpio driver on the
same DDC pins.

It was noted in the original submission of H96 MAX V58 [1] that HDMI was
untested but was assumed to be working. This is not the case, and
Armbian have had a similar workaround for this problem for some time.

Patch 1: Propagate bus format to the bridge input. Without this the 
	 output would be disabled when dw-hdmi-qp attaches to connector.
Patch 2: Attach dw-hdmi-qp to next bridge in the chain. This allows the
	 driver chain to use properties from the hdmi-connector. For
	 example the ddc-i2c-bus needed by H96 MAX V58.
Patch 3/4: Fix HDMI by using i2c-gpio for DDC and enable HDMI sound.

I used AI assistance (Claude) to write the two first patch so please
give them a critical review. I am not very familiar with the DRM subs
system. So please provide some guidance if this approach is wrong.

Patches tested on both H96 MAX V58 and NanoPi M6. No regressions
observed on NanoPi M6.

Also note that there is no schematics for H96 MAX V58 so it's not
possible to see where they screwed up the design. No other board in
mainline require this type of workaround.

Based on drm-misc-next.

[1]: https://lore.kernel.org/all/20250108-rk3588-h96-max-v58-v2-0-522301b905d6@gmail.com/

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
Joachim Eastwood (4):
      drm/bridge: synopsys: dw-hdmi-qp: Propagate the bus format to the bridge input
      drm/bridge: synopsys: dw-hdmi-qp: Attach the next bridge in the chain
      arm64: dts: rockchip: use i2c-gpio for hdmi ddc on rk3588-h96-max-v58
      arm64: dts: rockchip: enable hdmi sound on rk3588-h96-max-v58

 .../arm64/boot/dts/rockchip/rk3588-h96-max-v58.dts | 30 +++++++++++++++++++--
 drivers/gpu/drm/bridge/synopsys/dw-hdmi-qp.c       | 31 ++++++++++++++++++++++
 2 files changed, 59 insertions(+), 2 deletions(-)
---
base-commit: 17a180572ca50c8d38f3aa47d6fc81ce7c5594da
change-id: 20261115-dw-hdmi-qp-bridge_attach-a3c943a4ac33

Best regards,
--  
Joachim Eastwood <joachim.eastwood@gmail.com>

