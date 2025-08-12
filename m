From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Tue, 12 Aug 2025 19:59:14 +0200
Subject: [PATCH b4 v2 1/2] git_range_to_patches: add git options to better
 represent renames and copies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250812-format-harder-v2-1-53f74982079a@oldschoolsolutions.biz>
References: <20250812-format-harder-v2-0-53f74982079a@oldschoolsolutions.biz>
In-Reply-To: <20250812-format-harder-v2-0-53f74982079a@oldschoolsolutions.biz>
To: "Kernel.org Tools" <tools@kernel.org>
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755021559; l=1009;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=bSyncenwTXyl6hnBeb7URh7Kurn8icGV3x9qoXbSXIo=;
 b=MXevnUyDFOBcVOHS7voxgn+6bl714QOjt0LMfmmXiLxuwwWFZYnsGIYWOBBAJPoAROyjRdvzb
 Jqz6VLXzWeKDIF0L6lO6q8ASYK6UMb9gSpYbqa5WQe/fv+W2AEPx+52
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As remarked in [1] and [2], add the necessary options to get better and more
terse output.

[1]: https://lore.kernel.org/all/7tejkof2kec7ugpz6xugkjrcpzab27lsjpnkphj3vd3xoc4ly7@x3otjziiehju/
[2]: https://lore.kernel.org/all/369fc807-f05e-4837-b623-b718e47fd840@kernel.org/

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 src/b4/__init__.py | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/src/b4/__init__.py b/src/b4/__init__.py
index ff6075e3a95e0df5f8ba3f717b12ae2bbce03432..93cf016bd705584ace4d61c4968be365a25f2502 100644
--- a/src/b4/__init__.py
+++ b/src/b4/__init__.py
@@ -3594,6 +3594,10 @@ def git_range_to_patches(gitdir: Optional[str], start: str, end: str,
             '--encoding=utf-8',
             '--default-prefix',
             '--find-renames',
+			'-M',
+			'-B',
+			'-C',
+			'--find-copies-harder',
         ]
         smcfg = get_sendemail_config()
         if not get_git_bool(str(smcfg.get('mailmap', 'false'))):

-- 
2.48.1

