From: =?utf-8?q?Christian_Thie=C3=9Fen?= <christian.thiessen@airbus.com>
Date: Wed, 03 Sep 2025 10:49:41 +0200
Subject: [PATCH] mtd: Make mtd_erase fail gracefully if CONFIG_MTD_WRITE is
 off
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250903-mtd-erase-enosys-v1-1-967a95172c4e@airbus.com>
X-B4-Tracking: v=1; b=H4sIACQBuGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDSwMj3dySFN3UosTiVN3UvPziymJdoxQLg1STpGRz82QLJaC2gqLUtMw
 KsJHRsbW1ACHdSEViAAAA
X-Change-ID: 20250902-mtd-erase-enosys-2d80e4bc77c8
To: BAREBOX <barebox@lists.infradead.org>
Cc: =?utf-8?q?Christian_Thie=C3=9Fen?= <christian.thiessen@airbus.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756889391; l=1624;
 i=christian.thiessen@airbus.com; s=20250902; h=from:subject:message-id;
 bh=4QnaLa8ImGaHF9cT+Hdr3X2rr4xAoEVL/kTlt4wW/5o=;
 b=GEClXZbYMcm2g8wWRwNxPGKvDyigmJM1PtzW8VxfS69osKhicGENjbJn5mgVJFpHB6VrLCEaB
 HT8Z+XSFZ0NAczbComRqdZ7q7bh8Wby9FIodocXG2dYbCFhY2ZrKSgL
X-Developer-Key: i=christian.thiessen@airbus.com; a=ed25519;
 pk=NCvzeydU+5OZKp2shtC3Zp/OS1LfbLmhNZNws46FeWk=
X-Endpoint-Received: by B4 Relay for christian.thiessen@airbus.com/20250902 with auth_id=508
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When CONFIG_MTD_WRITE is unset, the mtd->_erase member of partition
devices does not get initialized, so it remains NULL.
However when running ubiattach on an UBI partition, mtd_erase() still
gets called, tries to call mtd->_erase and crashes. Make it fail
gracefully by returning ENOSYS ("Function not implemented") instead.

---
As discussed in https://github.com/barebox/barebox/issues/39 this patch
enables ubiattach-ing a NAND partition even if CONFIG_MTD_WRITE is
turned off, by making mtd_erase fail gracefully.

Signed-off-by: Christian Thießen <christian.thiessen@airbus.com>
---
 drivers/mtd/core.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/mtd/core.c b/drivers/mtd/core.c
index 6162ec450fc1c3a0fa6339042c4d627e0f9567d0..7ca8fc900af4666070b03ef5f945748d60e6a6e7 100644
--- a/drivers/mtd/core.c
+++ b/drivers/mtd/core.c
@@ -436,6 +436,7 @@ int mtd_erase(struct mtd_info *mtd, struct erase_info *instr)
 {
 	if (instr->addr >= mtd->size || instr->len > mtd->size - instr->addr)
 		return -EINVAL;
+#ifdef CONFIG_MTD_WRITE
 	if (!(mtd->flags & MTD_WRITEABLE))
 		return -EROFS;
 	instr->fail_addr = MTD_FAIL_ADDR_UNKNOWN;
@@ -443,6 +444,9 @@ int mtd_erase(struct mtd_info *mtd, struct erase_info *instr)
 		return 0;
 
 	return mtd->_erase(mtd, instr);
+#else
+	return -ENOSYS;
+#endif
 }
 
 int mtd_read_oob(struct mtd_info *mtd, loff_t from, struct mtd_oob_ops *ops)

---
base-commit: b5561f3bdd4845b478e5b35aab04f1d8e71ea93b
change-id: 20250902-mtd-erase-enosys-2d80e4bc77c8

Best regards,
-- 
Christian Thießen <christian.thiessen@airbus.com>

