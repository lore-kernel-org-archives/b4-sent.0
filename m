From: Yoann Congal <yoann.congal@smile.fr>
Date: Wed, 27 May 2026 14:27:35 +0200
Subject: [PATCH] linux-yocto/6.6: update CVE exclusions (6.6.127)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-ycongal-scarthgap-linux_metrics_warnings-v1-1-686416a84804@smile.fr>
X-B4-Tracking: v=1; b=H4sIADbjFmoC/x3NQQqDQAxA0atI1g3ogLX0KqVIOmbGgI2S2NYi3
 r1Dl2/z/w7OJuxwrXYwfovLrAXNqYI4kmZGGYoh1OFct6HDb5w104QeydYx04KT6Gvrn7yaRO8
 /ZCqaHR+podSF4dISQcktxkm2/+p2P44fVLB0PXoAAAA=
X-Change-ID: 20260527-ycongal-scarthgap-linux_metrics_warnings-bf1af72d85aa
To: openembedded-core@lists.openembedded.org
Cc: Yoann Congal <yoann.congal@smile.fr>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779884873; l=148241;
 i=yoann.congal@smile.fr; s=20260527; h=from:subject:message-id;
 bh=H/B6dVFd3+UVP5at32taYX9elr3mdPjVRtih4jIJaT4=;
 b=Ndd1v3MMe0bXZrnKv5rbvCqI2AIp7JwZ+cFXCSJqdI+2tBnVyx0J4vir13Ient4htpKKMPBtp
 QTjpZ9CSetmBrD1I1BAAjBdENmxYH7ezRgfb9yxJmBery6fgIcB7vrX
X-Developer-Key: i=yoann.congal@smile.fr; a=ed25519;
 pk=AccXM/XSn9zzv1zYXEM/MdcAaQ7cluqUBg1xzwrqNts=
X-Endpoint-Received: by B4 Relay for yoann.congal@smile.fr/20260527 with auth_id=796
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Regenerated to fix this warning:
WARNING: linux-yocto-6.6.127+git-r0 do_cve_check: Kernel CVE status needs updating: generated for 6.6.123 but kernel is 6.6.127

$ ./meta/recipes-kernel/linux/generate-cve-exclusions.py .../cvelistV5/ 6.6.127 > meta/recipes-kernel/linux/cve-exclusion_6.6.inc

Generated at 2026-05-27 12:02:49.732909+00:00 for kernel version 6.6.127
From cvelistV5 cve_2026-05-27_0900Z

Signed-off-by: Yoann Congal <yoann.congal@smile.fr>
---
 meta/recipes-kernel/linux/cve-exclusion_6.6.inc | 2462 ++++++++++++++++++++---
 1 file changed, 2208 insertions(+), 254 deletions(-)

diff --git a/meta/recipes-kernel/linux/cve-exclusion_6.6.inc b/meta/recipes-kernel/linux/cve-exclusion_6.6.inc
index 99f4ebcdd9fade809b79f18119b814bc2e23a9b5..fcd38c56aed55b6c5b2e160d9d84fb297f98a9fe 100644
--- a/meta/recipes-kernel/linux/cve-exclusion_6.6.inc
+++ b/meta/recipes-kernel/linux/cve-exclusion_6.6.inc
@@ -1,11 +1,11 @@
 
 # Auto-generated CVE metadata, DO NOT EDIT BY HAND.
-# Generated at 2026-04-03 09:30:32.247568+00:00 for kernel version 6.6.123
-# From cvelistV5 cve_2026-04-03_0700Z
+# Generated at 2026-05-27 12:02:49.732909+00:00 for kernel version 6.6.127
+# From cvelistV5 cve_2026-05-27_0900Z
 
 
 python check_kernel_cve_status_version() {
-    this_version = "6.6.123"
+    this_version = "6.6.127"
     kernel_version = d.getVar("LINUX_VERSION")
     if kernel_version != this_version:
         bb.warn("Kernel CVE status needs updating: generated for %s but kernel is %s" % (this_version, kernel_version))
@@ -6634,7 +6634,7 @@ CVE_STATUS[CVE-2023-52918] = "cpe-stable-backport: Backported in 6.6.48"
 
 CVE_STATUS[CVE-2023-52919] = "fixed-version: Fixed from version 6.6"
 
-CVE_STATUS[CVE-2023-52920] = "cpe-stable-backport: Backported in 6.6.70"
+# CVE-2023-52920 may need backporting (fixed from 6.6.140)
 
 CVE_STATUS[CVE-2023-52921] = "fixed-version: Fixed from version 6.5"
 
@@ -6752,7 +6752,7 @@ CVE_STATUS[CVE-2023-53010] = "fixed-version: Fixed from version 6.2"
 
 CVE_STATUS[CVE-2023-53011] = "fixed-version: Fixed from version 6.2"
 
-# CVE-2023-53012 has no known resolution
+CVE_STATUS[CVE-2023-53012] = "fixed-version: Fixed from version 6.1"
 
 CVE_STATUS[CVE-2023-53013] = "fixed-version: Fixed from version 6.2"
 
@@ -7064,7 +7064,7 @@ CVE_STATUS[CVE-2023-53185] = "fixed-version: Fixed from version 6.5"
 
 CVE_STATUS[CVE-2023-53186] = "fixed-version: Fixed from version 6.3"
 
-# CVE-2023-53187 has no known resolution
+CVE_STATUS[CVE-2023-53187] = "fixed-version: Fixed from version 5.16"
 
 CVE_STATUS[CVE-2023-53188] = "fixed-version: Fixed from version 6.3"
 
@@ -9030,7 +9030,7 @@ CVE_STATUS[CVE-2023-54326] = "fixed-version: Fixed from version 6.5"
 
 CVE_STATUS[CVE-2023-7324] = "fixed-version: Fixed from version 6.3"
 
-# CVE-2024-14027 may need backporting (fixed from 6.6.131)
+# CVE-2024-14027 may need backporting (fixed from 6.6.133)
 
 CVE_STATUS[CVE-2024-26581] = "cpe-stable-backport: Backported in 6.6.17"
 
@@ -9732,7 +9732,7 @@ CVE_STATUS[CVE-2024-26947] = "cpe-stable-backport: Backported in 6.6.24"
 
 # CVE-2024-26948 needs backporting (fixed from 6.9)
 
-CVE_STATUS[CVE-2024-26949] = "fixed-version: only affects 6.7 onwards"
+CVE_STATUS[CVE-2024-26949] = "fixed-version: only affects 6.7.9 onwards"
 
 CVE_STATUS[CVE-2024-26950] = "cpe-stable-backport: Backported in 6.6.24"
 
@@ -9758,7 +9758,7 @@ CVE_STATUS[CVE-2024-26960] = "cpe-stable-backport: Backported in 6.6.24"
 
 CVE_STATUS[CVE-2024-26961] = "cpe-stable-backport: Backported in 6.6.24"
 
-CVE_STATUS[CVE-2024-26962] = "fixed-version: only affects 6.7 onwards"
+# CVE-2024-26962 may need backporting (fixed from 6.7)
 
 CVE_STATUS[CVE-2024-26963] = "cpe-stable-backport: Backported in 6.6.24"
 
@@ -9824,7 +9824,7 @@ CVE_STATUS[CVE-2024-26995] = "fixed-version: only affects 6.8 onwards"
 
 CVE_STATUS[CVE-2024-26996] = "cpe-stable-backport: Backported in 6.6.29"
 
-CVE_STATUS[CVE-2024-26997] = "cpe-stable-backport: Backported in 6.6.29"
+CVE_STATUS[CVE-2024-26997] = "fixed-version: only affects 6.7.12 onwards"
 
 CVE_STATUS[CVE-2024-26998] = "cpe-stable-backport: Backported in 6.6.29"
 
@@ -9874,7 +9874,7 @@ CVE_STATUS[CVE-2024-27020] = "cpe-stable-backport: Backported in 6.6.29"
 
 CVE_STATUS[CVE-2024-27021] = "fixed-version: only affects 6.8 onwards"
 
-# CVE-2024-27022 needs backporting (fixed from 6.9)
+# CVE-2024-27022 may need backporting (fixed from 6.6.134)
 
 CVE_STATUS[CVE-2024-27023] = "cpe-stable-backport: Backported in 6.6.19"
 
@@ -10460,7 +10460,7 @@ CVE_STATUS[CVE-2024-35981] = "cpe-stable-backport: Backported in 6.6.29"
 
 CVE_STATUS[CVE-2024-35982] = "cpe-stable-backport: Backported in 6.6.28"
 
-CVE_STATUS[CVE-2024-35983] = "cpe-stable-backport: Backported in 6.6.30"
+CVE_STATUS[CVE-2024-35983] = "fixed-version: only affects 6.7.12 onwards"
 
 CVE_STATUS[CVE-2024-35984] = "cpe-stable-backport: Backported in 6.6.30"
 
@@ -10498,7 +10498,7 @@ CVE_STATUS[CVE-2024-36000] = "cpe-stable-backport: Backported in 6.6.30"
 
 CVE_STATUS[CVE-2024-36001] = "fixed-version: only affects 6.8 onwards"
 
-CVE_STATUS[CVE-2024-36002] = "fixed-version: only affects 6.8.2 onwards"
+CVE_STATUS[CVE-2024-36002] = "fixed-version: only affects 6.7.11 onwards"
 
 CVE_STATUS[CVE-2024-36003] = "cpe-stable-backport: Backported in 6.6.30"
 
@@ -10568,7 +10568,7 @@ CVE_STATUS[CVE-2024-36281] = "cpe-stable-backport: Backported in 6.6.33"
 
 CVE_STATUS[CVE-2024-36286] = "cpe-stable-backport: Backported in 6.6.33"
 
-CVE_STATUS[CVE-2024-36288] = "fixed-version: only affects 6.9.3 onwards"
+CVE_STATUS[CVE-2024-36288] = "fixed-version: only affects 6.8.12 onwards"
 
 CVE_STATUS[CVE-2024-36476] = "cpe-stable-backport: Backported in 6.6.70"
 
@@ -10806,7 +10806,7 @@ CVE_STATUS[CVE-2024-38540] = "cpe-stable-backport: Backported in 6.6.33"
 
 CVE_STATUS[CVE-2024-38541] = "cpe-stable-backport: Backported in 6.6.33"
 
-CVE_STATUS[CVE-2024-38542] = "fixed-version: only affects 6.8 onwards"
+CVE_STATUS[CVE-2024-38542] = "fixed-version: only affects 6.8.2 onwards"
 
 CVE_STATUS[CVE-2024-38543] = "cpe-stable-backport: Backported in 6.6.33"
 
@@ -10912,7 +10912,7 @@ CVE_STATUS[CVE-2024-38593] = "cpe-stable-backport: Backported in 6.6.33"
 
 CVE_STATUS[CVE-2024-38594] = "cpe-stable-backport: Backported in 6.6.55"
 
-CVE_STATUS[CVE-2024-38595] = "fixed-version: only affects 6.8 onwards"
+CVE_STATUS[CVE-2024-38595] = "fixed-version: only affects 6.8.7 onwards"
 
 CVE_STATUS[CVE-2024-38596] = "cpe-stable-backport: Backported in 6.6.33"
 
@@ -11172,9 +11172,9 @@ CVE_STATUS[CVE-2024-40918] = "cpe-stable-backport: Backported in 6.6.35"
 
 CVE_STATUS[CVE-2024-40919] = "cpe-stable-backport: Backported in 6.6.35"
 
-CVE_STATUS[CVE-2024-40920] = "cpe-stable-backport: Backported in 6.6.35"
+CVE_STATUS[CVE-2024-40920] = "fixed-version: only affects 6.8.12 onwards"
 
-CVE_STATUS[CVE-2024-40921] = "cpe-stable-backport: Backported in 6.6.35"
+CVE_STATUS[CVE-2024-40921] = "fixed-version: only affects 6.8.12 onwards"
 
 CVE_STATUS[CVE-2024-40922] = "cpe-stable-backport: Backported in 6.6.35"
 
@@ -11300,7 +11300,7 @@ CVE_STATUS[CVE-2024-40984] = "cpe-stable-backport: Backported in 6.6.36"
 
 CVE_STATUS[CVE-2024-40985] = "fixed-version: only affects 6.7 onwards"
 
-CVE_STATUS[CVE-2024-40986] = "fixed-version: only affects 6.9 onwards"
+CVE_STATUS[CVE-2024-40986] = "fixed-version: only affects 6.8.9 onwards"
 
 CVE_STATUS[CVE-2024-40987] = "cpe-stable-backport: Backported in 6.6.36"
 
@@ -11624,9 +11624,9 @@ CVE_STATUS[CVE-2024-42109] = "cpe-stable-backport: Backported in 6.6.39"
 
 CVE_STATUS[CVE-2024-42110] = "cpe-stable-backport: Backported in 6.6.39"
 
-CVE_STATUS[CVE-2024-42111] = "fixed-version: only affects 6.9 onwards"
+CVE_STATUS[CVE-2024-42111] = "fixed-version: only affects 6.8.10 onwards"
 
-CVE_STATUS[CVE-2024-42112] = "fixed-version: only affects 6.9 onwards"
+CVE_STATUS[CVE-2024-42112] = "fixed-version: only affects 6.8.12 onwards"
 
 CVE_STATUS[CVE-2024-42113] = "cpe-stable-backport: Backported in 6.6.39"
 
@@ -11696,7 +11696,7 @@ CVE_STATUS[CVE-2024-42148] = "cpe-stable-backport: Backported in 6.6.39"
 
 CVE_STATUS[CVE-2024-42149] = "fixed-version: only affects 6.8 onwards"
 
-CVE_STATUS[CVE-2024-42150] = "fixed-version: only affects 6.9 onwards"
+CVE_STATUS[CVE-2024-42150] = "fixed-version: only affects 6.8.12 onwards"
 
 CVE_STATUS[CVE-2024-42151] = "fixed-version: only affects 6.8 onwards"
 
@@ -11930,7 +11930,7 @@ CVE_STATUS[CVE-2024-43818] = "cpe-stable-backport: Backported in 6.6.44"
 
 # CVE-2024-43819 needs backporting (fixed from 6.11)
 
-CVE_STATUS[CVE-2024-43820] = "fixed-version: only affects 6.9 onwards"
+CVE_STATUS[CVE-2024-43820] = "fixed-version: only affects 6.7.12 onwards"
 
 CVE_STATUS[CVE-2024-43821] = "cpe-stable-backport: Backported in 6.6.44"
 
@@ -11966,7 +11966,7 @@ CVE_STATUS[CVE-2024-43836] = "fixed-version: only affects 6.10 onwards"
 
 CVE_STATUS[CVE-2024-43837] = "cpe-stable-backport: Backported in 6.6.44"
 
-CVE_STATUS[CVE-2024-43838] = "fixed-version: only affects 6.10 onwards"
+CVE_STATUS[CVE-2024-43838] = "fixed-version: only affects 6.9.8 onwards"
 
 CVE_STATUS[CVE-2024-43839] = "cpe-stable-backport: Backported in 6.6.44"
 
@@ -12152,7 +12152,7 @@ CVE_STATUS[CVE-2024-44949] = "cpe-stable-backport: Backported in 6.6.46"
 
 CVE_STATUS[CVE-2024-44950] = "cpe-stable-backport: Backported in 6.6.64"
 
-CVE_STATUS[CVE-2024-44951] = "fixed-version: only affects 6.8 onwards"
+# CVE-2024-44951 may need backporting (fixed from 6.7)
 
 CVE_STATUS[CVE-2024-44953] = "fixed-version: only affects 6.8 onwards"
 
@@ -12810,7 +12810,7 @@ CVE_STATUS[CVE-2024-47709] = "cpe-stable-backport: Backported in 6.6.54"
 
 CVE_STATUS[CVE-2024-47710] = "cpe-stable-backport: Backported in 6.6.54"
 
-CVE_STATUS[CVE-2024-47711] = "fixed-version: only affects 6.10 onwards"
+CVE_STATUS[CVE-2024-47711] = "fixed-version: only affects 6.9.8 onwards"
 
 CVE_STATUS[CVE-2024-47712] = "cpe-stable-backport: Backported in 6.6.54"
 
@@ -12928,7 +12928,7 @@ CVE_STATUS[CVE-2024-49852] = "cpe-stable-backport: Backported in 6.6.54"
 
 CVE_STATUS[CVE-2024-49853] = "cpe-stable-backport: Backported in 6.6.54"
 
-# CVE-2024-49854 has no known resolution
+CVE_STATUS[CVE-2024-49854] = "fixed-version: Fixed from version 5.11"
 
 CVE_STATUS[CVE-2024-49855] = "cpe-stable-backport: Backported in 6.6.54"
 
@@ -13292,7 +13292,7 @@ CVE_STATUS[CVE-2024-50040] = "cpe-stable-backport: Backported in 6.6.57"
 
 CVE_STATUS[CVE-2024-50041] = "cpe-stable-backport: Backported in 6.6.57"
 
-CVE_STATUS[CVE-2024-50042] = "fixed-version: only affects 6.8 onwards"
+CVE_STATUS[CVE-2024-50042] = "fixed-version: only affects 6.7.10 onwards"
 
 CVE_STATUS[CVE-2024-50043] = "fixed-version: only affects 6.9 onwards"
 
@@ -13392,7 +13392,7 @@ CVE_STATUS[CVE-2024-50095] = "cpe-stable-backport: Backported in 6.6.57"
 
 CVE_STATUS[CVE-2024-50096] = "cpe-stable-backport: Backported in 6.6.57"
 
-CVE_STATUS[CVE-2024-50097] = "cpe-stable-backport: Backported in 6.6.57"
+CVE_STATUS[CVE-2024-50097] = "fixed-version: only affects 6.10.14 onwards"
 
 CVE_STATUS[CVE-2024-50098] = "cpe-stable-backport: Backported in 6.6.58"
 
@@ -13602,13 +13602,13 @@ CVE_STATUS[CVE-2024-50201] = "cpe-stable-backport: Backported in 6.6.58"
 
 CVE_STATUS[CVE-2024-50202] = "cpe-stable-backport: Backported in 6.6.58"
 
-CVE_STATUS[CVE-2024-50203] = "fixed-version: only affects 6.11 onwards"
+CVE_STATUS[CVE-2024-50203] = "fixed-version: only affects 6.10.3 onwards"
 
 CVE_STATUS[CVE-2024-50204] = "fixed-version: only affects 6.11 onwards"
 
 CVE_STATUS[CVE-2024-50205] = "cpe-stable-backport: Backported in 6.6.59"
 
-CVE_STATUS[CVE-2024-50206] = "fixed-version: only affects 6.10 onwards"
+CVE_STATUS[CVE-2024-50206] = "fixed-version: only affects 6.9.6 onwards"
 
 CVE_STATUS[CVE-2024-50207] = "fixed-version: only affects 6.8 onwards"
 
@@ -13668,13 +13668,13 @@ CVE_STATUS[CVE-2024-50236] = "cpe-stable-backport: Backported in 6.6.60"
 
 CVE_STATUS[CVE-2024-50237] = "cpe-stable-backport: Backported in 6.6.60"
 
-CVE_STATUS[CVE-2024-50238] = "fixed-version: only affects 6.9 onwards"
+CVE_STATUS[CVE-2024-50238] = "fixed-version: only affects 6.8.2 onwards"
 
 CVE_STATUS[CVE-2024-50239] = "cpe-stable-backport: Backported in 6.6.60"
 
 CVE_STATUS[CVE-2024-50240] = "cpe-stable-backport: Backported in 6.6.60"
 
-CVE_STATUS[CVE-2024-50241] = "fixed-version: only affects 6.11.3 onwards"
+CVE_STATUS[CVE-2024-50241] = "fixed-version: only affects 6.10.14 onwards"
 
 CVE_STATUS[CVE-2024-50242] = "cpe-stable-backport: Backported in 6.6.60"
 
@@ -13690,7 +13690,7 @@ CVE_STATUS[CVE-2024-50247] = "cpe-stable-backport: Backported in 6.6.60"
 
 CVE_STATUS[CVE-2024-50248] = "cpe-stable-backport: Backported in 6.6.60"
 
-CVE_STATUS[CVE-2024-50249] = "cpe-stable-backport: Backported in 6.6.60"
+CVE_STATUS[CVE-2024-50249] = "fixed-version: only affects 6.10.13 onwards"
 
 CVE_STATUS[CVE-2024-50250] = "cpe-stable-backport: Backported in 6.6.60"
 
@@ -13754,7 +13754,7 @@ CVE_STATUS[CVE-2024-50279] = "cpe-stable-backport: Backported in 6.6.61"
 
 CVE_STATUS[CVE-2024-50280] = "cpe-stable-backport: Backported in 6.6.61"
 
-CVE_STATUS[CVE-2024-50281] = "fixed-version: only affects 6.11 onwards"
+CVE_STATUS[CVE-2024-50281] = "fixed-version: only affects 6.10.7 onwards"
 
 CVE_STATUS[CVE-2024-50282] = "cpe-stable-backport: Backported in 6.6.61"
 
@@ -13874,7 +13874,7 @@ CVE_STATUS[CVE-2024-53071] = "fixed-version: only affects 6.10 onwards"
 
 CVE_STATUS[CVE-2024-53072] = "cpe-stable-backport: Backported in 6.6.61"
 
-CVE_STATUS[CVE-2024-53073] = "fixed-version: only affects 6.11.3 onwards"
+CVE_STATUS[CVE-2024-53073] = "fixed-version: only affects 6.10.14 onwards"
 
 CVE_STATUS[CVE-2024-53074] = "fixed-version: only affects 6.9 onwards"
 
@@ -13922,7 +13922,7 @@ CVE_STATUS[CVE-2024-53095] = "cpe-stable-backport: Backported in 6.6.62"
 
 CVE_STATUS[CVE-2024-53096] = "cpe-stable-backport: Backported in 6.6.63"
 
-CVE_STATUS[CVE-2024-53097] = "cpe-stable-backport: Backported in 6.6.62"
+CVE_STATUS[CVE-2024-53097] = "fixed-version: only affects 6.10.14 onwards"
 
 CVE_STATUS[CVE-2024-53098] = "fixed-version: only affects 6.8 onwards"
 
@@ -13956,7 +13956,7 @@ CVE_STATUS[CVE-2024-53113] = "cpe-stable-backport: Backported in 6.6.63"
 
 # CVE-2024-53114 needs backporting (fixed from 6.12)
 
-CVE_STATUS[CVE-2024-53115] = "fixed-version: only affects 6.11 onwards"
+CVE_STATUS[CVE-2024-53115] = "fixed-version: only affects 6.10.4 onwards"
 
 CVE_STATUS[CVE-2024-53116] = "fixed-version: only affects 6.10 onwards"
 
@@ -13992,7 +13992,7 @@ CVE_STATUS[CVE-2024-53131] = "cpe-stable-backport: Backported in 6.6.63"
 
 CVE_STATUS[CVE-2024-53132] = "fixed-version: only affects 6.11 onwards"
 
-CVE_STATUS[CVE-2024-53133] = "fixed-version: only affects 6.8 onwards"
+CVE_STATUS[CVE-2024-53133] = "fixed-version: only affects 6.7.12 onwards"
 
 CVE_STATUS[CVE-2024-53134] = "cpe-stable-backport: Backported in 6.6.63"
 
@@ -14062,7 +14062,7 @@ CVE_STATUS[CVE-2024-53167] = "fixed-version: only affects 6.11 onwards"
 
 CVE_STATUS[CVE-2024-53168] = "cpe-stable-backport: Backported in 6.6.64"
 
-CVE_STATUS[CVE-2024-53169] = "fixed-version: only affects 6.11 onwards"
+CVE_STATUS[CVE-2024-53169] = "fixed-version: only affects 6.10.7 onwards"
 
 CVE_STATUS[CVE-2024-53170] = "cpe-stable-backport: Backported in 6.6.74"
 
@@ -14126,7 +14126,7 @@ CVE_STATUS[CVE-2024-53199] = "fixed-version: only affects 6.11 onwards"
 
 CVE_STATUS[CVE-2024-53200] = "cpe-stable-backport: Backported in 6.6.64"
 
-CVE_STATUS[CVE-2024-53201] = "fixed-version: only affects 6.11 onwards"
+CVE_STATUS[CVE-2024-53201] = "fixed-version: only affects 6.11.3 onwards"
 
 CVE_STATUS[CVE-2024-53202] = "cpe-stable-backport: Backported in 6.6.64"
 
@@ -14222,7 +14222,7 @@ CVE_STATUS[CVE-2024-53690] = "cpe-stable-backport: Backported in 6.6.68"
 
 CVE_STATUS[CVE-2024-54031] = "cpe-stable-backport: Backported in 6.6.70"
 
-CVE_STATUS[CVE-2024-54191] = "fixed-version: only affects 6.12.2 onwards"
+CVE_STATUS[CVE-2024-54191] = "fixed-version: only affects 6.11.11 onwards"
 
 CVE_STATUS[CVE-2024-54193] = "fixed-version: only affects 6.7 onwards"
 
@@ -14232,7 +14232,7 @@ CVE_STATUS[CVE-2024-54456] = "cpe-stable-backport: Backported in 6.6.79"
 
 CVE_STATUS[CVE-2024-54458] = "cpe-stable-backport: Backported in 6.6.79"
 
-CVE_STATUS[CVE-2024-54460] = "fixed-version: only affects 6.9 onwards"
+CVE_STATUS[CVE-2024-54460] = "fixed-version: only affects 6.8.12 onwards"
 
 CVE_STATUS[CVE-2024-54683] = "cpe-stable-backport: Backported in 6.6.67"
 
@@ -14274,7 +14274,7 @@ CVE_STATUS[CVE-2024-56540] = "fixed-version: only affects 6.8 onwards"
 
 CVE_STATUS[CVE-2024-56541] = "fixed-version: only affects 6.10 onwards"
 
-CVE_STATUS[CVE-2024-56542] = "fixed-version: only affects 6.11 onwards"
+CVE_STATUS[CVE-2024-56542] = "fixed-version: only affects 6.11.2 onwards"
 
 CVE_STATUS[CVE-2024-56543] = "cpe-stable-backport: Backported in 6.6.64"
 
@@ -14290,7 +14290,7 @@ CVE_STATUS[CVE-2024-56548] = "cpe-stable-backport: Backported in 6.6.64"
 
 CVE_STATUS[CVE-2024-56549] = "cpe-stable-backport: Backported in 6.6.78"
 
-CVE_STATUS[CVE-2024-56550] = "fixed-version: only affects 6.10 onwards"
+CVE_STATUS[CVE-2024-56550] = "fixed-version: only affects 6.9.4 onwards"
 
 CVE_STATUS[CVE-2024-56551] = "cpe-stable-backport: Backported in 6.6.64"
 
@@ -14312,7 +14312,7 @@ CVE_STATUS[CVE-2024-56559] = "fixed-version: only affects 6.9 onwards"
 
 CVE_STATUS[CVE-2024-56560] = "fixed-version: only affects 6.12 onwards"
 
-CVE_STATUS[CVE-2024-56561] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2024-56561] = "fixed-version: only affects 6.11.4 onwards"
 
 CVE_STATUS[CVE-2024-56562] = "cpe-stable-backport: Backported in 6.6.64"
 
