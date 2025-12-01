From: Maud Spierings <maudspierings@gocontroll.com>
Date: Mon, 01 Dec 2025 11:26:17 +0100
Subject: [PATCH v2 2/3] scripts: imx: add pread implementation for mingw
 target
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251201-imx_usb-v2-2-95ec2a0e8694@gocontroll.com>
References: <20251201-imx_usb-v2-0-95ec2a0e8694@gocontroll.com>
In-Reply-To: <20251201-imx_usb-v2-0-95ec2a0e8694@gocontroll.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764584777; l=1814;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=OwKMuhXH5vvFbq1Z8XaoBUlAP4WA1sPVmfjqijDeoZM=;
 b=woLXBIN/jjS5yzBGoI2TR3E36NcLpcYAUxQ/WM0liQbyymFNqKXtF1O4nceN8OLT01/9FgeOn
 W1aRLl1ovSmBNYFYph5KKj44qXRLw6uisubNuXsKOgKYjWiboSDxtQl
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a simple pread implementation for the mingw target so imx-usb-loader
can be compiled for windows.

This function is actually only called by bareboxtlv, which I don't think
targets being compiled for windows, so it is a bit of a dead weight.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 scripts/imx/Makefile.mingw64 |  2 +-
 scripts/imx/pread.c          | 25 +++++++++++++++++++++++++
 2 files changed, 26 insertions(+), 1 deletion(-)

diff --git a/scripts/imx/Makefile.mingw64 b/scripts/imx/Makefile.mingw64
index 101b39e917..a7be48ae53 100644
--- a/scripts/imx/Makefile.mingw64
+++ b/scripts/imx/Makefile.mingw64
@@ -33,7 +33,7 @@ obj := $(realpath $(obj))
 CPPFLAGS := -I $(LIBUSB_MINGW)/include/libusb-1.0 -I $(src)/../include/ -I $(src)/../../include/mach/ -include $(src)/../include/defines.h
 LDFLAGS := -L $(LIBUSB_MINGW)/lib -lusb-1.0 -static
 
-OBJECTS := $(addprefix $(obj)/, imx.o imx-usb-loader.o)
+OBJECTS := $(addprefix $(obj)/, imx.o imx-usb-loader.o pread.o)
 
 $(obj)/%.o: $(src)/%.c
 	@$(CC) -c -o $@ $< $(CPPFLAGS)
diff --git a/scripts/imx/pread.c b/scripts/imx/pread.c
new file mode 100644
index 0000000000..febb6f3243
--- /dev/null
+++ b/scripts/imx/pread.c
@@ -0,0 +1,25 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+// SPDX-FileCopyrightText: 2025 Maud Spierings, GOcontroll B.V.
+
+#include <stdint.h>
+#include <sys/types.h>
+#include <unistd.h>
+
+ssize_t pread(int fd, void *buf, size_t count, off_t offset)
+{
+	int offset_start, now;
+
+	offset_start = lseek(fd, 0, SEEK_CUR);
+	if (offset_start < 0)
+		return offset_start;
+
+	now = lseek(fd, offset, SEEK_SET);
+	if (now < 0)
+		return now;
+
+	now = read(fd, buf, count);
+
+	lseek(fd, offset_start, SEEK_SET);
+
+	return now;
+}

-- 
2.52.0

