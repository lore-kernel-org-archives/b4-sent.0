From: Casey Connolly <casey.connolly@linaro.org>
Date: Fri, 20 Mar 2026 16:45:40 +0100
Subject: [PATCH 1/2] serial: msm-geni: allow invalid clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260320-casey-qcom-rpmh-serial-fixes-v1-1-b81d05832eec@linaro.org>
References: <20260320-casey-qcom-rpmh-serial-fixes-v1-0-b81d05832eec@linaro.org>
In-Reply-To: <20260320-casey-qcom-rpmh-serial-fixes-v1-0-b81d05832eec@linaro.org>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Andrew Goodbody <andrew.goodbody@linaro.org>, 
 Stephen Boyd <swboyd@chromium.org>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=openpgp-sha256; l=1729;
 i=casey.connolly@linaro.org; h=from:subject:message-id;
 bh=7/r+622xulBFw7ksZmxxltq0sQqqtV5oui7FCVQq6rg=;
 b=owGbwMvMwCFYaeA6f6eBkTjjabUkhsy92avV9pyY864hSPfec00jD/biMuk1T2vOuTbOuf58i
 8XCjG+6HaUsDIIcDLJiiiziJ5ZZNq29bK+xfcEFmDmsTCBDGLg4BWAiPNcY/tfuW37uR2/W4fMr
 ZrFsOOuj93DTytDK+Nrb/ZPcZm7JOSHN8M+0uWXiAfljlSd9FVz3bF5dXVnnea//tMoV/ayHKRt
 MCs8CAA==
X-Developer-Key: i=casey.connolly@linaro.org; a=openpgp;
 fpr=83B24DA7FE145076BC38BB250CD904EB673A7C47
X-Endpoint-Received: by B4 Relay for casey.connolly@linaro.org/default with auth_id=688
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pre-relocation we probably won't have a clock but it's usually
been enabled for us already, or worst case we will enable it after
relocation.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
---
 drivers/serial/serial_msm_geni.c | 15 +++++----------
 1 file changed, 5 insertions(+), 10 deletions(-)

diff --git a/drivers/serial/serial_msm_geni.c b/drivers/serial/serial_msm_geni.c
index bb5a2cb4d2cd..c37255f57d05 100644
--- a/drivers/serial/serial_msm_geni.c
+++ b/drivers/serial/serial_msm_geni.c
@@ -211,9 +211,9 @@ static int msm_serial_setbrg(struct udevice *dev, int baud)
 	}
 	ret = clk_set_rate(priv->se, clk_rate);
 	if (ret < 0) {
 		pr_err("%s: Couldn't set clock rate: %d\n", __func__, ret);
-		return ret;
+		return 0;
 	}
 	geni_serial_baud(priv->base, clk_div, baud);
 
 	return 0;
@@ -516,15 +516,14 @@ static int msm_serial_probe(struct udevice *dev)
 	int ret;
 	u32 proto;
 	struct clk *clk;
 
-	clk = devm_clk_get(dev, NULL);
-	if (IS_ERR(clk))
-		return PTR_ERR(clk);
-	priv->se = clk;
+	clk = devm_clk_get_optional(dev, NULL);
+	if (!IS_ERR(clk))
+		priv->se = clk;
 
 	/* Try enable clock */
-	ret = clk_enable(clk);
+	clk_enable(clk);
 
 	/* Check if firmware loading is needed (BT UART) */
 	proto = readl(priv->base + GENI_FW_REVISION_RO);
 	proto &= FW_REV_PROTOCOL_MSK;
@@ -546,12 +545,8 @@ static int msm_serial_probe(struct udevice *dev)
 	/* Don't actually probe non-debug UARTs */
 	if (ofnode_device_is_compatible(dev_ofnode(dev), "qcom,geni-uart"))
 		return -ENOENT;
 
-	/* Now handle clock enable return value */
-	if (ret)
-		return ret;
-
 	ret = geni_set_oversampling(dev);
 	if (ret < 0)
 		return ret;
 

-- 
2.51.0

