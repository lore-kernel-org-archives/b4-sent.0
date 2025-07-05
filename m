From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 05 Jul 2025 17:52:50 +0200
Subject: [PATCH b4] git_range_to_patches: add git options to better
 represent renames and copies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250705-format-harder-v1-1-55c5342be55c@oldschoolsolutions.biz>
X-B4-Tracking: v=1; b=H4sIAFFKaWgC/x3MQQqAIBBA0avErBNUtKCrRAu1KWeRxhgRSHdPW
 r7F/xUKMmGBqavAeFOhnBpU30GILu0oaG0GLbWVo7Riy3y4S0THK7LAAb13VhsfFLTmZNzo+X8
 zeAPL+37mxBT6YwAAAA==
X-Change-ID: 20250705-format-harder-e6ebba524bc1
To: "Kernel.org Tools" <tools@kernel.org>
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751730778; l=1370;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=gAdssHnCF0Xwb2viD/hFmFPVBFIzEo1trVnupy4j+qs=;
 b=CGk1Kn4svxaYySSCryr5OC+kOkZ91Ox1QtsYvoxvqMEqKv3n2W0zj09G5qYAsoDXYaY4okVuJ
 FswehaJQhZkAOiDauxz+noj2BPWjcFBicl1n8YOUSocNjRsAbLW1TIu
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
This is an attempt at mitigating the real-world issue of file renames
in patches due to code restructuring. I have a few of these, and would 
like to keep using b4 for patch management.
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

---
base-commit: a9b2aba54be85ea2933c43b8a6d71c1611230b59
change-id: 20250705-format-harder-e6ebba524bc1

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

