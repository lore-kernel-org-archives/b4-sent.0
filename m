From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Wed, 11 Dec 2024 23:25:25 +0100
Subject: [PATCH v2 1/3] cmd: ufetch: Fix type mismatch on 32-bit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241211-ufetch-v2-1-2b5432ffaeb1@posteo.net>
References: <20241211-ufetch-v2-0-2b5432ffaeb1@posteo.net>
In-Reply-To: <20241211-ufetch-v2-0-2b5432ffaeb1@posteo.net>
To: Caleb Connolly <caleb.connolly@linaro.org>, 
 Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733955947; l=1467;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=ukV5W4viTNXoPORPuKkJ7XwZABI+SL1DgnUObgjPNLI=;
 b=gfPor0h6dE/stpIj5+SQMuDzFmZy673j+Z6SWBXLNkGbC4FB4EogVCVQNWi0eaoIQ+Jhm5gMG
 Z1I6UaAxtfQCxPx3tO1QZSGHsFNVBNcYlhX12XQ/JgxSFTgotJr7AKV
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On 32-bit architectures, LAST_LINE (_LAST_LINE - 1UL) is 64 bits long,
but size_t (from ARRAY_SIZE(...)) is 32 bits. This results in a warning
because the max() macro expects the same type on both sides:

cmd/ufetch.c: In function ‘do_ufetch’:
include/linux/kernel.h:179:24: warning: comparison of distinct pointer types lacks a cast [-Wcompare-distinct-pointer-types]
  179 |         (void) (&_max1 == &_max2);              \
      |                        ^~
cmd/ufetch.c:92:25: note: in expansion of macro ‘max’
   92 |         int num_lines = max(LAST_LINE + 1, ARRAY_SIZE(logo_lines));
      |                         ^~~

Fix this by casting LAST_LINE to size_t.

Reviewed-by: Caleb Connolly <caleb.connolly@linaro.org>
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

v2:
- Add Caleb's R-b
---
 cmd/ufetch.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/cmd/ufetch.c b/cmd/ufetch.c
index 0b825d7e8c75f3b18933d3e3f77e5f40f2c7b658..5f3ef847b268dc384271fc6774720e5fd2337157 100644
--- a/cmd/ufetch.c
+++ b/cmd/ufetch.c
@@ -89,7 +89,7 @@ enum output_lines {
 static int do_ufetch(struct cmd_tbl *cmdtp, int flag, int argc,
 		     char *const argv[])
 {
-	int num_lines = max(LAST_LINE + 1, ARRAY_SIZE(logo_lines));
+	int num_lines = max((size_t)LAST_LINE + 1, ARRAY_SIZE(logo_lines));
 	const char *model, *compatible;
 	char *ipaddr;
 	int n_cmds, n_cpus = 0, ret, compatlen;

-- 
2.45.2

