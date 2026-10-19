From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 18 Oct 2026 21:16:31 -0500
Subject: [PATCH] ALSA: hda/hdmi: Enable HBR capability
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-tegra-hda-hbr-v1-1-b8bb1f1d8d15@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0ML3ZLU9KJE3YwUIE4q0jU2NTQwNzK2SDIzslQC6ikoSk3LrACbFx1
 bWwsAJ3XdHV8AAAA=
X-Change-ID: 20261018-tegra-hda-hbr-35107238b629
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-sound@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792376192; l=2810;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=qFmrnBw4EOakmFV/4lcw6Dgrh0QXmQvGG5R48W8S4OE=;
 b=MCd4DdasK9WMbWfwoGf3K0UTwFYxA5dmqIglrh3xsaWwgcbDGBNU2Ad7l+/GenQhjuaP//OIq
 pukPE9DL1XFCKu3MBao0W0SYbLXq+zsQxA4wMx78qJxSeNcmkaGlxn4
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Tegra HDA does not set the HBR capability bit, however every SoC since
Tegra114 does support HBR. Override the hbr setup function for these
SoCs to unconditionally enable the feature. Since Tegra30 does not
support HBR, this function will report invalid on that SoC.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Before this, any attempt to open an hbr stream resulted in a rejection
on Tegra hardware. Looking at the downstream support, that just bypassed
the capbility check for all supported Tegra hardware in the common code.
This replicates that in a driver specific hook.

This has been tested on a SHIELD TV 2019 Pro trying to bitstream an
Atmos demo video. It attempts to play, but mostly just underruns the
entire time, with a few spurts of correct noise. My expectation is that
issue is userspace, since that is a WIP android audio hal. But even if
there are more kernel problems, this should be correct as a standalone
change.
---
 sound/hda/codecs/hdmi/tegrahdmi.c | 37 +++++++++++++++++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/sound/hda/codecs/hdmi/tegrahdmi.c b/sound/hda/codecs/hdmi/tegrahdmi.c
index ebb6410a48313..c4d8d8a570542 100644
--- a/sound/hda/codecs/hdmi/tegrahdmi.c
+++ b/sound/hda/codecs/hdmi/tegrahdmi.c
@@ -227,6 +227,41 @@ static int nvhdmi_chmap_validate(struct hdac_chmap *chmap,
 	return 0;
 }
 
+static int tegrahdmi_pin_hbr_setup(struct hda_codec *codec, hda_nid_t pin_nid,
+				   int dev_id, bool hbr)
+{
+	int pinctl, new_pinctl;
+
+	// Tegra 3 does not support HBR
+	if (codec->core.vendor_id == 0x10de0020)
+		return -EINVAL;
+
+	snd_hda_set_dev_select(codec, pin_nid, dev_id);
+	pinctl = snd_hda_codec_read(codec, pin_nid, 0,
+				    AC_VERB_GET_PIN_WIDGET_CONTROL, 0);
+
+	if (pinctl < 0)
+		return hbr ? -EINVAL : 0;
+
+	new_pinctl = pinctl & ~AC_PINCTL_EPT;
+	if (hbr)
+		new_pinctl |= AC_PINCTL_EPT_HBR;
+	else
+		new_pinctl |= AC_PINCTL_EPT_NATIVE;
+
+	codec_dbg(codec, "%s: NID=0x%x, %spinctl=0x%x\n",
+		    __func__, pin_nid,
+		    pinctl == new_pinctl ? "" : "new-",
+		    new_pinctl);
+
+	if (pinctl != new_pinctl)
+		snd_hda_codec_write(codec, pin_nid, 0,
+				    AC_VERB_SET_PIN_WIDGET_CONTROL,
+				    new_pinctl);
+
+	return 0;
+}
+
 static int tegra_hdmi_init(struct hda_codec *codec)
 {
 	struct hdmi_spec *spec = codec->spec;
@@ -255,6 +290,8 @@ static int tegra_hdmi_init(struct hda_codec *codec)
 	spec->chmap.ops.chmap_validate = nvhdmi_chmap_validate;
 	spec->nv_dp_workaround = true;
 
+	spec->ops.pin_hbr_setup = tegrahdmi_pin_hbr_setup;
+
 	return 0;
 }
 

---
base-commit: 2efb7a11f1aa4d2dc285fe2680cca22cb9f72f64
change-id: 20261018-tegra-hda-hbr-35107238b629

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

