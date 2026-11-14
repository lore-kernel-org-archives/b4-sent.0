From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 14 Nov 2026 07:22:19 +0000
Subject: [PATCH] sunxi: dram: h616: give the MAHB MBUS port priority
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-h616-mbus-mahb-priority-v1-1-8a65a2b60b35@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw6CQAxA0V8hXduE8piFv2JcMLQ6JeGRFoyG8
 O8OujyLe3dwMRWHa7GDyUtd5ymDLgX0qZuegsrZUJVVIKIGU6CAY9wcxy5FXExn0/WDNcdauCm
 5bRlyvZg89P073+5/+xYH6ddzB8fxBYYzkxt7AAAA
X-Change-ID: 20261114-h616-mbus-mahb-priority-3db3ed40d55d
To: Andre Przywara <andre.przywara@arm.com>
Cc: Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 u-boot@lists.u-boot-project.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794640938; l=1601;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=TLUyXRDsAef9Ifu4GsEl1ERPm+wnlT5ZHDuMh+ikUtQ=;
 b=DBSe0s5EkFI7lS+8a8JA8XFhl4g7lzLnXH0Ld93T80y5k0GG1uKBn97BJZA6rLsb0CwyJgFNP
 ezymwSEtpCcBrAb+hYwsczqiVHiyEYejRcrgsAw2ckHbYi7+R4fmcBa
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Problem: The EMAC reaches DRAM through MBUS port 2. With jumbo frames
larger than its 4 KiB TX FIFO, later portions of the frame have to
come from DRAM. Under CPU and video decoder load, the FIFO runs empty:
in MAC loopback at 1 Gbit/s, 6% of 8192-byte, 20% of 9014-byte and
about 70% of 13000-byte and larger frames underflowed.

Fix: Set the priority bit of port 2 (as is already done for port 25).
With the bit set, 0 of 4000 frames sized 60-16376 bytes underflowed,
against 1178 of 4000 without it.

Caveat: The setting applies to every master behind MAHB, not only the
EMAC.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm/mach-sunxi/dram_sun50i_h616.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm/mach-sunxi/dram_sun50i_h616.c b/arch/arm/mach-sunxi/dram_sun50i_h616.c
index 42a0550e015..e2a01a51a88 100644
--- a/arch/arm/mach-sunxi/dram_sun50i_h616.c
+++ b/arch/arm/mach-sunxi/dram_sun50i_h616.c
@@ -71,7 +71,7 @@ static void mctl_set_master_priority(void)
 
 	MBUS_CONF(0, false, HIGHEST, 0,  256,  128,  100);
 	MBUS_CONF(1, false,    HIGH, 0, 1536, 1400,  256);
-	MBUS_CONF(2, false, HIGHEST, 0,  512,  256,   96);
+	MBUS_CONF(2,  true, HIGHEST, 0,  512,  256,   96);
 	MBUS_CONF(3, false,    HIGH, 0,  256,  100,   80);
 	MBUS_CONF(4, false,    HIGH, 2, 8192, 5500, 5000);
 	MBUS_CONF(5, false,    HIGH, 2,  100,   64,   32);

---
base-commit: 6487c50b8a40f2668ab98a892b9300ad5c181f38
change-id: 20261114-h616-mbus-mahb-priority-3db3ed40d55d

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

