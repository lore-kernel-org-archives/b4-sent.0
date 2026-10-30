From: Rodnei Cilto <rcilto1@lenovo.com>
Date: Fri, 30 Oct 2026 15:39:08 -0300
Subject: [PATCH] ASoC: amd: yc: Add DMI quirk for Lenovo V15 AMN G6
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-ideapad-mic-support-v1-1-7677371af384@lenovo.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBBA0avIrDVpCRFXEYvqDEaCpoNIxN0Vy
 7f4/wKhwCRQJxcEOlh4XSJMmoAb7TKQYoyGTGel0bmOJOstqpmdkt37NWwKy6JCxK4yhYVY+kA
 9n9+1aX/L3k3ktncF9/0AgjSgDHcAAAA=
X-Change-ID: 20261030-ideapad-mic-support-d658dddb815a
To: Vijendar Mukunda <Vijendar.Mukunda@amd.com>, 
 Venkata Prasad Potturu <venkataprasad.potturu@amd.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Rodnei Cilto <rcilto1@lenovo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793385554; l=1565;
 i=rcilto1@lenovo.com; s=20261030; h=from:subject:message-id;
 bh=ngSYT+Mjnj1bJD7gv/LtVb+GccB+Gm/tJ1Kvc5e3BMg=;
 b=2LxSq+RHIcA8dEoRez96sR+lFpsXGWYD38N80aDf5NYq9RcM3X7aadQQi7UKBAbo2Ltf806IB
 Hl42ySeSi89CXE6e4axzxavYCBQWy90xkrzukZ6B4+hBLzdUSJYqI6d
X-Developer-Key: i=rcilto1@lenovo.com; a=ed25519;
 pk=6PTykaxM+bmmv9zzOdlotAPqQJMtcwF9npDR/4gLHaA=
X-Endpoint-Received: by B4 Relay for rcilto1@lenovo.com/20261030 with auth_id=1365
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Lenovo V15 AMN G6 (product name 83VD and 84CS) uses the ACP6x PDM
interface for its internal digital microphone array.

Its firmware exposes neither the AcpDmicConnected _DSD property
nor the _WOV method, causing acp6x_probe() to fall through to
the DMI check and return -ENODEV. As a result, acp_yc_mach.0
is not bound and no capture device is registered.

Add a DMI quirk entry for this model. With it, the machine
driver binds correctly and the DMIC capture device becomes
available.

Capture was verified working with arecord and PipeWire.

Signed-off-by: Rodnei Cilto <rcilto1@lenovo.com>
---
 sound/soc/amd/yc/acp6x-mach.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/sound/soc/amd/yc/acp6x-mach.c b/sound/soc/amd/yc/acp6x-mach.c
index 41f8c0885865..fc648590409a 100644
--- a/sound/soc/amd/yc/acp6x-mach.c
+++ b/sound/soc/amd/yc/acp6x-mach.c
@@ -395,6 +395,20 @@ static const struct dmi_system_id yc_acp_quirk_table[] = {
 			DMI_MATCH(DMI_PRODUCT_NAME, "83UU"),
 		}
 	},
+	{
+		.driver_data = &acp6x_card,
+		.matches = {
+			DMI_MATCH(DMI_BOARD_VENDOR, "LENOVO"),
+			DMI_MATCH(DMI_PRODUCT_NAME, "84CS"),
+		}
+	},
+	{
+		.driver_data = &acp6x_card,
+		.matches = {
+			DMI_MATCH(DMI_BOARD_VENDOR, "LENOVO"),
+			DMI_MATCH(DMI_PRODUCT_NAME, "83VD"),
+		}
+	},
 	{
 		.driver_data = &acp6x_card,
 		.matches = {

---
base-commit: d89e1d186ec9271bf78e62771779e9fc03bf0fc3
change-id: 20261030-ideapad-mic-support-d658dddb815a

Best regards,
--  
Rodnei Cilto <rcilto1@lenovo.com>

