From: Demeter Barna <me@fromdisposition.org>
Date: Sat, 14 Nov 2026 02:22:03 +0000
Subject: [PATCH 9/9] qcom_defconfig: Enable SM8350 GCC and interconnect
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-sm8350-support-v1-9-414271f59474@fromdisposition.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794622936; l=860;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=1xJioPfDBoVjOo+gcIP/g2da+DPcc7vuXJsdfTi88Zs=;
 b=bNOfpup4+eDshhwm/3sGx7N2+Fk/5w1TTs2syMKddFuI9ADc6cjjpOX+o2IcmzZqMcw5V5R3D
 r1tQhRrRjeLCVBJVLxwZlzANjVXFoRt43g/zrP9urwv/VYmJPzKrna2
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the GCC and interconnect drivers for SM8350 in qcom_defconfig.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 configs/qcom_defconfig | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/configs/qcom_defconfig b/configs/qcom_defconfig
index e5291750aa..7eadfd9454 100644
--- a/configs/qcom_defconfig
+++ b/configs/qcom_defconfig
@@ -69,6 +69,7 @@ CONFIG_CLK_QCOM_SM6350=y
 CONFIG_CLK_QCOM_SM7150=y
 CONFIG_CLK_QCOM_SM8150=y
 CONFIG_CLK_QCOM_SM8250=y
+CONFIG_CLK_QCOM_SM8350=y
 CONFIG_CLK_QCOM_SM8550=y
 CONFIG_CLK_QCOM_SM8650=y
 CONFIG_CLK_QCOM_SC7180=y
@@ -93,6 +94,7 @@ CONFIG_BUTTON_KEYBOARD=y
 CONFIG_INTERCONNECT=y
 CONFIG_INTERCONNECT_QCOM_RPMH=y
 CONFIG_INTERCONNECT_QCOM_SC7280=y
+CONFIG_INTERCONNECT_QCOM_SM8350=y
 CONFIG_INTERCONNECT_QCOM_SM8650=y
 CONFIG_IOMMU=y
 CONFIG_QCOM_HYP_SMMU=y

-- 
2.53.0

