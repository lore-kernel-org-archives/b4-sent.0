From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 18 Dec 2024 11:30:04 +0100
Subject: [PATCH 10/12] bringup: Use full path when creating custom_source
 file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241218-jag-bringup_fixes-v1-10-0bf2e07c640c@kernel.org>
References: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
In-Reply-To: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=940;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=l/flaod/aZKoU8m0yBnBUBZzRVVykVMk2fVKTOumNQU=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGdipDC19P9j5CpqAmnwsR0L2mlmJ1dunLF2q
 ILFlLYc4AD5R4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnYqQwAAoJELqXzVK3
 lkFPee4L/3DDhjxLkW0GUmv7nGfX4HLGs/+Ucgx+wkO7d8o4yFpTOfJXOFWqC41DMW73GFYoHgA
 r+MQnew3TWK7JEWqDLHBhKd7opkojk72iEp86PZREzzhtxTuDg6baYU4jamwo/AloJoF8SP/bIN
 +1ceMQYHOHWYcjJCl4jww7bJZ9h8aNPa+6fiF6ktcs1FxzqArD+VDIEEfAmGlkCd0zhXFMFZnAB
 QczwqBtWbB5kUfBQSNDJe5x9o/r95D2Fck6ZqMcsTdMe0Uob6ACYEt27GPjQfzBgSOl2Gp1Ptbu
 JHsSuNs3NYHTLNngzdktPIoYhgt4oB7IxWOgRibRandWvUeHpd8kHnEtEU4Bl8sOEijWiRPUUKi
 aIrvx1JOLntuInJlZ4aI1gnULLPEbIAzJyTIB/fdxX8BEUBmhETfwuPwYkvk9X8WPWJukjF17tU
 +9ak04Qy9Ten8kAj15qYiir8O0a1RWbfPF9wOWMsClfc4JyhmfWeLuzoD9l8aBc/qR+V82uah75
 Dc=
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

