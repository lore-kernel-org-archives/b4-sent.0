From: Waqar Gulzar <iamwaqargulzar@gmail.com>
Date: Thu, 08 Oct 2026 12:15:01 +0500
Subject: [PATCH v2] HID: i2c-hid-acpi: restore touchscreen IRQ routing on
 HP OmniBook Flip laptops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-b4-elan2514-irq-route-v2-1-432d95eb7348@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPRCx2oC/4WNTQ6CMBBGr0Jm7Zi2lh9deQ/DgpYpjEGqLRAN4
 e4CHsDlS973vhkiBaYIl2SGQBNH9v0K6pCAbau+IeR6ZVBCZeJ8Emg0Ulf1KpUaObww+HEgrAu
 Va2ddIVID6/YZyPF7797KH8fR3MkOW2wzWo6DD5/9eJKb9+9jkihR6yyXxglZi/TaPCrujtY/o
 FyW5QtMscxuzAAAAA==
X-Change-ID: 20260930-b4-elan2514-irq-route-d8274fcf805b
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-acpi@vger.kernel.org, stable@vger.kernel.org, 
 Waqar Gulzar <iamwaqargulzar@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791443700; l=6715;
 i=iamwaqargulzar@gmail.com; s=20260930; h=from:subject:message-id;
 bh=7Fnwx/BOp4ha3EW9HMMdAzjRcB5AydGK0F0fLjOu1CU=;
 b=PM15xATBt61NyYOs5vyUNiNgedZHChppMgjYDCQc+2vuLIJjemu3nDFSjFXEem7kwPishGYp9
 eMSBF7lD8caBwo3dXJ1+EoEMrsc8lUyl0o/Z8X+5EU30AA5WQc7O8/9
X-Developer-Key: i=iamwaqargulzar@gmail.com; a=ed25519;
 pk=SaQhB3EnN6qioo4wuu0rBv6REy1Nx9hz3QOh3Qp9xtk=
X-Endpoint-Received: by B4 Relay for iamwaqargulzar@gmail.com/20260930 with auth_id=1083
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the HP OmniBook X Flip 16, OmniBook 7 Flip 16 and OmniBook X Flip 14
the ELAN2514 touchscreen interrupt is a GPIO pad (GPP_E_18) routed
directly to the IO-APIC. The firmware's touchscreen power resource does

    PTPL._ON:  \_SB.SGRA (TPI2, TPIP)        // TPIP = T0IP = 0
    PTPL._OFF: \_SB.SGRA (TPI2, TPIP ^ 1)

while the device's _INI enables routing with SGRA (GPLI, T0IP ^ 1).
So _ON clears PADCFG0.GPIROUTIOXAPIC and disconnects the pad from the
IO-APIC. Linux evaluates _ON at probe and on every D3->D0 transition
(Windows apparently does not while _STA already reports the resource
on), after which the level-triggered IRQ never deasserts:

  - ~630 interrupts/s while idle, nearly every read returns 0xffff
  - frames shifted by a leading 0xff, "incomplete report (67/7167)"
  - stylus reports arrive at ~25 Hz instead of the native ~268 Hz
  - touch stalls and false stylus proximity

Re-enable the routing through the firmware's own \_SB.SGRA helper from
the power_up hook, which runs at probe and on resume before the HID
reset.

Tested with this patch on the OmniBook X Flip 16 (board 8DA1, BIOS
F.20): idle interrupts drop from ~630/s to 0 after boot and after
s2idle resume, and pen and touch behave as on Windows.

The same faulty _ON, the same pad and the same ~630/s storm were
confirmed by other owners on the OmniBook 7 Flip 16 (board 8DA0, BIOS
F.08) and the OmniBook X Flip 14 (board 8D9F, BIOS F.08). On both,
correcting the _ON value through an ACPI table override stops the storm
(routing bit set, 0 interrupts/s idle, also after s2idle), which is the
same correction this patch applies at runtime.

Link: https://bugzilla.kernel.org/show_bug.cgi?id=220854
Link: https://bugs.launchpad.net/ubuntu/+source/linux/+bug/2142384
Link: https://github.com/testyfishy/hp-omnibook-flip16-touchscreen-fix
Link: https://github.com/iamwaqargulzar/hp-omnibook-x-flip-16-linux-touchscreen-pen-fix
Cc: stable@vger.kernel.org
Signed-off-by: Waqar Gulzar <iamwaqargulzar@gmail.com>
---
The firmware of the HP OmniBook X Flip 16, OmniBook 7 Flip 16 and
OmniBook X Flip 14 disconnects the ELAN2514 touchscreen interrupt from
the IO-APIC in its power resource _ON method, which Linux runs at probe
and resume. This patch re-enables the routing through the firmware's own
helper from i2c-hid-acpi's power_up hook.

Tested with the patch on board 8DA1 (BIOS F.20), Linux 7.2.8,
including s2idle resume. Boards 8DA0 and 8D9F were confirmed by their
owners to have the same faulty _ON and storm, and to be fixed by the
equivalent ACPI table correction (kernel bugzilla 220854).

