From: Travis Howard <thoward@lafayetteinstrument.com>
Date: Mon, 19 Oct 2026 20:03:10 +0000
Subject: [PATCH net] tg3: Add Datto SIRIS 5 1U Server to restart AER quirk
 table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-tg3-datto-aer-quirk-v1-1-f0eccfb2ab5d@lafayetteinstrument.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqDMBBG4avIrB1IDEjtVUoXIfm1QyHqJEohe
 PcGl9/ivUoZKsj07CopTsmypgbbdxQ+Pi1gic00mGG0xk5cFsfRl7Kyh/J+iH7ZBvcwcJNDGKm
 Vm2KW3319UUKh93X9AT5jtKFqAAAA
X-Change-ID: 20261019-tg3-datto-aer-quirk-1c380e393ec6
To: Pavan Chebbi <pavan.chebbi@broadcom.com>, 
 Michael Chan <mchan@broadcom.com>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Lenny Szubowicz <lszubowi@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Travis Howard <thoward@lafayetteinstrument.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792440210; l=1864;
 i=thoward@lafayetteinstrument.com; s=20261019; h=from:subject:message-id;
 bh=FQAa09JcOMIFgEiW9Oki1Yij0dC7wNyid9KU2wn2HgE=;
 b=kwubS8wgB9x8wOWlt3wML8AyxENUtJiqe2UyVQnlXbOrY99ByBcGu4WttrdIZ+yg0sKqXNGYI
 VHordkMzvsNCM2L7ye3M719/4m6Svo+lIqNrBAuESWBWz8/CxWsqvcY
X-Developer-Key: i=thoward@lafayetteinstrument.com; a=ed25519;
 pk=rtL9URAe9ViV6WvIEtBEMb/2i9C1CKXa5RwTxC6I6Vw=
X-Endpoint-Received: by B4 Relay for thoward@lafayetteinstrument.com/20261019 with auth_id=1243
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Datto SIRIS 5 1U Server is a Dell OEMR XL R640 (Dell's OEM-ready
variant of the PowerEdge R640) sold under Datto's identity. Its DMI
strings report sys_vendor "datto" and product_name "SIRIS 5 1U Server",
so it does not match the existing "PowerEdge R640" entry in
tg3_restart_aer_quirk_table.

As on the PowerEdge R640, a system restart triggers a fatal PCIe AER
on the BCM5720 during ACPI _PTS for S5, which the iDRAC logs as
PCI1318 and which hangs the reboot. Power off is unaffected.

Clearing the same PCI_EXP_DEVCTL error-reporting bits on both BCM5720
functions from userspace immediately before restart allows the system
to reboot normally, confirming the quirk applies to this platform.

Fixes: e0efe83ed325 ("tg3: Disable tg3 PCIe AER on system reboot")
Signed-off-by: Travis Howard <thoward@lafayetteinstrument.com>
---
Tested on the affected system (Ubuntu 26.04, 7.0.0-38-generic) with
this change applied to tg3: reboot completes and no PCI1318 is logged.
Without it, every restart hangs with PCI1318 logged against the BCM5720.
---
 drivers/net/ethernet/broadcom/tg3.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/net/ethernet/broadcom/tg3.c b/drivers/net/ethernet/broadcom/tg3.c
index 8b6806a79edf..b6aa10f2bdf7 100644
--- a/drivers/net/ethernet/broadcom/tg3.c
+++ b/drivers/net/ethernet/broadcom/tg3.c
@@ -18229,6 +18229,12 @@ static const struct dmi_system_id tg3_restart_aer_quirk_table[] = {
 			DMI_MATCH(DMI_PRODUCT_NAME, "PowerEdge R750"),
 		},
 	},
+	{
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "datto"),
+			DMI_MATCH(DMI_PRODUCT_NAME, "SIRIS 5 1U Server"),
+		},
+	},
 	{}
 };
 

---
base-commit: 78731b46967e3e7102b5cd5062bef185f3404b5c
change-id: 20261019-tg3-datto-aer-quirk-1c380e393ec6

Best regards,
-- 
Travis Howard <thoward@lafayetteinstrument.com>

