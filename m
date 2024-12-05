From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 05 Dec 2024 19:35:35 +0100
Subject: [PATCH 3/3] cmd: ufetch: Show CPU architecture under "CPU"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241205-ufetch-v1-3-df861318bd49@posteo.net>
References: <20241205-ufetch-v1-0-df861318bd49@posteo.net>
In-Reply-To: <20241205-ufetch-v1-0-df861318bd49@posteo.net>
To: Caleb Connolly <caleb.connolly@linaro.org>, 
 Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733423734; l=910;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=crIjf2A+enP0K5Ya091QaL8E4S7xMtCUK2fAhsq3hj0=;
 b=npMmM+rb2AfEIp7GbBkLxClvhAYuTtj+R14rGIT8xGO0Z7I5pgVmTsXJ1qLRzF9zdlJLylI35
 WMeBJ6OA3vpCPkpYEm2Pd63HAKppIw9TIl9MAtsL3j8IsoN2S/Bplml
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When looking at ufetch output it isn't immediately obvious which CPU
architecture the presented board has. This patch therefore adds the CPU
architecture string (for example "powerpc") to the "CPU:" line.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 cmd/ufetch.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/cmd/ufetch.c b/cmd/ufetch.c
index 7aed0b447bda104b837d37c6adcbb21b80237aba..0ee50bfb606aa2223072c63cd46b3a70ef5449fd 100644
--- a/cmd/ufetch.c
+++ b/cmd/ufetch.c
@@ -188,7 +188,7 @@ static int do_ufetch(struct cmd_tbl *cmdtp, int flag, int argc,
 				if (ofnode_name_eq(np, "cpu"))
 					n_cpus++;
 			}
-			printf("CPU:" RESET " %d (1 in use)\n", n_cpus);
+			printf("CPU: " RESET CONFIG_SYS_ARCH ", %d (1 in use)\n", n_cpus);
 			break;
 		case MEMORY:
 			for (int j = 0; j < CONFIG_NR_DRAM_BANKS && gd->bd->bi_dram[j].size; j++)

-- 
2.45.2

