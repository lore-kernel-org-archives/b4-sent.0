From: Benjamin Missey <benjamin.missey@non.se.com>
Date: Fri, 04 Jul 2025 11:20:31 +0200
Subject: [PATCH] kernel-fit-image: fix symbolic link fit-image.its
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250704-fix_typo_kernel_fit_image_bbclass-v1-1-b30b07126469@non.se.com>
X-B4-Tracking: v=1; b=H4sIAN6cZ2gC/x2NQQqDMBAAvyJ7biCmitqvlLLEuNFFGyUrooh/N
 3icw8ycIBSZBD7ZCZE2Fp5DgvyVgRts6ElxlxiMNqWudKE877gey4wjxUATel6R/7YnbFs3WRF
 lC+N0U9dl5d+QOkukJD2P7++6bnpL7fRzAAAA
To: openembedded-core@lists.openembedded.org
Cc: pascal.eberhard@se.com, Benjamin Missey <benjamin.missey@non.se.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751620841; l=1205;
 i=benjamin.missey@non.se.com; s=20250620; h=from:subject:message-id;
 bh=TON0k6AXlo565FrIe2ZnTiaFCI8bZoW2lQ6EtL8r3fQ=;
 b=02ypVho0/c1npgZrwzklevxn1hewt8+QbPJEr2vW0uEQWZykNY9wmQttVnMsrc1ZBZ/N8DSHb
 JQOmkSydYXcAkLDO+QCDD380bLzOnC2wC17cOwT8XTCFK1epoygobvP
X-Developer-Key: i=benjamin.missey@non.se.com; a=ed25519;
 pk=HehU6MOmKShwMy0xbM2FC7HuoJnsSlKtZKWSTRRy1Do=
X-Endpoint-Received: by B4 Relay for benjamin.missey@non.se.com/20250620 with auth_id=437
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Bad symbolic link is used for kernel-fit-image. fit-image-its used
instead of fit-image.its.
Fix bad typo.

Signed-off-by: Benjamin Missey <benjamin.missey@non.se.com>
---
 meta/classes-recipe/kernel-fit-image.bbclass | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/meta/classes-recipe/kernel-fit-image.bbclass b/meta/classes-recipe/kernel-fit-image.bbclass
index 39845997ed..fd4c6a30fe 100644
--- a/meta/classes-recipe/kernel-fit-image.bbclass
+++ b/meta/classes-recipe/kernel-fit-image.bbclass
@@ -173,7 +173,7 @@ do_deploy() {
     fi
 
     if [ -n "${INITRAMFS_IMAGE}" ]; then
-        ln -snf fit-image-its "$deploy_dir/fitImage-its-${INITRAMFS_IMAGE_NAME}-${KERNEL_FIT_NAME}.its"
+        ln -snf fit-image.its "$deploy_dir/fitImage-its-${INITRAMFS_IMAGE_NAME}-${KERNEL_FIT_NAME}.its"
         if [ -n "${KERNEL_FIT_LINK_NAME}" ]; then
             ln -snf fit-image.its "$deploy_dir/fitImage-its-${INITRAMFS_IMAGE_NAME}-${KERNEL_FIT_LINK_NAME}"
         fi

---
base-commit: 77a93e8cf1da4231341c56f64f9d4d474f9f2bb7
change-id: 20250704-fix_typo_kernel_fit_image_bbclass-a42c098857f3

Best regards,
-- 
Benjamin Missey <benjamin.missey@non.se.com>