@@ -14482,7 +14482,7 @@ CVE_STATUS[CVE-2024-56645] = "cpe-stable-backport: Backported in 6.6.66"
 
 CVE_STATUS[CVE-2024-56646] = "fixed-version: only affects 6.9 onwards"
 
-# CVE-2024-56647 needs backporting (fixed from 6.13)
+# CVE-2024-56647 may need backporting (fixed from 6.6.140)
 
 CVE_STATUS[CVE-2024-56648] = "cpe-stable-backport: Backported in 6.6.66"
 
@@ -14728,7 +14728,7 @@ CVE_STATUS[CVE-2024-56779] = "cpe-stable-backport: Backported in 6.6.64"
 
 CVE_STATUS[CVE-2024-56780] = "cpe-stable-backport: Backported in 6.6.64"
 
-CVE_STATUS[CVE-2024-56782] = "fixed-version: only affects 6.9 onwards"
+CVE_STATUS[CVE-2024-56782] = "fixed-version: only affects 6.8.6 onwards"
 
 CVE_STATUS[CVE-2024-56783] = "cpe-stable-backport: Backported in 6.6.66"
 
@@ -14760,7 +14760,7 @@ CVE_STATUS[CVE-2024-57802] = "cpe-stable-backport: Backported in 6.6.70"
 
 # CVE-2024-57804 needs backporting (fixed from 6.13)
 
-CVE_STATUS[CVE-2024-57805] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2024-57805] = "fixed-version: only affects 6.11.6 onwards"
 
 CVE_STATUS[CVE-2024-57806] = "fixed-version: only affects 6.7 onwards"
 
@@ -14784,7 +14784,7 @@ CVE_STATUS[CVE-2024-57849] = "cpe-stable-backport: Backported in 6.6.66"
 
 CVE_STATUS[CVE-2024-57850] = "cpe-stable-backport: Backported in 6.6.66"
 
-CVE_STATUS[CVE-2024-57852] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2024-57852] = "fixed-version: only affects 6.11.8 onwards"
 
 # CVE-2024-57857 needs backporting (fixed from 6.13)
 
@@ -14800,7 +14800,7 @@ CVE_STATUS[CVE-2024-57877] = "fixed-version: only affects 6.12 onwards"
 
 CVE_STATUS[CVE-2024-57878] = "fixed-version: only affects 6.9 onwards"
 
-CVE_STATUS[CVE-2024-57879] = "fixed-version: only affects 6.9 onwards"
+CVE_STATUS[CVE-2024-57879] = "fixed-version: only affects 6.8.12 onwards"
 
 CVE_STATUS[CVE-2024-57880] = "fixed-version: only affects 6.10 onwards"
 
@@ -14906,7 +14906,7 @@ CVE_STATUS[CVE-2024-57933] = "cpe-stable-backport: Backported in 6.6.70"
 
 CVE_STATUS[CVE-2024-57934] = "fixed-version: only affects 6.11 onwards"
 
-CVE_STATUS[CVE-2024-57935] = "fixed-version: only affects 6.12.2 onwards"
+CVE_STATUS[CVE-2024-57935] = "fixed-version: only affects 6.11.11 onwards"
 
 CVE_STATUS[CVE-2024-57936] = "fixed-version: only affects 6.12 onwards"
 
@@ -14938,7 +14938,7 @@ CVE_STATUS[CVE-2024-57950] = "fixed-version: only affects 6.11 onwards"
 
 CVE_STATUS[CVE-2024-57951] = "cpe-stable-backport: Backported in 6.6.74"
 
-CVE_STATUS[CVE-2024-57952] = "fixed-version: only affects 6.11 onwards"
+CVE_STATUS[CVE-2024-57952] = "fixed-version: only affects 6.10.7 onwards"
 
 CVE_STATUS[CVE-2024-57953] = "fixed-version: only affects 6.8 onwards"
 
@@ -14976,7 +14976,7 @@ CVE_STATUS[CVE-2024-57988] = "fixed-version: only affects 6.9 onwards"
 
 CVE_STATUS[CVE-2024-57989] = "fixed-version: only affects 6.11 onwards"
 
-CVE_STATUS[CVE-2024-57990] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2024-57990] = "fixed-version: only affects 6.10.13 onwards"
 
 CVE_STATUS[CVE-2024-57991] = "fixed-version: only affects 6.13 onwards"
 
@@ -15012,7 +15012,7 @@ CVE_STATUS[CVE-2024-58005] = "cpe-stable-backport: Backported in 6.6.78"
 
 CVE_STATUS[CVE-2024-58007] = "cpe-stable-backport: Backported in 6.6.78"
 
-CVE_STATUS[CVE-2024-58008] = "fixed-version: only affects 6.11 onwards"
+CVE_STATUS[CVE-2024-58008] = "fixed-version: only affects 6.10.7 onwards"
 
 CVE_STATUS[CVE-2024-58009] = "cpe-stable-backport: Backported in 6.6.78"
 
@@ -15106,7 +15106,7 @@ CVE_STATUS[CVE-2024-58079] = "cpe-stable-backport: Backported in 6.6.78"
 
 CVE_STATUS[CVE-2024-58080] = "cpe-stable-backport: Backported in 6.6.78"
 
-CVE_STATUS[CVE-2024-58081] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2024-58081] = "fixed-version: only affects 6.11.10 onwards"
 
 CVE_STATUS[CVE-2024-58082] = "fixed-version: only affects 6.7 onwards"
 
@@ -15154,7 +15154,7 @@ CVE_STATUS[CVE-2024-58239] = "cpe-stable-backport: Backported in 6.6.19"
 
 CVE_STATUS[CVE-2024-58240] = "cpe-stable-backport: Backported in 6.6.21"
 
-CVE_STATUS[CVE-2024-58241] = "fixed-version: only affects 6.10 onwards"
+# CVE-2024-58241 may need backporting (fixed from 6.7)
 
 CVE_STATUS[CVE-2025-21629] = "cpe-stable-backport: Backported in 6.6.70"
 
@@ -15368,7 +15368,7 @@ CVE_STATUS[CVE-2025-21737] = "fixed-version: only affects 6.10 onwards"
 
 CVE_STATUS[CVE-2025-21738] = "cpe-stable-backport: Backported in 6.6.78"
 
-# CVE-2025-21739 needs backporting (fixed from 6.14)
+# CVE-2025-21739 may need backporting (fixed from 6.6.135)
 
 CVE_STATUS[CVE-2025-21741] = "cpe-stable-backport: Backported in 6.6.78"
 
@@ -15392,7 +15392,7 @@ CVE_STATUS[CVE-2025-21750] = "cpe-stable-backport: Backported in 6.6.78"
 
 CVE_STATUS[CVE-2025-21751] = "fixed-version: only affects 6.12 onwards"
 
-CVE_STATUS[CVE-2025-21752] = "fixed-version: only affects 6.7 onwards"
+CVE_STATUS[CVE-2025-21752] = "fixed-version: only affects 6.6.130 onwards"
 
 CVE_STATUS[CVE-2025-21753] = "cpe-stable-backport: Backported in 6.6.78"
 
@@ -15502,7 +15502,7 @@ CVE_STATUS[CVE-2025-21807] = "fixed-version: only affects 6.9 onwards"
 
 CVE_STATUS[CVE-2025-21808] = "cpe-stable-backport: Backported in 6.6.76"
 
-CVE_STATUS[CVE-2025-21809] = "fixed-version: only affects 6.8 onwards"
+CVE_STATUS[CVE-2025-21809] = "fixed-version: only affects 6.7.3 onwards"
 
 CVE_STATUS[CVE-2025-21810] = "cpe-stable-backport: Backported in 6.6.76"
 
@@ -15510,7 +15510,7 @@ CVE_STATUS[CVE-2025-21811] = "cpe-stable-backport: Backported in 6.6.76"
 
 CVE_STATUS[CVE-2025-21812] = "cpe-stable-backport: Backported in 6.6.76"
 
-CVE_STATUS[CVE-2025-21813] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-21813] = "fixed-version: only affects 6.12.11 onwards"
 
 CVE_STATUS[CVE-2025-21814] = "cpe-stable-backport: Backported in 6.6.78"
 
@@ -15684,7 +15684,7 @@ CVE_STATUS[CVE-2025-21900] = "fixed-version: only affects 6.11 onwards"
 
 CVE_STATUS[CVE-2025-21901] = "fixed-version: only affects 6.12 onwards"
 
-CVE_STATUS[CVE-2025-21902] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-21902] = "fixed-version: only affects 6.12.5 onwards"
 
 CVE_STATUS[CVE-2025-21903] = "fixed-version: only affects 6.7 onwards"
 
@@ -15932,17 +15932,17 @@ CVE_STATUS[CVE-2025-22024] = "fixed-version: only affects 6.10 onwards"
 
 CVE_STATUS[CVE-2025-22025] = "cpe-stable-backport: Backported in 6.6.87"
 
-# CVE-2025-22026 may need backporting (fixed from 6.6.125)
+CVE_STATUS[CVE-2025-22026] = "cpe-stable-backport: Backported in 6.6.125"
 
 CVE_STATUS[CVE-2025-22027] = "cpe-stable-backport: Backported in 6.6.87"
 
 CVE_STATUS[CVE-2025-22028] = "cpe-stable-backport: Backported in 6.6.89"
 
-CVE_STATUS[CVE-2025-22030] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-22030] = "fixed-version: only affects 6.12.12 onwards"
 
 CVE_STATUS[CVE-2025-22031] = "fixed-version: only affects 6.13 onwards"
 
