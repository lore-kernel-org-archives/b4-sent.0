From: David Heidelberg <david@ixit.cz>
Date: Thu, 03 Sep 2026 17:21:42 +0200
Subject: [PATCH v3 1/2] mfd: wcd934x: Fix NULL pointer dereference on IRQ
 probe deferral
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260903-wcd-dma-v3-1-d3920c6563c4@ixit.cz>
References: <20260903-wcd-dma-v3-0-d3920c6563c4@ixit.cz>
In-Reply-To: <20260903-wcd-dma-v3-0-d3920c6563c4@ixit.cz>
To: Lee Jones <lee@kernel.org>, Thomas Tai <thomas.tai@oracle.com>, 
 Konrad Rzeszutek Wilk <konrad.wilk@oracle.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>
Cc: mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 stable@vger.kernel.org, Sashiko <sashiko-bot@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1653; i=david@ixit.cz;
 h=from:subject:message-id; bh=VU4vkCCqWQAD3UTvE2YpWnadOlQKw+33pNCRUeftoV0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqmZCGhwMASsnSM+8t5MAsRgjVHLop/57TOI64h
 WI1V4q6fAaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapmQhgAKCRBgAj/E00kg
 coPnEAC1Px2HkZLmtRmIHu9hIipFEDgWLidgYxi1KZr576tJQGtw/9aEaKWPkCPlKy0D3AWKKOq
 sNUlIyEVWwO/4EHjAHv+7qyodwjoRNB64Uf02m7ROxJO4ocV7GsagVe56yt6v1LhoBD9bQkEmPl
 52N87NlJIO0yhaxdLnAFq9XYnRNXEnpSn8n3EAU0M4POaf8j2TqonGq0nGAMfLVJ1CPsGdBTaQt
 oVftq8QvEDQFRYEMxLQue6ZKvu8Xs/oj7oza9HUex9DdbVwvXnUx/W9QQtd/Xq5Oe5slG/iPU71
 ctWo3S5eFv4vkaLPgeDjsJt585iwxkgoeJhWSk0NALwFhBiGTHUxiE9clFMWVZcsqXE/IH0tJzQ
 fOmO6eGVCvQlP7ojqeX1slIRgzuUsmjiCaqOOAWZp0ojKnL8eQLZT/OqMvvIzQ69u0xdoSDrr7x
 6eI/KL/gPQgJ5v+z3UEwDuXOCnUQp40tnCW/0UYV7w+DrEamiuHZWmSzjEyKEjzn6DaozHWoH9C
 NPYT6R7LXgSmTVRIloXlp7CfKy2TXSkmViZEr8tKe/9cJZcEOlRIhgEtJwJLPOQaY5CAxCPPw/S
 FfgECH26z6JU8+aCCZZGVbnM+fNTgezxcLQpIid8eAnwjEfn8AZhEiODrwKgxmZ0g9ULx3n9grN
 ovw1ocL3n3xkvlw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ddata->dev is only assigned at the end of wcd934x_slim_probe(), but the
of_irq_get() error path has passed it to the error print since the
driver was added, while it is still NULL.

This used to be harmless with dev_err(), which copes with a NULL device
and was skipped on -EPROBE_DEFER. Since the switch to dev_err_probe(), a
deferred IRQ reaches device_set_deferred_probe_reason() ->
dev_driver_string(), which dereferences the NULL pointer and crashes
during probe. Use dev, which is already valid at this point.

Cc: stable@vger.kernel.org
Fixes: 0f1b1b899521 ("mfd: wcd934x: Simplify with dev_err_probe()")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Link: https://lore.kernel.org/mfd/20260903145651.AC1311F00ACA@smtp.kernel.org/
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/mfd/wcd934x.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/mfd/wcd934x.c b/drivers/mfd/wcd934x.c
index 3c3080e8c8cf7..3a939e7ad3da5 100644
--- a/drivers/mfd/wcd934x.c
+++ b/drivers/mfd/wcd934x.c
@@ -218,17 +218,17 @@ static int wcd934x_slim_probe(struct slim_device *sdev)
 	int ret;
 
 	ddata = devm_kzalloc(dev, sizeof(*ddata), GFP_KERNEL);
 	if (!ddata)
 		return	-ENOMEM;
 
 	ddata->irq = of_irq_get(np, 0);
 	if (ddata->irq < 0)
-		return dev_err_probe(ddata->dev, ddata->irq,
+		return dev_err_probe(dev, ddata->irq,
 				     "Failed to get IRQ\n");
 
 	ddata->extclk = devm_clk_get(dev, "extclk");
 	if (IS_ERR(ddata->extclk))
 		return dev_err_probe(dev, PTR_ERR(ddata->extclk),
 				     "Failed to get extclk");
 
 	ddata->supplies[0].supply = "vdd-buck";

-- 
2.55.0

