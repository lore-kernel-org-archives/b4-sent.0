From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:13:02 +0000
Subject: [PATCH] nfc: nxp-nci: i2c: Do not keep a fault taken in reset
 across power-up
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-nxp-nci-cold-fault-v1-1-fad784c73cfe@enser.io>
X-B4-Tracking: v=1; b=H4sIAN15AmsC/yXMwQ6CMBAE0F8he3bVNoSqv2I8tMtW1pBCWiAkh
 H+nxeObzMwGiaNwgle1QeRFkgwhQ10qoM6GL6O02aDvulFKa3Q1hnXEQII09C16O/cTmof3/DT
 GONtA3o6Rvazn7/vzd5rdj2kqZ6XhbGJ00QbqSlR4W8y1xkga9v0ANA+UVpkAAAA=
X-Change-ID: 20261122-b4-nxp-nci-cold-fault-78ffe9777ba6
To: David Heidelberg <david@ixit.cz>
Cc: oe-linux-nfc@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Cl=C3=A9ment_Perrochaud?= <clement.perrochaud@nxp.com>, 
 Samuel Ortiz <sameo@linux.intel.com>, EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324382; l=3002;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=mB+rrVjlXf4RV4trPETUOgk0Sb3i1GXtUlZZsMRZRbk=;
 b=yyOeSlKhkgcaNvBbh6HL4cj3paoE+S1FtJkg8tZbr3E5Bg8XymaEKA2rbuZea+1JDEKmrn000
 WSA1891ZlwWCINpxN810Luw5YQYkfUJTJEeOt+i6U65+jaN4bI72+vt
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a OnePlus 6T (PN553), the controller powers up once after boot and
never again. Each power-down logs a read error, and every later
power-up times out:

  nxp-nci_i2c 3-0028: NFC: Read failed with error -121
  nci: __nci_request: wait_for_completion_interruptible_timeout failed 0

nxp_nci_close() holds info_lock while it drops EN and sets the mode to
COLD, and the IRQ thread takes the same lock. An interrupt raised as
the controller goes into reset is therefore handled after close() has
finished, in COLD mode, where the IRQ thread treats it as -EREMOTEIO and
records it in hard_fault. set_mode() clears hard_fault only on entry to
COLD, which has already happened, so the fault survives into the next
power-up: nxp_nci_i2c_write() returns it for CORE_RESET without touching
the bus, and the request times out.

Do not count an interrupt taken while the controller is held in reset
as a fault, and clear hard_fault on every mode change, since each one
drives EN/FW and so resets the controller.

Tested on a OnePlus 6T with this change on the postmarketOS sdm845
kernel (6.18): five power-up/power-down cycles through the NFC netlink
interface all succeed, 0.03-0.04 s each, with no read errors. Without
it, every power-up after the first times out.

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Fixes: 6be88670fc59 ("NFC: nxp-nci_i2c: Add I2C support to NXP NCI driver")
Signed-off-by: EMCP333 <emcp@enser.io>
---
Also ran on v7.4-rc3 on the same phone, as this exact commit: 5 of 5
NFC_CMD_DEV_UP/DEV_DOWN cycles over netlink, 0.03-0.04 s each, no -121
(EREMOTEIO).
---
 drivers/nfc/nxp-nci/i2c.c | 15 +++++++++++----
 1 file changed, 11 insertions(+), 4 deletions(-)

diff --git a/drivers/nfc/nxp-nci/i2c.c b/drivers/nfc/nxp-nci/i2c.c
index 9eec67c109..1ff8b5a2bb 100644
--- a/drivers/nfc/nxp-nci/i2c.c
+++ b/drivers/nfc/nxp-nci/i2c.c
@@ -52,8 +52,11 @@ static int nxp_nci_i2c_set_mode(void *phy_id,
 	gpiod_set_value_cansleep(phy->gpiod_en, (mode != NXP_NCI_MODE_COLD) ? 1 : 0);
 	usleep_range(10000, 15000);
 
-	if (mode == NXP_NCI_MODE_COLD)
-		phy->hard_fault = 0;
+	/*
+	 * Each mode change drives EN/FW and resets the controller, so a fault
+	 * recorded before it no longer applies.
+	 */
+	phy->hard_fault = 0;
 
 	return 0;
 }
@@ -222,8 +225,12 @@ static irqreturn_t nxp_nci_i2c_irq_thread_fn(int irq, void *phy_id)
 		r = nxp_nci_i2c_fw_read(phy, &skb);
 		break;
 	case NXP_NCI_MODE_COLD:
-		r = -EREMOTEIO;
-		break;
+		/*
+		 * The controller is held in reset, so there is nothing to read.
+		 * The interrupt can arrive just after EN drops; it is not a bus
+		 * fault.
+		 */
+		goto exit_irq_handled;
 	}
 
 	if (r == -EREMOTEIO) {

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261122-b4-nxp-nci-cold-fault-78ffe9777ba6

Best regards,
--  
EMCP333 <emcp@enser.io>

