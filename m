From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Date: Mon, 08 Jun 2026 13:33:26 +0300
Subject: [PATCH v3 2/5] ufs: Add flags according
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260608-ufs_tool2-v3-2-a9f181e86229@mobileye.com>
References: <20260608-ufs_tool2-v3-0-a9f181e86229@mobileye.com>
In-Reply-To: <20260608-ufs_tool2-v3-0-a9f181e86229@mobileye.com>
To: u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Tawfik Bayouk <tawfik.bayouk@mobileye.com>, 
 Vladimir Kondratiev <vladimir.Kondratiev@mobileye.com>, 
 Raz Ben Yehuda <raz.benyehuda@mobileye.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=726;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=/w2PkHnQPmuBGriJVqFAGn8l0ypJLuh/dA3UCYxJEc8=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqJpqV0+rbusA21eQNSPdnAXwB0MLAuBvP1rbvL
 QVg0OVAWxyJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCaiaalQAKCRCfmumUluiO
 ObmYD/9sZ+2vawYxYFUHN5SrIBeqGb57WIOcE4vj/VEB/H7Qd5HPMWpR8PqcxtVkupYSXI4StX0
 hsiNR0jkKqAA+peNmicG8C8A6Ghytkh6z1/Vu25v2Re920S6iFd0F/KGA+YcA30xfaok1AsDWLA
 wIGC2OO8EBf4Gm1VCx/4JcgxKLJ4pUsJhNSqKU/2JrXgfZs3Byd0c5hV2LzzTHKPn+8nSvIVkyn
 9XDk508RB3aPvjfshVBjB+v8MOKtip3K9/6pGydsytJhKfDiG9z3SV8cVsbbRHSLwskmUSWA2DW
 hQb/JRxDtHRIND2RZoep4Z29xCthJ1ZXIYTeTSlhj2Z50be4keA0ueN8D+zIzp0x09DAbFAx+8e
 3KXWzCbrqtzTD7Vo0n+kEsAACdHpP28lt0731y2THEyk42lkOCHanzfCvgIOWpeJMDlxPsjb6BX
 ZRgSZ2l2ugK8RbYmnqGc7SosncLK8xaK4WHuP453sMj3i36AXOPcGKqghhHUlN7SQKa5Dieh4W4
 g67lp3pzGI8CFmJqrq4kpHd5amL/guEcVVzyLcx6ol8NVOWSPuMggfnDDAmmJ6VofUF6Ikplv5q
 CFonULNMhg87IteWsINZoq0DA2NOq4d3RvNECKYIc0DELBATBPk/Cq2roD6ToVeyVAxDfSrQ5rg
 H87aYH5JWxXErYw==
X-Developer-Key: i=raz.benyehuda@mobileye.com; a=openpgp;
 fpr=82EE5CF91375263AB26F443A9F9AE99496E88E39
X-Endpoint-Received: by B4 Relay for raz.benyehuda@mobileye.com/default with auth_id=808
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some flags are missing according to UFS 3.1

Signed-off-by: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
---
 drivers/ufs/ufs.h | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/ufs/ufs.h b/drivers/ufs/ufs.h
index 213b489e5e4..75b7ff83155 100644
--- a/drivers/ufs/ufs.h
+++ b/drivers/ufs/ufs.h
@@ -218,6 +218,9 @@ enum flag_idn {
 	QUERY_FLAG_IDN_BUSY_RTC				= 0x09,
 	QUERY_FLAG_IDN_RESERVED3			= 0x0A,
 	QUERY_FLAG_IDN_PERMANENTLY_DISABLE_FW_UPDATE	= 0x0B,
+	QUERY_FLAG_IDN_F_WRITE_BOOSTER_EN               = 0x0E,
+	QUERY_FLAG_IDN_F_WB_BUF_FLUSH_EN                = 0x0F,
+	QUERY_FLAG_IDN_F_WB_BUF_FLUSH_HIBERN8           = 0x10
 };
 
 /* Attribute idn for Query requests */

-- 
2.43.0

