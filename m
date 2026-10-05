From: Michael Garland <minimelkav@gmail.com>
Date: Mon, 05 Oct 2026 01:10:32 -0600
Subject: [PATCH] ASoC: amd: yc: Add DMI quirk for Acer Aspire Go 15
 (AG15-21P)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261005-acp6x-herbag2-quirk-v1-1-a1f2683d758f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDMBBA4avIrDuQCak/vUpxEeOo04LaiYog3
 r1pXX6L9w6IrMIRHtkByptEmcYEumUQBj/2jNImgzU2J2Pu6MOc7ziwNr63+FlF3+gckQtFWVH
 rIZWzcif7//qsL8e1eXFYfis4zy9UYpbSdwAAAA==
X-Change-ID: 20261005-acp6x-herbag2-quirk-44114c7891da
To: Vijendar Mukunda <Vijendar.Mukunda@amd.com>, 
 Venkata Prasad Potturu <venkataprasad.potturu@amd.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Michael Garland <minimelkav@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791184246; l=1417;
 i=minimelkav@gmail.com; s=20261005; h=from:subject:message-id;
 bh=Rc372Nll5VxRtwlHdHYkmK+PKfsdL8c4K22pmtyJb7E=;
 b=Q7WbuefFzM3v8XRdrT7tEayQ3HnLgqisFG8NVVaLcVLDclOEm1h6lmzaqqryhtlNflI/Bq7dN
 Wx0jHN9JUqMDMqgjKfrJBBkKhvEZyFHspRvzcOQx+3ZIZeo4ZQX0vHK
X-Developer-Key: i=minimelkav@gmail.com; a=ed25519;
 pk=YgP8zoqOpwmElHd5xoqUtKJTkGSY9Jg/LavDAoXazjs=
X-Endpoint-Received: by B4 Relay for minimelkav@gmail.com/20261005 with auth_id=1113
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Acer Aspire Go 15 (AG15-21P, board MDC Herbag2_MDU) has two PDM
DMICs connected to the ACP. The BIOS does not set the AcpDmicConnected
_DSD property, so the acp6x machine driver never registers the DMIC
card. The existing Herbag_MDU entry does not match this board name, so
add a DMI quirk for it.

Tested on BIOS V1.11: the acp6x DMIC capture device is registered and
records audio on both channels.

Cc: stable@vger.kernel.org
Signed-off-by: Michael Garland <minimelkav@gmail.com>
---
The board name differs from the existing Herbag_MDU entry by one
character, so DMI_MATCH() does not cover it.
---
 sound/soc/amd/yc/acp6x-mach.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/sound/soc/amd/yc/acp6x-mach.c b/sound/soc/amd/yc/acp6x-mach.c
index e798bf6a9cd0..1be8504571ad 100644
--- a/sound/soc/amd/yc/acp6x-mach.c
+++ b/sound/soc/amd/yc/acp6x-mach.c
@@ -787,6 +787,13 @@ static const struct dmi_system_id yc_acp_quirk_table[] = {
 			DMI_MATCH(DMI_BOARD_NAME, "Herbag_MDU"),
 		}
 	},
+	{
+		.driver_data = &acp6x_card,
+		.matches = {
+			DMI_MATCH(DMI_BOARD_VENDOR, "MDC"),
+			DMI_MATCH(DMI_BOARD_NAME, "Herbag2_MDU"),
+		}
+	},
 	{
 		.driver_data = &acp6x_card,
 		.matches = {

---
base-commit: 695f659d296fb05a76f03967733e79b6c2085bae
change-id: 20261005-acp6x-herbag2-quirk-44114c7891da

Best regards,
--  
Michael Garland <minimelkav@gmail.com>

