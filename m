From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 04 Feb 2025 21:10:34 +0100
Subject: [PATCH] build: Replace meson introspection argument with a
 builddir
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250204-jag-fix_meson-v1-1-ecb6bdb1db51@kernel.org>
X-B4-Tracking: v=1; b=H4sIADl0omcC/x2MWwqAIBAAryL7neDzo64SEZabbZCGQgTS3ZM+h
 2GmQsFMWGBgFTLeVCjFBrJjsO4uBuTkG4MSygolDD9c4Bs984klRW60X4xXvdDSQmuujE3+v3F
 63w/xCzuaXwAAAA==
X-Change-ID: 20250204-jag-fix_meson-43db4d290315
To: qemu-devel@nongnu.org
Cc: Paolo Bonzini <pbonzini@redhat.com>, 
 =?utf-8?q?Alex_Benn=C3=A9e?= <alex.bennee@linaro.org>, 
 Thomas Huth <thuth@redhat.com>, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.15-dev-64da2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1262;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=n903QA//BBYKpY4cOT1+2ldqqv5Gmu9LPXH4tfYVe+M=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGeidEdVR4Y+ouemPf1zTZjEMaNRJFn89bnt4
 dgnUdtMIAj4A4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnonRHAAoJELqXzVK3
 lkFPuDUL/3uPcT7NKjoHmxwSq470mQp0rmGM0CqaKYBCZWBSJxdaQw6uhViGUT1C8PXWp/kWY+O
 tEtyUyhiD5V3HIc5i7X8bveN4A+potmEJaJ2LWf8sIJcMWFPlENh2wOzk1DpGRy0Y/8c1Y0B4Wv
 fJteBBO9XAICnim88PhzpXkt9ia0KeNHKrbq7nhE2p2WXDjIB4wCrUyR1tM55A4FTKTLoxDP3nh
 qJLgK2VRbJOkuRx4UfTl0VYfQiar5UT/9m60YXg4/ueighvMAOUhbt4JoRlrRjZ6OIBil8x6y5D
 W21VwLubidLzKf5MiZDlo8T260HqhklvaDh+WGSdC8hd96Q5exgKjC1FCiUzkPyzlaqQsMP48ta
 QY5Gt+HbPbK5NUSCBJ/3kAkwi2rL7Da3vYcU4n7Q2/zuKwbQh5KAJ2VcLF4MJLUgMMYyTv0rTy0
 8Cvza78hO4HNoZyg1c3yR4ipwtxExlQQb/fm9UKcG+Gd5bG73T6AhlXON1peDDiYxBj3kajTEU7
 HA=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the meson introspect argument with the build directory instead
of the meson.build file. The introspect command accepts an optional
build directory not a file.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
For some reason this causes an error when I "remote" compile qemu.
In any case, the introspect only accepts directories, so having it point
the to the meson.build file is a mistake.

Comments are greatly appreciated
---
 Makefile | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Makefile b/Makefile
index b65b0bd41a..da88d9bb31 100644
--- a/Makefile
+++ b/Makefile
@@ -129,7 +129,7 @@ Makefile.mtest: build.ninja scripts/mtest2make.py
 .PHONY: update-buildoptions
 all update-buildoptions: $(SRC_PATH)/scripts/meson-buildoptions.sh
 $(SRC_PATH)/scripts/meson-buildoptions.sh: $(SRC_PATH)/meson_options.txt
-	$(MESON) introspect --buildoptions $(SRC_PATH)/meson.build | $(PYTHON) \
+	$(MESON) introspect --buildoptions $(BUILD_DIR) | $(PYTHON) \
 	  scripts/meson-buildoptions.py > $@.tmp && mv $@.tmp $@
 endif
 

---
base-commit: d922088eb4ba6bc31a99f17b32cf75e59dd306cd
change-id: 20250204-jag-fix_meson-43db4d290315

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

