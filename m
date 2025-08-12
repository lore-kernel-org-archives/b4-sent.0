From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH b4 v2 0/2] git_range_to_patches: add git options to better
 represent renames and copies
Date: Tue, 12 Aug 2025 19:59:13 +0200
Message-Id: <20250812-format-harder-v2-0-53f74982079a@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPGAm2gC/3VOSw6CMBC9Cpm1NbRSTVx5D8KiLYOdBBkzg0Ql3
 N2Gvbv3yfusoCiECtdqBcGFlHgqxB0qSDlMdzTUFw6udr6+1N4MLI8wmxykRzF4xhiDd01MFkr
 mKTjQe+9rITbQFS2TziyffWKxu/OnbbHGGu+TPzUuYgE3HntNmXlUHl9z+abHSF/otm37AXk3V
 H+7AAAA
X-Change-ID: 20250705-format-harder-e6ebba524bc1
To: "Kernel.org Tools" <tools@kernel.org>
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755021559; l=871;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=nlIO//jZ2weZx34dLPui/msR2DyB4Z4hVhnWq8BNy2c=;
 b=M6OGwdU7cWsVhgjcKXxzv5uWlOsDWC1waPbjWwe8PlY6WvAAtN9U85AfI2NnMCmR5vDEFxGnA
 3rPFm3shmC+Ck3lPU7t0ultee4Bt9uvc6ZRRisrZxWD5UXwU68AqK+b
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is an attempt at mitigating the real-world issue of file renames
in patches due to code restructuring. I have a few of these, and would 
like to keep using b4 for patch management.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
Changes in v2:
- set minimum similarity index to 95% to avoid un-reviewable patches
- Link to v1: https://patch.msgid.link/20250705-format-harder-v1-1-55c5342be55c@oldschoolsolutions.biz

---
Jens Glathe (2):
      git_range_to_patches: add git options to better represent renames and copies
      git_range_to_patches: set minimum similarity index to 95%

 src/b4/__init__.py | 4 ++++
 1 file changed, 4 insertions(+)
---
base-commit: a9b2aba54be85ea2933c43b8a6d71c1611230b59
change-id: 20250705-format-harder-e6ebba524bc1

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

