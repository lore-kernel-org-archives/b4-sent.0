From: =?utf-8?q?Gilson_Marquato_J=C3=BAnior?= <gilsonmandalogo@hotmail.com>
Date: Mon, 30 Mar 2026 02:43:48 +0100
Subject: [PATCH] ASoC: amd: yc: Add DMI entry for HP Laptop 15-fc0xxx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260330-hp-15-fc0xxx-dmic-v2-v1-1-6dd6f53a1917@hotmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MSQqAMAwAvyI5G0grCvoV8dAltTm40IIUpH+3y
 JzmMPNC5iScYeleSPxIlutsovoOXDTnzii+OWjSEw0DYbxRjRgclVLQH+Lw0TizNYqsaSho6Z0
 4SPm361brB1C2roVmAAAA
X-Change-ID: 20260330-hp-15-fc0xxx-dmic-v2-9eba10babab1
To: Vijendar Mukunda <Vijendar.Mukunda@amd.com>, 
 Venkata Prasad Potturu <venkataprasad.potturu@amd.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Gilson_Marquato_J=C3=BAnior?= <gilsonmandalogo@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774835040; l=1218;
 i=gilsonmandalogo@hotmail.com; s=20260330; h=from:subject:message-id;
 bh=6qeyom/q+wq80HQ4SjhnrO8d7uH0lH6UkhJuNUiDj3A=;
 b=Zt4t4bzIe3LStovXjfObr3F6jTZIBYaD90NqJCNy3OC1mJ030BlGkWVOq/IESLpGZnyO369U6
 w1EYA0y/+sMCATHsGtV19BnBNd8NOfZFdqaSiPsuItKiahylksOwual
X-Developer-Key: i=gilsonmandalogo@hotmail.com; a=ed25519;
 pk=1S2rDhYrMqtm3oH3Q8zOSoiPjAjN43ViUvVUmQ28I1A=
X-Endpoint-Received: by B4 Relay for gilsonmandalogo@hotmail.com/20260330 with auth_id=702
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HP Laptop 15-fc0xxx (subsystem ID 0x103c8dc9) has an internal
DMIC connected to the AMD ACP6x audio coprocessor. Add a DMI quirk
entry so the internal microphone is properly detected on this model.

Tested on HP Laptop 15-fc0237ns with Fedora 43 (kernel 6.19.9).

Signed-off-by: Gilson Marquato Júnior <gilsonmandalogo@hotmail.com>
---
 sound/soc/amd/yc/acp6x-mach.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/sound/soc/amd/yc/acp6x-mach.c b/sound/soc/amd/yc/acp6x-mach.c
index 6f1c105ca77e3896ed1c0a6628331e378bfba988..4c0acdad13ea1c034eb51b69828914cf35dad713 100644
--- a/sound/soc/amd/yc/acp6x-mach.c
+++ b/sound/soc/amd/yc/acp6x-mach.c
@@ -45,6 +45,13 @@ static struct snd_soc_card acp6x_card = {
 };
 
 static const struct dmi_system_id yc_acp_quirk_table[] = {
+	{
+		.driver_data = &acp6x_card,
+		.matches = {
+			DMI_MATCH(DMI_BOARD_VENDOR, "HP"),
+			DMI_MATCH(DMI_PRODUCT_NAME, "HP Laptop 15-fc0xxx"),
+		}
+	},
 	{
 		.driver_data = &acp6x_card,
 		.matches = {

---
base-commit: 39b68f430a1b299a041ce44a695ae9ddb2576ca1
change-id: 20260330-hp-15-fc0xxx-dmic-v2-9eba10babab1

Best regards,
-- 
Gilson Marquato Júnior <gilsonmandalogo@hotmail.com>

