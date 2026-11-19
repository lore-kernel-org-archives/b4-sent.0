From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/2] media: verisilicon: Fix VDPU2 decoder error handling
Date: Thu, 19 Nov 2026 06:20:06 +0000
Message-Id: <20261119-vdpu2-errreset-v1-0-f8fa403b6a3a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSwqDQBBF0a1IjdPQHzStWwkZ+HmJ5UClSiUg7
 t3WDM/g3p0UwlCqsp0EGytPY4J7ZNT29fiF4S6ZvPWFcy43Wzev3kBEoFhMLGJ8WhvKUAdK0Sz
 48O8evt5/69oMaJfrQsdxAjWqA61yAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795069206; l=1334;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=2RFAUR3ng5/QnrGOQnWU+xGFztNU4gfgufFi7kzRutU=;
 b=OjJRsu4+0DdVHmvl5f/yUFh9DPg7MhS/pT7qenF5H07QM1yFTfJx6KXvTla6h9Fqw68gjmIuo
 mtkobnUna1sCg+BTTpBZtAsQOddm23UGyyBfLbCHqFHog2CZUfoSsl2
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The VDPU2 decoder reports failed decodes as done and is not reset
after an error, so it can keep accessing freed buffers.

Tested on an Orange Pi 5 (RK3588S), KASAN v7.3 based kernel: 72 H.264
fluster runs, no IOMMU faults or stalls; with patch 1 alone, an earlier
run faulted. The VP8 test vectors pass (61/61). Two H.264 vectors
(FI1_Sony_E, MR8_BT_B) fail in 1 to 4 of 249 runs each, with patch 1
alone as with both. Build-tested on media next. MPEG-2, RK3399 and
RK3568 untested.

Independent of "Recover the Rockchip VPUs from faults and timeouts"
v3 [1]; the two only conflict in one #include line.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

[1] https://lore.kernel.org/r/20261113-hantro-robust-v3-0-82383c722ad2@gmail.com

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (2):
      media: verisilicon: Don't report VDPU2 decoder errors as success
      media: verisilicon: Reset the VDPU2 decoder after an error

 .../media/platform/verisilicon/rockchip_vpu_hw.c   | 23 +++++++++++++++++++---
 1 file changed, 20 insertions(+), 3 deletions(-)
---
base-commit: aa0f4c41d4870a18e65772a1817af16427200371
change-id: 20261115-vdpu2-errreset-8688700393a3

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

