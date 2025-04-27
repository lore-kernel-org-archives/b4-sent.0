From: George Chan <gchan9527@gmail.com>
Date: Sun, 27 Apr 2025 19:25:21 +0800
Subject: [PATCH 2/3] boot/bootmeth-android.c: Reuse fastboot memory block
 for unzip kernel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250427-android-boot-v1-2-bb6b37c9c9f1@gmail.com>
References: <20250427-android-boot-v1-0-bb6b37c9c9f1@gmail.com>
In-Reply-To: <20250427-android-boot-v1-0-bb6b37c9c9f1@gmail.com>
To: Tom Rini <trini@konsulko.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Simon Glass <sjg@chromium.org>, Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745753127; l=1287;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=ugLpxrUUrjW2ErfABS319vt1y5sqKu5fwdIFl4zVGGM=;
 b=DwpjZnwwoUszR0Kesxi9yE0r9CzeWPQ76RnmYvbigKN+pL58rb+DpDAGJjWLciBeNaIZ6XcPJ
 ZZjI7a59t1qBnQ4Q4CFUAb9gUzDlQ/FZgiMBLM09vWDB7ZTxcExbjo5
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some androidboot images have gzipped kernel so we need to reuse
extra mem block for holding gzipped boot.img, and let loadaddr
to hold unzipped kernel data. Here we choose fastboot memory for
reuse and avoid dramatically increase memory footprint.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 boot/bootmeth_android.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/boot/bootmeth_android.c b/boot/bootmeth_android.c
index 654ebfdf1fc..27ca2907052 100644
--- a/boot/bootmeth_android.c
+++ b/boot/bootmeth_android.c
@@ -518,6 +518,18 @@ static int boot_android_normal(struct bootflow *bflow)
 	int ret;
 	ulong loadaddr = env_get_hex("loadaddr", 0);
 	ulong vloadaddr = env_get_hex("vendor_boot_comp_addr_r", 0);
+	ulong fastboot_addr_r = env_get_hex("fastboot_addr_r", 0);
+
+	/*
+	 * Since there are some soc with very constrain mem footprint
+	 * so dont borther to allocate extra block for androidboot img
+	 * instead, reuse fastboot mem block for androidboot img
+	 *
+	 * The idea is to let loadaddr as source boot.img for unzip,
+	 * and the original loadaddr is for holding unzipped kernel.
+	 */
+	if (fastboot_addr_r)
+		loadaddr = fastboot_addr_r;
 
 	ret = run_avb_verification(bflow);
 	if (ret < 0)

-- 
2.43.0

