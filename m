From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Tue, 12 Aug 2025 19:59:15 +0200
Subject: [PATCH b4 v2 2/2] git_range_to_patches: set minimum similarity
 index to 95%
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250812-format-harder-v2-2-53f74982079a@oldschoolsolutions.biz>
References: <20250812-format-harder-v2-0-53f74982079a@oldschoolsolutions.biz>
In-Reply-To: <20250812-format-harder-v2-0-53f74982079a@oldschoolsolutions.biz>
To: "Kernel.org Tools" <tools@kernel.org>
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755021559; l=982;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=AU+acsVaWeeFhgOmPkvemVaNu+t9PcDSpp4UH79XZ9k=;
 b=CnWGZ8FmPRYiCumCknELvDRaxC1xbVClRdko1RpqesIGaGUqEDXfS3W6Jy2TrjGKdjkOaUDvf
 Sd3lsL95EIlCfgP4laMDLCh2W/cz5Xi4F/nxXaO9sp7YbJdL1rUMTWb
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There was an occurrence of (correctly) showing the diff to the original
source a file was copied from, but understandably it was classified as
impossible to review. [1]
To avoid this situation, require pretty high similarity to make it a
diff against the original.

[1]: https://lore.kernel.org/all/388aed37-03c1-4a5f-a425-5ed8c4f9cb34@oss.qualcomm.com/

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 src/b4/__init__.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/src/b4/__init__.py b/src/b4/__init__.py
index 93cf016bd705584ace4d61c4968be365a25f2502..99198fe29aca34f09646775303638764b4a3fef1 100644
--- a/src/b4/__init__.py
+++ b/src/b4/__init__.py
@@ -3596,7 +3596,7 @@ def git_range_to_patches(gitdir: Optional[str], start: str, end: str,
             '--find-renames',
 			'-M',
 			'-B',
-			'-C',
+			'-C95',
 			'--find-copies-harder',
         ]
         smcfg = get_sendemail_config()

-- 
2.48.1

