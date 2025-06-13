From: Raven Black <ravenblack@gmail.com>
Date: Fri, 13 Jun 2025 07:51:25 -0400
Subject: [PATCH] ASoC: amd: yc: update quirk data for HP Victus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250613-support-hp-victus-microphone-v1-1-bebc4c3a2041@gmail.com>
X-B4-Tracking: v=1; b=H4sIALwQTGgC/x3MwQqDMAwA0F+RnBeodQ7Zr4wdShvXHGxDoiKI/
 27Z8V3eCUbKZPDuTlDa2biWhv7RQcyh/Ag5NYN3fnSvfkDbRKqumAV3jutmuHDUKrkWwtm5NKX
 RP0MM0ApRmvn495/vdd2ZeuRYbgAAAA==
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Raven Black <ravenblack@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749815492; l=967;
 i=ravenblack@gmail.com; s=20250613; h=from:subject:message-id;
 bh=/bACXv58cmQwq8+BzTLIvAZpJC8AGmmTuOuCZ0+0UMk=;
 b=xTamQF7Ox7AfzVbSqdl2WJ2aehKA1sXLoBYMMIHt4t5lDQBvpUfTfzF3uR3CmlDPtjct7mg0i
 oEdrNV2z+uMA3v04due/xp8ttfSkDZA1ZPneno5EuviXCV1ZrN4poCo
X-Developer-Key: i=ravenblack@gmail.com; a=ed25519;
 pk=8ECM1VXVU5AHsXWVPR5Gs6qmW8kY07IYbgnWZDe+ddY=
X-Endpoint-Received: by B4 Relay for ravenblack@gmail.com/20250613 with auth_id=431
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make the internal microphone work on HP Victus laptops.

Signed-off-by: Raven Black <ravenblack@gmail.com>
---
 sound/soc/amd/yc/acp6x-mach.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/sound/soc/amd/yc/acp6x-mach.c b/sound/soc/amd/yc/acp6x-mach.c
index 7e62445e02c1..3451d2f9c9ba 100644
--- a/sound/soc/amd/yc/acp6x-mach.c
+++ b/sound/soc/amd/yc/acp6x-mach.c
@@ -514,6 +514,13 @@ static const struct dmi_system_id yc_acp_quirk_table[] = {
 			DMI_MATCH(DMI_PRODUCT_NAME, "OMEN by HP Gaming Laptop 16z-n000"),
 		}
 	},
+	{
+		.driver_data = &acp6x_card,
+		.matches = {
+			DMI_MATCH(DMI_BOARD_VENDOR, "HP"),
+			DMI_MATCH(DMI_PRODUCT_NAME, "Victus by HP Gaming Laptop 15-fb2xxx"),
+		}
+	},
 	{
 		.driver_data = &acp6x_card,
 		.matches = {

---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250613-support-hp-victus-microphone-f00d8d524aca

Best regards,
-- 
Raven Black <ravenblack@gmail.com>

