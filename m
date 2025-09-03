From: =?utf-8?q?Christian_Thie=C3=9Fen?= <christian.thiessen@airbus.com>
Date: Wed, 03 Sep 2025 16:31:21 +0200
Subject: [PATCH v2] mtd: Make mtd_erase fail gracefully if CONFIG_MTD_WRITE
 is off
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250903-mtd-erase-enosys-v2-1-7b7f28302f25@airbus.com>
X-B4-Tracking: v=1; b=H4sIADhRuGgC/2WNQQ6CMBBFr0Jm7Zi2ggVX3sOwKGWUWUBNB4mE9
 O5WElcu30v++xsIRSaBS7FBpIWFw5TBHArwg5sehNxnBqNMpRplcJx7pOiEkKYgq6Dpa0Vl563
 1NeTZM9Kd33vy1mYeWOYQ1/1h0V/7i53+Y4tGjc3ZuqbS1viSro5j95KjDyO0KaUPjitzG7EAA
 AA=
X-Change-ID: 20250902-mtd-erase-enosys-2d80e4bc77c8
To: BAREBOX <barebox@lists.infradead.org>
Cc: Ahmad Fatoum <a.fatoum@pengutronix.de>, 
 =?utf-8?q?Christian_Thie=C3=9Fen?= <christian.thiessen@airbus.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756909883; l=1789;
 i=christian.thiessen@airbus.com; s=20250902; h=from:subject:message-id;
 bh=emJT9PXfX11+EmeT0CfeZS06OR+auBfkOIiI8W3unJc=;
 b=I4F1s14f5xx2CiThPY90cnC4PurebN3mVrIYCZVDBNZfScKVjgo+hfhRKqEHxLKD8MhktAXKu
 Q/RgUrXg3LSDEqIqKgKlvWNvELSjeJ7j76PqvCcf6mNePg0z+YUUAPR
X-Developer-Key: i=christian.thiessen@airbus.com; a=ed25519;
 pk=NCvzeydU+5OZKp2shtC3Zp/OS1LfbLmhNZNws46FeWk=
X-Endpoint-Received: by B4 Relay for christian.thiessen@airbus.com/20250902 with auth_id=508
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When CONFIG_MTD_WRITE is unset, the mtd->_erase member of partition
devices does not get initialized, so it remains NULL.
However when running ubiattach on an UBI partition, mtd_erase() still
gets called, tries to call mtd->_erase and crashes. Make it fail
gracefully by returning ENOSYS ("Function not implemented") instead.

Reviewed-by: Ahmad Fatoum <a.fatoum@pengutronix.de>
Signed-off-by: Christian Thießen <christian.thiessen@airbus.com>
---
As discussed in https://github.com/barebox/barebox/issues/39 this patch
enables ubiattach-ing a NAND partition even if CONFIG_MTD_WRITE is
turned off, by making mtd_erase fail gracefully.
---
Hi,
thank you for the warm welcome and the constructive feedback!
Changes in v2: Addressed review comments.
- Changed from ifdef to IS_ENABLED
- Moved the sign-off tag to the commit message (why does b4 add it to
  the cover letter?)
- Link to v1: https://lore.kernel.org/r/20250903-mtd-erase-enosys-v1-1-967a95172c4e@airbus.com
---
 drivers/mtd/core.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/mtd/core.c b/drivers/mtd/core.c
index 6162ec450fc1c3a0fa6339042c4d627e0f9567d0..bb579a8f5249981ec1623060ddb1b7056a06c1a0 100644
--- a/drivers/mtd/core.c
+++ b/drivers/mtd/core.c
@@ -436,6 +436,8 @@ int mtd_erase(struct mtd_info *mtd, struct erase_info *instr)
 {
 	if (instr->addr >= mtd->size || instr->len > mtd->size - instr->addr)
 		return -EINVAL;
+	if (!IS_ENABLED(CONFIG_MTD_WRITE))
+		return -ENOSYS;
 	if (!(mtd->flags & MTD_WRITEABLE))
 		return -EROFS;
 	instr->fail_addr = MTD_FAIL_ADDR_UNKNOWN;

---
base-commit: b5561f3bdd4845b478e5b35aab04f1d8e71ea93b
change-id: 20250902-mtd-erase-enosys-2d80e4bc77c8

Best regards,
-- 
Christian Thießen <christian.thiessen@airbus.com>

