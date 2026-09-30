From: Waqar Gulzar <iamwaqargulzar@gmail.com>
Date: Wed, 30 Sep 2026 11:22:49 +0500
Subject: [PATCH] HID: i2c-hid-acpi: restore touchscreen IRQ routing on HP
 OmniBook X Flip 16
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-b4-elan2514-irq-route-v1-1-44671bf01d05@gmail.com>
X-B4-Tracking: v=1; b=H4sIALiqvGoC/yXMQQqDMBBA0avIrDsQY7TaqxQXJk7siEQ7URHEu
 zdtl2/x/wmRhCnCIztBaOfIc0jIbxm4VxcGQu6TQStdqaZQaA3S1AVd5gZZ3ijzthL2tb4b73y
 tSgupXYQ8H7/vs/07bnYkt35ncF0fk1cS8nkAAAA=
X-Change-ID: 20260930-b4-elan2514-irq-route-d8274fcf805b
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-acpi@vger.kernel.org, stable@vger.kernel.org, 
 Waqar Gulzar <iamwaqargulzar@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790749371; l=5531;
 i=iamwaqargulzar@gmail.com; s=20260930; h=from:subject:message-id;
 bh=i/kcWiyvC9sOaZJ1/0neMN3dO4OBwcexqs5ODF8WpnE=;
 b=587x1mpxQN0x62TTKWKXtPdtKnrhddDQKiq2/8MFrl7x+g6GrAgLnUMYhz2h4sdOnNmRDDYel
 8PYX7GrgiGMDHCTLbK1KdvQrU2RjE1InqS+UeAijEHn1IxH/SdGfWKW
X-Developer-Key: i=iamwaqargulzar@gmail.com; a=ed25519;
 pk=SaQhB3EnN6qioo4wuu0rBv6REy1Nx9hz3QOh3Qp9xtk=
X-Endpoint-Received: by B4 Relay for iamwaqargulzar@gmail.com/20260930 with auth_id=1083
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the HP OmniBook X Flip 16 the ELAN2514 touchscreen interrupt is a
GPIO pad (GPP_E_18) routed directly to the IO-APIC. The firmware's
touchscreen power resource does

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

Tested on board 8DA1 (BIOS F.20): idle interrupts drop from ~630/s to
0 after boot and after s2idle resume, and pen and touch behave as on
Windows. Board 8DA0 is the other board ID of this model and is reported
to have the same firmware code, so it is included, but it has not been
tested because I do not have access to one.

Link: https://bugs.launchpad.net/ubuntu/+source/linux/+bug/2142384
Link: https://github.com/testyfishy/hp-omnibook-flip16-touchscreen-fix
Link: https://github.com/iamwaqargulzar/hp-omnibook-x-flip-16-linux-touchscreen-pen-fix
Cc: stable@vger.kernel.org
Signed-off-by: Waqar Gulzar <iamwaqargulzar@gmail.com>
---
The HP OmniBook X Flip 16 firmware disconnects the ELAN2514 touchscreen
interrupt from the IO-APIC in its power resource _ON method, which Linux
runs at probe and resume. This patch re-enables the routing through the
firmware's own helper from i2c-hid-acpi's power_up hook.

Tested on board 8DA1 with BIOS F.20 on Linux 7.2.8, including s2idle
resume. The 8DA0 entry is untested (I do not have that board).

Full analysis, ACPI excerpts, and Windows/Linux traces:
https://github.com/iamwaqargulzar/hp-omnibook-x-flip-16-linux-touchscreen-pen-fix
---
 drivers/hid/i2c-hid/i2c-hid-acpi.c | 58 ++++++++++++++++++++++++++++++++++++++
 1 file changed, 58 insertions(+)

diff --git a/drivers/hid/i2c-hid/i2c-hid-acpi.c b/drivers/hid/i2c-hid/i2c-hid-acpi.c
index 9371db200..b6348ee3d 100644
--- a/drivers/hid/i2c-hid/i2c-hid-acpi.c
+++ b/drivers/hid/i2c-hid/i2c-hid-acpi.c
@@ -21,6 +21,7 @@
 
 #include <linux/acpi.h>
 #include <linux/device.h>
+#include <linux/dmi.h>
 #include <linux/i2c.h>
 #include <linux/kernel.h>
 #include <linux/module.h>
@@ -55,6 +56,60 @@ static void i2c_hid_acpi_restore_sequence(struct i2chid_ops *ops)
 	i2c_hid_acpi_get_descriptor(ihid_acpi->adev);
 }
 
+/*
+ * HP OmniBook X Flip 16 (boards 8DA0/8DA1): the touchscreen power resource
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
@@ -85,6 +140,9 @@ static int i2c_hid_acpi_probe(struct i2c_client *client)
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

