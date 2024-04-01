From: Daniel Berlin <dberlin@dberlin.org>
Date: Mon, 01 Apr 2024 10:31:30 -0400
Subject: [PATCH] Add support for 2024 ROG Strix G634JZR
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240401-add-rog-strix-16-g634jzr-v1-1-ac396095409e@dberlin.org>
X-B4-Tracking: v=1; b=H4sIAEHFCmYC/x3MQQ5AMBBA0avIrE3SVkm4ilhUO2oskKmIEHfXW
 L7F/w8kEqYEXfGA0MmJtzVDlwX42a2RkEM2GGWsskqjCwFli5gO4Qt1g7Gp7HILtlTbVnkXvBk
 h57vQxNe/7of3/QAvzIPVagAAAA==
To: James Schulman <james.schulman@cirrus.com>, 
 David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: alsa-devel@alsa-project.org, patches@opensource.cirrus.com, 
 linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daniel Berlin <dberlin@dberlin.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711981912; l=1959;
 i=dberlin@dberlin.org; s=20231103; h=from:subject:message-id;
 bh=OkAb0mgem2LTUaEtI3QpWVORvUHuRQ4HTHDw+7mTmOo=;
 b=YVpBuS/DPGPSMIvGvxBHJw3haqM0JyxXizPd9bNmgUQrCczpAtLBPuXOb2U+cilk8c/JMCLHZ
 djiMPPPiofUCumZT2HN3Y3EM2dPYqLVSXN41TPEjDEE0IspYGoyAv1W
X-Developer-Key: i=dberlin@dberlin.org; a=ed25519;
 pk=cy2fotxgi42vqBilzDOe7Wq2+TsfMspPwg7pfE9Te+M=
X-Endpoint-Received: by B4 Relay for dberlin@dberlin.org/20231103 with auth_id=96
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The windows driver inf says it uses the exact same tunings and setup as the
older G634, and then reuses the data for ID 1043:1CAF.

We do the same here.
Tested on an actual laptop, sound works fine with this patch plus
default fallback firmware.

Signed-off-by: Daniel Berlin <dberlin@dberlin.org>
---
 sound/pci/hda/cs35l41_hda_property.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/sound/pci/hda/cs35l41_hda_property.c b/sound/pci/hda/cs35l41_hda_property.c
index 72ec872afb8d..25c117db3317 100644
--- a/sound/pci/hda/cs35l41_hda_property.c
+++ b/sound/pci/hda/cs35l41_hda_property.c
@@ -108,6 +108,7 @@ static const struct cs35l41_config cs35l41_config_table[] = {
 	{ "10431F12", 2, INTERNAL, { CS35L41_LEFT, CS35L41_RIGHT, 0, 0 }, 0, 1, -1, 1000, 4500, 24 },
 	{ "10431F1F", 2, EXTERNAL, { CS35L41_LEFT, CS35L41_RIGHT, 0, 0 }, 1, -1, 0, 0, 0, 0 },
 	{ "10431F62", 2, EXTERNAL, { CS35L41_LEFT, CS35L41_RIGHT, 0, 0 }, 1, 2, 0, 0, 0, 0 },
+	{ "10433A60", 2, INTERNAL, { CS35L41_LEFT, CS35L41_RIGHT, 0, 0 }, 1, 2, 0, 1000, 4500, 24 },
 	{ "17AA386F", 2, EXTERNAL, { CS35L41_LEFT, CS35L41_RIGHT, 0, 0 }, 0, -1, -1, 0, 0, 0 },
 	{ "17AA38A9", 2, EXTERNAL, { CS35L41_LEFT, CS35L41_RIGHT, 0, 0 }, 0, 2, -1, 0, 0, 0 },
 	{ "17AA38AB", 2, EXTERNAL, { CS35L41_LEFT, CS35L41_RIGHT, 0, 0 }, 0, 2, -1, 0, 0, 0 },
@@ -496,6 +497,7 @@ static const struct cs35l41_prop_model cs35l41_prop_model_table[] = {
 	{ "CSC3551", "10431F12", generic_dsd_config },
 	{ "CSC3551", "10431F1F", generic_dsd_config },
 	{ "CSC3551", "10431F62", generic_dsd_config },
+	{ "CSC3551", "10433A60", generic_dsd_config },
 	{ "CSC3551", "17AA386F", generic_dsd_config },
 	{ "CSC3551", "17AA38A9", generic_dsd_config },
 	{ "CSC3551", "17AA38AB", generic_dsd_config },

---
base-commit: 39cd87c4eb2b893354f3b850f916353f2658ae6f
change-id: 20240401-add-rog-strix-16-g634jzr-9e5490cadc2b

Best regards,
-- 
Daniel Berlin <dberlin@dberlin.org>

