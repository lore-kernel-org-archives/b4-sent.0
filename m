From: Michael Riesch <michael.riesch@collabora.com>
Subject: [PATCH 0/2] media: synopsys: csi2rx: various fixes
Date: Mon, 16 Feb 2026 13:28:46 +0100
Message-Id: <20260216-snps-csi2rx-v1-0-747bc7408f87@collabora.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAH4Nk2kC/02NQQrCQAxFrzJkbejMaKv0KuIiM6ZtNmNJQAqld
 zfixt1/8B5/B2MVNhjDDspvMXk1h3QKUBdqM6M8nSHHPMScBrS2GlaTrBteSx8pxRvTmcCLQsZ
 YlFpdvk25dP/2JJsfubYq//YY7o/j+AD9O7CHhAAAAA==
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mehdi Djait <mehdi.djait@linux.intel.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, Frank Li <Frank.Li@nxp.com>, 
 Dan Carpenter <dan.carpenter@linaro.org>
Cc: Collabora Kernel Team <kernel@collabora.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@kernel.org, Michael Riesch <michael.riesch@collabora.com>, 
 kernel test robot <lkp@intel.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771244928; l=956;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=/LZt/T9liTWeDgycIZZt6KHvICc1pPZDiLrpc2mzndw=;
 b=rkTgzCPrAU6piNT7K84+HpLVyOPTyAX2KeHui5bQp2dq3/xMINWNwdI83Jz24w8ABE0dMyR0c
 HoLmB7PJH02BkxWIiuG0OBQfef525e8sIcpGntbbI7zjlJFqmRCGMDR
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Habidere,

This series contains two fixes that address two issues raised by
CI bots.

1) A stupid off-by-one mistake in the check that protects the formats
   array. Thanks to Dan and his smatch bot.

2) A missing Kconfig dependency discovered by the lkp bot.

At this point, thanks to all the people that maintain those bots/the
CI infrastructure!

Best regards,
Michael

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
Michael Riesch (2):
      media: synopsys: csi2rx: fix out-of-bounds check for formats array
      media: synopsys: csi2rx: add missing kconfig dependency

 drivers/media/platform/synopsys/Kconfig          | 1 +
 drivers/media/platform/synopsys/dw-mipi-csi2rx.c | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)
---
base-commit: c824345288d11e269ce41b36c105715bc2286050
change-id: 20260216-snps-csi2rx-7b50a108ea3a

Best regards,
-- 
Michael Riesch <michael.riesch@collabora.com>

