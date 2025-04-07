From: George Chan <gchan9527@gmail.com>
Date: Mon, 07 Apr 2025 14:43:44 +0800
Subject: [PATCH RFC] fdt.c: fdt chosen cmd had off-by-one issue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250407-fdt-chosen-v1-1-3dda83c48c07@gmail.com>
X-B4-Tracking: v=1; b=H4sIAB9082cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDEwNz3bSUEt3kjPzi1DzdZAtzAxPTNKNUw1RLJaCGgqLUtMwKsGHRsbW
 1AB149+5cAAAA
To: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744008239; l=1586;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=KXpDs9FaMUuw/TaF08xplmfD+9pguJkYrpcltFm/Q3U=;
 b=osa2720q9l0fvEKXeaUD32d5ZTJdZDmOSmCBCLhO1f3Xwl8tEHcRqspJjfzx2FBLa1FRmDnhK
 IP4mf1Z2qE5A184Epo8XgNBDx9En6YJHMn2LCB1RzHSbW8bdP5YKXR9
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The kernel searching bootconfig will be off-by-1 and never match
thus always not found in this case.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
The searching will shift-by-1 and never match the bootconfig thus
always not found bootconfig this case.

Kernel:
            data = (char *)initrd_end - BOOTCONFIG_MAGIC_LEN;
            for (i = 0; i < 4; i++) {
                    if (!memcmp(data, BOOTCONFIG_MAGIC, BOOTCONFIG_MAGIC_LEN))
                            goto found;
                    data--;
            }
u-boot:
            initrd_end = initrd_start + hextoul(argv[3], NULL) - 1;

That would be off-by-one apprently and matching fail for bootconfig.
Both u-boot and kernel worth a fix.

An out-of-tree patch for kernel to relax the searching is available
but not ready for submit.
https://github.com/99degree/linux/commit/9d9ea454fe857a9f550d7e60957253e176e8e123
---
 cmd/fdt.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/cmd/fdt.c b/cmd/fdt.c
index d16b141ce32..13ffe929f8b 100644
--- a/cmd/fdt.c
+++ b/cmd/fdt.c
@@ -705,7 +705,7 @@ static int do_fdt(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[])
 
 		if (argc == 4) {
 			initrd_start = hextoul(argv[2], NULL);
-			initrd_end = initrd_start + hextoul(argv[3], NULL) - 1;
+			initrd_end = initrd_start + hextoul(argv[3], NULL);
 		}
 
 		fdt_chosen(working_fdt);

---
base-commit: 848f7ffc64aa7c4cc2229095812625c12343c8c1
change-id: 20250407-fdt-chosen-c87045f2e1e9

Best regards,
-- 
George Chan <gchan9527@gmail.com>

