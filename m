From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Date: Mon, 08 Jun 2026 13:33:29 +0300
Subject: [PATCH v3 5/5] MAINTAINERS: Add myself to the list of UFS
 maintainers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260608-ufs_tool2-v3-5-a9f181e86229@mobileye.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=610;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=Evo/xayXeA+xDd8mrRtcOpcBO0hiTU23xBCrmgriIpk=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqJpqW1bnCUMTvFfx8ii+6W2MYAw/eB5lqSspBY
 2phdCKs5/qJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCaiaalgAKCRCfmumUluiO
 OQmQEACtHxB1TfPueraOdSIpv4DCPBg/nxPo3VKyoQNF+/sFq+YYK5VYSvTQmuHxzfRzse3NL2Q
 jHtzcAFNHhBLCBsb1kQKXBj8ybiD3aCTDfNkcfTxnZ+feaP3iYeqZWjbFLupRL5Tg6N8Pr26RZE
 0iP1cToRDVBqBaXk4U6M4iiIwORcNU5OL6x0NfG7FRu7pGIrDRX1slvvmZodm7ZZCIqKEREEjLs
 lTP1aDamsFzEcVS42Kn8D9iUC7VE6PTQztT/SZeedCQQEBzlfI6WigNSdCYRs960uo5cWmhPxUl
 jJmfFTWbwPbqE8nSMW6jke2GlGY+OJJJKm/23hnW2xO0iydb2tJChxsmen1/I11DduLxHlimL5P
 Q7ro3IYQbVnStt7OUxPVXdLmdDmNJbA6rlDZWQKMmD0sLI2ebPVnSI/IUr7LfXXMLVCvgA6ZaC7
 3puWKMH1xCdbx0AS04Q4h7DZUGgC5Dpgke8xYU9+xMAa2WSoEUu1l9BKsrmDpiJ5jnmkyLPjE2q
 56RQXECORTyQgmbB8tgg50hNsonImhQdnyHn8W87V9y4SORFISu/wMOogum1hWYeSIp4PwEd2Ix
 xg4g2R4yKfpxsjbROi9bHkht0H+/hVUENwwFWlYfrZYrTvouBxMHVv/gjAPEChEmjIVTfNmTvZp
 6iX5nfV5bqa2xFQ==
X-Developer-Key: i=raz.benyehuda@mobileye.com; a=openpgp;
 fpr=82EE5CF91375263AB26F443A9F9AE99496E88E39
X-Endpoint-Received: by B4 Relay for raz.benyehuda@mobileye.com/default with auth_id=808
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

    Adding myself to ufs.

Signed-off-by: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
---
 MAINTAINERS | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 571af196465..d2257a8327c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1920,8 +1920,11 @@ UFS
 M:	Neil Armstrong <neil.armstrong@linaro.org>
 M:	Bhupesh Sharma <bhupesh.linux@gmail.com>
 M:	Neha Malcom Francis <n-francis@ti.com>
+R:	Raz Ben Yehuda <raz.benyehuda@mobileye.com>
 S:	Maintained
+F:	cmd/ufs.c
 F:	common/spl/spl_ufs.c
+F:	doc/usage/cmd/ufs.rst
 F:	drivers/ufs/
 
 UPL

-- 
2.43.0

