From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v3 0/2] media: verisilicon: Fix VDPU2 decoder error
 handling
Date: Sat, 21 Nov 2026 06:30:20 +0000
Message-Id: <20261121-vdpu2-errreset-v3-0-073b5e5bdd64@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WNTQ6CMBgFr0K6tqY/UIsr72FcFPgKNUJJC42Gc
 HdbjAnR5SRv5i3IgzPg0TlbkINgvLFDBH7IUN2poQVsmsiIESYopQUOzTgzDM458DBhKaQ8EcJ
 LrjiK0uhAm+cWvN4+7OfqDvWUKmnRGT9Z99oeA027b7z8jQeKCdZSq5zwSiiuLm2vzONY2x6le
 GA7nZE/nUVd6hx0UYBoAPb6uq5vOxtlqf0AAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795242621; l=1971;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=1u5taNj+P7yOouobMLZ53fRbxme9fnoguPLNBW4jIKQ=;
 b=xgWfQ8NIkGVMLgnHHe8JrgTb7tJzzFTuTK/+ZyPcmWSpQefkaGuBU1+8+AiHQB9TeRfCnDWj4
 C2UajmH4aO0ACL4Wo+FKfEIlYGKWlszh5mhQH6FTirgq6jMfFPXkA0O
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The VDPU2 decoder reports failed decodes as done, and its interrupt
handler can finish a job the decoder is still working on.

Tested on Orange Pi 5 (RK3588S), v7.3-based KASAN kernel. v2: 72 H.264
fluster suite runs, 50 error-stream runs; no IOMMU faults or timeouts.
v3: one suite run and VP8 61/61, same results. The decoder was still
enabled after both buffer-empty interrupts of that run; a later
interrupt ended the job.
With a TEST-only patch (not in this series), the IRQ_NONE path ran
200 times on real registers; bus error and timeout, simulated 5 times
each by injected status bits, were logged and ended their jobs at once.
VP8 stayed 61/61 bit-exact.
A TEST-only injection of a decoder stopping right after the status clear:
with this order each re-raised interrupt ended its own job (bit-exact);
with the v2 order it ended the next job early.
Build-tested on media next. MPEG-2, RK3399 and RK3568 untested.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
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
      media: verisilicon: Handle VDPU2 decoder interrupts like the G2

 .../media/platform/verisilicon/rockchip_vpu_hw.c   | 24 +++++++++++++++++++---
 1 file changed, 21 insertions(+), 3 deletions(-)
---
base-commit: aa0f4c41d4870a18e65772a1817af16427200371
change-id: 20261115-vdpu2-errreset-8688700393a3

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

