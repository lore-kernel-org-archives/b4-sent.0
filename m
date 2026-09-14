From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Mon, 14 Sep 2026 08:05:02 +0200
Subject: [PATCH v2 2/3] usb: typec: mux: ps883x: add a delay after writing
 config regs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-ps883x-disable-usb4-v2-2-523c32b4e4d7@oldschoolsolutions.biz>
References: <20260914-ps883x-disable-usb4-v2-0-523c32b4e4d7@oldschoolsolutions.biz>
In-Reply-To: <20260914-ps883x-disable-usb4-v2-0-523c32b4e4d7@oldschoolsolutions.biz>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Abel Vesa <abelvesa@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Sebastian Reichel <sre@kernel.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, stable@vger.kernel.org, 
 "Dr. David Alan Gilbert" <dave@treblig.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789365928; l=1571;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=D8avNZp7mg36tQCbaHtlJAlu07OwE/RGBF2BKM3mSKA=;
 b=ykLpnS2xe9wbd3cF9M/OrCl8S8CJDgPNPAjC/pE47LWBVSQ2IbnFEFHljr37A5Y1aqSrqUsCk
 R7MAKqOmctTAaDkeiV0Jp+pwabScLgh/rNUIlMs7J7vjx/Ysi7GALBJ
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The connection-status registers need time to propagate through the
analog front-end (PLLs, lane training) after they are written. A 30 ms
delay after ps883x_configure() brings DisplayPort Alt Mode hotplug on
the Lenovo 40B0 to a reliable success rate.

Tested with T14s G6 and IdeaCentre Mini with the 40B0 dock on the HDMI
port with a Type-C host cable. Qualcomm firmware that programs this
retimer from an MCU uses a similar post-config delay.

Assisted-by: Grok(xAI):4.6
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 drivers/usb/typec/mux/ps883x.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/usb/typec/mux/ps883x.c b/drivers/usb/typec/mux/ps883x.c
index c185d8897e3a4..e93e958065f6f 100644
--- a/drivers/usb/typec/mux/ps883x.c
+++ b/drivers/usb/typec/mux/ps883x.c
@@ -7,6 +7,7 @@
 
 #include <drm/bridge/aux-bridge.h>
 #include <linux/clk.h>
+#include <linux/delay.h>
 #include <linux/gpio/consumer.h>
 #include <linux/i2c.h>
 #include <linux/kernel.h>
@@ -184,6 +185,15 @@ static int ps883x_configure(struct ps883x_retimer *retimer, int cfg0,
 		return ret;
 	}
 
+	/*
+	 * The retimer needs time after the connection-status registers are
+	 * written for the analog front-end (PLLs, lane training) to settle.
+	 * Without this, DisplayPort Alt Mode hotplug is unreliable on some
+	 * docks (e.g. Lenovo 40B0). Qualcomm firmware on platforms that
+	 * program this chip from an MCU uses a similar post-config delay.
+	 */
+	fsleep(30000);
+
 	return 0;
 }
 

-- 
2.53.0

