From: Federico Amedeo Izzo <federico@izzo.pro>
Date: Thu, 09 Jul 2026 19:00:10 +0200
Subject: [PATCH] slimbus: qcom-ngd-ctrl: fix ngd register base address
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260709-qcom-ngd-register-base-fix-v1-1-5f7ab48f9209@izzo.pro>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBA0auQWTtJiyjgVYyLtox1TCwyg4SEc
 HcqLN9f/AWUhEnhViwgNLFynzLsqYDwcikScpcNpSmvpjYtDqH/YIodCkXWkQS9U8Inz+gubW3
 PzjaVbyAPvkI57/P747D+/JvC+D/Cum5SVOQHfgAAAA==
X-Change-ID: 20260709-qcom-ngd-register-base-fix-a59713a184b8
To: Srinivas Kandagatla <srini@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 Federico Amedeo Izzo <federico@izzo.pro>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783616414; l=1498;
 i=federico@izzo.pro; s=20251017; h=from:subject:message-id;
 bh=YJ5NoHF16uL+S0+ruF7CdiW1W1Lj7X20ZzLrfsWs2uc=;
 b=6GKaN8cIpOR7P8+3A1ZUNjECNDVngPPRIiPIxLZutcAZeSce1HTeKWXEVgcnXYLH/hxn4qBbg
 QcvpdMOTAjfA5cvKg83OeN5nGnFp480VGzyArEMjuTzRhtT5iQzGZbf
X-Developer-Key: i=federico@izzo.pro; a=ed25519;
 pk=XfmNfpH48k8jLbId5NKrp0yoKoFb/uLjr97qIxBImBw=
X-Endpoint-Received: by B4 Relay for federico@izzo.pro/20251017 with auth_id=544
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The slimbus controller register base was calculated using the
controller ID and the register size, producing wrong results for ID > 1.

The expression reduces to ngd->base = ctrl->base for controller with ID = 1;
but for ID > 1 the other factors produce a wrong base address.
This bug caused a crash while trying to bring-up the secondary
slimbus controller (ID = 3) on oneplus-enchilada with sdm845.

In practice, the correct base address for each slimbus controller can be
obtained from the device-tree, so there is no need for further
calculations.

This was validated by reading the version register from the WCN3990 slim
interface on oneplus-enchilada.

---
Signed-off-by: Federico Amedeo Izzo <federico@izzo.pro>
---
 drivers/slimbus/qcom-ngd-ctrl.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/slimbus/qcom-ngd-ctrl.c b/drivers/slimbus/qcom-ngd-ctrl.c
index 80877e951849..91932f8d021b 100644
--- a/drivers/slimbus/qcom-ngd-ctrl.c
+++ b/drivers/slimbus/qcom-ngd-ctrl.c
@@ -1547,8 +1547,7 @@ static int of_qcom_slim_ngd_register(struct device *parent,
 			kfree(ngd);
 			return ret;
 		}
-		ngd->base = ctrl->base + ngd->id * data->offset +
-					(ngd->id - 1) * data->size;
+		ngd->base = ctrl->base + data->offset;
 
 		return 0;
 	}

---
base-commit: b9810cd75b9fb56a3425d391cba3f608502bd474
change-id: 20260709-qcom-ngd-register-base-fix-a59713a184b8

Best regards,
--  
Federico Amedeo Izzo <federico@izzo.pro>

