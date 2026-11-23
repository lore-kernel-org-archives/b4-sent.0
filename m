From: Xiuqi Xu <cagedbird043@gmail.com>
Date: Mon, 23 Nov 2026 15:51:57 +0800
Subject: [PATCH] ACPI: resource: Do IRQ override on MECHREVO GM6XG0X
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-acpi-mechrevo-gm6xg0x-v1-1-8ad76455267e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMywqDMBCF4VeRWXcgiZBWX0W6iOMYp+CFxJZA8
 N2NdvnBOX+GyEE4QltlCPyTKOtSoB8V0OQWzyhDMRhlrNamRkeb4Mw0lfWKfrbJq4T01MT2Nbp
 GDVC+W+BR0t3t3n/Hb/9h2q8YHMcJ1M1fAHkAAAA=
X-Change-ID: 20261123-acpi-mechrevo-gm6xg0x-c71ce68fa90d
To: "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 Chuanhong Guo <gch981213@gmail.com>
Cc: linux-acpi@vger.kernel.org, stable@vger.kernel.org, 
 Xiuqi Xu <cagedbird043@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795420316; l=1606;
 i=cagedbird043@gmail.com; s=20261123; h=from:subject:message-id;
 bh=8TxhdXQM1wQfG6AauVLgZq58N7Egkr43PPl431dbi7Q=;
 b=PLdVr6/4Q+vkfpfYDh8TWjvWtiP+DmAxgTcCZdbEtX7dwRQ+CZUws9+pS9ttA0BOJq294IpRm
 ZtCtEza31m7BbK40DSB0P+v2BvBXm66QrChea/zJgseWpH2vxpntdiH
X-Developer-Key: i=cagedbird043@gmail.com; a=ed25519;
 pk=zdBhtz5U+dUh9MDFOitlMU0OLF4BaaSouGW7kdduQR8=
X-Endpoint-Received: by B4 Relay for cagedbird043@gmail.com/20261123 with auth_id=1614
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MECHREVO Jiaolong16S Series laptop (board name GM6XG0X) has the
same problem as the Jiaolong17KS (GM7XG0M) already listed: the DSDT
describes the keyboard IRQ as Edge, ActiveLow, Shared, so the internal
keyboard does not work.

Add it to irq1_edge_low_force_override[] to make the internal keyboard
work.

Tested on a GM6XG0X (AMD Ryzen 7 7840H, BIOS N.1.24MRO14) with a DSDT
override that changes the PS2K IRQ descriptor to Edge, ActiveHigh, which
is what this override does. The keyboard works with no other kernel
parameters.

Fixes: 9946e39fe8d0 ("ACPI: resource: skip IRQ override on AMD Zen platforms")
Cc: stable@vger.kernel.org
Signed-off-by: Xiuqi Xu <cagedbird043@gmail.com>
---
I used an AI assistant to find that this board was missing from the list
and to draft this commit message. I have reviewed the change and the
message.
---
 drivers/acpi/resource.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/acpi/resource.c b/drivers/acpi/resource.c
index 56df4599d360..144173f2c272 100644
--- a/drivers/acpi/resource.c
+++ b/drivers/acpi/resource.c
@@ -553,6 +553,12 @@ static const struct dmi_system_id irq1_edge_low_force_override[] = {
 			DMI_MATCH(DMI_BOARD_NAME, "GM7XG0M"),
 		},
 	},
+	{
+		/* MECHREVO Jiaolong16S Series GM6XG0X */
+		.matches = {
+			DMI_MATCH(DMI_BOARD_NAME, "GM6XG0X"),
+		},
+	},
 	{
 		/* XMG APEX 17 (M23) */
 		.matches = {

---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-acpi-mechrevo-gm6xg0x-c71ce68fa90d

Best regards,
--  
Xiuqi Xu <cagedbird043@gmail.com>

