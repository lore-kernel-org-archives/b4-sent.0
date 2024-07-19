From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Fri, 19 Jul 2024 17:12:41 +0100
Subject: [PATCH kmod 1/3] libkmod: document
 KMOD_INDEX_MODULES_BUILTIN_ALIAS in kmod_dump_index()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240719-abi-fixes-v1-1-1e6d99a2846b@gmail.com>
References: <20240719-abi-fixes-v1-0-1e6d99a2846b@gmail.com>
In-Reply-To: <20240719-abi-fixes-v1-0-1e6d99a2846b@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Marco d'Itri <md@linux.it>, Eugene Syromiatnikov <esyr@redhat.com>, 
 Josh Boyer <jwboyer@fedoraproject.org>, 
 Yauheni Kaliuta <ykaliuta@fedoraproject.org>, 
 Alexey Gladkov <gladkov.alexey@gmail.com>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721405562; l=1746;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=8AhtTXAyZZ10eWdz87tQwKwm866stviAIl/eVpSKW9U=;
 b=DB495+JOHzWaoxN3xLGaBrchoWkB1mvIa7tfARaIdUPZBMCoX/bHAf3YOHOrohst9OfbFmlf0
 vgvXqYM92ryCI05jNUfGdBx6VF21rSpkzkeKlZzk5bbbfGyK665WZTc
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The extra enum was introduced a few years ago, although the (only)
function using it did not have it's documentation updated.

The commit itself has caused an ABI break with kmod v27, since the
KMOD_INDEX_MODULES_BUILTIN value has changed.

A search through Google, Github and Arch packages have shown one user of
kmod_dump_index() - the only API that uses the enum.

In that case and all others, no projects referencing the changed enum
were found. Although since recent and/or supported distros use kmod v27
or later we've decided to only update the documentation.

Cc: Alexey Gladkov <gladkov.alexey@gmail.com>
Fixes: b866b21 ("Lookup aliases in the modules.builtin.modinfo")
Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
The project itself being https://github.com/falconindy/modtree which
hasn't been updated in 12 years.

The following distros/versions ship kmod v26 or older, where bunch of
them are no longer supported.

 - RHEL 8 + community variants Alma/Amazon/CentOS/Rocky/Scientific
 - Alpine Linux 3.11
 - Debian 10 + derivatives
 - Ubuntu 18.04
---
 libkmod/libkmod.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/libkmod/libkmod.c b/libkmod/libkmod.c
index 213b424..fecb8e7 100644
--- a/libkmod/libkmod.c
+++ b/libkmod/libkmod.c
@@ -971,6 +971,7 @@ KMOD_EXPORT void kmod_unload_resources(struct kmod_ctx *ctx)
  * KMOD_INDEX_MODULES_DEP: index of module dependencies;
  * KMOD_INDEX_MODULES_ALIAS: index of module aliases;
  * KMOD_INDEX_MODULES_SYMBOL: index of symbol aliases;
+ * KMOD_INDEX_MODULES_BUILTIN_ALIAS: index of builtin module aliases.
  * KMOD_INDEX_MODULES_BUILTIN: index of builtin module.
  * @fd: file descriptor to dump index to
  *

-- 
2.45.2

