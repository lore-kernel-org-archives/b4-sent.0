From: Ivan Verbovoy <ivanverbovoy@gmail.com>
Date: Mon, 09 Nov 2026 06:21:11 +0200
Subject: [PATCH] soundwire: qcom: enable CPU interrupts only for MMIO
 controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-swrm-mmio-irq-v1-1-570fc05f22d7@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwNL3eLyolzd3NzMfN3MokLdFAtLM3ML40RTk5REJaCegqLUtMwKsHn
 RsRB+cWlSVmpyCcgQpdpaADAqLv5xAAAA
X-Change-ID: 20261109-swrm-mmio-irq-d896783a54da
To: Srinivas Kandagatla <srini@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Bard Liao <yung-chuan.liao@linux.intel.com>, 
 Pierre-Louis Bossart <pierre-louis.bossart@linux.dev>, 
 Mohammad Rafi Shaik <mohammad.rafi.shaik@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ivan Verbovoy <ivanverbovoy@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794198071; l=1798;
 i=ivanverbovoy@gmail.com; s=20261103; h=from:subject:message-id;
 bh=QD1XMeeWI7Z+Najg0/8tSfdJNHSFsUN6oXfbw01Un7k=;
 b=dyI7A28T5z0Pxt+gEo/x6FzCwS21fQFt9sHAz0v7PjOVIHBrMtGeSaaxFP6JY1DD21QwNFVtf
 vZPEuFileqTCciP7rRaDs7T/qXhpT/vH1DtEUbqskwok039s09bRimJ
X-Developer-Key: i=ivanverbovoy@gmail.com; a=ed25519;
 pk=0AchqTH1hJFToIUeFfQRlVzzuaWQDs4e75SxT2y3s8c=
X-Endpoint-Received: by B4 Relay for ivanverbovoy@gmail.com/20261103 with auth_id=1396
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit b27be5a85ed3 ("soundwire: qcom: add EE-aware register layout for
Shikra") dropped the ctrl->mmio check around the CPU interrupt enable in
qcom_swrm_init(), which its message does not mention. The enable has
been written for MMIO controllers only since they were added in
commit 82f5c70c2651 ("soundwire: qcom: add support for mmio soundwire
master devices"); a controller inside a codec, reached over SLIMbus, was
left alone.

On a Surface Duo (SM8150, a WCD9340 with one WSA8815 on its SoundWire)
the amplifier no longer enumerates since: "SWR bus clsh detected" at
boot, "link failed to connect" at each resume, and every stream fails
with -110. With the check back it enumerates and plays again. Shikra's
controller is MMIO and keeps the enable.

Fixes: b27be5a85ed3 ("soundwire: qcom: add EE-aware register layout for Shikra")
Signed-off-by: Ivan Verbovoy <ivanverbovoy@gmail.com>
---
 drivers/soundwire/qcom.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/soundwire/qcom.c b/drivers/soundwire/qcom.c
index 147e55b7a600..99c1b6398894 100644
--- a/drivers/soundwire/qcom.c
+++ b/drivers/soundwire/qcom.c
@@ -995,8 +995,9 @@ static int qcom_swrm_init(struct qcom_swrm_ctrl *ctrl)
 			0xFFFFFFFF);
 
 	/* enable CPU IRQs for the selected EE window */
-	ctrl->reg_write(ctrl, ctrl->reg_layout[SWRM_REG_INTERRUPT_CPU_EN],
-			SWRM_INTERRUPT_STATUS_RMSK);
+	if (ctrl->mmio)
+		ctrl->reg_write(ctrl, ctrl->reg_layout[SWRM_REG_INTERRUPT_CPU_EN],
+				SWRM_INTERRUPT_STATUS_RMSK);
 
 	/* Set IRQ to PULSE */
 	ctrl->reg_write(ctrl, SWRM_COMP_CFG_ADDR,

---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261109-swrm-mmio-irq-d896783a54da

Best regards,
--  
Ivan Verbovoy <ivanverbovoy@gmail.com>