-CVE_STATUS[CVE-2025-22032] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-22032] = "fixed-version: only affects 6.12.13 onwards"
 
 CVE_STATUS[CVE-2025-22033] = "cpe-stable-backport: Backported in 6.6.87"
 
@@ -16016,7 +16016,7 @@ CVE_STATUS[CVE-2025-22067] = "fixed-version: only affects 6.12 onwards"
 
 CVE_STATUS[CVE-2025-22068] = "fixed-version: only affects 6.7 onwards"
 
-CVE_STATUS[CVE-2025-22069] = "fixed-version: only affects 6.14 onwards"
+CVE_STATUS[CVE-2025-22069] = "fixed-version: only affects 6.12.75 onwards"
 
 # CVE-2025-22070 needs backporting (fixed from 6.15)
 
@@ -16102,7 +16102,7 @@ CVE_STATUS[CVE-2025-22110] = "fixed-version: only affects 6.14 onwards"
 
 CVE_STATUS[CVE-2025-22111] = "cpe-stable-backport: Backported in 6.6.120"
 
-CVE_STATUS[CVE-2025-22112] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-22112] = "fixed-version: only affects 6.12.20 onwards"
 
 # CVE-2025-22113 needs backporting (fixed from 6.15)
 
@@ -16126,9 +16126,9 @@ CVE_STATUS[CVE-2025-22122] = "fixed-version: only affects 6.12 onwards"
 
 CVE_STATUS[CVE-2025-22123] = "fixed-version: only affects 6.9 onwards"
 
-CVE_STATUS[CVE-2025-22124] = "fixed-version: only affects 6.11 onwards"
+# CVE-2025-22124 may need backporting (fixed from 6.7)
 
-# CVE-2025-22125 needs backporting (fixed from 6.15)
+# CVE-2025-22125 may need backporting (fixed from 6.6.136)
 
 CVE_STATUS[CVE-2025-22126] = "cpe-stable-backport: Backported in 6.6.88"
 
@@ -16136,7 +16136,7 @@ CVE_STATUS[CVE-2025-22126] = "cpe-stable-backport: Backported in 6.6.88"
 
 CVE_STATUS[CVE-2025-22128] = "fixed-version: only affects 6.8 onwards"
 
-CVE_STATUS[CVE-2025-23129] = "fixed-version: only affects 6.7 onwards"
+# CVE-2025-23129 may need backporting (fixed from 6.7)
 
 # CVE-2025-23130 needs backporting (fixed from 6.15)
 
@@ -16222,13 +16222,13 @@ CVE_STATUS[CVE-2025-37745] = "fixed-version: only affects 6.9 onwards"
 
 CVE_STATUS[CVE-2025-37746] = "fixed-version: only affects 6.8 onwards"
 
-CVE_STATUS[CVE-2025-37747] = "fixed-version: only affects 6.11 onwards"
+# CVE-2025-37747 may need backporting (fixed from 6.7)
 
 CVE_STATUS[CVE-2025-37748] = "cpe-stable-backport: Backported in 6.6.88"
 
 CVE_STATUS[CVE-2025-37749] = "cpe-stable-backport: Backported in 6.6.88"
 
-CVE_STATUS[CVE-2025-37750] = "fixed-version: only affects 6.12 onwards"
+# CVE-2025-37750 may need backporting (fixed from 6.7)
 
 CVE_STATUS[CVE-2025-37751] = "fixed-version: only affects 6.14 onwards"
 
@@ -16246,7 +16246,7 @@ CVE_STATUS[CVE-2025-37758] = "cpe-stable-backport: Backported in 6.6.88"
 
 # CVE-2025-37759 needs backporting (fixed from 6.15)
 
-CVE_STATUS[CVE-2025-37760] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-37760] = "fixed-version: only affects 6.12.19 onwards"
 
 CVE_STATUS[CVE-2025-37761] = "fixed-version: only affects 6.8 onwards"
 
@@ -16348,7 +16348,7 @@ CVE_STATUS[CVE-2025-37812] = "cpe-stable-backport: Backported in 6.6.89"
 
 CVE_STATUS[CVE-2025-37813] = "cpe-stable-backport: Backported in 6.6.89"
 
-CVE_STATUS[CVE-2025-37814] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-37814] = "fixed-version: only affects 6.12.14 onwards"
 
 CVE_STATUS[CVE-2025-37815] = "cpe-stable-backport: Backported in 6.6.89"
 
@@ -16374,7 +16374,7 @@ CVE_STATUS[CVE-2025-37825] = "fixed-version: only affects 6.14 onwards"
 
 # CVE-2025-37826 needs backporting (fixed from 6.15)
 
-CVE_STATUS[CVE-2025-37827] = "fixed-version: only affects 6.11 onwards"
+CVE_STATUS[CVE-2025-37827] = "fixed-version: only affects 6.10.10 onwards"
 
 CVE_STATUS[CVE-2025-37828] = "cpe-stable-backport: Backported in 6.6.89"
 
@@ -16406,7 +16406,7 @@ CVE_STATUS[CVE-2025-37843] = "fixed-version: only affects 6.11 onwards"
 
 CVE_STATUS[CVE-2025-37844] = "cpe-stable-backport: Backported in 6.6.88"
 
-CVE_STATUS[CVE-2025-37845] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-37845] = "fixed-version: only affects 6.12.21 onwards"
 
 CVE_STATUS[CVE-2025-37846] = "fixed-version: only affects 6.7 onwards"
 
@@ -16452,13 +16452,13 @@ CVE_STATUS[CVE-2025-37866] = "fixed-version: only affects 6.14 onwards"
 
 CVE_STATUS[CVE-2025-37867] = "cpe-stable-backport: Backported in 6.6.88"
 
-CVE_STATUS[CVE-2025-37868] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-37868] = "fixed-version: only affects 6.12.19 onwards"
 
 CVE_STATUS[CVE-2025-37869] = "fixed-version: only affects 6.8 onwards"
 
 # CVE-2025-37870 needs backporting (fixed from 6.15)
 
-CVE_STATUS[CVE-2025-37871] = "cpe-stable-backport: Backported in 6.6.88"
+CVE_STATUS[CVE-2025-37871] = "fixed-version: only affects 6.13.11 onwards"
 
 CVE_STATUS[CVE-2025-37872] = "fixed-version: only affects 6.8 onwards"
 
@@ -16472,7 +16472,7 @@ CVE_STATUS[CVE-2025-37876] = "fixed-version: only affects 6.8 onwards"
 
 CVE_STATUS[CVE-2025-37877] = "fixed-version: only affects 6.12 onwards"
 
-CVE_STATUS[CVE-2025-37878] = "fixed-version: only affects 6.12.24 onwards"
+CVE_STATUS[CVE-2025-37878] = "fixed-version: only affects 6.13.12 onwards"
 
 CVE_STATUS[CVE-2025-37879] = "cpe-stable-backport: Backported in 6.6.89"
 
@@ -16506,7 +16506,7 @@ CVE_STATUS[CVE-2025-37893] = "cpe-stable-backport: Backported in 6.6.87"
 
 CVE_STATUS[CVE-2025-37894] = "fixed-version: only affects 6.10 onwards"
 
-CVE_STATUS[CVE-2025-37895] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-37895] = "fixed-version: only affects 6.12.10 onwards"
 
 CVE_STATUS[CVE-2025-37896] = "fixed-version: only affects 6.14 onwards"
 
@@ -16572,7 +16572,7 @@ CVE_STATUS[CVE-2025-37927] = "cpe-stable-backport: Backported in 6.6.90"
 
 CVE_STATUS[CVE-2025-37928] = "cpe-stable-backport: Backported in 6.6.90"
 
-CVE_STATUS[CVE-2025-37929] = "cpe-stable-backport: Backported in 6.6.90"
+CVE_STATUS[CVE-2025-37929] = "fixed-version: only affects 6.13.12 onwards"
 
 CVE_STATUS[CVE-2025-37930] = "cpe-stable-backport: Backported in 6.6.90"
 
@@ -16636,7 +16636,7 @@ CVE_STATUS[CVE-2025-37960] = "cpe-stable-backport: Backported in 6.6.92"
 
 CVE_STATUS[CVE-2025-37961] = "cpe-stable-backport: Backported in 6.6.91"
 
-CVE_STATUS[CVE-2025-37962] = "cpe-stable-backport: Backported in 6.6.91"
+CVE_STATUS[CVE-2025-37962] = "fixed-version: only affects 6.13.11 onwards"
 
 CVE_STATUS[CVE-2025-37963] = "cpe-stable-backport: Backported in 6.6.91"
 
@@ -16660,7 +16660,7 @@ CVE_STATUS[CVE-2025-37972] = "cpe-stable-backport: Backported in 6.6.91"
 
 CVE_STATUS[CVE-2025-37973] = "cpe-stable-backport: Backported in 6.6.91"
 
-CVE_STATUS[CVE-2025-37974] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-37974] = "fixed-version: only affects 6.12.5 onwards"
 
 CVE_STATUS[CVE-2025-37975] = "fixed-version: only affects 6.8 onwards"
 
@@ -16814,7 +16814,7 @@ CVE_STATUS[CVE-2025-38053] = "fixed-version: only affects 6.7 onwards"
 
 CVE_STATUS[CVE-2025-38054] = "fixed-version: only affects 6.9 onwards"
 
-CVE_STATUS[CVE-2025-38055] = "fixed-version: only affects 6.11 onwards"
+CVE_STATUS[CVE-2025-38055] = "fixed-version: only affects 6.10.5 onwards"
 
 CVE_STATUS[CVE-2025-38056] = "fixed-version: only affects 6.12 onwards"
 
@@ -16824,7 +16824,7 @@ CVE_STATUS[CVE-2025-38058] = "cpe-stable-backport: Backported in 6.6.93"
 
 CVE_STATUS[CVE-2025-38059] = "cpe-stable-backport: Backported in 6.6.93"
 
-CVE_STATUS[CVE-2025-38060] = "fixed-version: only affects 6.7 onwards"
+# CVE-2025-38060 may need backporting (fixed from 6.7)
 
 CVE_STATUS[CVE-2025-38061] = "cpe-stable-backport: Backported in 6.6.93"
 
@@ -16898,9 +16898,9 @@ CVE_STATUS[CVE-2025-38095] = "cpe-stable-backport: Backported in 6.6.92"
 
 CVE_STATUS[CVE-2025-38097] = "cpe-stable-backport: Backported in 6.6.93"
 
-CVE_STATUS[CVE-2025-38098] = "fixed-version: only affects 6.8 onwards"
+CVE_STATUS[CVE-2025-38098] = "fixed-version: only affects 6.7.2 onwards"
 
-CVE_STATUS[CVE-2025-38099] = "fixed-version: only affects 6.12.24 onwards"
+CVE_STATUS[CVE-2025-38099] = "fixed-version: only affects 6.13.12 onwards"
 
 CVE_STATUS[CVE-2025-38100] = "cpe-stable-backport: Backported in 6.6.94"
 
@@ -17026,7 +17026,7 @@ CVE_STATUS[CVE-2025-38160] = "cpe-stable-backport: Backported in 6.6.94"
 
 CVE_STATUS[CVE-2025-38161] = "cpe-stable-backport: Backported in 6.6.94"
 
-# CVE-2025-38162 may need backporting (fixed from 6.6.125)
+CVE_STATUS[CVE-2025-38162] = "cpe-stable-backport: Backported in 6.6.125"
 
 CVE_STATUS[CVE-2025-38163] = "cpe-stable-backport: Backported in 6.6.94"
 
@@ -17040,7 +17040,7 @@ CVE_STATUS[CVE-2025-38167] = "cpe-stable-backport: Backported in 6.6.94"
 
 CVE_STATUS[CVE-2025-38168] = "fixed-version: only affects 6.12 onwards"
 
-CVE_STATUS[CVE-2025-38169] = "fixed-version: only affects 6.10 onwards"
+CVE_STATUS[CVE-2025-38169] = "fixed-version: only affects 6.8.12 onwards"
 
 CVE_STATUS[CVE-2025-38170] = "cpe-stable-backport: Backported in 6.6.94"
 
@@ -17102,7 +17102,7 @@ CVE_STATUS[CVE-2025-38198] = "cpe-stable-backport: Backported in 6.6.95"
 
 CVE_STATUS[CVE-2025-38200] = "cpe-stable-backport: Backported in 6.6.95"
 
-# CVE-2025-38201 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2025-38201] = "cpe-stable-backport: Backported in 6.6.124"
 
 CVE_STATUS[CVE-2025-38202] = "cpe-stable-backport: Backported in 6.6.95"
 
@@ -17146,7 +17146,7 @@ CVE_STATUS[CVE-2025-38222] = "cpe-stable-backport: Backported in 6.6.95"
 
 CVE_STATUS[CVE-2025-38223] = "fixed-version: only affects 6.12 onwards"
 
-CVE_STATUS[CVE-2025-38224] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-38224] = "fixed-version: only affects 6.12.31 onwards"
 
 CVE_STATUS[CVE-2025-38225] = "cpe-stable-backport: Backported in 6.6.95"
 
@@ -17166,7 +17166,7 @@ CVE_STATUS[CVE-2025-38232] = "cpe-stable-backport: Backported in 6.6.122"
 
 CVE_STATUS[CVE-2025-38233] = "fixed-version: only affects 6.13 onwards"
 
-# CVE-2025-38234 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2025-38234] = "cpe-stable-backport: Backported in 6.6.124"
 
 CVE_STATUS[CVE-2025-38235] = "fixed-version: only affects 6.15 onwards"
 
@@ -17276,7 +17276,7 @@ CVE_STATUS[CVE-2025-38287] = "fixed-version: only affects 6.13 onwards"
 
 CVE_STATUS[CVE-2025-38288] = "fixed-version: only affects 6.12 onwards"
 
-CVE_STATUS[CVE-2025-38289] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-38289] = "fixed-version: only affects 6.12.5 onwards"
 
 CVE_STATUS[CVE-2025-38290] = "cpe-stable-backport: Backported in 6.6.94"
 
@@ -17348,7 +17348,7 @@ CVE_STATUS[CVE-2025-38323] = "cpe-stable-backport: Backported in 6.6.95"
 
 CVE_STATUS[CVE-2025-38324] = "cpe-stable-backport: Backported in 6.6.95"
 
-CVE_STATUS[CVE-2025-38325] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-38325] = "fixed-version: only affects 6.12.26 onwards"
 
 CVE_STATUS[CVE-2025-38326] = "cpe-stable-backport: Backported in 6.6.95"
 
@@ -17442,9 +17442,9 @@ CVE_STATUS[CVE-2025-38370] = "fixed-version: only affects 6.14 onwards"
 
 CVE_STATUS[CVE-2025-38371] = "cpe-stable-backport: Backported in 6.6.97"
 
-CVE_STATUS[CVE-2025-38372] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-38372] = "fixed-version: only affects 6.12.13 onwards"
 
-CVE_STATUS[CVE-2025-38373] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-38373] = "fixed-version: only affects 6.12.14 onwards"
 
 CVE_STATUS[CVE-2025-38374] = "fixed-version: only affects 6.8 onwards"
 
@@ -17506,7 +17506,7 @@ CVE_STATUS[CVE-2025-38403] = "cpe-stable-backport: Backported in 6.6.97"
 
 CVE_STATUS[CVE-2025-38404] = "cpe-stable-backport: Backported in 6.6.97"
 
-CVE_STATUS[CVE-2025-38405] = "fixed-version: only affects 6.11 onwards"
+CVE_STATUS[CVE-2025-38405] = "fixed-version: only affects 6.10.10 onwards"
 
 CVE_STATUS[CVE-2025-38406] = "cpe-stable-backport: Backported in 6.6.97"
 
@@ -17538,7 +17538,7 @@ CVE_STATUS[CVE-2025-38419] = "cpe-stable-backport: Backported in 6.6.95"
 
 CVE_STATUS[CVE-2025-38420] = "cpe-stable-backport: Backported in 6.6.95"
 
-CVE_STATUS[CVE-2025-38421] = "fixed-version: only affects 6.14 onwards"
+CVE_STATUS[CVE-2025-38421] = "fixed-version: only affects 6.12.23 onwards"
 
 CVE_STATUS[CVE-2025-38422] = "cpe-stable-backport: Backported in 6.6.95"
 
@@ -17664,7 +17664,7 @@ CVE_STATUS[CVE-2025-38482] = "cpe-stable-backport: Backported in 6.6.100"
 
 CVE_STATUS[CVE-2025-38483] = "cpe-stable-backport: Backported in 6.6.100"
 
-CVE_STATUS[CVE-2025-38484] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-38484] = "fixed-version: only affects 6.12.23 onwards"
 
 CVE_STATUS[CVE-2025-38485] = "cpe-stable-backport: Backported in 6.6.100"
 
@@ -17758,7 +17758,7 @@ CVE_STATUS[CVE-2025-38529] = "cpe-stable-backport: Backported in 6.6.100"
 
 CVE_STATUS[CVE-2025-38530] = "cpe-stable-backport: Backported in 6.6.100"
 
-# CVE-2025-38531 needs backporting (fixed from 6.16)
+# CVE-2025-38531 may need backporting (fixed from 6.6.136)
 
 CVE_STATUS[CVE-2025-38532] = "cpe-stable-backport: Backported in 6.6.100"
 
@@ -17798,7 +17798,7 @@ CVE_STATUS[CVE-2025-38549] = "fixed-version: only affects 6.7 onwards"
 
 CVE_STATUS[CVE-2025-38550] = "cpe-stable-backport: Backported in 6.6.100"
 
-CVE_STATUS[CVE-2025-38551] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-38551] = "fixed-version: only affects 6.11.2 onwards"
 
 CVE_STATUS[CVE-2025-38552] = "cpe-stable-backport: Backported in 6.6.101"
 
@@ -17830,7 +17830,7 @@ CVE_STATUS[CVE-2025-38565] = "cpe-stable-backport: Backported in 6.6.102"
 
 CVE_STATUS[CVE-2025-38566] = "cpe-stable-backport: Backported in 6.6.102"
 
-CVE_STATUS[CVE-2025-38567] = "fixed-version: only affects 6.15 onwards"
+CVE_STATUS[CVE-2025-38567] = "fixed-version: only affects 6.15.3 onwards"
 
 CVE_STATUS[CVE-2025-38568] = "cpe-stable-backport: Backported in 6.6.102"
 
