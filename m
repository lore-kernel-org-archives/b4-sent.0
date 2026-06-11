From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Date: Thu, 11 Jun 2026 10:49:35 +0300
Subject: [PATCH v4 1/4] MAINTAINERS: Add myself to the list of UFS
 maintainers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260611-ufs_tool2-v4-1-a4de78bc2409@mobileye.com>
References: <20260611-ufs_tool2-v4-0-a4de78bc2409@mobileye.com>
In-Reply-To: <20260611-ufs_tool2-v4-0-a4de78bc2409@mobileye.com>
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
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqKmiaA1mUYQ6RoKhHxTR6dzZrxcJsr4PDpO+oV
 u87ZPxC5vWJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCaipomgAKCRCfmumUluiO
 Oc39D/4oe9VZHLvp5vQvbOt+gzykH010C/NTZ93i7zvpyLeEhfwRUJsfjhGHhlvNnHam3bCSaeb
 QkVn/EdXjfhoSK32y2fjvdAOKCXRRdhwH+t/csEArHoKD9RTQQDNRiQT4bLgNLrfcxe//mj71YD
 jdK+M8Wvpi/PYQX837cGglCr4vy1+uIVV0LA91VJPwte28CUnLU/IoUGEt02tvzlPJc3l7IWO1L
 de/0b8baEttikyBU4AwrWtzxt/809dAdtPQnNLYcaZdUHtRqSIpSrm3MooQrvUZMebR5mLyf19h
 gF5fDBAE8MHGwGe/JotJltpozJI/OCzqJtTYcCAApO52TwS7AlSC055U4JSI5tf9hVHYhJ30VWn
 fkkHG0A2Lzfv0D6sEwngmmUHoSbb/URM0DsqyAdcXzvn1p/ZLymLXKsc/G+mKbeW6AIKGgtF0y2
 GPzreRDCBiEwnST+fI7gmM/itYomEHneLNi/5/j+aBxOtzfCFM6UEf/Pq7+B9wJ6r+BLU7B1Qwc
 7Hers3N/hZ6DL8XkVyBcXuY1K0I15GmAiXIk8pnjKJ+g6UM7Hv/4kkzFSJvKMocc2kUZnHg/EFf
 RQ1iwMsNoo8WgZTswkFL5l5l5i6dcICwiORPNYdxxQurLAazkZmYJinPwVi8uTNzAxCgv5HG1db
 bw6697pgTRyLeCA==
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

