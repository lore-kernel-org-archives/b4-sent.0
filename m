From: Alexandre MINETTE <contact@alex-min.fr>
Date: Tue, 21 Apr 2026 11:45:10 +0200
Subject: [PATCH 4/8] iommu/msm: Look up masters per IOMMU instance
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260421-mainline-send-v1-sending-v1-4-bcb0857724de@alex-min.fr>
References: <20260421-mainline-send-v1-sending-v1-0-bcb0857724de@alex-min.fr>
In-Reply-To: <20260421-mainline-send-v1-sending-v1-0-bcb0857724de@alex-min.fr>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Guru Das Srinagesh <linux@gurudas.dev>, Linus Walleij <linusw@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Kees Cook <kees@kernel.org>, Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 iommu@lists.linux.dev, Alexandre MINETTE <contact@alex-min.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776764711; l=3031;
 i=contact@alex-min.fr; s=20260421; h=from:subject:message-id;
 bh=UrMTbZmWlSX+tqRYklfcc7/MU3hItTnCn3Swx8np/0k=;
 b=ysNmz9HJjSMgPgv7jED3yAV/X6Wskid2fofvFDhF3jxGMMWvJ0qATjOu2lFQg9SDM3VI+KmXu
 UfKhkT/d93sCwc4eOBXCsMPptc72IZAiSkDVuaw69Kq3sM12mrg/cS1
X-Developer-Key: i=contact@alex-min.fr; a=ed25519;
 pk=KOCaxY4v16ptaT0uk1FRkuaDF2n1JhmnYwLiqWD76M4=
X-Endpoint-Received: by B4 Relay for contact@alex-min.fr/20260421 with auth_id=743
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MSM IOMMU stores context descriptors on each IOMMU instance. Looking up
the descriptor through dev_iommu_priv_get() is not sufficient because a
device can reference multiple IOMMU provider nodes.

Look up the master from the target IOMMU ctx_list instead, and use the
same helper when probing and attaching devices. This avoids dereferencing
a NULL master when an IOMMU already has context entries for another
device, and keeps separate context descriptors for separate IOMMU
instances.

This is required to boot APQ8064 boards using multiple IOMMU contexts.

Signed-off-by: Alexandre MINETTE <contact@alex-min.fr>
---
 drivers/iommu/msm_iommu.c | 28 ++++++++++++++++------------
 1 file changed, 16 insertions(+), 12 deletions(-)

diff --git a/drivers/iommu/msm_iommu.c b/drivers/iommu/msm_iommu.c
index 0ad5ff431d5b..9c03878d0d2c 100644
--- a/drivers/iommu/msm_iommu.c
+++ b/drivers/iommu/msm_iommu.c
@@ -357,17 +357,25 @@ static int msm_iommu_domain_config(struct msm_priv *priv)
 	return 0;
 }
 
+static struct msm_iommu_ctx_dev *find_iommu_master(struct msm_iommu_dev *iommu,
+						   struct device *dev)
+{
+	struct msm_iommu_ctx_dev *master;
+
+	list_for_each_entry(master, &iommu->ctx_list, list)
+		if (master->of_node == dev->of_node)
+			return master;
+
+	return NULL;
+}
+
 /* Must be called under msm_iommu_lock */
 static struct msm_iommu_dev *find_iommu_for_dev(struct device *dev)
 {
 	struct msm_iommu_dev *iommu, *ret = NULL;
-	struct msm_iommu_ctx_dev *master;
 
 	list_for_each_entry(iommu, &qcom_iommu_devices, dev_node) {
-		master = list_first_entry(&iommu->ctx_list,
-					  struct msm_iommu_ctx_dev,
-					  list);
-		if (master->of_node == dev->of_node) {
+		if (find_iommu_master(iommu, dev)) {
 			ret = iommu;
 			break;
 		}
@@ -405,10 +413,7 @@ static int msm_iommu_attach_dev(struct iommu_domain *domain, struct device *dev,
 
 	spin_lock_irqsave(&msm_iommu_lock, flags);
 	list_for_each_entry(iommu, &qcom_iommu_devices, dev_node) {
-		master = list_first_entry(&iommu->ctx_list,
-					  struct msm_iommu_ctx_dev,
-					  list);
-		if (master->of_node == dev->of_node) {
+		if (find_iommu_master(iommu, dev)) {
 			ret = __enable_clocks(iommu);
 			if (ret)
 				goto fail;
@@ -601,10 +606,10 @@ static int insert_iommu_master(struct device *dev,
 				struct msm_iommu_dev **iommu,
 				const struct of_phandle_args *spec)
 {
-	struct msm_iommu_ctx_dev *master = dev_iommu_priv_get(dev);
+	struct msm_iommu_ctx_dev *master = find_iommu_master(*iommu, dev);
 	int sid;
 
-	if (list_empty(&(*iommu)->ctx_list)) {
+	if (!master) {
 		master = kzalloc_obj(*master, GFP_ATOMIC);
 		if (!master) {
 			dev_err(dev, "Failed to allocate iommu_master\n");
@@ -612,7 +617,6 @@ static int insert_iommu_master(struct device *dev,
 		}
 		master->of_node = dev->of_node;
 		list_add(&master->list, &(*iommu)->ctx_list);
-		dev_iommu_priv_set(dev, master);
 	}
 
 	for (sid = 0; sid < master->num_mids; sid++)

-- 
2.43.0

