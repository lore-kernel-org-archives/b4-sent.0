From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Wed, 18 Nov 2026 23:25:04 +0000
Subject: [PATCH 1/2] libproc: fix readlink() typo in Psystem_daemon()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-b4-bug008-daemon-readlink-v1-1-187c9eb22d11@d-matrix.ai>
References: <20261118-b4-bug008-daemon-readlink-v1-0-187c9eb22d11@d-matrix.ai>
In-Reply-To: <20261118-b4-bug008-daemon-readlink-v1-0-187c9eb22d11@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: Kris Van Hees <kris.van.hees@oracle.com>, 
 Nick Alcock <nix@esperi.org.uk>, Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795044315; l=770;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=X9qAzd7ZDnORJhQr1VZplrx+O3JnAZBaIhpe294weXU=;
 b=dnwZzCUec30UavyqcuxZov6GguqDxojZ616foD1WYPf0eZAznmp+MHQBo1k30qpeD7W24mpV3
 mE945UKGEfpCItuHZOCOnbQ1qIyyr9fnwD0NFWT2LykJkjk6cGV0Nbg
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

readlink() returns the number of bytes it stored or -1, never 0, so
the check for a regular file outside /var never ran.

Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 libproc/Pcontrol.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/libproc/Pcontrol.c b/libproc/Pcontrol.c
index f8440d5b..ece074e0 100644
--- a/libproc/Pcontrol.c
+++ b/libproc/Pcontrol.c
@@ -3045,7 +3045,7 @@ Psystem_daemon(pid_t pid, uid_t useruid, const char *sysslice)
 		 */
 		memset(buf, '\0', sizeof(buf));
 		if (S_ISREG(s.st_mode) &&
-		    (readlink(procname, buf, sizeof(buf)-1) == 0)) {
+		    (readlink(procname, buf, sizeof(buf)-1) > 0)) {
 			if((buf[0] == '/') && (strcmp(buf, "/var/") != 0))
 				return 0;
 		}

-- 
2.55.0

