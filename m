From: Sergei Khomenkov <shomenkow@gmail.com>
Subject: [PATCH v2 0/3] media: verisilicon: fix VEPU1 JPEG encoder writes
 past the CAPTURE buffer
Date: Tue, 10 Nov 2026 15:41:43 +0300
Message-Id: <20261110-hantro-buflimit-v2-0-ff7790def9fc@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WNwQrDIBAFfyXsuRa1RJKe+h8hh2jXZCHGolZag
 v9eG+ipxxl483aIGAgjXJsdAmaK5LcK8tSAWaZtRkb3yiC5VEJwxapMwTP9tCs5Soy3LXZc9hr
 lBerqEdDS6ygOY+WFYvLhfRxk8bW/Vv/XyoJxZrnulEElUKnb7CZaz8Y7GEspHxsD73quAAAA
X-Change-ID: 20261106-hantro-buflimit-055e8029be23
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Chen-Yu Tsai <wenst@chromium.org>, 
 Hugues Fruchet <hugues.fruchet@foss.st.com>, linux-media@vger.kernel.org, 
 linux-rockchip@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-stm32@st-md-mailman.stormreply.com, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sergei Khomenkov <shomenkow@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794314506; l=2924;
 i=shomenkow@gmail.com; s=20261104; h=from:subject:message-id;
 bh=Au9m2ZyJsM3rdkYmqexDG3q3feqvM6j21m3H6c6K1c0=;
 b=vmeArtTiWleE0liax4kfCT491w/QAjEfFTub6oVHTQqfEiqvH9AVODBQI7koxcvGyZdbFrIdp
 inI0naDjH4tA5WgSDPPtmKjthKVj4CqHjnIVuwKy3olsRRsJJQOp54U
X-Developer-Key: i=shomenkow@gmail.com; a=ed25519;
 pk=FwuHDVe7aiISDMLmQEcMC+RflEIJ6kEp/ekwznWXmI8=
X-Endpoint-Received: by B4 Relay for shomenkow@gmail.com/20261104 with auth_id=1409
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The H1 JPEG encoder is given its stream buffer limit in bytes, but the
register counts 64-bit words, so a stream that does not fit the CAPTURE
buffer is written past its end, up to eight times the buffer size. A
quality 100 frame of noise does not fit the default sizeimage, and
userspace can also set a smaller one.

Patch 1 stops the VEPU1 encoder after a buffer-full interrupt, which
leaves it paused. Patch 2 programs the limit in 64-bit words, rounded
down to whole 64-byte bursts. Patch 3 makes the smallest CAPTURE
sizeimage the 624-byte header plus one burst.

Testing, on an RK3026 (VEPU1) only: without the series the encoder
wrote 230 KB past a default-sized 640x480 buffer and 1.6 MB past a
1920x1088 one. With it, 17 overflowing frames, four of them queued back
to back, stopped at the programmed limit without writing past the plane
and came back with the ERROR flag, one interrupt each and no timeout;
the jobs after them completed, and frames that fit are byte for byte the
same as before. A sizeimage of 1 or 600 now reads back 688.
v4l2-compliance 1.30.1 on the encoder node shows no new failures.

The VEPU2 JPEG encoder writes its limit in bytes the same way, but I
cannot test it, so its limit and interrupt handler are unchanged; the
common patch 3 applies to it as well. The STM32MP25 VENC runs the H1
code of patch 2 and gets patch 3, but not the stop of patch 1. Neither
is tested.

The bugs were found and the patches drafted with an LLM coding
assistant while porting mainline Linux to an RK3026 board.

---
Changes in v2:
- Trim the commit messages and code comments (Nicolas).
- 1/3: clear only the enable bit of H1_REG_ENC_CTRL instead of writing
  0 to the register, and add a rate-limited warning per fault bit, as
  hantro_g2_irq() does; add the H1_REG_INTERRUPT_* fault bits (Nicolas).
- 3/3: keep max(): it is a floor of header + one burst, the 64-byte
  rounding is on the stream limit in 2/3 (Nicolas).
- Move the test numbers from the commit messages to this cover letter.
- Link to v1: https://lore.kernel.org/r/20261109-hantro-buflimit-v1-0-f0b86ce61e66@gmail.com

---
Sergei Khomenkov (3):
      media: verisilicon: stop the VEPU1 JPEG encoder after an unfinished frame
      media: verisilicon: program the H1 JPEG stream limit in 64-bit words
      media: verisilicon: leave room for the JPEG header and one stream burst

 .../media/platform/verisilicon/hantro_h1_jpeg_enc.c    |  7 ++++++-
 drivers/media/platform/verisilicon/hantro_h1_regs.h    |  4 ++++
 drivers/media/platform/verisilicon/hantro_v4l2.c       |  9 +++++++++
 drivers/media/platform/verisilicon/rockchip_vpu_hw.c   | 18 ++++++++++++++++++
 4 files changed, 37 insertions(+), 1 deletion(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261106-hantro-buflimit-055e8029be23

Best regards,
-- 
Sergei Khomenkov <shomenkow@gmail.com>

