From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v4 0/2] media: verisilicon: Fix VDPU2 decoder error
 handling
Date: Thu, 26 Nov 2026 11:03:04 +0000
Message-Id: <20261126-vdpu2-errreset-v4-0-a955b1c8b119@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2XNTQ6CMBCG4auQrq3pP9WV9zAuCp1CjYppodEQ7
 m7BmBBcfsk874woQvAQ0bEYUYDko+8eeYhdgerWPBrA3uaNGGGKUipxss+BYQghQIQea6V1SQg
 /cMNRRs8Azr+W4Pny3XGorlD3c2W+aH3su/BePiY63/3ih208UUyw084IwitluDk1d+Nv+7q7o
 zme2Ioz8sdZ5toJcFKCsgBbztec/nGeOSl5JUFW1iqx5tM0fQB6SH54PAEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795690985; l=1888;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=11oMye5IkP9PU+O+uZwvxvHF43EAO+r22v9RqX+wWWA=;
 b=46EXLdYywrCDMrE7/4LRwjV52TTjcTlQPOOTob2WPUNbuO4utqURogAo66ZFyD0dwAugtxaHO
 OWr3wB+yxhICoDmr2YJp0c8pOdGsIgeop8IxufxYqpfNRdhvIJEAkTM
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The VDPU2 decoder reports failed decodes as done, and after an error
its interrupt handler can finish a job while the decoder may still be
active.

Tested on Orange Pi 5 (RK3588S), v7.3-based KASAN kernel:
5 bus errors and 5 timeouts, simulated by a test-only patch that injects
the status bits, each reset once and ended the job;
buffer-empty kept the job, output bit-exact; 186 resets in error-stream
stress, no watchdog; VP8 61/61 and H.264 conformance unchanged.
Build-tested on media next. MPEG-2, RK3399 and RK3568 untested.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Changes in v4:
- Patch 2: soft-reset the decoder after a bus, stream or ASO error
  or a timeout, before finishing the job (Nicolas)
- Rebased on media next
- Link to v3: https://patch.msgid.link/20261121-vdpu2-errreset-v3-0-073b5e5bdd64@gmail.com

Changes in v3:
- Patch 2: read DEC_E before clearing the status, as G2 does (Sashiko)
- Link to v2: https://patch.msgid.link/20261120-vdpu2-errreset-v2-0-8f4ef55e6dee@gmail.com

Changes in v2:
- Patch 2: no reset after an error; handle the interrupt like the G2
  handler instead (Nicolas)
- Link to v1: https://patch.msgid.link/20261119-vdpu2-errreset-v1-0-f8fa403b6a3a@gmail.com

---
Arun Iyengar (2):
      media: verisilicon: Don't report VDPU2 decoder errors as success
      media: verisilicon: Reset the VDPU2 decoder after an error

 .../platform/verisilicon/rockchip_vpu2_regs.h      |  4 +++
 .../media/platform/verisilicon/rockchip_vpu_hw.c   | 42 +++++++++++++++++++---
 2 files changed, 41 insertions(+), 5 deletions(-)
---
base-commit: b4e3c4b6a36fd76f57bf3e48638f68ddecc54ba4
change-id: 20261115-vdpu2-errreset-8688700393a3

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

