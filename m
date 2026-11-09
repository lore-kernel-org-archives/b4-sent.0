From: Sergei Khomenkov <shomenkow@gmail.com>
Date: Mon, 09 Nov 2026 16:43:51 +0300
Subject: [PATCH 1/3] media: verisilicon: stop the VEPU1 JPEG encoder after
 an unfinished frame
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-hantro-buflimit-v1-1-f0b86ce61e66@gmail.com>
References: <20261109-hantro-buflimit-v1-0-f0b86ce61e66@gmail.com>
In-Reply-To: <20261109-hantro-buflimit-v1-0-f0b86ce61e66@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794231837; l=3446;
 i=shomenkow@gmail.com; s=20261104; h=from:subject:message-id;
 bh=zI1doLggNAdKArdfoF8NOsjTBvai2n/eWahpgrADzl4=;
 b=8i+V7bEymp3SbAXhd4ILpebsao8cHm3kZV+rAwGPEaCvrJGhxMx0PLQmL0tt4yySDSzHBZ10+
 s0AYQgzA3KKCl4CkjCPqkaPVq/KO2cNlL5R+YVmF9czzhtjDif/g6CW
X-Developer-Key: i=shomenkow@gmail.com; a=ed25519;
 pk=FwuHDVe7aiISDMLmQEcMC+RflEIJ6kEp/ekwznWXmI8=
X-Endpoint-Received: by B4 Relay for shomenkow@gmail.com/20261104 with auth_id=1409
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a JPEG stream does not fit the CAPTURE buffer, the H1 raises an
interrupt with BUFFER_FULL set and FRAME_RDY clear, and pauses with the
enable bit of H1_REG_ENC_CTRL still set, waiting for more output space.
rockchip_vpu1_vepu_irq() returns the buffer with the ERROR flag but
clears only the interrupt and AXI registers, so the next job is
programmed into the paused encoder: its ENC_CTRL write aborts the paused
frame, which raises a reset interrupt while the new job is being set up,
and that job times out. The watchdog then calls
rockchip_vpu1_enc_reset(), which sets H1_REG_INTERRUPT_DIS_BIT, and the
JPEG encoder path never clears that bit again, so every later job times
out as well. That second problem is not addressed here.

Write 0 to the enable register when an interrupt does not report a
finished frame. The write comes before the interrupt and AXI registers
are cleared, and before the next job is scheduled. On the RK3026 it
raises no interrupt of its own: in the test below the encoder raised one
interrupt per frame and no job timed out.

The encoder rarely gets there today, because the stream limit it is
given is eight times too large; the next patch fixes that, and then
every frame that does not fit ends this way.

rockchip_vpu2_vepu_irq() and stm32mp25_venc_irq() do not stop the
encoder either. I cannot test the VEPU2 or the STM32MP25, so this patch
leaves them alone.

Found with an LLM coding assistant while porting mainline Linux to a
Rockchip RK3026 board (VEPU1); the assistant also drafted the code and
this message. Tested on that board with the stream limit fixed: without
this change the job after a buffer-full interrupt gets a reset interrupt
and every later job times out; with it the frame that does not fit comes
back with the ERROR flag and the following jobs, overflowing or not,
complete as before (10 alternating jobs, and four overflowing frames
queued back to back followed by fitting ones). Counted in
/proc/interrupts over 24 runs of the series (48 frames, 16 of them
ending in a buffer full), every frame raised exactly one interrupt, so
the stop write raises none. Only buffer full was exercised, not bus
errors or the hardware timeout. Not tested on other SoCs.

Fixes: 775fec69008d ("media: add Rockchip VPU JPEG encoder driver")
Cc: stable@vger.kernel.org
Signed-off-by: Sergei Khomenkov <shomenkow@gmail.com>
---
 drivers/media/platform/verisilicon/rockchip_vpu_hw.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
index 02673be9878e..144d320302a1 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
@@ -376,6 +376,15 @@ static irqreturn_t rockchip_vpu1_vepu_irq(int irq, void *dev_id)
 	state = (status & H1_REG_INTERRUPT_FRAME_RDY) ?
 		VB2_BUF_STATE_DONE : VB2_BUF_STATE_ERROR;
 
+	/*
+	 * An interrupt without FRAME_RDY does not end the frame: after a
+	 * buffer full the encoder pauses with its enable bit still set,
+	 * waiting for more output space. Stop it, so that the next job is
+	 * not programmed into a paused encoder.
+	 */
+	if (!(status & H1_REG_INTERRUPT_FRAME_RDY))
+		vepu_write(vpu, 0, H1_REG_ENC_CTRL);
+
 	vepu_write(vpu, 0, H1_REG_INTERRUPT);
 	vepu_write(vpu, 0, H1_REG_AXI_CTRL);
 

-- 
2.53.0

