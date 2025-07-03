From: Benjamin Missey <benjamin.missey@non.se.com>
Date: Thu, 03 Jul 2025 15:21:55 +0200
Subject: [PATCH] kernel-fit-image: fix symbolic link fit-image.its
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250703-fix_typo_kernel_fit_image_bbclass-v1-1-2f1857f1466b@non.se.com>
X-B4-Tracking: v=1; b=H4sIAPKDZmgC/x2NzQrCMBAGX6Xs2UBsDP68ipQlTb/UxZqWbBGl9
 N0NHucwMxspikDp1mxU8BaVOVc4HhqKj5BHGBkqU2tbb8/WmSQfXr/LzE+UjImTrCyvMIL7Pk5
 B1USHIZ2uwbuLp9pZCqr0f9y7ff8Bw5pDjXMAAAA=
To: openembedded-core@lists.openembedded.org
Cc: pascal.eberhard@se.com, Benjamin Missey <benjamin.missey@non.se.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751548929; l=1205;
 i=benjamin.missey@non.se.com; s=20250620; h=from:subject:message-id;
 bh=VZXY6XMGgfZM2Ki6yfw6FoZm+iOjyCZSwwTwDNidL6c=;
 b=lR9ROplyeyuepZysfNXHF90cQD8mz5cvVcKGgh9RXEUAaYPEFiW5Ue4EUos6czDTDdGlwLEqT
 1urRAMmg9pKCMCb0Mv78Hy1hitPoyopMWLJ1mXP2ZzjPvnzJYdmjyFW
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
base-commit: d1c39b29f21719b349072c51a761fa19770a49ea
change-id: 20250703-fix_typo_kernel_fit_image_bbclass-c3edf49a5385

Best regards,
-- 
Benjamin Missey <benjamin.missey@non.se.com>

