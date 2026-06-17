From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 16 Jun 2026 23:59:45 -0500
Subject: [PATCH v2] power: supply: cros_usbpd-charger: bound the
 EC-reported port count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260616-b4-disp-5e197080-v2-1-8aa5bffce945@proton.me>
X-B4-Tracking: v=1; b=H4sIAMApMmoC/x3MTQqAIBBA4avIrBtQacy6SrToZ6rZlChEIN49a
 fkt3suQOAonGFSGyI8kua8K2yhYz/k6GGWrBqut0844XFrcJAUkNn2nvcaW9tnTYpnIQM1C5F3
 efzlOpXy8PTAlYgAAAA==
To: Tzung-Bi Shih <tzungbi@kernel.org>, Benson Leung <bleung@chromium.org>, 
 Sebastian Reichel <sre@kernel.org>
Cc: chrome-platform@lists.linux.dev, linux-pm@vger.kernel.org, 
 Guenter Roeck <groeck@chromium.org>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781672384; l=3873;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=vPz9/pW6U5P0Sxc9eiv+I7NjKeYRGkRNB5Df/kBDu5I=;
 b=NFsa2KOzhEQDsjkdSRtr8D8fNJ9soVqK/oPxzxazG+t/t2oN4lmyUrYz7UGO+lA65sqpMHbht
 572k5ZGKGfiAAVlwiKrUuOrDA8v1L4TKHUJuDDDJI6Ag3IuQrYYxCZI
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cros_usbpd_charger_probe() reads two port counts from the EC and uses
one of them, num_charger_ports, as the loop bound when populating a
fixed-size array:

	struct port_data *ports[EC_USB_PD_MAX_PORTS];	/* 8 entries */
	...
	for (i = 0; i < charger->num_charger_ports; i++)
		charger->ports[charger->num_registered_psy++] = port;

Both num_usbpd_ports (from EC_CMD_USB_PD_PORTS) and num_charger_ports
(from EC_CMD_CHARGE_PORT_COUNT) are u8 values reported by the EC. The
only validation is a sanity check that compares the two EC-reported
values against each other:

	if (num_charger_ports < num_usbpd_ports ||
	    num_charger_ports > num_usbpd_ports + 1)
		return -EPROTO;

It never checks either count against EC_USB_PD_MAX_PORTS, the size of
the ports[] array. A malfunctioning, malicious or compromised EC that
reports num_usbpd_ports == num_charger_ports == N for any N > 8 (for
example both 255) passes this check, and the loop then writes N pointers
into the 8-entry ports[] array embedded in the devm_kzalloc()'d
charger_data, overflowing it by up to 255 - 8 = 247 entries (~1976
bytes): a slab out-of-bounds write.

Reject a port count larger than the ports[] array can hold.

Fixes: f68b883e8fad ("power: supply: add cros-ec USBPD charger driver.")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
Reviewed-by: Tzung-Bi Shih <tzungbi@kernel.org>
---
v2:
 - Reword the added comment per Tzung-Bi Shih: drop the redundant "the
   count is reported by the EC" and name the bound, EC_USB_PD_MAX_PORTS.
   No functional change.
 - Add Reviewed-by: Tzung-Bi Shih.
 v1: https://lore.kernel.org/all/20260615-b4-disp-e0930b21-v1-1-c9ffbac7c9bb@proton.me

I reproduced the out-of-bounds write with an in-kernel test that drives
the cros_usbpd_charger_probe() geometry verbatim under KASAN - a
devm_kzalloc()'d charger_data with the 8-entry ports[] array, the
EC-value cross-check, and the population loop - with the device-supplied
port counts:

  num_charger_ports = num_usbpd_ports = 12, no bound:
    BUG: KASAN: slab-out-of-bounds in ...probe
    Write of size 8 ... cache kmalloc-128 ... 0 bytes to the right of the
    allocated 128-byte region   (ports[8..11] past the 8-entry array)
  with this patch (count > EC_USB_PD_MAX_PORTS rejected): -EPROTO, no
    KASAN report.
  a well-formed count (<= EC_USB_PD_MAX_PORTS) is unaffected, no report.

The full device range - both counts reported as 255, writing 247
pointers (~1976 bytes) past the array - reproduces the same way under
userspace AddressSanitizer on both -m32 and -m64.
---
 drivers/power/supply/cros_usbpd-charger.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/power/supply/cros_usbpd-charger.c b/drivers/power/supply/cros_usbpd-charger.c
index 7d3e676a951c..45a87f5baac6 100644
--- a/drivers/power/supply/cros_usbpd-charger.c
+++ b/drivers/power/supply/cros_usbpd-charger.c
@@ -589,10 +589,13 @@ static int cros_usbpd_charger_probe(struct platform_device *pd)
 
 	/*
 	 * Sanity checks on the number of ports:
-	 *  there should be at most 1 dedicated port
+	 *  there should be at most 1 dedicated port, and the count must
+	 *  not exceed the maximum number of supported ports
+	 *  (EC_USB_PD_MAX_PORTS).
 	 */
 	if (charger->num_charger_ports < charger->num_usbpd_ports ||
-	    charger->num_charger_ports > (charger->num_usbpd_ports + 1)) {
+	    charger->num_charger_ports > (charger->num_usbpd_ports + 1) ||
+	    charger->num_charger_ports > EC_USB_PD_MAX_PORTS) {
 		dev_err(dev, "Unexpected number of charge port count\n");
 		ret = -EPROTO;
 		goto fail_nowarn;

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260616-b4-disp-5e197080-45fa85b2e551

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

