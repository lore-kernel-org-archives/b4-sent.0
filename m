From: Sergei Khomenkov <shomenkow@gmail.com>
Subject: [PATCH v3 0/3] media: verisilicon: fix JPEG encoder writes past
 the CAPTURE buffer
Date: Tue, 24 Nov 2026 16:40:16 +0300
Message-Id: <20261124-hantro-buflimit-v3-0-780903970ca0@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WNwQqDMBAFf0VybsomYjQ99T9KDxo3uqCmJDa0i
 P/eKBQEj/Ng5i0soCcM7JYtzGOkQG5KkF8yZvp66pBTm5hJkEoIUDyNs3e8eduBRpo5FAVWIHW
 DMmfJenm09NmLj2finsLs/Hc/iGJb/y19akXBgVtoKmVQCVTq3o01DVfjRra1ojz4As6+3Hxbl
 hpatNqao7+u6w/R2YDI7gAAAA==
X-Change-ID: 20261106-hantro-buflimit-055e8029be23
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Chen-Yu Tsai <wenst@chromium.org>, 
 Hugues Fruchet <hugues.fruchet@foss.st.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, 
 linux-stm32@st-md-mailman.stormreply.com, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sergei Khomenkov <shomenkow@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795527620; l=3845;
 i=shomenkow@gmail.com; s=20261104; h=from:subject:message-id;
 bh=CS9Hh2KOnLAmmovBFtvM/OChuActMNOyzEIbmU8KbTc=;
 b=y17AVohcoo/KohpGkVwr+Ely6dXWd6I4yYSnnuzNlvSkAMEJvfHGiBx1esxZ7X04A3R7vSKwQ
 3i8ptxwqT4MAbW5cmI5aHdACqvfkRQ5iPFh1yaZPPIAp6l2S+5UkOJs
X-Developer-Key: i=shomenkow@gmail.com; a=ed25519;
 pk=FwuHDVe7aiISDMLmQEcMC+RflEIJ6kEp/ekwznWXmI8=
X-Endpoint-Received: by B4 Relay for shomenkow@gmail.com/20261104 with auth_id=1409
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The H1 and VEPU2 JPEG encoders are given their stream buffer limit in
bytes, but the register counts 64-bit words, so a stream that does not
fit the CAPTURE buffer is written past its end, up to eight times the
buffer size. A quality 100 frame of noise does not fit the default
sizeimage, and userspace can also set a smaller one.

Patch 1 stops the encoder in the VEPU1 interrupt handler after a
buffer-full interrupt, which leaves it paused. Patch 2 programs the
limit in 64-bit words, rounded down to whole 64-byte bursts, on the H1
and on the VEPU2. Patch 3 makes the smallest CAPTURE sizeimage of the
JPEG encoders the 624-byte header plus one burst, set in the variant
format data.

Testing, on an RK3026 (its H1 is Rockchip's VEPU1) only: without the
series the encoder wrote 230 KB past a default-sized 640x480 buffer and
1.6 MB past a 1920x1088 one. With it, 17 overflowing frames, four of
them queued back to back, stopped at the programmed limit without
writing past the plane and came back with the ERROR flag, one interrupt
each and no timeout; the jobs after them completed, and frames that fit
are byte for byte the same as before. A sizeimage of 1 or 600 now reads
back 688. v4l2-compliance 1.30.1 on the encoder node shows no new
failures.

I cannot test the VEPU2 or the STM32MP25 VENC. The VEPU2 gets patches 2
and 3, but its interrupt handler is unchanged; Nicolas offered to test
the VEPU2 part of patch 2. The STM32MP25 VENC runs the H1 code of patch
2 and gets patch 3, but not the stop of patch 1.

The bugs were found and the patches drafted with an LLM coding
assistant while porting mainline Linux to an RK3026 board.

---
Changes in v3:
- Move the LLM and test notes below the --- line and add an
  Assisted-by: tag (Nicolas).
- 1/3: add Nicolas's Reviewed-by.
- 2/3: program the VEPU2 JPEG encoder's limit in 64-bit words as well;
  Nicolas offered to test it. Subject says "JPEG encoder", not "H1".
- 3/3: move the header + 64 floor out of hantro_try_fmt() into a new
  min_size field of struct hantro_fmt, set in the JPEG encoder formats
  of the Rockchip and STM32MP25 variants (Nicolas).
- Rebase on media next aa0f4c41d487.
- Link to v2: https://lore.kernel.org/all/20261110-hantro-buflimit-v2-0-ff7790def9fc@gmail.com/

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
      media: verisilicon: program the JPEG encoder stream limit in 64-bit words
      media: verisilicon: leave room for the JPEG header and one stream burst

 drivers/media/platform/verisilicon/hantro.h           |  2 ++
 .../media/platform/verisilicon/hantro_h1_jpeg_enc.c   |  4 +++-
 drivers/media/platform/verisilicon/hantro_h1_regs.h   |  4 ++++
 drivers/media/platform/verisilicon/hantro_v4l2.c      |  3 +++
 .../platform/verisilicon/rockchip_vpu2_hw_jpeg_enc.c  |  4 +++-
 drivers/media/platform/verisilicon/rockchip_vpu_hw.c  | 19 +++++++++++++++++++
 drivers/media/platform/verisilicon/stm32mp25_vpu_hw.c |  1 +
 7 files changed, 35 insertions(+), 2 deletions(-)
---
base-commit: aa0f4c41d4870a18e65772a1817af16427200371
change-id: 20261106-hantro-buflimit-055e8029be23

Best regards,
-- 
Sergei Khomenkov <shomenkow@gmail.com>

