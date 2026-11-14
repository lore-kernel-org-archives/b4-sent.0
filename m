From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/4] media: verisilicon: Keep the CAPTURE format in line
 with the decoder
Date: Sat, 14 Nov 2026 00:14:11 +0000
Message-Id: <20261114-hantro-fixes-v1-0-abb78264801e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMyw5AMBBFf0VmrUlbj4hfEYuqwVggHUTS+HeD5
 Tk350ZgDIQMdRIh4ElM6yJg0gT85JYRFfXCYLUtjTGZErmHVQ10ISvnPOq8L2xZdSDJFvAbpGj
 an/noZvT7+wH3/QCC6dXdcAAAAA==
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
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794615252; l=2262;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=mnIntMiDrfV9YjjKOqzkuVqV2d/DXAOYr9w8YQ7vPoM=;
 b=ZsXIqa4xz7yC6IWsADXwoKvhmpLUUwInD/83g5bAC8paxA1GqysIVovLKzvpVy9QYhtou1KQW
 lwutzSb62cyBcN6mzhZIK8mzDa1LBKyD8rJ8JzdtETumKBE0HOfKaA/
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pre-existing bugs where the decoder writes more than the CAPTURE format
or an auxiliary buffer provides: the VP8 segment map when the format
grows while streaming (1), the AV1 motion vector area after film grain
is turned off (2), and an 8-bit CAPTURE format for a 10-bit stream
(3, 4). Found by Sashiko on my hantro-dec-size-check v1 [1].

Tested on an Orange Pi 5 (RK3588S) with a v7.3-based kernel, on the AV1
decoder: after film grain is turned off, the CAPTURE format is the same
as a fresh one (stock: 3133440 instead of 3525632 bytes); an 8-bit
CAPTURE format set for a 10-bit sequence is replaced by the 10-bit one,
and the 10-bit format comes back after the sequence is set again (stock:
8-bit in both cases). VP8 and AV1 fluster: no new failures; no splats.
HEVC and VP9 (G2) are not tested: the RK3588 has no G2 core, so AV1 is
the only 10-bit path here.
Patch 1 is not reproduced: the test kernel limits RK3588 VP8 to
1920x1088, and frames up to that size fit the single page the map gets.

Benjamin Gaignard's "[PATCH v1 5/7] media: verisilicon: vp8: Use
alloc/free helpers for auxiliary buffers" (2026-09-16) has the lines
patch 1 changes as context: a trivial conflict for whichever lands
second.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

[1] https://lore.kernel.org/r/20261112-hantro-dec-size-check-v1-1-e5f1180b625f@gmail.com

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (4):
      media: verisilicon: Size the VP8 segment map for the largest frame
      media: verisilicon: Set need_postproc before resetting the CAPTURE format
      media: verisilicon: Keep the CAPTURE format at the stream's bit depth
      media: verisilicon: Set the bit depth again when its control is rewritten

 drivers/media/platform/verisilicon/hantro_drv.c  | 14 ++++++++++++--
 drivers/media/platform/verisilicon/hantro_v4l2.c | 20 +++++++++++++++++---
 drivers/media/platform/verisilicon/hantro_vp8.c  |  6 +++---
 3 files changed, 32 insertions(+), 8 deletions(-)
---
base-commit: ad6549a46748d00818483b535e5cd2a704685c98
change-id: 20261113-hantro-fixes-aace04d5268b

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

