From: Prasanna Raghavan <email2trprasanna@gmail.com>
Date: Fri, 17 Apr 2026 16:53:47 -0400
Subject: [PATCH] ALSA: hda/realtek: Enable GPIO amp on Razer Blade 14
 (2021)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260417-for-next-v1-1-c3338f3b1f5d@gmail.com>
X-B4-Tracking: v=1; b=H4sIANqd4mkC/yXMSwqAIBSF4a3IHSeoRK+tRIPMa90GGlohRHvPa
 vjBf84FEQNhhI5dEPCkSN5lyILBtIxuRk4mG5RQlShlza0P3GHauRJlK4UxurEWcr4FtJS+q37
 4HQ+94rS/e7jvB6nilZtsAAAA
X-Change-ID: 20260417-for-next-204910ddb8ff
To: perex@perex.cz
Cc: linux-kernel@vger.kernel.org, 
 Prasanna Raghavan <email2trprasanna@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776459252; l=2355;
 i=email2trprasanna@gmail.com; s=20260417; h=from:subject:message-id;
 bh=YSf+DrkdioqtmvufmkJZqNFTIiKv8EdRzZW52f5JvSk=;
 b=L1YHCIbFuob7jEnBfXByJrpgQuJdNKGROvEyYKjlFpCdHwkWkBalr8dyBqOLpb7Hn4dSYu9jN
 JlN8Begc5AFB+2/Z3T4nsQZDc2GMig6oOit1gMMKyFyfcCwtveDFCNQ
X-Developer-Key: i=email2trprasanna@gmail.com; a=ed25519;
 pk=HzojC3zGBcTee8lR32uFbkif0LmPqaxEvfornda4QUI=
X-Endpoint-Received: by B4 Relay for email2trprasanna@gmail.com/20260417 with auth_id=740
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Razer Blade 14 (2021, RZ09-0370) uses an ALC897 codec with
subsystem ID 0x1a582014. The headphone output is routed through a
GPIO-controlled external amplifier. The Windows driver enables GPIO
pins 0-2 at init, but Linux has no quirk for this board, leaving the
amp disabled -- resulting in ~15dB lower output with degraded frequency
response.

Add a fixup to enable GPIO 0-2 as outputs set high, matching the
Windows driver behavior.

Signed-off-by: Prasanna Raghavan <email2trprasanna@gmail.com>
---
 sound/hda/codecs/realtek/alc662.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/sound/hda/codecs/realtek/alc662.c b/sound/hda/codecs/realtek/alc662.c
index 2cf3664a3..a8ebe06ae 100644
--- a/sound/hda/codecs/realtek/alc662.c
+++ b/sound/hda/codecs/realtek/alc662.c
@@ -325,6 +325,7 @@ enum {
 	ALC897_FIXUP_UNIS_H3C_X500S,
 	ALC897_FIXUP_HEADSET_MIC_PIN3,
 	ALC662_FIXUP_CSL_GPIO,
+	ALC897_FIXUP_RAZER_BLADE_14,
 };
 
 static const struct hda_fixup alc662_fixups[] = {
@@ -782,6 +783,16 @@ static const struct hda_fixup alc662_fixups[] = {
 		.type = HDA_FIXUP_FUNC,
 		.v.func = alc662_fixup_csl_amp,
 	},
+	[ALC897_FIXUP_RAZER_BLADE_14] = {
+		.type = HDA_FIXUP_VERBS,
+		.v.verbs = (const struct hda_verb[]) {
+			/* Enable GPIO 0-2 for headphone amp */
+			{ 0x01, AC_VERB_SET_GPIO_MASK, 0x07 },
+			{ 0x01, AC_VERB_SET_GPIO_DIRECTION, 0x07 },
+			{ 0x01, AC_VERB_SET_GPIO_DATA, 0x07 },
+			{ }
+		},
+	},
 };
 
 static const struct hda_quirk alc662_fixup_tbl[] = {
@@ -846,6 +857,7 @@ static const struct hda_quirk alc662_fixup_tbl[] = {
 	SND_PCI_QUIRK(0x17aa, 0x3742, "Lenovo TianYi510Pro-14IOB", ALC897_FIXUP_HEADSET_MIC_PIN2),
 	SND_PCI_QUIRK(0x17aa, 0x38af, "Lenovo Ideapad Y550P", ALC662_FIXUP_IDEAPAD),
 	SND_PCI_QUIRK(0x17aa, 0x3a0d, "Lenovo Ideapad Y550", ALC662_FIXUP_IDEAPAD),
+	SND_PCI_QUIRK(0x1a58, 0x2014, "Razer Blade 14 (2021)", ALC897_FIXUP_RAZER_BLADE_14),
 	SND_PCI_QUIRK(0x1849, 0x5892, "ASRock B150M", ALC892_FIXUP_ASROCK_MOBO),
 	SND_PCI_QUIRK(0x19da, 0xa130, "Zotac Z68", ALC662_FIXUP_ZOTAC_Z68),
 	SND_PCI_QUIRK(0x1b0a, 0x01b8, "ACER Veriton", ALC662_FIXUP_ACER_VERITON),

---
base-commit: f43a4c2158239c8247f25758eea6cecfab90d98c
change-id: 20260417-for-next-204910ddb8ff

Best regards,
--  
Prasanna Raghavan <email2trprasanna@gmail.com>

