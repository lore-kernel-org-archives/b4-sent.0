From: Janne Grunau <j@jannau.net>
Date: Sat, 23 Nov 2024 22:44:04 +0100
Subject: [PATCH v2 1/2] iommu: apple: Mark device with DM_FLAG_VITAL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241123-iommu_apple_dart_ordering-v2-1-cc2ade6dde97@jannau.net>
References: <20241123-iommu_apple_dart_ordering-v2-0-cc2ade6dde97@jannau.net>
In-Reply-To: <20241123-iommu_apple_dart_ordering-v2-0-cc2ade6dde97@jannau.net>
To: Mark Kettenis <kettenis@openbsd.org>, Tom Rini <trini@konsulko.com>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Simon Glass <sjg@chromium.org>, Rick Chen <rick@andestech.com>, 
 Leo <ycliang@andestech.com>, Bin Meng <bmeng.cn@gmail.com>
Cc: u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=881; i=j@jannau.net; s=yk2024;
 h=from:subject:message-id; bh=VcMS4Mwn1t2CU29JtOi4fio13jUTlPQHyjkPb8z53DY=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhnQnn6UiT6saz5yck3H6qOtdlrD3omGO0wrWBjF9/jRlv
 o/1rI3SHaUsDGJcDLJiiixJ2i87GFbXKMbUPgiDmcPKBDKEgYtTACYS8puR4cGL/5f8f934bzjd
 OP3tiXvfp6wsN1bjvb9lmmz7kSeXuooZ/of/SJoqckqldnGOe4zY/9dHWb9eeOWx6MreE8dvBhz
 +k8cAAA==
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Avoids NULL pointer dereferences in apple_dart_unmap when the iommu
device is removed before its user. U-boot's device model does not track
dependencies between devices.
Observed on a M1 Ultra Mac Studio with v2024.10.

Acked-by: Mark Kettenis <kettenis@openbsd.org>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 drivers/iommu/apple_dart.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iommu/apple_dart.c b/drivers/iommu/apple_dart.c
index 3e9e7819e517b8fe62b9e429b7a8ca3eca29741d..bfd4ad2010547de34d67f48e9b58295429ca8d3c 100644
--- a/drivers/iommu/apple_dart.c
+++ b/drivers/iommu/apple_dart.c
@@ -322,5 +322,5 @@ U_BOOT_DRIVER(apple_dart) = {
 	.ops = &apple_dart_ops,
 	.probe = apple_dart_probe,
 	.remove = apple_dart_remove,
-	.flags	= DM_FLAG_OS_PREPARE
+	.flags	= DM_FLAG_OS_PREPARE | DM_FLAG_VITAL
 };

-- 
2.47.0

