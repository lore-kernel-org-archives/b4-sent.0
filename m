From: Ernst Persson <ernstp@gmail.com>
Date: Tue, 27 Oct 2026 07:13:44 +0100
Subject: [PATCH] ALSA: hda/realtek: Extend quirk for HP Pavilion All-in-One
 27-ca1xxx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-realtek-alc274-v1-1-c0eae15d0c55@gmail.com>
X-B4-Tracking: v=1; b=H4sIABhB4GoC/yXMwQ5EMBRG4VeRu54mdYPKvIrMourHNcKkRSTi3
 dVYfotzDgrwgkDv5CCPTYLMU0T6Ssj1duqgpIkm1lykmo3ysOOCr7KjY5MprXPLpWlLNI5i9PN
 oZf8Pq8/jsNYD3HJf6DwvyefPMXIAAAA=
X-Change-ID: 20261027-realtek-alc274-005a287f8edc
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 zhangheng@kylinos.cn, Ernst Persson <ernstp@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2032; i=ernstp@gmail.com;
 h=from:subject:message-id; bh=VjuNIrX9RVYCmjZADt89pdF/VDabfyZw4IScOGTvRZE=;
 b=owEBbQKS/ZANAwAKAfbNHl4MU4sXAcsmYgBq4EEnT1xsuGtL6oT5pZmYnZVxjc43epEUXcz8E
 6QOtx181QKJAjMEAAEKAB0WIQSoaWiqhDU91g8HVDb2zR5eDFOLFwUCauBBJwAKCRD2zR5eDFOL
 F8dAEACnnamrJQfV7VTVON4ycmgT8fHr4F+LIP5c4DD0x4oM+MzOB6VDYf42kLOFi8MEwpQuO78
 zJZMWMgZaI9L5b7LndK0gx5L+bQMdrx8/OQlykzO+Wu94BnCVZHUzrl13gfO5Xlj5ApM2ZGBqts
 D8ITzC4yrCbe4xcF+oFOVbV6jaRZJWtg+xOxfEt9zXTP+Zum7/XSMfMeOqXaBVHOi3AV5OnFz44
 AIP1PWyTT0pbSK5U6mn+WKeehUiXeAabHMZCwol2xv/5O2w2LtSOeGDgMkiKgTxn45DqrkoLU+E
 yjGUHXaZ2eOar0N7cJOurTMavJ01l/4dE+Nz47Lpy9Rbe3oYvbiW6MnSZoVRxk7IOl7k/k+lDzT
 IxTGi+1OHLFEvEvwllptAs8y1dVL3qatb1Zd16KcuMeTSmrtQu3uDJDAlDfYq/C6Z870dsRna48
 LzRfsd3FReMmc0R9v3PJUcs2xV2t4KW2BPJqGTaFDTCU6COzj7Q2gyzwZhVJ6DO8kd1hbWPrnF5
 GZioo37Qz7FFK6n81rgfGR2FNLRtlB9abD0CXRcpgBxi7ttAtd54TyY913Cr2qcvEk+i0An7UG3
 zIAoLZHZ5NsEY/E9NYjYum1BPZCPKvAJXp46xPqcJKd1NeluM5bk0w7VrOtG6Ln56aBfQM1zBc2
 zxs0xKSzlJmcrZA==
X-Developer-Key: i=ernstp@gmail.com; a=openpgp;
 fpr=002A73BE25C829CA09A174A229DAA1DAF1638E68
X-Endpoint-Received: by B4 Relay for ernstp@gmail.com/default with auth_id=1331
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A quirk was added in commit 704de5697008 ("ALSA: hda/realtek: Add quirk
for HP Pavilion All-in-One 27-ca1xxx")
Also enable the quirk for the actual 89e9 model named there.

Link: https://bugzilla.kernel.org/show_bug.cgi?id=216139
Signed-off-by: Ernst Persson <ernstp@gmail.com>
---
 sound/hda/codecs/realtek/alc269.c | 1 +
 sound/hda/controllers/intel.c     | 1 +
 2 files changed, 2 insertions(+)

diff --git a/sound/hda/codecs/realtek/alc269.c b/sound/hda/codecs/realtek/alc269.c
index 23aa175faedd..e198ce86ab4a 100644
--- a/sound/hda/codecs/realtek/alc269.c
+++ b/sound/hda/codecs/realtek/alc269.c
@@ -7869,6 +7869,7 @@ static const struct hda_quirk alc269_fixup_tbl[] = {
 	SND_PCI_QUIRK(0x103c, 0x8a4f, "HP Victus 15-fa0xxx (MB 8A4F)", ALC245_FIXUP_HP_MUTE_LED_COEFBIT),
 	SND_PCI_QUIRK(0x103c, 0x8a50, "HP Victus 15-fa0xxx (MB 8A50)", ALC245_FIXUP_HP_MUTE_LED_COEFBIT),
 	SND_PCI_QUIRK(0x103c, 0x8a6b, "HP Pavilion All-in-One Desktop 27-ca1xxx", ALC274_FIXUP_HP_VERBS),
+	SND_PCI_QUIRK(0x103c, 0x89e9, "HP Pavilion All-in-One Desktop 27-ca1xxx", ALC274_FIXUP_HP_VERBS),
 	SND_PCI_QUIRK(0x103c, 0x8a6e, "HP EDNA 360", ALC287_FIXUP_CS35L41_I2C_4),
 	SND_PCI_QUIRK(0x103c, 0x8a74, "HP ProBook 440 G8 Notebook PC", ALC236_FIXUP_HP_GPIO_LED),
 	SND_PCI_QUIRK(0x103c, 0x8a75, "HP ProBook 450 G8 Notebook PC", ALC236_FIXUP_HP_GPIO_LED),
diff --git a/sound/hda/controllers/intel.c b/sound/hda/controllers/intel.c
index 6b80b59b8743..95211952804e 100644
--- a/sound/hda/controllers/intel.c
+++ b/sound/hda/controllers/intel.c
@@ -2329,6 +2329,7 @@ static const struct snd_pci_quirk power_save_denylist[] = {
 	SND_PCI_QUIRK(0x17aa, 0x5079, "Lenovo Thinkpad E15", 0),
 	/* https://bugzilla.kernel.org/show_bug.cgi?id=220694 */
 	SND_PCI_QUIRK(0x103c, 0x8a6b, "HP 89E9", 0),
+	SND_PCI_QUIRK(0x103c, 0x89e9, "HP 89E9", 0),
 	{}
 };
 

---
base-commit: d135ab453a7400a34930bdda1ef4bdc8acfac80e
change-id: 20261027-realtek-alc274-005a287f8edc

Best regards,
--  
Ernst Persson <ernstp@gmail.com>

