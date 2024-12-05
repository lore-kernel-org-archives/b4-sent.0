From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 05 Dec 2024 19:35:34 +0100
Subject: [PATCH 2/3] cmd: Allow building ufetch without CONFIG_BLK
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241205-ufetch-v1-2-df861318bd49@posteo.net>
References: <20241205-ufetch-v1-0-df861318bd49@posteo.net>
In-Reply-To: <20241205-ufetch-v1-0-df861318bd49@posteo.net>
To: Caleb Connolly <caleb.connolly@linaro.org>, 
 Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733423734; l=1994;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=DnyP6oDnp1lVSkVKMsKyWltrCFz7Ez9t5/Fu2/ef8jA=;
 b=6QeTrJDma/AQq67RbdwT6oaXewi61yI0yAty7ufsbbIndopWiGWg6bMQxq/mShSK2LWsPeBQX
 /7tZ0oe4rjOBi2rjlVqSXq/pAhOWrJFjVVSNZHc9Iagp5NSOXUBsOUQ
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ufetch command is still quite useful on systems without block
device support; remove the CONFIG_BLK dependency and make sure the code
compiles/works with and without CONFIG_BLK.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 cmd/Kconfig  |  1 -
 cmd/ufetch.c | 10 +++++++---
 2 files changed, 7 insertions(+), 4 deletions(-)

diff --git a/cmd/Kconfig b/cmd/Kconfig
index 4936a70f3ef16ddb093ceafa12d011ca1b89e95c..547fd2a91f7883e2ae5982897ec93c4483d67852 100644
--- a/cmd/Kconfig
+++ b/cmd/Kconfig
@@ -178,7 +178,6 @@ config CMD_CPU
 
 config CMD_UFETCH
 	bool "U-Boot fetch"
-	depends on BLK
 	help
 	  Fetch utility for U-Boot (akin to neofetch). Prints information
 	  about U-Boot and the board it is running on in a pleasing format.
diff --git a/cmd/ufetch.c b/cmd/ufetch.c
index 5f3ef847b268dc384271fc6774720e5fd2337157..7aed0b447bda104b837d37c6adcbb21b80237aba 100644
--- a/cmd/ufetch.c
+++ b/cmd/ufetch.c
@@ -92,11 +92,9 @@ static int do_ufetch(struct cmd_tbl *cmdtp, int flag, int argc,
 	int num_lines = max((size_t)LAST_LINE + 1, ARRAY_SIZE(logo_lines));
 	const char *model, *compatible;
 	char *ipaddr;
-	int n_cmds, n_cpus = 0, ret, compatlen;
+	int n_cmds, n_cpus = 0, compatlen;
 	size_t size;
 	ofnode np;
-	struct udevice *dev;
-	struct blk_desc *desc;
 	bool skip_ascii = false;
 
 	if (argc > 1 && strcmp(argv[1], "-n") == 0) {
@@ -200,6 +198,11 @@ static int do_ufetch(struct cmd_tbl *cmdtp, int flag, int argc,
 			break;
 		case STORAGE:
 		default:
+#ifdef CONFIG_BLK
+			struct udevice *dev;
+			struct blk_desc *desc;
+			int ret;
+
 			ret = uclass_find_device_by_seq(UCLASS_BLK, line - STORAGE, &dev);
 			if (!ret && dev) {
 				desc = dev_get_uclass_plat(dev);
@@ -213,6 +216,7 @@ static int do_ufetch(struct cmd_tbl *cmdtp, int flag, int argc,
 			} else if (ret == -ENODEV && (skip_ascii || line > ARRAY_SIZE(logo_lines))) {
 				break;
 			}
+#endif
 			printf("\n");
 		}
 	}

-- 
2.45.2

