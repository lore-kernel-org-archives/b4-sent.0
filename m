From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 04 Oct 2026 22:48:26 +0200
Subject: [PATCH 2/2] arm: snapdragon: export kernel_addr_r_size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-b4-dfu-alt-info-env-expand-v1-2-700eb0e54b61@protonmail.com>
References: <20261004-b4-dfu-alt-info-env-expand-v1-0-700eb0e54b61@protonmail.com>
In-Reply-To: <20261004-b4-dfu-alt-info-env-expand-v1-0-700eb0e54b61@protonmail.com>
To: u-boot@lists.u-boot-project.org, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Lukasz Majewski <lukma@denx.de>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Tom Rini <trini@konsulko.com>, Sean Anderson <sean.anderson@linux.dev>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Petr Pavlata <petr@acrux.cz>, David Heidelberg <david@ixit.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791146915; l=969;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=TMcEEwctAcjfWgy4s8/8EISXg1ISob5U7HUdIo1r3o0=;
 b=Dg2ORcCwT3X/WK8jTdxgt1L4rPPpbA5pYpRaZw8WPaGe3t+zt8b3jGGksuZDLbiy13INSSMbP
 1yu/JRYsTFJD7BYFGp+8O7nmnoed1qjaMpp0Fmk4BzZgFm83EboVJMs
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

board_late_init() allocates SZ_128M for kernel_addr_r but never
exported the size, only the address.

kernel_addr_r_size mirrors the existing kernel_comp_addr_r /
kernel_comp_size pairing already done for the compressed-kernel
buffer.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 arch/arm/mach-snapdragon/board.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm/mach-snapdragon/board.c b/arch/arm/mach-snapdragon/board.c
index 829a0109ac7..70d53a30329 100644
--- a/arch/arm/mach-snapdragon/board.c
+++ b/arch/arm/mach-snapdragon/board.c
@@ -530,6 +530,7 @@ int board_late_init(void)
 	status |= !lmb_alloc(SZ_128M, &addr) ?
 		env_set_hex("loadaddr", addr) : 1;
 	status |= env_set_hex("kernel_addr_r", addr);
+	status |= env_set_hex("kernel_addr_r_size", SZ_128M);
 	status |= !lmb_alloc(SZ_128M, &addr) ?
 		env_set_hex("ramdisk_addr_r", addr) : 1;
 	status |= !lmb_alloc(KERNEL_COMP_SIZE, &addr) ?

-- 
2.55.0

