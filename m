From: DelaySystem <DelaySystem@tubot.lat>
Date: Sat, 07 Nov 2026 21:04:40 -0800
Subject: [PATCH v2] media: ipu6: declare firmware files with
 MODULE_FIRMWARE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-batch1-s1-ipu6-fw-v2-1-0e8567a1aefa@tubot.lat>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NwQ6CMBBEf4Xs2TVsG0v05H8YDm1pZY0B0hbUk
 P67Be9mTi+ZebNCdIFdhEu1QnALRx6HAuJQge31cHfIXWEQtVBEdYNGJ9sTRkKeZoX+hZ0S3mu
 lpT0TlN0UnOf37ry1P46zeTibNtHW6DmmMXz204W23j//QljSnaSQ2vvGiGuazZiOT52gzTl/A
 TZpOXXEAAAA
X-Change-ID: 20261107-batch1-s1-ipu6-fw-d62ffa6a3c91
To: sakari.ailus@linux.intel.com
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 mchehab@kernel.org, DelaySystem <DelaySystem@tubot.lat>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1921; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=+GbCL4YspWticqNV8WYJ8X7lc408t7KsybFEoDp2+3U=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDFkfmF5MOxB/6aL/830JWZVTZ8Z/Kr17SCDdf1Yd2+vft
 W2re25s7ShlYRDjYJAVU2QRk+F5X39fJ87aas4JmDmsTCBDGLg4BWAicc8ZGa7s7H5yUcBnnuTX
 w/cceOW1Exh+n49xdw48mTmV/Z3ilmcM/51Py62prXxulpY38cPBv6e0X/K+DPg+O2Zj1iQDkyy
 XGkYA
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
DelaySystem <DelaySystem@tubot.lat>