@@ -17860,11 +17860,11 @@ CVE_STATUS[CVE-2025-38580] = "fixed-version: only affects 6.15 onwards"
 
 CVE_STATUS[CVE-2025-38581] = "cpe-stable-backport: Backported in 6.6.102"
 
-CVE_STATUS[CVE-2025-38582] = "fixed-version: only affects 6.12 onwards"
+# CVE-2025-38582 may need backporting (fixed from 6.7)
 
 CVE_STATUS[CVE-2025-38583] = "cpe-stable-backport: Backported in 6.6.102"
 
-# CVE-2025-38584 needs backporting (fixed from 6.17)
+# CVE-2025-38584 may need backporting (fixed from 6.6.140)
 
 # CVE-2025-38585 needs backporting (fixed from 6.17)
 
@@ -18004,7 +18004,7 @@ CVE_STATUS[CVE-2025-38654] = "fixed-version: only affects 6.13 onwards"
 
 CVE_STATUS[CVE-2025-38655] = "fixed-version: only affects 6.13 onwards"
 
-# CVE-2025-38656 has no known resolution
+# CVE-2025-38656 may need backporting (fixed from 6.7)
 
 CVE_STATUS[CVE-2025-38657] = "fixed-version: only affects 6.16 onwards"
 
@@ -18042,7 +18042,7 @@ CVE_STATUS[CVE-2025-38673] = "fixed-version: only affects 6.15 onwards"
 
 CVE_STATUS[CVE-2025-38674] = "fixed-version: only affects 6.15 onwards"
 
-CVE_STATUS[CVE-2025-38675] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-38675] = "fixed-version: only affects 6.12.13 onwards"
 
 CVE_STATUS[CVE-2025-38676] = "cpe-stable-backport: Backported in 6.6.103"
 
@@ -18112,7 +18112,7 @@ CVE_STATUS[CVE-2025-38708] = "cpe-stable-backport: Backported in 6.6.103"
 
 CVE_STATUS[CVE-2025-38709] = "cpe-stable-backport: Backported in 6.6.109"
 
-# CVE-2025-38710 needs backporting (fixed from 6.17)
+# CVE-2025-38710 may need backporting (fixed from 6.6.134)
 
 CVE_STATUS[CVE-2025-38711] = "cpe-stable-backport: Backported in 6.6.103"
 
@@ -18158,13 +18158,13 @@ CVE_STATUS[CVE-2025-38731] = "fixed-version: only affects 6.15 onwards"
 
 CVE_STATUS[CVE-2025-38732] = "cpe-stable-backport: Backported in 6.6.103"
 
-CVE_STATUS[CVE-2025-38733] = "fixed-version: only affects 6.11 onwards"
+CVE_STATUS[CVE-2025-38733] = "fixed-version: only affects 6.10.11 onwards"
 
 CVE_STATUS[CVE-2025-38734] = "cpe-stable-backport: Backported in 6.6.103"
 
 CVE_STATUS[CVE-2025-38735] = "cpe-stable-backport: Backported in 6.6.103"
 
-CVE_STATUS[CVE-2025-38736] = "fixed-version: only affects 6.12.43 onwards"
+CVE_STATUS[CVE-2025-38736] = "fixed-version: only affects 6.15.11 onwards"
 
 CVE_STATUS[CVE-2025-38737] = "fixed-version: only affects 6.12 onwards"
 
@@ -18198,7 +18198,7 @@ CVE_STATUS[CVE-2025-39686] = "cpe-stable-backport: Backported in 6.6.103"
 
 CVE_STATUS[CVE-2025-39687] = "cpe-stable-backport: Backported in 6.6.103"
 
-CVE_STATUS[CVE-2025-39688] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-39688] = "fixed-version: only affects 6.11.6 onwards"
 
 CVE_STATUS[CVE-2025-39689] = "cpe-stable-backport: Backported in 6.6.103"
 
@@ -18272,7 +18272,7 @@ CVE_STATUS[CVE-2025-39723] = "fixed-version: only affects 6.10 onwards"
 
 CVE_STATUS[CVE-2025-39724] = "cpe-stable-backport: Backported in 6.6.103"
 
-CVE_STATUS[CVE-2025-39725] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-39725] = "fixed-version: only affects 6.12.26 onwards"
 
 CVE_STATUS[CVE-2025-39726] = "cpe-stable-backport: Backported in 6.6.101"
 
@@ -18370,7 +18370,7 @@ CVE_STATUS[CVE-2025-39773] = "cpe-stable-backport: Backported in 6.6.103"
 
 CVE_STATUS[CVE-2025-39774] = "fixed-version: only affects 6.14 onwards"
 
-CVE_STATUS[CVE-2025-39775] = "fixed-version: only affects 6.13 onwards"
+CVE_STATUS[CVE-2025-39775] = "fixed-version: only affects 6.12.11 onwards"
 
 CVE_STATUS[CVE-2025-39776] = "cpe-stable-backport: Backported in 6.6.103"
 
@@ -18432,7 +18432,7 @@ CVE_STATUS[CVE-2025-39805] = "cpe-stable-backport: Backported in 6.6.119"
 
 CVE_STATUS[CVE-2025-39806] = "cpe-stable-backport: Backported in 6.6.104"
 
-CVE_STATUS[CVE-2025-39807] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-39807] = "fixed-version: only affects 6.12.40 onwards"
 
 CVE_STATUS[CVE-2025-39808] = "cpe-stable-backport: Backported in 6.6.104"
 
@@ -18560,7 +18560,7 @@ CVE_STATUS[CVE-2025-39870] = "cpe-stable-backport: Backported in 6.6.107"
 
 CVE_STATUS[CVE-2025-39871] = "cpe-stable-backport: Backported in 6.6.107"
 
-CVE_STATUS[CVE-2025-39872] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-39872] = "fixed-version: only affects 6.12.63 onwards"
 
 CVE_STATUS[CVE-2025-39873] = "cpe-stable-backport: Backported in 6.6.107"
 
@@ -18674,7 +18674,7 @@ CVE_STATUS[CVE-2025-39928] = "fixed-version: only affects 6.13 onwards"
 
 CVE_STATUS[CVE-2025-39929] = "cpe-stable-backport: Backported in 6.6.108"
 
-CVE_STATUS[CVE-2025-39930] = "fixed-version: only affects 6.14 onwards"
+CVE_STATUS[CVE-2025-39930] = "fixed-version: only affects 6.6.130 onwards"
 
 CVE_STATUS[CVE-2025-39931] = "cpe-stable-backport: Backported in 6.6.108"
 
@@ -18710,7 +18710,7 @@ CVE_STATUS[CVE-2025-39946] = "cpe-stable-backport: Backported in 6.6.108"
 
 CVE_STATUS[CVE-2025-39947] = "cpe-stable-backport: Backported in 6.6.108"
 
-CVE_STATUS[CVE-2025-39948] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-39948] = "fixed-version: only affects 6.12.14 onwards"
 
 CVE_STATUS[CVE-2025-39949] = "cpe-stable-backport: Backported in 6.6.108"
 
@@ -18744,7 +18744,7 @@ CVE_STATUS[CVE-2025-39963] = "fixed-version: only affects 6.10 onwards"
 
 CVE_STATUS[CVE-2025-39964] = "cpe-stable-backport: Backported in 6.6.108"
 
-CVE_STATUS[CVE-2025-39965] = "cpe-stable-backport: Backported in 6.6.109"
+CVE_STATUS[CVE-2025-39965] = "fixed-version: only affects 6.15.11 onwards"
 
 CVE_STATUS[CVE-2025-39966] = "fixed-version: only affects 6.11 onwards"
 
@@ -18776,7 +18776,7 @@ CVE_STATUS[CVE-2025-39979] = "fixed-version: only affects 6.14 onwards"
 
 CVE_STATUS[CVE-2025-39980] = "cpe-stable-backport: Backported in 6.6.109"
 
-# CVE-2025-39981 needs backporting (fixed from 6.17)
+# CVE-2025-39981 may need backporting (fixed from 6.6.140)
 
 CVE_STATUS[CVE-2025-39982] = "cpe-stable-backport: Backported in 6.6.109"
 
@@ -18808,11 +18808,11 @@ CVE_STATUS[CVE-2025-39995] = "cpe-stable-backport: Backported in 6.6.111"
 
 CVE_STATUS[CVE-2025-39996] = "cpe-stable-backport: Backported in 6.6.110"
 
-CVE_STATUS[CVE-2025-39997] = "fixed-version: only affects 6.16 onwards"
+# CVE-2025-39997 needs backporting (fixed from 6.18)
 
 CVE_STATUS[CVE-2025-39998] = "cpe-stable-backport: Backported in 6.6.110"
 
-CVE_STATUS[CVE-2025-39999] = "fixed-version: only affects 6.16 onwards"
+CVE_STATUS[CVE-2025-39999] = "fixed-version: only affects 6.16.4 onwards"
 
 # CVE-2025-40000 needs backporting (fixed from 6.18)
 
@@ -18824,11 +18824,11 @@ CVE_STATUS[CVE-2025-40002] = "fixed-version: only affects 6.14 onwards"
 
 CVE_STATUS[CVE-2025-40004] = "fixed-version: only affects 6.12 onwards"
 
-# CVE-2025-40005 may need backporting (fixed from 6.6.125)
+CVE_STATUS[CVE-2025-40005] = "cpe-stable-backport: Backported in 6.6.125"
 
 CVE_STATUS[CVE-2025-40006] = "cpe-stable-backport: Backported in 6.6.109"
 
-CVE_STATUS[CVE-2025-40007] = "fixed-version: only affects 6.16 onwards"
+CVE_STATUS[CVE-2025-40007] = "fixed-version: only affects 6.15.3 onwards"
 
 CVE_STATUS[CVE-2025-40008] = "cpe-stable-backport: Backported in 6.6.109"
 
@@ -18978,7 +18978,7 @@ CVE_STATUS[CVE-2025-40080] = "cpe-stable-backport: Backported in 6.6.112"
 
 CVE_STATUS[CVE-2025-40081] = "cpe-stable-backport: Backported in 6.6.112"
 
-# CVE-2025-40082 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2025-40082] = "cpe-stable-backport: Backported in 6.6.124"
 
 CVE_STATUS[CVE-2025-40083] = "cpe-stable-backport: Backported in 6.6.116"
 
@@ -19016,7 +19016,7 @@ CVE_STATUS[CVE-2025-40099] = "cpe-stable-backport: Backported in 6.6.114"
 
 CVE_STATUS[CVE-2025-40100] = "cpe-stable-backport: Backported in 6.6.114"
 
-CVE_STATUS[CVE-2025-40101] = "fixed-version: only affects 6.8 onwards"
+CVE_STATUS[CVE-2025-40101] = "fixed-version: only affects 6.7.11 onwards"
 
 # CVE-2025-40102 needs backporting (fixed from 6.18)
 
@@ -19074,7 +19074,7 @@ CVE_STATUS[CVE-2025-40129] = "cpe-stable-backport: Backported in 6.6.112"
 
 CVE_STATUS[CVE-2025-40130] = "fixed-version: only affects 6.9 onwards"
 
-CVE_STATUS[CVE-2025-40131] = "fixed-version: only affects 6.16 onwards"
+CVE_STATUS[CVE-2025-40131] = "fixed-version: only affects 6.15.3 onwards"
 
 CVE_STATUS[CVE-2025-40132] = "fixed-version: only affects 6.10 onwards"
 
@@ -19208,7 +19208,7 @@ CVE_STATUS[CVE-2025-40197] = "cpe-stable-backport: Backported in 6.6.113"
 
 CVE_STATUS[CVE-2025-40198] = "cpe-stable-backport: Backported in 6.6.114"
 
-CVE_STATUS[CVE-2025-40199] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-40199] = "fixed-version: only affects 6.12.34 onwards"
 
 CVE_STATUS[CVE-2025-40200] = "cpe-stable-backport: Backported in 6.6.113"
 
@@ -19236,7 +19236,7 @@ CVE_STATUS[CVE-2025-40211] = "cpe-stable-backport: Backported in 6.6.117"
 
 CVE_STATUS[CVE-2025-40212] = "fixed-version: only affects 6.12 onwards"
 
-CVE_STATUS[CVE-2025-40213] = "fixed-version: only affects 6.17 onwards"
+CVE_STATUS[CVE-2025-40213] = "fixed-version: only affects 6.6.140 onwards"
 
 CVE_STATUS[CVE-2025-40214] = "cpe-stable-backport: Backported in 6.6.117"
 
@@ -19248,7 +19248,7 @@ CVE_STATUS[CVE-2025-40217] = "fixed-version: only affects 6.11 onwards"
 
 CVE_STATUS[CVE-2025-40218] = "cpe-stable-backport: Backported in 6.6.113"
 
-CVE_STATUS[CVE-2025-40219] = "cpe-stable-backport: Backported in 6.6.113"
+# CVE-2025-40219 may need backporting (fixed from 6.6.128)
 
 CVE_STATUS[CVE-2025-40220] = "cpe-stable-backport: Backported in 6.6.115"
 
@@ -19390,7 +19390,7 @@ CVE_STATUS[CVE-2025-40288] = "cpe-stable-backport: Backported in 6.6.117"
 
 # CVE-2025-40289 needs backporting (fixed from 6.18)
 
-CVE_STATUS[CVE-2025-40290] = "fixed-version: only affects 6.17 onwards"
+CVE_STATUS[CVE-2025-40290] = "fixed-version: only affects 6.16.8 onwards"
 
 CVE_STATUS[CVE-2025-40291] = "fixed-version: only affects 6.15 onwards"
 
@@ -19464,7 +19464,7 @@ CVE_STATUS[CVE-2025-40324] = "cpe-stable-backport: Backported in 6.6.117"
 
 CVE_STATUS[CVE-2025-40326] = "fixed-version: only affects 6.14 onwards"
 
-CVE_STATUS[CVE-2025-40327] = "fixed-version: only affects 6.17 onwards"
+CVE_STATUS[CVE-2025-40327] = "fixed-version: only affects 6.16.8 onwards"
 
 CVE_STATUS[CVE-2025-40328] = "cpe-stable-backport: Backported in 6.6.117"
 
@@ -19474,7 +19474,7 @@ CVE_STATUS[CVE-2025-40330] = "fixed-version: only affects 6.13 onwards"
 
 CVE_STATUS[CVE-2025-40331] = "cpe-stable-backport: Backported in 6.6.117"
 
-CVE_STATUS[CVE-2025-40332] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-40332] = "fixed-version: only affects 6.12.24 onwards"
 
 CVE_STATUS[CVE-2025-40333] = "cpe-stable-backport: Backported in 6.6.117"
 
@@ -19498,7 +19498,7 @@ CVE_STATUS[CVE-2025-40342] = "cpe-stable-backport: Backported in 6.6.117"
 
 CVE_STATUS[CVE-2025-40343] = "cpe-stable-backport: Backported in 6.6.117"
 
-CVE_STATUS[CVE-2025-40344] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-40344] = "fixed-version: only affects 6.11.9 onwards"
 
 CVE_STATUS[CVE-2025-40345] = "cpe-stable-backport: Backported in 6.6.119"
 
@@ -19594,7 +19594,7 @@ CVE_STATUS[CVE-2025-68193] = "fixed-version: only affects 6.10 onwards"
 
 CVE_STATUS[CVE-2025-68194] = "cpe-stable-backport: Backported in 6.6.117"
 
-# CVE-2025-68195 has no known resolution
+CVE_STATUS[CVE-2025-68195] = "fixed-version: only affects 6.12.58 onwards"
 
 CVE_STATUS[CVE-2025-68196] = "fixed-version: only affects 6.17 onwards"
 
@@ -19616,7 +19616,7 @@ CVE_STATUS[CVE-2025-68205] = "fixed-version: only affects 6.17 onwards"
 
 # CVE-2025-68206 may need backporting (fixed from 6.6.130)
 
-CVE_STATUS[CVE-2025-68207] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-68207] = "fixed-version: only affects 6.12.37 onwards"
 
 CVE_STATUS[CVE-2025-68208] = "cpe-stable-backport: Backported in 6.6.117"
 
@@ -19628,11 +19628,11 @@ CVE_STATUS[CVE-2025-68211] = "cpe-stable-backport: Backported in 6.6.121"
 
 CVE_STATUS[CVE-2025-68212] = "fixed-version: only affects 6.15 onwards"
 
-CVE_STATUS[CVE-2025-68213] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-68213] = "fixed-version: only affects 6.12.43 onwards"
 
 CVE_STATUS[CVE-2025-68214] = "cpe-stable-backport: Backported in 6.6.118"
 
-CVE_STATUS[CVE-2025-68215] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-68215] = "fixed-version: only affects 6.12.11 onwards"
 
 CVE_STATUS[CVE-2025-68216] = "fixed-version: only affects 6.17 onwards"
 
@@ -19702,7 +19702,7 @@ CVE_STATUS[CVE-2025-68249] = "cpe-stable-backport: Backported in 6.6.115"
 
 CVE_STATUS[CVE-2025-68250] = "fixed-version: only affects 6.16 onwards"
 
-CVE_STATUS[CVE-2025-68251] = "fixed-version: only affects 6.8 onwards"
+# CVE-2025-68251 may need backporting (fixed from 6.7)
 
 CVE_STATUS[CVE-2025-68252] = "cpe-stable-backport: Backported in 6.6.115"
 
@@ -19768,7 +19768,7 @@ CVE_STATUS[CVE-2025-68295] = "cpe-stable-backport: Backported in 6.6.119"
 
 CVE_STATUS[CVE-2025-68297] = "cpe-stable-backport: Backported in 6.6.119"
 
-CVE_STATUS[CVE-2025-68298] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-68298] = "fixed-version: only affects 6.12.13 onwards"
 
 CVE_STATUS[CVE-2025-68299] = "fixed-version: only affects 6.17.9 onwards"
 
@@ -19802,7 +19802,7 @@ CVE_STATUS[CVE-2025-68313] = "fixed-version: only affects 6.8 onwards"
 
 CVE_STATUS[CVE-2025-68314] = "fixed-version: only affects 6.17 onwards"
 
-# CVE-2025-68315 needs backporting (fixed from 6.18)
+# CVE-2025-68315 may need backporting (fixed from 6.6.140)
 
 CVE_STATUS[CVE-2025-68316] = "fixed-version: only affects 6.13 onwards"
 
