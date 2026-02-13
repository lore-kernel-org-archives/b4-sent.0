From: =?utf-8?q?Bence_Cs=C3=B3k=C3=A1s?= <bence98@sch.bme.hu>
Date: Fri, 13 Feb 2026 01:12:07 +0100
Subject: [PATCH v2] Documentation: sysfs-pps: Fix `Description:`s
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260213-sysfs-pps-doc-re-v2-1-044cba5715e1@sch.bme.hu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13MQQ7CIBBA0as0rB1TKDTqynsYF0AHS6JAZmqja
 Xp3qYkbl3/x3yIYKSKLU7MIwjlyzKmG2jXCjzbdEOJQW6hW9a2SCvjNgaEUhiF7IIS+O6LW0mj
 ne1G3Qhji60terrUD5QdMI6H9QaY9SANO/1mzBAm9HDpp0Abn7blQvtu0H5+b6ywjOLLJj5vzs
 DwhiXX9AKz79zrDAAAA
X-Change-ID: 20260212-sysfs-pps-doc-re-639e44154bc6
To: Rodolfo Giometti <giometti@enneenne.com>
Cc: linux-kernel@vger.kernel.org, 
 =?utf-8?q?Bence_Cs=C3=B3k=C3=A1s?= <bence98@sch.bme.hu>, 
 Rodolfo Giometti <giometti@linux.it>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770941534; l=4183;
 i=bence98@sch.bme.hu; s=20260213; h=from:subject:message-id;
 bh=NDSyGXtsT/QAd57UBSLhgXDguFZiMPZ+GFjvlQWLn4w=;
 b=YBNDcndyBnstItj3XeujA/660RgesvucRvalhiwOvQV1cPjwwejam2C66ry0XCtYlSIG111Ld
 mIZi3otCbceD9v+bGmwtSBITGXTYarsM6o4dFryS7SvipUD597E3iB5
X-Developer-Key: i=bence98@sch.bme.hu; a=ed25519;
 pk=rtWE8PtqZ5ZMyUVCckDq8i1ASLxgUbV2fwDA8KaOli8=
X-Endpoint-Received: by B4 Relay for bence98@sch.bme.hu/20260213 with auth_id=636
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It is unnecessary to duplicate `What:` content in the description. It
makes it harder to both read and maintain.

Also, the uapi header no longer lives at `linux/include/linux/pps.h`.

Acked-by: Rodolfo Giometti <giometti@enneenne.com>
Signed-off-by: Bence Csókás <bence98@sch.bme.hu>
---
Changes in v2:
* rebased on current master
* updated email from mailmap

Link to v1:
* https://lore.kernel.org/lkml/20250815-b4-sysfs-pps-doc-v1-1-61d315eafbca@prolan.hu
---
 Documentation/ABI/testing/sysfs-pps     | 29 ++++++++++++-----------------
 Documentation/ABI/testing/sysfs-pps-gen |  2 +-
 2 files changed, 13 insertions(+), 18 deletions(-)

diff --git a/Documentation/ABI/testing/sysfs-pps b/Documentation/ABI/testing/sysfs-pps
index 25028c7bc37d..b8034ead5ae5 100644
--- a/Documentation/ABI/testing/sysfs-pps
+++ b/Documentation/ABI/testing/sysfs-pps
@@ -10,16 +10,16 @@ What:		/sys/class/pps/ppsX/
 Date:		February 2008
 Contact:	Rodolfo Giometti <giometti@linux.it>
 Description:
-		The /sys/class/pps/ppsX/ directory is related to X-th
-		PPS source into the system. Each directory will
-		contain files to manage and control its PPS source.
+		This directory represents the X-th PPS source in the system.
+		Each directory will contain files to manage and control its
+		PPS source.
 
 What:		/sys/class/pps/ppsX/assert
 Date:		February 2008
 Contact:	Rodolfo Giometti <giometti@linux.it>
 Description:
-		The /sys/class/pps/ppsX/assert file reports the assert events
-		and the assert sequence number of the X-th source in the form:
+		This file reports the assert events and the assert sequence
+		number in the form:
 
 			<secs>.<nsec>#<sequence>
 
@@ -30,8 +30,8 @@ What:		/sys/class/pps/ppsX/clear
 Date:		February 2008
 Contact:	Rodolfo Giometti <giometti@linux.it>
 Description:
-		The /sys/class/pps/ppsX/clear file reports the clear events
-		and the clear sequence number of the X-th source in the form:
+		This file reports the clear events and the clear sequence
+		number in the form:
 
 			<secs>.<nsec>#<sequence>
 
@@ -42,32 +42,27 @@ What:		/sys/class/pps/ppsX/mode
 Date:		February 2008
 Contact:	Rodolfo Giometti <giometti@linux.it>
 Description:
-		The /sys/class/pps/ppsX/mode file reports the functioning
-		mode of the X-th source in hexadecimal encoding.
+		This file reports the mode bits in hexadecimal encoding.
 
-		Please, refer to linux/include/linux/pps.h for further
-		info.
+		Please refer to <linux/pps.h> for further info.
 
 What:		/sys/class/pps/ppsX/echo
 Date:		February 2008
 Contact:	Rodolfo Giometti <giometti@linux.it>
 Description:
-		The /sys/class/pps/ppsX/echo file reports if the X-th does
-		or does not support an "echo" function.
+		Whether this source supports an "echo" function.
 
 What:		/sys/class/pps/ppsX/name
 Date:		February 2008
 Contact:	Rodolfo Giometti <giometti@linux.it>
 Description:
-		The /sys/class/pps/ppsX/name file reports the name of the
-		X-th source.
+		The name of the PPS source.
 
 What:		/sys/class/pps/ppsX/path
 Date:		February 2008
 Contact:	Rodolfo Giometti <giometti@linux.it>
 Description:
-		The /sys/class/pps/ppsX/path file reports the path name of
-		the device connected with the X-th source.
+		The path name of the device connected to this source.
 
 		If the source is not connected with any device the content
 		of this file is empty.
diff --git a/Documentation/ABI/testing/sysfs-pps-gen b/Documentation/ABI/testing/sysfs-pps-gen
index 2519207b88fd..c36bac37a883 100644
--- a/Documentation/ABI/testing/sysfs-pps-gen
+++ b/Documentation/ABI/testing/sysfs-pps-gen
@@ -12,7 +12,7 @@ Date:		February 2025
 KernelVersion:  6.13
 Contact:	Rodolfo Giometti <giometti@enneenne.com>
 Description:
-		The /sys/class/pps-gen/pps-genX/ directory is related to X-th
+		This directory represents the X-th
 		PPS generator in the system. Each directory contain files to
 		manage and control its PPS generator.
 

---
base-commit: 136114e0abf03005e182d75761ab694648e6d388
change-id: 20260212-sysfs-pps-doc-re-639e44154bc6

Best regards,
-- 
Bence Csókás <bence98@sch.bme.hu>

