From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 08 May 2026 18:39:09 +0200
Subject: [PATCH 06/10] example: silence add_languages warning by setting
 'native: false'
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-new-mount-fixes-and-tests-v1-6-c67a0893ddbc@bsbernd.com>
References: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
In-Reply-To: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=835; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=2T00swt99g8sLBC7Xl3XVQfaKOApIVe39HlqufcWIVE=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGDL/Ca4V4k0LUPy4Va197XHh6RJzIxRb+1L2/vOf1Wi67
 ubFHzcedJSyMIhxMMiKKbJ0SeyxnfKPT1bt6/rrMHNYmUCGMHBxCsBEShYy/DMQ0qo+1KDV7Z12
 x7jh6tzb+9cfYj9WcPEHoySzwLzpIesY/oeo9l2PDfthEnHM95ftDo0FK48IlBz7mP+G6U96QfX
 vR3wA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The C++ examples (passthrough_hp, memfs_ll) link against libfuse,
i.e. there is no cross compilation from example/ point of view.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 example/meson.build | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/example/meson.build b/example/meson.build
index 76cf2d96..31e69187 100644
--- a/example/meson.build
+++ b/example/meson.build
@@ -32,7 +32,7 @@ foreach ex : threaded_examples
                install: false)
 endforeach
 
-if platform != 'dragonfly' and add_languages('cpp', required : false)
+if platform != 'dragonfly' and add_languages('cpp', native : false, required : false)
     executable('passthrough_hp', 'passthrough_hp.cc',
                dependencies: [ thread_dep, libfuse_dep ],
                install: false)

-- 
2.53.0

