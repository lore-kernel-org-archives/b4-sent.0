From: Janne Grunau <j@jannau.net>
Date: Thu, 18 Apr 2024 21:00:25 +0200
Subject: [PATCH v2 1/5] apple_m1_defconfig: Turn on CONFIG_SYS_64BIT_LBA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240418-apple_config-v2-1-7e5c6b9a9db3@jannau.net>
References: <20240418-apple_config-v2-0-7e5c6b9a9db3@jannau.net>
In-Reply-To: <20240418-apple_config-v2-0-7e5c6b9a9db3@jannau.net>
To: Mark Kettenis <kettenis@openbsd.org>, Tom Rini <trini@konsulko.com>
Cc: Simon Glass <sjg@chromium.org>, u-boot@lists.denx.de, 
 asahi@lists.linux.dev, Janne Grunau <j@jannau.net>, 
 Hector Martin <marcan@marcan.st>, Neal Gompa <neal@gompa.dev>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=911; i=j@jannau.net;
 h=from:subject:message-id; bh=iW3npaSaVV3BNoLkHi1Fz7M4xWDJIwJ9UUkZXz6uLiw=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhjTF3NNXd722eRf0L+uN9dHzE+wWdz+KZXmQutVUfNnEO
 7aGS4/Zd5SwMIhxMciKKbIkab/sYFhdoxhT+yAMZg4rE8gQBi5OAZhI2FNGhguXF709x/5k8b/Q
 C+lrmLetrv/l5P60t+n24oo59jnv9rcx/JhhO7uyYq7ElGPc7sZ9KRW6r529Xh35OoUto/wvx4Z
 YdgA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

This makes USB HDDs >2TiB work. The only reason this hasn't bitten us
for the internal NVMe yet is the 4K sector size, because the largest SSD
Apple sells is 8TB and we can handle up to 16TiB with that sector size.
Close call.

Signed-off-by: Hector Martin <marcan@marcan.st>
Reviewed-by: Mark Kettenis <kettenis@openbsd.org>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 configs/apple_m1_defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/configs/apple_m1_defconfig b/configs/apple_m1_defconfig
index e00d72e8be..31d966f0ab 100644
--- a/configs/apple_m1_defconfig
+++ b/configs/apple_m1_defconfig
@@ -10,6 +10,7 @@ CONFIG_SYS_PBSIZE=276
 CONFIG_DISPLAY_BOARDINFO_LATE=y
 CONFIG_BOARD_LATE_INIT=y
 # CONFIG_NET is not set
+CONFIG_SYS_64BIT_LBA=y
 CONFIG_APPLE_SPI_KEYB=y
 # CONFIG_MMC is not set
 CONFIG_NVME_APPLE=y

-- 
2.44.0

