From: Sergei Khomenkov <shomenkow@gmail.com>
Subject: [PATCH 0/3] media: verisilicon: fix VEPU1 JPEG encoder writes past
 the CAPTURE buffer
Date: Mon, 09 Nov 2026 16:43:50 +0300
Message-Id: <20261109-hantro-buflimit-v1-0-f0b86ce61e66@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MSQqAMAwAv1JyNtBWFPUr4sElasCNVEWQ/t3gc
 QZmXggkTAEq84LQzYH3TcElBvq53SZCHpTBW587Z3NUecqO3TUuvPKJNsuosL7syKeg1SE08vM
 f6ybGD+G1YdFhAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794231837; l=3241;
 i=shomenkow@gmail.com; s=20261104; h=from:subject:message-id;
 bh=en/jn4YMqVb7Nenx7Rb8ix4nBUnrgggys7Qhs7eVdYc=;
 b=Vzu8+WR8qtMz9STuQ8vNsgANjERJiMoL0jn3Kz0IB5o5qa5qjmePpUxxb375dpQGxFTRimMKP
 T/vCqhTRomuBg/iauDBMz10oDcnBKdVSRsyoTRBpSaar41IE7Ta6eJ/
X-Developer-Key: i=shomenkow@gmail.com; a=ed25519;
 pk=FwuHDVe7aiISDMLmQEcMC+RflEIJ6kEp/ekwznWXmI8=
X-Endpoint-Received: by B4 Relay for shomenkow@gmail.com/20261104 with auth_id=1409
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The H1 JPEG encoder is given its stream buffer limit in bytes, but the
register counts 64-bit words, so a stream that does not fit the CAPTURE
buffer is written past its end, up to eight times the buffer size. A
quality 100 frame of noise does not fit the default sizeimage, and
userspace can also set a smaller one, so any client of the encoder node
can get there. On an RK3026, which has no IOMMU in front of the VPU, the
encoder wrote 230 KB past a default-sized 640x480 buffer and 1.6 MB
past a 1920x1088 one.

Patch 2 writes the limit in the right unit, rounded down to the 64-byte
write bursts measured on the RK3026. With it, a frame that does not fit
ends with a buffer-full interrupt, which the driver turns into an ERROR
buffer but which leaves the encoder paused, so the following jobs time
out. Patch 1, which goes first, stops the VEPU1 encoder after such an
interrupt. The encoder still writes one burst with a limit of 0, and the
driver writes the 624-byte header itself, so patch 3 makes the smallest
CAPTURE sizeimage the header plus one burst.

All three were tested on the RK3026 (VEPU1) only; the test paragraph of
each patch has the numbers. v4l2-compliance 1.30.1 on the encoder node
shows no new failures with the series; its one failure (the raw OUTPUT
format's colorspace is not SRGB, v4l2-test-formats.cpp:892) fails
without it as well. The VEPU2 JPEG encoder (rockchip_vpu2_hw_jpeg_enc.c,
rockchip_vpu2_vepu_irq()) has the same code and the same limit in bytes,
and the STM32MP25 VENC runs the H1 code that patch 2 changes but has its
own interrupt handler without the stop of patch 1. I cannot test either,
so this series leaves the VEPU2 and the STM32MP25 handler alone; a check
there with a quality 100 noise frame and a default-sized CAPTURE buffer
would be welcome, and the same change can follow.

Not changed here: after a watchdog timeout, rockchip_vpu1_enc_reset()
sets H1_REG_INTERRUPT_DIS_BIT and the JPEG encoder path never clears
it, so every later job times out until the module is reloaded. That
can be a follow-up.

Before v5.18 (dc8bfe1e482d, "media: hantro: output encoded JPEG
content directly to capture buffers") the stream went to a bounce
buffer; patches 2 and 3 do not apply there and those trees would need a
separate backport.

The bugs were found and the patches drafted with an LLM coding
assistant while porting mainline Linux to an RK3026 board; every claim
in the messages was checked against the code or measured on the board.

---
Sergei Khomenkov (3):
      media: verisilicon: stop the VEPU1 JPEG encoder after an unfinished frame
      media: verisilicon: program the H1 JPEG stream limit in 64-bit words
      media: verisilicon: leave room for the JPEG header and one stream burst

 drivers/media/platform/verisilicon/hantro_h1_jpeg_enc.c | 10 +++++++++-
 drivers/media/platform/verisilicon/hantro_v4l2.c        | 10 ++++++++++
 drivers/media/platform/verisilicon/rockchip_vpu_hw.c    |  9 +++++++++
 3 files changed, 28 insertions(+), 1 deletion(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261106-hantro-buflimit-055e8029be23

Best regards,
-- 
Sergei Khomenkov <shomenkow@gmail.com>

