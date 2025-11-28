From: Maud Spierings <maudspierings@gocontroll.com>
Date: Fri, 28 Nov 2025 15:08:53 +0100
Subject: [PATCH 2/3] scripts: imx: Makefile.mingw64: add _GNU_SOURCE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251128-imx_usb-v1-2-bb6a5180b38e@gocontroll.com>
References: <20251128-imx_usb-v1-0-bb6a5180b38e@gocontroll.com>
In-Reply-To: <20251128-imx_usb-v1-0-bb6a5180b38e@gocontroll.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764339080; l=915;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=puxY5pJSZsJ+VyRdZC4qG9rFi3Qw/x8A0EbiuaE/63c=;
 b=Ba7tWP+MlEQr3j+n3GlWvfXZlCAwEaOc4+bguWvJzczNsdgG6Zb6u0wvqe5PsGzcwPyYstTTN
 Gcqg4TlMjfaBHQD4T1A0/n4odPFVlUBKD81MKOD2j0vRgCS0QmV1wN/
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

imx.c uses asprintf which requires _GNU_SOURCE to be defined, include
defines.h to define it.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 scripts/imx/Makefile.mingw64 | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/scripts/imx/Makefile.mingw64 b/scripts/imx/Makefile.mingw64
index e012d833f1..101b39e917 100644
--- a/scripts/imx/Makefile.mingw64
+++ b/scripts/imx/Makefile.mingw64
@@ -30,7 +30,7 @@ $(if $(obj),, \
 # $(realpath ...) resolves symlinks
 obj := $(realpath $(obj))
 
-CPPFLAGS := -I $(LIBUSB_MINGW)/include/libusb-1.0 -I $(src)/../include/ -I $(src)/../../include/mach/
+CPPFLAGS := -I $(LIBUSB_MINGW)/include/libusb-1.0 -I $(src)/../include/ -I $(src)/../../include/mach/ -include $(src)/../include/defines.h
 LDFLAGS := -L $(LIBUSB_MINGW)/lib -lusb-1.0 -static
 
 OBJECTS := $(addprefix $(obj)/, imx.o imx-usb-loader.o)

-- 
2.52.0

