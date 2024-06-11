From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 11 Jun 2024 16:05:01 +0100
Subject: [PATCH kmod 01/20] man: add script to generate/compare the xslt vs
 upcoming scdoc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-man-v1-1-bd6864d49639@gmail.com>
References: <20240611-man-v1-0-bd6864d49639@gmail.com>
In-Reply-To: <20240611-man-v1-0-bd6864d49639@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718118301; l=1480;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=wl8y3cCAXvkyBcYxfCkLgOSs/6n6t5ifCxlBs/k7x6I=;
 b=Lo2mmoP5zfrYdpxqFhJA2HGysoY+JMSnam2FhSYYf+v4tmMS4fpr7t0pb73yVlWbI681n33Xb
 kRG6S655KCKCnsKQAam275T186SdStufp6n66SySItkII75tliGR13V
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 man/compare.sh | 63 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 63 insertions(+)

diff --git a/man/compare.sh b/man/compare.sh
new file mode 100755
index 0000000..7579ab5
--- /dev/null
+++ b/man/compare.sh
@@ -0,0 +1,63 @@
+#!/bin/bash
+
+the_sed()
+{
+	sed -e 's|@DISTCONFDIR@|/TEST|g;s|@MODULE_DIRECTORY@|/TEST|g' $1
+}
+
+gen_xslt()
+{
+			#--output ${xml//.xml}.xslt \
+			#--noout \
+	for xml in *xml; do
+		the_sed $xml | xsltproc \
+			--stringparam man.output.quietly 1 \
+			--param funcsynopsis.style "'ansi'" \
+			http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl -
+		# The output and noout args seems cosmetic, sigh
+		mv ${xml//.xml}{,.xslt}
+	done
+}
+
+gen_scdoc()
+{
+	for scd in *scd; do
+		the_sed $scd | scdoc > ${scd//.scd}.scdoc
+	done
+}
+
+comp_output()
+{
+	export LESS='-F -i -M -R -S -w -X -z-4'
+	unset MANPAGER
+
+	for xslt in $(ls --sort=version *xslt); do
+		_name=${xslt//.xslt}
+
+		echo "Checking $_name"
+
+		diff --unified --color=always \
+			<(man ./$_name.xslt) \
+			<(man ./$_name.scdoc) | less
+
+		read
+	done
+}
+
+comp_raw()
+{
+	for xslt in *xslt; do
+		_name=${xslt//.xslt}
+
+		diff --unified --color=always ./$_name.{xslt,scdoc}
+	done
+}
+
+time gen_xslt
+time gen_scdoc
+
+comp_output
+#comp_raw
+
+rm -f *xslt
+rm -f *scdoc

-- 
2.45.0

