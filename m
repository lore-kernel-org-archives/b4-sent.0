From: Michael Riesch <michael.riesch@collabora.com>
Date: Fri, 20 Feb 2026 09:15:07 +0100
Subject: [PATCH v2 1/2] media: rockchip: rkcif: fix off by one bugs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260216-rkcif-fixes-v2-1-ee40931fe0ff@collabora.com>
References: <20260216-rkcif-fixes-v2-0-ee40931fe0ff@collabora.com>
In-Reply-To: <20260216-rkcif-fixes-v2-0-ee40931fe0ff@collabora.com>
To: Dan Carpenter <dan.carpenter@linaro.org>, 
 Paul Elder <paul.elder@ideasonboard.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mehdi Djait <mehdi.djait@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Cc: Collabora Kernel Team <kernel@collabora.com>, stable@kernel.org, 
 linux-media@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Michael Riesch <michael.riesch@collabora.com>, 
 Chen-Yu Tsai <wens@kernel.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771575308; l=2303;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=+CTMmqq/FBf0OUNoxM2h1AJhLJnTaBpUVbDN8g6FJXc=;
 b=jkqMSDUDANKBRHHyuTdC4NY7nDzfs9Wzk6LdU8E0ORJ+OVHx360FP8JRfy5VTJk4vVrWWJ7MQ
 HVgUvXIym14CwVEQA2gWZ/Cq0XPnkiR8U22M7NCl4m2YbgLdCjOcg6X
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Dan Carpenter <dan.carpenter@linaro.org>

Change these comparisons from > vs >= to avoid accessing one element
beyond the end of the arrays.
While at it, use ARRAY_SIZE instead of the _MAX enum values.

Fixes: 1f2353f5a1af ("media: rockchip: rkcif: add support for rk3568 vicap mipi capture")
Cc: stable@kernel.org
Signed-off-by: Dan Carpenter <dan.carpenter@linaro.org>
Reviewed-by: Michael Riesch <michael.riesch@collabora.com>
Reviewed-by: Paul Elder <paul.elder@ideasonboard.com>
Reviewed-by: Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Tested-by: Chen-Yu Tsai <wens@kernel.org>
[fix cosmetic issues]
Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 drivers/media/platform/rockchip/rkcif/rkcif-capture-mipi.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/media/platform/rockchip/rkcif/rkcif-capture-mipi.c b/drivers/media/platform/rockchip/rkcif/rkcif-capture-mipi.c
index 1b81bcc067ef..9e67160a16e4 100644
--- a/drivers/media/platform/rockchip/rkcif/rkcif-capture-mipi.c
+++ b/drivers/media/platform/rockchip/rkcif/rkcif-capture-mipi.c
@@ -489,8 +489,8 @@ static inline unsigned int rkcif_mipi_get_reg(struct rkcif_interface *interface,
 
 	block = interface->index - RKCIF_MIPI_BASE;
 
-	if (WARN_ON_ONCE(block > RKCIF_MIPI_MAX - RKCIF_MIPI_BASE) ||
-	    WARN_ON_ONCE(index > RKCIF_MIPI_REGISTER_MAX))
+	if (WARN_ON_ONCE(block >= ARRAY_SIZE(rkcif->match_data->mipi->blocks)) ||
+	    WARN_ON_ONCE(index >= ARRAY_SIZE(rkcif->match_data->mipi->regs)))
 		return RKCIF_REGISTER_NOTSUPPORTED;
 
 	offset = rkcif->match_data->mipi->blocks[block].offset;
@@ -510,9 +510,9 @@ static inline unsigned int rkcif_mipi_id_get_reg(struct rkcif_stream *stream,
 	block = stream->interface->index - RKCIF_MIPI_BASE;
 	id = stream->id;
 
-	if (WARN_ON_ONCE(block > RKCIF_MIPI_MAX - RKCIF_MIPI_BASE) ||
-	    WARN_ON_ONCE(id > RKCIF_ID_MAX) ||
-	    WARN_ON_ONCE(index > RKCIF_MIPI_ID_REGISTER_MAX))
+	if (WARN_ON_ONCE(block >= ARRAY_SIZE(rkcif->match_data->mipi->blocks)) ||
+	    WARN_ON_ONCE(id >= ARRAY_SIZE(rkcif->match_data->mipi->regs_id)) ||
+	    WARN_ON_ONCE(index >= ARRAY_SIZE(rkcif->match_data->mipi->regs_id[id])))
 		return RKCIF_REGISTER_NOTSUPPORTED;
 
 	offset = rkcif->match_data->mipi->blocks[block].offset;

-- 
2.39.5

