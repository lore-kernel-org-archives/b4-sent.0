From: Ihor Urazov <z0rc3r@gmail.com>
Date: Tue, 27 Oct 2026 12:35:00 +0200
Subject: [PATCH v2] usb: typec: ucsi: acpi: Assume UCSI 1.0 on HP ZBook 8
 G2i 14
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-ucsi-hp-zbook-8-g2i-v2-1-02a600e4f0a4@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NwQ6CMBBEf4Xs2TVtrSie/A/DAcoCq0JJC41K+
 HcL3j3M4SUz82bw5Jg8XJIZHAX2bPsIapeAaYu+IeQqMiihUhmDk/GM7YCf0toHnrFRjFrrtCh
 TOlKlIS4HRzW/ttdb/mM/lXcy43q1Nlr2o3XvTRvk2vtvCBIlZlIIRRnV4nS4Nl3Bz72xHeTLs
 nwBQeBu+8gAAAA=
X-Change-ID: 20261026-ucsi-hp-zbook-8-g2i-4446ab6e5ed4
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Francesco Orro <ncesco@interstellar.eu>, 
 Huang Wei <huangwei@kylinos.cn>, Ihor Urazov <z0rc3r@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4023; i=z0rc3r@gmail.com;
 h=from:subject:message-id; bh=NlPCvrvQhtgItzt9zsdsYFiRx4ZowVkUcnfZuo3biYA=;
 b=owGbwMvMwCWmab25vPXFu0bG02pJDFkP6sIKDLW3xMdYFExSvVCrEH9SYOrxPTm1Dpkc0bX+r
 9bqP/zSUcrCIMbFICumyNK/z4BXW8hUnOmLzRuYOaxMIEMYuDgFYCLPKhgZ5p7v37Wsanozl4il
 p+uM59orTF3WBQradSS/Plm52HYrM8Mf7kVvvj/Lj2WY1Tfn5QlHtvVLl2f67mE+bNkjK17WXf6
 MEwA=
X-Developer-Key: i=z0rc3r@gmail.com; a=openpgp;
 fpr=F7D877ECBB274E704A31F3AC5D006BEB7252F7F2
X-Endpoint-Received: by B4 Relay for z0rc3r@gmail.com/default with auth_id=1320
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HP ZBook 8 G2i 14 (board 8ED9) exposes a working UCSI ACPI PPM, but
its UCSI VERSION field reads zero until the first command completes.
ucsi_register() rejects a zero version with -ENODEV, so no Type-C ports
are registered.

The firmware's _DSM READ function (2) is a stub. The mailbox VERSION
field is written only by the EC response handler, after a command
completes, after which it reads 0x0100 (UCSI 1.0). The mailbox is
48 bytes with 16-byte MESSAGE_IN/MESSAGE_OUT fields, the UCSI 1.x
layout, and _DSM function 5 is not implemented.

Add a DMI-specific read_version for this board that substitutes the
version the firmware itself reports, UCSI 1.0, only when VERSION reads
zero. A non-zero firmware version is used as is.

The same firmware defect on the HP ZBook Fury G1i 16 was discussed in
"[RFC PATCH] usb: typec: ucsi: acpi: bootstrap PPM on HP systems with
empty _DSM func 2" [1]. The defect was reported to HP as case
5166176673.

Tested on an HP ZBook 8 G2i 14 with BIOS Y70 01.02.08, from a fresh
boot where VERSION reads zero: three connectors register, the PD
contract and alternate modes of a Thunderbolt dock are reported, and
its DisplayPort output stays up across the PPM reset in ucsi_init().
Dock unplug/replug and s2idle suspend/resume update the connector
state without errors.

Link: https://lore.kernel.org/linux-usb/f3M_fpjtt8FxDqGKcA84vqXmRbKzCBfpCrIK4-jCWvIscER51zkD8qD8FYpz75qZw51rMDRSkUyYlrBvLvdM8CGRY2l8TFVvr4MC1LdTzbc=@interstellar.eu/ [1]
Fixes: bdc62f2bae8f ("usb: typec: ucsi: Simplified registration and I/O API")
Cc: stable@vger.kernel.org
Cc: Francesco Orro <ncesco@interstellar.eu>
Assisted-by: Claude:claude-opus-5-5
Reviewed-by: Heikki Krogerus <heikki.krogerus@linux.intel.com>
Reviewed-by: Huang Wei <huangwei@kylinos.cn>
Signed-off-by: Ihor Urazov <z0rc3r@gmail.com>
---
Changes in v2:
- Point Fixes: at bdc62f2bae8f, which added the zero-version check (Huang Wei)
- Add Reviewed-by tags
- Link to v1: https://patch.msgid.link/20261026-ucsi-hp-zbook-8-g2i-v1-1-91002e9ef073@gmail.com
---
 drivers/usb/typec/ucsi/ucsi_acpi.c | 35 +++++++++++++++++++++++++++++++++++
 1 file changed, 35 insertions(+)

diff --git a/drivers/usb/typec/ucsi/ucsi_acpi.c b/drivers/usb/typec/ucsi/ucsi_acpi.c
index 5697ccc24ec3..2421a92ecb0e 100644
--- a/drivers/usb/typec/ucsi/ucsi_acpi.c
+++ b/drivers/usb/typec/ucsi/ucsi_acpi.c
@@ -148,6 +148,34 @@ static const struct ucsi_operations ucsi_acer_ops = {
 	.async_control = ucsi_acpi_async_control
 };
 
+static int ucsi_hp_read_version(struct ucsi *ucsi, u16 *version)
+{
+	struct ucsi_acpi *ua = ucsi_get_drvdata(ucsi);
+	int ret;
+
+	ret = ucsi_acpi_read_version(ucsi, version);
+	if (ret)
+		return ret;
+
+	/* Firmware fills in VERSION (1.0) only after the first command completes */
+	if (!*version) {
+		dev_warn(ua->dev, "UCSI version is zero, assuming 1.0\n");
+		*version = UCSI_VERSION_1_0;
+	}
+
+	return 0;
+}
+
+static const struct ucsi_operations ucsi_hp_ops = {
+	.read_version = ucsi_hp_read_version,
+	.read_cci = ucsi_acpi_read_cci,
+	.poll_cci = ucsi_acpi_poll_cci,
+	.read_message_in = ucsi_acpi_read_message_in,
+	.write_message_out = ucsi_acpi_write_message_out,
+	.sync_control = ucsi_sync_control_common,
+	.async_control = ucsi_acpi_async_control
+};
+
 static int ucsi_gram_sync_control(struct ucsi *ucsi, u64 command, u32 *cci,
 				  void *val, size_t len, void *msg_out,
 				  size_t msg_out_size)
@@ -196,6 +224,13 @@ static const struct dmi_system_id ucsi_acpi_quirks[] = {
 		},
 		.driver_data = (void *)&ucsi_acer_ops,
 	},
+	{
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "HP"),
+			DMI_MATCH(DMI_BOARD_NAME, "8ED9"),
+		},
+		.driver_data = (void *)&ucsi_hp_ops,
+	},
 	{
 		.matches = {
 			DMI_MATCH(DMI_SYS_VENDOR, "LG Electronics"),

---
base-commit: 21a7f44fd0765fcc5194130b28767786eba1d1e7
change-id: 20261026-ucsi-hp-zbook-8-g2i-4446ab6e5ed4

Best regards,
--  
Ihor Urazov <z0rc3r@gmail.com>

