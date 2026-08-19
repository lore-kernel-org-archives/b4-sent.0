From: Jonas Juffinger <jonas.juffinger@liebherr.com>
Date: Wed, 19 Aug 2026 10:21:37 +0200
Subject: [PATCH] kernel-fit-image: Don't add hash node when signing is
 enabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260819-bugfix-dont-add-hash-node-to-signed-fit-images-v1-1-c0ffc1a0fc17@liebherr.com>
X-B4-Tracking: v=1; b=H4sIAJBnhWoC/x2NsQ7CMAwFf6XyzJOSDED5FcSQxm7igQTFBSFV/
 XcixhvubieTrmJ0m3bq8lHTVgf400SpxJoFyoMpuHB2Vz9jeedVv+BWN0RmlGgFtbFgazDNVRi
 rbtBnzGLwIS4uzeHik9CIvroM/T+8P47jB6lowVmAAAAA
To: openembedded-core@lists.openembedded.org
Cc: Jonas Juffinger <jonas.juffinger@liebherr.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787127703; l=1359;
 i=jonas.juffinger@liebherr.com; s=20260615; h=from:subject:message-id;
 bh=dtNhGWXLaF9vg94YLb4ySsWG4N9Rg6SxtwNTftjmrlU=;
 b=A5p/LCa7sXh/hlb7HsIH3pCpPLkaL8j0mC8eWHaPXzZYxvkuGlsD0/Le6/va6Dx4MxUFCf+xK
 tgWByAHxK+3AnKb+WAo4ruS7QmHnkryZzLpZIUfLHgRnn9twpPIcMW9
X-Developer-Key: i=jonas.juffinger@liebherr.com; a=ed25519;
 pk=57Vzs2aKTP3E7TDrBuZMQibGR+Koattc4oIhiMOs3FI=
X-Endpoint-Received: by B4 Relay for jonas.juffinger@liebherr.com/20260615 with auth_id=821
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When configuration signing is enabled, mkimage does not fill
the hash node even if it present. This causes the verification
to fail with a "Bad Data Hash' error because the hash exists
but it empty.

This patch adds a check to only add the hash node if signing
is not enabled.

The example FIT from the official documentation also shows
the configuration field with only the signature, without the
hash field:
https://docs.u-boot.org/en/latest/usage/fit/signature.html#signed-configurations

Signed-off-by: Jonas Juffinger <jonas.juffinger@liebherr.com>
---
 meta/lib/oe/fitimage.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/meta/lib/oe/fitimage.py b/meta/lib/oe/fitimage.py
index d4dacdd508..142a5d60f7 100644
--- a/meta/lib/oe/fitimage.py
+++ b/meta/lib/oe/fitimage.py
@@ -485,7 +485,7 @@ class ItsNodeRootKernel(ItsNode):
             f"{default_flag} {', '.join(conf_desc)}",
             opt_props=opt_props
         )
-        if self._hash_algo:
+        if self._hash_algo and not self._sign_enable:
             ItsNodeHash(
                 "hash-1",
                 conf_node,

---
base-commit: 6f7a806ece411ab32e4b1c08a0299400bdf3b588
change-id: 20260819-bugfix-dont-add-hash-node-to-signed-fit-images-12ab0c9271ce

Best regards,
-- 
Jonas Juffinger <jonas.juffinger@liebherr.com>

