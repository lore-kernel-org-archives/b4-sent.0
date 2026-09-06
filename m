From: Murat Bayraktar <bob65536@proton.me>
Date: Sun, 06 Sep 2026 13:47:30 -0400
Subject: [PATCH] platform/x86/amd/pmc: Add HP Laptop 14-fq1xxx to s2idle
 quirk list
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-hp-887c-s2idle-quirk-v1-1-e470e36fb01d@proton.me>
X-B4-Tracking: v=1; b=H4sIADGnnWoC/yXMQQ6CQAxA0auQrm0yTEhhvIpxIaVAwQBOhZgQ7
 u4oy7f4fweTqGJwzXaIsqnpPCXklwy4f0ydoDbJ4J0nFxxhv2BVlYzmtXkKvlaNIwYuWs8UqKY
 SUrpEafXz397up22tB+H37wXH8QWp16JYeAAAAA==
X-Change-ID: 20260906-hp-887c-s2idle-quirk-9c4f2c696b67
To: Shyam Sundar S K <Shyam-sundar.S-k@amd.com>, 
 Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Murat Bayraktar <bob65536@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788716854; l=1443;
 i=bob65536@proton.me; s=20260906; h=from:subject:message-id;
 bh=m1+r1CYTcytXaBi2k5cjuAqrOc0NFoUMObOpHPYA82w=;
 b=iHBnWR/J7U7biRBOpAFUnQFRSgyDw7jv0o3dKyOp4RyakPBoBLQYvkXxWAg3QETckCq9MfJzK
 vqPXr+zSt+QCp8dEH/r/CfS5cp6tnTggy4CGoABmpp7BjUrDGqa9V0A
X-Developer-Key: i=bob65536@proton.me; a=ed25519;
 pk=G9C/pqrSzls8L2+wxehgU1yWaNjJcafp6o6nWqNnG7o=
X-Endpoint-Received: by B4 Relay for bob65536@proton.me/20260906 with auth_id=1009
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HP Laptop 14-fq1xxx (board 887C, BIOS F.38) takes about 10.2
seconds in noirq device resume from s2idle. Its firmware uses the NVMe
SMI path already handled by amd_pmc_skip_nvme_smi_handler().

Add the system to fwbug_list with the combined Cezanne quirk so the
existing spurious 8042 workaround remains enabled. This reduced noirq
device resume from 10195/10242 ms to 27 ms in testing.

Signed-off-by: Murat Bayraktar <bob65536@proton.me>
---
 drivers/platform/x86/amd/pmc/pmc-quirks.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/platform/x86/amd/pmc/pmc-quirks.c b/drivers/platform/x86/amd/pmc/pmc-quirks.c
index 09a30f3..e662b12 100644
--- a/drivers/platform/x86/amd/pmc/pmc-quirks.c
+++ b/drivers/platform/x86/amd/pmc/pmc-quirks.c
@@ -280,6 +280,15 @@ static const struct dmi_system_id fwbug_list[] = {
 			DMI_MATCH(DMI_PRODUCT_NAME, "83N1"),
 		}
 	},
+	{
+		.ident = "HP Laptop 14-fq1xxx",
+		.driver_data = &quirk_s2idle_spurious_8042,
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "HP"),
+			DMI_MATCH(DMI_PRODUCT_NAME, "HP Laptop 14-fq1xxx"),
+			DMI_MATCH(DMI_BOARD_NAME, "887C"),
+		}
+	},
 	/* https://gitlab.freedesktop.org/drm/amd/-/issues/2684 */
 	{
 		.ident = "HP Laptop 15s-eq2xxx",

---
base-commit: 1fc5a74b108fc90951890ec513ac81869f5eaff1
change-id: 20260906-hp-887c-s2idle-quirk-9c4f2c696b67

Best regards,
--  
Murat Bayraktar <bob65536@proton.me>

