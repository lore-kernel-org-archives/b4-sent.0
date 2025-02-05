From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 05 Feb 2025 09:50:51 +0100
Subject: [PATCH v2] bringup: Use full path when creating custom_source file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250205-jag-bringup_fixes-v2-1-48f70c0d0a08@kernel.org>
X-B4-Tracking: v=1; b=H4sIAGomo2cC/22NwQrCMBBEf6Xs2Uh2CVY8+R9SpI3bdFXSstGgl
 P67seDN45vhzcyQWIUTHKoZlLMkGWMB2lTghzYGNnIpDGTJIWFtrm0wnUoMz+ncy4uTIcc9dt4
 RYgvFm5TXominpvAg6THqe73I+E1/a/s/axmNNbbriW3td87644018n07aoBmWZYP+g32MbMAA
 AA=
X-Change-ID: 20241217-jag-bringup_fixes-24ef1bc4211a
To: Luis Chamberlain <mcgrof@kernel.org>, 
 Daniel Gomez <da.gomez@samsung.com>
Cc: kdevops@lists.linux.dev, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.15-dev-64da2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1474;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=cvXy/yFqYcvqf90EjZ/XNMPUxCh0tms83z3EobnIfeE=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGejJnvYM5S7jEvHbH18O1ZwtvNQAD0Y3GjAl
 y0CcAybqOf0OYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnoyZ7AAoJELqXzVK3
 lkFPNVUL/1MiQudcpI+LDfiBo2Q8Fbk9Us+5l6krgnoFMESZt+NSMX3UlTHgiQcqkSMJM5PETJM
 MhBZ3wnbfCUckV8dkxWT9tsIT8X9ZTlKKPQ64hoNWN18QFn2A28olaI8fGkS98ltm4KUbsThDNC
 cjN8V7rOWlgzsmIpHL+pQmQJfsRIexep1HdZvYNSSsxiPqeVTsf6KRo97TKADuS78TuyLEjss69
 s2UyunF52+FxkYm4SfUaipMP9EzZ9NK8kEF++1SpAn5dvBIRcKX0UenesnsDnQe5tQ4FatEe4OI
 s5KoZMeXHig6pPcWX3rZpyf7gffdJz8URu5VM4/Bg1wlfYtU9glb6Quk8p8SW6H5zKfm/UdJirL
 WI36voxvYBzFFD/NQCMeRBrsxToAGgeAliPZXbOUIs2tcdLrMHjoz/SarLxYw9PRkbMDmB2nO73
 Y/JkGwVDxp/yCiSyKM/E6wl2nY8lmlhb+3dpOnrJFGheAH3PDyoXD3EpxqhjCWEAMIpGAz8dRp5
 nE=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Avoid "file not found" failures related to relative paths in
custom_source

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
After discussion in the list there is only one patch remaining. I have
dropped the ones that were "shot down" and kept the one that makes sure
we use full paths instead of relative; which seems to be a good idea.

Changes in v2:
- Only one patch remains : "[PATCH RESEND 10/12] bringup: Use full path
  when creating custom_source file", because some have already gone into
  mainline and some other were "shot down"
- Link to v1: https://lore.kernel.org/r/20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org
---

---
 scripts/bringup_guestfs.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/scripts/bringup_guestfs.sh b/scripts/bringup_guestfs.sh
index 74eecea..2c41999 100755
--- a/scripts/bringup_guestfs.sh
+++ b/scripts/bringup_guestfs.sh
@@ -110,7 +110,7 @@ build_custom_image()
 	CUSTOM_IMAGE="${CUSTOM_IMAGE_DIR}/${OS_VERSION}.raw"
 	CUSTOM_IMAGE_OK="${CUSTOM_IMAGE_DIR}.ok"
 	CUSTOM_SOURCE="/etc/virt-builder/repos.d/kdevops-custom-images-${OS_VERSION}.conf"
-	CUSTOM_INDEX="${CUSTOM_IMAGE_DIR}/index"
+	CUSTOM_INDEX="$(realpath ${CUSTOM_IMAGE_DIR}/index)"
 
 	mkdir -p ${CUSTOM_IMAGE_DIR}
 

---
base-commit: 4bffd17ac6a3ac757a26897a75ffa185d623a8e4
change-id: 20241217-jag-bringup_fixes-24ef1bc4211a

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

