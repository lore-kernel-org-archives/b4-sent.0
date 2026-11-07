From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sat, 07 Nov 2026 08:01:46 -0600
Subject: [PATCH] staging: octeon: fix kernel-doc comment style in
 ethernet-mem.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261107-octeon-mem-doc-fix-v1-1-4d962b83a3d6@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MywqAIBAAfyX23ILaQ+pXooPYVntQQyOC6N9bO
 s7AzAOFMlOBsXog08WFUxTQdQV+d3Ej5EUYjDK91spi8ieliIECLsnjyje2rvGd6ZUeyIKERyb
 R/3Sa3/cDY3XgKGQAAAA=
X-Change-ID: 20261107-octeon-mem-doc-fix-4a3c526019e7
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794060106; l=1191;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=+9rVYI6biHPDGY8NGsdQc54rP2z64h+4I/8Uh5neCIY=;
 b=GVo42hx1tShon+12HPtDazHwAFfkis25aWmt5zQY6AF8ZqViXkJkxHXwJmR5/wLtLiUpIYT4E
 ilQJYmpwqu0ALJhEJcQnX60489I3IyHTe+ThHLWQH5FrPFC+/gncNgF
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix a style mismatch in the kernel-doc documentation block for
cvm_oct_free_hw_skbuff() by adding a missing space before the
descriptive dash. This allows the documentation toolchain scripts to
correctly parse the function identifier.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
 drivers/staging/octeon/ethernet-mem.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/staging/octeon/ethernet-mem.c b/drivers/staging/octeon/ethernet-mem.c
index 68c3ef984e56..7bcd11245d06 100644
--- a/drivers/staging/octeon/ethernet-mem.c
+++ b/drivers/staging/octeon/ethernet-mem.c
@@ -40,7 +40,7 @@ static int cvm_oct_fill_hw_skbuff(int pool, int size, int elements)
 }
 
 /**
- * cvm_oct_free_hw_skbuff- free hardware pool skbuffs
+ * cvm_oct_free_hw_skbuff - free hardware pool skbuffs
  * @pdev:     Platform device for logging
  * @pool:     Pool to allocate an skbuff for
  * @size:     Size of the buffer needed for the pool

---
base-commit: cd894bbfd059e76e71ffc9b92f8a09d4d6012e9f
change-id: 20261107-octeon-mem-doc-fix-4a3c526019e7

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

