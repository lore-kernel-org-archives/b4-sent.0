From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Fri, 19 Jul 2024 17:12:42 +0100
Subject: [PATCH kmod 2/3] libkmod: correctly tag
 kmod_module_new_from_name_lookup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240719-abi-fixes-v1-2-1e6d99a2846b@gmail.com>
References: <20240719-abi-fixes-v1-0-1e6d99a2846b@gmail.com>
In-Reply-To: <20240719-abi-fixes-v1-0-1e6d99a2846b@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Marco d'Itri <md@linux.it>, Eugene Syromiatnikov <esyr@redhat.com>, 
 Josh Boyer <jwboyer@fedoraproject.org>, 
 Yauheni Kaliuta <ykaliuta@fedoraproject.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721405562; l=1620;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=M4YnV9+hVYcdsO1S8HqSahF+HvXqm0LQJKAHn27gLdo=;
 b=CWvNKRHtB3FB1a1Ns3kXWRUkuOZzV8crymOuKk7taaxD9SKalrBrpN117Ll3tDdj1Npu7nlHX
 xauKNpyRmAqBrY/24bMrQr1xhG4LTH27jif7eKi4X9Ir+c4dQQ9ery5
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The symbol was introduced with v30, yet was erroneously added in the v5
section. Move it to the correct place.

In theory this might cause an issue - severity depends on how the
runtime linker is setup. From a harmless warning (on stderr/stdout) to
failure to load the library.

In practise this shouldn't be a problem, since there are seemingly no
external users of the API.

Fixes: 9becaae ("libkmod: Add lookup from module name")
Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
I'm fairly confident this commit won't cause an issue, although auditing
the whole internet is not possible in practise. In my search I checked
through Google, Github and all Arch packages using libkmod, namely:

 - dracut
 - igt-gpu-tools
 - libblockdev
 - ndctl
 - open-scsi
 - pciutils
 - stress-ng
 - systemd

Another option is to make the symbol as internal, since it's used solely
by modinfo which static links libkmod.

...we could also leave things as-is.
---
 libkmod/libkmod.sym | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/libkmod/libkmod.sym b/libkmod/libkmod.sym
index 0d6d338..e71f488 100644
--- a/libkmod/libkmod.sym
+++ b/libkmod/libkmod.sym
@@ -31,7 +31,6 @@ global:
 	kmod_module_new_from_name;
 	kmod_module_new_from_path;
 	kmod_module_new_from_lookup;
-	kmod_module_new_from_name_lookup;
 	kmod_module_new_from_loaded;
 	kmod_module_ref;
 	kmod_module_unref;
@@ -94,3 +93,8 @@ LIBKMOD_22 {
 global:
 	kmod_get_dirname;
 } LIBKMOD_6;
+
+LIBKMOD_30 {
+global:
+	kmod_module_new_from_name_lookup;
+} LIBKMOD_22;

-- 
2.45.2

