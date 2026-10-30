From: Alessandro Petrozzelli <apetrozzelli@gmail.com>
Date: Sat, 31 Oct 2026 00:57:36 +0100
Subject: [PATCH wireless-next] wifi: rt2x00: rt2800lib: fallback to default
 RF config when EEPROM_NIC_CONF0 is 0x0000
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-fix-rt2800-eeprom-nic-conf0-zero-v1-1-a118ee775fcb@gmail.com>
X-B4-Tracking: v=1; b=H4sIAO8u5WoC/yWNQQrCMBBFr1Jm7cAkQgheRVzUZKIjmpRJqsXSu
 xt1+fj891aorMIVDsMKyk+pUnIHsxsgXMd8YZTYGSxZZ2hvMMmC2qwnQuZJywOzBAwlJ8I3a8E
 xJO+TizE6gq6ZlPvnlzjCS5TvXCtmXhqc/nOdzzcO7ZuBbfsA3K2+U5MAAAA=
X-Change-ID: 20261031-fix-rt2800-eeprom-nic-conf0-zero-acf88f6ddd60
To: Stanislaw Gruszka <stf_xl@wp.pl>, 
 Johannes Berg <johannes@sipsolutions.net>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alessandro Petrozzelli <apetrozzelli@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2104;
 i=apetrozzelli@gmail.com; h=from:subject:message-id;
 bh=pnGNieAmqP5yjIcLc5cLxsweQychWUXH4HwSO++3Q88=;
 b=owEBbQKS/ZANAwAKAeWL0WdUYlOYAcsmYgBq5S7vWn4nbiRcMvaqp7EBX+ss33CIwrO2HUe/T
 h2jFTDGzTuJAjMEAAEKAB0WIQRWwqGiWlKpzW9/svzli9FnVGJTmAUCauUu7wAKCRDli9FnVGJT
 mBdED/9zrG+b/kXudUEdQEzyWBsqeX5A8CLKQffEcyJbIXZ377ujdJSn+slF/duO2lK+t/ezl0j
 HJmq/mfblroGPK1Fi8oqVStcyb2oy0TjcjtCH6tcndFu8tEbHKoJauSfHaVaDxVBPI/cGGCvUxw
 7hRPKkGrZa1vN7+2lNItzTEFZ63ruXKyF8tQfhbJm2nH1DCObCeXpd0v9rQTRSbMMUN/wZz2yOZ
 pXi0kTkpFI3Yu6pAmizOpL2rd63CXnwCloYIhhvMjTknimowjSEptJzv2WK3NcV2ZmJ9Oy46sky
 a6VpYKId1GYhV5RG2zzcfLCRTdwjoJKX25iSehmXQGDUWJ1ZnLuNtwN+NJtYikEp03ifn6Lly3N
 8iF/NxIiGif5hXAZQffJMpQC/Ove1xY4G05nITD32LcsQcS1OBSTGvfvynDzwYyGwEaMy8ZMuSQ
 ylFFKvPX6FyBULTIVnBM4josv2srr/GUxHb19brtpQh1NmMgBHL/YmciHR2MPhODsthauZbAIb6
 nDMXNrnTlBG9Owo86IozepfohFYpOE2Zv36I9P+t6KG+pLRHwfGqovoMPhD5r9JITrxCX0ZOaxv
 ZeoaH5OadjfyFo77gkpiXIMKiqqC8FYVyovlUCf68Ybg1FUCqTKlL1TPa5NAPziwERqWaL4EFRt
 Ose45R/z35s7cOQ==
X-Developer-Key: i=apetrozzelli@gmail.com; a=openpgp;
 fpr=56C2A1A25A52A9CD6F7FB2FCE58BD16754625398
X-Endpoint-Received: by B4 Relay for apetrozzelli@gmail.com/default with auth_id=1366
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On some Ralink PCI/PCIe wireless cards, such as the AzureWave AW-NE766
(Ralink RT2790 / RT2872, PCI ID 1814:0781, subsystem 1814:2790) bundled
in the ASUS EeeBox PC B202, reading EEPROM_NIC_CONF0 returns 0x0000
instead of 0xffff when the EEPROM word is uninitialized.

Currently, rt2800_validate_eeprom() only triggers the default RF2820
(1T2R) configuration fallback when EEPROM_NIC_CONF0 is 0xffff, unlike
other EEPROM validation checks in the same function (such as LNA gain
fields) which already check for both 0x00 and 0xff. As a result,
EEPROM_NIC_CONF0_RF_TYPE remains 0x0000 and rt2800_init_eeprom() aborts
device initialization with -ENODEV:

  rt2x00_set_rt: Info - RT chipset 2872, rev 0200 detected
  rt2800_init_eeprom: Error - Invalid RF chipset 0x0000 detected
  rt2x00lib_probe_dev: Error - Failed to allocate device

Since 0x0000 is never a valid RF_TYPE (valid chipsets start at
RF2820 = 0x0001), extend the EEPROM_NIC_CONF0 fallback check to also
handle 0x0000 so that these cards initialize and operate properly.

Signed-off-by: Alessandro Petrozzelli <apetrozzelli@gmail.com>
---
 drivers/net/wireless/ralink/rt2x00/rt2800lib.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/wireless/ralink/rt2x00/rt2800lib.c b/drivers/net/wireless/ralink/rt2x00/rt2800lib.c
index 2e2e382b6..dda5ba2ad 100644
--- a/drivers/net/wireless/ralink/rt2x00/rt2800lib.c
+++ b/drivers/net/wireless/ralink/rt2x00/rt2800lib.c
@@ -11047,7 +11047,7 @@ static int rt2800_validate_eeprom(struct rt2x00_dev *rt2x00dev)
 		return retval;
 
 	word = rt2800_eeprom_read(rt2x00dev, EEPROM_NIC_CONF0);
-	if (word == 0xffff) {
+	if (word == 0xffff || word == 0x0000) {
 		rt2x00_set_field16(&word, EEPROM_NIC_CONF0_RXPATH, 2);
 		rt2x00_set_field16(&word, EEPROM_NIC_CONF0_TXPATH, 1);
 		rt2x00_set_field16(&word, EEPROM_NIC_CONF0_RF_TYPE, RF2820);

---
base-commit: 2c50cd5d10e8723797f28c7978f1f61688e0c0d2
change-id: 20261031-fix-rt2800-eeprom-nic-conf0-zero-acf88f6ddd60

Best regards,
--  
Alessandro Petrozzelli <apetrozzelli@gmail.com>

