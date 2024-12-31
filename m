From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Tue, 31 Dec 2024 15:13:42 +0530
Subject: [PATCH v2 1/6] regulator: Guard of_regulator_bulk_get_all() with
 CONFIG_OF
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241231-pci-pwrctrl-slot-v2-1-6a15088ba541@linaro.org>
References: <20241231-pci-pwrctrl-slot-v2-0-6a15088ba541@linaro.org>
In-Reply-To: <20241231-pci-pwrctrl-slot-v2-0-6a15088ba541@linaro.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Qiang Yu <quic_qianyu@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 kernel test robot <lkp@intel.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2865;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=K+DYdieboNDk57dwVIEL7f2cQO+VTMxu2E7c8/n7Jlo=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnc7zqTMNVJc/B8DvCcn2G3OvvaTAA8fnoqVLv0
 2ZwUIbqNt2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ3O86gAKCRBVnxHm/pHO
 9ZQhB/41JoxXANcG/9Tbc6G33jRxLNfoE/73Y3y9qigHsQ5X7/5RafygZfY4p79ClS3RIE5w4eB
 UahE3ASO8oYFZkN+sLicBX7NuVSe3qamxrcH0hWra+xz/D2BxAvJjXRDT5Mj1+I5HnWfI2kBETJ
 qmL/B6y7QOpDEfXftuWufkOA7NGj1ue4nKO6hn7ghLwoIqF4Or5XukrsFDR3zm8NSW74VuJ+vkq
 xbPXdIEvGXSW4+8MrCnEP+5uT7m7vQ86kknvDGcN654sYs1glDWOFOBnUKEJmnf2q/DwSAZtxHC
 nc+OapDZchATmfw/WgsZoztkd7yCskuTgSLQg0WEbuIXGwFV
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the definition is in drivers/regulator/of_regulator.c and compiled
only if CONFIG_OF is enabled, building the consumer driver without
CONFIG_OF and with CONFIG_REGULATOR will result in below build error:

ERROR: modpost: "of_regulator_bulk_get_all" [drivers/pci/pwrctrl/pci-pwrctl-slot.ko] undefined!

Cc: Liam Girdwood <lgirdwood@gmail.com>
Cc: Mark Brown <broonie@kernel.org>
Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202412181640.12Iufkvd-lkp@intel.com/
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 include/linux/regulator/consumer.h | 17 +++++++++--------
 1 file changed, 9 insertions(+), 8 deletions(-)

diff --git a/include/linux/regulator/consumer.h b/include/linux/regulator/consumer.h
index 8c3c372ad735..85be83c8fa17 100644
--- a/include/linux/regulator/consumer.h
+++ b/include/linux/regulator/consumer.h
@@ -175,6 +175,8 @@ struct regulator *__must_check of_regulator_get_optional(struct device *dev,
 struct regulator *__must_check devm_of_regulator_get_optional(struct device *dev,
 							      struct device_node *node,
 							      const char *id);
+int __must_check of_regulator_bulk_get_all(struct device *dev, struct device_node *np,
+					   struct regulator_bulk_data **consumers);
 #else
 static inline struct regulator *__must_check of_regulator_get_optional(struct device *dev,
 								       struct device_node *node,
@@ -189,6 +191,13 @@ static inline struct regulator *__must_check devm_of_regulator_get_optional(stru
 {
 	return ERR_PTR(-ENODEV);
 }
+
+static inline int of_regulator_bulk_get_all(struct device *dev, struct device_node *np,
+					    struct regulator_bulk_data **consumers)
+{
+	return 0;
+}
+
 #endif
 
 int regulator_register_supply_alias(struct device *dev, const char *id,
@@ -223,8 +232,6 @@ int regulator_disable_deferred(struct regulator *regulator, int ms);
 
 int __must_check regulator_bulk_get(struct device *dev, int num_consumers,
 				    struct regulator_bulk_data *consumers);
-int __must_check of_regulator_bulk_get_all(struct device *dev, struct device_node *np,
-					   struct regulator_bulk_data **consumers);
 int __must_check devm_regulator_bulk_get(struct device *dev, int num_consumers,
 					 struct regulator_bulk_data *consumers);
 void devm_regulator_bulk_put(struct regulator_bulk_data *consumers);
@@ -483,12 +490,6 @@ static inline int devm_regulator_bulk_get(struct device *dev, int num_consumers,
 	return 0;
 }
 
-static inline int of_regulator_bulk_get_all(struct device *dev, struct device_node *np,
-					    struct regulator_bulk_data **consumers)
-{
-	return 0;
-}
-
 static inline int devm_regulator_bulk_get_const(
 	struct device *dev, int num_consumers,
 	const struct regulator_bulk_data *in_consumers,

-- 
2.25.1

