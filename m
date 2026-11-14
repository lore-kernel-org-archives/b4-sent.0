From: Haipeng Lin <jimmie.lin@gmail.com>
Date: Sat, 14 Nov 2026 01:18:41 -0500
Subject: [PATCH] pinctrl: qcom: sc8180x: Add missing dual edge GPIO IRQ
 errata flag
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-up-sc8180x-pinctrl-dual-edge-v1-1-aaa31ad633f3@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MSwqFMAxA0a1IxgYaFX9bkTeobaoBqaV9iiDu3
 eLwwOXekDgKJxiLGyKfkmT3GVQWYFbtF0ax2VCpqiWiBo+AyfTUqwuDePOPG9pDb8g2t66tzdA
 1Sru5g7wIkZ1c3376Pc8LfyINYG4AAAA=
X-Change-ID: 20261114-up-sc8180x-pinctrl-dual-edge-f63c9740afb7
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, Linus Walleij <linusw@kernel.org>
Cc: Val Packett <val@packett.cool>, linux-arm-msm@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Haipeng Lin <jimmie.lin@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794637126; l=2055;
 i=jimmie.lin@gmail.com; s=20261011; h=from:subject:message-id;
 bh=ERbdkmUDz2DUlOGI3v6R0Snrh7A43j5SXlTHI6jcLqI=;
 b=gKBO3Onq4yWQLKggkZ4qhWRLO385s+dlM+JyVH921I5mfSqSsUQKN2Acus9mH9YvqKQWQZN4S
 lLKzjGm2zgfCsDwuiqJRwY3j4yLGk7FDn8mhdiAv2Hr9Oa4jskvFxOa
X-Developer-Key: i=jimmie.lin@gmail.com; a=ed25519;
 pk=3KDRF1RQ/9A7ZUVTdRVEZnVrGltdmq1bRocsOYeXezI=
X-Endpoint-Received: by B4 Relay for jimmie.lin@gmail.com/20261011 with auth_id=1164
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Wakeup-capable GPIOs on SC8180X use the PDC as their parent interrupt
chip. Like the SM8150, the PDC on SC8180X does not support dual-edge
interrupts, so dual-edge GPIO interrupts only fire on a single edge
unless emulated by the TLMM driver via wakeirq_dual_edge_errata.

On SC8180X boards with a gpio-keys lid switch (e.g., Lenovo Flex 5G,
Surface Pro X) this causes the falling edge (lid close) to stop trig-
gering interrupts after the first suspend/resume cycle, preventing the
system from suspending again when the lid is closed.

Enables wakeirq_dual_edge_errata for SC8180X. Feature tested on a
v7.3.3 tree for the Surface Pro X with this patch applied, the lid
switch on TLMM GPIO 121 (PDC pin 89) now works after the first resume.
Without this patch opening the lid raised an interrupt but not on
close.

Fixes: 97423113ec4b ("pinctrl: qcom: Add sc8180x TLMM driver")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Haipeng Lin <jimmie.lin@gmail.com>
---
Hi, 

This fixes a lid-switch issue in SC8180X identified when trying to get
the Surface Pro X to sleep/resume when closing/opening the type cover.
It should apply cleanly to both fixes or devel but I based it off 
pinctrl/devel to send out the patch.

Thanks,
---
 drivers/pinctrl/qcom/pinctrl-sc8180x.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/pinctrl/qcom/pinctrl-sc8180x.c b/drivers/pinctrl/qcom/pinctrl-sc8180x.c
index 062cb913e5ee..fef21b2db57c 100644
--- a/drivers/pinctrl/qcom/pinctrl-sc8180x.c
+++ b/drivers/pinctrl/qcom/pinctrl-sc8180x.c
@@ -1597,6 +1597,7 @@ static struct msm_pinctrl_soc_data sc8180x_pinctrl = {
 	.ngpios = 191,
 	.wakeirq_map = sc8180x_pdc_map,
 	.nwakeirq_map = ARRAY_SIZE(sc8180x_pdc_map),
+	.wakeirq_dual_edge_errata = true,
 };
 
 static const struct msm_pinctrl_soc_data sc8180x_acpi_pinctrl = {

---
base-commit: 135fd91896455cd1b611a8ef99c35df8ba9c17df
change-id: 20261114-up-sc8180x-pinctrl-dual-edge-f63c9740afb7

Best regards,
-- 
Haipeng Lin <jimmie.lin@gmail.com>

