From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 18 Jul 2026 19:06:31 +0200
Subject: [PATCH 3/5] usb: typec: mux: ps883x: refactor DP altmode handling
 and support TYPEC_DP_STATE_F
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260718-ps883x-disable-usb4-v1-3-cec86d0b909e@oldschoolsolutions.biz>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784394390; l=2353;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=dFU1K6ePVlFZEJrflk6Gm0o53XRE02GqhkNK5EzXxw8=;
 b=ELkTs//0vo60nxPca3TX0u3tNw4wPNwFcDRhMjHrQa28cjpRi2VZ96oRD+Gy78p2oCTdYciKI
 5J9bHHx4H+NBY9gidSa36g1TK0PqaDXXksRCkibCwgAHChLgvkxFGOw
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Several docks, including the Lenovo 40B0 and SSK SC220, still send the
legacy TYPEC_DP_STATE_F mode request (deprecated since DisplayPort Alt
Mode spec version 1.0b). Treat it as USB3 + DP altmode (same as
TYPEC_DP_STATE_D) so that DP altmode works correctly, especially on
the 40B0 in Type-C fallback mode.

Extract the state handling into ps883x_apply_dp_altmode() (modelled
after qmp-combo-phy) for consistency.

Assisted-by: Grok(xAI):4.3
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 drivers/usb/typec/mux/ps883x.c | 35 ++++++++++++++++++++---------------
 1 file changed, 20 insertions(+), 15 deletions(-)

diff --git a/drivers/usb/typec/mux/ps883x.c b/drivers/usb/typec/mux/ps883x.c
index 3fa26ce01a9c9..3533d4f363286 100644
--- a/drivers/usb/typec/mux/ps883x.c
+++ b/drivers/usb/typec/mux/ps883x.c
@@ -188,6 +188,25 @@ static int ps883x_configure(struct ps883x_retimer *retimer, int cfg0,
 	return 0;
 }
 
+static void ps883x_apply_dp_altmode(int *cfg0, int *cfg1, int dp_state)
+{
+	*cfg1 |= CONN_STATUS_1_DP_CONNECTED | CONN_STATUS_1_DP_HPD_LEVEL;
+
+	switch (dp_state) {
+	case TYPEC_DP_STATE_D:
+	case TYPEC_DP_STATE_F:
+		*cfg0 |= CONN_STATUS_0_USB_3_1_CONNECTED;
+		fallthrough;
+	case TYPEC_DP_STATE_C:
+	case TYPEC_DP_STATE_E:
+		*cfg1 |= CONN_STATUS_1_DP_SINK_REQUESTED |
+			 CONN_STATUS_1_DP_PIN_ASSIGNMENT_C_D;
+		break;
+	default:
+		break;
+	}
+}
+
 static int ps883x_set(struct ps883x_retimer *retimer, struct typec_retimer_state *state)
 {
 	struct typec_thunderbolt_data *tb_data;
@@ -203,24 +222,10 @@ static int ps883x_set(struct ps883x_retimer *retimer, struct typec_retimer_state
 	if (state->alt) {
 		switch (state->alt->svid) {
 		case USB_TYPEC_DP_SID:
-			cfg1 |= CONN_STATUS_1_DP_CONNECTED |
-				CONN_STATUS_1_DP_HPD_LEVEL;
-
-			switch (state->mode)  {
-			case TYPEC_DP_STATE_D:
-				cfg0 |= CONN_STATUS_0_USB_3_1_CONNECTED;
-				fallthrough;
-			case TYPEC_DP_STATE_C:
-				cfg1 |= CONN_STATUS_1_DP_SINK_REQUESTED |
-					CONN_STATUS_1_DP_PIN_ASSIGNMENT_C_D;
-				break;
-			default: /* MODE_E */
-				break;
-			}
+			ps883x_apply_dp_altmode(&cfg0, &cfg1, state->mode);
 			break;
 		case USB_TYPEC_TBT_SID:
 			tb_data = state->data;
-
 			/* Unconditional */
 			cfg2 |= CONN_STATUS_2_TBT_CONNECTED;
 

-- 
2.53.0

