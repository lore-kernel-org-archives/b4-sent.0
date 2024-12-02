From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Mon, 02 Dec 2024 20:41:30 +0100
Subject: [PATCH v3 2/3] firmware: qcom: scm: Allow QSEECOM for HP Omnibook
 X14
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241202-hp-omnibook-x14-v3-2-0fcd96483723@oldschoolsolutions.biz>
References: <20241202-hp-omnibook-x14-v3-0-0fcd96483723@oldschoolsolutions.biz>
In-Reply-To: <20241202-hp-omnibook-x14-v3-0-0fcd96483723@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kalle Valo <kvalo@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733168490; l=867;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=5Oq4MdNKXVyJJvjmJFPu8lXVv7qb44phd5FkFC6DLHc=;
 b=DCkZgJqU7s8ayLGPhLMi/Ea2aN1ZrE17xovmsmP/VglNQN3GrW3m0b2+fdqQ4bVne8tNGa56K
 Ux+fTQJBVvBBwwnxKoYD90fyNR2Tme2ZwXxJ8zNnljHe1khKMwsgis1
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

add "hp,omnibook-x14" as compatible device for QSEECOM

This is required to get access to efivars and uefi boot loader support.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 drivers/firmware/qcom/qcom_scm.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/firmware/qcom/qcom_scm.c b/drivers/firmware/qcom/qcom_scm.c
index 72bf87ddcd969..2e148fb7167be 100644
--- a/drivers/firmware/qcom/qcom_scm.c
+++ b/drivers/firmware/qcom/qcom_scm.c
@@ -1769,6 +1769,7 @@ EXPORT_SYMBOL_GPL(qcom_scm_qseecom_app_send);
  */
 static const struct of_device_id qcom_scm_qseecom_allowlist[] __maybe_unused = {
 	{ .compatible = "dell,xps13-9345" },
+	{ .compatible = "hp,omnibook-x14" },
 	{ .compatible = "lenovo,flex-5g" },
 	{ .compatible = "lenovo,thinkpad-t14s" },
 	{ .compatible = "lenovo,thinkpad-x13s", },

-- 
2.43.0

