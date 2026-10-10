From: Federico Amedeo Izzo <federico@izzo.pro>
Date: Sat, 10 Oct 2026 12:24:43 +0200
Subject: [PATCH] ASoC: codecs: aw88261: expose hardware mute control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-aw88261-hardware-mute-v1-1-d0befedd3b4c@izzo.pro>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ6DMAyF4asgz1iKM7TAVSoGh7jFlaCVQwAJc
 fem7fa+4f0HJDGVBF11gMmqSV9zAdUVDCPPD0GNxeCdv5Ajh7w1TZk4ssWNTXDKi2B79RRbohC
 YoXzfJnfdf91b/3fK4SnD8o3BeX4Ast8XQnkAAAA=
X-Change-ID: 20261010-aw88261-hardware-mute-9721d911bbaa
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: Val Packett <val@packett.cool>, Luca Weiss <luca.weiss@fairphone.com>, 
 linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 Federico Amedeo Izzo <federico@izzo.pro>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791627905; l=2467;
 i=federico@izzo.pro; s=20251017; h=from:subject:message-id;
 bh=BYKelzy2Ps55yjmnOFm7JWNbifFBGV5GETpncVeWvFY=;
 b=M+g3tCFx03KoL5rCw3LD9LmwSCGb4Zrxy1QS/Fj6EbKtg09aENr05n7vFGwxaHl9dQIWtYpqj
 CaosaU6S4kuBIfsJn650s2XbgKkkuyWiCPNfdlFFZ+p1d7E1nQHd2d8
X-Developer-Key: i=federico@izzo.pro; a=ed25519;
 pk=XfmNfpH48k8jLbId5NKrp0yoKoFb/uLjr97qIxBImBw=
X-Endpoint-Received: by B4 Relay for federico@izzo.pro/20251017 with auth_id=544
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the aw88261 speaker volume is set to 0, it becomes very quiet but
still audible. This causes echo during phone calls on motorola-dubai, as
the bottom speaker output is getting picked up by the bottom microphone.

Expose the aw88261 hardware mute functionality as a Playback Switch
control. The new control can be used in a UCM profile to disable the
bottom speaker during phone calls and greatly reduce the echo.

Signed-off-by: Federico Amedeo Izzo <federico@izzo.pro>
---
 sound/soc/codecs/aw88261.c | 29 +++++++++++++++++++++++++++++
 1 file changed, 29 insertions(+)

diff --git a/sound/soc/codecs/aw88261.c b/sound/soc/codecs/aw88261.c
index 8671069f4c18..7303dc9eb4e0 100644
--- a/sound/soc/codecs/aw88261.c
+++ b/sound/soc/codecs/aw88261.c
@@ -1014,6 +1014,33 @@ static int aw88261_volume_set(struct snd_kcontrol *kcontrol,
 	return 0;
 }
 
+static int aw88261_mute_get(struct snd_kcontrol *kcontrol,
+				struct snd_ctl_elem_value *ucontrol)
+{
+	struct snd_soc_component *codec = snd_kcontrol_chip(kcontrol);
+	struct aw88261 *aw88261 = snd_soc_component_get_drvdata(codec);
+
+	ucontrol->value.integer.value[0] = !aw88261->mute_st;
+	return 0;
+}
+
+static int aw88261_mute_put(struct snd_kcontrol *kcontrol,
+				struct snd_ctl_elem_value *ucontrol)
+{
+	struct snd_soc_component *codec = snd_kcontrol_chip(kcontrol);
+	struct aw88261 *aw88261 = snd_soc_component_get_drvdata(codec);
+	bool mute = !ucontrol->value.integer.value[0];
+
+	if (aw88261->mute_st == mute)
+		return 0;
+
+	aw88261->mute_st = mute;
+	if (aw88261->aw_pa->status == AW88261_DEV_PW_ON)
+		aw88261_dev_mute(aw88261->aw_pa, mute);
+
+	return 1;
+}
+
 /*
  * The field contains 4 bits in units of 6dB + 6 bits in units of 0.125dB
  * which is too precise for TLV (!) so we have to multiply the scale by 2.
@@ -1026,6 +1053,8 @@ static const struct snd_kcontrol_new aw88261_controls[] = {
 	SOC_SINGLE_EXT_TLV("PCM Playback Volume", AW88261_SYSCTRL2_REG,
 		6, AW88261_CTL_MAX_VOL, 1,
 		aw88261_volume_get, aw88261_volume_set, volume_tlv),
+	SOC_SINGLE_EXT("Playback Switch", 0, 0, 1, 0,
+		aw88261_mute_get, aw88261_mute_put),
 	AW88261_PROFILE_EXT("Profile Set", aw88261_profile_info,
 		aw88261_profile_get, aw88261_profile_set),
 };

---
base-commit: becb95e45ef0dda9ffb35156d909d3da7a2789c3
change-id: 20261010-aw88261-hardware-mute-9721d911bbaa

Best regards,
--  
Federico Amedeo Izzo <federico@izzo.pro>

