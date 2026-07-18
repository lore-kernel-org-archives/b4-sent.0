From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 18 Jul 2026 19:06:30 +0200
Subject: [PATCH 2/5] usb: typec: ps883x: Return -EOPNOTSUPP for USB4 when
 parade,disable-usb4 is set
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260718-ps883x-disable-usb4-v1-2-cec86d0b909e@oldschoolsolutions.biz>
References: <20260718-ps883x-disable-usb4-v1-0-cec86d0b909e@oldschoolsolutions.biz>
In-Reply-To: <20260718-ps883x-disable-usb4-v1-0-cec86d0b909e@oldschoolsolutions.biz>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 stable@vger.kernel.org, "Dr. David Alan Gilbert" <dave@treblig.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784394390; l=2343;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=DJntb/TyC1gmbUdn71tBrUvPiFUv1X0w0aqISPM2PhU=;
 b=CAXvuO4hivIPZPM+OxEeKl1vaYFBvOFTqlCECok9dJRZt5EDOYOVhOwC3WdOYKQmSFHOi91+9
 OuVaiSVy+NeA7TucTUKKHSBns+XXfKouIZoItJxRqiLL8rcGT8nyBP2
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Qualcomm X1E80100 platforms using the Parade PS883x retimer (like
Lenovo ThinkPad T14s Gen6), hotplugging USB4-capable docks such as the
Lenovo 40B0 results in working USB but no DisplayPort output on the
dock's HDMI/DP ports.

When the dock negotiates USB4, the retimer receives TYPEC_MODE_USB4
and forwards it via typec_mux_set(). The qmp_combo PHY then selects
QMPPHY_MODE_USB3_ONLY because no classic DP altmode SVID is present in
the state, leaving the DP transmitter and AUX channel disabled.

Add a DT property "parade,disable-usb4" that, when present, makes the
PS883x driver reject USB4 modes as not supported. DP altmode
configuration is still applied if negotiated, so both USB and
DisplayPort continue to work.

This is a temporary workaround until proper USB4 DP tunneling support
is available in the X1E USB4 controller and qmp_combo PHY stack.

Link: https://patch.msgid.link/20260312101431.2375709-1-krishna.kurapati@oss.qualcomm.com
Assisted-by: Grok(xAI):4.3
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 drivers/usb/typec/mux/ps883x.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/usb/typec/mux/ps883x.c b/drivers/usb/typec/mux/ps883x.c
index 64e0a61b776a1..3fa26ce01a9c9 100644
--- a/drivers/usb/typec/mux/ps883x.c
+++ b/drivers/usb/typec/mux/ps883x.c
@@ -62,6 +62,7 @@ struct ps883x_retimer {
 
 	enum typec_orientation orientation;
 	bool in_reset;
+	bool disable_usb4;
 };
 
 static int ps883x_enable_vregs(struct ps883x_retimer *retimer)
@@ -249,6 +250,13 @@ static int ps883x_set(struct ps883x_retimer *retimer, struct typec_retimer_state
 			cfg0 |= CONN_STATUS_0_USB_3_1_CONNECTED;
 			break;
 		case TYPEC_MODE_USB4:
+			if (retimer->disable_usb4) {
+				dev_info(&retimer->client->dev,
+					 "USB4 disabled via DT property, rejecting USB4 mode\n");
+				return -EOPNOTSUPP;
+			}
+
+			/* Normal USB4 handling */
 			eudo_data = state->data;
 
 			cfg2 |= CONN_STATUS_2_USB4_CONNECTED;
@@ -378,6 +386,8 @@ static int ps883x_retimer_probe(struct i2c_client *client)
 
 	retimer->client = client;
 
+	retimer->disable_usb4 = device_property_read_bool(dev, "parade,disable-usb4");
+
 	mutex_init(&retimer->lock);
 
 	retimer->regmap = devm_regmap_init_i2c(client, &ps883x_retimer_regmap);

-- 
2.53.0

