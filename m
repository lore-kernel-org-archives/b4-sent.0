From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 11 Oct 2026 21:35:51 +0200
Subject: [PATCH v2 9/9] configs: pinephone-pro-rk3399: add a DFU alt
 setting for the SPI NOR
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-b4-pinephone-pro-defconfig-v2-9-6b7be35fbee7@protonmail.com>
References: <20261011-b4-pinephone-pro-defconfig-v2-0-6b7be35fbee7@protonmail.com>
In-Reply-To: <20261011-b4-pinephone-pro-defconfig-v2-0-6b7be35fbee7@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Peter Robinson <pbrobinson@gmail.com>, David Heidelberg <david@ixit.cz>, 
 Ondrej Jirman <megi@xff.cz>, Tom Rini <trini@konsulko.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, Simon Glass <sjg@chromium.org>, 
 Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Lukasz Majewski <lukma@denx.de>, 
 Anatolij Gustschin <ag.dev.uboot@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791747347; l=1003;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=eGyCJdERnylhbqAjbK86HRy1VXAZKm7uISg9fD5Z5iw=;
 b=2wQRLM9AtBNjzgE+lM/BklRlrnth+8VnE/BnJIcweshoLigmZaEflPB+xNOqZ2UWrDfq2jyxH
 BK9eStYvfhnCPSYG81Kz3FvKbF24dK4QlPwsDZyrpbpH9O0sXnQfwre
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Define dfu_alt_info with a single entry that maps the whole 16 MiB
SPI NOR on bus 1, chip select 0 to "u-boot-spi". With this
"dfu 0" from the U-Boot prompt exposes it, so u-boot-rockchip-spi.bin
can be flashed over USB without going through maskrom:

  dfu-util -a u-boot-spi -D u-boot-rockchip-spi.bin

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 include/configs/pinephone-pro-rk3399.h | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/include/configs/pinephone-pro-rk3399.h b/include/configs/pinephone-pro-rk3399.h
index 9cd44473439..9e5d3800347 100644
--- a/include/configs/pinephone-pro-rk3399.h
+++ b/include/configs/pinephone-pro-rk3399.h
@@ -10,7 +10,8 @@
 #define ROCKCHIP_DEVICE_SETTINGS \
 		"stdin=serial,usbkbd\0" \
 		"stdout=serial,vidconsole\0" \
-		"stderr=serial,vidconsole\0"
+		"stderr=serial,vidconsole\0" \
+		"dfu_alt_info=sf 1:0=u-boot-spi raw 0x0 0x1000000\0"
 
 #include <configs/rk3399_common.h>
 

-- 
2.55.0

