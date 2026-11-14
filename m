From: Demeter Barna <me@fromdisposition.org>
Date: Sat, 14 Nov 2026 02:21:58 +0000
Subject: [PATCH 4/9] clk: qcom: sm8350: enable shared RPMH clock driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-sm8350-support-v1-4-414271f59474@fromdisposition.org>
References: <20261114-sm8350-support-v1-0-414271f59474@fromdisposition.org>
In-Reply-To: <20261114-sm8350-support-v1-0-414271f59474@fromdisposition.org>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot@lists.u-boot-project.org, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, Lukasz Majewski <lukma@nabladev.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Biswapriyo Nath <nathbappai@gmail.com>, 
 Vitalii Skorkin <nikroks@mainlining.org>, 
 Erikas Bitovtas <xerikasxx@gmail.com>, Johan Jonker <jbx6244@gmail.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Peng Fan <peng.fan@nxp.com>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Michael Srba <Michael.Srba@seznam.cz>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Demeter Barna <me@fromdisposition.org>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794622936; l=1465;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=j7bDsytLsG45Z1AQET6GAc/Xk0WNVLXBc1WOuCBRuNc=;
 b=EOKX1irs+kWy6w7hroMigxdti+FhiV0l/N96p//f9e2FyQBH23IR4ehhPqw9g4LMtixYQoUcA
 K+thMSSmGQcBmthDeiGWQglZcTduRacb+mCLB+hYrhTYZSpWV4qmKhs
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8350's RPMH_CXO_CLK is bi_tcxo_div2 as well. Register the
"qcom,sm8350-rpmh-clk" compatible in the shared driver and have
CLK_QCOM_SM8350 select CLK_QCOM_RPMH.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 drivers/clk/qcom/Kconfig      | 1 +
 drivers/clk/qcom/clock-rpmh.c | 1 +
 2 files changed, 2 insertions(+)

diff --git a/drivers/clk/qcom/Kconfig b/drivers/clk/qcom/Kconfig
index e18d7c1c58..ba27d4ba63 100644
--- a/drivers/clk/qcom/Kconfig
+++ b/drivers/clk/qcom/Kconfig
@@ -163,6 +163,7 @@ config CLK_QCOM_SM8250
 config CLK_QCOM_SM8350
 	bool "Qualcomm SM8350 GCC"
 	select CLK_QCOM
+	select CLK_QCOM_RPMH
 	help
 	  Say Y here to enable support for the Global Clock Controller
 	  on the Snapdragon SM8350 SoC. This driver supports the clocks
diff --git a/drivers/clk/qcom/clock-rpmh.c b/drivers/clk/qcom/clock-rpmh.c
index 5d01b482fc..0154ad930d 100644
--- a/drivers/clk/qcom/clock-rpmh.c
+++ b/drivers/clk/qcom/clock-rpmh.c
@@ -48,6 +48,7 @@ static struct clk_ops qcom_rpmh_clk_ops = {
 static const struct udevice_id qcom_rpmh_clk_ids[] = {
 	{ .compatible = "qcom,sa8775p-rpmh-clk", .data = TCXO_DIV2_RATE },
 	{ .compatible = "qcom,sc7280-rpmh-clk", .data = TCXO_DIV2_RATE },
+	{ .compatible = "qcom,sm8350-rpmh-clk", .data = TCXO_DIV2_RATE },
 	{ .compatible = "qcom,sm8550-rpmh-clk", .data = TCXO_DIV2_RATE },
 	{ .compatible = "qcom,sm8650-rpmh-clk", .data = TCXO_DIV2_RATE },
 	{ }

-- 
2.53.0

