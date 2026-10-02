From: Petr Hodina <petr.hodina@protonmail.com>
Date: Fri, 02 Oct 2026 23:36:12 +0200
Subject: [PATCH] spmi: msm: bound the CMD_DONE poll with a timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-b4-qcom-spmi-v1-1-33fbd16ee559@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqEMAxA4atI1hOotQrOVYZZ1Bg1gn/NjAji3
 a26/Bbv7aAchBXeyQ6BV1GZxoj0lQB1fmwZpY4Ga2yRGmOxcrjQNKDOg6DPyDnyeV3mFmIyB25
 ku3ef72P9Vz3T73rAcZzNJIjNcAAAAA==
X-Change-ID: 20261002-b4-qcom-spmi-a3c44ca5d952
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.u-boot-project.org
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 David Heidelberg <david@ixit.cz>, 
 Mateusz Kulikowski <mateusz.kulikowski@gmail.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, Peng Fan <peng.fan@nxp.com>, 
 Yao Zi <me@ziyao.cc>, Patrice Chotard <patrice.chotard@foss.st.com>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790976984; l=2461;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=XhcZAlmJfd1XOgfLGQ5RB4F4aui0FVa7ft96ZW0ZEi0=;
 b=o/JC8t6vYtNO64vaEK3kT7VtVYTm8RR3MYxug3HIW1NgdYlQEWxgdKCa9o4pOpGWlPltvCnXb
 WKbq4Gv0l4rCoqeUhxa52+5ggRgzlSrSV8Zn69yCc4cR5gAEMh/TeXy
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

msm_spmi_write()/msm_spmi_read() busy-wait in inifinte loop.
Bound the wait with readl_poll_timeout() and return -ETIMEDOUT on
failure when the PMIC peripheral does not respond.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Tested on Xiaomi Pad 5 (nabu) hardware: pm8150l's WLED node
on usid 5 never returns CMD_DONE.

msm_spmi_write()/msm_spmi_read() busy-wait on CMD_DONE with no
timeout. Therefore one unresponsive PMIC peripheral hangs boot
indefinitely.

Bound the wait with readl_poll_timeout() so DM can fail that one
device's probe instead of halting the whole boot.
---
 drivers/spmi/spmi-msm.c | 18 +++++++++++-------
 1 file changed, 11 insertions(+), 7 deletions(-)

diff --git a/drivers/spmi/spmi-msm.c b/drivers/spmi/spmi-msm.c
index b89dd0b406b..92cd42d8627 100644
--- a/drivers/spmi/spmi-msm.c
+++ b/drivers/spmi/spmi-msm.c
@@ -12,8 +12,11 @@
 #include <fdtdec.h>
 #include <asm/io.h>
 #include <dm/device_compat.h>
+#include <linux/iopoll.h>
 #include <spmi/spmi.h>
 
+#define SPMI_CMD_DONE_TIMEOUT_US 100000
+
 /* PMIC Arbiter configuration registers */
 #define PMIC_ARB_VERSION 0x0000
 #define PMIC_ARB_VERSION_V2_MIN 0x20010000
@@ -161,10 +164,10 @@ static int msm_spmi_write(struct udevice *dev, int usid, int pid, int off,
 	writel(reg, priv->spmi_chnls + ch_offset + SPMI_REG_CMD0);
 
 	/* Wait till CMD DONE status */
-	reg = 0;
-	while (!reg) {
-		reg = readl(priv->spmi_chnls + ch_offset +
-			    SPMI_REG_STATUS);
+	if (readl_poll_timeout(priv->spmi_chnls + ch_offset + SPMI_REG_STATUS,
+			       reg, reg, SPMI_CMD_DONE_TIMEOUT_US)) {
+		printf("SPMI write timeout (channel %#x).\n", ch_offset);
+		return -ETIMEDOUT;
 	}
 
 	if (reg ^ SPMI_STATUS_DONE) {
@@ -231,9 +234,10 @@ static int msm_spmi_read(struct udevice *dev, int usid, int pid, int off)
 	writel(reg, priv->spmi_obs + ch_offset + SPMI_REG_CMD0);
 
 	/* Wait till CMD DONE status */
-	reg = 0;
-	while (!reg) {
-		reg = readl(priv->spmi_obs + ch_offset + SPMI_REG_STATUS);
+	if (readl_poll_timeout(priv->spmi_obs + ch_offset + SPMI_REG_STATUS,
+			       reg, reg, SPMI_CMD_DONE_TIMEOUT_US)) {
+		printf("SPMI read timeout (channel %#x).\n", ch_offset);
+		return -ETIMEDOUT;
 	}
 
 	if (reg ^ SPMI_STATUS_DONE) {

---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20261002-b4-qcom-spmi-a3c44ca5d952

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

