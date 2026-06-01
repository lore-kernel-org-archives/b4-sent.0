From: Sam Day <me@samcday.com>
Date: Mon, 01 Jun 2026 18:12:50 +1000
Subject: [PATCH RESEND 09/16] sysreset: qcom-pshold: offset support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-qcom-armv7-v1-9-05a08d87e476@samcday.com>
References: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
In-Reply-To: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Michal Simek <michal.simek@amd.com>, 
 Angelo Dureghello <angelo@kernel-space.org>, 
 Eugen Hristev <ehristev@kernel.org>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Yao Zi <me@ziyao.cc>, Simon Glass <sjg@chromium.org>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>, 
 Tien Fong Chee <tien.fong.chee@altera.com>, Peng Fan <peng.fan@nxp.com>, 
 Alif Zakuan Yuslaimi <alif.zakuan.yuslaimi@altera.com>, 
 Anshul Dalal <anshuld@ti.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Tingting Meng <tingting.meng@altera.com>, Alice Guo <alice.guo@nxp.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 David Wronek <david.wronek@mainlining.org>, 
 Danila Tikhonov <danila@jiaxyga.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Lukasz Majewski <lukma@denx.de>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Jens Reidel <adrian@mainlining.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780301569; l=1203;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=TxwSM2ajegUQsXtmSlBraUNkwazoTxuWpd5kLnaPIW4=;
 b=PvIFJ2cP06HF8dG74yIJlHZZfnGq+ruzycAEVRimICDzK8fCsnUZ/1aSkEs/t03wllajqeXGq
 tVCPEzr/9XRBimT+snkTmCY7DaKOZhG8/kw6aGvhc0zH5WJsEhb9C76
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On older SoCs (such as MSM8960/MSM8930), PS_HOLD is exposed through
the TLMM aperture. To prepare for that use-case, this driver is updated
to accept arbitrary offsets from regbase.

Signed-off-by: Sam Day <me@samcday.com>
---
 drivers/sysreset/sysreset_qcom-pshold.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/sysreset/sysreset_qcom-pshold.c b/drivers/sysreset/sysreset_qcom-pshold.c
index 45290478536..f8be1f2f593 100644
--- a/drivers/sysreset/sysreset_qcom-pshold.c
+++ b/drivers/sysreset/sysreset_qcom-pshold.c
@@ -10,6 +10,7 @@
  */
 
 #include <dm.h>
+#include <errno.h>
 #include <sysreset.h>
 #include <asm/io.h>
 #include <linux/delay.h>
@@ -35,9 +36,15 @@ static struct sysreset_ops qcom_pshold_ops = {
 static int qcom_pshold_probe(struct udevice *dev)
 {
 	struct qcom_pshold_priv *priv = dev_get_priv(dev);
+	ulong offset = dev_get_driver_data(dev);
 
 	priv->base = dev_read_addr(dev);
-	return priv->base == FDT_ADDR_T_NONE ? -EINVAL : 0;
+	if (priv->base == FDT_ADDR_T_NONE)
+		return -EINVAL;
+
+	priv->base += offset;
+
+	return 0;
 }
 
 static const struct udevice_id qcom_pshold_ids[] = {

-- 
2.54.0