Full analysis, ACPI excerpts, and Windows/Linux traces:
https://github.com/iamwaqargulzar/hp-omnibook-x-flip-16-linux-touchscreen-pen-fix
---
Changes in v2:
- Add board 8D9F (OmniBook X Flip 14): same faulty _ON, confirmed by
  its owner in bugzilla 220854.
- Fix the description of 8DA0: it is the OmniBook 7 Flip 16, a sibling
  model, not another board ID of the X Flip 16; now confirmed by its
  owner as well.
- Subject and commit message now name all three models; add the
  bugzilla link.
- Link to v1: https://patch.msgid.link/20260930-b4-elan2514-irq-route-v1-1-44671bf01d05@gmail.com
---
 drivers/hid/i2c-hid/i2c-hid-acpi.c | 65 ++++++++++++++++++++++++++++++++++++++
 1 file changed, 65 insertions(+)

diff --git a/drivers/hid/i2c-hid/i2c-hid-acpi.c b/drivers/hid/i2c-hid/i2c-hid-acpi.c
index 9371db200..b307d9a3d 100644
--- a/drivers/hid/i2c-hid/i2c-hid-acpi.c
+++ b/drivers/hid/i2c-hid/i2c-hid-acpi.c
@@ -21,6 +21,7 @@
 
 #include <linux/acpi.h>
 #include <linux/device.h>
+#include <linux/dmi.h>
 #include <linux/i2c.h>
 #include <linux/kernel.h>
 #include <linux/module.h>
@@ -55,6 +56,67 @@ static void i2c_hid_acpi_restore_sequence(struct i2chid_ops *ops)
 	i2c_hid_acpi_get_descriptor(ihid_acpi->adev);
 }
 
+/*
+ * HP OmniBook X Flip 14 (board 8D9F), OmniBook 7 Flip 16 (8DA0) and
+ * OmniBook X Flip 16 (8DA1): the touchscreen power resource
+ * \_SB.PC00.I2C4.PTPL._ON writes the wrong value to the GPIROUTIOXAPIC bit
+ * of the touchscreen interrupt pad, disconnecting it from the IO-APIC. The
+ * level-triggered interrupt then never deasserts, the controller is read
+ * continuously (~630 reads/s while idle) and it cannot deliver pen reports
+ * at its native rate. Windows does not run _ON while the resource already
+ * reports on, so it is not affected. Linux runs _ON at probe and on every
+ * resume, so re-enable the routing with the firmware's own helper before
+ * the HID reset.
+ */
+static const struct dmi_system_id i2c_hid_acpi_irq_route_dmi[] = {
+	{
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "HP"),
+			DMI_EXACT_MATCH(DMI_BOARD_NAME, "8D9F"),
+		},
+	},
+	{
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "HP"),
+			DMI_EXACT_MATCH(DMI_BOARD_NAME, "8DA0"),
+		},
+	},
+	{
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "HP"),
+			DMI_EXACT_MATCH(DMI_BOARD_NAME, "8DA1"),
+		},
+	},
+	{ }
+};
+
+static int i2c_hid_acpi_restore_irq_route(struct i2chid_ops *ops)
+{
+	struct i2c_hid_acpi *ihid_acpi = container_of(ops, struct i2c_hid_acpi, ops);
+	union acpi_object args[2];
+	struct acpi_object_list arg_list = { ARRAY_SIZE(args), args };
+	unsigned long long pad;
+	acpi_status status;
+
+	status = acpi_evaluate_integer(NULL, "\\GPLI", NULL, &pad);
+	if (ACPI_FAILURE(status))
+		return 0;
+
+	args[0].type = ACPI_TYPE_INTEGER;
+	args[0].integer.value = pad;
+	args[1].type = ACPI_TYPE_INTEGER;
+	args[1].integer.value = 1;
+
+	status = acpi_evaluate_object(NULL, "\\_SB.SGRA", &arg_list, NULL);
+	if (ACPI_FAILURE(status))
+		acpi_handle_warn(acpi_device_handle(ihid_acpi->adev),
+				 "failed to restore interrupt routing: %s\n",
+				 acpi_format_exception(status));
+
+	/* Never fail probe or resume because of this workaround */
+	return 0;
+}
+
 static void i2c_hid_acpi_shutdown_tail(struct i2chid_ops *ops)
 {
 	struct i2c_hid_acpi *ihid_acpi = container_of(ops, struct i2c_hid_acpi, ops);
@@ -85,6 +147,9 @@ static int i2c_hid_acpi_probe(struct i2c_client *client)
 	ihid_acpi->adev = adev;
 	ihid_acpi->ops.shutdown_tail = i2c_hid_acpi_shutdown_tail;
 	ihid_acpi->ops.restore_sequence = i2c_hid_acpi_restore_sequence;
+	if (acpi_dev_hid_uid_match(ihid_acpi->adev, "ELAN2514", NULL) &&
+	    dmi_check_system(i2c_hid_acpi_irq_route_dmi))
+		ihid_acpi->ops.power_up = i2c_hid_acpi_restore_irq_route;
 
 	acpi_device_fix_up_power(adev);
 

---
base-commit: 145c2b2e9a5c0f794fb4009bcb072ab19f8ccfcd
change-id: 20260930-b4-elan2514-irq-route-d8274fcf805b

Best regards,
--  
Waqar Gulzar <iamwaqargulzar@gmail.com>

