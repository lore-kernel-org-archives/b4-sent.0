From: =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
Date: Thu, 06 Jul 2023 15:42:47 +0200
Subject: [PATCH] security: smack: smackfs: fix typo (lables->labels)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20230706-smackfs-lables-fix-v1-1-228c8da5a526@gmail.com>
X-B4-Tracking: v=1; b=H4sIANbEpmQC/x2MSQqAMAwAvyI5G6g7+hXxUGOqwZUGRJD+3eJxB
 mZeUPbCCl3ygudbVM4jQpYmQIs9ZkaZIkNu8sI0pkbdLa1OcbPjxopOHrTU1hWVVDatgxhenqP
 +p/0QwgfggIfrZAAAAA==
To: Casey Schaufler <casey@schaufler-ca.com>, 
 Paul Moore <paul@paul-moore.com>, James Morris <jmorris@namei.org>, 
 "Serge E. Hallyn" <serge@hallyn.com>
Cc: linux-security-module@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1688650991; l=959;
 i=gomba007@gmail.com; s=20230706; h=from:subject:message-id;
 bh=S9HyRNyzLwD2W29A0DsX2ZZZiM4IO3L3DpcXXpfmTVs=;
 b=+l3RH2YK8ag+dH4tuUELH+9cCBBPq/Q/0jA3y2RaAMzIg/aM05m2xuKO2LqP1+WPWo8bU9u9R
 eJrj3WH5m+wCBZgCrQW0f5XpFTJJfh+0d8KcynKf72E51KCl0BZbNoI
X-Developer-Key: i=gomba007@gmail.com; a=ed25519;
 pk=iY9MjPCbud82ULS2PQJIq3QwjKyP/Sg730I6T2M8Y5U=
X-Endpoint-Received: by B4 Relay for gomba007@gmail.com/20230706 with auth_id=60
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix a spelling error in smakcfs.

Signed-off-by: Tóth János <gomba007@gmail.com>
---
 security/smack/smackfs.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/security/smack/smackfs.c b/security/smack/smackfs.c
index 5590eaad241b..2b79c30d4bb6 100644
--- a/security/smack/smackfs.c
+++ b/security/smack/smackfs.c
@@ -114,7 +114,7 @@ struct smack_known *smack_syslog_label;
  * SMACK_PTRACE_DEFAULT    regular smack ptrace rules (/proc based)
  * SMACK_PTRACE_EXACT      labels must match, but can be overriden with
  *			   CAP_SYS_PTRACE
- * SMACK_PTRACE_DRACONIAN  lables must match, CAP_SYS_PTRACE has no effect
+ * SMACK_PTRACE_DRACONIAN  labels must match, CAP_SYS_PTRACE has no effect
  */
 int smack_ptrace_rule = SMACK_PTRACE_DEFAULT;
 

---
base-commit: 6995e2de6891c724bfeb2db33d7b87775f913ad1
change-id: 20230706-smackfs-lables-fix-ac965c4c479f

Best regards,
-- 
Tóth János <gomba007@gmail.com>

