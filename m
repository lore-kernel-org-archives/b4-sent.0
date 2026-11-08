From: DelaySystem <DelaySystem@tubot.lat>
Date: Sat, 07 Nov 2026 21:03:55 -0800
Subject: [PATCH] media: ipu6: declare firmware files with MODULE_FIRMWARE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-batch1-s1-ipu6-fw-v1-1-1d5323aff7b2@tubot.lat>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqEMAxA4atI1gZMhYpeZXBRa6pxodL4B+Ld7
 cwsv8V7NyhHYYUmuyHyISrLnEB5Bn5088AofTKYwliiosLObX4kVEJZd4vhxN6aEJx1pa8JUrd
 GDnL9np/2b927if32HcHzvKX6zLd1AAAA
X-Change-ID: 20261107-batch1-s1-ipu6-fw-d62ffa6a3c91
To: sakari.ailus@linux.intel.com
Cc: linux-kernel@vger.kernel.org, DelaySystem <DelaySystem@tubot.lat>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1586; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=JVZ6MoRJlfn70hECkm/g+rCgcAl0la+JGGIypLxaXEs=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDFkfmHalaE08JBftXu23M8ZizcKvLd8c1BuVZ8/+oyxg/
 jQ780VORykLgxgHg6yYIouYDM/7+vs6cdZWc07AzGFlAhnCwMUpABNRjmdkWFtTN7Fpl4fVoqs9
 BnueNfzemzmBe7+ikHeHxMycSe++OjD8Yrat0Pj8/KLAvTrVX3GHStKSX2nLX5HKD1J9ZBb1+uB
 2FgA=
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
Signed-off-by: DelaySystem <DelaySystem@tubot.lat>
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
DelaySystem <DelaySystem@tubot.lat>

