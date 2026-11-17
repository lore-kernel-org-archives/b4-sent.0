From: Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
Date: Tue, 17 Nov 2026 15:50:36 -0800
Subject: [PATCH v3] media: ipu6: declare firmware files with
 MODULE_FIRMWARE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-batch1-s1-ipu6-fw-v3-1-fa82baa8a94e@tubot.lat>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XNQQ7CIBAF0Ks0rMV0IKXqynsYFwMdLMbYBihqm
 t5dqBtXmln95P83MwvkHQV2qGbmKbnghnsOclMx0+P9Qtx1OTNRCwVQt1xjND3wANyNk+L2wTs
 lrEWF0uyB5d3oybrnap7OnxwmfSUTC1QavQtx8K/1aYLS++Un4Pm6RgqJ1rZaHOOkh7i9YWTFT
 +KvILJQ065RLQKSxW9hWZY3WZNtwgYBAAA=
X-Change-ID: 20261107-batch1-s1-ipu6-fw-d62ffa6a3c91
To: sakari.ailus@linux.intel.com
Cc: linux-kernel@vger.kernel.org, linux-media@vger.kernel.org, lsa.uz@pm.me, 
 mchehab@kernel.org, Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2273; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=usCgb43Tza/ZYUcfTrOovdSpxv/fAJbVp5Ig2JIdzbk=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDFl/XngrL+upDX/WtKcq7OcNton/NJPWXpRL8ljVqCeyl
 L9LT9Klo5SFQYyDQVZMkUVMhud9/X2dOGurOSdg5rAygQxh4OIUgIkIGzIynNeRLAn+efh8eIT4
 Yam0+dsOXRGdl2bO2pgQaxdwv8ZwG8MfziOvU9NOvjyj+D4rbldERaef+C99Lf/ITeXeO9LLlnz
 mBQA=
X-Developer-Key: i=DelaySystem@tubot.lat; a=openpgp;
 fpr=161C0CEF7FDF2C5E3B3A9CC8E22333A79A058D4B
X-Endpoint-Received: by B4 Relay for DelaySystem@tubot.lat/default with auth_id=1447
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver requests one of eight firmware blobs at runtime depending on
the detected SoC (IPU6, IPU6SE, IPU6EP, IPU6EPADLN, IPU6EPMTL, IPU7,
IPU7P5 or IPU8), selected through isp->cpd_fw_name, but never declares
them.  As a result modinfo shows no firmware: lines and initramfs
generators cannot pick up the dependency automatically.

Add MODULE_FIRMWARE() for every blob the driver can request.

Suggested-by: Sakari Ailus <sakari.ailus@linux.intel.com>
Link: https://lore.kernel.org/all/apqB28RBDZV4BlDZ@kekkonen.localdomain/
Tested-by: Sergey Lebedev <lsa.uz@pm.me> # Surface Pro 11, IPU7
Signed-off-by: Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
---
Changes in v3:
- Resend under my real name (From/Signed-off-by: Maximo Manriquez Lizarraga).
- Fold in Tested-by from Sergey Lebedev (Surface Pro 11, IPU7).
- Link to v2: https://patch.msgid.link/20261107-batch1-s1-ipu6-fw-v2-1-0e8567a1aefa@tubot.lat

Changes in v2:
- Resend with corrected Cc list (v1 accidentally reached only Sakari and linux-kernel: repeated --cc flags do not accumulate in b4); no code change.
- Adds linux-media@vger.kernel.org and Mauro Carvalho Chehab to Cc.
- Link to v1: https://patch.msgid.link/20261107-batch1-s1-ipu6-fw-v1-1-1d5323aff7b2@tubot.lat
---
 drivers/media/pci/intel/ipu6/ipu6.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/media/pci/intel/ipu6/ipu6.c b/drivers/media/pci/intel/ipu6/ipu6.c
index cdf812c02960..ec2a9c2bf587 100644
--- a/drivers/media/pci/intel/ipu6/ipu6.c
+++ b/drivers/media/pci/intel/ipu6/ipu6.c
@@ -1028,3 +1028,11 @@ MODULE_AUTHOR("Yunliang Ding <yunliang.ding@intel.com>");
 MODULE_AUTHOR("Hongju Wang");
 MODULE_LICENSE("GPL");
 MODULE_DESCRIPTION("Intel IPU6 PCI driver");
+MODULE_FIRMWARE(IPU6SE_FIRMWARE_NAME);
+MODULE_FIRMWARE(IPU6EP_FIRMWARE_NAME);
+MODULE_FIRMWARE(IPU6_FIRMWARE_NAME);
+MODULE_FIRMWARE(IPU6EPMTL_FIRMWARE_NAME);
+MODULE_FIRMWARE(IPU6EPADLN_FIRMWARE_NAME);
+MODULE_FIRMWARE(IPU7_FIRMWARE_NAME);
+MODULE_FIRMWARE(IPU7P5_FIRMWARE_NAME);
+MODULE_FIRMWARE(IPU8_FIRMWARE_NAME);

---
base-commit: fa4ad798f6f681031775266044ba1b0cf3c670bd
change-id: 20261107-batch1-s1-ipu6-fw-d62ffa6a3c91

Best regards,
--  
Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>

