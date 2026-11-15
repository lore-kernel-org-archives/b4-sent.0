From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 0/4] media: verisilicon: Keep the CAPTURE format in line
 with the decoder
Date: Sun, 15 Nov 2026 08:39:45 +0000
Message-Id: <20261115-hantro-fixes-v2-0-bfecfb07a3e7@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WNQQ6CMBBFr0Jm7Zi2IhJX3sOwaMsIY4SSFomG9
 O62GBcu35//36wQyDMFOBcreFo4sBsTqF0BttdjR8htYlBCVVLKA6Zw9g5v/KKAWlsSZXtUVW0
 gTSZP2yEtrs2Xw9Pcyc7ZkRs9h9n59/Zvkbn3U5f/6kWiQG3MqVZVWQtJl27Q/NhbN0ATY/wAr
 ST8D7oAAAA=
X-Change-ID: 20261113-hantro-fixes-aace04d5268b
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Andrzej Pietrasiewicz <andrzej.p@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794731985; l=1704;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=ieijxoJ+Z395DXW1QlEoaITK3L8xF7mWwBby8wJ+DGk=;
 b=/uVlZ6ozpByZ8clNwP0NjCB4JDtnqv9NzXnKK2vpfHhw2ZdhGxVR0IoF5sT99Iw0cgW+z9uWP
 bIah0ICOwAMCLAlDAPAGWgscLLinzYElFp68cno5uNHbTyMNHyC1wx7
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes for cases where the decoder writes past the CAPTURE format or an
auxiliary buffer, found by Sashiko on hantro-dec-size-check v1 [1].

Tested on an Orange Pi 5 (RK3588S) with AV1: the CAPTURE format is right
after film grain is turned off and for 10-bit streams; VP8 and AV1
fluster show no new failures. The overrun in patch 1 was not reproduced.
HEVC and VP9 are untested (the RK3588 has no G2 core).

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

[1] https://lore.kernel.org/r/20261112-hantro-dec-size-check-v1-1-e5f1180b625f@gmail.com

---
Changes in v2:
- 3/4: also replace a native format when post-processing; second Fixes tag (Sashiko)
- 4/4: check the control returned by v4l2_ctrl_new_custom() (Sashiko)
- Shorter commit messages, fewer code comments
- Link to v1: https://patch.msgid.link/20261114-hantro-fixes-v1-0-abb78264801e@gmail.com

---
Arun Iyengar (4):
      media: verisilicon: Size the VP8 segment map for the largest frame
      media: verisilicon: Set need_postproc before resetting the CAPTURE format
      media: verisilicon: Keep the CAPTURE format at the stream's bit depth
      media: verisilicon: Set the bit depth again when its control is rewritten

 drivers/media/platform/verisilicon/hantro_drv.c  | 12 ++++++++++--
 drivers/media/platform/verisilicon/hantro_v4l2.c | 20 +++++++++++++++++---
 drivers/media/platform/verisilicon/hantro_vp8.c  |  4 ++--
 3 files changed, 29 insertions(+), 7 deletions(-)
---
base-commit: ad6549a46748d00818483b535e5cd2a704685c98
change-id: 20261113-hantro-fixes-aace04d5268b

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

