From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Tue, 22 Sep 2026 14:25:29 +0200
Subject: [PATCH v5 1/3] usb: typec: mux: ps883x: support TYPEC_DP_STATE_F
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260922-ps883x-disable-usb4-v5-1-02c0414978e6@oldschoolsolutions.biz>
References: <20260922-ps883x-disable-usb4-v5-0-02c0414978e6@oldschoolsolutions.biz>
In-Reply-To: <20260922-ps883x-disable-usb4-v5-0-02c0414978e6@oldschoolsolutions.biz>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790079937; l=936;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=qrj1s2PpCKclh5EwyG0Vo1P7ZOCUq/0XCQs0f4FZ16Q=;
 b=UsUnJYK41hJDcR8atDqzP2I1B5ohBA6G4f93GKWut/HuRECF/YcpsV+wX3xdtjs/rt7kiwXUh
 hLM0BL1z4TWAnnDJ5mvYBGfUCIws8YGHSemc+CRe/rPhpthKbdcp12Y
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Several docks, including the Lenovo 40B0 and SSK SC220, still send the
legacy TYPEC_DP_STATE_F mode request (deprecated since DisplayPort Alt
Mode spec version 1.0b).

Group it with TYPEC_DP_STATE_D.

Assisted-by: Grok(xAI):4.6
Acked-by: Heikki Krogerus <heikki.krogerus@linux.intel.com>
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

