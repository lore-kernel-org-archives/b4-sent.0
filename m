From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 0/2] media: verisilicon: Fix VDPU2 decoder error
 handling
Date: Fri, 20 Nov 2026 02:49:13 +0000
Message-Id: <20261120-vdpu2-errreset-v2-0-8f4ef55e6dee@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/12Nyw6CMBBFf4XM2po+FIsr/8OwKDDAGKFkCo2G8
 O8Cxo3Lk5x77gwBmTDANZmBMVIg36+gDwmUresbFFStDFrqVCl1FrEaJi2QmTHgKGxq7UVKkxl
 nYB0NjDW99uA9/3KYigeW41bZjJbC6Pm9P0a1eb949h+PSkhR29qdpClSZ9yt6Rw9j6XvIF+W5
 QPt8b64vgAAAA==
X-Change-ID: 20261115-vdpu2-errreset-8688700393a3
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Jonas Karlman <jonas@kwiboo.se>, 
 Boris Brezillon <boris.brezillon@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795142953; l=1549;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=236hsCejcx3sS9x+HFSJjCRXf+BV1f1+zibsBZf0JVg=;
 b=+ScOgDQeEaI5FZeSrS1ngM1Vh5HeTVe1p8NGZR8cjcXzNPcKHKCVAGU/ex+lwBGdM2kHJUuCi
 3ZpiTcU5blgAZD4G9tSKHLAmAsOsrEeaAqfLZAxw7WU3d/sWWcCRDiu
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The VDPU2 decoder reports failed decodes as done, and its interrupt
handler can finish a job the decoder is still working on.

Tested on Orange Pi 5 (RK3588S), v7.3-based KASAN kernel: 72 H.264
fluster suite runs, 50 error-stream runs, VP8 61/61; no IOMMU faults or
timeouts. The decoder was still enabled after 72 buffer-empty
interrupts; a later interrupt ended each of those jobs.
With a TEST-only patch (not in this series), the IRQ_NONE path ran
200 times on real registers; bus error and timeout, simulated 5 times
each by injected status bits, were logged and ended their jobs at once.
VP8 stayed 61/61 bit-exact.
Build-tested on media next. MPEG-2, RK3399 and RK3568 untested.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Changes in v2:
- Patch 2: no reset after an error; handle the interrupt like the G2
  handler instead (Nicolas)
- Link to v1: https://patch.msgid.link/20261119-vdpu2-errreset-v1-0-f8fa403b6a3a@gmail.com

---
Arun Iyengar (2):
      media: verisilicon: Don't report VDPU2 decoder errors as success
      media: verisilicon: Handle VDPU2 decoder interrupts like the G2

 drivers/media/platform/verisilicon/rockchip_vpu_hw.c | 20 ++++++++++++++++++--
 1 file changed, 18 insertions(+), 2 deletions(-)
---
base-commit: aa0f4c41d4870a18e65772a1817af16427200371
change-id: 20261115-vdpu2-errreset-8688700393a3

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