@@ -19874,7 +19874,7 @@ CVE_STATUS[CVE-2025-68349] = "cpe-stable-backport: Backported in 6.6.120"
 
 CVE_STATUS[CVE-2025-68350] = "fixed-version: only affects 6.18 onwards"
 
-CVE_STATUS[CVE-2025-68351] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-68351] = "fixed-version: only affects 6.12.23 onwards"
 
 CVE_STATUS[CVE-2025-68352] = "fixed-version: only affects 6.11 onwards"
 
@@ -19886,9 +19886,9 @@ CVE_STATUS[CVE-2025-68355] = "fixed-version: only affects 6.18 onwards"
 
 # CVE-2025-68356 needs backporting (fixed from 6.19)
 
-# CVE-2025-68357 may need backporting (fixed from 6.6.130)
+CVE_STATUS[CVE-2025-68357] = "fixed-version: only affects 6.17.13 onwards"
 
-# CVE-2025-68358 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2025-68358] = "cpe-stable-backport: Backported in 6.6.124"
 
 CVE_STATUS[CVE-2025-68359] = "fixed-version: only affects 6.12 onwards"
 
@@ -20108,8 +20108,6 @@ CVE_STATUS[CVE-2025-68810] = "fixed-version: only affects 6.8 onwards"
 
 CVE_STATUS[CVE-2025-68811] = "fixed-version: only affects 6.8 onwards"
 
-CVE_STATUS[CVE-2025-68812] = "fixed-version: only affects 6.15 onwards"
-
 CVE_STATUS[CVE-2025-68813] = "cpe-stable-backport: Backported in 6.6.120"
 
 CVE_STATUS[CVE-2025-68814] = "cpe-stable-backport: Backported in 6.6.120"
@@ -20130,7 +20128,7 @@ CVE_STATUS[CVE-2025-68821] = "cpe-stable-backport: Backported in 6.6.120"
 
 # CVE-2025-68822 needs backporting (fixed from 6.19)
 
-# CVE-2025-68823 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2025-68823] = "cpe-stable-backport: Backported in 6.6.124"
 
 CVE_STATUS[CVE-2025-71064] = "cpe-stable-backport: Backported in 6.6.120"
 
@@ -20144,7 +20142,7 @@ CVE_STATUS[CVE-2025-71068] = "cpe-stable-backport: Backported in 6.6.120"
 
 CVE_STATUS[CVE-2025-71069] = "cpe-stable-backport: Backported in 6.6.120"
 
-CVE_STATUS[CVE-2025-71070] = "fixed-version: only affects 6.15 onwards"
+CVE_STATUS[CVE-2025-71070] = "fixed-version: only affects 6.14.6 onwards"
 
 CVE_STATUS[CVE-2025-71071] = "cpe-stable-backport: Backported in 6.6.120"
 
@@ -20156,7 +20154,7 @@ CVE_STATUS[CVE-2025-71071] = "cpe-stable-backport: Backported in 6.6.120"
 
 CVE_STATUS[CVE-2025-71075] = "cpe-stable-backport: Backported in 6.6.120"
 
-CVE_STATUS[CVE-2025-71076] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-71076] = "fixed-version: only affects 6.12.17 onwards"
 
 CVE_STATUS[CVE-2025-71077] = "cpe-stable-backport: Backported in 6.6.120"
 
@@ -20274,7 +20272,7 @@ CVE_STATUS[CVE-2025-71133] = "cpe-stable-backport: Backported in 6.6.120"
 
 CVE_STATUS[CVE-2025-71134] = "fixed-version: only affects 6.10 onwards"
 
-CVE_STATUS[CVE-2025-71135] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2025-71135] = "fixed-version: only affects 6.12.4 onwards"
 
 CVE_STATUS[CVE-2025-71136] = "cpe-stable-backport: Backported in 6.6.120"
 
@@ -20294,16 +20292,14 @@ CVE_STATUS[CVE-2025-71143] = "cpe-stable-backport: Backported in 6.6.120"
 
 CVE_STATUS[CVE-2025-71144] = "cpe-stable-backport: Backported in 6.6.120"
 
-# CVE-2025-71145 has no known resolution
+CVE_STATUS[CVE-2025-71145] = "fixed-version: Fixed from version 5.11"
 
-CVE_STATUS[CVE-2025-71146] = "fixed-version: only affects 6.12.63 onwards"
+CVE_STATUS[CVE-2025-71146] = "fixed-version: only affects 6.17.13 onwards"
 
 CVE_STATUS[CVE-2025-71147] = "cpe-stable-backport: Backported in 6.6.120"
 
 CVE_STATUS[CVE-2025-71148] = "cpe-stable-backport: Backported in 6.6.120"
 
-CVE_STATUS[CVE-2025-71149] = "cpe-stable-backport: Backported in 6.6.120"
-
 CVE_STATUS[CVE-2025-71150] = "cpe-stable-backport: Backported in 6.6.120"
 
 CVE_STATUS[CVE-2025-71151] = "cpe-stable-backport: Backported in 6.6.120"
@@ -20314,7 +20310,7 @@ CVE_STATUS[CVE-2025-71153] = "cpe-stable-backport: Backported in 6.6.120"
 
 CVE_STATUS[CVE-2025-71154] = "cpe-stable-backport: Backported in 6.6.120"
 
-CVE_STATUS[CVE-2025-71155] = "fixed-version: only affects 6.18 onwards"
+CVE_STATUS[CVE-2025-71155] = "fixed-version: only affects 6.17.4 onwards"
 
 CVE_STATUS[CVE-2025-71156] = "fixed-version: only affects 6.9 onwards"
 
@@ -20380,41 +20376,41 @@ CVE_STATUS[CVE-2025-71201] = "fixed-version: only affects 6.14 onwards"
 
 # CVE-2025-71203 may need backporting (fixed from 6.6.130)
 
-# CVE-2025-71204 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2025-71204] = "cpe-stable-backport: Backported in 6.6.124"
 
-# CVE-2025-71220 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2025-71220] = "cpe-stable-backport: Backported in 6.6.124"
 
 # CVE-2025-71221 may need backporting (fixed from 6.6.130)
 
-# CVE-2025-71222 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2025-71222] = "cpe-stable-backport: Backported in 6.6.124"
 
-# CVE-2025-71223 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2025-71223] = "cpe-stable-backport: Backported in 6.6.124"
 
-# CVE-2025-71224 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2025-71224] = "cpe-stable-backport: Backported in 6.6.124"
 
 # CVE-2025-71225 needs backporting (fixed from 6.19)
 
 # CVE-2025-71227 needs backporting (fixed from 6.19)
 
-# CVE-2025-71229 may need backporting (fixed from 6.6.125)
+CVE_STATUS[CVE-2025-71229] = "cpe-stable-backport: Backported in 6.6.125"
 
 CVE_STATUS[CVE-2025-71230] = "fixed-version: only affects 6.13 onwards"
 
 CVE_STATUS[CVE-2025-71231] = "fixed-version: only affects 6.8 onwards"
 
-# CVE-2025-71232 may need backporting (fixed from 6.6.125)
+CVE_STATUS[CVE-2025-71232] = "cpe-stable-backport: Backported in 6.6.125"
 
-# CVE-2025-71233 may need backporting (fixed from 6.6.127)
+CVE_STATUS[CVE-2025-71233] = "cpe-stable-backport: Backported in 6.6.127"
 
 CVE_STATUS[CVE-2025-71234] = "fixed-version: only affects 6.9 onwards"
 
-# CVE-2025-71235 may need backporting (fixed from 6.6.125)
+CVE_STATUS[CVE-2025-71235] = "cpe-stable-backport: Backported in 6.6.125"
 
-# CVE-2025-71236 may need backporting (fixed from 6.6.125)
+CVE_STATUS[CVE-2025-71236] = "cpe-stable-backport: Backported in 6.6.125"
 
-# CVE-2025-71237 may need backporting (fixed from 6.6.125)
+CVE_STATUS[CVE-2025-71237] = "cpe-stable-backport: Backported in 6.6.125"
 
-# CVE-2025-71238 may need backporting (fixed from 6.6.127)
+CVE_STATUS[CVE-2025-71238] = "cpe-stable-backport: Backported in 6.6.127"
 
 # CVE-2025-71239 may need backporting (fixed from 6.6.128)
 
@@ -20424,11 +20420,55 @@ CVE_STATUS[CVE-2025-71234] = "fixed-version: only affects 6.9 onwards"
 
 # CVE-2025-71267 may need backporting (fixed from 6.6.128)
 
-# CVE-2025-71268 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2025-71268] = "cpe-stable-backport: Backported in 6.6.124"
+
+# CVE-2025-71269 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2025-71270] = "cpe-stable-backport: Backported in 6.6.124"
+
+CVE_STATUS[CVE-2025-71271] = "fixed-version: only affects 6.13 onwards"
+
+# CVE-2025-71272 needs backporting (fixed from 7.0)
+
+# CVE-2025-71273 needs backporting (fixed from 7.0)
+
+# CVE-2025-71274 may need backporting (fixed from 6.6.128)
+
+# CVE-2025-71285 needs backporting (fixed from 7.0)
+
+# CVE-2025-71286 may need backporting (fixed from 6.6.128)
+
+# CVE-2025-71287 may need backporting (fixed from 6.6.130)
+
+# CVE-2025-71288 may need backporting (fixed from 6.6.130)
+
+# CVE-2025-71289 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2025-71290] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2025-71291 may need backporting (fixed from 6.6.128)
+
+# CVE-2025-71292 may need backporting (fixed from 6.6.128)
 
-# CVE-2025-71269 needs backporting (fixed from 6.19)
+CVE_STATUS[CVE-2025-71293] = "fixed-version: only affects 6.18 onwards"
 
-# CVE-2025-71270 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2025-71294] = "fixed-version: only affects 6.7 onwards"
+
+# CVE-2025-71295 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2025-71296] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2025-71297 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2025-71298] = "fixed-version: only affects 6.16 onwards"
+
+CVE_STATUS[CVE-2025-71299] = "fixed-version: only affects 6.17.11 onwards"
+
+CVE_STATUS[CVE-2025-71300] = "fixed-version: only affects 6.9 onwards"
+
+CVE_STATUS[CVE-2025-71301] = "fixed-version: only affects 6.16 onwards"
+
+CVE_STATUS[CVE-2025-71302] = "fixed-version: only affects 6.10 onwards"
 
 CVE_STATUS[CVE-2026-22976] = "cpe-stable-backport: Backported in 6.6.121"
 
@@ -20506,7 +20546,7 @@ CVE_STATUS[CVE-2026-23012] = "fixed-version: only affects 6.17 onwards"
 
 CVE_STATUS[CVE-2026-23013] = "fixed-version: only affects 6.9 onwards"
 
-CVE_STATUS[CVE-2026-23014] = "fixed-version: only affects 6.18 onwards"
+CVE_STATUS[CVE-2026-23014] = "fixed-version: only affects 6.17.8 onwards"
 
 CVE_STATUS[CVE-2026-23015] = "fixed-version: only affects 6.13 onwards"
 
@@ -20514,7 +20554,7 @@ CVE_STATUS[CVE-2026-23016] = "fixed-version: only affects 6.18 onwards"
 
 CVE_STATUS[CVE-2026-23017] = "fixed-version: only affects 6.7 onwards"
 
-CVE_STATUS[CVE-2026-23018] = "fixed-version: only affects 6.17 onwards"
+CVE_STATUS[CVE-2026-23018] = "fixed-version: only affects 6.16.9 onwards"
 
 CVE_STATUS[CVE-2026-23019] = "cpe-stable-backport: Backported in 6.6.121"
 
@@ -20636,7 +20676,7 @@ CVE_STATUS[CVE-2026-23077] = "fixed-version: only affects 6.16 onwards"
 
 CVE_STATUS[CVE-2026-23078] = "cpe-stable-backport: Backported in 6.6.122"
 
-CVE_STATUS[CVE-2026-23079] = "fixed-version: only affects 6.18 onwards"
+CVE_STATUS[CVE-2026-23079] = "fixed-version: only affects 6.17.10 onwards"
 
 CVE_STATUS[CVE-2026-23080] = "cpe-stable-backport: Backported in 6.6.122"
 
@@ -20678,7 +20718,7 @@ CVE_STATUS[CVE-2026-23098] = "cpe-stable-backport: Backported in 6.6.122"
 
 CVE_STATUS[CVE-2026-23099] = "cpe-stable-backport: Backported in 6.6.122"
 
-# CVE-2026-23100 may need backporting (fixed from 6.6.127)
+CVE_STATUS[CVE-2026-23100] = "cpe-stable-backport: Backported in 6.6.127"
 
 CVE_STATUS[CVE-2026-23101] = "cpe-stable-backport: Backported in 6.6.122"
 
@@ -20700,9 +20740,9 @@ CVE_STATUS[CVE-2026-23109] = "fixed-version: only affects 6.16 onwards"
 
 CVE_STATUS[CVE-2026-23110] = "cpe-stable-backport: Backported in 6.6.122"
 
-# CVE-2026-23111 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23111] = "cpe-stable-backport: Backported in 6.6.124"
 
-# CVE-2026-23112 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23112] = "cpe-stable-backport: Backported in 6.6.124"
 
 CVE_STATUS[CVE-2026-23113] = "cpe-stable-backport: Backported in 6.6.122"
 
@@ -20764,7 +20804,7 @@ CVE_STATUS[CVE-2026-23141] = "cpe-stable-backport: Backported in 6.6.122"
 
 CVE_STATUS[CVE-2026-23142] = "cpe-stable-backport: Backported in 6.6.122"
 
-CVE_STATUS[CVE-2026-23143] = "fixed-version: only affects 6.15 onwards"
+CVE_STATUS[CVE-2026-23143] = "fixed-version: only affects 6.12.91 onwards"
 
 CVE_STATUS[CVE-2026-23144] = "cpe-stable-backport: Backported in 6.6.122"
 
@@ -20774,13 +20814,13 @@ CVE_STATUS[CVE-2026-23146] = "cpe-stable-backport: Backported in 6.6.123"
 
 CVE_STATUS[CVE-2026-23147] = "fixed-version: only affects 6.15 onwards"
 
-CVE_STATUS[CVE-2026-23148] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2026-23148] = "fixed-version: only affects 6.12.37 onwards"
 
 CVE_STATUS[CVE-2026-23149] = "fixed-version: only affects 6.18 onwards"
 
 CVE_STATUS[CVE-2026-23150] = "cpe-stable-backport: Backported in 6.6.123"
 
-CVE_STATUS[CVE-2026-23151] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2026-23151] = "fixed-version: only affects 6.12.59 onwards"
 
 CVE_STATUS[CVE-2026-23152] = "fixed-version: only affects 6.7 onwards"
 
@@ -20810,17 +20850,17 @@ CVE_STATUS[CVE-2026-23164] = "cpe-stable-backport: Backported in 6.6.123"
 
 CVE_STATUS[CVE-2026-23165] = "fixed-version: only affects 6.17 onwards"
 
-CVE_STATUS[CVE-2026-23166] = "fixed-version: only affects 6.11 onwards"
+CVE_STATUS[CVE-2026-23166] = "fixed-version: only affects 6.10.10 onwards"
 
 CVE_STATUS[CVE-2026-23167] = "cpe-stable-backport: Backported in 6.6.123"
 
 CVE_STATUS[CVE-2026-23168] = "cpe-stable-backport: Backported in 6.6.123"
 
-# CVE-2026-23169 may need backporting (fixed from 6.6.125)
+CVE_STATUS[CVE-2026-23169] = "cpe-stable-backport: Backported in 6.6.125"
 
 CVE_STATUS[CVE-2026-23170] = "cpe-stable-backport: Backported in 6.6.123"
 
-# CVE-2026-23171 needs backporting (fixed from 6.19)
+# CVE-2026-23171 may need backporting (fixed from 6.6.140)
 
 CVE_STATUS[CVE-2026-23172] = "cpe-stable-backport: Backported in 6.6.123"
 
@@ -20830,19 +20870,19 @@ CVE_STATUS[CVE-2026-23174] = "fixed-version: only affects 6.17 onwards"
 
 CVE_STATUS[CVE-2026-23175] = "fixed-version: only affects 6.17 onwards"
 
-# CVE-2026-23176 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23176] = "cpe-stable-backport: Backported in 6.6.124"
 
 CVE_STATUS[CVE-2026-23177] = "fixed-version: only affects 6.12 onwards"
 
-# CVE-2026-23178 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23178] = "cpe-stable-backport: Backported in 6.6.124"
 
 CVE_STATUS[CVE-2026-23179] = "fixed-version: only affects 6.7 onwards"
 
-# CVE-2026-23180 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23180] = "cpe-stable-backport: Backported in 6.6.124"
 
 CVE_STATUS[CVE-2026-23181] = "fixed-version: only affects 6.15 onwards"
 
-# CVE-2026-23182 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23182] = "cpe-stable-backport: Backported in 6.6.124"
 
 CVE_STATUS[CVE-2026-23183] = "fixed-version: only affects 6.14 onwards"
 
@@ -20852,19 +20892,19 @@ CVE_STATUS[CVE-2026-23185] = "fixed-version: only affects 6.17 onwards"
 
 CVE_STATUS[CVE-2026-23186] = "fixed-version: only affects 6.15 onwards"
 
-# CVE-2026-23187 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23187] = "cpe-stable-backport: Backported in 6.6.124"
 
 CVE_STATUS[CVE-2026-23188] = "fixed-version: only affects 6.11 onwards"
 
-CVE_STATUS[CVE-2026-23189] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2026-23189] = "fixed-version: only affects 6.12.58 onwards"
 
-# CVE-2026-23190 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23190] = "cpe-stable-backport: Backported in 6.6.124"
 
 # CVE-2026-23191 needs backporting (fixed from 6.19)
 
 CVE_STATUS[CVE-2026-23192] = "fixed-version: only affects 6.15 onwards"
 
-# CVE-2026-23193 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23193] = "cpe-stable-backport: Backported in 6.6.124"
 
 CVE_STATUS[CVE-2026-23194] = "fixed-version: only affects 6.18 onwards"
 
@@ -20874,29 +20914,29 @@ CVE_STATUS[CVE-2026-23196] = "fixed-version: only affects 6.14 onwards"
 
 CVE_STATUS[CVE-2026-23197] = "fixed-version: only affects 6.13 onwards"
 
