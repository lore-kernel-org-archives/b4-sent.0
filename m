From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Fri, 19 Jul 2024 17:12:43 +0100
Subject: [PATCH kmod 3/3] libkmod: move new weak API to separate section
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240719-abi-fixes-v1-3-1e6d99a2846b@gmail.com>
References: <20240719-abi-fixes-v1-0-1e6d99a2846b@gmail.com>
In-Reply-To: <20240719-abi-fixes-v1-0-1e6d99a2846b@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Marco d'Itri <md@linux.it>, Eugene Syromiatnikov <esyr@redhat.com>, 
 Josh Boyer <jwboyer@fedoraproject.org>, 
 Yauheni Kaliuta <ykaliuta@fedoraproject.org>, 
 Jose Ignacio Tornos Martinez <jtornosm@redhat.com>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721405562; l=1334;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=vGLxbr7hhKT9ywrDmQYwW4P0+rL1j1tEnx5Lr/UUei0=;
 b=HkChS8BpMWSSsXkfB88Of9BJ3gC2qimdMCLTgfjlqyPIHnrwE1GaU/SjNRxecEZUABX/Y2HTE
 k1drtkMMPJeC8heA5dbSw7qoJsPjIGAhOqS0BbBnvaReZ5moP7k4IFK
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the new weak API, to a separate section in the version script. These
will be exposed with the upcoming v33 release and not with v5 as the
symbol tag implies.

Cc: Jose Ignacio Tornos Martinez <jtornosm@redhat.com>
Fixes: 05828b4 ("libkmod: add weak dependecies")
Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
This might be a bit of nuisance for Debian which has a git packages in
unstable.

@Marco I think you'd _really_ want this for unstable.
---
 libkmod/libkmod.sym | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/libkmod/libkmod.sym b/libkmod/libkmod.sym
index e71f488..0046300 100644
--- a/libkmod/libkmod.sym
+++ b/libkmod/libkmod.sym
@@ -21,7 +21,6 @@ global:
 	kmod_config_get_aliases;
 	kmod_config_get_options;
 	kmod_config_get_softdeps;
-	kmod_config_get_weakdeps;
 	kmod_config_iter_get_key;
 	kmod_config_iter_get_value;
 	kmod_config_iter_next;
@@ -42,7 +41,6 @@ global:
 
 	kmod_module_get_dependencies;
 	kmod_module_get_softdeps;
-	kmod_module_get_weakdeps;
 	kmod_module_get_filtered_blacklist;
 
 	kmod_module_get_name;
@@ -98,3 +96,9 @@ LIBKMOD_30 {
 global:
 	kmod_module_new_from_name_lookup;
 } LIBKMOD_22;
+
+LIBKMOD_33 {
+global:
+	kmod_config_get_weakdeps;
+	kmod_module_get_weakdeps;
+} LIBKMOD_30;

-- 
2.45.2

