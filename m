From: Maud Spierings <maudspierings@gocontroll.com>
Date: Mon, 01 Dec 2025 11:26:16 +0100
Subject: [PATCH v2 1/3] scripts: imx: Makefile.mingw64: add _GNU_SOURCE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251201-imx_usb-v2-1-95ec2a0e8694@gocontroll.com>
References: <20251201-imx_usb-v2-0-95ec2a0e8694@gocontroll.com>
In-Reply-To: <20251201-imx_usb-v2-0-95ec2a0e8694@gocontroll.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764584777; l=915;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=puxY5pJSZsJ+VyRdZC4qG9rFi3Qw/x8A0EbiuaE/63c=;
 b=89TtDrIB/9pTzhHUFqn+JQLkijYT6dhVdBPxpNSPXgICKx6aQfJVZ2wsYf764KpHhXVK+RaDD
 2Ue+b4tgdtUBwjUtQvjElXVyPyei1b3Rz+hCOdD+rHEN+teXtlEcEPL
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