-# CVE-2026-23198 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23198] = "cpe-stable-backport: Backported in 6.6.124"
 
 CVE_STATUS[CVE-2026-23199] = "fixed-version: only affects 6.11 onwards"
 
-# CVE-2026-23200 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23200] = "fixed-version: only affects 6.17.13 onwards"
 
-CVE_STATUS[CVE-2026-23201] = "fixed-version: only affects 6.12 onwards"
+CVE_STATUS[CVE-2026-23201] = "fixed-version: only affects 6.12.42 onwards"
 
-# CVE-2026-23202 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23202] = "fixed-version: only affects 6.17.13 onwards"
 
 CVE_STATUS[CVE-2026-23203] = "fixed-version: only affects 6.17 onwards"
 
-# CVE-2026-23204 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23204] = "cpe-stable-backport: Backported in 6.6.124"
 
-# CVE-2026-23205 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23205] = "cpe-stable-backport: Backported in 6.6.124"
 
-# CVE-2026-23206 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23206] = "cpe-stable-backport: Backported in 6.6.124"
 
-CVE_STATUS[CVE-2026-23207] = "fixed-version: only affects 6.12.63 onwards"
+# CVE-2026-23207 may need backporting (fixed from 6.7)
 
 # CVE-2026-23208 needs backporting (fixed from 6.19)
 
-# CVE-2026-23209 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23209] = "cpe-stable-backport: Backported in 6.6.124"
 
 CVE_STATUS[CVE-2026-23210] = "fixed-version: only affects 6.9 onwards"
 
@@ -20910,19 +20950,19 @@ CVE_STATUS[CVE-2026-23212] = "cpe-stable-backport: Backported in 6.6.123"
 
 CVE_STATUS[CVE-2026-23215] = "fixed-version: only affects 6.11 onwards"
 
-# CVE-2026-23216 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23216] = "cpe-stable-backport: Backported in 6.6.124"
 
-CVE_STATUS[CVE-2026-23217] = "fixed-version: only affects 6.11 onwards"
+CVE_STATUS[CVE-2026-23217] = "fixed-version: only affects 6.10.10 onwards"
 
 CVE_STATUS[CVE-2026-23218] = "fixed-version: only affects 6.18 onwards"
 
 CVE_STATUS[CVE-2026-23219] = "fixed-version: only affects 6.10 onwards"
 
-# CVE-2026-23220 may need backporting (fixed from 6.6.125)
+CVE_STATUS[CVE-2026-23220] = "cpe-stable-backport: Backported in 6.6.125"
 
-# CVE-2026-23221 may need backporting (fixed from 6.6.127)
+CVE_STATUS[CVE-2026-23221] = "cpe-stable-backport: Backported in 6.6.127"
 
-# CVE-2026-23222 may need backporting (fixed from 6.6.125)
+CVE_STATUS[CVE-2026-23222] = "cpe-stable-backport: Backported in 6.6.125"
 
 CVE_STATUS[CVE-2026-23223] = "fixed-version: only affects 6.9 onwards"
 
@@ -20930,35 +20970,35 @@ CVE_STATUS[CVE-2026-23224] = "fixed-version: only affects 6.12 onwards"
 
 CVE_STATUS[CVE-2026-23225] = "fixed-version: only affects 6.19 onwards"
 
-# CVE-2026-23226 needs backporting (fixed from 7.0rc1)
+# CVE-2026-23226 needs backporting (fixed from 7.0)
 
 # CVE-2026-23227 may need backporting (fixed from 6.6.130)
 
-# CVE-2026-23228 may need backporting (fixed from 6.6.125)
+CVE_STATUS[CVE-2026-23228] = "cpe-stable-backport: Backported in 6.6.125"
 
-# CVE-2026-23229 may need backporting (fixed from 6.6.125)
+CVE_STATUS[CVE-2026-23229] = "cpe-stable-backport: Backported in 6.6.125"
 
-# CVE-2026-23230 may need backporting (fixed from 6.6.125)
+CVE_STATUS[CVE-2026-23230] = "cpe-stable-backport: Backported in 6.6.125"
 
 # CVE-2026-23231 may need backporting (fixed from 6.6.128)
 
 CVE_STATUS[CVE-2026-23232] = "fixed-version: only affects 6.19 onwards"
 
-# CVE-2026-23233 may need backporting (fixed from 6.6.127)
+CVE_STATUS[CVE-2026-23233] = "cpe-stable-backport: Backported in 6.6.127"
 
-# CVE-2026-23234 may need backporting (fixed from 6.6.127)
+CVE_STATUS[CVE-2026-23234] = "cpe-stable-backport: Backported in 6.6.127"
 
-# CVE-2026-23235 may need backporting (fixed from 6.6.127)
+CVE_STATUS[CVE-2026-23235] = "cpe-stable-backport: Backported in 6.6.127"
 
-# CVE-2026-23236 may need backporting (fixed from 6.6.127)
+CVE_STATUS[CVE-2026-23236] = "cpe-stable-backport: Backported in 6.6.127"
 
-# CVE-2026-23237 may need backporting (fixed from 6.6.127)
+CVE_STATUS[CVE-2026-23237] = "cpe-stable-backport: Backported in 6.6.127"
 
-# CVE-2026-23238 may need backporting (fixed from 6.6.127)
+CVE_STATUS[CVE-2026-23238] = "cpe-stable-backport: Backported in 6.6.127"
 
-# CVE-2026-23239 needs backporting (fixed from 7.0rc2)
+# CVE-2026-23239 needs backporting (fixed from 7.0)
 
-# CVE-2026-23240 needs backporting (fixed from 7.0rc2)
+# CVE-2026-23240 needs backporting (fixed from 7.0)
 
 CVE_STATUS[CVE-2026-23241] = "fixed-version: only affects 6.13 onwards"
 
@@ -20972,7 +21012,7 @@ CVE_STATUS[CVE-2026-23241] = "fixed-version: only affects 6.13 onwards"
 
 # CVE-2026-23246 may need backporting (fixed from 6.6.130)
 
-# CVE-2026-23247 needs backporting (fixed from 7.0rc3)
+# CVE-2026-23247 needs backporting (fixed from 7.0)
 
 CVE_STATUS[CVE-2026-23248] = "fixed-version: only affects 6.14 onwards"
 
@@ -20986,33 +21026,33 @@ CVE_STATUS[CVE-2026-23252] = "fixed-version: only affects 6.10 onwards"
 
 # CVE-2026-23253 may need backporting (fixed from 6.6.130)
 
-# CVE-2026-23254 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23254] = "cpe-stable-backport: Backported in 6.6.124"
 
-# CVE-2026-23255 needs backporting (fixed from 6.19)
+# CVE-2026-23255 may need backporting (fixed from 6.6.136)
 
-# CVE-2026-23256 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23256] = "cpe-stable-backport: Backported in 6.6.124"
 
-# CVE-2026-23257 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23257] = "cpe-stable-backport: Backported in 6.6.124"
 
-# CVE-2026-23258 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23258] = "cpe-stable-backport: Backported in 6.6.124"
 
 CVE_STATUS[CVE-2026-23259] = "fixed-version: only affects 6.10 onwards"
 
-# CVE-2026-23260 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23260] = "cpe-stable-backport: Backported in 6.6.124"
 
-# CVE-2026-23261 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23261] = "cpe-stable-backport: Backported in 6.6.124"
 
-# CVE-2026-23262 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23262] = "cpe-stable-backport: Backported in 6.6.124"
 
 CVE_STATUS[CVE-2026-23263] = "fixed-version: only affects 6.17 onwards"
 
-# CVE-2026-23264 may need backporting (fixed from 6.6.124)
+CVE_STATUS[CVE-2026-23264] = "cpe-stable-backport: Backported in 6.6.124"
 
-# CVE-2026-23265 needs backporting (fixed from 7.0rc1)
+# CVE-2026-23265 needs backporting (fixed from 7.0)
 
-# CVE-2026-23266 may need backporting (fixed from 6.6.127)
+CVE_STATUS[CVE-2026-23266] = "cpe-stable-backport: Backported in 6.6.127"
 
-# CVE-2026-23267 may need backporting (fixed from 6.6.127)
+CVE_STATUS[CVE-2026-23267] = "cpe-stable-backport: Backported in 6.6.127"
 
 # CVE-2026-23268 may need backporting (fixed from 6.6.130)
 
@@ -21022,7 +21062,7 @@ CVE_STATUS[CVE-2026-23263] = "fixed-version: only affects 6.17 onwards"
 
 # CVE-2026-23271 may need backporting (fixed from 6.6.130)
 
-# CVE-2026-23272 needs backporting (fixed from 7.0rc3)
+# CVE-2026-23272 may need backporting (fixed from 6.6.141)
 
 # CVE-2026-23273 may need backporting (fixed from 6.6.128)
 
@@ -21030,11 +21070,11 @@ CVE_STATUS[CVE-2026-23263] = "fixed-version: only affects 6.17 onwards"
 
 CVE_STATUS[CVE-2026-23275] = "fixed-version: only affects 6.13 onwards"
 
-# CVE-2026-23276 needs backporting (fixed from 7.0rc4)
+# CVE-2026-23276 needs backporting (fixed from 7.0)
 
 # CVE-2026-23277 may need backporting (fixed from 6.6.130)
 
-# CVE-2026-23278 needs backporting (fixed from 7.0rc4)
+# CVE-2026-23278 needs backporting (fixed from 7.0)
 
 # CVE-2026-23279 may need backporting (fixed from 6.6.130)
 
@@ -21054,7 +21094,7 @@ CVE_STATUS[CVE-2026-23283] = "fixed-version: only affects 6.19 onwards"
 
 # CVE-2026-23287 may need backporting (fixed from 6.6.130)
 
-CVE_STATUS[CVE-2026-23288] = "fixed-version: only affects 6.19 onwards"
+CVE_STATUS[CVE-2026-23288] = "fixed-version: only affects 6.19.4 onwards"
 
 # CVE-2026-23289 may need backporting (fixed from 6.6.130)
 
@@ -21082,7 +21122,7 @@ CVE_STATUS[CVE-2026-23299] = "fixed-version: only affects 6.15 onwards"
 
 CVE_STATUS[CVE-2026-23301] = "fixed-version: only affects 6.19 onwards"
 
-# CVE-2026-23302 needs backporting (fixed from 7.0rc3)
+# CVE-2026-23302 may need backporting (fixed from 6.6.136)
 
 # CVE-2026-23303 may need backporting (fixed from 6.6.130)
 
@@ -21104,7 +21144,7 @@ CVE_STATUS[CVE-2026-23311] = "fixed-version: only affects 6.15 onwards"
 
 # CVE-2026-23312 may need backporting (fixed from 6.6.130)
 
-# CVE-2026-23313 needs backporting (fixed from 7.0rc3)
+# CVE-2026-23313 may need backporting (fixed from 6.6.136)
 
 CVE_STATUS[CVE-2026-23314] = "fixed-version: only affects 6.18 onwards"
 
@@ -21118,8 +21158,6 @@ CVE_STATUS[CVE-2026-23316] = "fixed-version: only affects 6.11 onwards"
 
 # CVE-2026-23319 may need backporting (fixed from 6.6.130)
 
-# CVE-2026-23320 needs backporting (fixed from 7.0rc1)
-
 # CVE-2026-23321 may need backporting (fixed from 6.6.130)
 
 CVE_STATUS[CVE-2026-23322] = "fixed-version: only affects 6.18 onwards"
@@ -21132,20 +21170,18 @@ CVE_STATUS[CVE-2026-23323] = "fixed-version: only affects 6.19 onwards"
 
 CVE_STATUS[CVE-2026-23326] = "fixed-version: only affects 6.13 onwards"
 
-# CVE-2026-23327 needs backporting (fixed from 7.0rc2)
+# CVE-2026-23327 needs backporting (fixed from 7.0)
 
 CVE_STATUS[CVE-2026-23328] = "fixed-version: only affects 6.14 onwards"
 
 CVE_STATUS[CVE-2026-23329] = "fixed-version: only affects 6.18 onwards"
 
-# CVE-2026-23330 needs backporting (fixed from 7.0rc3)
+# CVE-2026-23330 may need backporting (fixed from 6.6.136)
 
 CVE_STATUS[CVE-2026-23331] = "fixed-version: only affects 6.13 onwards"
 
 CVE_STATUS[CVE-2026-23332] = "fixed-version: only affects 6.16 onwards"
 
-# CVE-2026-23333 has no known resolution
-
 # CVE-2026-23334 may need backporting (fixed from 6.6.130)
 
 # CVE-2026-23335 may need backporting (fixed from 6.6.130)
@@ -21160,7 +21196,7 @@ CVE_STATUS[CVE-2026-23338] = "fixed-version: only affects 6.16 onwards"
 
 # CVE-2026-23340 may need backporting (fixed from 6.6.130)
 
-CVE_STATUS[CVE-2026-23341] = "fixed-version: only affects 6.19 onwards"
+CVE_STATUS[CVE-2026-23341] = "fixed-version: only affects 6.19.4 onwards"
 
 CVE_STATUS[CVE-2026-23342] = "fixed-version: only affects 6.18 onwards"
 
@@ -21170,11 +21206,11 @@ CVE_STATUS[CVE-2026-23344] = "fixed-version: only affects 6.19 onwards"
 
 CVE_STATUS[CVE-2026-23345] = "fixed-version: only affects 6.13 onwards"
 
-# CVE-2026-23346 needs backporting (fixed from 7.0rc2)
+# CVE-2026-23346 needs backporting (fixed from 7.0)
 
 # CVE-2026-23347 may need backporting (fixed from 6.6.130)
 
-# CVE-2026-23348 needs backporting (fixed from 7.0rc2)
+# CVE-2026-23348 needs backporting (fixed from 7.0)
 
 CVE_STATUS[CVE-2026-23349] = "fixed-version: only affects 6.18 onwards"
 
@@ -21188,7 +21224,7 @@ CVE_STATUS[CVE-2026-23353] = "fixed-version: only affects 6.19 onwards"
 
 CVE_STATUS[CVE-2026-23354] = "fixed-version: only affects 6.9 onwards"
 
-CVE_STATUS[CVE-2026-23355] = "fixed-version: only affects 6.18 onwards"
+CVE_STATUS[CVE-2026-23355] = "fixed-version: only affects 6.18.14 onwards"
 
 # CVE-2026-23356 may need backporting (fixed from 6.6.130)
 
@@ -21200,7 +21236,7 @@ CVE_STATUS[CVE-2026-23358] = "fixed-version: only affects 6.16 onwards"
 
 # CVE-2026-23360 may need backporting (fixed from 6.6.131)
 
-# CVE-2026-23361 needs backporting (fixed from 7.0rc2)
+# CVE-2026-23361 needs backporting (fixed from 7.0)
 
 # CVE-2026-23362 may need backporting (fixed from 6.6.130)
 
@@ -21220,19 +21256,19 @@ CVE_STATUS[CVE-2026-23369] = "fixed-version: only affects 6.7 onwards"
 
 # CVE-2026-23370 may need backporting (fixed from 6.6.130)
 
-# CVE-2026-23371 needs backporting (fixed from 7.0rc3)
+# CVE-2026-23371 needs backporting (fixed from 7.0)
 
 # CVE-2026-23372 may need backporting (fixed from 6.6.130)
 
 CVE_STATUS[CVE-2026-23373] = "fixed-version: only affects 6.9 onwards"
 
-# CVE-2026-23374 needs backporting (fixed from 7.0rc3)
+# CVE-2026-23374 may need backporting (fixed from 6.6.136)
 
 CVE_STATUS[CVE-2026-23375] = "fixed-version: only affects 6.8 onwards"
 
-CVE_STATUS[CVE-2026-23376] = "fixed-version: only affects 6.18 onwards"
+CVE_STATUS[CVE-2026-23376] = "fixed-version: only affects 6.17.3 onwards"
 
-# CVE-2026-23377 needs backporting (fixed from 7.0rc3)
+# CVE-2026-23377 needs backporting (fixed from 7.0)
 
 # CVE-2026-23378 may need backporting (fixed from 6.6.130)
 
@@ -21244,7 +21280,7 @@ CVE_STATUS[CVE-2026-23380] = "fixed-version: only affects 6.10 onwards"
 
 # CVE-2026-23382 may need backporting (fixed from 6.6.130)
 
-# CVE-2026-23383 needs backporting (fixed from 7.0rc2)
+# CVE-2026-23383 needs backporting (fixed from 7.0)
 
 CVE_STATUS[CVE-2026-23384] = "fixed-version: only affects 6.18 onwards"
 
@@ -21256,7 +21292,7 @@ CVE_STATUS[CVE-2026-23385] = "fixed-version: only affects 6.10 onwards"
 
 # CVE-2026-23388 may need backporting (fixed from 6.6.130)
 
-# CVE-2026-23389 needs backporting (fixed from 7.0rc3)
+# CVE-2026-23389 may need backporting (fixed from 6.6.136)
 
 CVE_STATUS[CVE-2026-23390] = "fixed-version: only affects 6.12 onwards"
 
@@ -21264,9 +21300,9 @@ CVE_STATUS[CVE-2026-23390] = "fixed-version: only affects 6.12 onwards"
 
 # CVE-2026-23392 may need backporting (fixed from 6.6.130)
 
-# CVE-2026-23393 needs backporting (fixed from 7.0rc5)
+# CVE-2026-23393 needs backporting (fixed from 7.0)
 
-CVE_STATUS[CVE-2026-23394] = "fixed-version: only affects 6.10 onwards"
+# CVE-2026-23394 may need backporting (fixed from 6.7)
 
 # CVE-2026-23395 may need backporting (fixed from 6.6.130)
 
@@ -21276,7 +21312,7 @@ CVE_STATUS[CVE-2026-23394] = "fixed-version: only affects 6.10 onwards"
 
 # CVE-2026-23398 may need backporting (fixed from 6.6.130)
 
-# CVE-2026-23399 needs backporting (fixed from 7.0rc5)
+# CVE-2026-23399 may need backporting (fixed from 6.6.136)
 
 CVE_STATUS[CVE-2026-23400] = "fixed-version: only affects 6.18 onwards"
 
@@ -21314,5 +21350,1923 @@ CVE_STATUS[CVE-2026-23416] = "fixed-version: only affects 6.17 onwards"
 
 CVE_STATUS[CVE-2026-23417] = "fixed-version: only affects 6.9 onwards"
 
