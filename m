From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: heikki.krogerus@linux.intel.com, gregkh@linuxfoundation.org, 
 linux@roeck-us.net
Cc: badhri@google.com, shufan_lee@richtek.com, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH] usb: typec: tcpci_rt1711h: restart DRP toggling on Ra/Open
 in TOGGLING
Date: Thu, 26 Nov 2026 00:33:08 +0000
Message-Id: <20261126003308.48940-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795653188; l=4594;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=48DbZvenyoxSQC7pGCnI1KXfaG2DTeuuUgLBgoGs71c=;
 b=bcWv86hvlPh2cPfbmwLklE4wWfQw8FOHZukHKNnU9UmWJEOatPVmFd8r0xg4QVYGO8RgFJ+Xb
 f5OGUCXC3mCB3WGro977IpNVHl/xZv5E900SX0pQeIysIS0c/SgbgYs
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a DRP port using RT1711H/RT1715 or its ETEK ET7303/ET7304
compatible silicon is connected via an e-marked USB-C cable (for example
to a USB-C PD charger whose own port is temporarily open), the hardware
can stop DRP toggling during its Rp phase upon detecting a single Ra
pull-down, reporting CC_STATUS with LOOKING4CONNECTION=0,
CONNECTRESULT=0 (Rp), and (CC1=Ra, CC2=Open).

In tcpm_cc_change(), case TOGGLING only transitions out of TOGGLING for
source (Rd), sink (Rp), audio accessory (Ra+Ra), and debug accessory
states. (Ra, Open), (Open, Ra), and (Open, Open) fall through with no
state change and no call to tcpm_start_toggling(). Because the TCPC has
already exited hardware toggling, the port remains permanently wedged
presenting Rp: PD chargers never see Rd and never source VBUS, and
subsequent USB host connections fail to enumerate until another
TCPC_CMD_LOOK4CONNECTION command is issued. (fusb302 handles the same
condition by restarting toggling on unexpected CC states.)

In rt1711h_irq(), when TCPC_ALERT_CC_STATUS fires with
TCPC_CC_STATUS_TOGGLING clear while tcpm_port_is_toggling() is true and
TCPC_ROLE_CTRL_DRP is set, decode (cc1, cc2) identically to
tcpci_get_cc(). If the state is (Open, Open), (Ra, Open), or (Open, Ra),
clear TCPC_ALERT_CC_STATUS, preserve RP_VAL while resetting CC1/CC2 to
Rd with the RT1711H DRP=0 settle delay matching
rt1711h_start_drp_toggling(), re-enable DRP, and issue
TCPC_CMD_LOOK4CONNECTION. Return IRQ_HANDLED so any co-occurring alert
bits remain pending on the level-low IRQ line and re-enter cleanly.

Observed and verified on hardware (MT6789 phone with ETEK ET7303
VID 0x6DCF PID 0x1711 DID 0x2173 and Anker/Apple USB-C PD chargers with
e-marked C-to-C cables) as well as a 1542-case host state-machine test
covering all 64 CC states, RP_VAL preservation, co-occurring alerts, and
I2C error fallbacks.

Drafted with an AI coding assistant.

Fixes: ce08eaeb6388 ("staging: typec: rt1711h typec chip driver")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 drivers/usb/typec/tcpm/tcpci_rt1711h.c | 47 ++++++++++++++++++++++++++
 1 file changed, 47 insertions(+)

diff --git a/drivers/usb/typec/tcpm/tcpci_rt1711h.c b/drivers/usb/typec/tcpm/tcpci_rt1711h.c
index 0581659..e03eca7 100644
--- a/drivers/usb/typec/tcpm/tcpci_rt1711h.c
+++ b/drivers/usb/typec/tcpm/tcpci_rt1711h.c
@@ -253,6 +253,51 @@ static int rt1711h_start_drp_toggling(struct tcpci *tcpci,
 	return 0;
 }
 
+static bool rt1711h_cc_needs_retoggle(enum typec_cc_status cc1,
+				      enum typec_cc_status cc2)
+{
+	return (cc1 == TYPEC_CC_OPEN && cc2 == TYPEC_CC_OPEN) ||
+	       (cc1 == TYPEC_CC_RA && cc2 == TYPEC_CC_OPEN) ||
+	       (cc1 == TYPEC_CC_OPEN && cc2 == TYPEC_CC_RA);
+}
+
+static bool rt1711h_restart_toggling(struct rt1711h_chip *chip, u8 status)
+{
+	struct tcpm_port *port = tcpci_get_tcpm_port(chip->tcpci);
+	enum typec_cc_status cc1, cc2;
+	unsigned int base;
+	u8 role = 0;
+	int ret;
+
+	if (!tcpm_port_is_toggling(port))
+		return false;
+	ret = rt1711h_read8(chip, TCPC_ROLE_CTRL, &role);
+	if (ret < 0 || !(role & TCPC_ROLE_CTRL_DRP))
+		return false;
+	cc1 = tcpci_to_typec_cc(FIELD_GET(TCPC_CC_STATUS_CC1, status),
+				status & TCPC_CC_STATUS_TERM ||
+				tcpc_presenting_rd(role, CC1));
+	cc2 = tcpci_to_typec_cc(FIELD_GET(TCPC_CC_STATUS_CC2, status),
+				status & TCPC_CC_STATUS_TERM ||
+				tcpc_presenting_rd(role, CC2));
+	if (!rt1711h_cc_needs_retoggle(cc1, cc2))
+		return false;
+	base = (role & TCPC_ROLE_CTRL_RP_VAL) |
+	       FIELD_PREP(TCPC_ROLE_CTRL_CC1, TCPC_ROLE_CTRL_CC_RD) |
+	       FIELD_PREP(TCPC_ROLE_CTRL_CC2, TCPC_ROLE_CTRL_CC_RD);
+	ret = rt1711h_write8(chip, TCPC_ALERT, TCPC_ALERT_CC_STATUS);
+	if (ret < 0)
+		return false;
+	ret = rt1711h_write8(chip, TCPC_ROLE_CTRL, base);
+	if (ret < 0)
+		return false;
+	usleep_range(500, 1000);
+	ret = rt1711h_write8(chip, TCPC_ROLE_CTRL, base | TCPC_ROLE_CTRL_DRP);
+	if (ret < 0)
+		return false;
+	return rt1711h_write8(chip, TCPC_COMMAND, TCPC_CMD_LOOK4CONNECTION) == 0;
+}
+
 static irqreturn_t rt1711h_irq(int irq, void *dev_id)
 {
 	int ret;
@@ -274,6 +319,8 @@ static irqreturn_t rt1711h_irq(int irq, void *dev_id)
 		/* Clear cc change event triggered by starting toggling */
 		if (status & TCPC_CC_STATUS_TOGGLING)
 			rt1711h_write8(chip, TCPC_ALERT, TCPC_ALERT_CC_STATUS);
+		else if (rt1711h_restart_toggling(chip, status))
+			return IRQ_HANDLED;
 		else
 			rt1711h_init_cc_params(chip, status);
 	}
-- 
2.54.0 (Apple Git-157)


