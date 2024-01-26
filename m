From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Fri, 26 Jan 2024 14:43:50 +0000
Subject: [PATCH 1/2] configure: tweak the module_directory help string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240126-master-v1-1-6257d039a30a@gmail.com>
References: <20240126-master-v1-0-6257d039a30a@gmail.com>
In-Reply-To: <20240126-master-v1-0-6257d039a30a@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706280230; l=981;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=odADJmMZHmCPpeUZVqD+kpI2Vt0oc+W3kHqA6aS9tIY=;
 b=AUcT2Of6cwHxxOx17QvN93TZCuSf+he/xRj0n3Qx5IYkq00JgFeKhRlmtOLzPoUJPxcu5rohS
 dBY/mzpSSSzBka4yGK8799Q4nadMspw9Hz+DIByk1zSvHYeY4xLcM3x
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

Drop the somewhat misleading ${prefix}/lib/modules and explicitly
mention what's the default.

Signed-off-by: Emil Velikov <emil.velikov@collabora.com>
---
 configure.ac | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/configure.ac b/configure.ac
index de01e08..ab0b303 100644
--- a/configure.ac
+++ b/configure.ac
@@ -93,7 +93,7 @@ AC_SUBST([rootlibdir], [$with_rootlibdir])
 
 # Ideally this would be $prefix/lib/modules but default to /lib/modules for compatibility with earlier versions
 AC_ARG_WITH([module_directory],
-        AS_HELP_STRING([--with-module-directory=DIR], [directory in which to look for kernel modules - typically '/lib/modules' or '${prefix}/lib/modules']),
+        AS_HELP_STRING([--with-module-directory=DIR], [directory in which to look for kernel modules @<:@default=/lib/modules@:>@]),
         [], [with_module_directory=/lib/modules])
 AC_SUBST([module_directory], [$with_module_directory])
 

-- 
2.43.0