-# CVE-2026-31788 may need backporting (fixed from 6.6.130)
+CVE_STATUS[CVE-2026-23418] = "fixed-version: only affects 6.14 onwards"
+
+# CVE-2026-23419 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23420 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-23421] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-23422 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-23423] = "fixed-version: only affects 6.13 onwards"
+
+CVE_STATUS[CVE-2026-23424] = "fixed-version: only affects 6.14 onwards"
+
+CVE_STATUS[CVE-2026-23425] = "fixed-version: only affects 6.14 onwards"
+
+# CVE-2026-23426 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23427 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23428 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-23429] = "fixed-version: only affects 6.18.7 onwards"
+
+CVE_STATUS[CVE-2026-23430] = "fixed-version: only affects 6.16 onwards"
+
+CVE_STATUS[CVE-2026-23431] = "fixed-version: only affects 6.17 onwards"
+
+CVE_STATUS[CVE-2026-23432] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-23433] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-23434 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-23435] = "fixed-version: only affects 6.18.2 onwards"
+
+CVE_STATUS[CVE-2026-23436] = "fixed-version: only affects 6.13 onwards"
+
+CVE_STATUS[CVE-2026-23437] = "fixed-version: only affects 6.13 onwards"
+
+# CVE-2026-23438 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23439 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23440 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23441 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23442 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-23443 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23444 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-23445] = "fixed-version: only affects 6.10 onwards"
+
+# CVE-2026-23446 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23447 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23448 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23449 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23450 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-23451] = "fixed-version: only affects 6.18.19 onwards"
+
+# CVE-2026-23452 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-23453] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-23454 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23455 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23456 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23457 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23458 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-23459] = "fixed-version: only affects 6.14 onwards"
+
+# CVE-2026-23460 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23461 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23462 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23463 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-23464] = "fixed-version: only affects 6.8 onwards"
+
+# CVE-2026-23465 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-23466] = "fixed-version: only affects 6.12 onwards"
+
+CVE_STATUS[CVE-2026-23467] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2026-23468 may need backporting (fixed from 6.6.140)
+
+CVE_STATUS[CVE-2026-23469] = "fixed-version: only affects 6.8 onwards"
+
+CVE_STATUS[CVE-2026-23470] = "fixed-version: only affects 6.8 onwards"
+
+# CVE-2026-23472 needs backporting (fixed from 7.0)
+
+# CVE-2026-23474 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-23475 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-31389 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-31390] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-31391 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-31392 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-31393 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-31394] = "fixed-version: only affects 6.11 onwards"
+
+CVE_STATUS[CVE-2026-31395] = "fixed-version: only affects 6.13 onwards"
+
+# CVE-2026-31396 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-31397] = "fixed-version: only affects 6.16 onwards"
+
+CVE_STATUS[CVE-2026-31398] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-31399 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-31400 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-31401] = "fixed-version: only affects 6.11 onwards"
+
+# CVE-2026-31402 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-31403 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-31404] = "fixed-version: only affects 6.14 onwards"
+
+# CVE-2026-31405 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-31406] = "fixed-version: only affects 6.11 onwards"
+
+# CVE-2026-31407 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31408 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31409 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-31410 needs backporting (fixed from 7.0)
+
+# CVE-2026-31411 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-31412 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-31413] = "fixed-version: only affects 6.12.75 onwards"
+
+# CVE-2026-31414 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31415 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31416 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31417 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31418 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31419 needs backporting (fixed from 7.0)
+
+# CVE-2026-31420 needs backporting (fixed from 7.0)
+
+# CVE-2026-31421 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31422 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31423 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31424 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31425 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31426 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31427 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31428 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31429 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31430 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31431 may need backporting (fixed from 6.6.137)
+
+# CVE-2026-31432 needs backporting (fixed from 7.0)
+
+# CVE-2026-31433 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31434 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31435] = "fixed-version: only affects 6.12 onwards"
+
+CVE_STATUS[CVE-2026-31436] = "fixed-version: only affects 6.8 onwards"
+
+CVE_STATUS[CVE-2026-31437] = "fixed-version: only affects 6.18.17 onwards"
+
+CVE_STATUS[CVE-2026-31438] = "fixed-version: only affects 6.8 onwards"
+
+# CVE-2026-31439 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31440 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-31441 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31442] = "fixed-version: only affects 6.14 onwards"
+
+CVE_STATUS[CVE-2026-31443] = "fixed-version: only affects 6.14 onwards"
+
+CVE_STATUS[CVE-2026-31444] = "fixed-version: only affects 6.6.130 onwards"
+
+CVE_STATUS[CVE-2026-31445] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-31446 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31447 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31448 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31449 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-31450 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31451 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31452 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31453 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31454 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31455 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31456] = "fixed-version: only affects 6.12 onwards"
+
+CVE_STATUS[CVE-2026-31457] = "fixed-version: only affects 6.17 onwards"
+
+# CVE-2026-31458 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31459] = "fixed-version: only affects 6.17.6 onwards"
+
+CVE_STATUS[CVE-2026-31460] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-31461] = "fixed-version: only affects 6.13 onwards"
+
+# CVE-2026-31462 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-31463] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-31464 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31465] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2026-31466 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31467 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31468] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-31469 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31470] = "fixed-version: only affects 6.7 onwards"
+
+CVE_STATUS[CVE-2026-31471] = "fixed-version: only affects 6.14 onwards"
+
+CVE_STATUS[CVE-2026-31472] = "fixed-version: only affects 6.14 onwards"
+
+# CVE-2026-31473 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31474 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31475] = "fixed-version: only affects 6.14.9 onwards"
+
+# CVE-2026-31476 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31477 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31478 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31479] = "fixed-version: only affects 6.8 onwards"
+
+# CVE-2026-31480 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31481] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-31482 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31483 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31484] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-31485 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31486 needs backporting (fixed from 7.0)
+
+# CVE-2026-31487 needs backporting (fixed from 7.0)
+
+# CVE-2026-31488 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-31489 may need backporting (fixed from 6.6.140)
+
+CVE_STATUS[CVE-2026-31490] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-31491] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-31492 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31493 needs backporting (fixed from 7.0)
+
+# CVE-2026-31494 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31495 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31496 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31497 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31498 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31499] = "fixed-version: only affects 6.12.20 onwards"
+
+# CVE-2026-31500 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31501] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-31502 needs backporting (fixed from 7.0)
+
+# CVE-2026-31503 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31504 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31505 needs backporting (fixed from 7.0)
+
+# CVE-2026-31506 needs backporting (fixed from 7.0)
+
+# CVE-2026-31507 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31508 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31509 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31510 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31511] = "fixed-version: only affects 6.12.59 onwards"
+
+# CVE-2026-31512 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31513] = "fixed-version: only affects 6.12.75 onwards"
+
+CVE_STATUS[CVE-2026-31514] = "fixed-version: only affects 6.12.75 onwards"
+
+# CVE-2026-31515 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31516 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-31517] = "fixed-version: only affects 6.14 onwards"
+
+# CVE-2026-31518 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31519 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31520 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31521 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31522 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31523 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31524 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31525 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31526] = "fixed-version: only affects 6.7 onwards"
+
+# CVE-2026-31527 needs backporting (fixed from 7.0)
+
+# CVE-2026-31528 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31529] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-31530 needs backporting (fixed from 7.0)
+
+# CVE-2026-31531 needs backporting (fixed from 7.0)
+
+# CVE-2026-31532 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31533 may need backporting (fixed from 6.6.135)
+
+CVE_STATUS[CVE-2026-31535] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-31536 needs backporting (fixed from 7.0)
+
+# CVE-2026-31537 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-31538] = "fixed-version: only affects 6.18 onwards"
+
+CVE_STATUS[CVE-2026-31539] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-31540 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-31541] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2026-31542 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-31543] = "fixed-version: only affects 6.16 onwards"
+
+CVE_STATUS[CVE-2026-31544] = "fixed-version: only affects 6.17 onwards"
+
+# CVE-2026-31545 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-31546 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-31547] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-31548 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-31549 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-31550 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-31551 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-31552 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-31553] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-31554] = "fixed-version: only affects 6.7 onwards"
+
+# CVE-2026-31555 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31556] = "fixed-version: only affects 6.8 onwards"
+
+# CVE-2026-31557 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-31558] = "fixed-version: only affects 6.10 onwards"
+
+CVE_STATUS[CVE-2026-31559] = "fixed-version: only affects 6.12.43 onwards"
+
+# CVE-2026-31560 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-31561] = "fixed-version: only affects 6.9 onwards"
+
+CVE_STATUS[CVE-2026-31562] = "fixed-version: only affects 6.9 onwards"
+
+# CVE-2026-31563 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31564] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-31565 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31566 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31567] = "fixed-version: only affects 6.17.8 onwards"
+
+# CVE-2026-31568 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-31569] = "fixed-version: only affects 6.13 onwards"
+
+# CVE-2026-31570 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-31571] = "fixed-version: only affects 6.15 onwards"
+
+CVE_STATUS[CVE-2026-31572] = "fixed-version: only affects 6.16 onwards"
+
+CVE_STATUS[CVE-2026-31573] = "fixed-version: only affects 6.19.6 onwards"
+
+CVE_STATUS[CVE-2026-31574] = "fixed-version: only affects 7.0 onwards"
+
+CVE_STATUS[CVE-2026-31575] = "fixed-version: only affects 6.7 onwards"
+
+# CVE-2026-31576 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31577 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31578 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31579 needs backporting (fixed from 7.1rc1)
+
+# CVE-2026-31580 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31581 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-31582] = "fixed-version: only affects 6.7 onwards"
+
+# CVE-2026-31583 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31584 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31585 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31586 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31587 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31588 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-31589] = "fixed-version: only affects 6.14 onwards"
+
+# CVE-2026-31590 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-31591] = "fixed-version: only affects 6.11 onwards"
+
+# CVE-2026-31592 needs backporting (fixed from 7.1rc1)
+
+CVE_STATUS[CVE-2026-31593] = "fixed-version: only affects 6.11 onwards"
+
+# CVE-2026-31594 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31595 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31596 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31597 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31598 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31599 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-31600] = "fixed-version: only affects 6.18 onwards"
+
+CVE_STATUS[CVE-2026-31601] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-31602 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31603 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31604 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31605 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31606 needs backporting (fixed from 7.1rc1)
+
+# CVE-2026-31607 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-31608] = "fixed-version: only affects 6.18.11 onwards"
+
+CVE_STATUS[CVE-2026-31609] = "fixed-version: only affects 6.18.11 onwards"
+
+# CVE-2026-31610 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31611 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31612 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31613 may need backporting (fixed from 6.6.141)
+
+# CVE-2026-31614 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31615 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31616 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31617 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31618 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31619 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-31620] = "fixed-version: only affects 6.18 onwards"
+
+CVE_STATUS[CVE-2026-31621] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-31622 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31623 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31624 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31625 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31626 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31627 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31628 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31629 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31630 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-31631] = "fixed-version: only affects 6.16 onwards"
+
+CVE_STATUS[CVE-2026-31632] = "fixed-version: only affects 6.16 onwards"
+
+CVE_STATUS[CVE-2026-31633] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2026-31634 may need backporting (fixed from 6.6.135)
+
+CVE_STATUS[CVE-2026-31635] = "fixed-version: only affects 6.16 onwards"
+
+CVE_STATUS[CVE-2026-31636] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2026-31637 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31638 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31639 may need backporting (fixed from 6.6.135)
+
+CVE_STATUS[CVE-2026-31640] = "fixed-version: only affects 6.16 onwards"
+
+CVE_STATUS[CVE-2026-31641] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2026-31642 may need backporting (fixed from 6.6.135)
+
+CVE_STATUS[CVE-2026-31643] = "fixed-version: only affects 6.16 onwards"
+
+CVE_STATUS[CVE-2026-31644] = "fixed-version: only affects 6.12 onwards"
+
+# CVE-2026-31645 needs backporting (fixed from 7.0)
+
+# CVE-2026-31646 may need backporting (fixed from 6.6.135)
+
+CVE_STATUS[CVE-2026-31647] = "fixed-version: only affects 6.9 onwards"
+
+# CVE-2026-31648 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31649 may need backporting (fixed from 6.6.135)
+
+CVE_STATUS[CVE-2026-31650] = "fixed-version: only affects 6.17 onwards"
+
+# CVE-2026-31651 may need backporting (fixed from 6.6.135)
+
+CVE_STATUS[CVE-2026-31652] = "fixed-version: only affects 6.17 onwards"
+
+CVE_STATUS[CVE-2026-31653] = "fixed-version: only affects 6.17 onwards"
+
+CVE_STATUS[CVE-2026-31654] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-31655 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31656 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31657 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31658 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31659 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31660 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31661 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31662 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31663 needs backporting (fixed from 7.0)
+
+# CVE-2026-31664 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31665 may need backporting (fixed from 6.6.135)
+
+CVE_STATUS[CVE-2026-31666] = "fixed-version: only affects 6.10 onwards"
+
+# CVE-2026-31667 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31668 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31669 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31670 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31671 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31672 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31673 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31674 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31675 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31676 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31677 needs backporting (fixed from 7.0)
+
+# CVE-2026-31678 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31679 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-31680 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31681 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31682 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31683 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-31684 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31685 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31686 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-31687] = "cpe-stable-backport: Backported in 6.6.126"
+
+# CVE-2026-31688 needs backporting (fixed from 7.0)
+
+# CVE-2026-31689 may need backporting (fixed from 6.6.135)
+
+CVE_STATUS[CVE-2026-31690] = "fixed-version: only affects 6.15 onwards"
+
+CVE_STATUS[CVE-2026-31691] = "fixed-version: only affects 6.14 onwards"
+
+# CVE-2026-31692 needs backporting (fixed from 7.0)
+
+# CVE-2026-31693 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-31694 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31695 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31696 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31697 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31698 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31699 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31700 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31701 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31702 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-31703] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-31704 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31705 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31706 needs backporting (fixed from 7.1rc1)
+
+# CVE-2026-31707 may need backporting (fixed from 6.6.141)
+
+# CVE-2026-31708 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31709 may need backporting (fixed from 6.6.140)
+
+CVE_STATUS[CVE-2026-31710] = "fixed-version: only affects 7.0 onwards"
+
+# CVE-2026-31711 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31712 may need backporting (fixed from 6.6.140)
+
+CVE_STATUS[CVE-2026-31713] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-31714 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31715 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-31716 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-31717 may need backporting (fixed from 6.7)
+
+# CVE-2026-31718 may need backporting (fixed from 6.6.140)
+
+CVE_STATUS[CVE-2026-31719] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-31720 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31721 may need backporting (fixed from 6.6.135)
+
+# CVE-2026-31722 needs backporting (fixed from 7.0)
+
+# CVE-2026-31723 needs backporting (fixed from 7.0)
+
+# CVE-2026-31724 needs backporting (fixed from 7.0)
+
+# CVE-2026-31725 needs backporting (fixed from 7.0)
+
+# CVE-2026-31726 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-31727] = "fixed-version: only affects 6.12.78 onwards"
+
+# CVE-2026-31728 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31729 needs backporting (fixed from 7.0)
+
+# CVE-2026-31730 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-31731] = "fixed-version: only affects 6.8 onwards"
+
+CVE_STATUS[CVE-2026-31732] = "fixed-version: only affects 6.9 onwards"
+
+CVE_STATUS[CVE-2026-31733] = "fixed-version: only affects 6.12 onwards"
+
+CVE_STATUS[CVE-2026-31734] = "fixed-version: only affects 6.18 onwards"
+
+CVE_STATUS[CVE-2026-31735] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-31736] = "fixed-version: only affects 6.11 onwards"
+
+# CVE-2026-31737 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31738 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-31739] = "fixed-version: only affects 6.10 onwards"
+
+# CVE-2026-31740 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31741 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-31742] = "fixed-version: only affects 6.18.20 onwards"
+
+CVE_STATUS[CVE-2026-31743] = "fixed-version: only affects 6.9 onwards"
+
+CVE_STATUS[CVE-2026-31744] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-31745] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-31746] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2026-31747 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31748 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31749 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-31750] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-31751 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31752 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-31753] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-31754 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31755 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31756 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-31757] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-31758 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31759 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-31760] = "fixed-version: only affects 6.13 onwards"
+
+# CVE-2026-31761 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31762 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31763 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-31764] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-31765] = "fixed-version: only affects 6.9 onwards"
+
+CVE_STATUS[CVE-2026-31766] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2026-31767 needs backporting (fixed from 7.0)
+
+# CVE-2026-31768 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-31769] = "fixed-version: only affects 6.13 onwards"
+
+# CVE-2026-31770 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31771 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-31772] = "fixed-version: only affects 6.12.2 onwards"
+
+# CVE-2026-31773 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-31774] = "fixed-version: only affects 6.10 onwards"
+
+CVE_STATUS[CVE-2026-31775] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-31776] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-31777 needs backporting (fixed from 7.0)
+
+# CVE-2026-31778 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31779 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31780 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-31781 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-31782] = "fixed-version: only affects 6.16 onwards"
+
+CVE_STATUS[CVE-2026-31783] = "fixed-version: only affects 6.18 onwards"
+
+CVE_STATUS[CVE-2026-31784] = "fixed-version: only affects 6.17 onwards"
+
+CVE_STATUS[CVE-2026-31785] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-31786 may need backporting (fixed from 6.6.137)
+
+# CVE-2026-31787 may need backporting (fixed from 6.6.137)
+
+# CVE-2026-31788 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43004] = "fixed-version: only affects 6.15 onwards"
+
+CVE_STATUS[CVE-2026-43005] = "fixed-version: only affects 6.17 onwards"
+
+CVE_STATUS[CVE-2026-43006] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-43007 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-43008] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-43009 needs backporting (fixed from 7.0)
+
+# CVE-2026-43010 needs backporting (fixed from 7.0)
+
+# CVE-2026-43011 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-43012] = "fixed-version: only affects 6.12.9 onwards"
+
+# CVE-2026-43013 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43014 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43015 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43016 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43017 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43018 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43019 needs backporting (fixed from 7.0)
+
+# CVE-2026-43020 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-43021] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-43022 may need backporting (fixed from 6.7)
+
+# CVE-2026-43023 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43024 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43025 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43026 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43027 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43028 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43029 may need backporting (fixed from 6.7)
+
+# CVE-2026-43030 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-43031] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-43032 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43033 may need backporting (fixed from 6.6.137)
+
+CVE_STATUS[CVE-2026-43034] = "fixed-version: only affects 6.8 onwards"
+
+# CVE-2026-43035 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43036 needs backporting (fixed from 7.0)
+
+# CVE-2026-43037 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43038 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-43039] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-43040 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43041 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43042 needs backporting (fixed from 7.0)
+
+# CVE-2026-43043 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43044 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-43045] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-43046 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43047 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43048 needs backporting (fixed from 7.0)
+
+# CVE-2026-43049 needs backporting (fixed from 7.0)
+
+# CVE-2026-43050 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43051 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43052 needs backporting (fixed from 7.0)
+
+# CVE-2026-43053 needs backporting (fixed from 7.0)
+
+# CVE-2026-43054 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-43055] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2026-43056 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43057 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43058 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-43059] = "fixed-version: only affects 6.12.59 onwards"
+
+# CVE-2026-43060 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43061 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43062 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43063] = "fixed-version: only affects 6.10 onwards"
+
+# CVE-2026-43064 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-43065 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-43066 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-43067 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43068 may need backporting (fixed from 6.6.131)
+
+# CVE-2026-43069 may need backporting (fixed from 6.6.131)
+
+CVE_STATUS[CVE-2026-43070] = "fixed-version: only affects 6.18.17 onwards"
+
+# CVE-2026-43071 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43072 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43073 needs backporting (fixed from 7.1rc1)
+
+# CVE-2026-43074 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43075 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43076 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43077 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43078 may need backporting (fixed from 6.6.137)
+
+# CVE-2026-43079 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43080 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43081 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43082 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43083 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-43084] = "fixed-version: only affects 6.12.75 onwards"
+
+# CVE-2026-43085 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43086 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-43087] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-43088 needs backporting (fixed from 7.0)
+
+# CVE-2026-43089 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-43090] = "fixed-version: only affects 6.12 onwards"
+
+# CVE-2026-43091 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43092 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43093 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43094 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-43095] = "fixed-version: only affects 6.17 onwards"
+
+CVE_STATUS[CVE-2026-43096] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-43097] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-43098 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43099 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-43100] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-43101 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-43102] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-43103 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43104 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43105 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-43106] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-43107 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-43108] = "fixed-version: only affects 6.11 onwards"
+
+# CVE-2026-43109 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-43110 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43111 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43112 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43113 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43114 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43115 needs backporting (fixed from 7.0)
+
+# CVE-2026-43116 needs backporting (fixed from 7.0)
+
+# CVE-2026-43117 may need backporting (fixed from 6.6.136)
+
+# CVE-2026-43118 needs backporting (fixed from 7.0)
+
+# CVE-2026-43119 needs backporting (fixed from 7.0)
+
+# CVE-2026-43120 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-43121] = "fixed-version: only affects 6.15 onwards"
+
+CVE_STATUS[CVE-2026-43122] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-43123 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43124 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43125 needs backporting (fixed from 7.0)
+
+# CVE-2026-43126 needs backporting (fixed from 7.0)
+
+# CVE-2026-43127 may need backporting (fixed from 6.7)
+
+# CVE-2026-43128 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43129 needs backporting (fixed from 7.0)
+
+# CVE-2026-43130 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43131] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-43132 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43133 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43134 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43135 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43136 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43137 may need backporting (fixed from 6.6.141)
+
+CVE_STATUS[CVE-2026-43138] = "fixed-version: only affects 6.9 onwards"
+
+# CVE-2026-43139 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43140 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43141 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43142] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-43143 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43144] = "fixed-version: only affects 6.13 onwards"
+
+# CVE-2026-43145 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43146] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-43147 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43148 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43149 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43150 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43151] = "fixed-version: only affects 6.18.3 onwards"
+
+# CVE-2026-43152 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43153 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-43154] = "fixed-version: only affects 6.18 onwards"
+
+CVE_STATUS[CVE-2026-43155] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2026-43156 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43157 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43158 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43159 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43160] = "fixed-version: only affects 6.17 onwards"
+
+# CVE-2026-43161 needs backporting (fixed from 7.0)
+
+# CVE-2026-43162 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43163 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43164] = "fixed-version: only affects 6.18 onwards"
+
+CVE_STATUS[CVE-2026-43165] = "fixed-version: only affects 6.13 onwards"
+
+CVE_STATUS[CVE-2026-43166] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-43167 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43168 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43169] = "fixed-version: only affects 6.7 onwards"
+
+# CVE-2026-43170 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43171 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43172 needs backporting (fixed from 7.0)
+
+# CVE-2026-43173 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43174] = "fixed-version: only affects 6.15 onwards"
+
+CVE_STATUS[CVE-2026-43175] = "fixed-version: only affects 6.8 onwards"
+
+CVE_STATUS[CVE-2026-43176] = "fixed-version: only affects 6.18 onwards"
+
+CVE_STATUS[CVE-2026-43177] = "fixed-version: only affects 6.10 onwards"
+
+CVE_STATUS[CVE-2026-43178] = "fixed-version: only affects 6.12.70 onwards"
+
+CVE_STATUS[CVE-2026-43179] = "fixed-version: only affects 6.17 onwards"
+
+# CVE-2026-43180 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43181] = "fixed-version: only affects 6.17 onwards"
+
+# CVE-2026-43182 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43183 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43184 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43185 needs backporting (fixed from 7.0)
+
+# CVE-2026-43186 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43187 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43188] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-43189 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43190 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43191] = "fixed-version: only affects 6.7 onwards"
+
+CVE_STATUS[CVE-2026-43192] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-43193] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-43194 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43195] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2026-43196 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43197 needs backporting (fixed from 7.0)
+
+# CVE-2026-43198 needs backporting (fixed from 7.0)
+
+# CVE-2026-43199 needs backporting (fixed from 7.0)
+
+# CVE-2026-43200 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43201] = "fixed-version: only affects 6.12.63 onwards"
+
+# CVE-2026-43202 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43203 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43204 needs backporting (fixed from 7.0)
+
+# CVE-2026-43205 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43206 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43207 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43208] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-43209 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43210] = "fixed-version: only affects 6.12 onwards"
+
+# CVE-2026-43211 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43212 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43213 needs backporting (fixed from 7.0)
+
+# CVE-2026-43214 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43215 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43216 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-43217] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-43218 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43219 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-43220] = "fixed-version: only affects 6.6.128 onwards"
+
+# CVE-2026-43221 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43222 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43223 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43224] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-43225 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43226 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43227 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43228] = "fixed-version: only affects 6.18 onwards"
+
+CVE_STATUS[CVE-2026-43229] = "fixed-version: only affects 6.8 onwards"
+
+# CVE-2026-43230 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43231 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43232 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43233 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43234 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-43235] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-43236 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43237] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2026-43238 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43239 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43240 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43241 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43242 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43243] = "fixed-version: only affects 6.11 onwards"
+
+# CVE-2026-43244 needs backporting (fixed from 7.0)
+
+# CVE-2026-43245 may need backporting (fixed from 6.6.141)
+
+# CVE-2026-43246 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43247] = "fixed-version: only affects 6.13 onwards"
+
+# CVE-2026-43248 needs backporting (fixed from 7.0)
+
+# CVE-2026-43249 needs backporting (fixed from 7.0)
+
+# CVE-2026-43250 needs backporting (fixed from 7.0)
+
+# CVE-2026-43251 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43252 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43253 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43254] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2026-43255 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43256 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43257 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43258 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-43259] = "fixed-version: only affects 6.15 onwards"
+
+CVE_STATUS[CVE-2026-43260] = "fixed-version: only affects 6.11 onwards"
+
+# CVE-2026-43261 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43262 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43263] = "fixed-version: only affects 6.8 onwards"
+
+# CVE-2026-43264 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43265 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43266 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43267] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-43268 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43269 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43270 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43271 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43272] = "fixed-version: only affects 6.12 onwards"
+
+# CVE-2026-43273 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43274] = "fixed-version: only affects 6.14 onwards"
+
+# CVE-2026-43275 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43276] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2026-43277 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43278 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43279 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43280] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-43281 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43282] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-43283 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43284 may need backporting (fixed from 6.6.138)
+
+CVE_STATUS[CVE-2026-43285] = "fixed-version: only affects 6.18 onwards"
+
+CVE_STATUS[CVE-2026-43286] = "fixed-version: only affects 6.14.8 onwards"
+
+# CVE-2026-43287 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43288 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43289 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43290] = "fixed-version: only affects 6.17 onwards"
+
+# CVE-2026-43291 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43292] = "fixed-version: only affects 6.9 onwards"
+
+CVE_STATUS[CVE-2026-43293] = "fixed-version: only affects 6.10 onwards"
+
+# CVE-2026-43294 needs backporting (fixed from 7.0)
+
+# CVE-2026-43295 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43296 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43297] = "fixed-version: only affects 6.8 onwards"
+
+# CVE-2026-43298 needs backporting (fixed from 7.0)
+
+# CVE-2026-43299 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-43300] = "fixed-version: only affects 6.7 onwards"
+
+CVE_STATUS[CVE-2026-43301] = "fixed-version: only affects 6.8 onwards"
+
+# CVE-2026-43302 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43303 needs backporting (fixed from 7.0)
+
+# CVE-2026-43304 may need backporting (fixed from 6.6.128)
+
+CVE_STATUS[CVE-2026-43305] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-43306] = "fixed-version: only affects 6.10 onwards"
+
+CVE_STATUS[CVE-2026-43307] = "fixed-version: only affects 6.12 onwards"
+
+# CVE-2026-43308 needs backporting (fixed from 7.0)
+
+# CVE-2026-43309 needs backporting (fixed from 7.0)
+
+# CVE-2026-43310 needs backporting (fixed from 7.0)
+
+# CVE-2026-43311 needs backporting (fixed from 7.0)
+
+# CVE-2026-43312 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43313 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43314 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43315 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43316 may need backporting (fixed from 6.6.128)
+
+# CVE-2026-43317 needs backporting (fixed from 7.0)
+
+# CVE-2026-43318 needs backporting (fixed from 7.0)
+
+# CVE-2026-43319 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-43320] = "fixed-version: only affects 6.10.13 onwards"
+
+CVE_STATUS[CVE-2026-43321] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-43322] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-43323] = "fixed-version: only affects 6.12.78 onwards"
+
+# CVE-2026-43324 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-43325] = "fixed-version: only affects 6.9 onwards"
+
+CVE_STATUS[CVE-2026-43326] = "fixed-version: only affects 6.12 onwards"
+
+# CVE-2026-43327 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43328 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43329 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43330 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43331 needs backporting (fixed from 7.0)
+
+# CVE-2026-43332 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43333 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43334 may need backporting (fixed from 6.6.134)
+
+CVE_STATUS[CVE-2026-43335] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-43336 may need backporting (fixed from 6.6.135)
+
+CVE_STATUS[CVE-2026-43337] = "fixed-version: only affects 6.11.3 onwards"
+
+# CVE-2026-43338 needs backporting (fixed from 7.0)
+
+# CVE-2026-43339 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43340 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43341 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43342 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43343 may need backporting (fixed from 6.6.134)
+
+# CVE-2026-43344 needs backporting (fixed from 7.0)
+
+# CVE-2026-43345 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-43346] = "fixed-version: only affects 6.12.11 onwards"
+
+CVE_STATUS[CVE-2026-43347] = "fixed-version: only affects 6.14 onwards"
+
+CVE_STATUS[CVE-2026-43348] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-43349] = "fixed-version: only affects 6.18.13 onwards"
+
+# CVE-2026-43350 may need backporting (fixed from 6.6.136)
+
+CVE_STATUS[CVE-2026-43351] = "fixed-version: only affects 6.14 onwards"
+
+# CVE-2026-43352 needs backporting (fixed from 7.0)
+
+# CVE-2026-43353 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-43354] = "fixed-version: only affects 6.12 onwards"
+
+# CVE-2026-43355 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43356] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-43357 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43358] = "fixed-version: only affects 6.16.4 onwards"
+
+# CVE-2026-43359 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43360 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43361 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43362 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43363 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43364] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2026-43365 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43366 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43367] = "fixed-version: only affects 6.18.16 onwards"
+
+# CVE-2026-43368 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43369] = "fixed-version: only affects 6.18.16 onwards"
+
+# CVE-2026-43370 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43371 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43372 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43373 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43374] = "fixed-version: only affects 6.9 onwards"
+
+CVE_STATUS[CVE-2026-43375] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-43376 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43377 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43378 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43379 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43380 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43381 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43382 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43383 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43384] = "fixed-version: only affects 6.7 onwards"
+
+CVE_STATUS[CVE-2026-43385] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-43386 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43387 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43388] = "fixed-version: only affects 6.14 onwards"
+
+CVE_STATUS[CVE-2026-43389] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-43390] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-43391] = "fixed-version: only affects 6.18 onwards"
+
+CVE_STATUS[CVE-2026-43392] = "fixed-version: only affects 6.12 onwards"
+
+CVE_STATUS[CVE-2026-43393] = "fixed-version: only affects 6.12 onwards"
+
+CVE_STATUS[CVE-2026-43394] = "fixed-version: only affects 6.10 onwards"
+
+CVE_STATUS[CVE-2026-43395] = "fixed-version: only affects 6.8 onwards"
+
+CVE_STATUS[CVE-2026-43396] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-43397 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43398] = "fixed-version: only affects 6.16 onwards"
+
+CVE_STATUS[CVE-2026-43399] = "fixed-version: only affects 6.16 onwards"
+
+CVE_STATUS[CVE-2026-43400] = "fixed-version: only affects 6.16 onwards"
+
+CVE_STATUS[CVE-2026-43401] = "fixed-version: only affects 6.18 onwards"
+
+CVE_STATUS[CVE-2026-43402] = "fixed-version: only affects 6.14 onwards"
+
+CVE_STATUS[CVE-2026-43403] = "fixed-version: only affects 6.12 onwards"
+
+CVE_STATUS[CVE-2026-43404] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-43405 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43406 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43407 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43408] = "fixed-version: only affects 6.12.48 onwards"
+
+# CVE-2026-43409 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43410] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-43411 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43412 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43413 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43414 may need backporting (fixed from 6.7)
+
+# CVE-2026-43415 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43416 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-43417] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-43418] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-43419 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43420 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43421 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-43422] = "fixed-version: only affects 6.18.17 onwards"
+
+CVE_STATUS[CVE-2026-43423] = "fixed-version: only affects 6.18.17 onwards"
+
+# CVE-2026-43424 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43425 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43426 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43427 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43428 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43429 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43430 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43431] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-43432 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43433] = "fixed-version: only affects 6.18 onwards"
+
+CVE_STATUS[CVE-2026-43434] = "fixed-version: only affects 6.18 onwards"
+
+CVE_STATUS[CVE-2026-43435] = "fixed-version: only affects 6.18 onwards"
+
+# CVE-2026-43436 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43437 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43438] = "fixed-version: only affects 6.12 onwards"
+
+# CVE-2026-43439 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43440] = "fixed-version: only affects 6.18.16 onwards"
+
+# CVE-2026-43441 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43442] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-43443 needs backporting (fixed from 7.0)
+
+CVE_STATUS[CVE-2026-43444] = "fixed-version: only affects 6.12 onwards"
+
+# CVE-2026-43445 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43446] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-43447] = "fixed-version: only affects 6.15 onwards"
+
+# CVE-2026-43448 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43449 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43450 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43451 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43452 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43453 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43454] = "fixed-version: only affects 6.16 onwards"
+
+# CVE-2026-43455 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43456 needs backporting (fixed from 7.0)
+
+# CVE-2026-43457 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43458 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43459 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43460] = "fixed-version: only affects 6.14 onwards"
+
+CVE_STATUS[CVE-2026-43461] = "fixed-version: only affects 6.18 onwards"
+
+CVE_STATUS[CVE-2026-43462] = "fixed-version: only affects 6.18 onwards"
+
+CVE_STATUS[CVE-2026-43463] = "fixed-version: only affects 6.7.3 onwards"
+
+# CVE-2026-43464 may need backporting (fixed from 6.7)
+
+# CVE-2026-43465 may need backporting (fixed from 6.7)
+
+# CVE-2026-43466 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43467] = "fixed-version: only affects 6.12.56 onwards"
+
+# CVE-2026-43468 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43469 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43470] = "fixed-version: only affects 6.10 onwards"
+
+# CVE-2026-43471 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43472 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43473 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43474] = "fixed-version: only affects 6.17 onwards"
+
+# CVE-2026-43475 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43476 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43477] = "fixed-version: only affects 6.16 onwards"
+
+CVE_STATUS[CVE-2026-43478] = "fixed-version: only affects 6.19 onwards"
+
+CVE_STATUS[CVE-2026-43479] = "fixed-version: only affects 6.17 onwards"
+
+# CVE-2026-43480 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43481] = "fixed-version: only affects 6.13 onwards"
+
+CVE_STATUS[CVE-2026-43482] = "fixed-version: only affects 6.12 onwards"
+
+# CVE-2026-43483 may need backporting (fixed from 6.6.130)
+
+# CVE-2026-43484 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43485] = "fixed-version: only affects 6.7 onwards"
+
+CVE_STATUS[CVE-2026-43486] = "fixed-version: only affects 6.9 onwards"
+
+CVE_STATUS[CVE-2026-43487] = "fixed-version: only affects 6.9 onwards"
+
+# CVE-2026-43488 may need backporting (fixed from 6.6.130)
+
+CVE_STATUS[CVE-2026-43489] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-43490 may need backporting (fixed from 6.6.141)
+
+# CVE-2026-43491 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-43492 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-43493 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-43494 may need backporting (fixed from 6.6.141)
+
+# CVE-2026-43495 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-43496 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-43497 may need backporting (fixed from 6.6.140)
+
+CVE_STATUS[CVE-2026-43498] = "fixed-version: only affects 6.19 onwards"
+
+# CVE-2026-43499 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-43500 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-43501 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-43502 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-43503 may need backporting (fixed from 6.6.141)
+
+# CVE-2026-45834 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-45835 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-45836 may need backporting (fixed from 6.6.140)
+
+# CVE-2026-46300 may need backporting (fixed from 6.6.141)
+
+# CVE-2026-46333 may need backporting (fixed from 6.6.139)
 

---
base-commit: 595777ffbd74a3814ddcffabe9f6f0c221b5f3bb
change-id: 20260527-ycongal-scarthgap-linux_metrics_warnings-bf1af72d85aa

Best regards,
-- 
Yoann Congal <yoann.congal@smile.fr>

