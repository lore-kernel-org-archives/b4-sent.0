From: Federico Amedeo Izzo <federico@izzo.pro>
Date: Fri, 10 Jul 2026 12:28:29 +0200
Subject: [PATCH v2] slimbus: qcom-ngd-ctrl: fix ngd register base address
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-qcom-ngd-register-base-fix-v2-1-0bb247c954c9@izzo.pro>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NQQ6CMBBFr0Jm7Zi2glBX3sOwaGGAmkhxikQh3
 N2CF3D5fn7eWyAQOwpwSRZgmlxwvo+gDglUnelbQldHBiXUWeRC47PyD+zbGplaF0ZitCYQNu6
 NJtO5PBlZpLaAKBiY4rzLb+WPw8veqRo34/boosHzZ69Pcvv9FZokSsya3Ni0aLQS+urm2R8H9
 lCu6/oFEg/iG9UAAAA=
X-Change-ID: 20260709-qcom-ngd-register-base-fix-a59713a184b8
To: Srinivas Kandagatla <srini@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 Federico Amedeo Izzo <federico@izzo.pro>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783679309; l=1720;
 i=federico@izzo.pro; s=20251017; h=from:subject:message-id;
 bh=+vuRfWB5TZ02U83zLp1dfXk7Vc/G5WPRtcOB/wAoh3Q=;
 b=0N3znYgt/Ey7czV5f9j2HziGVCJSAu52iQ0fAv1CAhUsKaYwkodgsS9BeRdAEjMczYzt73ypn
 8rflv6Ol1gSDn8HNrKVmenFd0qUwl6WPTfCiKV20KCavAOkpo0FgCzT
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

Fixes: 917809e2280b ("slimbus: ngd: Add qcom SLIMBus NGD driver")
Signed-off-by: Federico Amedeo Izzo <federico@izzo.pro>
---
Changes in v2:
- add missing Fixes and S-o-b tags
- Link to v1: https://patch.msgid.link/20260709-qcom-ngd-register-base-fix-v1-1-5f7ab48f9209@izzo.pro
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

