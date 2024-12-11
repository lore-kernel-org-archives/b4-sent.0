From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Wed, 11 Dec 2024 23:25:27 +0100
Subject: [PATCH v2 3/3] cmd: ufetch: Show CPU architecture under "CPU"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241211-ufetch-v2-3-2b5432ffaeb1@posteo.net>
References: <20241211-ufetch-v2-0-2b5432ffaeb1@posteo.net>
In-Reply-To: <20241211-ufetch-v2-0-2b5432ffaeb1@posteo.net>
To: Caleb Connolly <caleb.connolly@linaro.org>, 
 Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733955948; l=1029;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=/Cg0aGCHH9Ee1PEGTmvqDYJpZHTVfYwbSQst/nnF4mM=;
 b=hn1SVq0+J9nCc5W139NpXvfeteHxkh4G5mpVDUVABO1uQaW5071+MZQt/NiF4Smiu74Dmm5A+
 FNu64g1u3QVCGwWQj+7cYdHYjFFsFttvftNpZK7GvAxk3/f3C751Yi+
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When looking at ufetch output it isn't immediately obvious which CPU
architecture the presented board has. This patch therefore adds the
CPU architecture string (for example "powerpc") to the "CPU:" line.
The new format is:

	CPU: powerpc (1 cores, 1 in use)

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

v2:
- Reformat the CPU message for readability
---
 cmd/ufetch.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/cmd/ufetch.c b/cmd/ufetch.c
index 83cec0f6d5c875f150f7b948392a29803bdbc201..ed5a856c7abbe08949b81e0b2f634edd8b390be5 100644
--- a/cmd/ufetch.c
+++ b/cmd/ufetch.c
@@ -188,7 +188,7 @@ static int do_ufetch(struct cmd_tbl *cmdtp, int flag, int argc,
 				if (ofnode_name_eq(np, "cpu"))
 					n_cpus++;
 			}
-			printf("CPU:" RESET " %d (1 in use)\n", n_cpus);
+			printf("CPU: " RESET CONFIG_SYS_ARCH " (%d cores, 1 in use)\n", n_cpus);
 			break;
 		case MEMORY:
 			for (int j = 0; j < CONFIG_NR_DRAM_BANKS && gd->bd->bi_dram[j].size; j++)

-- 
2.45.2

