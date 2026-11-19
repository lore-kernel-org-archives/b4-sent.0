From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Thu, 19 Nov 2026 07:11:41 +0000
Subject: [PATCH v2 1/2] libproc: fix readlink() typo in Psystem_daemon()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-b4-bug008-daemon-readlink-v2-1-c4bc5fbf156f@d-matrix.ai>
References: <20261119-b4-bug008-daemon-readlink-v2-0-c4bc5fbf156f@d-matrix.ai>
In-Reply-To: <20261119-b4-bug008-daemon-readlink-v2-0-c4bc5fbf156f@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: Nick Alcock <nix@esperi.org.uk>, 
 Kris Van Hees <kris.van.hees@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795072309; l=825;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=BOu643POXRZw4OhvnNkHCx15zSgC9xf/H628LDrSpLs=;
 b=kQjpKplv8EAy+m6n1ccbhDvOEd6J6C+0FshILEE6DUK/DvcwpW++lqVLtwn0dZXhrZXsMEqns
 60hRl5Bn+02D6ICmv3K0pClGjlDGiYA1/0+PmkNT/vIfjNm7atQw79Z
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

readlink() returns the number of bytes it stored or -1, never 0, so
the check for a regular file outside /var never ran.

Reviewed-by: Kris Van Hees <kris.van.hees@oracle.com>
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

