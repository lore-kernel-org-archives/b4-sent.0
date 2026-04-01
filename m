From: Amit Sunil Dhamne <amitsd@google.com>
Date: Wed, 01 Apr 2026 21:02:08 +0000
Subject: [PATCH] mfd: max77759: fix comment style for enums
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260401-fix-mfd-max77759-usb-next-v1-1-174ec23ad824@google.com>
X-B4-Tracking: v=1; b=H4sIAM+HzWkC/x2MywqAIBAAfyX23IL2svqV6GC51R6y0ApB+vek4
 8DMRPDkmDz0WQRHD3s+bAKZZzBv2q6EbBJDIYpGVELiwgH3xeCug1Kq7vD2E1oKF1LTKmNkOYt
 WQ+pPR0n+38P4vh9S0MymawAAAA==
X-Change-ID: 20260401-fix-mfd-max77759-usb-next-e687dd13c08a
To: =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Lee Jones <lee@kernel.org>, Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-kernel@vger.kernel.org, linux-usb@vger.kernel.org, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775077329; l=3284;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=7DZ+8ZRZWuwCTzw0kJR0me2ttfQ1oXwKqAtj79QG1jU=;
 b=VnHr0xONR1kTvZZjHhd/sHmSTg6nOJjtG0cMtUhG3f8l0yxRUnWvR+/kHXJXey0rklvh+ED/e
 EiFG1L9BdqlBSemk4B8NzdgE6dq8NC1CcOFfMePc4eQCnmAsASYPwsL
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix comment style for enums so they're kernel-doc compliant.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
This patch is a follow-up to the series [1]. [1] has been accepted in
the USB subsystem tree (usb-next). However, since Lee has additional
feedback [2], I am sending this patch to fix it. Please note that this
patch is based out of usb-next branch on usb tree. This patch should be
applied on top of b422f7c072ac ("mfd: max77759: add register bitmasks
and modify irq configs for charger").

[1] https://lore.kernel.org/all/20260325-max77759-charger-v9-0-4486dd297adc@google.com/
[2] https://lore.kernel.org/all/20260331123138.GE3795166@google.com/
---
Output of kernel-doc script (none format)
$ scripts/kernel-doc -v -none -Wall include/linux/mfd/max77759.h
Info: include/linux/mfd/max77759.h:134 Scanning doc for enum max77759_chgr_chgin_dtls_status
Info: include/linux/mfd/max77759.h:152 Scanning doc for enum max77759_chgr_bat_dtls_states
Info: include/linux/mfd/max77759.h:174 Scanning doc for enum max77759_chgr_chg_dtls_states
Info: include/linux/mfd/max77759.h:212 Scanning doc for struct max77759
Info: include/linux/mfd/max77759.h:235 Scanning doc for struct max77759_maxq_command
Info: include/linux/mfd/max77759.h:247 Scanning doc for struct max77759_maxq_response
Info: include/linux/mfd/max77759.h:258 Scanning doc for function max77759_maxq_command
---
 include/linux/mfd/max77759.h | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/include/linux/mfd/max77759.h b/include/linux/mfd/max77759.h
index ad1aa4c2b779..ec19be952877 100644
--- a/include/linux/mfd/max77759.h
+++ b/include/linux/mfd/max77759.h
@@ -131,12 +131,12 @@
 #define MAX77759_MAXQ_OPCODE_USER_SPACE_READ     0x81
 #define MAX77759_MAXQ_OPCODE_USER_SPACE_WRITE    0x82
 
-/*
+/**
  * enum max77759_chgr_chgin_dtls_status - Charger Input Status
  * @MAX77759_CHGR_CHGIN_DTLS_VBUS_UNDERVOLTAGE:
  *     Charger input voltage (Vchgin) < Under Voltage Threshold (Vuvlo)
- * @MAX77759_CHGR_CHGIN_DTLS_VBUS_MARGINAL_VOLTAGE: Vchgin > Vuvlo and
- *     Vchgin < (Battery Voltage (Vbatt) + system voltage (Vsys))
+ * @MAX77759_CHGR_CHGIN_DTLS_VBUS_MARGINAL_VOLTAGE:
+ *     Vchgin > Vuvlo and Vchgin < (Battery Voltage (Vbatt) + system voltage (Vsys))
  * @MAX77759_CHGR_CHGIN_DTLS_VBUS_OVERVOLTAGE:
  *     Vchgin > Over Voltage threshold (Vovlo)
  * @MAX77759_CHGR_CHGIN_DTLS_VBUS_VALID:
@@ -149,7 +149,7 @@ enum max77759_chgr_chgin_dtls_status {
 	MAX77759_CHGR_CHGIN_DTLS_VBUS_VALID,
 };
 
-/*
+/**
  * enum max77759_chgr_bat_dtls_states - Battery Details
  * @MAX77759_CHGR_BAT_DTLS_NO_BATT_CHG_SUSP:	No battery and the charger suspended
  * @MAX77759_CHGR_BAT_DTLS_DEAD_BATTERY:	Vbatt < Vtrickle
@@ -171,7 +171,7 @@ enum max77759_chgr_bat_dtls_states {
 	MAX77759_CHGR_BAT_DTLS_BAT_ONLY_MODE,
 };
 
-/*
+/**
  * enum max77759_chgr_chg_dtls_states - Charger Details
  * @MAX77759_CHGR_CHG_DTLS_PREQUAL:		Charger in prequalification mode
  * @MAX77759_CHGR_CHG_DTLS_CC:			Charger in fast charge const curr mode

---
base-commit: 81ebd43cc0d6d106ce7b6ccbf7b5e40ca7f5503d
change-id: 20260401-fix-mfd-max77759-usb-next-e687dd13c08a

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

