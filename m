From: Michael Riesch <michael.riesch@collabora.com>
Date: Mon, 16 Feb 2026 13:28:47 +0100
Subject: [PATCH 1/2] media: synopsys: csi2rx: fix out-of-bounds check for
 formats array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260216-snps-csi2rx-v1-1-747bc7408f87@collabora.com>
References: <20260216-snps-csi2rx-v1-0-747bc7408f87@collabora.com>
In-Reply-To: <20260216-snps-csi2rx-v1-0-747bc7408f87@collabora.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mehdi Djait <mehdi.djait@linux.intel.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, Frank Li <Frank.Li@nxp.com>, 
 Dan Carpenter <dan.carpenter@linaro.org>
Cc: Collabora Kernel Team <kernel@collabora.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@kernel.org, Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771244928; l=989;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=VteqfxDD/ymX3hwze8jlu6vilo9kqUzwk/5uLNi6ndw=;
 b=8D3CCwTA9LPe0iN54HoRh3Q7IW8Bi2aUBpaxDlFGRVU/CUvLLJ0T1+PKX4kSSFM0dfT8ev2lE
 AlTZOfw90GICUpaDA3y6R8EFiHtpH0ligqLkYMdjfm/2C3V0w7bENOY
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The out-of-bounds check for the format array is off by one. Fix the
check.

Fixes: 355a11004066 ("media: synopsys: add driver for the designware mipi csi-2 receiver")
Cc: stable@kernel.org
Suggested-by: Dan Carpenter <dan.carpenter@linaro.org>
Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 drivers/media/platform/synopsys/dw-mipi-csi2rx.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/media/platform/synopsys/dw-mipi-csi2rx.c b/drivers/media/platform/synopsys/dw-mipi-csi2rx.c
index 170346ae1a59..4d96171a650b 100644
--- a/drivers/media/platform/synopsys/dw-mipi-csi2rx.c
+++ b/drivers/media/platform/synopsys/dw-mipi-csi2rx.c
@@ -301,7 +301,7 @@ dw_mipi_csi2rx_enum_mbus_code(struct v4l2_subdev *sd,
 
 		return 0;
 	case DW_MIPI_CSI2RX_PAD_SINK:
-		if (code->index > csi2->formats_num)
+		if (code->index >= csi2->formats_num)
 			return -EINVAL;
 
 		code->code = csi2->formats[code->index].code;

-- 
2.39.5

