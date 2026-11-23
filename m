From: Markus Haberlander <markus.haberlander@rosenberger.com>
Date: Mon, 23 Nov 2026 07:32:28 +0100
Subject: [PATCH] mfd: cgbc-core: Add support for conga-PA7
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-cgbc-conga-pa7-v1-1-f3d17fb02e43@rosenberger.com>
X-B4-Tracking: v=1; b=H4sIAPvdA2sC/yXMQQrDIBBA0auEWWegKhjoVUoXZpza6UJFkxCQ3
 D0mXb7F/w0qF+EKz6FB4U2qpNihxgHo62JgFN8N+qGtUtoghZmQUgwOs5vQk528Yc3eWOhRLvy
 R/R6+3n/Xdf4xLdcFjuMEGVKK8HIAAAA=
X-Change-ID: 20261123-cgbc-conga-pa7-dc67d3e2ed36
To: Thomas Richard <thomas.richard@bootlin.com>, Lee Jones <lee@kernel.org>
Cc: mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 Markus Haberlander <markus.haberlander@rosenberger.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795415564; l=1513;
 i=markus.haberlander@rosenberger.com; s=20261123; h=from:subject:message-id;
 bh=v1CPWN/2XkF2f1MoPpYxZuyNZds9qyQfrKK/LTczYvU=;
 b=Y2uothSjoELTvG4Mb6hN5yuCH4QqU5F6vr3ENRqv1VUiWrYP30Km46XE/zr7onLPqOz4YGiws
 1b2VGJMzJ4cCHecyB24R07WlKZv9zD5RwgXp7oSmw/ppYxk8Rz8iFC9
X-Developer-Key: i=markus.haberlander@rosenberger.com; a=ed25519;
 pk=baNIWlZCf58g17gE2FS6ir0ymNwyBXguoQENSJkXdeQ=
X-Endpoint-Received: by B4 Relay for markus.haberlander@rosenberger.com/20261123 with auth_id=1612
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The conga-PA7 is a Pico-ITX board with an Intel Elkhart Lake SoC, like
the conga-SA7 SMARC module. Its board controller is of the same
generation and is accessed through the same I/O ports, so the existing
driver works with it once the board is matched.

Match the board vendor and name, as for the other boards: the system
vendor and product name are empty on this board.

Tested on a conga-PA7 (board revision A.2, BIOS PA70R026): the core
driver loads through its DMI alias and adds its GPIO, I2C and hwmon
cells.

The patch and this changelog were drafted with the help of Claude
Opus 5.5 and reviewed and tested by me.

Cc: stable@vger.kernel.org # 6.13.x
Signed-off-by: Markus Haberlander <markus.haberlander@rosenberger.com>
---
 drivers/mfd/cgbc-core.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/mfd/cgbc-core.c b/drivers/mfd/cgbc-core.c
index 8a63923d1..cd68d396d 100644
--- a/drivers/mfd/cgbc-core.c
+++ b/drivers/mfd/cgbc-core.c
@@ -379,6 +379,13 @@ static struct platform_driver cgbc_driver = {
 };
 
 static const struct dmi_system_id cgbc_dmi_table[] __initconst = {
+	{
+		.ident = "PA7",
+		.matches = {
+			DMI_MATCH(DMI_BOARD_VENDOR, "congatec"),
+			DMI_MATCH(DMI_BOARD_NAME, "conga-PA7"),
+		},
+	},
 	{
 		.ident = "SA7",
 		.matches = {

---
base-commit: 1cb7268b6638c411fc32f373e965eb8ba9e9b2b4
change-id: 20261123-cgbc-conga-pa7-dc67d3e2ed36

Best regards,
--  
Markus Haberlander <markus.haberlander@rosenberger.com>

