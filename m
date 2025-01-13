From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 13 Jan 2025 12:53:08 +0100
Subject: [PATCH RESEND 10/12] bringup: Use full path when creating
 custom_source file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250113-jag-bringup_fixes-v1-10-fb28030b1f26@kernel.org>
References: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
In-Reply-To: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, mcgrof@kernel.org, 
 da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=940;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=l/flaod/aZKoU8m0yBnBUBZzRVVykVMk2fVKTOumNQU=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGeE/qfa1sJ/HfBa0mocYc6jdWvtDJGVW76R5
 dtpfyE7fZXNO4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnhP6nAAoJELqXzVK3
 lkFPcnoL/06qw5gdDicKVyr0fk5l2fgFSOjzS/iUc9mc3MNq7gk3d0oqKcCby0EIifsUgnmQN9F
 4HeisSoWUbyf2t9+qjyoeaIAxa6CaI0biYnEK7tWBNFQJqHbIHFJUx+45eDTPXci7AeiwpiQtb/
 pMtai2YWEcofAoMH24Ne8kr6dv7I1azhQGLs2vzgJML5sHTPAL0nYDcH1s32N90QFUffdaPMVox
 i82sTQr189RRrpoUnFANqxSybYpfV9za0848o2rtnQLm0HNrnr5Bj+xsbdGe2BJLMOyVEiYDacY
 2aXsLmZhsGpuommtJfekJM0Dy07bvcNePtxDvDhA1xMgXqNcM3H9xFuJsYNv4vihJvj8DPbnLCJ
 bbdmdL3ADwukSbLlzTPUwBA/+3fnrGDNMNEfBG5f8KEJORUtCbpxFwbJLzsU1FclS2RpAz6flO5
 xFLxaQXr3VI/fI8z4hZjqI0FWCWPQxPJPPhTTD/jbHyHg6L6kz6BOFzeUjUBfJvyMa7QFOqfAD6
 Dk=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Avoid "file not found" failures related to relative paths in
custom_source

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 scripts/bringup_guestfs.sh | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/scripts/bringup_guestfs.sh b/scripts/bringup_guestfs.sh
index 74eecea..f49fd12 100755
--- a/scripts/bringup_guestfs.sh
+++ b/scripts/bringup_guestfs.sh
@@ -34,7 +34,7 @@ build_custom_source()
 	SOURCE_TMP=$(mktemp)
 	cat <<_EOT >$SOURCE_TMP
 [local]
-uri=file:///${CUSTOM_INDEX}
+uri=file:///${REAL_CUSTOM_INDEX}
 proxy=off
 _EOT
 	sudo mv $SOURCE_TMP $CUSTOM_SOURCE
@@ -111,6 +111,7 @@ build_custom_image()
 	CUSTOM_IMAGE_OK="${CUSTOM_IMAGE_DIR}.ok"
 	CUSTOM_SOURCE="/etc/virt-builder/repos.d/kdevops-custom-images-${OS_VERSION}.conf"
 	CUSTOM_INDEX="${CUSTOM_IMAGE_DIR}/index"
+	REAL_CUSTOM_INDEX="$(realpath $CUSTOM_INDEX)"
 
 	mkdir -p ${CUSTOM_IMAGE_DIR}
 

-- 
2.44.2

