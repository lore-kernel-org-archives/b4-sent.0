From: David Heidelberg <david@ixit.cz>
Date: Sat, 18 Oct 2025 14:22:57 +0200
Subject: [PATCH RESEND v3] ARM: multi_v7_defconfig add /proc/config.gz
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251018-arm-config_gz-v3-1-0de1eaadd902@ixit.cz>
To: Russell King <linux@armlinux.org.uk>, Ard Biesheuvel <ardb@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1307; i=david@ixit.cz;
 h=from:subject:message-id; bh=7w/aD3shZMm8S2nIaaI4q8HkXYxgH0I/7K7GWxdOw78=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo84bFUXDf8xi9WnUPm10TJ71uwk3sxLZfjtFB7
 7FAxgH5IhyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPOGxQAKCRBgAj/E00kg
 cnI2D/0b15ZI37jdYTKlxu1rONqBTQJqsCCYgB4N+sRazVYVxyDoZxqZcZmw2Ls4Z6MUKQFOBRX
 a6BwkeYJTBwlJaDlSCtshtC1A8U9C/EkE/jeSdq4r65VvLyzj+ylhae63OfyxgH3wQrQkSZiWA8
 GEklNbawfl6PkdyfhyyUBFLTyjZgOGhTR1wdUjxbJUAidi0OZ798Blv/wUH0VfbglODF/HU87Cy
 aGHfrMa1GwjNoRNI8gIpl6zxFkipgAVMcu37/0JN45Lfdho3aGHXxls5MZA1G7vqm76LhVDQB4S
 8cc4LAirydGL2R9ivYJg4cup/qhu4LkzZ4tRvcrYk7NSMyIBucNedkkI8oe3l97Sg0QSZDpIOeU
 8ehTx7k/QpesIq/THLaPKzUvc0ZeoBylpCRHek7fnD72JyR0jliygGRqp7mEjBRhjRXPiUzWG8B
 PgLOBEQH75vO8dWS/9Q90s54WhYwoBmWbMuZzREaDYTNpZZ6XqjU6vMG6nrYd/ujI2SCNlRNSXH
 aLFIH6j6OUaYufulfD/V47ISvzjG77ylfMv8ztra4V1jolTNPVfj7B+KKemnIDInheSLYJTmS1x
 SK18W7VppaC3qAvGj85OJtYl+Qvr95Ou/hWcPLlQrcO9NEdbPFeLz/li9E6TAiybwCsMLfAQI6C
 pr9wSSHm7N6tXDQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While 32-bit ARM isn't that widespread, multi_v7_defconfig is used for
building more generic images, where having access to config can be handy.

arm64 and x86_64 already bundle config.gz, so this is an effort to provide
the same level of comfort with ARMv7 devices.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Rebased against next-20250715; otherwise, just a resend.
- Link to v2: https://lore.kernel.org/r/20250329-arm-config_gz-v2-1-f725d331fb5d@ixit.cz

Changes in v2:
- IKCONFIG is now module instead of built-in (Greg).
- Link to v1: https://lore.kernel.org/r/20230612210208.109267-1-david@ixit.cz
---
 arch/arm/configs/multi_v7_defconfig | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm/configs/multi_v7_defconfig b/arch/arm/configs/multi_v7_defconfig
index 65df4014c4a60..5180c90cb5da1 100644
--- a/arch/arm/configs/multi_v7_defconfig
+++ b/arch/arm/configs/multi_v7_defconfig
@@ -1,6 +1,8 @@
 CONFIG_SYSVIPC=y
 CONFIG_NO_HZ_IDLE=y
 CONFIG_HIGH_RES_TIMERS=y
+CONFIG_IKCONFIG=m
+CONFIG_IKCONFIG_PROC=y
 CONFIG_CGROUPS=y
 CONFIG_BLK_DEV_INITRD=y
 CONFIG_EXPERT=y

---
base-commit: f2b1f6a9f382564b1d4cf16c45e73ccccb917f1f
change-id: 20250329-arm-config_gz-7d656859ad59

Best regards,
-- 
David Heidelberg <david@ixit.cz>

