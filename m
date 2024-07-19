From: Emil Velikov <emil.l.velikov@gmail.com>
Subject: [PATCH kmod 0/3] libkmod: misc ABI changes
Date: Fri, 19 Jul 2024 17:12:40 +0100
Message-Id: <20240719-abi-fixes-v1-0-1e6d99a2846b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHiQmmYC/x3KQQqAIBBA0avIrBtQCYa6SrQwG2s2FgoRiHdva
 Pn4v0HlIlxhNg0KP1Llygo3GIhnyAej7Grw1o+WHGHYBJO8XJEskQspbuwm0P8u/Afdl7X3D+K
 l1KpbAAAA
To: linux-modules@vger.kernel.org
Cc: Marco d'Itri <md@linux.it>, Eugene Syromiatnikov <esyr@redhat.com>, 
 Josh Boyer <jwboyer@fedoraproject.org>, 
 Yauheni Kaliuta <ykaliuta@fedoraproject.org>, 
 Alexey Gladkov <gladkov.alexey@gmail.com>, 
 Emil Velikov <emil.l.velikov@gmail.com>, 
 Jose Ignacio Tornos Martinez <jtornosm@redhat.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721405562; l=1640;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=eV3qb5B+I1nDNQOkwqUHc7RO6Qbz3kjLk+d5HXT++yg=;
 b=PcWb4wLN548NuD7u1acnOtM+vH3kD+FNTQilSOgqp1eVc1t82LZd+2NFjBL4IjTx1MRGE2gem
 kDCe4SrrPAhAGti36MLLUVZAm45cjZzgeR/afLbXItBd3diq5kzBToI
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello all,

Recently I've noticed that new API was added into the incorrect section
of the version script. Thus the resulting library had incorrectly tagged
symbol(s) in the exports list.

As result I went ahead and checked for other ABI issues and I've noticed
that v26 and v27 have some changes in enum kmod_index. Although on
inspection neither of these should have caused issues in reality:

 - v26 changes the _KMOD_INDEX_PAD from signed to unsigned, all other
   enum values are identical
 - v27 adds new enum, effectively changing the final (non-pad) enum
   value. My search has found zero users of change and new enums, and
   single (abandoned) user of the kmod_dump_index() API (which uses the
   enum in the first place)

The respective commits have additional details and reasoning.

Personally I would recommend picking patch 2 across all distros and
patch 3, if your distro is shipping kmod version from git.

Cc-ing Debian, Fedora and RedHat maintainers - team, please forward this
to any fellow maintainers I may have missed.

Thanks in advance,

To: linux-modules@vger.kernel.org

---
Emil Velikov (3):
      libkmod: document KMOD_INDEX_MODULES_BUILTIN_ALIAS in kmod_dump_index()
      libkmod: correctly tag kmod_module_new_from_name_lookup
      libkmod: move new weak API to separate section

 libkmod/libkmod.c   |  1 +
 libkmod/libkmod.sym | 14 +++++++++++---
 2 files changed, 12 insertions(+), 3 deletions(-)
---
base-commit: fa715f8c8b78a09f47701ce1cf46e9b67a49b8d0
change-id: 20240717-abi-fixes-70771afcbe19

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>

