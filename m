From: Alexandre MINETTE <contact@alex-min.fr>
Date: Mon, 27 Apr 2026 21:34:50 +0200
Subject: [PATCH v2 4/8] iommu/msm: Look up masters per IOMMU instance
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260427-mainline-send-v1-sending-v2-4-dcaa9178007b@alex-min.fr>
References: <20260427-mainline-send-v1-sending-v2-0-dcaa9178007b@alex-min.fr>
In-Reply-To: <20260427-mainline-send-v1-sending-v2-0-dcaa9178007b@alex-min.fr>
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
 iommu@lists.linux.dev, phone-devel@vger.kernel.org, 
 Alexandre MINETTE <contact@alex-min.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777318488; l=3959;
 i=contact@alex-min.fr; s=20260421; h=from:subject:message-id;
 bh=1JcBVPryARcXpHswW3TvhWpd0BaNOt71q4/rKhmP4NY=;
 b=5XOC2OaldtQ1/p7DoGQyvI4znlWXoVAnNZPpzexhOajp6zxDrNkFAITLPL+f4vcXdeaXvbhPe
 03Vt1VkOdeyDYdBTlxDWYrwfaA7Z0dHQ9FssH2cQBSuxyXzQlSTm71y
X-Developer-Key: i=contact@alex-min.fr; a=ed25519;
 pk=KOCaxY4v16ptaT0uk1FRkuaDF2n1JhmnYwLiqWD76M4=
X-Endpoint-Received: by B4 Relay for contact@alex-min.fr/20260421 with auth_id=743
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MSM IOMMU stores context descriptors on each IOMMU instance. Looking up
the descriptor through dev_iommu_priv_get() is not sufficient because a
device can reference multiple IOMMU provider nodes.

Look up the master from the target IOMMU ctx_list instead, and use the
same helper when probing and attaching devices. This avoids
dereferencing a NULL master when an IOMMU already has context entries
for another device, and keeps separate context descriptors for separate
IOMMU instances.

On APQ8064 this crashes during IOMMU probe while qcom_iommu_of_xlate()
adds stream IDs for a device referencing multiple IOMMU provider nodes.
The failure comes from insert_iommu_master() dereferencing a NULL master
after dev_iommu_priv_get() returns no context descriptor for the current
IOMMU instance:

  Unable to handle kernel NULL pointer dereference at virtual address 00000088
  PC is at qcom_iommu_of_xlate+0x84/0x174
  Call trace:
   qcom_iommu_of_xlate from of_iommu_configure+0x140/0x234
   of_iommu_configure from of_dma_configure_id+0xec/0x3b0
   of_dma_configure_id from platform_dma_configure+0xb0/0xcc
   platform_dma_configure from __iommu_probe_device+0x270/0x450
   __iommu_probe_device from probe_iommu_group+0x24/0x48
   probe_iommu_group from bus_for_each_dev+0x7c/0xcc
   bus_for_each_dev from iommu_device_register+0xcc/0x220
   iommu_device_register from msm_iommu_probe+0x47c/0x578

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

