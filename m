From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 0/2] media: verisilicon: av1: Fix two reference reads
Date: Thu, 19 Nov 2026 04:40:06 +0000
Message-Id: <20261119-b4-vpu981-av1-refs-v2-0-7c270158b20e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22Nyw6CMBBFf4V07Rim4WFd+R+GRWkHGCOPtNBoC
 P9uwbhzNTmTe+9ZhSfH5MU1WYWjwJ7HIYI8JcJ0emgJ2EYWMpUFImZQZxCmRV0QdEBw1HiwKkO
 lG5SUWhGLU/zy6xi9V1/2S/0gM+9Le6JjP4/ufVgD7rmfIP8niDcFU+RloUrMba1uba/5eTZjL
 6pt2z5VNL4FxgAAAA==
X-Change-ID: 20261114-b4-vpu981-av1-refs-d9419af12e0d
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 stable@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795063206; l=1699;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=OVghNADDFQgyMPns3Y0DpyFYJj40oVDPUx76Vlxtv0A=;
 b=bFtv+bW9XyZ00rINk+J3aZT/SH6Had8LfW5wFMAjwS6QIWZefb+9/8hgEOR1TynoMecwnrsYr
 iHsBWdV+KIxAxtTutwPnrz6g2MyLwCWzDtCTQLrxi9nOROoipO5G147
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RK3588 AV1 decoder (VPU981) can read a CAPTURE buffer freed with
VIDIOC_REMOVE_BUFS (patch 1), and reads the segmentation map past the
end of a smaller reference after a switch to a larger CAPTURE format
(patch 2).

Found by code review. Tested on an Orange Pi 5 (RK3588S, 7.3-based
kernel with KASAN): AV1 resolution-change streams (sizeup, sizedown,
svc-L2T1) and 203 AV1 conformance streams decode bit-exact;
with a reference buffer removed, or replaced by a smaller one, the
current buffer is used and the segmentation map is skipped; a map in a
smaller buffer is read at its own offset.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

---
Changes in v2:
- 1/2: Also fall back when the reference buffer holds a frame of another
  size; set the CAPTURE buffer up before the references; drop
  current_frame_index (Sashiko). Reviewed-by dropped, the patch changed.
- 2/2: Use the buffer checked in 1/2.
- Link to v1: https://patch.msgid.link/20261115-b4-vpu981-av1-refs-v1-0-c65769715db9@gmail.com

---
Arun Iyengar (2):
      media: verisilicon: av1: Find the reference buffers by timestamp
      media: verisilicon: av1: Read the segmentation map at the reference's offset

 drivers/media/platform/verisilicon/hantro.h        |  2 +
 drivers/media/platform/verisilicon/hantro_hw.h     |  3 -
 .../verisilicon/rockchip_vpu981_hw_av1_dec.c       | 79 ++++++++++++++--------
 3 files changed, 54 insertions(+), 30 deletions(-)
---
base-commit: aa0f4c41d4870a18e65772a1817af16427200371
change-id: 20261114-b4-vpu981-av1-refs-d9419af12e0d

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

