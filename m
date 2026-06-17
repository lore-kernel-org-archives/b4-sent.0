From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Date: Wed, 17 Jun 2026 12:26:13 +0300
Subject: [PATCH v5 1/5] MAINTAINERS: Add myself to the list of UFS
 maintainers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-ufs_tool2-v5-1-1cf099f71111@mobileye.com>
References: <20260617-ufs_tool2-v5-0-1cf099f71111@mobileye.com>
In-Reply-To: <20260617-ufs_tool2-v5-0-1cf099f71111@mobileye.com>
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
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqMmhDH38Ns4GFCf3W9saKMVL7FdVhrVa7Kx6mg
 zhbTvDAugqJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCajJoQwAKCRCfmumUluiO
 OT/TD/0TIT4gUz5fTvdMFUQ3hVCaAoTXNwjorkooXbriEdpT+KsmTlgll5IQyv/wRPc16XV1d9q
 ew/Lqoy5IjJgAURkpiXZ6812MiXqaqFRR9kY9pZaKY4M/nsKdkWBOtzzKmYVIw/53oUU28VMGOh
 8X4YMOGldErJ0sVCn+3vVis1/83TRNhXRfDYccLNree1upZEpGVNIxNTe6KohaHe1pa/Rgb+rqq
 +aTGHgHZKT9LjHeL2ii5H+3v/ei8oqnjfH/etqxEribUo5Zs9E+oAXnp37yqZRssRLRawJUH08m
 z7QRIK8SeE/EB9bWD0o0m+u7208NPJjZfVqWg/yntpdPVKZQpoq+u+n/IylQYozcPyJbckv3nvt
 qwjBpY4xKPXWIOzZZRZBCBjIynjTkp0UPTeZAE3+HGy0M+JxX8S3soHhro6sRwJaHYF2gk06qDq
 bGcMxn1wGb4ARkASigDfKt4gisQ2tMTt5LVBfdJdknEaXgb8SV1wZH5ZowYDt/JnQGgkB/XOILd
 XsXeAMLv20Pl7clSnALgwCw3Pj8SqsIMmF/3ATDyzqhNFaJSmsFSrfoM0ot2bqwfxlbknIj+aO5
 qeWIaICcz6CUBZJvnI20fice+QUUCZ/HSdmVwEoZr9xGBy7eAS3Ff0RDLO+yNCv38ooWvXUaADq
 lRTStuWyqLffoTw==
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

