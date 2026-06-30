From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 30 Jun 2026 15:56:04 +0800
Subject: [PATCH] target/loongarch: Enable TARGET_PAGE_BITS_VARY for
 loongarch64 user-only
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260630-loong64-vary-page-sz-v1-1-1d1a894674be@gmail.com>
X-B4-Tracking: v=1; b=H4sIAJN2Q2oC/x2MWwqAIBAArxL73YJpSXSV6MNys4XQUIgeePekz
 4GZeSFRZEowVC9EOjlx8AWauoJlM94Rsi0MUkgttBK4h+CdbvE08cbDFCE9KDtlyYqZ+r6Fkh6
 RVr7+7Tjl/AF/a21FZgAAAA==
X-Change-ID: 20260630-loong64-vary-page-sz-253ded0be884
To: qemu-devel@nongnu.org
Cc: Song Gao <gaosong@loongson.cn>, b4-sent@feeds.kernel.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1044;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=P2yWSCAzG7Ep94c0IDqmt6Vf+hrglM5091uNh3I1QpQ=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqQ3aXlgurCQL3nbFGIngXREWSBvfHmQxB0Q+Pf
 gtjb0rJ9wOJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCakN2lwAKCRCwMePKe/7Z
 bkqfD/sHaIJAqHxhYzIrezK4G6ydiZlKdhf60zKPyUF1YM7PyeyFHvuA9cFWCn/eWtetTHzCIJy
 8TEFYK5NB8gEQ2tUsxiqgJb4S9DvuPjXvKGArIH/nPOvoKUkkDdQtQE99K7MjUqFtKbiokZ4hxw
 PN+FJWW6pqLC29iKuDKgACX/exz4CVqOEgLmnOuiM88sbHYo/wRyxQlEzpAtPlEDKvKRLnJIdz/
 0hNwfFCzek4yG3k/SacA2xCPq/e2J8sLfKemQJoJ1YRXMe7BUjGEH5kBg2D1q8QONiOQC0WFb3F
 u92aFFAPEhtQtnXql4vYTEwvIhNuMDJnL7Zbovzu+vW42TNjASs1zJ3R2LlkvEzInIJTUn7XqlV
 YrOOUC6B36w4BdvO7VIyrBNkmmOAFycjag59ZRxD1C+fVGjuo9ZpWOT8c4y6oSfgtLw3r8xMVDM
 +TYmZYvkxPkJtS4D7nRNINbez+IsyJb2LKKbpQpBS69bBov9wsVS8uXg63TsyJq53UEQi/vNcZ0
 uelK3IZGUm58Q3C7HJWRJpKKhgsYrFCoSgxliCm8f9nXvfbDaZRp4e2DqZtXK+FvNbjj4P0KgPM
 oNcixh95BUkPY2k1mqJbk5+dBs8DKGjhua+EyIXyKFuthdnxZ4i3v2gzYqYJhHdw5ASJB/TyEWb
 ySK0JD3XlnqJlVw==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hard coding PAGE_SIZE to 4K will prevent user-only emulation from
working on hosts with 16K page size.

Fixes: 1d832c19db1e ("target/loongarch: Support 4K page size")
Fixes: qemu-project/qemu#3651

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 target/loongarch/cpu-param.h | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/target/loongarch/cpu-param.h b/target/loongarch/cpu-param.h
index 3bcf77b3755abdc302699c22c7aa99e2e8c3bbf3..6abe72ff5cab46e246fde4fa76bce05ba7c1cd20 100644
--- a/target/loongarch/cpu-param.h
+++ b/target/loongarch/cpu-param.h
@@ -10,6 +10,11 @@
 
 #define TARGET_VIRT_ADDR_SPACE_BITS 48
 
-#define TARGET_PAGE_BITS 12
+#ifdef CONFIG_USER_ONLY
+/* Allow user-only to vary page size from 4k */
+# define TARGET_PAGE_BITS_VARY
+#else
+# define TARGET_PAGE_BITS 12
+#endif
 
 #endif

---
base-commit: 30e8a06b64aa58a3990ba39cb5d09531e7d265e0
change-id: 20260630-loong64-vary-page-sz-253ded0be884

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

