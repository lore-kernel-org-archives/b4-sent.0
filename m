From: Casey Connolly <casey.connolly@linaro.org>
Date: Fri, 20 Mar 2026 16:45:41 +0100
Subject: [PATCH 2/2] qcom: rpmh: don't error for SLEEP requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260320-casey-qcom-rpmh-serial-fixes-v1-2-b81d05832eec@linaro.org>
References: <20260320-casey-qcom-rpmh-serial-fixes-v1-0-b81d05832eec@linaro.org>
In-Reply-To: <20260320-casey-qcom-rpmh-serial-fixes-v1-0-b81d05832eec@linaro.org>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Andrew Goodbody <andrew.goodbody@linaro.org>, 
 Stephen Boyd <swboyd@chromium.org>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=openpgp-sha256; l=2047;
 i=casey.connolly@linaro.org; h=from:subject:message-id;
 bh=WjorGVF/iuEZ/FpHOQ1r5KECPmJC6p/Q/tEa6oJzdIA=;
 b=owGbwMvMwCFYaeA6f6eBkTjjabUkhsy92WvWMN8rOabybl0y42P+ZW8duiNvp1x72a0+jy1h7
 /I10jEbOkpZGAQ5GGTFFFnETyyzbFp72V5j+4ILMHNYmUCGMHBxCsBE7Bcz/E+8P7vgxLkasZWc
 H3/0fPpoPneNO8eT+DDZwDUzDk3osi5hZJjaU/R8A8ulZ5K6+6acjXScXr/l9hm1RP/s5yrLe+K
 OJXUDAA==
X-Developer-Key: i=casey.connolly@linaro.org; a=openpgp;
 fpr=83B24DA7FE145076BC38BB250CD904EB673A7C47
X-Endpoint-Received: by B4 Relay for casey.connolly@linaro.org/default with auth_id=688
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Just stub them out since the caller might also send active votes. Since
we don't suspend there's no risk of missing votes here, we never enter
the sleep state.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
---
 drivers/soc/qcom/rpmh-rsc.c | 8 ++++----
 drivers/soc/qcom/rpmh.c     | 4 ++--
 2 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/drivers/soc/qcom/rpmh-rsc.c b/drivers/soc/qcom/rpmh-rsc.c
index dce61f262292..0b821cc6f9d8 100644
--- a/drivers/soc/qcom/rpmh-rsc.c
+++ b/drivers/soc/qcom/rpmh-rsc.c
@@ -260,10 +260,10 @@ static struct tcs_group *get_tcs_for_msg(struct rsc_drv *drv,
 	 * U-Boot: since we're single threaded and running synchronously we can
 	 * just always used the first active TCS.
 	 */
 	if (msg->state != RPMH_ACTIVE_ONLY_STATE) {
-		log_err("WARN: only ACTIVE_ONLY state supported\n");
-		return ERR_PTR(-EINVAL);
+		log_debug("WARN: only ACTIVE_ONLY state supported\n");
+		return NULL;
 	}
 
 	return &drv->tcs[ACTIVE_TCS];
 }
@@ -389,10 +389,10 @@ int rpmh_rsc_send_data(struct rsc_drv *drv, const struct tcs_request *msg)
 	int tcs_id, i = 0;
 	u32 val;
 
 	tcs = get_tcs_for_msg(drv, msg);
-	if (IS_ERR(tcs))
-		return PTR_ERR(tcs);
+	if (IS_ERR_OR_NULL(tcs))
+		return 0;
 
 	/* U-Boot is single-threaded, always use the first TCS as we'll never conflict */
 	tcs_id = tcs->offset;
 	if (!read_tcs_reg(drv, drv->regs[RSC_DRV_STATUS], tcs_id)) {
diff --git a/drivers/soc/qcom/rpmh.c b/drivers/soc/qcom/rpmh.c
index 8c222324c66d..b55e23c4417d 100644
--- a/drivers/soc/qcom/rpmh.c
+++ b/drivers/soc/qcom/rpmh.c
@@ -59,10 +59,10 @@ static int __rpmh_write(const struct udevice *dev, enum rpmh_state state,
 {
 	struct rpmh_ctrlr *ctrlr = get_rpmh_ctrlr(dev);
 
 	if (state != RPMH_ACTIVE_ONLY_STATE) {
-		log_err("only ACTIVE_ONLY state supported\n");
-		return -EINVAL;
+		log_debug("WARN: Only ACTIVE_ONLY state supported\n");
+		return 0;
 	}
 
 	return rpmh_rsc_send_data(ctrlr_to_drv(ctrlr), &rpm_msg->msg);
 }

-- 
2.51.0

