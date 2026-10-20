From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 20 Oct 2026 03:18:14 -0500
Subject: [PATCH v2] ALSA: hda/hdmi: Enable HBR capability
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-tegra-hda-hbr-v2-1-6968017f585b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WMQQ7CIBBFr9LMWgxD04quvIfpopQpTGKLgYZoG
 u4udu/iL95P3tshUWRKcGt2iJQ5cVgrqFMDkx9XR4JtZVBS9ShRi41cHIW3dSaKtkN5Ua02vbp
 CdV6RZn4fvcdQ2XPaQvwc+Yy/918po0BhtDE4o9UWu7tbRn6ep7DAUEr5AmwhUV2qAAAA
X-Change-ID: 20261018-tegra-hda-hbr-35107238b629
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-sound@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792484297; l=3023;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=ABJMYi6wtZe91Rymkn3xsq8E4KBzp1tYt+2VfPsra24=;
 b=bVoDPBipwOi09/R8hJx5+RRUGyN1s4FqNUs/cHVBhOrpt7uE3YJMMs1kkqY9IGev/7PPJCVqa
 la2qswWv3J8BEprLp9mFGz/S21e4zprgHMd8qj8YTXuBb6w/5BUWl1A
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Tegra HDA does not set the HBR capability bit, however every SoC since
Tegra114 does support HBR. Override the hbr setup function for these
SoCs to unconditionally enable the feature. Since Tegra30 does not
support HBR, this override will not be applied.

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
Changes in v2:
- As suggested by Takashi, just don't apply the override for unsupported
  SoCs instead of trying to replicate the unsupported path.
- Link to v1: https://lore.kernel.org/r/20261018-tegra-hda-hbr-v1-1-b8bb1f1d8d15@gmail.com
---
 sound/hda/codecs/hdmi/tegrahdmi.c | 35 +++++++++++++++++++++++++++++++++++
 1 file changed, 35 insertions(+)

diff --git a/sound/hda/codecs/hdmi/tegrahdmi.c b/sound/hda/codecs/hdmi/tegrahdmi.c
index ebb6410a48313..171d1ee154d9c 100644
--- a/sound/hda/codecs/hdmi/tegrahdmi.c
+++ b/sound/hda/codecs/hdmi/tegrahdmi.c
@@ -227,6 +227,37 @@ static int nvhdmi_chmap_validate(struct hdac_chmap *chmap,
 	return 0;
 }
 
+static int tegrahdmi_pin_hbr_setup(struct hda_codec *codec, hda_nid_t pin_nid,
+				   int dev_id, bool hbr)
+{
+	int pinctl, new_pinctl;
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
@@ -255,6 +286,10 @@ static int tegra_hdmi_init(struct hda_codec *codec)
 	spec->chmap.ops.chmap_validate = nvhdmi_chmap_validate;
 	spec->nv_dp_workaround = true;
 
+	// Tegra 3 does not support HBR
+	if (codec->core.vendor_id != 0x10de0020)
+		spec->ops.pin_hbr_setup = tegrahdmi_pin_hbr_setup;
+
 	return 0;
 }
 

---
base-commit: 2efb7a11f1aa4d2dc285fe2680cca22cb9f72f64
change-id: 20261018-tegra-hda-hbr-35107238b629

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

