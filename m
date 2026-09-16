From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Wed, 16 Sep 2026 21:36:32 +0200
Subject: [PATCH v3 1/3] usb: typec: mux: ps883x: support TYPEC_DP_STATE_F
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260916-ps883x-disable-usb4-v3-1-8f19386456d0@oldschoolsolutions.biz>
References: <20260916-ps883x-disable-usb4-v3-0-8f19386456d0@oldschoolsolutions.biz>
In-Reply-To: <20260916-ps883x-disable-usb4-v3-0-8f19386456d0@oldschoolsolutions.biz>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789587411; l=875;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=bPpIDIw9LIDQr0mVlf5HDy4Ak7MRxbqehghQmc4sQjc=;
 b=LHj2y6UFpyTA572+L/o2uijs3EUo/ziZR1xwCz0JVVwZk/Oij1hJUry+VHgMYX1ot941lpRCl
 UTNuQqXro43DJeq3Vt98QbQUQ3Ik58/R/whW4InCspZ5g5knYC598B9
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Several docks, including the Lenovo 40B0 and SSK SC220, still send the
legacy TYPEC_DP_STATE_F mode request (deprecated since DisplayPort Alt
Mode spec version 1.0b).

Group it with TYPEC_DP_STATE_D.

Assisted-by: Grok(xAI):4.6
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 drivers/usb/typec/mux/ps883x.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/usb/typec/mux/ps883x.c b/drivers/usb/typec/mux/ps883x.c
index 64e0a61b776a1..a5696aef054ee 100644
--- a/drivers/usb/typec/mux/ps883x.c
+++ b/drivers/usb/typec/mux/ps883x.c
@@ -207,6 +207,7 @@ static int ps883x_set(struct ps883x_retimer *retimer, struct typec_retimer_state
 
 			switch (state->mode)  {
 			case TYPEC_DP_STATE_D:
+			case TYPEC_DP_STATE_F:
 				cfg0 |= CONN_STATUS_0_USB_3_1_CONNECTED;
 				fallthrough;
 			case TYPEC_DP_STATE_C:

-- 
2.53.0

