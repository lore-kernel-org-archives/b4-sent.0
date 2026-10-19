From: =?utf-8?q?Cl=C3=A1udio_Fernando_Pinto?= <claudio@studiomoob.com>
Date: Mon, 19 Oct 2026 23:32:26 +0000
Subject: [PATCH] ovl: say that only the capability to use reserved space is
 dropped
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261019-ovl-comment-v1-1-499b532b69de@studiomoob.com>
X-B4-Tracking: v=1; b=H4sIAImo1moC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0NL3fyyHN3k/Nzc1LwSXWNTC5NUM+PExFQjUyWgjoKi1LTMCrBp0bE
 QfnFpUlZqcgnICKXaWgB7XG2abwAAAA==
X-Change-ID: 20261019-ovl-comment-3584e63aae25
To: Miklos Szeredi <miklos@szeredi.hu>, Amir Goldstein <amir73il@gmail.com>
Cc: linux-unionfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Cl=C3=A1udio_Fernando_Pinto?= <claudio@studiomoob.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792452745; l=1558;
 i=claudio@studiomoob.com; s=20261019; h=from:subject:message-id;
 bh=KXvEZ5G4Kj83Jeh1CpWL8I93iCpOGNPJqUtMEL2j73A=;
 b=k1RpYgvbOWFTm33t5Hs8KNeba/OwD1daCjGvJuC3aPSimW7C/7BwDDHxoa/zF+WWTutjcP4z8
 Eu7JfEPEMB9A4Mi/zx1/fzX6Po+YM/bt6ExG3DtsgoYs7dCPGTNOMPe
X-Developer-Key: i=claudio@studiomoob.com; a=ed25519;
 pk=cJXPz68Qvj2c2L6TWJsYP1yNYCU+KA1USyC+oykJv6A=
X-Endpoint-Received: by B4 Relay for claudio@studiomoob.com/20261019 with auth_id=1246
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The comment above cap_lower(CAP_SYS_RESOURCE) in
ovl_fill_super_creds(), added by commit 51f8f3c4e225 ("ovl: drop
CAP_SYS_RESOURCE from saved mounter's credentials"), says overlayfs
never uses reserved space. Lowering the capability does not stop ext4
from granting its reserved blocks by fsuid: with the default reserve
owner and a root mounter, a write through overlayfs still spends them.
Say what the code does, without going further.

Link: https://lore.kernel.org/linux-unionfs/CAOQ4uxh0g1MtgCO7Q2f4yJP5vq5rLEiiXHbVfeCxwXB5ff4-VQ@mail.gmail.com/
Assisted-by: LLM
Signed-off-by: Cláudio Fernando Pinto <claudio@studiomoob.com>
---
Follow-up to the reserve report after Amir's reply: comment only.
---
 fs/overlayfs/super.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/overlayfs/super.c b/fs/overlayfs/super.c
index bd0a3f9039..21d0cb8719 100644
--- a/fs/overlayfs/super.c
+++ b/fs/overlayfs/super.c
@@ -1508,7 +1508,7 @@ static int ovl_fill_super_creds(struct fs_context *fc, struct super_block *sb)
 	else if (!ofs->nofh)
 		sb->s_export_op = &ovl_export_fid_operations;
 
-	/* Never override disk quota limits or use reserved space */
+	/* Never override disk quota limits or use reserved space by capability */
 	cap_lower(creator_cred->cap_effective, CAP_SYS_RESOURCE);
 
 	sb->s_magic = OVERLAYFS_SUPER_MAGIC;

---
base-commit: 24a19b953e2a3d0ea5a8c4951a0ab8f32720c907
change-id: 20261019-ovl-comment-3584e63aae25

Best regards,
--  
Cláudio Fernando Pinto <claudio@studiomoob.com>

