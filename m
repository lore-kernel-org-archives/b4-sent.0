From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Wed, 11 Dec 2024 23:25:26 +0100
Subject: [PATCH v2 2/3] cmd: Allow building ufetch without CONFIG_BLK
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241211-ufetch-v2-2-2b5432ffaeb1@posteo.net>
References: <20241211-ufetch-v2-0-2b5432ffaeb1@posteo.net>
In-Reply-To: <20241211-ufetch-v2-0-2b5432ffaeb1@posteo.net>
To: Caleb Connolly <caleb.connolly@linaro.org>, 
 Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733955947; l=2239;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=w3CntfH1PcCaKILPhytp+dmkSVmns7MQdgbpBdMQ9NI=;
 b=XinjDKXsmpWD4IlWvVWwzkoNDRqRa8hYtQoSbWMvu9h1wTayhqulqSYm5FrKR7QtdkyHeQd+K
 gg0M4p5S94uCrH36kqK61tqyWWHRUSWDgUGSzs6L3YQ+B2KQ0xgqjza
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ufetch command is still quite useful on systems without block
device support; remove the CONFIG_BLK dependency and make sure the code
compiles/works with and without CONFIG_BLK.

Reviewed-by: Caleb Connolly <caleb.connolly@linaro.org>
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

v2:
- Add parentheses to avoid having declarations after the "default" label.
- Add Caleb's R-b
---
 cmd/Kconfig  |  1 -
 cmd/ufetch.c | 13 +++++++++----
 2 files changed, 9 insertions(+), 5 deletions(-)

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
index 5f3ef847b268dc384271fc6774720e5fd2337157..83cec0f6d5c875f150f7b948392a29803bdbc201 100644
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
@@ -199,7 +197,12 @@ static int do_ufetch(struct cmd_tbl *cmdtp, int flag, int argc,
 			print_size(size, "\n");
 			break;
 		case STORAGE:
-		default:
+		default: {
+#ifdef CONFIG_BLK
+			struct udevice *dev;
+			struct blk_desc *desc;
+			int ret;
+
 			ret = uclass_find_device_by_seq(UCLASS_BLK, line - STORAGE, &dev);
 			if (!ret && dev) {
 				desc = dev_get_uclass_plat(dev);
@@ -213,8 +216,10 @@ static int do_ufetch(struct cmd_tbl *cmdtp, int flag, int argc,
 			} else if (ret == -ENODEV && (skip_ascii || line > ARRAY_SIZE(logo_lines))) {
 				break;
 			}
+#endif
 			printf("\n");
 		}
+		}
 	}
 
 	printf(RESET "\n\n");

-- 
2.45.2

