From: Alexandre Rapaille <arapaille@atlr-engineering.com>
Date: Wed, 18 Nov 2026 15:58:01 +0100
Subject: [PATCH 3/3] wifi: wcn36xx: Stop waiting on a dead firmware during
 remove
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-wcnss-series-v1-v1-3-a64d82e151bf@atlr-engineering.com>
References: <20261118-wcnss-series-v1-v1-0-a64d82e151bf@atlr-engineering.com>
In-Reply-To: <20261118-wcnss-series-v1-v1-0-a64d82e151bf@atlr-engineering.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Luca Weiss <luca@lucaweiss.eu>, Eugene Krasnikov <k.eugene.e@gmail.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, wcn36xx@lists.infradead.org, 
 linux-wireless@vger.kernel.org, 
 Alexandre Rapaille <arapaille@atlr-engineering.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795013892; l=2576;
 i=arapaille@atlr-engineering.com; s=20261118; h=from:subject:message-id;
 bh=OWtB8gLUHR0gZZyDT6Sr85NMnedCySghwg3+i2hEYMk=;
 b=40vQIVIHDiOrrWXDECYvU5u3JJRHAVNJeUedW0JPVJCgi5Xofe0K70qQvMCKg/EHM6Bza2uQk
 +hoPHbqb31UD0khKmRPYS2s9xX9yNGInY/QjftvDjjtkHMEQzsXZy8B
X-Developer-Key: i=arapaille@atlr-engineering.com; a=ed25519;
 pk=xskH/sIiNU/aZCeGeBB1TK/AuiG3MXlX0m2wMlbMl08=
X-Endpoint-Received: by B4 Relay for arapaille@atlr-engineering.com/20261118 with auth_id=1560
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After a WCNSS crash, remove sends ~16 HAL commands nobody can answer,
each waiting HAL_MSG_TIMEOUT: recovery took 160 s on msm8974. Once one
times out during remove, fail the rest at once; recovery now takes ~20 s.

Signed-off-by: Alexandre Rapaille <arapaille@atlr-engineering.com>
---
 drivers/net/wireless/ath/wcn36xx/main.c    | 1 +
 drivers/net/wireless/ath/wcn36xx/smd.c     | 8 ++++++++
 drivers/net/wireless/ath/wcn36xx/wcn36xx.h | 4 ++++
 3 files changed, 13 insertions(+)

diff --git a/drivers/net/wireless/ath/wcn36xx/main.c b/drivers/net/wireless/ath/wcn36xx/main.c
index ad8a4bd910..77a1029108 100644
--- a/drivers/net/wireless/ath/wcn36xx/main.c
+++ b/drivers/net/wireless/ath/wcn36xx/main.c
@@ -1651,6 +1651,7 @@ static void wcn36xx_remove(struct platform_device *pdev)
 
 	release_firmware(wcn->nv);
 
+	WRITE_ONCE(wcn->removing, true);
 	ieee80211_unregister_hw(hw);
 
 	qcom_smem_state_put(wcn->tx_enable_state);
diff --git a/drivers/net/wireless/ath/wcn36xx/smd.c b/drivers/net/wireless/ath/wcn36xx/smd.c
index c0b4773458..d07ea967ac 100644
--- a/drivers/net/wireless/ath/wcn36xx/smd.c
+++ b/drivers/net/wireless/ath/wcn36xx/smd.c
@@ -427,6 +427,12 @@ static int wcn36xx_smd_send_and_wait(struct wcn36xx *wcn, size_t len)
 		(struct wcn36xx_hal_msg_header *)wcn->hal_buf;
 	u16 req_type = hdr->msg_type;
 
+	/* After a WCNSS crash every teardown command would wait the full
+	 * timeout; one is enough to know nobody will answer.
+	 */
+	if (wcn->fw_dead)
+		return -ETIME;
+
 	wcn36xx_dbg_dump(WCN36XX_DBG_SMD_DUMP, "HAL >>> ", wcn->hal_buf, len);
 
 	init_completion(&wcn->hal_rsp_compl);
@@ -440,6 +446,8 @@ static int wcn36xx_smd_send_and_wait(struct wcn36xx *wcn, size_t len)
 		msecs_to_jiffies(HAL_MSG_TIMEOUT)) <= 0) {
 		wcn36xx_err("Timeout! No SMD response to req %d in %dms\n",
 			    req_type, HAL_MSG_TIMEOUT);
+		if (READ_ONCE(wcn->removing))
+			wcn->fw_dead = true;
 		ret = -ETIME;
 		goto out;
 	}
diff --git a/drivers/net/wireless/ath/wcn36xx/wcn36xx.h b/drivers/net/wireless/ath/wcn36xx/wcn36xx.h
index 8c43f67bd7..9e5f3918ca 100644
--- a/drivers/net/wireless/ath/wcn36xx/wcn36xx.h
+++ b/drivers/net/wireless/ath/wcn36xx/wcn36xx.h
@@ -276,6 +276,10 @@ struct wcn36xx {
 	spinlock_t	dxe_lock;
 	bool                    queues_stopped;
 
+	/* Set in remove; a HAL timeout then means the firmware is gone. */
+	bool			removing;
+	bool			fw_dead;
+
 	/* Memory pools */
 	struct wcn36xx_dxe_mem_pool mgmt_mem_pool;
 	struct wcn36xx_dxe_mem_pool data_mem_pool;

-- 
2.43.0

