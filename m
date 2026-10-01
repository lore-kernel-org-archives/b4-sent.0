From: Amit Sunil Dhamne <amitsd@google.com>
Date: Thu, 01 Oct 2026 22:51:13 +0000
Subject: [PATCH 1/3] usb: typec: tcpm: only call get_current_limit() for
 cc=Rp-def
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-max77759-icl-typec-v1-1-99ada1f65ced@google.com>
References: <20261001-max77759-icl-typec-v1-0-99ada1f65ced@google.com>
In-Reply-To: <20261001-max77759-icl-typec-v1-0-99ada1f65ced@google.com>
To: Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 RD Babiera <rdbabiera@google.com>, Kyle Tso <kyletso@google.com>, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790895080; l=1684;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=McNPTpZKO0TXWj67OGyGFn9ea4C0Lct3fPYqxSH5xyw=;
 b=4MsviocYxjRD1uhjleG6KxeIzsXmnqA8/HtnVK0BMhQa4UP4kF2EK6ZW1DFVTuQikbieqDP2y
 lHVyqfVTirqBCE7PPxGqej9biOF6qqqGxGvLrDm49zELeZ1KhKpdLOd
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tcpm_get_current_limit() folds the default label into the
TYPEC_CC_RP_DEF case, so tcpc_dev::get_current_limit() is also called
for CC states that do not advertise Rp, such as TYPEC_CC_OPEN,
TYPEC_CC_RA and TYPEC_CC_RD. Its kerneldoc has always scoped it to
cc=Rp-def:

  @get_current_limit:
          Optional; called by the tcpm core when configured as a snk
          and cc=Rp-def. This allows the tcpm to provide a fallback
          current-limit detection method for the cc=Rp-def case.

A chip driver has nothing to interpret in the other states. Therefore,
split the cases and report 0 when CC is not an Rp.

Assisted-by: LLM
Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
Reviewed-by: Badhri Jagan Sridharan <badhri@google.com>
---
 drivers/usb/typec/tcpm/tcpm.c | 7 +++----
 1 file changed, 3 insertions(+), 4 deletions(-)

diff --git a/drivers/usb/typec/tcpm/tcpm.c b/drivers/usb/typec/tcpm/tcpm.c
index 2d6b14aa20856..2e7371ada8642 100644
--- a/drivers/usb/typec/tcpm/tcpm.c
+++ b/drivers/usb/typec/tcpm/tcpm.c
@@ -1268,7 +1268,7 @@ static int tcpm_set_vconn(struct tcpm_port *port, bool enable)
 static u32 tcpm_get_current_limit(struct tcpm_port *port)
 {
 	enum typec_cc_status cc;
-	u32 limit;
+	u32 limit = 0;
 
 	cc = port->polarity ? port->cc2 : port->cc1;
 	switch (cc) {
@@ -1279,11 +1279,10 @@ static u32 tcpm_get_current_limit(struct tcpm_port *port)
 		limit = 3000;
 		break;
 	case TYPEC_CC_RP_DEF:
-	default:
 		if (port->tcpc->get_current_limit)
 			limit = port->tcpc->get_current_limit(port->tcpc);
-		else
-			limit = 0;
+		break;
+	default:
 		break;
 	}
 

-- 
2.56.0.rc1.315.gc6ed9934b7-goog

