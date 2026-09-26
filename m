From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 26 Sep 2026 02:24:19 -0500
Subject: [PATCH] ALSA: hda/tegra: Re-enable SDO workaround for Tegra194
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260926-tegra194-hda-sdo-v1-1-f7a636a07a58@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avIrBtQKdGuEi1Ep5qNhkYE4d2Tl
 m/x/wuVClOFWbxQ6ObKOXWoQUA4fNoJOXaDltpIpw1etBev3IhH9FhjRhXtGIy0k3IWenYW2vj
 5l8va2gf4fpxUYgAAAA==
X-Change-ID: 20260926-tegra194-hda-sdo-1d84c6085198
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Thierry Reding <treding@nvidia.com>, linux-sound@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790407469; l=1584;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=8rAycl98UAJVNpg4nxLeFSEwU8WePutSW40I7utV8vY=;
 b=jpT6mRhj6kFaT03vLb78Ga/cCq4a5oFDhA6+ifoHcGRLo0Q1WygeZdjkILrQ2wRqTUOIgSoJj
 ur/C6Ic/N/jCoPadVejJRrh2MNXBWbwY9PtMqbgCOK/Yg6KbL8H5cHw
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This workaround was originally added for Tegra194, but no longer gets
applied for it. Commit 615d43540043 ("ALSA: hda/tegra: fix tegra-hda on
tegra30 soc") changed the guard to tegra30-hda, which worked because all
affected archs had the fallback compatible. However, commit 7f0ea5acfc19
("arm64: tegra: Use correct compatible string for Tegra194 HDA") removed
the fallback compatible for Tegra194, causing this to break.

Fixes: 7f0ea5acfc19 ("arm64: tegra: Use correct compatible string for Tegra194 HDA")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
ALSA: hda/tegra: Re-enable SDO workaround for Tegra194
---
 sound/hda/controllers/tegra.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/sound/hda/controllers/tegra.c b/sound/hda/controllers/tegra.c
index 31c14c4bbe683..674cc0f79c3c8 100644
--- a/sound/hda/controllers/tegra.c
+++ b/sound/hda/controllers/tegra.c
@@ -374,7 +374,8 @@ static int hda_tegra_first_init(struct azx *chip, struct platform_device *pdev)
 	 * in powers of 2, next available ratio is 16 which can be
 	 * used as a limiting factor here.
 	 */
-	if (of_device_is_compatible(np, "nvidia,tegra30-hda"))
+	if (of_device_is_compatible(np, "nvidia,tegra30-hda") ||
+	    of_device_is_compatible(np, "nvidia,tegra194-hda"))
 		chip->bus.core.sdo_limit = 16;
 
 	/* codec detection */

---
base-commit: 4c253ac4b29b8c6cc6fdef8f92d4facde62e63b9
change-id: 20260926-tegra194-hda-sdo-1d84c6085198

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

