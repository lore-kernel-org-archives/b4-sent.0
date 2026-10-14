From: =?utf-8?q?Santiago_Mill=C3=A1n?= <santimillang@gmail.com>
Date: Wed, 14 Oct 2026 12:56:02 +0200
Subject: [PATCH] drm/tests: bridge: Document struct fmt_tuple members
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261014-drm-bridge-test-kdoc-v1-1-883f7ec8bcfa@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMFfz2oC/yXMQQrCMBCF4auUWTuQ1BDFq4iLJhl1FFOZSaVQc
 vemdvnxeP8CSsKkcOkWEPqx8pgb7KGD+Bzyg5BTM/Sm99ZYh0k+GIRTWwppwXcaIw7Ok7PnY/A
 nA+36Fbrz/M9eb7t1Ci+KZWtBrStnu/fJeAAAAA==
X-Change-ID: 20261014-drm-bridge-test-kdoc-a46e4183b670
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Daniel Stone <daniel@fooishbar.org>, 
 Nicolas Frattaroli <nicolas.frattaroli@collabora.com>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 kernel test robot <lkp@intel.com>, 
 =?utf-8?q?Santiago_Mill=C3=A1n?= <santimillang@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791975361; l=1388;
 i=santimillang@gmail.com; s=20261014; h=from:subject:message-id;
 bh=xBhEKNdRFSh2ZCArxhg9+cTIQT8Sm2LYQdWKl1M7dMc=;
 b=bx87YpYiKOgpkhPmHQ9IzqIXl65n38C8Pfnm9Nzvn7+bHii9hlVO9J3QPzSJhyfc/m0WqYEzQ
 2dlbosQr900DKESl5AVhAnFVjMKzm6LmYjk3x2aSaY5g26FNR3UUz9E
X-Developer-Key: i=santimillang@gmail.com; a=ed25519;
 pk=53GrtI4i/ZCeWuXdQe6gXlcTQdbMxKlYzTUEI0heuV0=
X-Endpoint-Received: by B4 Relay for santimillang@gmail.com/20261014 with auth_id=1175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The kernel-doc comment for struct fmt_tuple does not describe its
in_fmt and out_fmt members, so W=1 builds warn:

  struct member 'in_fmt' not described in 'fmt_tuple'
  struct member 'out_fmt' not described in 'fmt_tuple'

Add descriptions for both members.

Fixes: 082fbc179c01 ("drm/tests: bridge: Add KUnit tests for bridge chain format selection")
Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202606120201.5E4O2N7N-lkp@intel.com/
Signed-off-by: Santiago Millán <santimillang@gmail.com>
---
 drivers/gpu/drm/tests/drm_bridge_test.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/gpu/drm/tests/drm_bridge_test.c b/drivers/gpu/drm/tests/drm_bridge_test.c
index 15583ade8494..b79d7b8b2d32 100644
--- a/drivers/gpu/drm/tests/drm_bridge_test.c
+++ b/drivers/gpu/drm/tests/drm_bridge_test.c
@@ -123,6 +123,8 @@ static const struct drm_bridge_funcs drm_test_bridge_bus_fmts_funcs = {
 
 /**
  * struct fmt_tuple - a tuple of input/output MEDIA_BUS_FMT_*
+ * @in_fmt: input bus format accepted by the bridge
+ * @out_fmt: output bus format the bridge can produce from @in_fmt
  */
 struct fmt_tuple {
 	u32 in_fmt;

---
base-commit: dfc3c7b84d43e7de918686e5cd7dd49196a5f45e
change-id: 20261014-drm-bridge-test-kdoc-a46e4183b670

Best regards,
--  
Santiago Millán <santimillang@gmail.com>

