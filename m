From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/2] media: rkvdec: Stop VDPU381 and VDPU383 cores on
 timeout
Date: Sun, 15 Nov 2026 08:21:27 +0000
Message-Id: <20261115-rkvdec-wdt-stop-v1-0-59e687c6cc63@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/y2OzW7DIBAGX8XiXCwWcMBWVfU9ohzwsrTUsp0CT
 tpGefeSn+NI387shWVKkTIbmgtLdIo5rksFeGkYfrrlg3j0lZkUcgcAmqfp5An52Reey3rk2Cs
 re6OhR2T16pgoxJ+7cX94cN7GL8Jy0zwXib63miqPGZspZ3dPDc3rs6RASN3tWg1dJ5XhwF07u
 b+45On3PdYX1jZtbzff6DJxXOc5lqHRNlDnjFUaEYSwYK3xZkTfhyCcRudRBWeRHa7Xf5WFBgj
 9AAAA
X-Change-ID: 20261114-rkvdec-wdt-stop-c938297419cc
To: Detlev Casanova <detlev.casanova@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Alex Kazinsky <a.kazinsky@ideco.ru>, stable@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794730887; l=1762;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=vXWQKYqD65FGosSnp3CAGgFjhJ+XWPam2Tye34T89dI=;
 b=2i2GBE9TZ5786AIiy27G0vx6e0j71HcTkOrGbu5PMhpK7IEv5Spj9aGfiDYZzqjRYpmkN0l+8
 EgZ+OjQtN7LBMlRglqt/sq4LBCzBbMkZ33U6J9qr9fEs03gBunTosVQ
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The rkvdec watchdog writes an RK3399 register on VDPU381 and VDPU383,
so a timed-out core keeps running after its IOMMU and power domain are
suspended. On RK3588 this corrupts memory and panics.

1/2 fixes VDPU381 and is board-tested. 2/2 fixes VDPU383 and is
compile-tested only.

The series applies on top of Alex Kazinsky's "media: rkvdec: Handle
interrupts without a current context" v3 [1], which touches the same
lines. For stable this needs [1] first.

Tested on an Orange Pi 5 (RK3588S) with KASAN, my pending
rockchip-iommu fixes [2] and the watchdog cut to a few ms: unpatched
panics within 8 s; patched, 5955 timeouts with no KASAN, IOMMU or WARN
report, fluster H.264/H.265 unchanged.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

[1] https://lore.kernel.org/linux-media/20261113102456.4155237-1-a.kazinsky@ideco.ru/
[2] https://patch.msgid.link/20261110-iommu-rockchip-faults-v1-0-b1dda574dbb8@gmail.com

---
Arun Iyengar (2):
      media: rkvdec: Stop the VDPU381 core on timeout
      media: rkvdec: Stop the VDPU383 core on timeout

 .../platform/rockchip/rkvdec/rkvdec-vdpu381-regs.h |  4 ++
 .../platform/rockchip/rkvdec/rkvdec-vdpu383-regs.h |  4 ++
 drivers/media/platform/rockchip/rkvdec/rkvdec.c    | 82 +++++++++++++++++++++-
 drivers/media/platform/rockchip/rkvdec/rkvdec.h    |  3 +
 4 files changed, 92 insertions(+), 1 deletion(-)
---
base-commit: 48fe5a7834cc10081887d7bcd9ff0a4cadc3fa8c
change-id: 20261114-rkvdec-wdt-stop-c938297419cc
prerequisite-message-id: <20261113102456.4155237-1-a.kazinsky@ideco.ru>
prerequisite-patch-id: 4199405920f24e49b3993996a6bd951136e52e92

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

