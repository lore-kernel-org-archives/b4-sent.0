From: Amit Sunil Dhamne <amitsd@google.com>
Date: Thu, 14 Aug 2025 19:34:10 -0700
Subject: [PATCH 2/2] usb: typec: maxim_contaminant: re-enable cc toggle if
 cc is open and port is clean
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250814-fix-upstream-contaminant-v1-2-801ce8089031@google.com>
References: <20250814-fix-upstream-contaminant-v1-0-801ce8089031@google.com>
In-Reply-To: <20250814-fix-upstream-contaminant-v1-0-801ce8089031@google.com>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, RD Babiera <rdbabiera@google.com>, 
 Kyle Tso <kyletso@google.com>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755225269; l=3823;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=qAcTOGcQuyAV3AKhTOrWCDa/cZQDsDqaLED5LXbnmns=;
 b=uN5nu7i+AgvcuGYzFt9VC00M6KcrPBoShLVXmu6Xub4fDgbxH0MhWFD9dXMeteRBN3IAzdj6b
 6gQnGTBpS9RCW4HvLyQ6Uux0X+St0RstsIuhQ4ogTQR3tLAloi5UGEF
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Presently in `max_contaminant_is_contaminant()` if there's no
contaminant detected previously, CC is open & stopped toggling and no
contaminant is currently present, TCPC.RC would be programmed to do DRP
toggling. However, it didn't actively look for a connection. This would
lead to Type-C not detect *any* new connections. Hence, in the above
situation, re-enable toggling & program TCPC to look for a new
connection.

Also, return early if TCPC was looking for connection as this indicates
TCPC has neither detected a potential connection nor a change in
contaminant state.

In addition, once dry detection is complete (port is dry), restart
toggling.

Fixes: 02b332a06397e ("usb: typec: maxim_contaminant: Implement check_contaminant callback")
Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
Reviewed-by: Badhri Jagan Sridharan <badhri@google.com>
---
 drivers/usb/typec/tcpm/maxim_contaminant.c | 53 ++++++++++++++++++++++++++++++
 1 file changed, 53 insertions(+)

diff --git a/drivers/usb/typec/tcpm/maxim_contaminant.c b/drivers/usb/typec/tcpm/maxim_contaminant.c
index 818cfe226ac7716de2fcbce205c67ea16acba592..af8da6dc60ae0bc5900f6614514d51f41eded8ab 100644
--- a/drivers/usb/typec/tcpm/maxim_contaminant.c
+++ b/drivers/usb/typec/tcpm/maxim_contaminant.c
@@ -329,6 +329,39 @@ static int max_contaminant_enable_dry_detection(struct max_tcpci_chip *chip)
 	return 0;
 }
 
+static int max_contaminant_enable_toggling(struct max_tcpci_chip *chip)
+{
+	struct regmap *regmap = chip->data.regmap;
+	int ret;
+
+	/* Disable dry detection if enabled. */
+	ret = regmap_update_bits(regmap, TCPC_VENDOR_CC_CTRL2, CCLPMODESEL,
+				 FIELD_PREP(CCLPMODESEL,
+					    LOW_POWER_MODE_DISABLE));
+	if (ret)
+		return ret;
+
+	ret = regmap_update_bits(regmap, TCPC_VENDOR_CC_CTRL1, CCCONNDRY, 0);
+	if (ret)
+		return ret;
+
+	ret = max_tcpci_write8(chip, TCPC_ROLE_CTRL, TCPC_ROLE_CTRL_DRP |
+			       FIELD_PREP(TCPC_ROLE_CTRL_CC1,
+					  TCPC_ROLE_CTRL_CC_RD) |
+			       FIELD_PREP(TCPC_ROLE_CTRL_CC2,
+					  TCPC_ROLE_CTRL_CC_RD));
+	if (ret)
+		return ret;
+
+	ret = regmap_update_bits(regmap, TCPC_TCPC_CTRL,
+				 TCPC_TCPC_CTRL_EN_LK4CONN_ALRT,
+				 TCPC_TCPC_CTRL_EN_LK4CONN_ALRT);
+	if (ret)
+		return ret;
+
+	return max_tcpci_write8(chip, TCPC_COMMAND, TCPC_CMD_LOOK4CONNECTION);
+}
+
 bool max_contaminant_is_contaminant(struct max_tcpci_chip *chip, bool disconnect_while_debounce,
 				    bool *cc_handled)
 {
@@ -345,6 +378,12 @@ bool max_contaminant_is_contaminant(struct max_tcpci_chip *chip, bool disconnect
 	if (ret < 0)
 		return false;
 
+	if (cc_status & TCPC_CC_STATUS_TOGGLING) {
+		if (chip->contaminant_state == DETECTED)
+			return true;
+		return false;
+	}
+
 	if (chip->contaminant_state == NOT_DETECTED || chip->contaminant_state == SINK) {
 		if (!disconnect_while_debounce)
 			msleep(100);
@@ -377,6 +416,12 @@ bool max_contaminant_is_contaminant(struct max_tcpci_chip *chip, bool disconnect
 				max_contaminant_enable_dry_detection(chip);
 				return true;
 			}
+
+			ret = max_contaminant_enable_toggling(chip);
+			if (ret)
+				dev_err(chip->dev,
+					"Failed to enable toggling, ret=%d",
+					ret);
 		}
 	} else if (chip->contaminant_state == DETECTED) {
 		if (!(cc_status & TCPC_CC_STATUS_TOGGLING)) {
@@ -384,6 +429,14 @@ bool max_contaminant_is_contaminant(struct max_tcpci_chip *chip, bool disconnect
 			if (chip->contaminant_state == DETECTED) {
 				max_contaminant_enable_dry_detection(chip);
 				return true;
+			} else {
+				ret = max_contaminant_enable_toggling(chip);
+				if (ret) {
+					dev_err(chip->dev,
+						"Failed to enable toggling, ret=%d",
+						ret);
+					return true;
+				}
 			}
 		}
 	}

-- 
2.51.0.rc1.167.g924127e9c0-goog

